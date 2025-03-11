# gcp/main.tf

# GCPプロバイダー設定
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# リソース名の重複を避けるためのランダム文字列
resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

# Cloud Storageバケットを作成
resource "google_storage_bucket" "example" {
  name     = "${var.bucket_prefix}-${random_string.random.result}"
  location = var.gcp_region

  # バケットのバージョニングを有効化
  versioning {
    enabled = true
  }

  # 30日後に自動削除するライフサイクルルール
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    terraform   = "true"
  }
}

# バケットIAMポリシーを設定
resource "google_storage_bucket_iam_binding" "viewer" {
  bucket = google_storage_bucket.example.name
  role   = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}
