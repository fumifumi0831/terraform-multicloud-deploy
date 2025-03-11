# gcp/backend.tf

terraform {
  backend "gcs" {
    bucket = "terraform_ioc_test" # あなたのGCS バケット名に置き換える
    prefix = "terraform/state/gcp"
  }
}
