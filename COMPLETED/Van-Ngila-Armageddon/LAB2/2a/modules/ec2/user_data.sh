#!/bin/bash
set -x  # Active le mode debug
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== Starting user_data script ==="
date

# Mettre à jour et installer les dépendances
dnf update -y
dnf install -y python3-pip wget curl

# === INSTALL PYTHON DEPENDENCIES FIRST ===
echo "=== Installing Python dependencies ==="
pip3 install --upgrade pip
pip3 install flask pymysql boto3

# Verify installation
python3 -c "import flask, pymysql, boto3; print('✓ Python dependencies installed')"

# === INSTALLATION DE SSM AGENT ===
echo "=== Installing SSM Agent ==="

# Méthode 1: Via yum/dnf (recommandé pour Amazon Linux 2023)
dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

# Méthode alternative si la première échoue:
# mkdir -p /tmp/ssm
# cd /tmp/ssm
# wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
# rpm -ivh amazon-ssm-agent.rpm

# Vérifier l'installation
echo "=== Verifying SSM Agent installation ==="
rpm -qa | grep ssm
which amazon-ssm-agent

# Démarrer et activer SSM Agent
echo "=== Starting SSM Agent ==="
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Vérifier le statut
echo "=== SSM Agent status ==="
systemctl status amazon-ssm-agent --no-pager

# Attendre que l'agent démarre
echo "=== Waiting for SSM Agent to initialize ==="
sleep 10

# Vérifier les logs
echo "=== SSM Agent logs ==="
tail -20 /var/log/amazon/ssm/amazon-ssm-agent.log || echo "No SSM logs yet"

# === INSTALLATION CLOUDWATCH AGENT ===
echo "=== Installing CloudWatch Agent ==="
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

# === INSTALLATION DES AUTRES PAQUETS ===
#pip3 install flask pymysql boto3

# === TEST DE CONNECTIVITE AUX ENDPOINTS ===
echo "=== Testing VPC Endpoint Connectivity ==="

# Liste des endpoints à tester
endpoints=(
    "ssm.ap-northeast-1.amazonaws.com"
    "ec2messages.ap-northeast-1.amazonaws.com"
    "ssmmessages.ap-northeast-1.amazonaws.com"
    "logs.ap-northeast-1.amazonaws.com"
    "secretsmanager.ap-northeast-1.amazonaws.com"
    "kms.ap-northeast-1.amazonaws.com"
)

for endpoint in "${endpoints[@]}"; do
    echo -n "Testing $endpoint... "
    if timeout 3 curl -s -I "https://$endpoint" >/dev/null; then
        echo "✓ REACHABLE"
    else
        echo "✗ UNREACHABLE"
    fi
done

# === CONFIGURATION CLOUDWATCH AGENT ===
echo "=== Configuring CloudWatch Agent ==="
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
          },
          {
            "file_path": "/var/log/amazon/ssm/amazon-ssm-agent.log",
            "log_group_name": "/aws/ec2/ssm-agent",
            "log_stream_name": "{instance_id}",
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

# Démarrer CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo "=== CloudWatch Agent status ==="
systemctl status amazon-cloudwatch-agent --no-pager

# === APPLICATION FLASK ===
echo "=== Setting up Flask application ==="
mkdir -p /opt/rdsapp

# [VOTRE CODE APPLICATION FLASK ICI - le même que précédemment]
# ... copiez tout le contenu de votre application Flask ici ...

cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import logging
import boto3
import pymysql
from flask import Flask, request, jsonify
from datetime import datetime

# Configure logging
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
    <p>GET /ssm-status</p>
    <p>GET /static/test.txt (Lab 2B Cache Test)</p>
    <p>GET /api/health (Lab 2B API Test)</p>
    <p>GET /api/data (Lab 2B Auth Test)</p>
    """
# ========== LAB 2B ENDPOINTS ==========

@app.route('/static/test.txt')
def static_test():
    """Static endpoint for cache testing - CloudFront will cache aggressively"""
    logger.info("Static test endpoint accessed")
    return "Static content cached aggressively - " + datetime.now().isoformat(), 200, {
        'Content-Type': 'text/plain',
        'X-App-Generated': 'true'
    }

@app.route("/api/health")
def api_health():
    """API endpoint that should never be cached"""
    logger.info("API health endpoint accessed")
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.close()
        conn.close()
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "cache_hint": "This should never be cached"
        }), 200
    except Exception as e:
        logger.error(f"API health check failed: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/data')
def api_data():
    """API endpoint to test Authorization header forwarding"""
    auth_header = request.headers.get('Authorization', 'No-Auth')
    logger.info(f"API data endpoint accessed, auth header: {auth_header[:20] if auth_header != 'No-Auth' else 'None'}")
    
    return jsonify({
        "message": "API response - should never be cached",
        "auth_received": auth_header[:20] + "..." if auth_header != 'No-Auth' else 'None',
        "auth_full_length": len(auth_header) if auth_header != 'No-Auth' else 0,
        "timestamp": datetime.now().isoformat(),
        "cache_hint": "Age: 0, X-Cache: Miss expected"
    })

# ========== Previous Endpoints ==========

@app.route("/ssm-status")
def ssm_status():
    try:
        with open('/var/log/amazon/ssm/amazon-ssm-agent.log', 'r') as f:
            lines = f.readlines()[-10:]
        return f"<pre>SSM Agent Logs (last 10 lines):\n{''.join(lines)}</pre>"
    except:
        return "SSM Agent logs not available"

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
        return f"Database connection failed: {e}", 500

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

# Créer le fichier de log
touch /opt/rdsapp/app.log
chmod 644 /opt/rdsapp/app.log

# Service systemd
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

# === VERIFICATION FINALE ===
echo "=== Final verification ==="
echo "SSM Agent status:"
systemctl is-active amazon-ssm-agent && echo "ACTIVE" || echo "INACTIVE"

echo "CloudWatch Agent status:"
systemctl is-active amazon-cloudwatch-agent && echo "ACTIVE" || echo "INACTIVE"

echo "Flask app status:"
systemctl is-active rdsapp && echo "ACTIVE" || echo "INACTIVE"

echo "=== Checking registration status ==="
# Essayer de contacter le service SSM
for i in {1..10}; do
    echo "Registration attempt $i/10..."
    if curl -s http://localhost:80/ssm-status >/dev/null 2>&1; then
        echo "Application is responding"
        break
    fi
    sleep 5
done

echo "=== user_data script completed ==="
date