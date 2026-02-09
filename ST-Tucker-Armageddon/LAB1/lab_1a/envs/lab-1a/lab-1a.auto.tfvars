# -------------------------------------------------
# LAB 1A — Local Environment Values
# -------------------------------------------------

region     = "ap-northeast-1"
project    = "Armageddon"
env_prefix = "lab-1a"

account_id  = "261519058382"
kms_key_arn = "arn:aws:kms:ap-northeast-1:261519058382:key/0987dcba-09de-87dc-65ba-ab0987654321"

# -----------------
# Networking
# -----------------

vpc_cidr_block     = "172.17.0.0/16"
public_subnet_cidr = "172.17.1.0/24"

private_subnet_cidr_1 = "172.17.11.0/24"
private_subnet_cidr_2 = "172.17.12.0/24"

avail_zone_1 = "ap-northeast-1a"
avail_zone_2 = "ap-northeast-1c"

rtb_public_cidr = "0.0.0.0/0"

# -----------------
# EC2
# -----------------

instance_type = "t3.micro"

# Optional SSH KeyPair (recommended)
key_name = "lab1a-user"

# Restrict SSH to your IP (x.x.x.x/32)
#ssh_ingress_cidr = "0.0.0.0/0"

# -----------------
# RDS / Secrets
# -----------------

db_secret_name = "lab-1a/rds/mysql"
db_port        = 3306
