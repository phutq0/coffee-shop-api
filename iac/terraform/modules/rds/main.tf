resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "db" {
  name   = "${var.name}-db-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_sg_ids
    content {
      description     = "Postgres from allowed SG"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.name}-pg"
  family = "postgres${split(".", var.engine_version)[0]}"

  dynamic "parameter" {
    for_each = var.parameter_overrides
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

resource "random_password" "db" {
  count   = var.password == null ? 1 : 0
  length  = 20
  special = true
  override_special = "!#$%^&*()-_=+[]{}<>:,.?"
}

locals {
  master_password = coalesce(var.password, try(random_password.db[0].result, null))
}

resource "aws_db_instance" "this" {
  identifier                   = "${var.name}-postgres"
  engine                       = "postgres"
  engine_version               = var.engine_version
  instance_class               = var.instance_class
  db_name                      = var.db_name
  username                     = var.username
  password                     = local.master_password
  allocated_storage            = var.allocated_storage
  max_allocated_storage        = var.max_allocated_storage
  storage_encrypted            = true
  kms_key_id                   = var.kms_key_id
  db_subnet_group_name         = aws_db_subnet_group.this.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  publicly_accessible          = false
  multi_az                     = var.multi_az
  auto_minor_version_upgrade   = true
  deletion_protection          = var.deletion_protection
  backup_retention_period      = var.backup_retention_days
  copy_tags_to_snapshot        = true
  performance_insights_enabled = var.performance_insights
  monitoring_interval          = var.monitoring_interval
  parameter_group_name         = aws_db_parameter_group.this.name

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final-${substr(md5(timestamp()), 0, 8)}"

  tags = var.tags
}

resource "aws_db_instance" "replica" {
  count                        = var.create_read_replica ? 1 : 0
  identifier                   = "${var.name}-postgres-replica"
  engine                       = aws_db_instance.this.engine
  instance_class               = var.instance_class
  publicly_accessible          = false
  storage_encrypted            = true
  kms_key_id                   = var.kms_key_id
  replicate_source_db          = aws_db_instance.this.id
  auto_minor_version_upgrade   = true
  deletion_protection          = var.deletion_protection
  performance_insights_enabled = var.performance_insights
  monitoring_interval          = var.monitoring_interval
  tags                         = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name}-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "High CPU on RDS"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.this.id }
  alarm_actions       = var.alarm_sns_topic_arn == null ? null : [var.alarm_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "connections" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name}-db-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "High connections on RDS"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.this.id }
  alarm_actions       = var.alarm_sns_topic_arn == null ? null : [var.alarm_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "free_storage" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name}-db-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000
  alarm_description   = "Low free storage on RDS"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.this.id }
  alarm_actions       = var.alarm_sns_topic_arn == null ? null : [var.alarm_sns_topic_arn]
}

resource "aws_secretsmanager_secret" "conn" {
  count = var.store_connection_secret ? 1 : 0
  name  = coalesce(var.connection_secret_name, "${var.name}/db/connection")
  tags  = var.tags
}

resource "aws_secretsmanager_secret_version" "conn" {
  count     = var.store_connection_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.conn[0].id
  secret_string = jsonencode({
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    db_name  = var.db_name
    username = var.username
    password = local.master_password
  })
}
