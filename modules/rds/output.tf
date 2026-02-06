output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
}

output "rds_instance_arn" {
  value = aws_db_instance.rds_instance.arn
}

output "db_secret_name" {
  value = local.db_secret_name
}

output "rds_instance_id" {
  value = aws_db_instance.rds_instance.id
}

output "db_secret_id" {
  value = aws_secretsmanager_secret.lab_1_db_secret.id
}

output "rds_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}
