############################################
# Locals (naming convention: Chewbacca-*)
############################################
locals {
  name_prefix = var.project_name
}






############################################
# NAT Gateway + EIP : No need for an NAT GW as this RDS in the Private subnet does not need outbound internet access.
############################################

# # Explanation: Chewbacca wants the private base to call home—EIP gives the NAT a stable “holonet address.”
# resource "aws_eip" "nat_eip01" {
#   domain = "vpc"

#   tags = {
#     Name = "${local.name_prefix}-nat-eip01"
#   }
# }

# # Explanation: Create the NAT Gateway
# resource "aws_nat_gateway" "gw-nat01" {
#   connectivity_type = "public"
#   allocation_id = aws_eip.nat_eip01.id
#   subnet_id     = aws_subnet.public_subnets[0].id ## Must be a public subnet ID


#   tags = {
#     Name = "${local.name_prefix}-nat01"
#   }

#    # To ensure proper ordering, wait for the Internet Gateway to be ready
#   depends_on = [aws_internet_gateway.igw01]


# }

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table inet via IGW.
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
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.gw-nat01.id
# }

# Explanation: Attach private subnets to the “stealth lanes.”
resource "aws_route_table_association" "private_rta" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt01.id
}





# # ############################################
# # # EC2 Instance (App Host)
# # ############################################

# # Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.
# resource "aws_instance" "ec201" {
#   ami                    = var.ec2_ami_id
#   instance_type           = var.ec2_instance_type
#   subnet_id               = aws_subnet.private_subnets[0].id
#   vpc_security_group_ids  = [aws_security_group.ec2_sg01.id]
#   iam_instance_profile    = aws_iam_instance_profile.instance_profile01.name
#   user_data_replace_on_change = true

#   # TODO: student supplies user_data to install app + CW agent + configure log shipping
#   # user_data = file("${path.module}/user_data.sh")
#   user_data = file("user_data.sh")

#   tags = {
#     Name = "${local.name_prefix}-ec201"
#   }
# }

# ############################################
# # Parameter Store (SSM Parameters)
# ############################################

# Explanation: Parameter Store is Chewbacca’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "db_endpoint_param" {
  name  = local.ssm_db_host_name
  type  = "String"
  value = aws_db_instance.rds01.address

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

# Explanation: Ports are boring, but even Wookiees need to know which door number to kick in.
resource "aws_ssm_parameter" "db_port_param" {
  name  = local.ssm_db_port_name
  type  = "String"
  value = tostring(aws_db_instance.rds01.port)
  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

# Explanation: DB name is the label on the crate—without it, you’re rummaging in the dark.
resource "aws_ssm_parameter" "db_name_param" {
  name  = local.ssm_db_name_name
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
} 


############################################
# Locals (SSM Parameter names)
############################################

locals {
  ssm_db_host_name = "/lab/db/host"
  ssm_db_port_name = "/lab/db/port"
  ssm_db_name_name = "/lab/db/name"
}


# ############################################
# # (Optional but realistic) VPC Endpoints (Skeleton)
# ############################################

# # Explanation: Endpoints keep traffic inside AWS like hyperspace lanes—less exposure, more control.
# # TODO: students can add endpoints for SSM, Logs, Secrets Manager if doing “no public egress” variant.
# # resource "aws_vpc_endpoint" "vpce_ssm" { ... }