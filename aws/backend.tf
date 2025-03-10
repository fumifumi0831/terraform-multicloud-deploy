# aws/backend.tf

terraform {
  backend "s3" {
    bucket         = "terraform-state-fumipen-123"  # 一意なバケット名に変更
    key            = "aws/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # DynamoDBテーブル名（オプション）
  }
}
