output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = var.db_name
}

output "db_sg_id" {
  value = aws_security_group.db.id
}

output "db_subnet_group" {
  value = aws_db_subnet_group.this.name
}

output "db_identifier" {
  value = aws_db_instance.this.id
}
