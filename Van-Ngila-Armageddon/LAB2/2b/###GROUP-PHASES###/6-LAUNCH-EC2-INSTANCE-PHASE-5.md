<h1 align="center">Launch EC2 Instance Phase 5</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/6-LAUNCH-EC2-INSTANCE-PHASE-5.md#-1-purpose">1 Purpose</a>

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/6-LAUNCH-EC2-INSTANCE-PHASE-5.md#-11-terraform-actions">1.1 Terraform Actions</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/6-LAUNCH-EC2-INSTANCE-PHASE-5.md#-12-why-each-setting-matters">1.2 Why Each Setting Matters</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/6-LAUNCH-EC2-INSTANCE-PHASE-5.md#-13-terraform-checkpoint">1.3 Terraform Checkpoint</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/6-LAUNCH-EC2-INSTANCE-PHASE-5.md#-14-notes-for-documentation">1.4 Notes for Documentation</a>


    
<br>


</details>

<br>

<h2 align="center">👷 1 Purpose</h2>

<br>

To deploy the compute layer for your lab application. This EC2 instance will host the Python Flask web app that connects to the RDS database using credentials retrieved securely from Secrets Manager. At this point, the network, IAM role, and security groups are already set up, so the instance can safely communicate with the database once the app is installed. 

<br>

In this phase, the EC2 instance is launched in the custom VPC, attached to its security group and IAM role, and bootstrapped with the software needed to host the lab application.

<br>

<h2 align="center">👷 1.1 Terraform Actions</h2>

<br>

## Launch EC2 instance

<br>

```bash
resource "aws_instance" "ec2_app" {
  ami                         = "ami-0xxxxxxx"   # Amazon Linux 2023
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet1.id  # from Phase 1
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  key_name                    = "your-key-pair"  # optional, if SSH needed

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y python3 python3-pip git
              pip3 install flask pymysql boto3
              EOF

  tags = {
    Name = "lab-ec2-app"
  }
}
```

<br>

## Key references in this Terraform code:

- iam_instance_profile → attaches the IAM role from Phase 4

- vpc_security_group_ids → attaches the EC2 security group from Phase 2

- subnet_id → ensures the EC2 instance is in your custom VPC (Phase 1)

- user_data → bootstraps the instance with required software (Python, pip, Flask) to run the lab application

<br>

<h2 align="center">👷 1.2 Why Each Setting Matters</h2>

<br>

## Setting and its Purpose

<br>

- IAM Instance Profile:	**Allows EC2 to retrieve Secrets Manager credentials dynamically (no hardcoded passwords)**
- Security Group:	**Controls inbound HTTP/SSH access and outbound traffic, securing the instance while allowing app functionality**
- Subnet: **Ensures the EC2 instance is in the same network as RDS for connectivity**
- User Data: **Automates software installation so the instance is ready for the lab app immediately**

<br>

<h2 align="center">👷 1.3 Terraform Checkpoint</h2>

<br>

After applying your Terraform code, verify that the instance is running:

<br>

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab-ec2-app" \
  --query "Reservations[].Instances[].State.Name"
``` 

<br>

## Expected result: running

<br>

**Other verifications:**

<br>

- Confirm the IAM role is attached (Phase 4 checkpoint)

- Confirm the EC2 security group is applied (Phase 2 checkpoint)

- Confirm the public IP is assigned (if testing from browser)

<br>


<h2 align="center">👷 1.4 Notes for Documentation</h2>

<br>

- At this stage, the EC2 instance is just a ready compute host. The app itself will be added in a later phase (Phase 9).

- Using Terraform ensures that your EC2 launch is repeatable and consistent, a key principle in Infrastructure as Code.

- The instance is stateless: any data stored on it will not persist beyond its lifecycle. The database holds all persistent data.







