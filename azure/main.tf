# azure/main.tf

# Azureプロバイダー設定
provider "azurerm" {
  features {}



  # 環境変数から認証情報を取得
  # GitHub Actionsでは、以下の環境変数を設定する必要があります:
  # - ARM_CLIENT_ID
  # - ARM_CLIENT_SECRET
  # - ARM_TENANT_ID
  # - ARM_SUBSCRIPTION_ID
}

# リソース名の重複を避けるためのランダム文字列
resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

# リソースグループを作成
resource "azurerm_resource_group" "example" {
  name     = "${var.resource_group_prefix}-${random_string.random.result}"
  location = var.azure_location

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# ストレージアカウントを作成
resource "azurerm_storage_account" "example" {
  name                     = "${var.storage_account_prefix}${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# ストレージコンテナを作成
resource "azurerm_storage_container" "example" {
  name                  = "content"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}
