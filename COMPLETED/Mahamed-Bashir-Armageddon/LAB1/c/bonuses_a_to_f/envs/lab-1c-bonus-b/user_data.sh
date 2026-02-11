#!/bin/bash
# ----------------------------------------------------------------
# ARMAGEDDON: LAB 1 (BONUS B-F) - NAT-EGRESS PATTERN
# ----------------------------------------------------------------

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
import boto3
import pymysql
import logging
from flask import Flask, request

# --- CONFIGURATION ---
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

ssm = boto3.client("ssm", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_config():
    # Fetch endpoint and port from SSM
    resp = ssm.get_parameters(Names=[SSM_ENDPOINT, SSM_PORT, SSM_DBNAME], WithDecryption=False)
    params = {p['Name']: p['Value'] for p in resp['Parameters']}
    return params[SSM_ENDPOINT], int(params[SSM_PORT]), params[SSM_DBNAME]

def get_db_creds():
    # Fetch credentials from Secrets Manager
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    return json.loads(resp['SecretString'])

app = Flask(__name__)

@app.route("/")
def home():
    return "<h2>EC2 to RDS App (NAT Egress)</h2><p><a href='/init'>1. Init DB</a></p><p><a href='/list'>2. List Notes</a></p>"

@app.route("/init")
def init_db():
    try:
        host, port, dbname = get_db_config()
        creds = get_db_creds()
        # Connect without DB first to create it
        conn = pymysql.connect(host=host, user=creds['username'], password=creds['password'], port=port, autocommit=True)
        cur = conn.cursor()
        cur.execute(f"CREATE DATABASE IF NOT EXISTS {dbname}")
        cur.execute(f"USE {dbname}")
        cur.execute("CREATE TABLE IF NOT EXISTS notes (id INT AUTO_INCREMENT PRIMARY KEY, note VARCHAR(255))")
        conn.close()
        logger.info("Database Initialized Successfully")
        return "Database and Table Initialized."
    except Exception as e:
        logger.critical(f"INIT FAILED: {str(e)}")
        return f"Init Failed: {str(e)}", 500

@app.route("/add")
def add_note():
    note = request.args.get('note', 'New Note')
    try:
        host, port, dbname = get_db_config()
        creds = get_db_creds()
        conn = pymysql.connect(host=host, user=creds['username'], password=creds['password'], database=dbname, port=port, autocommit=True)
        cur = conn.cursor()
        cur.execute("INSERT INTO notes (note) VALUES (%s)", (note,))
        conn.close()
        logger.info(f"Note added: {note}")
        return f"Added note: {note}"
    except Exception as e:
        logger.error(f"ADD FAILED: {str(e)}")
        return "Error adding note", 500

@app.route("/list")
def list_notes():
    try:
        host, port, dbname = get_db_config()
        creds = get_db_creds()
        conn = pymysql.connect(host=host, user=creds['username'], password=creds['password'], database=dbname, port=port)
        cur = conn.cursor()
        cur.execute("SELECT note FROM notes")
        notes = cur.fetchall()
        conn.close()
        return f"Notes: {str(notes)}"
    except Exception as e:
        logger.error(f"LIST FAILED: {str(e)}")
        return "Error listing notes", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
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