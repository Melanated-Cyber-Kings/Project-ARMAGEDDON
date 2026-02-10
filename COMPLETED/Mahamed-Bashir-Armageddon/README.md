# Project Armageddon: Multi-Cloud Foundations submission

## 1. Executive Summary
This repository contains the complete Infrastructure as Code (IaC) and audit artifacts for the SEIR Foundations curriculum. The project demonstrates the evolution from a single-tier cloud foundation to a globally distributed, compliant, and edge-secured medical architecture.

## 2. Curriculum Roadmap & Navigation
The project is divided into three distinct phases, each documented within its respective directory:

### [Lab 1: Foundations & Identity](./LAB1/README.md)
*   **Focus:** Secure VPC architecture, Private RDS integration, and IAM Instance Profiles.
*   **Key Achievement:** Eliminated static credentials; implemented application-level telemetry ("Panic Button" custom metrics).

### [Lab 2: Edge Security & Origin Cloaking](./LAB2/README.md)
*   **Focus:** Global traffic management and origin protection.
*   **Key Achievement:** Implemented Layer 7 Origin Cloaking using X-Origin-Secret handshakes and WAFv2 edge shielding.

### [Lab 3: Japan Medical (Compliance Corridor)](./LAB3/README.md)
*   **Focus:** Multi-region architecture and APPI data residency compliance.
*   **Key Achievement:** Established a cross-region private data corridor via Transit Gateway (TGW) Peering between Tokyo (Hub) and São Paulo (Stateless Spoke).

## 3. Tech Stack
*   **Cloud Provider:** AWS (Primary: ap-northeast-1, Secondary: sa-east-1)
*   **IaC:** Terraform (Split-state architecture with S3 Backends)
*   **Security:** AWS WAFv2, Secrets Manager, ACM, IAM
*   **Networking:** Transit Gateway (TGW), Application Load Balancer (ALB), CloudFront
*   **App Tier:** Flask (Python), RDS MySQL

## 4. Final Verification Status

| Metric | Status |
| :--- | :--- |
| **Data Residency (APPI)** | Verified (0 DBs in sa-east-1) |
| **Network Corridor** | Verified (TGW Peering Available) |
| **Identity Management** | Verified (No Static Keys) |
| **Edge Protection** | Verified (WAF Active & Cloaked) |

---
**Submission Timestamp:** February 9, 2026  