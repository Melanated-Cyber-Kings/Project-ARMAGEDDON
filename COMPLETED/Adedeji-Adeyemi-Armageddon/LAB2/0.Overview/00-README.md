# Lab 2A: Edge Security & Origin Cloaking


## Project Overview
This project transitions the "Hardened Monolith" into a "cloaked" architecture by fronting the regional infrastructure with **Amazon CloudFront** and **AWS WAFv2**. The primary goal is to establish a secure, global entry point while ensuring the Application Load Balancer (ALB) is completely hidden from the public internet. This prevents attackers from bypassing edge security to hit the origin directly.
## Architecture Design
The architecture implements a multi-layered "Handshake" between the Global Edge and the Regional Tokyo origin.
### 1. Global Edge Tier (us-east-1)
**- Edge Security:** AWS WAFv2 (scope=CLOUDFRONT) enforces security policies at the edge.
**- Content Delivery:** Amazon CloudFront handles all viewer ingress and SSL termination using an ACM certificate in us-east-1. 
**- DNS:** Route 53 redirects all apex and subdomain traffic to the CloudFront distribution via Alias records.



## Architecture Overview

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


### 2. Cloaked Origin Tier (ap-northeast-1)
**- Network Isolation:** The ALB Security Group is restricted to allow inbound traffic ONLY from the AWS-managed CloudFront Prefix List. 
**- Header Validation:** ALB Listener Rules enforce a second layer of defense by requiring a secret custom header (X-Chewbacca-Growl) injected by CloudFront. 
**- Private Compute:** EC2 instances and RDS remain isolated in private subnets, reachable only via the cloaked ALB.

## DevOps Workflow (Edge Handshake)
This lab implements a specific deployment sequence to move WAF and DNS from the regional ALB to the global edge without downtime.
### Deployment Sequence
**WAF Relocation:** Replace the ALB-scoped WAF with a Global-scoped Web ACL in us-east-1.

**Origin Security Update:** Modify the ALB Security Group to remove 0.0.0.0/0 and replace it with the CloudFront Prefix List.

**Header Handshake:** Inject the secret header in the CloudFront origin config and add a matching "Fixed 403" fallback rule to the ALB listener.

**DNS Cutover:** Update Route 53 A-records (Alias) to point away from the ALB DNS and toward the CloudFront Anycast DNS.

## Security & Compliance
**VPC Cloaking:** Direct requests to the ALB DNS name fail with a 403 Forbidden, proving the origin is functionally private. 
**Edge Mitigation:** WAFv2 enforcement at the CloudFront edge absorbs malicious traffic before it ever consumes regional bandwidth or compute resources. 
**Least Privilege Networking:** Utilizing the AWS-managed Prefix List ensures the ALB only talks to authoritative AWS edge locations.

## Verification
Verification is performed via CLI to prove all three core requirements are met:

### Verify VPC Cloaking (Direct ALB Access)
 curl -I https://<ALB_DNS_NAME> Expected Output: 403 Forbidden

### Verify CloudFront Access 
 curl -I https://chewbacca-growl.com Expected Output: 200 OK

### Verify DNS Resolution
 dig chewbacca-growl.com A +short Expected Output: CloudFront Anycast IPs (not ALB IPs)

# Lab 2B: Cache Correctness & Behavior
## Project Overview
Lab 2B focuses on the operational correctness of the CDN. The objective is to optimize the delivery of a hybrid application where **Static Content** (images, JS, CSS) must be cached aggressively for performance, and **API Content** (dynamic data) must be cached cautiously (or not at all) to prevent session mixups or stale data delivery.
## Architecture Design
The CloudFront distribution is updated with multiple **Cache Behaviors** to handle path-specific routing logic.
### 1. Static Asset Behavior (/static/*)
**- Aggressive Caching:** Uses a high TTL (Max-Age) policy to offload origin requests and reduce costs. 
**- Minimum Cache Key:** Only the URL path is included in the cache key to maximize the Cache Hit Ratio.

### 2. API / Dynamic Behavior (Default *)
**- Dynamic Routing:** Configured with caching disabled by default (Managed-CachingDisabled) to ensure real-time data accuracy. 
**- Origin Request Policy:** Forwards all headers (Authorization, Cookies) required for the backend application to process user-specific sessions.

## DevOps Workflow (Cache Key Logic)
A critical skill for a Cloud Engineer is managing the "Cache Key" to avoid fragmentation.
### Caching Strategy
**High-Cardinality Awareness:** Avoided caching based on headers like User-Agent, which would explode cache variations and degrade performance.

**Cache-Control Semantics:** Standardized on Cache-Control: max-age headers over legacy Expires headers.

**Policy Separation:** Distinguished between Cache Policies (what is in the "Key") and Origin Request Policies (what is forwarded to the backend).

**Security & Compliance**
Correctness over Speed: Ensuring that user-specific API data never "leaks" to another user through a misconfigured cache. Origin Offload: Aggressive static caching protects the origin from traffic spikes during large-scale reads.

## Verification
Success is proved by inspecting response headers and application behavior:

### Check Cache Status 
curl -I https://app.chewbacca-growl.com/static/logo.png Look for: X-Cache: Hit from cloudfront and an increasing Age header.

### Check API Correctness 
curl -I https://app.chewbacca-growl.com/api/user Look for: X-Cache: Miss from cloudfront (Expected for dynamic data).

## Workforce Relevance (Common Interview Questions)
***- "Why do you use a custom header if you already have a prefix-list SG rule?"**

"Defense in Depth. While the SG limits traffic to AWS, the header ensures it is specifically our distribution talking to our origin, preventing "Distribution Bypassing."

**- "Why shouldn't we just cache everything for 24 hours?"**
"Catastrophic session mixups. Caching a /user/profile response could result in User A seeing User B's private data. We use path-based behaviors to isolate dynamic data from static assets."

**- "What is the difference between a Cache Policy and an Origin Request Policy?"** 
"The Cache Policy determines the "fingerprint" of the file in the CDN. The Origin Request Policy determines what "luggage" the request carries back to the server (like Cookies or Auth headers) without necessarily making those values part of the fingerprint."