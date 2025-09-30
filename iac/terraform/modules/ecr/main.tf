

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.immutability
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
  encryption_configuration {
    encryption_type = var.kms_key_arn == null ? "AES256" : "KMS"
    kms_key         = var.kms_key_arn
  }
  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last N tagged images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["latest-"],
          countType     = "imageCountMoreThan",
          countNumber   = var.lifecycle_keep_last
        },
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "this" {
  count      = var.repository_policy_json == null ? 0 : 1
  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy_json
}
