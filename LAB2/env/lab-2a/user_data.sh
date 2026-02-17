#!/bin/bash

# 1. System Dependencies
# Note: mariadb105 is used for the mysql client binaries
dnf update -y
dnf install -y python3-pip git mariadb105 amazon-cloudwatch-agent

# 2. CloudWatch Agent Configuration (For Bonus F: Insights)
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

# 3. Install Python Dependencies via NAT Gateway
pip3 install flask pymysql boto3

# 4. Application Setup
mkdir -p /opt/rdsapp
cd /opt/rdsapp

cat > app.py <<'PY'
import json
import os
import boto3
import pymysql
import logging
import datetime
from flask import Flask, request, make_response

# --- CONFIGURATION (Authoritative Source: env/lab-2a/02-locals.tf) ---
# Project: Armageddon | Domain: lab2.couch2cloud.dev
REGION = "ap-northeast-1"
SECRET_ID = "Lab-2a/rds/mysql"
SSM_ENDPOINT = "/lab/db/endpoint"
SSM_DBNAME   = "/lab/db/name"
SSM_PORT     = "/lab/db/port"

# --- LOGGING (Audit Trail for Lab 3B Evidence) ---
# Source Reference: [Lab3 | 3b_audit.txt | Section 2]
logging.basicConfig(
    filename="/var/log/rdsapp.log",
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize AWS Clients (Identity inherited via IAM Instance Profile)
# Source Reference: [modules/iam/01-main.tf | Line 58]
ssm = boto3.client("ssm", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_config():
    """Interrogates SSM and sanitizes the RDS hostname."""
    try:
        resp = ssm.get_parameters(Names=[SSM_ENDPOINT, SSM_PORT, SSM_DBNAME], WithDecryption=False)
        params = {p['Name']: p['Value'] for p in resp['Parameters']}
        # ATOMIC FIX: Strip port (:3306) to prevent DNS 'Name or service not known'
        raw_host = params[SSM_ENDPOINT]
        clean_host = raw_host.split(':')[0]
        return clean_host, int(params[SSM_PORT]), params[SSM_DBNAME]
    except Exception as e:
        logger.error(f"SSM CONFIG ERROR: {str(e)}")
        raise

def get_db_creds():
    """Retrieves credentials from the Secure Vault."""
    try:
        resp = secrets.get_secret_value(SecretId=SECRET_ID)
        return json.loads(resp['SecretString'])
    except Exception as e:
        logger.error(f"SECRETS ERROR: {str(e)}")
        raise

def get_conn():
    """Establish connection with short timeout to prevent 504 hangs."""
    host, port, dbname = get_db_config()
    creds = get_db_creds()
    return pymysql.connect(
        host=host, 
        user=creds['username'], 
        password=creds['password'], 
        database=dbname, 
        port=port,
        autocommit=True,
        connect_timeout=5 # Fail fast for CloudFront resilience
    )

app = Flask(__name__, static_folder=None)

# ----------------------------------------------------------------------------
# ROUTE 1: THE HEARTBEAT (ALB Health Check)
# ----------------------------------------------------------------------------
@app.route("/")
def home():
    # Source Reference: [modules/alb/01-main.tf | Line 23]
    return "<h2>Armageddon Logic Tier: Online</h2><p>Path: /api/public-feed</p>", 200

# ----------------------------------------------------------------------------
# ROUTE 2: THE INITIALIZATION (Pass 1 Setup)
# ----------------------------------------------------------------------------
@app.route("/init")
def init_db():
    try:
        host, port, dbname = get_db_config()
        creds = get_db_creds()
        conn = pymysql.connect(host=host, user=creds['username'], password=creds['password'], port=port, autocommit=True, connect_timeout=5)
        cur = conn.cursor()
        cur.execute(f"CREATE DATABASE IF NOT EXISTS {dbname}")
        cur.execute(f"USE {dbname}")
        cur.execute("CREATE TABLE IF NOT EXISTS notes (id INT AUTO_INCREMENT PRIMARY KEY, note VARCHAR(255), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")
        conn.close()
        return "SUCCESS: Database and Table Initialized.", 200
    except Exception as e:
        logger.critical(f"INIT FAILED: {str(e)}")
        return f"Error: {str(e)}", 500

# ----------------------------------------------------------------------------
# ROUTE 3: HONORS A - PUBLIC FEED (Origin-Driven Caching)
# ----------------------------------------------------------------------------
@app.route("/api/public-feed")
def public_feed():
    """Requirement: Shared cache for 30s, browser cache 0."""
    # Source Reference: [LAB2 | 2b_Be_A_ManA.txt | Section 1]
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    content = {"status": "success", "message": "Armageddon Global Feed", "server_time_utc": now}
    resp = make_response(json.dumps(content), 200)
    resp.headers['Content-Type'] = 'application/json'
    # THE MANDATE: public (cacheable), s-maxage (CDN time), max-age (browser time)
    resp.headers['Cache-Control'] = 'public, s-maxage=30, max-age=0'
    return resp

# ----------------------------------------------------------------------------
# ROUTE 4: HONORS A - PRIVATE LIST (Never Cache)
# ----------------------------------------------------------------------------
@app.route("/api/list")
def list_notes():
    """Requirement: Private data must NEVER be cached by the Edge."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note, ts FROM notes ORDER BY id DESC")
        
        # ATOMIC FIX: Convert rows to a list of dictionaries
        row_headers = [x[0] for x in cur.description] # Get headers
        rv = cur.fetchall()
        json_data = []
        for result in rv:
            json_data.append(dict(zip(row_headers, result)))
            
        conn.close()
        
        # ATOMIC FIX: Use a custom JSON encoder for datetime objects
        def json_serial(obj):
            """JSON serializer for objects not serializable by default json code"""
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
# ROUTE 5: LAB 2B - STATIC ASSET PROOF
# ----------------------------------------------------------------------------
@app.route("/static/<path:path>")
def send_static(path):
    """Requirement: Demonstrate Edge-side TTL enforcement."""
    content = f"Immaculate Standard Verified: Static Delivery for {path}"
    resp = make_response(content, 200)
    # Note: Even if we send no-cache here, CloudFront Policy 'static_force' overrides it.
    resp.headers['Cache-Control'] = 'no-cache' 
    return resp
# ----------------------------------------------------------------------------
# ROUTE 6: FUNCTIONAL WRITE (The Data Entry Point)
# ----------------------------------------------------------------------------
@app.route("/api/add")
def add_note():
    """Requirement: Prove remote writes can traverse the TGW corridor."""
    # Logic: /api/add?note=YourMessage
    note = request.args.get('note', 'New Entry from Armageddon')
    try:
        conn = get_conn()
        cur = conn.cursor()
        # Source Reference: [LAB1 | 1a_user_data.sh | Line 56]
        cur.execute("INSERT INTO notes (note) VALUES (%s)", (note,))
        conn.close()
        
        resp = make_response(json.dumps({"status": "success", "inserted": note}), 200)
        resp.headers['Content-Type'] = 'application/json'
        # COMPLIANCE: Never cache a POST/Write action
        resp.headers['Cache-Control'] = 'private, no-store'
        return resp
    except Exception as e:
        logger.error(f"ADD FAILED: {str(e)}")
        return make_response(json.dumps({"error": str(e)}), 500)
if __name__ == "__main__":
    # Internal port 80 maps to ALB target. Use unbuffered for log flushing.
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