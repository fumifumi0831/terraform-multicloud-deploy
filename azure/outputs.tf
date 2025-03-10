# azure/outputs.tf

output "resource_group_name" {
  description = "作成したリソースグループの名前"
  value       = azurerm_resource_group.example.name
}

output "storage_account_name" {
  description = "作成したストレージアカウントの名前"
  value       = azurerm_storage_account.example.name
}

output "storage_container_name" {
  description = "作成したストレージコンテナの名前"
  value       = azurerm_storage_container.example.name
}

output "random_suffix" {
  description = "リソース名に使用したランダムな文字列"
  value       = random_string.random.result
}
