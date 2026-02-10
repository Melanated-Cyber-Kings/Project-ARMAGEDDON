#Deliverables:

##Terraform Plan outputs:

##Terraform Apply outputs:

##CLI verification commands:

aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption
{
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "lew-rds01.cvecsic0y331.ap-northeast-1.rds.amazonaws.com",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T18:59:08.965000-07:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:620812304994:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "labdb",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T18:39:52.809000-07:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:620812304994:parameter/lab/db/name",
            "DataType": "text"
        },
        {
:...skipping...
{
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "lew-rds01.cvecsic0y331.ap-northeast-1.rds.amazonaws.com",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T18:59:08.965000-07:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:620812304994:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "labdb",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T18:39:52.809000-07:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:620812304994:parameter/lab/db/name",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/port",
            "Type": "String",
:...skipping...
{
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "lew-rds01.cvecsic0y331.ap-northeast-1.rds.amazonaws.com",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T18:59:08.965000-07:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:620812304994:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "labdb",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T18:39:52.809000-07:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:620812304994:parameter/lab/db/name",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/port",
            "Type": "String",
            "Value": "3306",
            "Version": 1,
            "LastModifiedDate": "2026-01-21T18:59:08.966000-07:00",
            "ARN": "arn:aws:ssm:ap-northeast-1:620812304994:parameter/lab/db/port",
            "DataType": "text"
        }
    ],
    "InvalidParameters": []
}


##Incident runbook executions notes: