# gcp/backend.tf

terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"  # あなたのGCS バケット名に置き換える
    prefix = "terraform/state/gcp"
  }
}
