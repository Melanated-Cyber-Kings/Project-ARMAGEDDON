#!/bin/bash
# ----------------------------------------------------------------
# APPLICATION BOOTSTRAP: FLASK RDS CLIENT
# ----------------------------------------------------------------

# 1. System Dependencies
dnf update -y
dnf install -y python3-pip git mariadb105 amazon-cloudwatch-agent

# 2. CloudWatch Agent Configuration
# Configures log aggregation for application-level monitoring
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<EOF
{
  "agent": { "metrics_collection_interval": 60, "run_as_user": "root" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/rdsapp.log",
            "log_group_name": "/aws/ec2/lab-rds-app",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

# 3. Install Python Dependencies
pip3 install flask pymysql boto3

# 4. Application Setup
mkdir -p /opt/rdsapp
cd /opt/rdsapp

cat > app.py <<PY
import json
import os
import boto3
import pymysql
import logging
import datetime
from flask import Flask, request, make_response

# --- CONFIGURATION (Injected via Terraform Template) ---
REGION = "${region}" 
SECRET_ID = "${secret_id}"
SSM_ENDPOINT = "/lab/db/endpoint"
SSM_DBNAME   = "/lab/db/name"
SSM_PORT     = "/lab/db/port"

# --- LOGGING ---
logging.basicConfig(
    filename="/var/log/rdsapp.log",
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize AWS Clients (Identity inherited via IAM Instance Profile)
ssm = boto3.client("ssm", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_config():
    """Retrieves dynamic database configuration from SSM Parameter Store."""
    try:
        resp = ssm.get_parameters(Names=[SSM_ENDPOINT, SSM_PORT, SSM_DBNAME], WithDecryption=False)
        params = {p['Name']: p['Value'] for p in resp['Parameters']}
        
        # Sanitize Host: Remove port if present to prevent DNS resolution errors
        raw_host = params[SSM_ENDPOINT]
        clean_host = raw_host.split(':')[0]
        return clean_host, int(params[SSM_PORT]), params[SSM_DBNAME]
    except Exception as e:
        logger.error(f"SSM CONFIG ERROR: {str(e)}")
        raise

def get_db_creds():
    """Retrieves database credentials from Secrets Manager."""
    try:
        resp = secrets.get_secret_value(SecretId=SECRET_ID)
        return json.loads(resp['SecretString'])
    except Exception as e:
        logger.error(f"SECRETS ERROR: {str(e)}")
        raise

def get_conn():
    """Establish database connection with aggressive timeout for failover resilience."""
    host, port, dbname = get_db_config()
    creds = get_db_creds()
    return pymysql.connect(
        host=host, 
        user=creds['username'], 
        password=creds['password'], 
        database=dbname, 
        port=port,
        autocommit=True,
        connect_timeout=5 
    )

app = Flask(__name__, static_folder=None)

# ----------------------------------------------------------------------------
# ROUTE 1: HEALTH CHECK (ALB Target)
# ----------------------------------------------------------------------------
@app.route("/")
def home():
    return "<h2>Application Online</h2><p>Endpoint: /api/public-feed</p>", 200

# ----------------------------------------------------------------------------
# ROUTE 2: DATABASE INITIALIZATION
# ----------------------------------------------------------------------------
@app.route("/init")
def init_db():
    """Bootstraps the database schema if not present."""
    try:
        host, port, dbname = get_db_config()
        creds = get_db_creds()
        conn = pymysql.connect(host=host, user=creds['username'], password=creds['password'], port=port, autocommit=True, connect_timeout=5)
        cur = conn.cursor()
        cur.execute(f"CREATE DATABASE IF NOT EXISTS {dbname}")
        cur.execute(f"USE {dbname}")
        cur.execute("CREATE TABLE IF NOT EXISTS notes (id INT AUTO_INCREMENT PRIMARY KEY, note VARCHAR(255), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")
        conn.close()
        return "SUCCESS: Database schema initialized.", 200
    except Exception as e:
        logger.critical(f"INIT FAILED: {str(e)}")
        return f"Error: {str(e)}", 500

# ----------------------------------------------------------------------------
# ROUTE 3: PUBLIC API (Cached)
# ----------------------------------------------------------------------------
@app.route("/api/public-feed")
def public_feed():
    """Returns timestamped JSON with Origin-Controlled Caching headers."""
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    content = {"status": "success", "message": "Global Feed", "server_time_utc": now}
    resp = make_response(json.dumps(content), 200)
    resp.headers['Content-Type'] = 'application/json'
    # CACHE STRATEGY: Shared cache (CDN) 30s, Private cache (Browser) 0s
    resp.headers['Cache-Control'] = 'public, s-maxage=30, max-age=0'
    return resp

# ----------------------------------------------------------------------------
# ROUTE 4: PRIVATE LIST (No-Cache)
# ----------------------------------------------------------------------------
@app.route("/api/list")
def list_notes():
    """Retrieves data from RDS. Must never be cached."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note, ts FROM notes ORDER BY id DESC")
        
        # Convert tuple rows to dictionary list
        row_headers = [x[0] for x in cur.description]
        rv = cur.fetchall()
        json_data = []
        for result in rv:
            json_data.append(dict(zip(row_headers, result)))
            
        conn.close()
        
        # JSON serializer for datetime objects
        def json_serial(obj):
            if isinstance(obj, (datetime.datetime, datetime.date)):
                return obj.isoformat()
            raise TypeError ("Type %s not serializable" % type(obj))

        resp = make_response(json.dumps({"notes": json_data}, default=json_serial), 200)
        resp.headers['Content-Type'] = 'application/json'
        resp.headers['Cache-Control'] = 'private, no-store'
        return resp
    except Exception as e:
        return make_response(json.dumps({"error": str(e)}), 500)

# ----------------------------------------------------------------------------
# ROUTE 5: STATIC ASSETS (Edge TTL Enforcement)
# ----------------------------------------------------------------------------
@app.route("/static/<path:path>")
def send_static(path):
    """Serves static content to validate CloudFront Minimum TTL policies."""
    content = f"Static Delivery Verified: {path}"
    resp = make_response(content, 200)
    # Origin sends no-cache; CloudFront policy should override this
    resp.headers['Cache-Control'] = 'no-cache' 
    return resp

# ----------------------------------------------------------------------------
# ROUTE 6: WRITE OPERATION
# ----------------------------------------------------------------------------
@app.route("/api/add")
def add_note():
    """Writes data to the database via GET request to support Origin Failover."""
    note = request.args.get('note', 'New Entry')
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes (note) VALUES (%s)", (note,))
        conn.close()
        
        resp = make_response(json.dumps({"status": "success", "inserted": note}), 200)
        resp.headers['Content-Type'] = 'application/json'
        resp.headers['Cache-Control'] = 'private, no-store'
        return resp
    except Exception as e:
        logger.error(f"ADD FAILED: {str(e)}")
        return make_response(json.dumps({"error": str(e)}), 500)

if __name__ == "__main__":
    # Bind to port 80 for ALB traffic
    app.run(host="0.0.0.0", port=80, debug=False)
PY

# 5. Create Systemd Service
cat > /etc/systemd/system/rdsapp.service <<EOF
[Unit]
Description=Flask RDS App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp