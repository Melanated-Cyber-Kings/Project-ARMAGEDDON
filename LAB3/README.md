# Project Armageddon: APPI-Compliant Global Medical Architecture

## 1. Architectural Overview
This project implements a multi-region, hub-and-spoke architecture designed to meet strict Data Residency requirements (Japan APPI) while allowing global access with failover.

*   **Tokyo Hub (`ap-northeast-1`):** Serves as the "Data Authority." Hosts the primary RDS MySQL database and controls the Transit Gateway Hub.
*   **São Paulo Spoke (`sa-east-1`):** A stateless compute tier. Contains no persistent storage. Connects to Tokyo via a private Transit Gateway Peering connection.
*   **Global Edge:** Amazon CloudFront with Origin Group Failover routing to Application Load Balancers in both regions.

### Compliance Strategy
*   **Data Residency:** Database subnets exist *only* in Tokyo. The São Paulo Network module strictly conditionally prevents DB subnet creation.
*   **Traffic Isolation:** Cross-region database traffic traverses the AWS Backbone via Transit Gateway (TGW), never the public internet.
*   **Identity:** Application credentials are managed via Secrets Manager Global Replication; connection endpoints are bridged via SSM Parameter Store.

## 2. Infrastructure as Code Structure
The repository follows a modular, split-state approach to simulate enterprise environments where regions may be managed independently.

*   `env/tokyo`: Primary state. Manages TGW Request, RDS, and CloudFront.
*   `env/saopaulo`: Secondary state. Manages TGW Acceptance and Stateless Compute.
*   `modules/`: Reusable Terraform modules (TGW, ALB, WAF, etc.).

## 3. Deployment Guide
Due to the circular dependency between TGW Peering (Requester/Accepter) and Cross-Region Routing, deployment follows a strict staged sequence.

### Prerequisites
*   AWS CLI configured with Administrator access.
*   S3 Buckets created for remote state (`armageddon-tf-state-tokyo`, `armageddon-tf-state-saopaulo`).
*   Cloudflare account for DNS delegation.

### Execution Order

**Step 1: Identity & Secrets**
```bash
cd secrets && terraform apply
# Inject the initial database credentials via CLI immediately after creation.
```
**Step 2: Hub Initialization (Tokyo Pass 1)**
```bash
cd env/tokyo && terraform apply
```
*   *Outcome:* Builds VPC, RDS, and TGW. Generates NS records.
*   *Action:* Update Cloudflare Nameservers immediately to allow ACM validation to proceed.

**Step 3: Spoke Initialization (São Paulo Pass 1)**
```bash
cd env/saopaulo && terraform apply
```
*   *Outcome:* Builds VPC and Stateless App. Reads Tokyo State to bootstrap SSM parameters. Updates Remote State with Spoke TGW ID.

**Step 4: The Handshake (Tokyo Pass 2)**
```bash
cd env/tokyo && terraform apply
```
*   *Outcome:* Reads Spoke TGW ID from state. Initiates TGW Peering Request. Updates CloudFront Origin Group.

**Step 5: The Acceptance (São Paulo Pass 2)**
```bash
cd env/saopaulo && terraform apply
```
*   *Outcome:* Accepts TGW Peering. Activates Cross-Region Routes.

## 4. Verification & Audit
Audit evidence is generated using the Python scripts in `scripts/` and stored in `audit-artifacts/`.

### Manual Verification
1.  **Stateless Connectivity:**
    Log into the São Paulo EC2 via SSM and verify internal connectivity to Tokyo:
    ```bash
    # Uses bash tcp socket to verify port 3306 reachability
    (echo > /dev/tcp/<TOKYO_RDS_ENDPOINT>/3306) > /dev/null 2>&1 && echo "CONNECTED"
    ```

2.  **Edge Caching:**
    ```bash
    # First Request (Miss)
    curl -I https://lab3.couch2cloud.dev/static/test.js
    # Second Request (Hit)
    curl -I https://lab3.couch2cloud.dev/static/test.js
    ```
## 5. Known Design Constraints
*   **Write Operations:** To support CloudFront Origin Groups (which restrict mutation methods), write operations are handled via GET requests with query parameters (`/api/add?note=...`).
*   **Provisioning Latency:** TGW Routes require the Peering Attachment to be in `available` state. If a route error occurs during deployment, wait 60 seconds and re-run the apply.