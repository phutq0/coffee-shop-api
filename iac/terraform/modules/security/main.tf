# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_ingress_cidrs
    content {
      description = "HTTP"
      from_port   = var.alb_http_port
      to_port     = var.alb_http_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.alb_ingress_cidrs
    content {
      description = "HTTPS"
      from_port   = var.alb_https_port
      to_port     = var.alb_https_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "ECS tasks security group"
  vpc_id      = var.vpc_id

  # Allow from ALB SG on app port
  ingress {
    description     = "App from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name}-ecs-sg" })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "RDS security group"
  vpc_id      = var.vpc_id

  # Allow DB port from ECS SG only
  ingress {
    description     = "Postgres from ECS"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name}-rds-sg" })
}

resource "aws_security_group" "vpce" {
  count       = var.enable_vpce_sg ? 1 : 0
  name        = "${var.name}-vpce-sg"
  description = "Interface endpoint SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name}-vpce-sg" })
}

# IAM Roles
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name}-ecs-task-exec"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_extra" {
  name = "${var.name}-ecs-exec-extra"
  role = aws_iam_role.ecs_task_execution.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue", "ssm:GetParameters", "ssm:GetParameter"], Resource = "*" },
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"], Resource = "*" }
    ]
  })
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.name}-ecs-task"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "ecs_task_app" {
  name = "${var.name}-ecs-task-app"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "*" },
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue", "ssm:GetParameter", "ssm:GetParameters"], Resource = "*" }
    ]
  })
}

# KMS
resource "aws_kms_key" "this" {
  count                   = var.create_kms ? 1 : 0
  description             = "KMS key for application secrets"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = var.tags
}

# Secrets Manager
resource "random_password" "db" {
  count   = var.create_secrets && (var.db_password == null) ? 1 : 0
  length  = 20
  special = true
}

locals {
  db_secret_payload = jsonencode({
    username = coalesce(var.db_username, "coffeeshop")
    password = coalesce(var.db_password, try(random_password.db[0].result, null))
  })
  jwt_secret_value = coalesce(var.jwt_secret_value, try(random_password.jwt[0].result, null))
}

resource "random_password" "jwt" {
  count   = var.create_secrets && (var.jwt_secret_value == null) ? 1 : 0
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  count       = var.create_secrets ? 1 : 0
  name        = coalesce(var.db_secret_name, "${var.name}/db")
  description = "Database credentials"
  kms_key_id  = try(aws_kms_key.this[0].id, null)
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  count         = var.create_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.db[0].id
  secret_string = local.db_secret_payload
}

resource "aws_secretsmanager_secret" "jwt" {
  count       = var.create_secrets ? 1 : 0
  name        = coalesce(var.jwt_secret_name, "${var.name}/jwt")
  description = "JWT secret"
  kms_key_id  = try(aws_kms_key.this[0].id, null)
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "jwt" {
  count         = var.create_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.jwt[0].id
  secret_string = local.jwt_secret_value
}

# SSM Parameters
resource "aws_ssm_parameter" "this" {
  for_each = var.ssm_params
  name     = "/${var.name}/${each.key}"
  type     = "String"
  value    = each.value
  tags     = var.tags
}

# Optional S3 bucket policy for ALB logs
resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.alb_logs_bucket_arn != null && var.alb_logs_bucket_policy_json != null ? 1 : 0
  bucket = replace(var.alb_logs_bucket_arn, "arn:aws:s3:::", "")
  policy = var.alb_logs_bucket_policy_json
}
