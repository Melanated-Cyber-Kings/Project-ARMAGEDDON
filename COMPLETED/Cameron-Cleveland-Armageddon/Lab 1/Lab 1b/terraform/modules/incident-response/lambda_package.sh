#!/bin/bash
cd "$(dirname "$0")"

# Create requirements.txt
echo "boto3==1.28.57" > requirements.txt

# Create zip file
zip -r lambda_function.zip lambda_function.py requirements.txt

echo "Lambda package created: lambda_function.zip"

