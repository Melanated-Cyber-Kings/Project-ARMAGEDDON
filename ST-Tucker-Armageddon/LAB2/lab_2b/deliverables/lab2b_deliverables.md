# LAB-2B Deliverables

> Domain used in this deployment: **devlab405.click**  
> CloudFront URLs used for verification:
> - https://devlab405.click
> - https://devlab405.click/static/example.txt
> - https://devlab405.click/api/list

---

## Deliverable A — Terraform

### A1) Two cache policies

#### A1.1 Static cache policy (aggressive caching)
**Terraform resources**
- `aws_cloudfront_cache_policy.cache_static`

**Key intent**
- Aggressively cache `/static/*`
- No cookies in cache key
- No query strings in cache key
- No headers in cache key
- Enable gzip/brotli (allowed for caching-enabled policies)

**Expected properties**
- TTLs: default 86400, max 31536000, min 0
- Cache key does **not** vary per request for static assets

#### A1.2 API cache policy (caching disabled OR origin-driven)
**Terraform resources**
- `aws_cloudfront_cache_policy.cache_api_disabled`

**Key intent**
- Safe default for `/api/*`: caching disabled (TTL=0)
- Cache key minimal/empty (required by CloudFront when caching is disabled)

**Expected properties**
- TTLs: min/default/max all 0
- No gzip/brotli flags inside this cache policy (CloudFront rejects them when caching disabled)
- No header behavior other than `none` in this cache policy (CloudFront rejects otherwise when caching disabled)

---

### A2) Two origin request policies

#### A2.1 Static origin request policy (minimal forwarding)
**Terraform resources**
- `aws_cloudfront_origin_request_policy.orp_static`

**Key intent**
- Forward nothing for `/static/*` (maximize cache hit ratio)
- cookies: none
- query strings: none
- headers: none

#### A2.2 API origin request policy (forwards required headers/query/cookies)
**Terraform resources**
- `aws_cloudfront_origin_request_policy.orp_api`

**Key intent**
- Forward what the origin needs for dynamic API requests without caching responses
- cookies: all
- query strings: all
- headers: whitelist only (lab-safe set)

**Notes**
- `Authorization` header is not allowed by CloudFront validation in origin request policies.
- Keep the whitelist minimal and purposeful.

---

### A3) Two cache behaviors

#### A3.1 Cache behavior for `/static/*` → static policies
**Terraform configuration**
- `aws_cloudfront_distribution.cf` ordered behavior:
  - `path_pattern = "/static/*"`
  - `cache_policy_id = aws_cloudfront_cache_policy.cache_static.id`
  - `origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_static.id`
  - `response_headers_policy_id = aws_cloudfront_response_headers_policy.rsp_static.id`

#### A3.2 Cache behavior for `/api/*` → api policies
**Terraform configuration**
- `aws_cloudfront_distribution.cf` ordered behavior:
  - `path_pattern = "/api/*"`
  - `cache_policy_id = aws_cloudfront_cache_policy.cache_api_disabled.id`
  - `origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api.id`

---

### A4) Be A Man Challenge — Response headers policy

#### A4.1 Response headers policy for explicit Cache-Control (static)
**Terraform resources**
- `aws_cloudfront_response_headers_policy.rsp_static`

**Key intent**
- Force explicit Cache-Control for `/static/*` responses:
  - `Cache-Control: public, max-age=86400, immutable`

---

### Deliverable B — Correctness Proof (CLI evidence)

### B.A) `curl -I` outputs

> Run these from a workstation with public DNS access.

#### B.A.1 Static: `/static/example.txt` (must show cache hit behavior)
**Command (run twice):**

```bash
curl -sS -I https://devlab405.click/static/example.txt | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:|x-amz-cf-pop|x-amz-cf-id'
curl -sS -I https://devlab405.click/static/example.txt | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:|x-amz-cf-pop|x-amz-cf-id'

Expected output:
Cache-Control: public, max-age=86400, immutable

Age: appears and/or increases on the second request
x-cache: tends to transition toward Hit from cloudfront after warmup



Output #1 (first run, may show Miss or Error from cloudfront):

$ curl -sS -I https://devlab405.click/static/example.txt | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:'
HTTP/2 502 
x-cache: Error from cloudfront
via: 1.1 b3c2d934335633b45a80b7ad63463cda.cloudfront.net (CloudFront)
cache-control: public, max-age=86400, immutable

Output #2 (second run, may show Hit after warmup):

$ curl -sS -I "https://devlab405.click/static/example.txt" | egrep -i 'HTTP/|cache-control:|age:|x-cache:|via:|x-amz-cf-pop:|x-amz-cf-id:'
HTTP/2 502 
x-cache: Error from cloudfront
via: 1.1 e82859bd3e5e584a3698e67f22415dae.cloudfront.net (CloudFront)
x-amz-cf-pop: FRA60-P13
x-amz-cf-id: pPqzhUoP_bl6sy1SAnAe-h_El9LoRFtM-Z59IkZljrBSReVgn3sfJA==
age: 6
cache-control: public, max-age=86400, immutable

B.A.2 API: `/api/list` (must NOT cache unsafe content)
**Command (run twice):**

```bash
curl -sS -I https://devlab405.click/api/list | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:'
curl -sS -I https://devlab405.click/api/list | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:'   
Expected output:
Age: absent (best) or 0
x-cache: often stays Miss from cloudfront (because TTL=0)
```

Output #1:
 curl -sS -I https://devlab405.click/api/list | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:|x-amz-cf-pop|x-amz-cf-id'
HTTP/2 404 
x-cache: Error from cloudfront
via: 1.1 2ae88352064bd2ee8746477a8b6fb1da.cloudfront.net (CloudFront)
x-amz-cf-pop: FRA60-P13
x-amz-cf-id: NmciuYCOVbgiMeATwG_CBKkQ3SN49eWs644ZhRDHdv1WhL4EWq-ohw==

output #2:
 curl -sS -I https://devlab405.click/api/list | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:|x-amz-cf-pop|x-amz-cf-id'
HTTP/2 404 
x-cache: Error from cloudfront
via: 1.1 3e7af1ef389db8ab4a319bd943f95544.cloudfront.net (CloudFront)
x-amz-cf-pop: FRA60-P13
x-amz-cf-id: Xtis-EgAPaa2ZMyX08JhXI7x3Iv4D36-x4radxepXrvmaeSgfOeoLg==

Output #3:
 curl -sS -I https://devlab405.click/api/list | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:|x-amz-cf-pop|x-amz-cf-id'
HTTP/2 404 
x-cache: Error from cloudfront
via: 1.1 581599a51772a76c2489c9d094b70226.cloudfront.net (CloudFront)
x-amz-cf-pop: FRA60-P13
x-amz-cf-id: V8B97EI5Nbh1sywprnKEQLkDzCg2iEt10gCkFzwdC-5Yx5CKz0zztA=

Output #4:

curl -sS -I https://devlab405.click/api/list | egrep -i 'HTTP/|cache-control:|age:|via:|x-cache:'
HTTP/2 404 
x-cache: Error from cloudfront
via: 1.1 c8441ee313b5204aa32e9bf5a370d536.cloudfront.net (CloudFront)


B.B A short written explanation of the results:

B.B.1 “What is my cache key for /api/* and why?”

For /api/*, caching is disabled by policy (min/default/max TTL are all 0). This prevents CloudFront from serving stored responses for dynamic endpoints and avoids unsafe outcomes such as stale reads or cross-user response reuse. With caching disabled, the cache key is effectively irrelevant for reuse because objects are not retained for cache hits.

B.B.2 “What am I forwarding to origin and why?”

For /api/*, the origin request policy forwards all cookies and all query strings so the application can evaluate session state and request parameters (filters, pagination, etc.). A minimal whitelist of headers is forwarded to preserve essential client/origin context while avoiding forwarding unnecessary headers.

For /static/*, the origin request policy forwards no cookies, no query strings, and no headers to maximize cache hit ratio and reduce cache fragmentation.

Deliverable C — Haiku

 A) Haiku descibing Chewbacca's perfections.

  


### Deliverable D - Technical Verification (CLI) — “Correctness, not vibes”



### D.1) Static caching proof

Run twice:

    ```bash
  curl -I https://devlab405.click/static/example.txt
  ```
  ```bash
  curl -I https://devlab405.click/static/example.txt
  ```

Look for:
  Cache-Control: public, max-age=... (from response headers policy)
  Age: increases on subsequent requests (cached object indicator) 

  If Age never appears/increases, caching isn’t working (or TTL is 0 / headers prevent caching).

  curl -I https://devlab405.click/static/example.txt
HTTP/2 502 
content-type: text/html
content-length: 937
date: Sun, 08 Feb 2026 21:07:09 GMT
x-cache: Error from cloudfront
via: 1.1 13cf0cb36194e875c127f27844256ba4.cloudfront.net (CloudFront)
x-amz-cf-pop: FRA60-P13
x-amz-cf-id: YeOIT_AAaKcFGeOylkH8SP4VLFP2DoTmU09glA2N-G3U8RdC59yJNw==
cache-control: public, max-age=86400, immutable

curl -I https://devlab405.click/static/example.txt
HTTP/2 502 
content-type: text/html
content-length: 937
date: Sun, 08 Feb 2026 21:07:09 GMT
x-cache: Error from cloudfront
via: 1.1 1d665d877b0e9ec09e9ec07fe3b6c7b6.cloudfront.net (CloudFront)
x-amz-cf-pop: FRA60-P13
x-amz-cf-id: uoc0alDxGWqV2Cc7ulmwhU7HlJi7f-U2xyhTxpCKt60up6hpeV3wkg==
age: 3
cache-control: public, max-age=86400, immutable



### D.2) API must NOT cache unsafe output
Run twice:

```bash
  curl -I https://devlab405.click/api/list
  ```
  ```bash
  curl -I https://devlab405.click/api/list
  ```

    Expected for “safe default” API behavior:
        Age should be absent or 0
        Responses should reflect fresh origin behavior
        If you add auth later, you must never allow one user to see another’s response


    $ curl -I https://devlab405.click/api/list
    HTTP/2 404 
    content-type: text/html; charset=utf-8
    content-length: 207
    date: Sun, 08 Feb 2026 21:07:43 GMT
    server: Werkzeug/3.1.5 Python/3.9.25
    x-cache: Error from cloudfront
    via: 1.1 387be0cf162c8cb6592090f9496a1e92.cloudfront.net (CloudFront)
    x-amz-cf-pop: FRA60-P13
    x-amz-cf-id: 5y67KYlBNaz6pzYqsZXVEkO-o2-PrxW922vphNxMpqWYP6uUJ_vYPQ==

    $ curl -I https://devlab405.click/api/list
    HTTP/2 404 
    content-type: text/html; charset=utf-8
    content-length: 207
    date: Sun, 08 Feb 2026 21:07:47 GMT
    server: Werkzeug/3.1.5 Python/3.9.25
    x-cache: Error from cloudfront
    via: 1.1 62adf6efa9de9ec639541ac293f53aa0.cloudfront.net (CloudFront)
    x-amz-cf-pop: FRA60-P13
    x-amz-cf-id: kioOy09DSpXh01RnmsmOmjYo7M4GlVYtdoi4iIL_RBgcTA7JZ0d52Q==


### D.3) Cache key sanity checks (query strings)
Static should ignore query strings by default:

```bash
  curl -I "https://devlab405.click/static/example.txt?v=1"
  ```
  ```bash
  curl -I "https://devlab405.click/static/example.txt?v=2"
  ```

    Expected:
    both map to the same cached object (hit ratio stays high) because static cache policy ignores query strings (unless students intentionally change it)


    $  curl -I "https://devlab405.click/static/example.txt?v=1"
    HTTP/2 502 
    content-type: text/html
    content-length: 937
    date: Sun, 08 Feb 2026 21:09:31 GMT
    x-cache: Error from cloudfront
    via: 1.1 2455ef8edb3925202de453ceda9f2c14.cloudfront.net (CloudFront)
    x-amz-cf-pop: FRA60-P13
    x-amz-cf-id: 6eVj-dI_EnXdURcL1X8Q-ena4WXJSMxF0Ippoc63ym-G15lnMmHI-g==
    cache-control: public, max-age=86400, immutable


    $  curl -I "https://devlab405.click/static/example.txt?v=1"
    HTTP/2 502 
    content-type: text/html
    content-length: 937
    date: Sun, 08 Feb 2026 21:09:55 GMT
    x-cache: Error from cloudfront
    via: 1.1 13cf0cb36194e875c127f27844256ba4.cloudfront.net (CloudFront)
    x-amz-cf-pop: FRA60-P13
    x-amz-cf-id: 4iY23CZsL6NS0UHDPXYT-Iwp4nlTzeZ1tLOPuHBsp6yx7uDYmhCCaw==
    cache-control: public, max-age=86400, immutable



### D.4) “Stale read after write” safety test

 Not applicable — this lab application does not implement a write endpoint (POST/PUT). Therefore the “stale read after write” test cannot be executed. The safety control is enforced by disabling caching for /api/* (TTL=0) so CloudFront does not serve stored API responses.
 