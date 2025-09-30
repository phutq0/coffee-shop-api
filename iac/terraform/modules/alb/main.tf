

# Access Logs bucket (optional create)
resource "aws_s3_bucket" "logs" {
  count         = var.logs.enabled && var.logs.create_bucket ? 1 : 0
  bucket        = coalesce(var.logs.bucket_name, "${var.name}-alb-logs-${random_id.suffix.hex}")
  force_destroy = false
  tags          = var.tags
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.logs.enabled && var.logs.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = var.logs.enabled && var.logs.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule {
    id     = "expire"
    status = "Enabled"
    filter {}
    expiration {
      days = var.logs.lifecycle_days
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.logs.enabled && var.logs.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AWSLoadBalancerLogsPolicy",
        Effect   = "Allow",
        Principal = {
          Service = "logdelivery.elb.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.logs[0].arn}/*"
      }
    ]
  })
}

# ALB SG (optional external)
resource "aws_security_group" "alb" {
  count  = length(var.security_group_ids) == 0 ? 1 : 0
  name   = "${var.name}-alb-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

locals {
  alb_sg_ids = length(var.security_group_ids) == 0 ? [aws_security_group.alb[0].id] : var.security_group_ids
}

resource "aws_lb" "this" {
  name                             = "${var.name}-alb"
  internal                         = false
  load_balancer_type               = "application"
  subnets                          = var.subnet_ids
  security_groups                  = local.alb_sg_ids
  enable_deletion_protection       = var.deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_lb

  dynamic "access_logs" {
    for_each = var.logs.enabled ? [1] : []
    content {
      bucket  = var.logs.create_bucket ? aws_s3_bucket.logs[0].bucket : var.logs.bucket_name
      prefix  = var.logs.prefix
      enabled = true
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = var.health_check.path
    interval            = var.health_check.interval
    timeout             = var.health_check.timeout
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
    matcher             = var.health_check.matcher
  }
  stickiness {
    enabled         = var.stickiness_enabled
    type            = "lb_cookie"
    cookie_duration = var.stickiness_duration_seconds
  }
  deregistration_delay = var.deregistration_delay
  tags                 = var.tags
}

# HTTP listener (forward directly to target group when redirect not desired)
resource "aws_lb_listener" "http_forward" {
  count             = var.create_https_listener && var.enable_http_redirect ? 0 : 1
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# HTTP listener (redirect to HTTPS when enabled)
resource "aws_lb_listener" "http_redirect" {
  count             = var.create_https_listener && var.enable_http_redirect ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      port        = "443"
      protocol    = "HTTPS"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.create_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Optional WAF association
resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_web_acl_arn == null ? 0 : 1
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}

# Alarms
resource "aws_cloudwatch_metric_alarm" "unhealthy" {
  count               = var.alarm_sns_topic_arn == null ? 0 : 1
  alarm_name          = "${var.name}-alb-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.this.arn_suffix
  }
  alarm_actions = [var.alarm_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  count               = var.alarm_sns_topic_arn == null ? 0 : 1
  alarm_name          = "${var.name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }
  alarm_actions = [var.alarm_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  count               = var.alarm_sns_topic_arn == null ? 0 : 1
  alarm_name          = "${var.name}-alb-target-rt"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.this.arn_suffix
  }
  alarm_actions = [var.alarm_sns_topic_arn]
}
