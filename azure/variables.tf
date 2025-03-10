# azure/variables.tf

variable "azure_location" {
  description = "Azureのロケーション"
  type        = string
  default     = "japaneast"
}

variable "resource_group_prefix" {
  description = "リソースグループ名のプレフィックス"
  type        = string
  default     = "terraform-test-rg"
}

variable "storage_account_prefix" {
  description = "ストレージアカウント名のプレフィックス"
  type        = string
  default     = "tftest"
}

variable "environment" {
  description = "環境名（development, staging, productionなど）"
  type        = string
  default     = "development"
}
