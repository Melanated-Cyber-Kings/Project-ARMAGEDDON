#!/bin/bash
# dnf update -y

# # 1. Install System Dependencies & CloudWatch Agent
# dnf install -y python3-pip git mariadb105 amazon-cloudwatch-agent 
# dnf install -y tmux #easier to do diagnostics on server
# pip3 install flask pymysql boto3

#latest ami uses yum instead
yum update -y

# 1. Install System Dependencies & CloudWatch Agent
yum install -y python3-pip git mariadb105 amazon-cloudwatch-agent 
yum install -y tmux #easier to do diagnostics on server
pip3 install flask pymysql boto3

#make static test file
mkdir -p /opt/rdsapp/static
chown -R ubuntu:ubuntu /opt/rdsapp/static
echo "Chewbacca wasn't here!" >/opt/rdsapp/static/example.txt

#install rdsapp
mkdir -p /opt/rdsapp
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql
from flask import Flask, request, jsonify, make_response, send_from_directory
from datetime import datetime
import random

REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysql")

secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    s = json.loads(resp["SecretString"])
    # When you use "Credentials for RDS database", AWS usually stores:
    # username, password, host, port, dbname (sometimes)
    return s

def get_conn():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))
    db = c.get("dbname", "labdb")  # we'll create this if it doesn't exist
    return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)

#app = Flask(__name__)
app = Flask(__name__, static_folder='static')
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 3600  # Add this line

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

@app.route("/add", methods=["POST", "GET"])
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

@app.route("/list")
def list_notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    out = "<h3>Notes</h3><ul>"
    for r in rows:
        out += f"<li>{r[0]}: {r[1]}</li>"
    out += "</ul>"
    return out


# 1) Public Endpoint (Cacheable for 30s)
@app.route('/api/public-feed')
def public_feed():
    data = {
        "server_time_utc": datetime.utcnow().isoformat(),
        "message_of_the_minute": random.choice(["May the Force be with you", "RRRAARRWHHGWWR!", "Stay on target"])
    }
    
    response = make_response(jsonify(data))
    
    # s-maxage=30 tells CloudFront to cache for 30s
    # max-age=0 tells the BROWSER not to cache it (forces it to ask CloudFront)
    response.headers['Cache-Control'] = 'public, s-maxage=30, max-age=0'
    
    return response

# 2) Private Endpoint (Never Cache)
@app.route('/api/list')
def private_list():
    data = {
        "user_data": "Top secret rebel plans",
        "timestamp": datetime.utcnow().isoformat()
    }
    
    response = make_response(jsonify(data))
    
    # private: CloudFront won't cache this
    # no-store: Don't even save a temporary copy on disk
    response.headers['Cache-Control'] = 'private, no-store'
    
    return response

# Route to serve static files with specific caching logic
# @app.route('/static/<path:filename>')
# def serve_static(filename):
#     # This sends files from the 'static' folder
#     response = send_from_directory('static', filename, max_age=3600)
    
#     # Static files don't change often. 
#     # Let's tell CloudFront to cache them for 1 hour (3600s).
#     #response.headers['Cache-Control'] = 'public, max-age=3600'
#     response.cache_control.public = True
#     response.cache_control.max_age = 3600
    
#     return response

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=lab/rds/mysql
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
StandardOutput=append:/var/log/rdsapp.log
StandardError=append:/var/log/rdsapp.log
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp

# 2. Configure CloudWatch Agent 
# Tells the Agent to watch the app log file and pass it to AWS API 
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<'EOF'
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
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

