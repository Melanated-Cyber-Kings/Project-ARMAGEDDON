#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    mysql-client \
    awscli \
    jq

# Create application directory
mkdir -p /opt/lab1b-app
cd /opt/lab1b-app

# Create Python application
cat > app.py << 'EOF'
from flask import Flask, jsonify, request
import mysql.connector
import pymysql
import boto3
import json
import os
import logging
from datetime import datetime
from botocore.exceptions import ClientError

app = Flask(__name__)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# AWS clients
session = boto3.session.Session(region_name='${region}')
ssm = session.client('ssm')
secrets = session.client('secretsmanager')

def get_db_config():
    """Get database configuration from SSM and Secrets Manager"""
    try:
        # Get config from SSM Parameter Store
        ssm_params = ssm.get_parameters(
            Names=[
                '/lab1b/db/endpoint',
                '/lab1b/db/port',
                '/lab1b/db/name'
            ],
            WithDecryption=True
        )
        
        params = {p['Name']: p['Value'] for p in ssm_params['Parameters']}
        host = params.get('/lab1b/db/endpoint')
        port = params.get('/lab1b/db/port')
        db_name = params.get('/lab1b/db/name')
        
        # Get credentials from Secrets Manager
        secret_response = secrets.get_secret_value(SecretId='lab1b/rds/mysql')
        secret = json.loads(secret_response['SecretString'])
        
        return {
            'host': host,
            'port': int(port),
            'database': db_name,
            'user': secret['username'],
            'password': secret['password']
        }
        
    except Exception as e:
        logger.error(f"Failed to get DB config: {str(e)}")
        return None

def test_db_connection():
    """Test database connection and log result"""
    config = get_db_config()
    if not config:
        logger.error("No database configuration available")
        return False, "Configuration error"
    
    try:
        connection = mysql.connector.connect(
            host=config['host'],
            port=config['port'],
            user=config['user'],
            password=config['password'],
            database=config['database'],
            connection_timeout=5
        )
        
        cursor = connection.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        logger.info("Database connection successful")
        return True, "Connection successful"
        
    except mysql.connector.Error as e:
        error_msg = f"Database connection failed: {str(e)}"
        logger.error(error_msg)
        
        # Log to CloudWatch
        print(f"DB_CONNECTION_FAILURE: {datetime.utcnow().isoformat()} - {error_msg}")
        
        return False, error_msg
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        logger.error(error_msg)
        print(f"DB_CONNECTION_ERROR: {datetime.utcnow().isoformat()} - {error_msg}")
        return False, error_msg

@app.route('/')
def index():
    return jsonify({
        'status': 'running',
        'service': 'lab1b-app',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/health')
def health():
    db_ok, db_message = test_db_connection()
    
    status = 'healthy' if db_ok else 'unhealthy'
    http_code = 200 if db_ok else 503
    
    return jsonify({
        'status': status,
        'database': db_message,
        'timestamp': datetime.utcnow().isoformat()
    }), http_code

@app.route('/config')
def config():
    config = get_db_config()
    if config:
        # Don't expose password
        safe_config = config.copy()
        safe_config['password'] = '***REDACTED***'
        return jsonify(safe_config)
    return jsonify({'error': 'Configuration not available'}), 500

@app.route('/list')
def list_data():
    """List sample data from database"""
    config = get_db_config()
    if not config:
        return jsonify({'error': 'Database configuration not available'}), 500
    
    try:
        connection = mysql.connector.connect(
            host=config['host'],
            port=config['port'],
            user=config['user'],
            password=config['password'],
            database=config['database']
        )
        
        cursor = connection.cursor(dictionary=True)
        
        # Create sample table if it doesn't exist
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sample_data (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100),
                value VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Insert sample data if empty
        cursor.execute("SELECT COUNT(*) as count FROM sample_data")
        if cursor.fetchone()['count'] == 0:
            cursor.execute("""
                INSERT INTO sample_data (name, value) VALUES
                ('Server', 'lab1b-app'),
                ('Environment', 'demo'),
                ('Status', 'active')
            """)
            connection.commit()
        
        # Fetch all data
        cursor.execute("SELECT * FROM sample_data ORDER BY created_at DESC")
        results = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'items': results,
            'count': len(results)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.3
mysql-connector-python==8.1.0
pymysql==1.1.0
boto3==1.28.57
botocore==1.31.57
EOF

# Create systemd service
cat > /etc/systemd/system/lab1b-app.service << EOF
[Unit]
Description=Lab 1b Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lab1b-app
Environment="PYTHONPATH=/opt/lab1b-app"
ExecStart=/usr/bin/python3 /opt/lab1b-app/app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Setup Python environment - install globally to avoid virtual env issues
pip3 install --upgrade pip
pip3 install -r requirements.txt

# Create database table script
cat > init_db.py << 'EOF'
import mysql.connector
import boto3
import json

session = boto3.session.Session(region_name='${region}')
secrets = session.client('secretsmanager')
ssm = session.client('ssm')

# Get config
ssm_params = ssm.get_parameters(
    Names=[
        '/lab1b/db/endpoint',
        '/lab1b/db/port',
        '/lab1b/db/name'
    ],
    WithDecryption=True
)

params = {p['Name']: p['Value'] for p in ssm_params['Parameters']}
host = params['/lab1b/db/endpoint'].split(':')[0]  # Remove port
port = params['/lab1b/db/port']
db_name = params['/lab1b/db/name']

secret_response = secrets.get_secret_value(SecretId='lab1b/rds/mysql')
secret = json.loads(secret_response['SecretString'])

# Connect and create table
conn = mysql.connector.connect(
    host=host,
    port=int(port),
    user=secret['username'],
    password=secret['password']
)

cursor = conn.cursor()
cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_name}")
cursor.execute(f"USE {db_name}")

cursor.execute("""
    CREATE TABLE IF NOT EXISTS sample_data (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        value VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
""")

conn.commit()
cursor.close()
conn.close()
print("Database initialized successfully")
EOF

# Wait for instance metadata service and AWS CLI to be ready
sleep 30

# Initialize database
source venv/bin/activate
python3 init_db.py

# Start application
systemctl daemon-reload
systemctl enable lab1b-app
systemctl start lab1b-app

# Enable CloudWatch Agent for logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/syslog",
                        "log_group_name": "/aws/ec2/lab1b-app",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/opt/lab1b-app/app.log",
                        "log_group_name": "/aws/ec2/lab1b-app",
                        "log_stream_name": "application",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

echo "Setup complete! Application running on port 8080"
EOF