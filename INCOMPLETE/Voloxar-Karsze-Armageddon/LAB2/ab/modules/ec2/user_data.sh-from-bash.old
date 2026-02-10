#!/bin/bash

# 1. System Infrastructure & CloudWatch Setup
dnf update -y
dnf install -y python3-pip git mariadb105 amazon-cloudwatch-agent
pip3 install flask pymysql boto3

mkdir -p /opt/rdsapp
mkdir -p /var/log/app/

# 2. The Logic Layer: App.py
# Scrutiny: Handles dual-store (SSM + Secrets) and strips port from hostname.
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql
import logging
from flask import Flask, request

# --- CONFIGURATION ---
REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysql")
SSM_PARAM_ENDPOINT = "/lab/db/endpoint"

# --- LOGGING (Captured by CW Agent) ---
logging.basicConfig(
    filename="/var/log/app/rdsapp.log",
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)

ssm = boto3.client("ssm", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_config():
    """Interrogates SSM for the RDS Endpoint and cleans the string."""
    try:
        resp = ssm.get_parameter(Name=SSM_PARAM_ENDPOINT)
        raw_host = resp["Parameter"]["Value"]
        # Strip port (:3306) to prevent 'Name or service not known'
        clean_host = raw_host.split(':')[0]
        return clean_host
    except Exception as e:
        logger.error(f"SSM Retrieval Failed: {str(e)}")
        return None

def get_db_creds():
    """Interrogates Secrets Manager for credentials."""
    try:
        resp = secrets.get_secret_value(SecretId=SECRET_ID)
        return json.loads(resp["SecretString"])
    except Exception as e:
        logger.error(f"Secret Retrieval Failed: {str(e)}")
        return None

def get_conn():
    """Establish connection with short timeout to prevent 504 hangs."""
    host = get_db_config()
    creds = get_db_creds()
    
    if not host or not creds:
        raise Exception("Configuration incomplete. Check SSM/Secrets.")

    return pymysql.connect(
        host=host, 
        user=creds["username"], 
        password=creds["password"], 
        database="labdb", 
        autocommit=True,
        connect_timeout=5 # Fail fast so ALB/CloudFront can handle the error
    )

app = Flask(__name__)

@app.route("/")
def home():
    return "<h2>EC2 to RDS App (Lab 2 Cloaked Origin)</h2><p>GET /init</p><p>GET /list</p>"

@app.route("/init")
def init_db():
    try:
        host = get_db_config()
        creds = get_db_creds()
        # Connect without DB first to create it
        conn = pymysql.connect(host=host, user=creds['username'], password=creds['password'], autocommit=True, connect_timeout=5)
        cur = conn.cursor()
        cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
        cur.execute("USE labdb;")
        cur.execute("CREATE TABLE IF NOT EXISTS notes (id INT AUTO_INCREMENT PRIMARY KEY, note VARCHAR(255));")
        conn.close()
        logger.info("Database Initialized")
        return "Initialized labdb + notes table."
    except Exception as e:
        logger.critical(f"INIT FAILED: {str(e)}")
        return f"Error: {str(e)}", 500

@app.route("/add")
def add_note():
    note = request.args.get("note", "Default Note")
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
        conn.close()
        return f"Inserted: {note}"
    except Exception as e:
        logger.error(f"ADD FAILED: {str(e)}")
        return "Error adding note", 500

@app.route("/list")
def list_notes():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
        rows = cur.fetchall()
        conn.close()
        return f"Notes: {str(rows)}"
    except Exception as e:
        logger.error(f"LIST FAILED: {str(e)}")
        return "Error listing notes", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

# 3. Systemd Resilience Implementation
# Forces auto-restart if the app crashes during Pass 1/2 of build.
cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=lab/rds/mysql
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always
RestartSec=5
StandardOutput=append:/var/log/app/rdsapp.log
StandardError=append:/var/log/app/rdsapp.log

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp

# 4. CloudWatch Agent Monitoring (Audit Artifacts)
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<'EOF'
{
  "agent": { "metrics_collection_interval": 60, "run_as_user": "root" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app/rdsapp.log",
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

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json