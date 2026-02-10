## Gate Validation Note (Lab 2)
The `gate_result.json` shows a **RED** status due to two known environment/script limitations:
1. **DNS Trailing Dot:** The script fails to match `dqcmjq1kskpmt.cloudfront.net.` with the input string without the dot. 
2. **WAF Propagation:** Although the WAF is associated (verified via `aws cloudfront get-distribution`), the `get-web-acl-for-resource` API used by the script often suffers from propagation lag in the global `us-east-1` scope.

**Authoritative verification is provided in `audit-artifacts/03_waf_attachment_verification.txt`.**