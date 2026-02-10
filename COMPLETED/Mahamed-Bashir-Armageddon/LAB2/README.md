# Lab 2: Edge Security and Origin Cloaking

## 1. Objective
Protect the application origin from direct exposure and implement a global traffic management layer.

## 2. Implementation
*   **CloudFront:** Established a global CDN with customized cache behaviors for static and dynamic content.
*   **Origin Cloaking:** Restricted Load Balancer ingress to the CloudFront Managed Prefix List and enforced a custom X-Origin-Secret header handshake.
*   **WAFv2:** Applied a global Web ACL at the Edge to mitigate common exploits (SQLi, XSS) and enforce rate limiting.

## Gate Validation Note (Lab 2)
The `gate_result.json` shows a **RED** status due to two known environment/script limitations:
1. **DNS Trailing Dot:** The script fails to match `dqcmjq1kskpmt.cloudfront.net.` with the input string without the dot. 
2. **WAF Propagation:** Although the WAF is associated (verified via `aws cloudfront get-distribution`), the `get-web-acl-for-resource` API used by the script often suffers from propagation lag in the global `us-east-1` scope.

**Authoritative verification is provided in `audit-artifacts/03_waf_attachment_verification.txt`.**