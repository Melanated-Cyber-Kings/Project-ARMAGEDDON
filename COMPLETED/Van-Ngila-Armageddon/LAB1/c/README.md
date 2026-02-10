# Lab 1C — Infrastructure as Code: EC2 → RDS with Secrets, Observability, and Incident Alerts

## 📋 Project Description

This project implements a complete AWS infrastructure using Terraform (Infrastructure as Code) to deploy a Flask application that communicates with an RDS MySQL database. The architecture integrates secure secret management, observability via CloudWatch, and an incident alerting system.

## 🎯 Objectives

The goal is to demonstrate modern enterprise best practices:
- **Infrastructure as Code**: Reproducible, auditable, and recoverable environments
- **Security**: Secret management via Secrets Manager, restrictive IAM policies
- **Observability**: CloudWatch logs, metrics, and alerts
- **High Availability**: Secure network architecture with NAT Gateway

## 👨‍💻 Author
**Vany Ferrand** - Cloud Infrastructure Engineer

## 🏗️ Architecture

### Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                            VPC (172.17.0.0/16)                      │
│                                                                     │
│  ┌─────────────┐      ┌──────────────┐      ┌─────────────────┐    │
│  │   Subnet    │      │   Subnet     │      │    Subnet       │    │
│  │   Public    │      │   Private A  │      │    Private B    │    │
│  │  172.17.1.0/24│     │ 172.17.11.0/24 │    │ 172.17.21.0/24  │    │
│  │             │      │              │      │                 │    │
│  │  ┌──────┐   │      │  ┌──────┐    │      │  ┌──────────┐   │    │
│  │  │ NAT  │   │      │  │ EC2  │    │      │  │   RDS    │   │    │
│  │  │Gateway│  │      │  │ App  │────┼─────▶│  │  MySQL   │   │    │
│  │  └──────┘   │      │  └──────┘    │      │  └──────────┘   │    │
│  │      │      │      │       │      │      │        │        │    │
│  └──────┼──────┘      └───────┼──────┘      └────────┼────────┘    │
│         │                     │                      │             │
│  ┌──────▼──────┐      ┌──────▼──────┐               │             │
│  │  Internet   │      │  AWS        │               │             │
│  │   Gateway   │      │  Services   │◀──────────────┘             │
│  └─────────────┘      │  (SSM, CW,  │                             │
│                       │   Secrets)  │                             │
│                       └─────────────┘                             │
└─────────────────────────────────────────────────────────────────────┘
```

### Core Components

1. **Network (VPC)**:
   - VPC with CIDR 172.17.0.0/16
   - 1 public subnet (NAT Gateway)
   - 2 private subnets (EC2 and RDS)
   - Internet Gateway and NAT Gateway
   - Associated route tables

2. **Security**:
   - Security Groups for EC2 and RDS
   - Restrictive traffic rules
   - IAM role with least-privilege policies

3. **Compute (EC2)**:
   - Amazon Linux 2023 instance
   - Flask application + MySQL Connector
   - IAM Instance Profile
   - User Data for automatic configuration

4. **Database (RDS)**:
   - Multi-AZ MySQL instance
   - DB Subnet Group
   - Automated backups
   - Enhanced monitoring

5. **Configuration and Secrets**:
   - SSM Parameter Store (/lab/db/*)
   - Secrets Manager (RDS credentials)
   - KMS for encryption

6. **Observability (CloudWatch)**:
   - Log Group for the application
   - Custom metrics
   - Connection error alarms
   - SNS Topic for notifications

## 📁 Project Structure

```
terraform-lab-1c/
├── main.tf                    # Main configuration
├── variables.tf              # Input variables
├── terraform.tfvars          # Variable values
├── outputs.tf               # Terraform outputs
├── modules/
│   ├── network/             # VPC, subnets, routing
│   ├── security/            # Security Groups
│   ├── iam/                 # IAM roles and policies
│   ├── ec2/                 # EC2 instance
│   ├── rds/                 # MySQL database
│   ├── config-store/        # SSM + Secrets Manager
│   └── cloudwatch/          # Monitoring and alerts
└── README.md               # This documentation
```

## 🚀 Deployment

### Prerequisites

1. **Configured AWS CLI** with valid credentials
2. **Terraform 1.0+** installed
3. **AWS access** with sufficient permissions

### Initialization

```bash
terraform init
```

### Planning

```bash
terraform plan -var-file="terraform.tfvars"
```

### Deployment

```bash
terraform apply -var-file="terraform.tfvars"
```

### Expected Output

```bash
Apply complete! Resources: XX added, 0 changed, 0 destroyed.

Outputs:

address = "lab-mysql.xxxxxx.ap-northeast-1.rds.amazonaws.com"
iam_instance_profile_name = "armageddon-lab-1c-ec2-secrets-profile"
private_subnet_id = "subnet-xxxxxx"
public_subnet_id = "subnet-xxxxxx"
vpc_id = "vpc-xxxxxx"
```

## 🔧 Configuration

### Main Variables (`terraform.tfvars`)

```terraform
region = "ap-northeast-1"
env_prefix = "lab-1c"
project = "Armageddon"

vpc_cidr_block = "172.17.0.0/16"
public_subnet_cidr = "172.17.1.0/24"
private_subnet_cidr_1 = "172.17.11.0/24"
private_subnet_cidr_2 = "172.17.21.0/24"

instance_type = "t3.micro"
db_name = "labdb"
db_username = "admin"
db_password = "secure_password"

alert_email = "admin@example.com"
```

### Flask Application

The application included in the EC2 user data:
- Framework: Flask
- Database: MySQL via PyMySQL
- Endpoints:
  - `/` : Home page
  - `/init` : Database initialization
  - `/add?note=text` : Add note
  - `/list` : List notes
  - `/health` : Health check

## 📊 Monitoring and Alerts

### Monitored Metrics

1. **RDS Connection Errors**:
   - Filter: `"ERROR"` in application logs
   - Alarm: ≥3 errors in 5 minutes
   - Action: SNS notification

2. **Application Logs**:
   - Group: `/aws/ec2/lab-rds-app`
   - Retention: 30 days

### Notifications

- **SNS Topic**: `lab-db-incidents`
- **Subscription**: Email
- **Alert Threshold**: 3 errors/5min

## 🔒 Security

### IAM - Least Privilege Principle

```terraform
# EC2 Policy (example)
Action = [
  "ec2:Describe*",
  "ssm:GetParameter",
  "secretsmanager:GetSecretValue",
  "logs:CreateLogGroup",
  "logs:CreateLogStream",
  "logs:PutLogEvents"
]
Resource = [
  "arn:aws:ssm:${var.region}:${var.account_id}:parameter/lab/db/*",
  "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:lab/rds/mysql*"
]
```

### Encryption

- **RDS**: Encrypted storage
- **Secrets Manager**: KMS encryption
- **SSM Parameters**: Standard encryption

## 🧪 Testing and Verification

### Automated Tests

```bash
# 1. Verify EC2 → RDS connection
aws ssm start-session --target i-xxxxxx
curl http://localhost/health

# 2. Test application endpoints
curl http://localhost/init
curl "http://localhost/add?note=test"
curl http://localhost/list

# 3. Check CloudWatch logs
aws logs describe-log-streams --log-group-name /aws/ec2/lab-rds-app

# 4. Verify secrets
aws secretsmanager get-secret-value --secret-id lab/rds/mysql
aws ssm get-parameter --name /lab/db/endpoint
```

### Incident Runbook

**Scenario**: "DB Connection Errors" alarm triggered

**Actions**:
1. Check CloudWatch logs
2. Test EC2 → RDS connectivity
3. Verify RDS instance status
4. Examine Security Groups
5. Restart application if necessary

## 📈 Deployment Results

### Resource Summary

| Service | Quantity | Examples |
|---------|----------|----------|
| VPC | 1 | vpc-02384a36084855975 |
| Subnets | 3 | subnet-08da0ae7c50dae200 |
| EC2 Instance | 1 | i-05f740a6401a1b866 |
| RDS Instance | 1 | db-OLAR37F3DBAVKZBLXQSQJ2QNVA |
| Security Groups | 2 | sg-027ff2d7974b65170 |
| IAM Roles | 1 | armageddon-lab-1c-ec2-secrets-role |
| SSM Parameters | 4 | /lab/db/endpoint |
| CloudWatch Alarms | 1 | lab-db-connection-failure |

### Deployment Time
- **Total**: ~15 minutes
- **RDS (longest)**: ~11 minutes
- **NAT Gateway**: ~1 minute 38 seconds
- **EC2**: ~17 seconds

## 🐛 Troubleshooting

### Common Issues

1. **NAT Gateway Timeout**:
   - Wait additional 2-3 minutes
   - Check AWS service limits

2. **RDS Connection Failed**:
   ```bash
   # Check Security Groups
   aws ec2 describe-security-groups --group-ids sg-xxxxxx
   
   # Test from EC2
   mysql -h lab-mysql.xxxxxx.rds.amazonaws.com -u admin -p
   ```

3. **Missing CloudWatch Logs**:
   - Verify IAM permissions
   - Wait 2-5 minutes for ingestion

### Useful Commands

```bash
# Resource state
terraform state list
terraform show

# Destroy environment
terraform destroy -var-file="terraform.tfvars"

# Outputs
terraform output
terraform output vpc_id
```

## 📚 Implemented Best Practices

### Infrastructure as Code
- ✅ Reusable modules
- ✅ Git versioning
- ✅ Complete documentation
- ✅ Parameterizable variables

### Security
- ✅ Least privilege IAM
- ✅ Encrypted secrets
- ✅ Network isolation
- ✅ Restrictive Security Groups

### Observability
- ✅ Centralized logs
- ✅ Custom metrics
- ✅ Proactive alerts
- ✅ Health checks

### Resilience
- ✅ Multi-AZ for RDS
- ✅ Automated backups
- ✅ EC2 auto-recovery
- ✅ 24/7 monitoring

## 🔮 Future Improvements

1. **CI/CD Pipeline**:
   - Terraform with Atlantis or Terraform Cloud
   - Automated testing with Terratest

2. **High Availability**:
   - Auto Scaling Group for EC2
   - RDS Read Replicas
   - Application Load Balancer

3. **Advanced Security**:
   - WAF for the application
   - GuardDuty for detection
   - Config Rules for compliance

4. **Monitoring**:
   - CloudWatch Dashboard
   - Advanced custom metrics
   - Slack/SMS integration

## 📞 Support and Documentation

### References
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Best Practices](https://aws.amazon.com/architecture/well-architected/)
- [RDS MySQL Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html)

### Author
**Vany Ferrand** - Project developed as part of Lab 1C


---

**🚀 Deployment Successful** - The infrastructure is operational with all required components functional and secure.