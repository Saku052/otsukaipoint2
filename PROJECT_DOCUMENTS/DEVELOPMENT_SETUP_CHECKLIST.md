# ✅ 開発環境構築チェックリスト
# おつかいポイント MVP版

---

## 📋 環境構築確認（30分）

### Phase 1: 基本環境確認（5分）
- [ ] Flutter 3.35+ インストール済み
  ```bash
  flutter --version
  # Flutter 3.35.0 以上であることを確認
  ```
- [ ] Dart 3.9.2+ インストール済み
  ```bash
  dart --version
  # Dart SDK version: 3.9.2 以上であることを確認
  ```
- [ ] Android Studio インストール済み
- [ ] VS Code インストール済み（推奨）
- [ ] Git設定完了
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```

### Phase 2: プロジェクト設定（10分）
- [ ] リポジトリクローン完了
  ```bash
  git clone https://github.com/[YOUR_ORG]/otsukaipoint2.git
  cd otsukaipoint2
  ```
- [ ] 依存関係インストール完了
  ```bash
  flutter pub get
  # Running "flutter pub get"... と表示されることを確認
  ```
- [ ] 環境変数設定完了
  ```bash
  cp .env.example .env
  # .env ファイルを実際の値で更新
  ```
- [ ] アプリ起動確認完了
  ```bash
  flutter run
  # アプリが正常に起動することを確認
  ```

### Phase 3: Supabase設定（15分）
- [ ] Supabaseアカウント作成済み
- [ ] プロジェクト作成済み
  - プロジェクト名: otsukaipoint-mvp
  - リージョン: Asia Pacific (Tokyo)
- [ ] Project URL取得済み
  - Settings > API > Project URL をコピー
- [ ] API Key取得済み
  - Settings > API > anon public key をコピー
- [ ] 環境変数更新済み
  ```bash
  # .env ファイル
  SUPABASE_URL=https://your-project-id.supabase.co
  SUPABASE_ANON_KEY=your-anon-key-here
  ```
- [ ] データベーステーブル作成済み
  ```sql
  -- SQL Editor で実行
  CREATE TABLE shopping_lists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );
  ```
- [ ] RLS設定済み
  ```sql
  -- SQL Editor で実行
  ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Users can only access their own lists"
    ON shopping_lists FOR ALL
    USING (user_id = auth.uid());
  ```

---

## 🔧 CI/CD設定確認（15分）

### GitHub Actions設定
- [ ] GitHub Repository 作成済み
- [ ] GitHub Actions ワークフロー設定済み
  - `.github/workflows/ci.yml` ファイル存在確認
- [ ] シークレット変数設定済み
  - GitHub Settings > Secrets and variables > Actions
  - `SUPABASE_URL` 設定済み
  - `SUPABASE_ANON_KEY` 設定済み
- [ ] 自動テスト実行確認済み
  ```bash
  git add .
  git commit -m "Initial setup"
  git push origin main
  # GitHub Actions で緑色のチェックマーク確認
  ```

---

## 🧪 テスト実行確認（10分）

### ローカルテスト
- [ ] 単体テスト実行成功
  ```bash
  flutter test
  # All tests passed! を確認
  ```
- [ ] テストカバレッジ確認
  ```bash
  flutter test --coverage
  # Coverage report generated 出力を確認
  ```
- [ ] 静的解析実行成功
  ```bash
  flutter analyze
  # No issues found! を確認
  ```

### ビルド確認
- [ ] デバッグビルド成功
  ```bash
  flutter build apk --debug
  # Built build/app/outputs/flutter-apk/app-debug.apk を確認
  ```
- [ ] リリースビルド成功
  ```bash
  flutter build apk --release
  # Built build/app/outputs/flutter-apk/app-release.apk を確認
  ```

---

## 📱 デプロイ準備確認（10分）

### Google Play Console設定
- [ ] Google Play Console アカウント作成済み
- [ ] 新しいアプリ作成済み
  - アプリ名: おつかいポイント
  - パッケージ名: com.example.otsukaipoint
- [ ] 署名キー作成済み
  ```bash
  keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] 署名設定完了
  - `android/key.properties` ファイル作成済み
  - `android/app/build.gradle` 設定済み

---

## 🚀 最終確認チェック

### 全体動作確認
- [ ] アプリ起動確認
  ```bash
  flutter run
  # アプリが正常に起動
  ```
- [ ] Supabase接続確認
  - ログイン画面でGoogle認証テスト
- [ ] 基本機能確認
  - リスト作成テスト
  - アイテム追加テスト
- [ ] CI/CD動作確認
  - コミット・プッシュでテスト自動実行
- [ ] ビルド確認
  - APKファイル正常生成

### チーム共有
- [ ] 環境構築完了をSlackで報告
- [ ] 開発開始準備完了を技術リーダーに連絡
- [ ] 実装スケジュール確認

---

## ⚠️ トラブルシューティング

### よくあるエラーと解決策

#### Flutter環境エラー
```bash
# flutter doctor でエラーが出る場合
flutter doctor --android-licenses
flutter doctor
```

#### 依存関係エラー
```bash
# pub get でエラーが出る場合
flutter clean
flutter pub get
```

#### Supabase接続エラー
```bash
# 接続エラーの場合
1. .env ファイルの設定値を再確認
2. Supabase プロジェクトの状態確認
3. ネットワーク接続確認
```

---

## 📞 サポート連絡先

- **技術的問題**: tech-leader@company.com
- **Slack**: #tech-support チャンネル
- **緊急時**: #tech-emergency チャンネル

---

**チェックリスト完了日**: ___________  
**確認者**: ___________  
**承認者**: ___________