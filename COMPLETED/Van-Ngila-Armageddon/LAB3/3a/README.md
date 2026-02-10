# Lab 3: Multi-Region Compliance ("Japan Medical")

**Author:** Vany FERRAND  
**Completion Date:** 2026-02-10  
**Lab Status:** ✅ COMPLETE

## 📋 Overview

Lab 3 implements a **hub-and-spoke multi-region architecture** between **Tokyo (ap-northeast-1)** and **São Paulo (sa-east-1)** with strict **data residency compliance**. Medical data (PHI) must remain exclusively in Tokyo, while São Paulo hosts stateless compute resources.

## 🏗️ Architecture

```
Tokyo (ap-northeast-1)          São Paulo (sa-east-1)
    TGW (shinjuku-tgw) <-- Peering --> TGW (liberdade-tgw)
        |                                   |
    VPC Attachment                    VPC Attachment
        |                                   |
    Tokyo VPC                        São Paulo VPC
        |                                   |
    RDS (MySQL)                      EC2 (Stateless App)
```

### Key Components:
- **Tokyo Region:** VPC, RDS, Transit Gateway, Application Tier
- **São Paulo Region:** VPC, EC2 instances, Transit Gateway, Stateless compute only
- **TGW Peering:** Cross-region connectivity via Transit Gateway peering attachment
- **Data Residency:** RDS exists ONLY in Tokyo - no database resources in São Paulo

## 🎯 Objectives Achieved

1. **✅ Data Residency Enforcement:** RDS deployed exclusively in Tokyo region
2. **✅ Cross-Region Connectivity:** São Paulo EC2 → Tokyo RDS via TGW peering
3. **✅ Hub-and-Spoke Architecture:** Dual TGW with peering (regional TGWs)
4. **✅ Security Compliance:** RDS Security Group allows São Paulo CIDR only
5. **✅ Geo-Thematic Naming:** Tokyo (train stations) × São Paulo (Japanese districts)

## 🔧 Technical Implementation

### Terraform Structure:
```
./envs/lab-3-saopaulo/
├── 01-main.tf          # São Paulo infrastructure
├── 02-locals.tf        # Local variables
├── 03-variables.tf     # Input variables
├── 04-outputs.tf       # Output values
├── lab-3-saopaulo.auto.tfvars
└── security_rules.tf   # Security configurations
```

### Key Terraform Resources:
- **São Paulo VPC:** `liberdade-vpc` (172.18.0.0/16)
- **São Paulo TGW:** `liberdade-tgw` with VPC attachment
- **TGW Peering:** `shinjuku-to-liberdade-peer01`
- **EC2 Instance:** `liberdade-ec2-app` (t3.micro)
- **Route Tables:** Explicit routes to Tokyo CIDR via local TGW

## 🚨 Challenges & Solutions

### **Challenge 1: "No route to host" Error**
**Symptom:** `nc -zv` returned "No route to host" despite all AWS configurations being correct.

**Root Cause:** São Paulo EC2 had corrupted routing table pointing to Tokyo router (`172.17.0.1`) as its gateway.

**Solution:** 
```bash
# Fixed EC2 routing table
sudo ip route del 172.17.0.0/16 via 172.17.0.1
sudo ip route add 172.17.0.0/16 via 172.18.0.1  # Correct São Paulo router
```

### **Challenge 2: TGW Route Propagation Limitations**
**Discovery:** TGW peering attachments do NOT support route propagation (AWS limitation).

**Solution:** Implemented **static TGW routes**:
```bash
# São Paulo TGW → Tokyo
aws ec2 create-transit-gateway-route \
  --destination-cidr-block 172.17.0.0/16 \
  --transit-gateway-route-table-id tgw-rtb-xxx \
  --transit-gateway-attachment-id tgw-attach-xxx

# Tokyo TGW → São Paulo
aws ec2 create-transit-gateway-route \
  --destination-cidr-block 172.18.0.0/16 \
  --transit-gateway-route-table-id tgw-rtb-yyy \
  --transit-gateway-attachment-id tgw-attach-xxx
```

### **Challenge 3: Security Group Configuration**
**Issue:** RDS Security Group initially only allowed Tokyo EC2 SG, not São Paulo CIDR.

**Fix:** Added explicit CIDR rule:
```hcl
resource "aws_security_group_rule" "rds_from_sao_paulo" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["172.18.0.0/16"]  # São Paulo VPC CIDR
  security_group_id = "sg-xxx"
  description       = "Allow MySQL from São Paulo VPC via TGW"
}
```

## 🧪 Validation

### Gate Validation Script (`gate_network_db.sh`):
```bash
./gate_network_db.sh
```
Checks:
1. ✅ Data residency (no RDS in São Paulo)
2. ✅ TGW peering state (`available`)
3. ✅ Cross-region connectivity (TCP 3306)
4. ✅ Bidirectional route tables
5. ✅ RDS Security Group rules

### Manual Test:
```bash
# From São Paulo EC2
nc -zv lab-mysql.cxm8o4cwoftn.ap-northeast-1.rds.amazonaws.com 3306
# Result: Connected to 172.17.21.137:3306
```

## 📊 Performance Characteristics

- **Latency:** ~300ms Tokyo ↔ São Paulo
- **Throughput:** TGW limits apply per attachment
- **Cost:** Data transfer charges between regions
- **Resilience:** Stateless architecture allows failover

## 🏷️ Naming Convention Enforcement

| Region | Theme | Examples |
|--------|-------|----------|
| Tokyo | Train Stations | `shinjuku-tgw`, `tokyo-vpc` |
| São Paulo | Japanese Districts | `liberdade-vpc`, `japao-subnet` |
| GCP (Lab 4) | NYC Landmarks | `nihonmachi-router` |

## 🔒 Security & Compliance

1. **Data Residency:** PHI never leaves Tokyo region
2. **Encryption:** All cross-region traffic encrypted via TGW
3. **Audit Trail:** CloudTrail logs all cross-region access
4. **Least Privilege:** IAM roles with minimal necessary permissions
5. **Network Isolation:** All cross-region traffic through TGW corridor

## 📈 Lessons Learned

1. **TGW Peering ≠ Route Propagation:** Requires static routes, not propagation
2. **EC2 Routing Can Corrupt:** Instance-level routing tables need monitoring
3. **"No Route to Host" ≠ Routing Issue:** Can be local EC2 configuration
4. **Bidirectional Everything:** Routes, Security Groups, NACLs need both directions
5. **Test Incrementally:** Validate each hop before proceeding

## 🚀 Next Steps

Ready for **Lab 4: Multi-Cloud Connectivity** (AWS Tokyo ↔ GCP Iowa) with:
- Site-to-Site VPN
- BGP routing
- GCP Cloud Router
- Cross-cloud stateless compute

---

**Architect Sign-off:** Vany FERRAND  
**Status:** Lab 3A Multi-Region Compliance ✅ VALIDATED