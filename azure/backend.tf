# azure/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstate123test"  # ユニークな名前に置き換える
    container_name       = "tfstate"
    key                  = "azure/terraform.tfstate"
  }
}
