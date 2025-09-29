output "sg_alb_id" {
  value = aws_security_group.alb.id
}

output "sg_ecs_id" {
  value = aws_security_group.ecs.id
}

output "sg_rds_id" {
  value = aws_security_group.rds.id
}

output "sg_vpce_id" {
  value = try(aws_security_group.vpce[0].id, null)
}

output "iam_ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "iam_ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "kms_key_id" {
  value = try(aws_kms_key.this[0].id, null)
}

output "secret_db_arn" {
  value = try(aws_secretsmanager_secret.db[0].arn, null)
}

output "secret_jwt_arn" {
  value = try(aws_secretsmanager_secret.jwt[0].arn, null)
}
