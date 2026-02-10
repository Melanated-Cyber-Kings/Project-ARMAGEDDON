# ############################################
# # Locals & Provider Configuration
# ############################################
# locals {
#   name_prefix = var.project_name
# }

# ############################################
# # VPC & Networking
# ############################################

# resource "aws_vpc" "chewbacca_vpc01" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "${local.name_prefix}-vpc01"
#   }
# }

# resource "aws_internet_gateway" "chewbacca_igw01" {
#   vpc_id = aws_vpc.chewbacca_vpc01.id

#   tags = {
#     Name = "${local.name_prefix}-igw01"
#   }
# }

# resource "aws_subnet" "chewbacca_public_subnets" {
#   count                   = length(var.public_subnet_cidrs)
#   vpc_id                  = aws_vpc.chewbacca_vpc01.id
#   cidr_block              = var.public_subnet_cidrs[count.index]
#   availability_zone       = var.azs[count.index]
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
#   }
# }

# resource "aws_subnet" "chewbacca_private_subnets" {
#   count             = length(var.private_subnet_cidrs)
#   vpc_id            = aws_vpc.chewbacca_vpc01.id
#   cidr_block        = var.private_subnet_cidrs[count.index]
#   availability_zone = var.azs[count.index]

#   tags = {
#     Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
#   }
# }

# ############################################
# # NAT Gateway (For Private Subnet Internet)
# ############################################

# resource "aws_eip" "chewbacca_nat_eip01" {
#   domain = "vpc"
#   tags   = { Name = "${local.name_prefix}-nat-eip01" }
# }

# resource "aws_nat_gateway" "chewbacca_nat01" {
#   allocation_id = aws_eip.chewbacca_nat_eip01.id
#   subnet_id     = aws_subnet.chewbacca_public_subnets[0].id

#   tags       = { Name = "${local.name_prefix}-nat01" }
#   depends_on = [aws_internet_gateway.chewbacca_igw01]
# }

# ############################################
# # Routing
# ############################################

# resource "aws_route_table" "chewbacca_public_rt01" {
#   vpc_id = aws_vpc.chewbacca_vpc01.id
#   tags   = { Name = "${local.name_prefix}-public-rt01" }
# }

# resource "aws_route" "chewbacca_public_default_route" {
#   route_table_id         = aws_route_table.chewbacca_public_rt01.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.chewbacca_igw01.id
# }

# resource "aws_route_table_association" "chewbacca_public_rta" {
#   count          = length(aws_subnet.chewbacca_public_subnets)
#   subnet_id      = aws_subnet.chewbacca_public_subnets[count.index].id
#   route_table_id = aws_route_table.chewbacca_public_rt01.id
# }

# resource "aws_route_table" "chewbacca_private_rt01" {
#   vpc_id = aws_vpc.chewbacca_vpc01.id
#   tags   = { Name = "${local.name_prefix}-private-rt01" }
# }

# resource "aws_route" "chewbacca_private_default_route" {
#   route_table_id         = aws_route_table.chewbacca_private_rt01.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.chewbacca_nat01.id
# }

# resource "aws_route_table_association" "chewbacca_private_rta" {
#   count          = length(aws_subnet.chewbacca_private_subnets)
#   subnet_id      = aws_subnet.chewbacca_private_subnets[count.index].id
#   route_table_id = aws_route_table.chewbacca_private_rt01.id
# }

# ############################################
# # Security Groups
# ############################################

# resource "aws_security_group" "chewbacca_ec2_sg01" {
#   name        = "${local.name_prefix}-ec2-sg01"
#   vpc_id      = aws_vpc.chewbacca_vpc01.id
#   tags        = { Name = "${local.name_prefix}-ec2-sg01" }
# }

# resource "aws_vpc_security_group_ingress_rule" "ec2_http" {
#   security_group_id = aws_security_group.chewbacca_ec2_sg01.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 80
#   to_port           = 80
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_egress_rule" "ec2_all_outbound" {
#   security_group_id = aws_security_group.chewbacca_ec2_sg01.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"
# }

# resource "aws_security_group" "chewbacca_rds_sg01" {
#   name   = "${local.name_prefix}-rds-sg01"
#   vpc_id = aws_vpc.chewbacca_vpc01.id
#   tags   = { Name = "${local.name_prefix}-rds-sg01" }
# }

# resource "aws_vpc_security_group_ingress_rule" "rds_mysql" {
#   security_group_id            = aws_security_group.chewbacca_rds_sg01.id
#   referenced_security_group_id = aws_security_group.chewbacca_ec2_sg01.id
#   from_port                    = 3306
#   to_port                      = 3306
#   ip_protocol                  = "tcp"
# }

# ############################################
# # RDS Database
# ############################################

# resource "aws_db_subnet_group" "chewbacca_rds_subnet_group01" {
#   name       = "${local.name_prefix}-rds-subnet-group01"
#   subnet_ids = aws_subnet.chewbacca_private_subnets[*].id
# }

# resource "aws_db_instance" "chewbacca_rds01" {
#   identifier              = "${local.name_prefix}-rds01"
#   engine                  = var.db_engine
#   instance_class          = var.db_instance_class
#   allocated_storage       = 20
#   db_name                 = var.db_name
#   username                = var.db_username
#   password                = var.db_password
#   db_subnet_group_name    = aws_db_subnet_group.chewbacca_rds_subnet_group01.name
#   vpc_security_group_ids  = [aws_security_group.chewbacca_rds_sg01.id]
#   publicly_accessible     = false
#   skip_final_snapshot     = true
#   multi_az                = true
#   backup_retention_period = 1
#   tags                    = { Name = "${local.name_prefix}-rds01" }
# }

# ############################################
# # IAM Role & EC2 Instance
# ############################################

# resource "aws_iam_role" "chewbacca_ec2_role01" {
#   name = "${local.name_prefix}-ec2-role01"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ssm" {
#   role       = aws_iam_role.chewbacca_ec2_role01.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_role_policy_attachment" "secrets" {
#   role       = aws_iam_role.chewbacca_ec2_role01.name
#   policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
# }

# resource "aws_iam_role_policy_attachment" "cw" {
#   role       = aws_iam_role.chewbacca_ec2_role01.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }

# resource "aws_iam_instance_profile" "chewbacca_instance_profile01" {
#   name = "${local.name_prefix}-instance-profile01"
#   role = aws_iam_role.chewbacca_ec2_role01.name
# }

# # THE FIXED EC2 RESOURCE
# resource "aws_instance" "chewbacca_ec201_private_bonus" {
#   ami                    = var.ec2_ami_id
#   instance_type          = var.ec2_instance_type
#   subnet_id              = aws_subnet.chewbacca_private_subnets[0].id
#   vpc_security_group_ids = [aws_security_group.chewbacca_ec2_sg01.id]
#   iam_instance_profile   = aws_iam_instance_profile.chewbacca_instance_profile01.name

#   user_data = templatefile("${path.module}/user_data.sh", {
#     project_name = var.project_name
#     secret_id    = aws_secretsmanager_secret.chewbacca_db_secret01.name
#     region       = var.aws_region
#   })

#   tags = { Name = "${local.name_prefix}-ec201" }
# }

# ############################################
# # SSM & Secrets
# ############################################

# resource "aws_ssm_parameter" "db_endpoint" {
#   name      = "/lab/db/endpoint"
#   type      = "String"
#   value     = aws_db_instance.chewbacca_rds01.address
#   overwrite = true
# }

# resource "aws_secretsmanager_secret" "chewbacca_db_secret01" {
#   name = "${local.name_prefix}/rds/mysql/v2" # Name change to avoid deletion conflicts
# }

# resource "aws_secretsmanager_secret_version" "val" {
#   secret_id = aws_secretsmanager_secret.chewbacca_db_secret01.id
#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password
#     host     = aws_db_instance.chewbacca_rds01.address
#     port     = aws_db_instance.chewbacca_rds01.port
#     dbname   = var.db_name
#   })
# }

# ############################################
# # CloudWatch & SNS
# ############################################

# resource "aws_cloudwatch_log_group" "chewbacca_log_group01" {
#   name              = "/aws/ec2/${local.name_prefix}-rds-app"
#   retention_in_days = 7
# }

# resource "aws_sns_topic" "chewbacca_sns_topic01" {
#   name = "${local.name_prefix}-db-incidents"
# }

# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.chewbacca_sns_topic01.arn
#   protocol  = "email"
#   endpoint  = var.sns_email_endpoint
# }

# ############################################
# # VPC Endpoints (Interface + Gateway)
# ############################################

# resource "aws_security_group" "endpoints_sg" {
#   name   = "${local.name_prefix}-vpce-sg"
#   vpc_id = aws_vpc.chewbacca_vpc01.id
#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.chewbacca_ec2_sg01.id]
#   }
# }

# resource "aws_vpc_endpoint" "interfaces" {
#   for_each            = toset(["ssm", "ssmmessages", "ec2messages", "secretsmanager", "logs"])
#   vpc_id              = aws_vpc.chewbacca_vpc01.id
#   service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
#   vpc_endpoint_type   = "Interface"
#   security_group_ids  = [aws_security_group.endpoints_sg.id]
#   subnet_ids          = [aws_subnet.chewbacca_private_subnets[0].id]
#   private_dns_enabled = true
# }

# resource "aws_vpc_endpoint" "s3" {
#   vpc_id          = aws_vpc.chewbacca_vpc01.id
#   service_name    = "com.amazonaws.${var.aws_region}.s3"
#   route_table_ids = [aws_route_table.chewbacca_private_rt01.id]
# }