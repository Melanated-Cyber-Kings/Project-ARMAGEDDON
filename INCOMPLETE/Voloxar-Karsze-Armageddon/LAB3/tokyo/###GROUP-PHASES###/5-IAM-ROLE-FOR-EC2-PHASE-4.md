<h1 align="center">IAM Role For EC2 Phase 4</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-1-purpose">1 Purpose</a>

  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-11-terraform-actions">1.1 Terraform Actions</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-12-why-the-secret-is-created-before-rds">1.2 Why This Is Required?</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/Project-ARMAGEDDON/blob/main/LAB1/a/4-SECRETS-MANAGER-PHASE-3.md#-13-terraform-checkpoint">1.3 Terraform checkpoint</a>


   
    
<br>


</details>

<br>

<h2 align="center">👷 1 Purpose</h2>

To allow the EC2 instance to securely retrieve database credentials from AWS Secrets Manager without storing any credentials on the instance.
This establishes identity-based trust between EC2 and Secrets Manager and eliminates the need for static access keys. In this phase, an IAM role is attached to the EC2 instance to allow secure, identity-based access to Secrets Manager without storing credentials on the server.




<br>

<h2 align="center">👷 1.1 Terraform Actions</h2>

<br>

## Create an IAM role for EC2

<br>

```bash
resource "aws_iam_role" "ec2_secrets_role" {
  name = "ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
```

This role defines who is allowed to assume it. Only EC2 instances can use this role.


<br>


## Attach permissions to read secrets

<br>

```bash
resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
```
<br>


This policy allows the EC2 instance to call secretsmanager:GetSecretValue.

For production systems, this would be replaced with a tighter, custom policy scoped to a single secret.

<br>

## Create an instance profile

<br>

```bash
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-secrets-profile"
  role = aws_iam_role.ec2_secrets_role.name
}
```

EC2 cannot attach IAM roles directly — it uses an instance profile, which acts as the bridge between the EC2 instance and the IAM role.

<br>


<h2 align="center">👷 1.2 Why This Is Required?</h2>

<br>

- EC2 needs permission to read the database credentials at runtime

- IAM roles remove the need for:

  - Hardcoded access keys

  - Environment variables with secrets

  - Manually rotated credentials

- Permissions are granted based on instance identity, not shared credentials

<br>

This is the standard, production-grade way for AWS services to trust each other.


<br>

<h2 align="center">👷 1.3 Terraform Checkpoint</h2>

<br>

After the EC2 instance is launched, verify that the role is attached:

<br>

```bash
aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn"
```

<br>

## Expected result:

- A non-null IAM Instance Profile ARN

- Confirms the EC2 instance can assume the IAM role

<br>

## What This Proves

- EC2 authenticates using its AWS identity, not static credentials

- Secrets Manager access is tightly controlled by IAM

- Credential delivery is secure and auditable

<br>



