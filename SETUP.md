# マルチクラウドTerraformデプロイメントのセットアップガイド

このリポジトリは、GitHub Actionsを使用してTerraformコードを複数のクラウドプロバイダ（AWS、Azure、GCP）にデプロイする方法を示しています。

## 前提条件

- GitHub アカウント
- AWS、Azure、GCPのアカウント
- 各クラウドプロバイダの基本的な知識

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/fumifumi0831/terraform-multicloud-deploy.git
cd terraform-multicloud-deploy
```

### 2. 各クラウドプロバイダの認証情報の準備

#### AWS

1. AWSコンソールでIAMユーザーを作成し、必要なポリシーを付与します:
   - `AmazonS3FullAccess`
   - `IAMFullAccess` (リソースに応じて調整)

2. アクセスキーIDとシークレットアクセスキーを取得します

3. Terraform状態用のS3バケットとDynamoDBテーブルを作成します:

```bash
# S3バケットの作成
aws s3 mb s3://your-terraform-state-bucket --region ap-northeast-1

# S3バケットのバージョニングを有効化
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# DynamoDBテーブルの作成
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-1
```

4. aws/backend.tf ファイルのバケット名とDynamoDBテーブル名を更新します

#### Azure

1. Azure CLIでサービスプリンシパルを作成します:

```bash
# サービスプリンシパルの作成
az ad sp create-for-rbac \
  --name "terraform-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

2. 出力されたJSONを保存します（後でGitHub Secretsに設定します）

3. Terraform状態用のストレージアカウントを作成します:

```bash
# リソースグループの作成
az group create --name terraform-state-rg --location japaneast

# ストレージアカウントの作成
az storage account create \
  --name terraformstate<unique-suffix> \
  --resource-group terraform-state-rg \
  --location japaneast \
  --sku Standard_LRS

# コンテナの作成
az storage container create \
  --name tfstate \
  --account-name terraformstate<unique-suffix>
```

4. azure/backend.tf ファイルのストレージアカウント名を更新します

#### GCP

1. GCPコンソールでサービスアカウントを作成し、必要な権限を付与します:
   - `Storage Admin`
   - `Storage Object Admin`
   - （プロジェクトに応じて追加の権限が必要な場合があります）

2. サービスアカウントのJSONキーをダウンロードします

3. Terraform状態用のストレージバケットを作成します:

```bash
# GCSバケットの作成
gsutil mb -l asia-northeast1 gs://your-terraform-state-bucket
# バージョン管理の有効化
gsutil versioning set on gs://your-terraform-state-bucket
```

4. gcp/backend.tf ファイルのバケット名を更新します

### 3. GitHub Secretsの設定

GitHubリポジトリの"Settings" > "Secrets and variables" > "Actions"に移動し、以下のシークレットを追加します:

#### AWS向けシークレット
- `AWS_ACCESS_KEY_ID`: AWSアクセスキーID
- `AWS_SECRET_ACCESS_KEY`: AWSシークレットアクセスキー

#### Azure向けシークレット
- `AZURE_CREDENTIALS`: サービスプリンシパルのJSON

#### GCP向けシークレット
- `GCP_CREDENTIALS`: サービスアカウントのJSONキー
- `GCP_PROJECT_ID`: GCPプロジェクトID

### 4. GitHub Environments（環境）の設定

リポジトリの"Settings" > "Environments"で以下の環境を作成し、必要に応じて承認ルールを設定します:

- `aws-deployment`
- `azure-deployment`
- `gcp-deployment`

### 5. デプロイを実行する

デプロイを実行するには:

1. コードを変更してプッシュします:
```bash
git add .
git commit -m "初期構成"
git push origin main
```

2. 手動デプロイを実行する場合は:
   - GitHubリポジトリの"Actions"タブに移動
   - "Multi-Cloud Terraform Deployment"ワークフローを選択
   - "Run workflow"ボタンをクリック
   - デプロイしたいクラウドプロバイダーを選択して実行
