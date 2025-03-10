# azure/backend.tf

terraform {
  backend "azurerm" {
    subscription_id      = "2eaa1b9d-d176-4d03-ac9b-e8a82cdea297"
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstate123test"  # ユニークな名前に置き換える
    container_name       = "tfstate"
    key                  = "azure/terraform.tfstate"
  }
}
