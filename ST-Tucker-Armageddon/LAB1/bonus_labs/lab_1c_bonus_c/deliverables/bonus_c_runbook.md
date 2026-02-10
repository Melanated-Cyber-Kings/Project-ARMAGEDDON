1️⃣ Terraform State = Green

From envs/lab-1c:

terraform init
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars




2️⃣ CLI Validation (Authoritative)

These go in your Bonus-C runbook.

Hosted Zone

```
aws route53 list-hosted-zones-by-name \
  --dns-name devlab405.click \
  --query "HostedZones[].Id"
```

  [
    "/hostedzone/Z103851437PNELROEQ0AM",
    "/hostedzone/Z018466133GJR4SEO22CT"
]

App Record
```
aws route53 list-resource-record-sets \
  --hosted-zone-id <ZONE_ID> \
  --query "ResourceRecordSets[?Name=='app.devlab405.click.']"
```
[
    {
        "Name": "app.devlab405.click.",
        "Type": "A",
        "AliasTarget": {
            "HostedZoneId": "Z14GRHDCWA56QT",
            "DNSName": "lab-1c-alb-335960807.ap-northeast-1.elb.amazonaws.com.",
            "EvaluateTargetHealth": true
        }
    }
]

Certificate
```
aws acm describe-certificate \
  --certificate-arn <CERT_ARN> \
  --query "Certificate.Status"
```

Must return:

"ISSUED"

$ aws acm describe-certificate \
>   --certificate-arn "arn:aws:acm:ap-northeast-1:261519058382:certificate/c24c2563-c82c-42af-9927-7d3ebc94d070" \
>   --query "Certificate.Status"
"ISSUED"

