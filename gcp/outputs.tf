# gcp/outputs.tf

output "bucket_name" {
  description = "作成したCloud Storageバケットの名前"
  value       = google_storage_bucket.example.name
}

output "bucket_url" {
  description = "作成したCloud StorageバケットのパブリックアクセスURL"
  value       = google_storage_bucket.example.url
}

output "bucket_self_link" {
  description = "作成したCloud Storageバケットのself_link"
  value       = google_storage_bucket.example.self_link
}

output "random_suffix" {
  description = "リソース名に使用したランダムな文字列"
  value       = random_string.random.result
}
