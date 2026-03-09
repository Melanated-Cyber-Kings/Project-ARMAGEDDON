#!/bin/bash

aws ec2 describe-security-groups --group-ids sg-0b0def7b115ce9f70 sg-0d33b9ec58f63dcc9> sg.json
aws rds describe-db-instances --db-instance-identifier armageddon-class-vii-rds01> rds.json
aws secretsmanager describe-secret --secret-id dakid/lab/rds/mysql> secret.json
aws ec2 describe-instances --instance-ids i-02390a743e3afa588> instance.json
aws iam list-attached-role-policies --role-name armageddon-class-vii-ec2-role01 > role-policies.json
