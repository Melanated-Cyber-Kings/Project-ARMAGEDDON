

# LAB‑2A — CloudFront Origin Cloaking & Secure ALB Ingress

## Purpose

LAB‑2A extends the LAB‑1C Bonus‑B baseline by introducing a production‑grade ingress pattern:

**CloudFront is the only public entry point**, and the ALB becomes functionally private through **origin cloaking**, WAF at the edge, and DNS pointing exclusively to CloudFront.

This lab mirrors real‑world enterprise architectures where CloudFront provides global edge security, caching, and WAF enforcement, while the ALB and application stack remain protected inside the VPC.

---

## Learning Objectives

By completing LAB‑2A, practitioners will:

- Deploy CloudFront in front of an existing ALB  
- Enforce **origin cloaking** using:
  - AWS‑managed CloudFront prefix list  
  - Secret custom origin header  
  - ALB listener rule requiring the header  
- Move WAF from ALB → CloudFront (scope = `CLOUDFRONT`)  
- Configure Route53 to alias the domain and app subdomain to CloudFront  
- Validate that the ALB is unreachable directly  
- Validate that CloudFront is the only public ingress  
- Validate WAF association at the CloudFront distribution  

---

## Architecture

Internet
↓
CloudFront (ACM + WAFv2)
↓
Application Load Balancer
↓
Private EC2 Instance
↓
RDS (MySQL)
Code

### Key Security Controls

| Control | Description |
|--------|-------------|
| **CloudFront prefix list restriction** | ALB SG allows inbound only from `com.amazonaws.global.cloudfront.origin-facing` |
| **Secret origin header** | CloudFront adds `X-Chewbacca-Growl: <secret>`; ALB listener requires it |
| **WAFv2 at the edge** | WAF scope = `CLOUDFRONT`, attached to the distribution |
| **DNS → CloudFront** | Apex + app subdomain alias to CloudFront, not ALB |
| **Private compute** | EC2 + RDS remain in private subnets |

---

## Repository Layout

LAB‑2A lives under:

LAB2/lab_2a/
├── bootstrap/
├── envs/
│   └── lab-2a/
│       ├── main.tf
│       ├── variables.tf
│       ├── lab-2a.auto.tfvars
│       └── lab-2a.auto.tfvars.example
├── modules/
├── deliverables/
└── README.md
Code

---

## Configuration

Environment‑specific values are stored in:

envs/lab-2a/lab-2a.auto.tfvars
Code

A safe example file is provided:

envs/lab-2a/lab-2a.auto.tfvars.example
Code

To use it:

cp lab-2a.auto.tfvars.example  lab-2a.auto.tfvars
Code

Fill in:

- AWS account ID  
- Domain name  
- Route53 zone ID  
- DB credentials  
- KMS key ARN (optional)  

---

## CloudFront Requirements

### ACM Certificate Must Be in us-east-1
CloudFront viewer certificates **must** be created in **N. Virginia**.

Terraform options:

- Use a second provider alias for `us-east-1`  
- Or manually paste an ACM ARN (less ideal)

---

## Origin Cloaking Components

### 1. ALB Security Group Restriction
Allow inbound only from:

com.amazonaws.global.cloudfront.origin-facing
Code

This AWS‑managed prefix list is maintained automatically.

---

### 2. Secret Origin Header
CloudFront adds:

X-Chewbacca-Growl = <secret>
Code

ALB listener rule:

- If header matches → forward to target group  
- Else → return **403**  

Terraform resource:  
`aws_lb_listener_rule`

---

### 3. WAF Moves to CloudFront
- WAFv2 scope = `CLOUDFRONT`  
- Attached directly to the distribution via `web_acl_id`

Terraform resource:  
`aws_wafv2_web_acl`

---

### 4. CloudFront Distribution
Origin configuration:

- Origin = ALB DNS name  
- Protocol = HTTPS only  
- Custom header = secret header  
- WAF association = via `web_acl_id`  

Terraform resource:  
`aws_cloudfront_distribution`

---

### 5. Route53 → CloudFront
Both:

- `devlab405.click`  
- `app.devlab405.click`  

must alias to CloudFront, not ALB.

Terraform resource:  
`aws_route53_record`

---

## Deployment Instructions

From the environment directory:

cd envs/lab-2a
terraform init
terraform validate
terraform plan
terraform apply
Code

---

## Validation (Required Deliverables)

### 1. ALB must NOT be directly reachable

#### A) Direct ALB access → should fail (403)

curl -I https://<ALB_DNS_NAME>
Code

Expected:

403 Forbidden
Code

---

### 2. CloudFront access must succeed

curl -I https://devlab405.click
curl -I https://app.devlab405.click
Code

Expected:

200 OK (or 301 → 200)
Code

---

### 3. WAF must be CloudFront‑scoped

Check WAF:

aws wafv2 get-web-acl \
--name <project>-cf-waf01 \
--scope CLOUDFRONT \
--id <WEB_ACL_ID>
Code

Check CloudFront association:

aws cloudfront get-distribution \
--id <DISTRIBUTION_ID> \
--query "Distribution.DistributionConfig.WebACLId"
Code

Expected: WebACL ARN present.

---

### 4. DNS must resolve to CloudFront

dig devlab405.click  A +short
dig app.devlab405.click  A +short
Code

Expected: CloudFront anycast IPs.

---

## Teardown

To avoid AWS charges:

terraform destroy
Code

---

## Cost Notice

CloudFront, ALB, NAT Gateways, and RDS incur ongoing charges.  
Destroy the environment when not actively testing.

---

## Summary

LAB‑2A introduces a realistic enterprise ingress pattern:

- CloudFront as the only public entry point  
- ALB protected by origin cloaking  
- WAF at the edge  
- DNS pointing to CloudFront  
- Private EC2 + RDS backend  

This lab demonstrates how to secure an application stack behind CloudFront using AWS‑recommended best practices for origin protection.