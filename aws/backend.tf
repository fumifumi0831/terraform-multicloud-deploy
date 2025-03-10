# aws/backend.tf

terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # あなたのS3バケット名に置き換える
    key            = "aws/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # DynamoDBテーブル名（オプション）
  }
}
