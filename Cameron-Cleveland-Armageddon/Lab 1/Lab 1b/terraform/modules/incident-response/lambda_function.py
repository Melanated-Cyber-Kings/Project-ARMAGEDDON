import json
import boto3
import os
import logging
from datetime import datetime

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """Handle CloudWatch Alarm events for database connectivity failures"""
    
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Extract alarm information
    try:
        alarm_name = event.get('detail', {}).get('alarmName', '')
        alarm_state = event.get('detail', {}).get('state', {}).get('value', '')
        
        logger.info(f"Alarm: {alarm_name}, State: {alarm_state}")
        
        if 'db-connection-failure' in alarm_name.lower() and alarm_state == 'ALARM':
            logger.info("Database connection failure detected. Initiating recovery...")
            
            # 1. Get database configuration from Parameter Store
            ssm = boto3.client('ssm')
            params = ssm.get_parameters(
                Names=[
                    '/lab1b/db/endpoint',
                    '/lab1b/db/port',
                    '/lab1b/db/name'
                ],
                WithDecryption=True
            )
            
            param_dict = {p['Name']: p['Value'] for p in params['Parameters']}
            logger.info(f"Retrieved parameters: {list(param_dict.keys())}")
            
            # 2. Get credentials from Secrets Manager
            secrets = boto3.client('secretsmanager')
            secret_response = secrets.get_secret_value(SecretId='my-lab1b/rds/mysql')
            secret = json.loads(secret_response['SecretString'])
            
            # 3. Check RDS instance status
            rds = boto3.client('rds')
            db_instance_id = os.environ.get('DB_INSTANCE_ID')
            
            instance_info = rds.describe_db_instances(DBInstanceIdentifier=db_instance_id)
            instance = instance_info['DBInstances'][0]
            
            db_status = instance['DBInstanceStatus']
            db_endpoint = instance['Endpoint']['Address']
            
            logger.info(f"RDS Status: {db_status}, Endpoint: {db_endpoint}")
            
            # 4. Take recovery action based on status
            recovery_action = None
            
            if db_status == 'available':
                logger.info("Database is available but connections failing. Rebooting...")
                rds.reboot_db_instance(DBInstanceIdentifier=db_instance_id)
                recovery_action = "REBOOT"
                
            elif db_status in ['stopped', 'stopping']:
                logger.info("Database is stopped. Starting...")
                rds.start_db_instance(DBInstanceIdentifier=db_instance_id)
                recovery_action = "START"
                
            else:
                logger.info(f"Database status: {db_status}. No recovery action taken.")
                recovery_action = "NONE"
            
            # 5. Send notification
            sns = boto3.client('sns')
            
            message = {
                "timestamp": datetime.utcnow().isoformat(),
                "alarm": alarm_name,
                "alarm_state": alarm_state,
                "db_instance_id": db_instance_id,
                "db_status": db_status,
                "recovery_action": recovery_action,
                "recovery_time": datetime.utcnow().isoformat(),
                "message": f"Database connectivity failure detected and recovery action '{recovery_action}' initiated"
            }
            
            # Publish to SNS topic (topic ARN is in event)
            if 'topicArn' in event.get('detail', {}):
                sns.publish(
                    TopicArn=event['detail']['topicArn'],
                    Subject=f"DB Recovery: {recovery_action} for {db_instance_id}",
                    Message=json.dumps(message, indent=2)
                )
            
            return {
                'statusCode': 200,
                'body': json.dumps(message)
            }
        
        else:
            logger.info(f"No action needed for alarm: {alarm_name}, state: {alarm_state}")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No action taken'})
            }
            
    except Exception as e:
        logger.error(f"Error in incident response: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
