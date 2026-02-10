# Lab 1A/1B: Cloud Networking and Database Integration

## 1. Objective
Establish a secure, high-availability VPC foundation and integrate a private RDS MySQL database instance.

## 2. Implementation
*   **Networking (1A):** Deployed a multi-AZ VPC with distinct public and private subnets.
*   **Database (1B):** Provisioned an RDS MySQL instance within the private DB subnets, ensuring zero public accessibility.
*   **Security:** Enforced security group rules allowing ingress only from the application tier on port 3306.


# Lab 1C: Hardening, Identity, and Observability (Bonus A-F)

## 1. Objective
Implement advanced security patterns, automated configuration management, and custom telemetry.

## 2. Key Deliverables
*   **NAT Gateway (Bonus B):** Established secure egress for instances in private subnets.
*   **IAM Identity (Bonus C):** Removed static credentials; utilized IAM Instance Profiles for resource access.
*   **SSM & Secrets (Bonus D/E):** Decoupled configuration from code using Parameter Store and Secrets Manager.
*   **Custom Metrics (Bonus F):** Implemented a 'Panic Button' metric in the Flask app to monitor DB connection failures via CloudWatch.