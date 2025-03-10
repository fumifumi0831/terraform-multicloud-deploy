# aws/outputs.tf

output "bucket_name" {
  description = "作成したS3バケットの名前"
  value       = aws_s3_bucket.test_bucket.bucket
}

output "bucket_arn" {
  description = "作成したS3バケットのARN"
  value       = aws_s3_bucket.test_bucket.arn
}

output "random_suffix" {
  description = "リソース名に使用したランダムな文字列"
  value       = random_string.random.result
}
