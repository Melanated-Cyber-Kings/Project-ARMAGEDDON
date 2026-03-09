############################################
# Locals 
############################################
locals {
  name_prefix = var.project_name
}

############################################
# VPC + Internet Gateway
############################################

# Network VPC 
resource "aws_vpc" "lab1_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}

# Explanation: Needed to allow users in to access the app on the EC2 from the internet.
resource "aws_internet_gateway" "igw01" {
  vpc_id = aws_vpc.lab1_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation: Public subnets are like docking bays—ships can land directly from space (internet).
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.lab1_vpc01.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet0${0 + 1}"
  }
}

# Explanation: Private subnets for defence in depth.
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.lab1_vpc01.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet0${0 + 1}"
  }
}

############################################
# NAT Gateway + EIP : No need for an NAT GW as this RDS in the Private subnet does not need outbound internet access.
############################################

# # Explanation: Chewbacca wants the private base to call home—EIP gives the NAT a stable “holonet address.”
# resource "aws_eip" "chewbacca_nat_eip01" {
#   domain = "vpc"

#   tags = {
#     Name = "${local.name_prefix}-nat-eip01"
#   }
# }

# # Explanation: NAT is Chewbacca’s smuggler tunnel—private subnets can reach out without being seen.
# resource "aws_nat_gateway" "chewbacca_nat01" {
#   allocation_id = aws_eip.chewbacca_nat_eip01.id
#   subnet_id     = aws_subnet.chewbacca_public_subnets[0].id # NAT in a public subnet

#   tags = {
#     Name = "${local.name_prefix}-nat01"
#   }

#   depends_on = [aws_internet_gateway.chewbacca_igw01]
# }

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table = “open lanes” to the galaxy via IGW.
resource "aws_route_table" "lab1_public_rt01" {
  vpc_id = aws_vpc.lab1_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

# Explanation: This route is the Kessel Run—0.0.0.0/0 goes out the IGW.
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.lab1_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw01.id
}

# Explanation: Attach public subnets to the “public lanes.”
resource "aws_route_table_association" "lab1_public_rta" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.lab1_public_rt01.id
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "private_rt01" {
  vpc_id = aws_vpc.lab1_vpc01.id
  
  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

# # Explanation: Private subnets route outbound internet via NAT. This Private network doesn't need a route as only Hosting RDS that is stateful.
# resource "aws_route" "private_default_route" {
#   route_table_id         = aws_route_table.private_rt01.id
#   destination_cidr_block = "172.17.0.0/0"
# # nat_gateway_id         = aws_nat_gateway.chewbacca_nat01.id
# }

# Explanation: Attach private subnets to the “stealth lanes.”
resource "aws_route_table_association" "private_rta" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt01.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

# Explanation: EC2 SG is Chewbacca’s bodyguard—only let in what you mean to.
resource "aws_security_group" "ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.lab1_vpc01.id


  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}
 # TODO: student adds inbound rules (HTTP 80, SSH 22 from their IP)

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.ec2_sg01.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ec2_sg01.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

 # TODO: student ensures outbound allows DB port to RDS SG (or allow all outbound)
# resource "aws_vpc_security_group_egress_rule" "allow_to_rds" {
#   security_group_id = aws_security_group.ec2_sg01.id

#   referenced_security_group_id  = aws_security_group.rds_sg01.id
#   from_port   = 3306
#   ip_protocol = "tcp"
#   to_port     = 3306
# }

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.ec2_sg01.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1" # semantically equivalent to all ports
}



# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.lab1_vpc01.id

  # TODO: student adds inbound MySQL 3306 from aws_security_group ec2_sg01.id

  tags = {
    Name = "${local.name_prefix}-rds-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql_from_ec2" {
  security_group_id = aws_security_group.rds_sg01.id
  referenced_security_group_id  = aws_security_group.ec2_sg01.id
  from_port   = 3306
  ip_protocol = "tcp"
  to_port     = 3306
}


############################################
# RDS Subnet Group
############################################

# Explanation: RDS hides in private subnets like the Rebel base on Hoth—cold, quiet, and not public.
resource "aws_db_subnet_group" "rds_subnet_group01" {
  name       = "${local.name_prefix}-rds-subnet-group01"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnet-group01"
  }
}

############################################
# RDS Instance (MySQL)
############################################

# Explanation: This is the holocron of state—your relational data lives here, not on the EC2.
resource "aws_db_instance" "rds01" {
  identifier             = "${local.name_prefix}-rds01"
  #identifier             = "armageddon-class7-rds01"
  engine                 = var.db_engine
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group01.name
  vpc_security_group_ids = [aws_security_group.rds_sg01.id]

  publicly_accessible    = false
  skip_final_snapshot    = true

  # TODO: student sets multi_az / backups / monitoring as stretch goals

  tags = {
    Name = "${local.name_prefix}-rds01"
  }
}

############################################
# IAM Role + Instance Profile for EC2
############################################

# Explanation: this role lets EC2 assume permissions safely.
resource "aws_iam_role" "ec2_role01" {
  name = "${local.name_prefix}-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Explanation: These policies are allowing Session Manger access to EC2.
resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_role01.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
resource "aws_iam_role_policy_attachment" "ec2_secrets_attach" {
  role      = aws_iam_role.ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # TODO: student replaces w/ least privilege
}

# Explanation: CloudWatch logs
resource "aws_iam_role_policy_attachment" "ec2_cw_attach" {
  role      = aws_iam_role.ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}



# Explanation: Instance profile 
resource "aws_iam_instance_profile" "instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.ec2_role01.name
}

# ############################################
# # EC2 Instance (App Host)
# ############################################

# Explanation: app layer to DB Layer.
resource "aws_instance" "ec201" {
  ami                    = var.ec2_ami_id
  instance_type           = var.ec2_instance_type
  subnet_id               = aws_subnet.public_subnets[0].id
  vpc_security_group_ids  = [aws_security_group.ec2_sg01.id]
  iam_instance_profile    = aws_iam_instance_profile.instance_profile01.name
  user_data_replace_on_change = true

  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  # user_data = file("${path.module}/user_data.sh")
  user_data = file("user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec201"
  }
}

# ############################################
# # Parameter Store (SSM Parameters)
# ############################################

# Explanation: Parameter Store  and config live here for fast recovery.
resource "aws_ssm_parameter" "db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.rds01.address
  description = "RDS endpoint"
  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

# # Explanation: Ports.
resource "aws_ssm_parameter" "db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.rds01.port)
  description = "RDS port"
  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

# Explanation: Data Base Layer.
resource "aws_ssm_parameter" "db_name_param" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name
  description = "RDS name"

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

# ############################################
# # Secrets Manager (DB Credentials)
# ############################################

# Explanation: Secrets Manager 
resource "aws_secretsmanager_secret" "db_secret01" {
  name = var.secret_name
  recovery_window_in_days = 0
}

# resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
#   secret_id           = aws_secretsmanager_secret.rds_secret.id
#   rotation_lambda_arn = "arn:aws:lambda:"

#   rotation_rules {
#     automatically_after_days = 30
#   }
# }

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "db_secret_version01" {
  secret_id = aws_secretsmanager_secret.db_secret01.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.rds01.address
    port     = aws_db_instance.rds01.port
    dbname   = var.db_name
  })
}




# ############################################
# # CloudWatch Logs (Log Group)
# ############################################

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "applog_group01" {
  name              = "/aws/ec2/${local.name_prefix}-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-applog-group01"
  }
}

# ############################################
# # Custom Metric + Alarm (Skeleton)
# ############################################

# Explanation: Metrics.
# NOTE: Emit the metric from app/agent; this just declares the alarm.
# resource "aws_cloudwatch_metric_alarm" "db_alarm01" {
#   alarm_name          = "${local.name_prefix}-db-connection-failure"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 1
#   metric_name         = "DBConnectionErrors"
#   namespace           = "AWS/RDS"#"Lab/RDSApp"
#   period              = 300
#   statistic           = "Sum"
#   threshold           = 3

#   alarm_actions       = [aws_sns_topic.sns_topic01.arn]

#  # We'll add dimensions after creating the metric filter
#   dimensions = {
#     #LogGroupName = aws_cloudwatch_log_group.app_logs.name
#     DBInstanceIdentifier = aws_db_instance.rds01.identifier
#   }
  
#   tags = {
#     Name = "${local.name_prefix}-alarm-db-fail"
#   }
# }


# resource "aws_cloudwatch_metric_alarm" "db_alarm01" {
#   alarm_name          = "${local.name_prefix}-db-connection-failure"
#   alarm_description   = "RDS connection"
#   comparison_operator = "GreaterThanUpperThreshold"

#   evaluation_periods  = 2
#   datapoints_to_alarm = 2
#   threshold           = 0
#   threshold_metric_id = "ad1"

#   treat_missing_data  = "breaching"
#   actions_enabled     = true

#   alarm_actions = [aws_sns_topic.sns_topic01.arn]

#   metric_query {
#     id          = "m1"
#     return_data = true

#     metric {
#       namespace   = "AWS/RDS"
#       metric_name = "DatabaseConnections"
#       stat        = "Average"
#       period      = 60

#       dimensions = {
#         DBInstanceIdentifier = "armageddon-class-vii-rds01"
#       }
#     }
#   }

#   metric_query {
#     id          = "ad1"
#     expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
#     label       = "DatabaseConnections (expected)"
#     return_data = true
#   }
# }

resource "aws_cloudwatch_metric_alarm" "db_alarm01" {
  actions_enabled     = true
  alarm_actions = [aws_sns_topic.sns_topic01.arn]  
  alarm_description   = "RDS connection Error"
  alarm_name          = "db_alarm_01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds01.identifier
  }
  evaluation_periods        = 1
  extended_statistic        = null
  insufficient_data_actions = []
  metric_name               = "DatabaseConnectionsErrors"
  namespace                 = "Lab/RDSapp"
  ok_actions                = []
  period                    = 300   
  region                    = "us-east-1"
  statistic                 = "Sum"
  tags                      = {}
  tags_all                  = {}
  threshold                 = 3
  threshold_metric_id       = null
  treat_missing_data        = "notBreaching"
  unit                      = null
}

############
#lookup from prototype
###########
# resource "aws_cloudwatch_log_metric_filter" "db_errors" {
#   name           = "DBConnectionErrors"
#   pattern        = "CRITICAL"
#   log_group_name = aws_cloudwatch_log_group.app_logs.name

#   metric_transformation {
#     name      = "DBConnectionErrors"
#     namespace = "Lab/RDSApp"
#     value     = "1"
#   }
# }
############


# {
#     "Type": "AWS::CloudWatch::Alarm",
#     "Properties": {
#         "AlarmName": "test alarm",
#         "AlarmDescription": "RDS connection",
#         "Tags": [],
#         "ActionsEnabled": true,
#         "OKActions": [],
#         "AlarmActions": [
#             "arn:aws:sns:us-east-1:420228061920:armageddon-class-vii-db-incidents"
#         ],
#         "InsufficientDataActions": [],
#         "Dimensions": [],
#         "EvaluationPeriods": 2,
#         "DatapointsToAlarm": 2,
#         "ThresholdMetricId": "ad1",
#         "ComparisonOperator": "GreaterThanUpperThreshold",
#         "TreatMissingData": "breaching",
#         "Metrics": [
#             {
#                 "Id": "m1",
#                 "ReturnData": true,
#                 "MetricStat": {
#                     "Metric": {
#                         "Namespace": "AWS/RDS",
#                         "MetricName": "DatabaseConnections",
#                         "Dimensions": [
#                             {
#                                 "Name": "DBInstanceIdentifier",
#                                 "Value": "armageddon-class-vii-rds01"
#                             }
#                         ]
#                     },
#                     "Period": 60,
#                     "Stat": "Average"
#                 }
#             },
#             {
#                 "Id": "ad1",
#                 "Label": "DatabaseConnections (expected)",
#                 "ReturnData": true,
#                 "Expression": "ANOMALY_DETECTION_BAND(m1, 2)"
#             }
#         ]
#     }
# }





# ############################################
# # SNS (Notification simulation)
# ############################################

# Explanation: SNS notification
resource "aws_sns_topic" "sns_topic01" {
  name = "${local.name_prefix}-db-incidents"
}

# Explanation: Email subscription
resource "aws_sns_topic_subscription" "sns_sub01" {
  topic_arn = aws_sns_topic.sns_topic01.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

# ############################################
# # (Optional but realistic) VPC Endpoints (Skeleton)
# ############################################

# # Explanation: Endpoints keep traffic inside AWS like hyperspace lanes—less exposure, more control.
# # TODO: students can add endpoints for SSM, Logs, Secrets Manager if doing “no public egress” variant.
# # resource "aws_vpc_endpoint" "vpce_ssm" { ... }