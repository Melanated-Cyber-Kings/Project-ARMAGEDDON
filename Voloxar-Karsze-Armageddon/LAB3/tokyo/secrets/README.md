terraform init
terraform apply
then
```
aws secretsmanager put-secret-value \
  --secret-id lab/rds/mysql \
  --secret-string '{"username":"admin","password":"REDACTED","dbname":"labdb", "host":"lab-mysql.fake.ap-northeast-1.rds.amazonaws.com"}'
  ```