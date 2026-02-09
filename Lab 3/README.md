# Lab 3
# AWS Multi-Region Cloud Architecture Project

> **Production-grade, compliance-aware AWS architecture built with Terraform**

## Table of Contents

* [Project Overview](#project-overview)
* [Architecture Summary](#architecture-summary)

  * [Lab 1: Foundation → Operations → Advanced](#lab-1-foundation--operations--advanced)
  * [Lab 2: Edge Optimization](#lab-2-edge-optimization)
  * [Lab 3: Cross-Region Compliance Architecture](#lab-3-cross-region-compliance-architecture)
* [Key Technical Achievements](#key-technical-achievements)

  * [Security & Compliance](#security--compliance)
  * [Operational Excellence](#operational-excellence)
  * [Advanced Networking](#advanced-networking)
* [Technologies Used](#technologies-used)
* [Project Structure](#project-structure)
* [Verification](#verification)
* [Learning Outcomes](#learning-outcomes)

---

## Project Overview

A comprehensive cloud engineering project implementing real-world AWS architecture patterns across three progressive labs. The design emphasizes **security-first principles**, **operational excellence**, and **regulatory compliance**, while remaining scalable and production-ready.

This project was built to mirror how modern, regulated workloads are deployed in AWS—using private infrastructure, least-privilege IAM, global edge services, and Infrastructure as Code.

---

## Architecture Summary

### Lab 1: Foundation → Operations → Advanced

Core AWS infrastructure patterns focused on secure, private workloads.

* **EC2 → RDS Integration**: Secure connectivity between compute and database layers
* **Secrets Management**: AWS Secrets Manager + Parameter Store (no hard-coded credentials)
* **Private Infrastructure**:

  * Private subnets only
  * VPC endpoints for AWS services
  * SSM Session Manager (no public SSH access)
* **Observability**: CloudWatch Logs, metrics, alarms, and dashboards
* **Load Balancing & Security**:

  * Application Load Balancer (ALB)
  * AWS WAF
  * ACM-issued TLS certificates
  * Custom domain configuration

---

### Lab 2: Edge Optimization

Global edge security and performance optimization using CloudFront.

* **CloudFront as Single Ingress**: CDN fronting all application traffic
* **Origin Cloaking**: ALB accessible only from CloudFront
* **WAF at the Edge**: Managed rule sets for common attack vectors
* **Caching Strategies**:

  * Static content caching
  * Tuned API cache behaviors
* **Security Headers**: Custom headers used for origin validation

---

### Lab 3: Cross-Region Compliance Architecture

Multi-region deployment designed around **data residency and compliance constraints**.

* **Regions**:

  * Tokyo (`ap-northeast-1`) — primary + data region
  * São Paulo (`sa-east-1`) — compute-only extension
* **Data Residency Compliance**:

  * APPI-aligned architecture
  * PHI stored *only* in Japan
* **Networking**:

  * Transit Gateway
  * Secure cross-region connectivity
* **Stateless Compute Extension**:

  * São Paulo region consumes services without storing regulated data
* **Global Access**:

  * Single public endpoint: `chewbacca-growls.com`
  * Intelligent routing via Route 53 and CloudFront

---

## Key Technical Achievements

### Security & Compliance

* Zero hard-coded credentials (Secrets Manager + IAM Roles)
* Private subnets with VPC endpoints for AWS service access
* Security Group referencing (no broad CIDR rules)
* APPI-aligned data residency enforcement
* AWS WAF with managed rule sets
* TLS termination using ACM certificates

### Operational Excellence

* Infrastructure as Code using Terraform
* Automated monitoring and alerting with CloudWatch
* Centralized logging strategy
* Automated backups and recovery procedures
* Multi-region architecture supporting regional failure scenarios

### Advanced Networking

* Transit Gateway peering across regions
* Private AWS API access via VPC endpoints
* CloudFront → ALB origin cloaking
* Custom header validation for origin security
* Route 53 DNS with health checks

---

## Technologies Used

* **Compute**: EC2, Auto Scaling, Application Load Balancer
* **Database**: RDS MySQL
* **Networking**: VPC, Transit Gateway, CloudFront, Route 53
* **Security**: IAM, Secrets Manager, WAF, KMS, Security Groups
* **Management & Ops**: Systems Manager, CloudWatch, SNS
* **Infrastructure as Code**: Terraform
* **Compliance**: APPI-aligned architecture design

---

## Verification

All infrastructure components were validated using AWS CLI and service-level checks to confirm:

* Secure connectivity between services
* Correct IAM permissions and least-privilege enforcement
* Functional cross-region networking
* Compliance with AWS security best practices
* Operational readiness via simulated failure scenarios

---

## Learning Outcomes

This project demonstrates proficiency in:

1. **Production AWS Architecture** — Designing secure, scalable, and maintainable infrastructure
2. **Compliance-Driven Design** — Translating legal requirements (APPI) into technical controls
3. **Multi-Region Strategy** — Building global systems with data sovereignty constraints
4. **Operational Readiness** — Monitoring, alerting, and incident response patterns
5. **Security-First Engineering** — Defense-in-depth across networking, identity, and application layers

---

> 📌 This repository is intended as a **portfolio-grade reference** demonstrating real-world cloud architecture decisions rather than a minimal tutorial deployment.
