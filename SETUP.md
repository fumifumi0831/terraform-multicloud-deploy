# マルチクラウドTerraformデプロイメントのセットアップガイド（更新版）

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
   - `AmazonDynamoDBFullAccess` (状態ロック用)
   - デプロイするリソースに応じた追加のポリシー
   
2. アクセスキーIDとシークレットアクセスキーを取得します
   - IAMコンソール > ユーザー > 該当ユーザー > セキュリティ認証情報 > アクセスキーの作成
   - **重要**: アクセスキーは一度しか表示されないため、安全な場所に保存してください

3. Terraform状態用のS3バケットとDynamoDBテーブルを作成します:

```bash
# S3バケットの作成（バケット名はグローバルで一意である必要があります）
aws s3 mb s3://terraform-state-<your-unique-suffix> --region ap-northeast-1

# S3バケットのバージョニングを有効化
aws s3api put-bucket-versioning \
  --bucket terraform-state-<your-unique-suffix> \
  --versioning-configuration Status=Enabled

# DynamoDBテーブルの作成（必要な権限がある場合）
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-1
```

4. aws/backend.tf ファイルのバケット名とDynamoDBテーブル名を更新します:

```hcl
terraform {
  backend "s3" {
    bucket  = "terraform-state-<your-unique-suffix>"  # 作成したバケット名に置き換え
    key     = "aws/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
    # dynamodb_table = "terraform-locks"  # 権限がない場合はコメントアウト
  }
}
```

#### Azure

1. Azure CLIでサービスプリンシパルを作成します:

```bash
# まずAzure CLIでログイン
az login

# サブスクリプションを選択（複数ある場合）
az account set --subscription <your-subscription-id>

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

# Storageリソースプロバイダーの登録（初回のみ必要）
az provider register --namespace Microsoft.Storage

# 登録状態の確認（Registeredになるまで待つ）
az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv

# ストレージアカウントの作成（名前は小文字と数字のみ使用可能）
az storage account create \
  --name terraformstate<unique-suffix> \
  --resource-group terraform-state-rg \
  --location japaneast \
  --sku Standard_LRS

# コンテナの作成
az storage container create \
  --name tfstate \
  --account-name terraformstate<unique-suffix> \
  --auth-mode login
```

4. azure/backend.tf ファイルを以下のように更新します:

```hcl
terraform {
  backend "azurerm" {
    subscription_id      = "<your-subscription-id>"
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstate<unique-suffix>"
    container_name       = "tfstate"
    key                  = "azure/terraform.tfstate"
  }
}
```

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

または、以下の4つの個別のシークレットを設定することもできます:

- `ARM_CLIENT_ID`: サービスプリンシパルのクライアントID
- `ARM_CLIENT_SECRET`: サービスプリンシパルのクライアントシークレット
- `ARM_SUBSCRIPTION_ID`: Azureサブスクリプションのサブスクリプションid
- `ARM_TENANT_ID`: AzureテナントのテナントID

#### GCP向けシークレット

- `GCP_CREDENTIALS`: サービスアカウントのJSONキー
- `GCP_PROJECT_ID`: GCPプロジェクトID

### 4. GitHub Environments（環境）の設定

リポジトリの"Settings" > "Environments"で以下の環境を作成し、必要に応じて承認ルールを設定します:

- `aws-deployment`
- `azure-deployment`
- `gcp-deployment`

### 5. GitHub Actionsワークフローファイルの修正

Azure認証のために、`.github/workflows/terraform.yml`ファイルのAzureデプロイジョブに以下の変更を加えます:

```yaml
- name: Extract Azure Credentials
  run: |
    # JSONからクレデンシャル情報を抽出
    AZURE_CREDS='${{ secrets.AZURE_CREDENTIALS }}'
    echo "ARM_CLIENT_ID=$(echo $AZURE_CREDS | jq -r .clientId)" >> $GITHUB_ENV
    echo "ARM_CLIENT_SECRET=$(echo $AZURE_CREDS | jq -r .clientSecret)" >> $GITHUB_ENV
    echo "ARM_SUBSCRIPTION_ID=$(echo $AZURE_CREDS | jq -r .subscriptionId)" >> $GITHUB_ENV
    echo "ARM_TENANT_ID=$(echo $AZURE_CREDS | jq -r .tenantId)" >> $GITHUB_ENV

- name: Terraform Init
  run: terraform init
  working-directory: ./azure
  env:
    ARM_CLIENT_ID: ${{ env.ARM_CLIENT_ID }}
    ARM_CLIENT_SECRET: ${{ env.ARM_CLIENT_SECRET }}
    ARM_SUBSCRIPTION_ID: ${{ env.ARM_SUBSCRIPTION_ID }}
    ARM_TENANT_ID: ${{ env.ARM_TENANT_ID }}
```

同様に、`Terraform Validate`、`Terraform Plan`、`Terraform Apply`ステップにも環境変数を追加します。

### 6. Terraformファイルのフォーマット

デプロイ前に、Terraformファイルが正しくフォーマットされていることを確認します:

```bash
# AWSファイルのフォーマット
cd aws
terraform fmt

# Azureファイルのフォーマット
cd ../azure
terraform fmt

# GCPファイルのフォーマット
cd ../gcp
terraform fmt
```

### 7. .gitignoreファイルの設定

**重要**: Terraformの一時ファイルやプロバイダーファイルをGitリポジトリに含めないように、プロジェクトのルートディレクトリに`.gitignore`ファイルを作成します:

```
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore lock files
.terraform.lock.hcl

# Ignore Mac/OSX system files
.DS_Store
```

この`.gitignore`ファイルは、プロジェクトの最初の段階で設定することが非常に重要です。これにより、大きなプロバイダーファイルがGitリポジトリに含まれることを防ぎます。

### 8. デプロイを実行する

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

## トラブルシューティング

### AWS関連のエラー

#### 認証情報エラー

GitHub Actionsで以下のようなエラーが発生した場合:

```
Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.
```

または:

```
Error: The AWS Access Key Id you provided does not exist in our records.
```

**解決策**:
1. GitHub Secretsに設定したAWS認証情報が正しいことを確認します
2. IAMユーザーに必要な権限が付与されていることを確認します
3. アクセスキーが有効であることを確認します（期限切れでないか）
4. 必要に応じて新しいアクセスキーを作成し、GitHub Secretsを更新します

#### S3バケットエラー

```
Error: Failed to get existing workspaces: S3 bucket does not exist.
```

**解決策**:
1. S3バケットが正しく作成されていることを確認します
2. バケット名がbackend.tfファイルの設定と一致していることを確認します
3. IAMユーザーにS3バケットへのアクセス権限があることを確認します

#### DynamoDBテーブルエラー

```
Error: Error creating DynamoDB Table: AccessDeniedException: User is not authorized to perform: dynamodb:CreateTable
```

**解決策**:
1. IAMユーザーにDynamoDBテーブルを作成する権限がない場合は、backend.tfファイルからdynamodb_table設定を削除するか、コメントアウトします
2. または、必要な権限を持つ別のユーザーでDynamoDBテーブルを事前に作成します

### Terraformフォーマットエラー

GitHub Actionsで以下のエラーが発生した場合:

```
Error: Terraform exited with code 3.
```

**解決策**:
1. ローカルで各ディレクトリに対して`terraform fmt`コマンドを実行します:

```bash
cd aws && terraform fmt
cd ../azure && terraform fmt
cd ../gcp && terraform fmt
```

2. フォーマットされたファイルをコミットしてプッシュします

### 大きなファイルのプッシュエラー

GitHubへのプッシュ時に以下のエラーが発生した場合:

```
remote: error: File aws/.terraform/providers/registry.terraform.io/hashicorp/aws/5.90.0/darwin_amd64/terraform-provider-aws_v5.90.0_x5 is 669.60 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: GH001: Large files detected. You may want to try Git Large File Storage - https://git-lfs.github.com.
```

これは、`.terraform`ディレクトリ内のプロバイダーファイルがGitHubの制限（100MB）を超えているためです。

**解決策**:

1. まず、`.gitignore`ファイルを正しく設定します（上記の「.gitignoreファイルの設定」セクションを参照）

2. すでに追跡されている大きなファイルをGitの履歴から削除します:

```bash
# 追跡対象から.terraformディレクトリを削除
git rm -r --cached **/.terraform/

# 変更をコミット
git commit -m "Remove .terraform directories from git tracking"

# Gitの履歴から大きなファイルを完全に削除
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch **/terraform-provider-*" --prune-empty --tag-name-filter cat -- --all

# リポジトリをクリーンアップ
git gc --prune=now

# 変更を強制的にプッシュ
git push origin main --force
```

**注意**: `git filter-branch`コマンドはGitの履歴を書き換えるため、チーム開発の場合は注意が必要です。他の開発者に事前に通知し、リポジトリを再クローンするよう依頼してください。

### Azure認証エラー

GitHub Actionsで以下のエラーが発生した場合:

```
Error building ARM Config: Authenticating using the Azure CLI is only supported as a User (not a Service Principal).
```

**解決策**:
1. GitHub Secretsに`AZURE_CREDENTIALS`が正しく設定されていることを確認します
2. ワークフローファイルで環境変数の抽出と設定が正しく行われていることを確認します
3. 必要に応じて、サービスプリンシパルを再作成します

### GCP認証エラー

GitHub Actionsで以下のエラーが発生した場合:

```
Error: google: could not find default credentials.
```

**解決策**:
1. GitHub Secretsに`GCP_CREDENTIALS`が正しく設定されていることを確認します
2. サービスアカウントに必要な権限が付与されていることを確認します
3. 必要に応じて、サービスアカウントのJSONキーを再生成します

## ベストプラクティス

1. **認証情報の管理**: 認証情報は常にGitHub Secretsなどの安全な方法で管理し、コードに直接記述しないでください

2. **最小権限の原則**: 各クラウドプロバイダーのサービスアカウント/IAMユーザーには、必要最小限の権限のみを付与してください

3. **状態ファイルの保護**: Terraformの状態ファイルには機密情報が含まれる可能性があるため、適切に保護してください（暗号化、アクセス制限など）

4. **モジュール化**: 大規模なインフラストラクチャの場合は、Terraformコードをモジュール化して再利用性と保守性を高めてください

5. **変数の使用**: ハードコードされた値ではなく変数を使用して、環境間での再利用を容易にしてください

6. **コードレビュー**: インフラストラクチャの変更は、コードレビューを通じて検証してください

7. **テスト**: 本番環境に適用する前に、ステージング環境でTerraformの変更をテストしてください

## 参考リソース

- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [GitHub Actions公式ドキュメント](https://docs.github.com/ja/actions)
- [AWS IAMベストプラクティス](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Azure RBAC公式ドキュメント](https://docs.microsoft.com/ja-jp/azure/role-based-access-control/overview)
- [GCP IAMベストプラクティス](https://cloud.google.com/iam/docs/using-iam-securely)
- [Git Large File Storage (LFS)](https://git-lfs.github.com/)
