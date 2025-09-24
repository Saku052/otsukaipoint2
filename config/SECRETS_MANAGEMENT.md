# 🔐 シークレット管理ガイド
# Secrets Management Guide

## 📋 概要

このドキュメントでは、おつかいポイントアプリケーションにおけるシークレット（機密情報）の管理方法について説明します。

## 🔑 管理対象シークレット一覧

### 1. Supabase関連
- `SUPABASE_SERVICE_ROLE_KEY`: サーバーサイドAPI操作用
- `SUPABASE_JWT_SECRET`: JWTトークン署名用
- `SUPABASE_DATABASE_PASSWORD`: データベース接続用

### 2. Google OAuth関連
- `GOOGLE_CLIENT_SECRET`: OAuth認証用
- `GOOGLE_SERVICE_ACCOUNT_KEY`: サービスアカウント認証用

### 3. Firebase関連
- `FIREBASE_SERVICE_ACCOUNT`: Firebase Admin SDK用
- `FIREBASE_PRIVATE_KEY`: プッシュ通知用
- `FIREBASE_SERVER_KEY`: Cloud Messaging用

### 4. Android署名関連
- `ANDROID_KEYSTORE_PASSWORD`: キーストアパスワード
- `ANDROID_KEY_PASSWORD`: 署名キーパスワード
- `ANDROID_KEYSTORE_BASE64`: キーストアファイル（Base64エンコード）

### 5. Google Play Console関連
- `GOOGLE_PLAY_SERVICE_ACCOUNT`: Play Console API用

### 6. 外部サービス関連
- `SLACK_WEBHOOK_URL`: 通知用Slack Webhook
- `SENTRY_DSN`: エラー追跡用
- `CODECOV_TOKEN`: コードカバレッジ用

## 🏗️ 環境別シークレット管理戦略

### 開発環境
```bash
# ローカル開発用 - .env.local (gitignoreに追加)
SUPABASE_SERVICE_ROLE_KEY=dev-service-role-key
GOOGLE_CLIENT_SECRET=dev-client-secret
```

### ステージング環境
```bash
# GitHub Secrets (staging環境用)
STAGING_SUPABASE_SERVICE_ROLE_KEY=staging-service-role-key
STAGING_GOOGLE_CLIENT_SECRET=staging-client-secret
```

### 本番環境
```bash
# GitHub Secrets (production環境用)
PRODUCTION_SUPABASE_SERVICE_ROLE_KEY=prod-service-role-key
PRODUCTION_GOOGLE_CLIENT_SECRET=prod-client-secret
```

## 🔧 GitHub Secretsセットアップ手順

### 1. リポジトリレベルSecrets設定

```bash
# GitHub CLI使用例
gh secret set SUPABASE_SERVICE_ROLE_KEY --body "your-service-role-key"
gh secret set GOOGLE_CLIENT_SECRET --body "your-client-secret"
gh secret set ANDROID_KEYSTORE_BASE64 --body "$(base64 -i keystore.jks)"
gh secret set ANDROID_KEYSTORE_PASSWORD --body "your-keystore-password"
gh secret set ANDROID_KEY_PASSWORD --body "your-key-password"
```

### 2. Environment Secrets設定

```bash
# 環境別設定（production環境）
gh secret set SUPABASE_URL --env production --body "https://prod-project.supabase.co"
gh secret set FIREBASE_PROJECT_ID --env production --body "otsukaipoint-prod"
```

### 3. Organization Secrets設定（複数リポジトリ共有）

```bash
# 組織レベルのシークレット
gh secret set --org ORGANIZATION_NAME SHARED_SECRET_KEY --body "shared-value"
```

## 📱 アプリケーション内でのシークレット使用

### 1. 環境変数からの読み込み

```dart
// lib/config/app_config.dart
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://localhost:54321',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'development-anon-key',
  );
  
  // 本番環境では必ずシークレットが設定されていることを確認
  static void validateConfig() {
    if (kReleaseMode) {
      assert(supabaseUrl != 'https://localhost:54321', 
        'Production SUPABASE_URL must be configured');
      assert(supabaseAnonKey != 'development-anon-key', 
        'Production SUPABASE_ANON_KEY must be configured');
    }
  }
}
```

### 2. 設定ファイル読み込み

```dart
// lib/services/config_service.dart
class ConfigService {
  static Future<Map<String, String>> loadConfig() async {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');
    
    final configFile = 'assets/config/$flavor.env';
    final configContent = await rootBundle.loadString(configFile);
    
    final config = <String, String>{};
    for (final line in configContent.split('\n')) {
      if (line.contains('=') && !line.startsWith('#')) {
        final parts = line.split('=');
        config[parts[0].trim()] = parts[1].trim();
      }
    }
    
    return config;
  }
}
```

## 🔒 セキュリティベストプラクティス

### 1. 原則

- ❌ **絶対にコードにハードコーディングしない**
- ❌ **平文でコミットしない**
- ✅ **環境変数やSecrets Managerを使用**
- ✅ **最小権限の原則を適用**
- ✅ **定期的なローテーション実施**

### 2. 開発時の注意事項

```bash
# .gitignore に追加必須項目
.env
.env.local
.env.production
.env.staging
*.keystore
*.jks
google-services.json
service-account-key.json
```

### 3. CI/CD実行時の設定

```yaml
# .github/workflows/ci-cd-pipeline.yml
jobs:
  build:
    steps:
    - name: Setup environment
      run: |
        echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> $GITHUB_ENV
        echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> $GITHUB_ENV
        echo "GOOGLE_CLIENT_ID=${{ secrets.GOOGLE_CLIENT_ID }}" >> $GITHUB_ENV
```

## 📊 シークレット監査・ローテーション

### 1. 定期監査チェックリスト

- [ ] 使用されていないシークレットの特定・削除
- [ ] 過度な権限を持つAPIキーの特定
- [ ] 期限切れ間近の証明書の特定
- [ ] アクセスログの確認

### 2. ローテーション計画

| シークレット種別 | ローテーション頻度 | 責任者 |
|-----------------|------------------|--------|
| データベースパスワード | 3ヶ月毎 | インフラチーム |
| APIキー | 6ヶ月毎 | 開発チーム |
| 署名証明書 | 1年毎 | リリース管理者 |
| OAuth設定 | 必要時 | セキュリティ担当 |

### 3. 緊急時対応手順

```bash
# 1. 侵害されたシークレットの無効化
gh secret delete COMPROMISED_SECRET_NAME

# 2. 新しいシークレット生成・設定
gh secret set NEW_SECRET_NAME --body "new-secure-value"

# 3. 影響を受けるサービスの再起動
kubectl rollout restart deployment/otsukaipoint-app
```

## 🚨 インシデント対応

### 1. シークレット漏洩時の対応

1. **即座の対応**
   - 漏洩したシークレットの無効化
   - 関連サービスへのアクセス遮断
   - ログの確認・保全

2. **復旧作業**
   - 新しいシークレット生成
   - 影響システムの再設定
   - 動作確認テスト実施

3. **事後対応**
   - インシデントレポート作成
   - 再発防止策の実装
   - チーム共有・教育実施

### 2. 連絡体制

```yaml
緊急連絡先:
  セキュリティ担当: security@otsukaipoint.com
  インフラ担当: infra@otsukaipoint.com
  開発リーダー: dev-lead@otsukaipoint.com
  
対応時間:
  平日: 9:00-18:00 (1時間以内応答)
  休日・夜間: 重大インシデントのみ (2時間以内応答)
```

## 📚 参考資料・ツール

### 1. 推奨ツール

- **GitHub Secrets**: CI/CD用
- **HashiCorp Vault**: エンタープライズ向け
- **AWS Secrets Manager**: AWS環境用
- **Azure Key Vault**: Azure環境用
- **Google Secret Manager**: GCP環境用

### 2. セキュリティスキャンツール

```bash
# git-secretsのインストール・設定
git secrets --install
git secrets --register-aws

# truffleHogでのシークレットスキャン
trufflehog git file://. --only-verified

# GitHubのSecret Scanningを有効化
# Settings > Security & analysis > Secret scanning
```

### 3. 学習リソース

- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub Secrets Best Practices](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)

## ✅ チェックリスト

### 開発者向け
- [ ] .gitignoreにシークレットファイル追加済み
- [ ] ローカル開発環境でのシークレット設定完了
- [ ] コード内にハードコーディングされたシークレットがないことを確認

### CI/CD設定者向け
- [ ] GitHub Secretsに必要なシークレット設定完了
- [ ] 環境別シークレット分離実施済み
- [ ] ワークフロー内でのシークレット使用方法確認済み

### 運用担当者向け
- [ ] シークレットローテーション計画策定済み
- [ ] 監査・レビュー体制構築済み
- [ ] インシデント対応手順周知済み

---

**最終更新**: 2025年09月24日  
**次回見直し**: 2025年12月24日（3ヶ月後）