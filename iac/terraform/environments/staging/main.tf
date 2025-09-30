terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

module "networking" {
  source = "../../modules/networking"

  name                 = var.name
  region               = var.region
  tags                 = var.tags
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  enable_nat_per_az    = var.enable_nat_per_az
  enable_vpc_flow_logs = var.enable_vpc_flow_logs

  vpc_endpoints = {
    s3  = true
    ecr = true
  }
}

module "security" {
  source = "../../modules/security"

  name     = var.name
  region   = var.region
  tags     = var.tags
  vpc_id   = module.networking.vpc_id
  vpc_cidr = var.vpc_cidr

  alb_ingress_cidrs = ["0.0.0.0/0"]
  app_port          = var.app_port

  depends_on = [module.networking]
}

module "alb" {
  source = "../../modules/alb"

  name                  = var.name
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  security_group_ids    = [module.security.sg_alb_id]
  tags                  = var.tags
  target_port           = var.app_port
  create_https_listener = var.alb_create_https
  certificate_arn       = var.alb_certificate_arn
  enable_http_redirect  = var.alb_enable_http_redirect

  depends_on = [module.networking, module.security]
}

module "ecr" {
  source = "../../modules/ecr"

  name = var.name
  tags = var.tags
}

module "rds" {
  source = "../../modules/rds"

  name           = var.name
  region         = var.region
  tags           = var.tags
  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.db_subnet_ids
  db_name        = var.db_name
  instance_class = var.db_instance_class
  multi_az       = var.db_multi_az
  ingress_sg_ids = [module.security.sg_ecs_id]

  depends_on = [module.networking, module.security]
}

module "ecs" {
  source = "../../modules/ecs"

  name               = var.name
  region             = var.region
  tags               = var.tags
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.security.sg_ecs_id]
  cluster_name       = "${var.name}-cluster"
  image              = var.app_image
  container_port     = var.app_port
  cpu                = var.ecs_cpu
  memory             = var.ecs_memory
  desired_count      = var.desired_count
  target_group_arn   = module.alb.target_group_arn

  depends_on = [module.networking, module.security, module.alb, module.ecr]
}

module "monitoring" {
  source = "../../modules/monitoring"

  name                 = var.name
  region               = var.region
  tags                 = var.tags
  notification_emails  = var.notification_emails
  ecs_cluster_name     = module.ecs.cluster_name
  alb_arn_suffix       = trimprefix(module.alb.alb_arn, "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:")
  tg_arn_suffix        = trimprefix(module.alb.target_group_arn, "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:")
  rds_identifier       = module.rds.db_identifier
  error_filter_pattern = "?ERROR ?Error ?Exception"
  app_log_group_names  = [module.ecs.log_group_name]

  enable_cost_alarms   = false
  monthly_cost_threshold = 100
  alarm_thresholds = {
    ecs_cpu_high         = 80
    ecs_memory_high      = 80
    alb_5xx_high         = 10
    alb_target_rt_high   = 1
    rds_cpu_high         = 80
    rds_connections_high = 100
    rds_free_storage_low = 2000000000
    log_error_rate_high  = 5
  }

  depends_on = [module.networking, module.security, module.alb, module.ecr, module.rds, module.ecs]
}

data "aws_caller_identity" "current" {}
