# 🔧 環境設定手順書（MVP実装ガイド）
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント 環境設定手順書 |
| **バージョン** | v1.0（MVP実装ガイド） |
| **修正日** | 2025年09月28日 |
| **作成者** | 技術チームリーダー |
| **対象読者** | 開発チーム・新規メンバー |

---

## 🎯 1. MVP環境設定概要

### 1.1 必要な環境

**最小限構成**:
- ✅ **Flutter 3.35+**: モバイルアプリ開発
- ✅ **Supabase プロジェクト**: バックエンド
- ✅ **GitHub アカウント**: CI/CD
- ✅ **Google Cloud Console**: OAuth設定

**推定設定時間**: 2時間

---

## 📱 2. Flutter開発環境設定

### 2.1 Flutter SDK インストール

```bash
# 1. Flutter SDK ダウンロード
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 2. 依存関係確認
flutter doctor

# 3. 必要なツールインストール
flutter doctor --android-licenses  # Android用
```

### 2.2 プロジェクト初期化

```bash
# 1. プロジェクト作成
flutter create otsukaipoint --org com.example

# 2. ディレクトリ移動
cd otsukaipoint

# 3. 依存関係追加
```

### 2.3 pubspec.yaml設定

```yaml
# pubspec.yaml（MVP最小構成）
name: otsukaipoint
description: MVP版ショッピングリスト共有アプリ
version: 1.0.0+1

environment:
  sdk: '>=3.9.2 <4.0.0'
  flutter: ">=3.35.0"

dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  flutter_riverpod: ^2.4.9
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
```

---

## 🗄️ 3. Supabase環境設定

### 3.1 Supabaseプロジェクト作成

```bash
# 1. Supabase ウェブサイトでアカウント作成
# https://supabase.com

# 2. 新規プロジェクト作成
# - Organization: 個人アカウント
# - Name: otsukaipoint-mvp
# - Database Password: 強力なパスワード設定
# - Region: Northeast Asia (Tokyo)
```

### 3.2 データベーススキーマ設定

```sql
-- Supabase SQL Editor で実行

-- 1. ショッピングリストテーブル
CREATE TABLE shopping_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  family_id VARCHAR(50) NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. ショッピングアイテムテーブル
CREATE TABLE shopping_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id UUID REFERENCES shopping_lists(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. ファミリーメンバーテーブル
CREATE TABLE family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id VARCHAR(50) NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  role VARCHAR(20) DEFAULT 'member',
  joined_at TIMESTAMP DEFAULT NOW()
);
```

### 3.3 Row Level Security設定

```sql
-- RLSポリシー設定

-- shopping_lists RLS
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分のリストのみアクセス可能"
  ON shopping_lists FOR ALL
  USING (created_by = auth.uid());

-- shopping_items RLS
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分のリストのアイテムのみアクセス可能"
  ON shopping_items FOR ALL
  USING (
    list_id IN (
      SELECT id FROM shopping_lists 
      WHERE created_by = auth.uid()
    )
  );

-- family_members RLS
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ファミリーメンバーは所属リストのみアクセス可能"
  ON family_members FOR ALL
  USING (user_id = auth.uid());
```

---

## 🔐 4. Google OAuth設定

### 4.1 Google Cloud Console設定

```bash
# 1. Google Cloud Console にアクセス
# https://console.cloud.google.com/

# 2. 新規プロジェクト作成
# - プロジェクト名: otsukaipoint-mvp
# - 場所: 組織なし

# 3. Google+ API 有効化
# APIs & Services > Library > Google+ API > 有効にする
```

### 4.2 OAuth認証情報作成

```bash
# 1. 認証情報 > 認証情報を作成 > OAuth 2.0 クライアント ID

# 2. アプリケーションの種類選択
# - Android アプリケーション
# - iOS アプリケーション
# - ウェブ アプリケーション（開発用）

# 3. 必要情報入力
# Android:
# - パッケージ名: com.example.otsukaipoint
# - SHA-1 証明書フィンガープリント: 開発用証明書から取得

# iOS:
# - Bundle ID: com.example.otsukaipoint
```

### 4.3 Supabase Auth設定

```bash
# Supabase Dashboard > Authentication > Providers

# 1. Google Provider 有効化
# - Enable Google provider: ON
# - Client ID: Google Consoleから取得
# - Client Secret: Google Consoleから取得

# 2. リダイレクトURL設定
# - Authorized redirect URIs:
#   - https://your-project.supabase.co/auth/v1/callback
#   - com.example.otsukaipoint://login-callback
```

---

## 💻 5. アプリケーション実装

### 5.1 基本ファイル構成作成

```bash
# ディレクトリ構造作成
mkdir -p lib/services
mkdir -p lib/providers  
mkdir -p lib/screens
mkdir -p lib/widgets

# 基本ファイル作成
touch lib/services/auth_service.dart
touch lib/services/data_service.dart
touch lib/services/realtime_service.dart
touch lib/providers/providers.dart
touch lib/screens/login_screen.dart
touch lib/screens/list_screen.dart
touch lib/screens/qr_screen.dart
```

### 5.2 main.dart設定

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'おつかいポイント',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}
```

### 5.3 環境変数設定

```dart
// lib/config/environment.dart
class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
}
```

---

## 🔄 6. CI/CD設定

### 6.1 GitHub Repository設定

```bash
# 1. GitHub でリポジトリ作成
# - Repository name: otsukaipoint-mvp
# - Visibility: Private
# - Initialize with README: Yes

# 2. ローカルでGit初期化
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/username/otsukaipoint-mvp.git
git push -u origin main
```

### 6.2 GitHub Actions設定

```yaml
# .github/workflows/main.yml
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

### 6.3 環境変数設定

```bash
# GitHub Repository > Settings > Secrets and variables > Actions

# Repository secrets 追加:
# SUPABASE_URL: https://your-project.supabase.co
# SUPABASE_ANON_KEY: your-anon-key
```

---

## 🧪 7. テスト環境設定

### 7.1 テストファイル作成

```bash
# テストディレクトリ作成
mkdir -p test
touch test/mvp_test.dart
```

### 7.2 基本テスト実装

```dart
// test/mvp_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('MVP Tests', () {
    test('アプリ起動テスト', () {
      expect(1 + 1, 2);
    });
    
    testWidgets('ログイン画面表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Text('テスト'),
        ),
      ));
      
      expect(find.text('テスト'), findsOneWidget);
    });
  });
}
```

---

## 📱 8. Android/iOS設定

### 8.1 Android設定

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.otsukaipoint">
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    
    <application
        android:label="おつかいポイント"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- OAuth リダイレクト -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="com.example.otsukaipoint" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 8.2 iOS設定

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <!-- 既存設定... -->
    
    <!-- カメラ権限 -->
    <key>NSCameraUsageDescription</key>
    <string>QRコードスキャンのためにカメラを使用します</string>
    
    <!-- OAuth リダイレクト -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.example.otsukaipoint</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.example.otsukaipoint</string>
            </array>
        </dict>
    </array>
</dict>
```

---

## ✅ 9. 動作確認チェックリスト

### 9.1 基本動作確認

```bash
# 1. アプリビルド確認
flutter pub get
flutter build apk --debug

# 2. テスト実行確認
flutter test

# 3. 実機/エミュレータ動作確認
flutter run
```

### 9.2 Supabase接続確認

```bash
# Supabase接続テスト
# 1. Dashboard でプロジェクト動作確認
# 2. Authentication タブでGoogle設定確認
# 3. Database タブでテーブル作成確認
# 4. API タブでエンドポイント確認
```

---

## 🚀 10. 本番環境デプロイ準備

### 10.1 本番用Supabaseプロジェクト

```bash
# 1. 本番用プロジェクト作成
# - Name: otsukaipoint-production
# - 同様のスキーマ・RLS設定適用

# 2. 本番用OAuth設定
# - Google Cloud Console で本番用認証情報作成
# - Supabase で本番用Google Provider設定
```

### 10.2 アプリストア準備

```bash
# Android (Google Play Console)
# 1. Google Play Console でアプリ作成
# 2. APK署名設定
# 3. ストア掲載情報入力

# iOS (App Store Connect)
# 1. Apple Developer Program 登録
# 2. App Store Connect でアプリ作成
# 3. Bundle ID設定
```

---

## 📋 11. トラブルシューティング

### 11.1 よくある問題

```bash
# 1. Flutter Doctor エラー
flutter doctor --android-licenses  # Android licenses
flutter config --enable-web        # Web有効化

# 2. Supabase接続エラー
# - URL・APIキー確認
# - ネットワーク接続確認
# - CORS設定確認

# 3. OAuth認証エラー
# - Google Console設定確認
# - リダイレクトURL確認
# - Client ID/Secret確認

# 4. ビルドエラー
flutter clean
flutter pub get
flutter pub deps
```

### 11.2 デバッグ方法

```dart
// デバッグログ追加
print('[DEBUG] Supabase URL: ${Supabase.instance.client.supabaseUrl}');
print('[DEBUG] Current User: ${Supabase.instance.client.auth.currentUser}');
```

---

**技術チームリーダー**: MVP環境構築の完全ガイド  
**修正日**: 2025年09月28日  
**想定作業時間**: 2時間（初回設定）  
**必要スキル**: Flutter基礎・Git基礎・Web管理画面操作