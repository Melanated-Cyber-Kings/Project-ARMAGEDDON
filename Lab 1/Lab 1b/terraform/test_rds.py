import mysql.connector
import boto3
import json

session = boto3.session.Session(region_name='ap-northeast-1')
ssm = session.client('ssm')
secrets = session.client('secretsmanager')

# Get SSM parameters
params = ssm.get_parameters(
    Names=['/lab1b/db/endpoint', '/lab1b/db/port', '/lab1b/db/name'],
    WithDecryption=True
)

param_dict = {p['Name']: p['Value'] for p in params['Parameters']}
host = param_dict['/lab1b/db/endpoint']
port = param_dict['/lab1b/db/port']
db_name = param_dict['/lab1b/db/name']

print('Host:', host)
print('Port:', port)
print('DB:', db_name)

# Get secret
secret = secrets.get_secret_value(SecretId='my-lab1b/rds/mysql')
secret_dict = json.loads(secret['SecretString'])
print('User:', secret_dict['username'])

# Try connection
try:
    conn = mysql.connector.connect(
        host=host,
        port=int(port),
        user=secret_dict['username'],
        password=secret_dict['password'],
        database=db_name,
        connection_timeout=5
    )
    print('SUCCESS: RDS Connection OK!')
    conn.close()
except Exception as e:
    print('ERROR: RDS Connection FAILED:', str(e))
