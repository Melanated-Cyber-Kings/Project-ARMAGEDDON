#!/bin/bash

###############################################################################
# COURSE: ARMAGEDDON LABS
# TRACK: LAB-1
# COMPONENT: ec2
# PURPOSE: Standardized script header for LAB-1.
###############################################################################

set -euo pipefail

# -----------------------------------------------------------------------------
# Lab-1B bootstrap (SSM + app + CloudWatch Logs)
# -----------------------------------------------------------------------------
BOOT_LOG="/var/log/user-data-bootstrap.log"
exec > >(tee -a "$BOOT_LOG" | logger -t user-data -s 2>/dev/console) 2>&1

echo "[BOOT] $(date -Is) user-data starting"

# Ensure SSM agent is installed + running and restart after IMDS/IAM is reachable
if ! command -v amazon-ssm-agent >/dev/null 2>&1; then
  echo "[SSM] Installing amazon-ssm-agent"
  dnf install -y amazon-ssm-agent || true
fi

echo "[SSM] Enabling + starting amazon-ssm-agent"
systemctl enable --now amazon-ssm-agent || true

echo "[SSM] Waiting for IMDS + IAM role credentials (avoid first-boot race)"
for i in $(seq 1 20); do
  TOKEN="$(curl -sS -m 2 -X PUT "http://169.254.169.254/latest/api/token"     -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)"
  if [ -n "${TOKEN:-}" ] && curl -sS -m 2 -H "X-aws-ec2-metadata-token: $TOKEN"       "http://169.254.169.254/latest/meta-data/iam/info" >/dev/null 2>&1; then
    echo "[SSM] IMDS/IAM reachable (attempt $i)"
    break
  fi
  sleep 3
done

echo "[SSM] Restarting amazon-ssm-agent"
systemctl restart amazon-ssm-agent || true
systemctl --no-pager status amazon-ssm-agent || true

dnf update -y
dnf install -y python3-pip
pip3 install flask pymysql boto3

mkdir -p /opt/rdsapp
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql

# Added logging for better observability and troubleshooting.
from flask import Flask, request
import logging

logging.basicConfig(
    filename="/var/log/rdsapp.log",
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
SECRET_ID = os.environ.get("SECRET_ID", "lab-1b/rds/mysql")

secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    s = json.loads(resp["SecretString"])
    # When you use "Credentials for RDS database", AWS usually stores:
    # username, password, host, port, dbname (sometimes)
    return s

# def get_conn():
#     c = get_db_creds()
#     host = c["host"]
#     user = c["username"]
#     password = c["password"]
#     port = int(c.get("port", 3306))
#     db = c.get("dbname", "labdb")  # we'll create this if it doesn't exist
#     return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)

# Improved get_conn with error handling and timeout.
def get_conn():
    try:
        c = get_db_creds()
        host = c["host"]
        user = c["username"]
        password = c["password"]
        port = int(c.get("port", 3306))
        db = c.get("dbname", "labdb")
        return pymysql.connect(
            host=host,
            user=user,
            password=password,
            port=port,
            database=db,
            autocommit=True,
            connect_timeout=3
        )
    except Exception as e:
        logging.error("DB_CONNECTION_ERROR %s", e)
        raise

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    """

@app.route("/init")
def init_db():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))

    # connect without specifying a DB first
    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
    cur = conn.cursor()
    cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
    cur.execute("USE labdb;")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            note VARCHAR(255) NOT NULL
        );
    """)
    cur.close()
    conn.close()
    return "Initialized labdb + notes table."

# @app.route("/add", methods=["POST", "GET"])

# Enhanced error handling in add_note endpoint.This wraps routes that 
# interact with the database in try-except blocks to catch and log exceptions.

@app.route("/add", methods=["POST", "GET"])
def add_note():
    try:
        note = request.args.get("note", "").strip()
        if not note:
            return "Missing note param. Try: /add?note=hello", 400

        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
        cur.close()
        conn.close()
        return f"Inserted note: {note}"

    except Exception:
        return "Database error", 500


def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        return "Missing note param. Try: /add?note=hello", 400
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
    cur.close()
    conn.close()
    return f"Inserted note: {note}"

# Commented out list_notes for troubleshooting simplicity.
# @app.route("/list")
# def list_notes():
#     conn = get_conn()
#     cur = conn.cursor()
#     cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
#     rows = cur.fetchall()
#     cur.close()
#     conn.close()
#     out = "<h3>Notes</h3><ul>"
#     for r in rows:
#         out += f"<li>{r[0]}: {r[1]}</li>"
#     out += "</ul>"
#     return out

# Added revised list_notes with error handling. This should help error messages
# that are expected to be in error logs. Database failure log should be in /var/log/rdsapp.log.
# Error log for database will be DB_CONNECTION_ERROR.
# Flask will return 500 status code on database errors.
# Cloudwatch metric filter triggers on DB_CONNECTION_ERROR in /var/log/rdsapp.log.
# Alarm triggers from rdsapp log errors.

@app.route("/list")
def list_notes():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note FROM notes;")
        rows = cur.fetchall()
        cur.close()
        conn.close()

        out = "\n".join([f"{r[0]}: {r[1]}" for r in rows])
        return out or "No notes yet"

    except Exception:
        # get_conn() already logs DB_CONNECTION_ERROR
        return "Database error", 500




if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=lab-1b/rds/mysql
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

# Send app stdout/stderr to a file so CloudWatch Agent can ship it
StandardOutput=append:/var/log/rdsapp.log
StandardError=append:/var/log/rdsapp.log

[Install]
WantedBy=multi-user.target
SERVICE

# Ensure application log file exists (CloudWatch Agent watches this)
touch /var/log/rdsapp.log
chmod 644 /var/log/rdsapp.log

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp

\
# -----------------------------------------------------------------------------
# CloudWatch Agent (ships /var/log/rdsapp.log -> /aws/ec2/lab-rds-app)
# -----------------------------------------------------------------------------
echo "[CW] Installing amazon-cloudwatch-agent"
dnf install -y amazon-cloudwatch-agent || true

CWA_DIR="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d"
CWA_CFG="${CWA_DIR}/amazon-cloudwatch-agent-config.json"

mkdir -p "$CWA_DIR"

cat >"$CWA_CFG" <<'JSON'
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
JSON

echo "[CW] Applying CloudWatch agent config from ${CWA_CFG}"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop || true
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c "file:${CWA_CFG}" -s || true

systemctl enable --now amazon-cloudwatch-agent || true
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status || true

if ! systemctl is-active --quiet amazon-cloudwatch-agent; then
  echo "[CW][WARN] CloudWatch Agent failed to start — check /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
else
  echo "[CW] CloudWatch Agent running"
fi

echo "[BOOT] $(date -Is) user-data complete"
