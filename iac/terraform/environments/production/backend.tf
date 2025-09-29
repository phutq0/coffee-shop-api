terraform {
  backend "s3" {
    bucket         = "${TF_STATE_BUCKET}"
    key            = "coffee-shop/production/terraform.tfstate"
    region         = "${AWS_REGION}"
    dynamodb_table = "${TF_STATE_LOCK_TABLE}"
    encrypt        = true
  }
}
