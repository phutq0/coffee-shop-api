terraform {
  backend "s3" {
    bucket         = "coffee-shop-terraform-state-1"
    key            = "coffee-shop/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
