# Lab-1C --- Bonus E

## OPERATIONS Runbook (Expanded / Grader-Grade)

This runbook is the authoritative operator notebook for deploying,
validating, grading, and tearing down Bonus E.\
It is written to match real execution, including failed paths, retries,
pagination, and artifact capture.

Use alongside:

-   `README.md` --- conceptual overview and architecture
-   `deliverables/` --- grader artifacts only

------------------------------------------------------------------------

## 1. Scope

Covers:

-   ordered Terraform deployment
-   Secrets Manager rotation toggling
-   redeploy after partial failure
-   teardown safety
-   grading gate scripts (workstation + EC2)
-   AWS WAF CLI validation
-   CloudWatch pagination and time windows
-   S3 / Firehose alternatives
-   artifact naming
-   containerized execution
-   recovery playbooks

------------------------------------------------------------------------

## 2. Layout

    lab_1c_bonus_e/
    ├── bootstrap/
    ├── deliverables/
    ├── envs/lab-1c/
    ├── modules/
    ├── secrets/
    ├── README.md
    └── OPERATIONS.md

Scratch workspace (never committed):

   /scratch/grader/

Gate scripts live only in scratch.

------------------------------------------------------------------------

## 3. Deployment Ordering (Critical)

Rotation Lambdas are created in `envs/`.\
Secrets must therefore be applied twice.

Sequence:

1.  secrets (rotation OFF)\
2.  envs\
3.  secrets (rotation ON)

------------------------------------------------------------------------

# 4. First-Time Deployment

## 4.1 Deploy Secrets --- Rotation Disabled

Edit:

    secrets/terraform.tfvars

Confirm:

    enable_rotation     = false
    rotation_lambda_arn = ""

Run:

    cd secrets
    terraform init
    terraform apply -auto-approve | tee ../deliverables/01_secrets_initial_apply.txt

------------------------------------------------------------------------

## 4.2 Deploy Environment

    cd envs/lab-1c
    terraform init
    terraform apply -auto-approve | tee ../../deliverables/02_env_apply.txt

Capture outputs:

    terraform output > ../../deliverables/env_outputs.txt

------------------------------------------------------------------------

## 4.3 Enable Rotation

Extract ARN:

    ROT_ARN=$(cd envs/lab-1c && terraform output -raw rotation_lambda_arn)
    echo "$ROT_ARN" | tee ../deliverables/rotation_lambda_arn.txt

Apply secrets again:

    cd secrets
    terraform apply -auto-approve   -var="enable_rotation=true"   -var="rotation_lambda_arn=$ROT_ARN"   | tee ../deliverables/03_secrets_rotation_enabled.txt

------------------------------------------------------------------------

# 5. Redeploy When Secret Already Exists

Symptom:

    ResourceExistsException: secret already exists

Fix:

    aws secretsmanager delete-secret   --secret-id lab-1c/rds/mysql   --force-delete-without-recovery   | tee ../deliverables/secret_force_delete.txt

Re-run step 4.1.

------------------------------------------------------------------------

# 6. Teardown Workflow

## 6.1 Disable Rotation First

    cd secrets
    terraform apply -auto-approve   -var="enable_rotation=false"   -var="rotation_lambda_arn="   | tee ../deliverables/90_rotation_disabled_before_destroy.txt

------------------------------------------------------------------------

## 6.2 Destroy Environment

    cd envs/lab-1c
    terraform destroy -auto-approve   | tee ../../deliverables/91_env_destroy.txt

------------------------------------------------------------------------

## 6.3 Destroy Secrets

    cd secrets
    terraform destroy -auto-approve   | tee ../deliverables/92_secrets_destroy.txt

------------------------------------------------------------------------

# 7. Gate Script Execution

Gate scripts run from scratch or container.

Scripts:

-   gate_secrets_and_role.sh
-   gate_network_db.sh
-   run_all_gates.sh

------------------------------------------------------------------------

## 7.1 Inputs From Terraform

From env outputs:

    REGION=ap-northeast-1
    INSTANCE_ID=i-xxxxxxxx
    SECRET_ID=lab-1c/rds/mysql
    DB_ID=lab-mysql

------------------------------------------------------------------------

## 7.2 Secrets Gate --- Workstation

    REGION=$REGION INSTANCE_ID=$INSTANCE_ID SECRET_ID=$SECRET_ID ./gate_secrets_and_role.sh   | tee deliverables/gate_secrets_workstation.txt

------------------------------------------------------------------------

## 7.3 Secrets Gate --- On EC2 (SSM)

    CHECK_SECRET_VALUE_READ=true REQUIRE_ROTATION=true REGION=$REGION INSTANCE_ID=$INSTANCE_ID SECRET_ID=$SECRET_ID ./gate_secrets_and_role.sh   | tee deliverables/gate_secrets_ec2.txt

------------------------------------------------------------------------

## 7.4 Network Gate

    CHECK_PRIVATE_SUBNETS=true REGION=$REGION INSTANCE_ID=$INSTANCE_ID DB_ID=$DB_ID ./gate_network_db.sh   | tee deliverables/gate_network_db.txt

------------------------------------------------------------------------

# 8. AWS WAF CLI Validation

## 8.1 Confirm Logging Enabled

    aws wafv2 get-logging-configuration   --resource-arn <WEB_ACL_ARN>   | tee deliverables/bonus_e_A_logging_config.json

Count destinations:

    jq '.LoggingConfiguration.LogDestinationConfigs | length'   deliverables/bonus_e_A_logging_config.json   | tee deliverables/bonus_e_A_log_destination_count.txt

------------------------------------------------------------------------

## 8.2 Generate Traffic

    curl -I https://example.com/   | tee deliverables/bonus_e_B_curl_apex_headers.txt

    curl -I https://app.example.com/   | tee deliverables/bonus_e_B_curl_app_headers.txt

------------------------------------------------------------------------

## 8.3 Pull CloudWatch Streams

    aws logs describe-log-streams   --log-group-name aws-waf-logs-lab-1c-webacl   --order-by LastEventTime   --descending   | tee deliverables/bonus_e_C1_streams.json

------------------------------------------------------------------------

## 8.4 Filter Recent Events (Time Window)

    START_MS=$(($(date +%s) * 1000 - 600000))

    aws logs filter-log-events   --log-group-name aws-waf-logs-lab-1c-webacl   --start-time $START_MS   --limit 50   | tee deliverables/bonus_e_C1_filter_log_events.json

------------------------------------------------------------------------

## 8.5 Pagination Loop

    TOKEN=$(jq -r '.nextToken // empty' deliverables/bonus_e_C1_filter_log_events.json)

    while [ -n "$TOKEN" ]; do
      aws logs filter-log-events     --log-group-name aws-waf-logs-lab-1c-webacl     --next-token "$TOKEN"     | tee -a deliverables/bonus_e_C1_filter_log_events_page2.json
      TOKEN=$(jq -r '.nextToken // empty' deliverables/bonus_e_C1_filter_log_events_page2.json)
    done

------------------------------------------------------------------------

## 8.6 BLOCK Evidence Checklist

Look for:

-   `"action":"BLOCK"`
-   `"terminatingRuleId":"AWSManagedRulesCommonRuleSet"`
-   `"NoUserAgent_HEADER"`
-   `httpSourceName=ALB`
-   `clientIp`
-   `country`

------------------------------------------------------------------------

# 9. S3 Destination Alternative

    aws s3 ls s3://aws-waf-logs-<ACCOUNT_ID>/ --recursive   | head   | tee deliverables/bonus_e_C2_s3_head.txt

------------------------------------------------------------------------

# 10. Firehose Destination Alternative

    aws firehose describe-delivery-stream   --delivery-stream-name aws-waf-logs-firehose01   --query 'DeliveryStreamDescription.DeliveryStreamStatus'   | tee deliverables/bonus_e_C3_firehose_status.txt

Confirm S3 delivery:

    aws s3 ls s3://<FIREHOSE_BUCKET>/waf-logs/ --recursive   | head   | tee deliverables/bonus_e_C3_firehose_objects.txt

------------------------------------------------------------------------

# 11. Container Execution

    docker run -it --rm   -v ~/.aws:/root/.aws   -v /scratch/grader:/grader   amazon/aws-cli bash

------------------------------------------------------------------------

# 12. JSON Validation

    python3 -m json.tool gate_result.json   | tee deliverables/gate_result_validated.json

If invalid, submit raw TXT logs.

------------------------------------------------------------------------

# 13. Failure Modes

## Rotation Blocks Destroy

Disable rotation and re-apply secrets.

## Secret Exists

Force delete then re-apply.

## No WAF Logs

-   confirm logging config
-   curl traffic again
-   wait 60s
-   re-run filter-log-events

## Gate Role Failure

    aws ec2 describe-instances   --instance-ids $INSTANCE_ID   --query 'Reservations[].Instances[].IamInstanceProfile.Arn'

------------------------------------------------------------------------

# 14. Pre-Submission Checklist

-   secrets gate PASS
-   network gate PASS
-   WAF BLOCK visible
-   logging destination confirmed
-   artifacts complete
-   destroy tested
-   scratch excluded from git

------------------------------------------------------------------------

END OF RUNBOOK
