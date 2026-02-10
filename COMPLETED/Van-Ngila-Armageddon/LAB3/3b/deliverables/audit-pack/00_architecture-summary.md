# Lab 3 Architecture Summary
## Multi-Region Compliance ("Japan Medical")

### Architecture Overview
- **Tokyo Region (ap-northeast-1):** Data tier only - RDS MySQL database
- **São Paulo Region (sa-east-1):** Stateless compute only - EC2 application servers
- **Connectivity:** Transit Gateway peering between regional TGWs
- **Compliance:** PHI data NEVER leaves Tokyo region

### Key Components
1. **Data Residency:** RDS exists ONLY in Tokyo (172.17.21.137)
2. **Network Corridor:** TGW peering (tgw-attach-041d5b46c2379aaf5) with static routes
3. **Security:** 
   - RDS SG allows São Paulo CIDR (172.18.0.0/16)
   - WAF at edge (CloudFront) for OWASP protection
   - CloudTrail audit trail for all changes
4. **Performance:**
   - CloudFront cache policies: Static (aggressive) vs API (no cache)
   - Cross-region latency: ~300ms via TGW

### Evidence Files
- `01_data-residency-proof.txt`: RDS only in Tokyo
- `02_edge-proof-cloudfront.txt`: Cache behavior verification
- `03_waf-proof.txt`: WAF allow/block statistics
- `04_cloudtrail-change-proof.txt`: Change audit trail
- `05_network-corridor-proof.txt`: TGW routing proof
- `evidence.json`: Combined script outputs

**Architect:** Vany FERRAND  
**Date:** 2026-02-10  
**Status:** Lab 3A Complete, Lab 3B Application Deployed
