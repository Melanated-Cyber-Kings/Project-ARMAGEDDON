# Lab 1b: Operations, Secrets, and Incident Response

## Architecture
- EC2 Instance (Python Flask App)
- RDS MySQL Database
- SSM Parameter Store (DB config)
- Secrets Manager (DB credentials)
- CloudWatch Logs & Alarms
- Lambda Incident Response
- SNS Notifications

## Deployment

### 1. Setup Environment
```bash
chmod +x scripts/*.sh
source scripts/setup.sh
