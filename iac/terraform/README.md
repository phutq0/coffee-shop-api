# Coffee Shop API - Terraform Infrastructure

## Overview
Modular Terraform for AWS deploying a Spring Boot app. Modules: networking, security, ecs, rds, alb, ecr, monitoring. Environments: dev, staging, production. Remote state via S3+DynamoDB.

## Prerequisites
- AWS CLI configured (or OIDC in CI)
- Terraform >= 1.3
- Make

## Quick Start (dev)
```bash
export AWS_REGION=us-east-1
export TF_STATE_BUCKET=<your-state-bucket>
export TF_STATE_LOCK_TABLE=<your-lock-table>
cd iac/terraform
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

## Structure
- modules/
- environments/
- scripts/
- Makefile

## Common Commands
- `make fmt`
- `make validate ENV=dev`
- `make destroy ENV=dev`

## Notes
- Never commit secrets. Use env vars, Secrets Manager, SSM.
- Update variables per environment in `terraform.tfvars`.
