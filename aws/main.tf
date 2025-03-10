# aws/main.tf

# AWSプロバイダー設定
provider "aws" {
  region = var.aws_region
}

# バケット名の重複を避けるためのランダム文字列
resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

# S3バケットの作成
resource "aws_s3_bucket" "test_bucket" {
  bucket = "${var.bucket_prefix}-${random_string.random.result}"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# バケットの公開アクセスブロックを設定
resource "aws_s3_bucket_public_access_block" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
