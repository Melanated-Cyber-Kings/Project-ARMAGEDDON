#!/bin/bash

aws secretsmanager replicate-secret-to-regions --secret-id lab/rds/mysql --add-replica-regions Region=sa-east-1
