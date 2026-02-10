output "secret_kms_key_id" {
    value = data.aws_secretsmanager_secret.my_secret.kms_key_id 
}