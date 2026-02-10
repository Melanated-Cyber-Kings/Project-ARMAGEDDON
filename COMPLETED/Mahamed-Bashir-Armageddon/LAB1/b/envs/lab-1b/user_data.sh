#!/bin/bash
# ----------------------------------------------------
# ARMAGEDDON: LAB 1B (SSM + ENTERPRISE LOGGING)
# ----------------------------------------------------

# 1. Install System Dependencies & CloudWatch Agent
dnf update -y
dnf install -y python3-pip git mariadb105 amazon-cloudwatch-agent

# 2. Configure CloudWatch Agent (The Courier)
# This tells the Agent to watch the app log file and ship it to AWS
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
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

# 3. Start the Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
    -s

# 4. App Setup
mkdir -p /opt/rdsapp
cd /opt/rdsapp
pip3 install flask pymysql boto3

# 5. Application Code (SSM Aware)
cat > app.py <<'EOF'
import json
import boto3
import pymysql
import logging
from flask import Flask

# --- CONFIGURATION KEYS (Not Values) ---
REGION = "${region}"
SECRET_ID = "lab-1a/rds/mysql"
SSM_ENDPOINT = "/lab/db/endpoint"
SSM_DBNAME   = "/lab/db/name"
SSM_PORT     = "/lab/db/port"

# --- LOGGING SETUP (Critical for Lab 1B) ---
LOG_FILE = "/var/log/rdsapp.log"
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)

# AWS CLIENTS
ssm = boto3.client("ssm", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)

def get_config():
    """
    Fetch Non-Sensitive Config from SSM Parameter Store
    """
    try:
        response = ssm.get_parameters(
            Names=[SSM_ENDPOINT, SSM_DBNAME, SSM_PORT],
            WithDecryption=False
        )
        # Map parameters to a dictionary
        params = {p['Name']: p['Value'] for p in response.get('Parameters', [])}
        
        return params[SSM_ENDPOINT], params[SSM_DBNAME], int(params[SSM_PORT])
    except Exception as e:
        logger.critical(f"FAILED TO FETCH SSM CONFIG: {str(e)}")
        raise e

def get_creds():
    """
    Fetch Sensitive Credentials from Secrets Manager
    """
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    return json.loads(resp["SecretString"])

def get_conn():
    # 1. Get Config (SSM)
    host, dbname, port = get_config()
    
    # 2. Get Secrets (Secrets Manager)
    c = get_creds()
    
    try:
        # 3. Connect
        return pymysql.connect(
            host=host,
            user=c['username'],
            password=c['password'],
            database=dbname,
            port=port,
            connect_timeout=3
        )
    except Exception as e:
        # 4. LOG THE CRITICAL ERROR (This triggers the Alarm)
        logger.critical(f"DATABASE CONNECTION FAILED: {str(e)}")
        raise e

app = Flask(__name__)

@app.route("/")
def home():
    logger.info("Home page accessed")
    return "<h1>Lab 1B: SSM + CloudWatch Agent</h1><p><a href='/list'>Test DB</a></p>"

@app.route("/list")
def list_notes():
    try:
        conn = get_conn()
        conn.close()
        logger.info("Database connection successful")
        return "SUCCESS: Connected via SSM & Secrets Manager!"
    except Exception as e:
        return f"FAILED: {str(e)}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
EOF

# 6. Permissions & Service Start
touch /var/log/rdsapp.log
chmod 666 /var/log/rdsapp.log

cat > /etc/systemd/system/rdsapp.service <<EOF
[Unit]
Description=Flask App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp