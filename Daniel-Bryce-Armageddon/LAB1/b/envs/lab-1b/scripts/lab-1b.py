#Add to your app.py or create new monitoring module
import logging
import boto3
from botocore.exceptions import ClientError
import time

#Setup CloudWatch Logs
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(name)

#CloudWatch client for custom metrics
cloudwatch = boto3.client('cloudwatch')

class DatabaseMonitor:
    def init(self):
        self.error_count = 0

    def log_db_error(self, error_message):
        """Log DB error and emit metric"""
        # Log to CloudWatch (via systemd/journald if using CloudWatch agent)
        logger.error(f"DB Connection Error: {error_message}")

#Emit custom metric
        try:
            cloudwatch.put_metric_data(
                Namespace='Lab/RDSApp',
                MetricData=[{
                    'MetricName': 'DBConnectionErrors',
                    'Value': 1,
                    'Timestamp': time.time(),
                    'Unit': 'Count'
                }]
            )
        except Exception as e:
            logger.error(f"Failed to emit metric: {e}")

#In your DB connection function, wrap with monitoring
def connect_to_database():
    monitor = DatabaseMonitor()
    try:
        # Your existing connection code
        # connection = pymysql.connect(...)
        return connection
    except Exception as e:
        monitor.log_db_error(str(e))
        raise