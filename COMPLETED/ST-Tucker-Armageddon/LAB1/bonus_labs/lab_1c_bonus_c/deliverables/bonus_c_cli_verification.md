0) Set helpers (Domain + pull outputs)

Run from envs/lab-1c:

REGION="ap-northeast-1"

DOMAIN="$(terraform output -raw bonus_c_fqdn 2>/dev/null || terraform output -raw bonus_b_fqdn)"
BASE_DOMAIN="$(echo "$DOMAIN" | sed 's/^[^.]*\.//')"   # devlab405.click
CERT_ARN="$(terraform output -raw acm_certificate_arn)"


If you’re using Route53 existing/managed and want the zone id from Terraform:

ZONE_ID="$(terraform output -raw route53_zone_id 2>/dev/null || true)"
ZONE_ID="${ZONE_ID#/hostedzone/}"  # normalize if AWS returns /hostedzone/XYZ
echo "DOMAIN=$DOMAIN  BASE_DOMAIN=$BASE_DOMAIN  ZONE_ID=$ZONE_ID"

1) Confirm hosted zone exists
If you want to validate “zone exists by name” (works whether managed or existing):
aws route53 list-hosted-zones-by-name \
  --dns-name "$BASE_DOMAIN" \
  --query "HostedZones[?Name=='${BASE_DOMAIN}.'].Id" \
  --output text


  $ aws route53 list-hosted-zones-by-name \
>   --dns-name "$BASE_DOMAIN" \
>   --query "HostedZones[?Name=='${BASE_DOMAIN}.'].Id" \
>   --output text
/hostedzone/Z103851437PNELROEQ0AM




If that prints something like /hostedzone/Z103..., that’s good.

2) Confirm the app record exists in that hosted zone

First ensure you have a usable ZONE_ID:

if [[ -z "${ZONE_ID:-}" ]]; then
  ZONE_ID="$(aws route53 list-hosted-zones-by-name \
    --dns-name "$BASE_DOMAIN" \
    --query "HostedZones[?Name=='${BASE_DOMAIN}.'].Id | [0]" \
    --output text)"
  ZONE_ID="${ZONE_ID#/hostedzone/}"
fi

echo "ZONE_ID=$ZONE_ID"

$ if [[ -z "${ZONE_ID:-}" ]]; then
>   ZONE_ID="$(aws route53 list-hosted-zones-by-name \
>     --dns-name "$BASE_DOMAIN" \
>     --query "HostedZones[?Name=='${BASE_DOMAIN}.'].Id | [0]" \
>     --output text)"
>   ZONE_ID="${ZONE_ID#/hostedzone/}"
> fi

$ echo "ZONE_ID=$ZONE_ID"
ZONE_ID=Z103851437PNELROEQ0AM


Now check the record:

aws route53 list-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --query "ResourceRecordSets[?Name=='${DOMAIN}.']"

  $ aws route53 list-resource-record-sets \
>   --hosted-zone-id "$ZONE_ID" \
>   --query "ResourceRecordSets[?Name=='${DOMAIN}.']"
[
    {
        "Name": "app.devlab405.click.",
        "Type": "A",
        "AliasTarget": {
            "HostedZoneId": "Z14GRHDCWA56QT",
            "DNSName": "lab-1c-alb-991397764.ap-northeast-1.elb.amazonaws.com.",
            "EvaluateTargetHealth": true
        }
    }
]



If you specifically want to see an ALIAS A record pointing at an ALB, use:

aws route53 list-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --query "ResourceRecordSets[?Name=='${DOMAIN}.' && Type=='A']"

  $ aws route53 list-resource-record-sets \
>   --hosted-zone-id "$ZONE_ID" \
>   --query "ResourceRecordSets[?Name=='${DOMAIN}.' && Type=='A']"
[
    {
        "Name": "app.devlab405.click.",
        "Type": "A",
        "AliasTarget": {
            "HostedZoneId": "Z14GRHDCWA56QT",
            "DNSName": "lab-1c-alb-991397764.ap-northeast-1.elb.amazonaws.com.",
            "EvaluateTargetHealth": true
        }
    }
]


3) Confirm ACM certificate is ISSUED
aws acm describe-certificate \
  --region "$REGION" \
  --certificate-arn "$CERT_ARN" \
  --query "Certificate.Status" \
  --output text


Expected: ISSUED

$ aws acm describe-certificate \
>   --region "$REGION" \
>   --certificate-arn "$CERT_ARN" \
>   --query "Certificate.Status" \
>   --output text
ISSUED



Optional extra (shows the DNS validation record ACM expects):

aws acm describe-certificate \
  --region "$REGION" \
  --certificate-arn "$CERT_ARN" \
  --query "Certificate.DomainValidationOptions[0].ResourceRecord" \
  --output table

  $ aws acm describe-certificate \
>   --region "$REGION" \
>   --certificate-arn "$CERT_ARN" \
>   --query "Certificate.DomainValidationOptions[0].ResourceRecord" \
>   --output table
--------------------------------------------------------------------------------
|                              DescribeCertificate                             |
+-------+----------------------------------------------------------------------+
|  Name |  _f4fe8d69a8756f70c3659e242eebe39a.app.devlab405.click.              |
|  Type |  CNAME                                                               |
|  Value|  _958f675658fb59e44aded32d4a520594.jkddzztszm.acm-validations.aws.   |
+-------+----------------------------------------------------------------------+