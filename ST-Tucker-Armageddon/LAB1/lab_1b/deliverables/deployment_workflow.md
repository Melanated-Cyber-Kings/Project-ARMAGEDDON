# Lab 1C — Deployment Workflow (Option A: Bootstrap Secrets as Separate Terraform Root)

This repo uses a **two-phase workflow**:

1) **Bootstrap** (creates/owns Secrets Manager + SSM Parameter Store values)  
2) **Deploy Lab 1B** (network, IAM, EC2, RDS, CloudWatch alarm, SNS, etc.)

The only structural change required is moving `secrets/` under `bootstrap/secrets/`.

---

## Phase 0 — One-time repo structure change

From repo root:

```
mkdir -p bootstrap/secrets
git mv secrets/* bootstrap/secrets/
rmdir secrets 2>/dev/null || true
git status
git commit -m "Move secrets terraform root under bootstrap/secrets"
```

---

## Phase 1 — Bootstrap Secrets + SSM (authoritative contract)

From repo root:

```
cd bootstrap/secrets
terraform init -upgrade -reconfigure
terraform fmt -recursive
terraform validate
terraform apply
```

Capture outputs (these are fed into the main lab deployment):

```
export DB_SECRET_ARN="$(terraform output -raw db_secret_arn)"
export SSM_PREFIX="$(terraform output -raw ssm_prefix)"
echo "DB_SECRET_ARN=$DB_SECRET_ARN"
echo "SSM_PREFIX=$SSM_PREFIX"
```

> Notes:
> - `ssm_prefix` defaults to `/lab/db` unless overridden.
> - Ensure your EC2 instance role allows `ssm:GetParameter` for `${SSM_PREFIX}/*`
>   and `secretsmanager:GetSecretValue` for `${DB_SECRET_ARN}`.

---

## Phase 2 — Deploy Lab 1B (main environment)

From repo root:

```
cd envs/lab-1b
terraform init -upgrade -reconfigure
terraform fmt -recursive
terraform validate

terraform apply \
  -var="db_secret_arn=$DB_SECRET_ARN" \
  -var="ssm_prefix=$SSM_PREFIX"
```

---

## Destroy (recommended order)

Destroy the main lab first, then bootstrap:

```
cd envs/lab-1b
terraform destroy

cd ../../bootstrap/secrets
terraform destroy
```

---

## Expected Parameter Store paths (by convention)

Under `ssm_prefix` (default `/lab/db`):

- `${ssm_prefix}/host`
- `${ssm_prefix}/port`
- `${ssm_prefix}/name`
- `${ssm_prefix}/user`

Your EC2 bootstrap/user-data should read these values and read the DB password
from the Secrets Manager secret referenced by `db_secret_arn`.
