output "cluster_id" { value = aws_ecs_cluster.this.id }
output "cluster_name" { value = aws_ecs_cluster.this.name }
output "service_name" { value = aws_ecs_service.this.name }
output "task_definition_arn" { value = aws_ecs_task_definition.this.arn }
output "log_group_name" { value = aws_cloudwatch_log_group.this.name }
