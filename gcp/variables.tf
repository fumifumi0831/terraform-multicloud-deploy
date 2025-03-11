# gcp/variables.tf

variable "gcp_project_id" {
  description = "GCPのプロジェクトID"
  type        = string
  # デフォルト値は設定しません。GitHub Secretsから取得します。
}

variable "gcp_region" {
  description = "GCPのリージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "bucket_prefix" {
  description = "バケット名のプレフィックス"
  type        = string
  default     = "terraform-test-bucket"
}

variable "environment" {
  description = "環境名（development, staging, productionなど）"
  type        = string
  default     = "development"
}

variable "service_account_email" {
  description = "アクセス権を付与するサービスアカウントのメールアドレス"
  type        = string
  default     = "ioc-test@ioctest-453400.iam.gserviceaccount.com"
}
