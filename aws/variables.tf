# aws/variables.tf

variable "aws_region" {
  description = "AWSのリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "bucket_prefix" {
  description = "S3バケット名のプレフィックス"
  type        = string
  default     = "terraform-test-bucket"
}

variable "environment" {
  description = "環境名（development, staging, productionなど）"
  type        = string
  default     = "development"
}
