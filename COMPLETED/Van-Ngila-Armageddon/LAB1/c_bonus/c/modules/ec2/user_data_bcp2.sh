#!/bin/bash
dnf update -y
dnf install -y python3-pip wget

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

pip3 install flask pymysql boto3

# Start SSM Agent if not running
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent

# Create CloudWatch Agent configuration
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/rdsapp/app.log",
            "log_group_name": "/aws/ec2/lab-rds-app",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/lab-rds-app/system",
            "log_stream_name": "{instance_id}/messages",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": true
      },
      "disk": {
        "measurement": [
          "used_percent",
          "inodes_free"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
CWCONFIG

# Start CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

mkdir -p /opt/rdsapp
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import logging
import boto3
import pymysql
from flask import Flask, request

# Configure logging to file and console
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/opt/rdsapp/app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
SECRET_ID = os.environ.get("SECRET_ID", "lab-1c/rds/mysql")

secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    try:
        resp = secrets.get_secret_value(SecretId=SECRET_ID)
        s = json.loads(resp["SecretString"])
        logger.info(f"Successfully retrieved secret for {SECRET_ID}")
        return s
    except Exception as e:
        logger.error(f"Error retrieving secret: {e}")
        raise

def get_conn():
    try:
        c = get_db_creds()
        host = c["host"]
        user = c["username"]
        password = c["password"]
        port = int(c.get("port", 3306))
        db = c.get("dbname", "labdb")
        conn = pymysql.connect(
            host=host, 
            user=user, 
            password=password, 
            port=port, 
            database=db, 
            autocommit=True,
            connect_timeout=10
        )
        logger.info(f"Connected to database at {host}:{port}")
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        raise

app = Flask(__name__)

@app.route("/")
def home():
    logger.info("Home page accessed")
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    <p>GET /health</p>
    """

@app.route("/health")
def health():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.close()
        conn.close()
        logger.info("Health check passed")
        return "OK", 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return "Database connection failed", 500

@app.route("/init")
def init_db():
    try:
        c = get_db_creds()
        host = c["host"]
        user = c["username"]
        password = c["password"]
        port = int(c.get("port", 3306))

        conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
        cur = conn.cursor()
        cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
        cur.execute("USE labdb;")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                note VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        cur.close()
        conn.close()
        logger.info("Database initialized successfully")
        return "Initialized labdb + notes table."
    except Exception as e:
        logger.error(f"Database initialization error: {e}")
        return f"Initialization failed: {e}", 500

@app.route("/add", methods=["POST", "GET"])
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        logger.warning("Add note called without note parameter")
        return "Missing note param. Try: /add?note=hello", 400
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
        cur.close()
        conn.close()
        logger.info(f"Note inserted: {note}")
        return f"Inserted note: {note}"
    except Exception as e:
        logger.error(f"Error inserting note: {e}")
        return f"Error inserting note: {e}", 500

@app.route("/list")
def list_notes():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note, created_at FROM notes ORDER BY id DESC LIMIT 100;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        out = "<h3>Latest Notes (max 100)</h3><table border='1'><tr><th>ID</th><th>Note</th><th>Created At</th></tr>"
        for r in rows:
            out += f"<tr><td>{r[0]}</td><td>{r[1]}</td><td>{r[2]}</td></tr>"
        out += "</table>"
        logger.info(f"Listed {len(rows)} notes")
        return out
    except Exception as e:
        logger.error(f"Error listing notes: {e}")
        return f"Error listing notes: {e}", 500

if __name__ == "__main__":
    logger.info("Starting Flask application")
    app.run(host="0.0.0.0", port=80)
PY

# Create a log file for the application
touch /opt/rdsapp/app.log
chmod 644 /opt/rdsapp/app.log

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target amazon-ssm-agent.service

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=lab-1c/rds/mysql
Environment=AWS_REGION=ap-northeast-1
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp

# Log the completion of user_data
echo "User data script completed at $(date)" >> /var/log/user-data.log

# Ajoutez à la fin de user_data.sh
echo "=== Waiting for SSM Agent registration ==="
for i in {1..30}; do
    if systemctl is-active --quiet amazon-ssm-agent; then
        echo "SSM Agent is running, attempt $i/30"
        # Vérifier si l'agent est enregistré
        if [ -f /var/lib/amazon/ssm/registration ]; then
            echo "SSM Agent registered successfully"
            break
        fi
    else
        echo "SSM Agent not running, starting..."
        systemctl start amazon-ssm-agent
    fi
    sleep 10
done

# Dernière vérification
if systemctl is-active --quiet amazon-ssm-agent; then
    echo "SUCCESS: SSM Agent is active"
else
    echo "ERROR: SSM Agent failed to start"
    journalctl -u amazon-ssm-agent --no-pager -n 50
fi