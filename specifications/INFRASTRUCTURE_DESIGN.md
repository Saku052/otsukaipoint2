# 🏗️ インフラストラクチャ設計書（MVP超軽量版）
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント インフラストラクチャ設計書 |
| **バージョン** | v1.0（MVP超軽量版） |
| **修正日** | 2025年09月28日 |
| **作成者** | 技術チームリーダー |
| **承認状況** | MVP超軽量版・Supabase BaaS活用 |
| **対象読者** | 開発チーム・DevOpsエンジニア |

---

## 🎯 1. MVP超軽量インフラ戦略

### 1.1 BaaS活用による極限シンプル化

**最小限インフラ方針**:
- ✅ **バックエンド**: Supabase BaaS 100%活用
- ✅ **フロントエンド**: Flutter Android/iOS ネイティブアプリ
- ✅ **CI/CD**: GitHub Actions 20行
- ✅ **サーバー管理**: 不要（Supabase任せ）

### 1.2 削除する複雑インフラ

```
❌ MVP不要インフラ（削除済み）:
- 独自サーバー構築
- Docker環境
- Kubernetes
- ロードバランサー
- CDN設定
- Webホスティング（Firebase Hosting等）
- 複雑なネットワーク構成
- インフラ監視ツール
- 独自SSL証明書管理
```

---

## 🌐 2. アーキテクチャ概要（超シンプル）

### 2.1 システム構成図

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter Mobile App                       │
│              (Android/iOS ネイティブ)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS API calls
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Supabase                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              PostgreSQL Database                    │   │
│  │         (全データ・RLS・バックアップ)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Supabase Auth                       │   │
│  │            (Google OAuth・JWT)                      │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │               Real-time Engine                      │   │
│  │              (WebSocket・同期)                       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 3環境構成（最小限）

| 環境 | Supabase URL | 用途 | アクセス制御 |
|------|-------------|------|-------------|
| **Development** | https://dev-project.supabase.co | 開発・テスト | 開発者全員 |
| **Staging** | https://staging-project.supabase.co | 最終確認 | QAチーム |
| **Production** | https://prod-project.supabase.co | 本番 | 限定メンバー |

---

## 📱 3. モバイルアプリ インフラ

### 3.1 Flutter ネイティブアプリ配布

**Android配布**:
```yaml
# GitHub Actions でビルド・配布
- name: Build Android APK
  run: flutter build apk --release
  
- name: Upload to Google Play Console (手動)
  # 初期MVPは手動アップロード
  # APKファイルを直接アップロード
```

**iOS配布**:
```yaml
# GitHub Actions でビルド
- name: Build iOS IPA
  run: flutter build ios --release
  
- name: Upload to App Store Connect (手動)
  # 初期MVPは手動アップロード
  # IPAファイルを直接アップロード
```

### 3.2 アプリ設定

```dart
// lib/config/environment.dart（環境設定）
class Environment {
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
  
  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
}
```

---

## 🗄️ 4. データベース インフラ（Supabase）

### 4.1 データベース仕様

**PostgreSQL 15 (Supabase)**:
- **接続数**: 最大100接続
- **ストレージ**: 8GB（MVP十分）
- **バックアップ**: 日次自動（30日保持）
- **レプリケーション**: Supabase標準
- **暗号化**: AES-256（保存時・転送時）

### 4.2 テーブル設計（最小限）

```sql
-- MVP最小DB構成（3テーブルのみ）

-- 1. ショッピングリスト
CREATE TABLE shopping_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  family_id VARCHAR(50) NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. ショッピングアイテム
CREATE TABLE shopping_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id UUID REFERENCES shopping_lists(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. ファミリーメンバー（QR共有用）
CREATE TABLE family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id VARCHAR(50) NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  role VARCHAR(20) DEFAULT 'member',
  joined_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🚀 5. CI/CD パイプライン（20行）

### 5.1 GitHub Actions設定

```yaml
# .github/workflows/main.yml（20行で完結）
name: MVP CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-and-build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.0'
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v3
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

### 5.2 デプロイ戦略（手動）

```bash
# MVP デプロイ手順（超シンプル）
# 1. テスト実行
flutter test

# 2. ビルド
flutter build apk --release

# 3. 手動配布（MVP初期）
# - Google Play Console にアップロード
# - App Store Connect にアップロード
```

---

## 🔒 6. ネットワーク・セキュリティ

### 6.1 Supabase セキュリティ設定

**接続セキュリティ**:
```javascript
// Supabase プロジェクト設定
{
  "api": {
    "max_rows": 1000,
    "rate_limit": "100/minute",
    "cors_origins": ["*"]  // MVP簡易設定
  },
  "auth": {
    "enable_signup": true,
    "email_confirm_changes": false,  // MVP簡易化
    "secure_password_change": true
  }
}
```

### 6.2 API セキュリティ

```dart
// アプリ内API呼び出し制限
class APILimiter {
  static int _requestCount = 0;
  static DateTime _lastReset = DateTime.now();
  
  static bool canMakeRequest() {
    final now = DateTime.now();
    if (now.difference(_lastReset).inMinutes >= 1) {
      _requestCount = 0;
      _lastReset = now;
    }
    
    if (_requestCount >= 50) {  // 1分間50リクエスト制限
      print('[API] レート制限中');
      return false;
    }
    
    _requestCount++;
    return true;
  }
}
```

---

## 📊 7. 基本監視（MVP最小限）

### 7.1 Supabase ダッシュボード確認のみ

**月次確認項目**:
- **API使用量**: 制限チェック（5分）
- **データベース使用量**: 容量確認（2分）
- **認証**: エラー有無確認（1分）

**アプリ監視**: なし（MVP不要）

---

## 💾 8. バックアップ・災害復旧

### 8.1 Supabase 自動バックアップ

**バックアップ仕様**:
- **頻度**: 日次自動バックアップ
- **保持期間**: 30日間
- **リカバリ**: Point-in-time recovery（24時間）
- **地理的分散**: Supabase標準（AWS複数リージョン）

### 8.2 災害復旧計画

```
🚨 災害復旧手順（MVP版）:

1. 障害検知
   - Supabaseステータス確認
   - アプリ動作確認

2. 復旧作業
   - Supabaseサポート連絡
   - バックアップからの復旧
   - 必要に応じて新環境作成

3. 確認作業
   - 基本機能テスト
   - データ整合性確認
   - ユーザー通知

目標復旧時間（RTO）: 4時間
目標復旧ポイント（RPO）: 1時間
```

---

## 💰 9. コスト設計

### 9.1 Supabase コスト試算

**Free Tier利用**:
- **API呼び出し**: 50万回/月
- **データベース容量**: 500MB
- **認証ユーザー**: 10万ユーザー
- **ストレージ**: 1GB
- **帯域幅**: 5GB/月

**MVP想定使用量**:
- **API呼び出し**: 10万回/月
- **DB容量**: 100MB
- **ユーザー数**: 1,000人
- **ストレージ**: 100MB

### 9.2 スケールアップ計画

```
📈 成長段階別コスト:

MVP段階（〜1,000ユーザー）:
- Supabase Free: $0/月
- Google Play: $25（初回のみ）
- Apple Developer: $99/年

成長段階（〜10,000ユーザー）:
- Supabase Pro: $25/月
- 運用コスト: $50/月

スケール段階（10,000ユーザー以上）:
- Supabase Team: $599/月
- 追加リソース: 使用量従量課金
```

---

## 🔧 10. 運用管理

### 10.1 日常運用（最小限）

**運用作業**: なし（MVP期間中は運用レス）

### 10.2 定期メンテナンス

```
🔄 月次メンテナンス（10分）:
□ Supabaseダッシュボード確認
□ API使用量確認
□ Flutter SDK更新確認
```

---

## 📈 11. スケーラビリティ設計

### 11.1 Supabase スケーリング

**自動スケーリング**:
- **データベース**: Supabase自動スケーリング
- **API**: Supabase負荷分散
- **ストレージ**: 従量課金で自動拡張
- **リアルタイム**: 接続数に応じて自動拡張

### 11.2 アプリ側最適化

```dart
// 基本的なキャッシュ戦略
class SimpleCache {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  
  static T? get<T>(String key) {
    final cacheTime = _cacheTime[key];
    if (cacheTime == null || 
        DateTime.now().difference(cacheTime).inMinutes > 5) {
      return null;
    }
    return _cache[key] as T?;
  }
  
  static void set(String key, dynamic value) {
    _cache[key] = value;
    _cacheTime[key] = DateTime.now();
  }
}
```

---

## ✅ 12. MVP達成確認

### 12.1 インフラ要件達成

- [x] **バックエンド**: Supabase BaaS 100%活用
- [x] **フロントエンド**: Flutter ビルド・配布
- [x] **CI/CD**: GitHub Actions 20行設定
- [x] **監視**: Supabase標準ダッシュボード
- [x] **バックアップ**: Supabase自動バックアップ
- [x] **セキュリティ**: HTTPS・RLS・JWT

### 12.2 運用負荷最小化

- [x] **サーバー管理**: 不要（Supabase管理）
- [x] **日次運用**: 5分チェックのみ
- [x] **月次メンテナンス**: 30分作業
- [x] **スケーリング**: Supabase自動対応

---

**技術チームリーダー**: MVP に最適化された超軽量インフラ設計  
**修正日**: 2025年09月28日  
**構築時間**: 1日以内（Supabase設定のみ）  
**運用負荷**: 日次5分・月次30分