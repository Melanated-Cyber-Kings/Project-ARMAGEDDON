Title: Project Armageddon – Global Medical Data Vault Architecture Summary

Account ID: 200819971986

Status: COMPLIANT

1. Data Residency & Sovereignty (APPI Compliance)
To satisfy Japan’s Act on the Protection of Personal Information (APPI), all Personal Health Information (PHI) is persisted exclusively within the ap-northeast-1 (Tokyo) region. We utilized a Multi-Tier RDS architecture with automated verification scripts (malgus_residency_proof.py) to confirm that no data-bearing resources exist in the sa-east-1 (São Paulo) spoke region. The São Paulo environment remains entirely stateless, serving only as a compute extension for regional latency reduction.

2. Secure Network Corridor
International data transit is handled via a private Transit Gateway (TGW) Inter-Region Peering connection. This "Secure Corridor" ensures that synchronization traffic between Tokyo and São Paulo never traverses the public internet. By peering tgw-042ec676e58287dfd (Tokyo) with tgw-0bcd53292581f1d8e (São Paulo), we have implemented a hardware-encrypted backbone that maintains a single chain of custody for all medical records in transit.

3. Edge Defense & Origin Cloaking
The "Global Medical Vault" is protected at the edge by AWS WAF (Web Application Firewall) and Amazon CloudFront.

Origin Cloaking: We implemented strict header validation (X-Medical-Vault-Secret). Any request attempting to bypass CloudFront and hit the Application Load Balancers (ALBs) directly is rejected with a 403/504 error.

WAF Enforcement: The aws-waf-logs-medical-vault log group captures all edge interactions, providing forensic evidence of blocked SQL injection or Cross-Site Scripting (XSS) attempts.

4. Immutable Audit Vault
All administrative changes and access logs are centralized in a hardened S3 Audit Bucket (class-lab3-200819971986).

Versioning: Enabled to prevent deletion of audit evidence.

Logging: CloudFront standard logs are delivered to the Chwebacca-logs/ prefix, and CloudTrail provides a multi-region management trail for all API actions. This ensures a "single source of truth" for regulatory bodies during annual audits.