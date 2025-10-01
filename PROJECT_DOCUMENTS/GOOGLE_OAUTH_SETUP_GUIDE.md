# 🔐 Google OAuth設定ガイド
# おつかいポイント MVP版

---

## 📋 設定手順サマリー

### ⏱️ 所要時間: 約20分

1. **Google Cloud Console設定** (10分)
2. **Supabase設定** (5分)
3. **動作確認** (5分)

---

## 🔧 Step 1: Google Cloud Console設定

### 1.1 プロジェクト作成

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. 新しいプロジェクト作成
   - プロジェクト名: `otsukaipoint-mvp`
   - 組織: なし（個人プロジェクト）

### 1.2 OAuth同意画面設定

1. **APIとサービス** → **OAuth同意画面** を選択
2. **外部** を選択して作成
3. 必須項目入力:
   - アプリ名: `おつかいポイント`
   - ユーザーサポートメール: （あなたのメールアドレス）
   - デベロッパーの連絡先: （あなたのメールアドレス）
4. **保存して次へ**

### 1.3 OAuth認証情報作成

1. **APIとサービス** → **認証情報** を選択
2. **認証情報を作成** → **OAuth 2.0 クライアントID**
3. アプリケーションの種類:
   - **Webアプリケーション** を選択
4. 名前: `otsukaipoint-web-client`
5. **承認済みのリダイレクトURI** に以下を追加:
   ```
   https://YOUR_PROJECT_ID.supabase.co/auth/v1/callback
   ```
   ※ `YOUR_PROJECT_ID` は次のステップで取得
6. **作成** をクリック
7. **クライアントID** と **クライアントシークレット** をコピー（後で使用）

---

## 🔗 Step 2: Supabase設定

### 2.1 Supabaseプロジェクト確認

1. [Supabase Dashboard](https://app.supabase.com/) にログイン
2. プロジェクトを選択
3. **Settings** → **API** で以下を確認:
   - **Project URL**: `SUPABASE_URL`
   - **anon public key**: `SUPABASE_ANON_KEY`

### 2.2 Google Provider有効化

1. **Authentication** → **Providers** を選択
2. **Google** を見つけて **Enable** をクリック
3. Google Cloud Consoleでコピーした情報を入力:
   - **Client ID**: （Step 1.3でコピーしたクライアントID）
   - **Client Secret**: （Step 1.3でコピーしたクライアントシークレット）
4. **Save** をクリック

### 2.3 Redirect URLs設定

1. **Authentication** → **URL Configuration** を選択
2. **Site URL** を確認:
   ```
   https://YOUR_PROJECT_ID.supabase.co
   ```
3. **Redirect URLs** に以下を追加（開発用）:
   ```
   http://localhost:3000/**
   otsukaipoint://login-callback
   ```

---

## 📱 Step 3: Flutter設定

### 3.1 .envファイル作成

`.env.example` をコピーして `.env` を作成:

```bash
cp .env.example .env
```

### 3.2 環境変数設定

`.env` ファイルを編集:

```env
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 3.3 Android設定（必須）

`android/app/src/main/AndroidManifest.xml` に以下を追加:

```xml
<manifest ...>
    <application ...>
        <activity ...>
            <!-- Deep linking for OAuth callback -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="otsukaipoint"
                    android:host="login-callback" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 3.4 iOS設定（将来対応時）

`ios/Runner/Info.plist` に以下を追加:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>otsukaipoint</string>
        </array>
    </dict>
</array>
```

---

## ✅ Step 4: 動作確認

### 4.1 アプリ起動

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 4.2 ログインテスト

1. アプリを起動
2. 「Googleでログイン」ボタンをタップ
3. Googleアカウント選択画面が表示されることを確認
4. アカウント選択後、アプリにリダイレクトされることを確認

### 4.3 確認項目

- [ ] Google OAuth画面が表示される
- [ ] ログイン後アプリに戻る
- [ ] Supabase Dashboardの**Authentication** → **Users**にユーザーが追加される
- [ ] ログアウトが正常に動作する

---

## 🐛 トラブルシューティング

### エラー: redirect_uri_mismatch

**原因**: Google Cloud ConsoleのリダイレクトURIが正しく設定されていない

**解決策**:
1. Google Cloud Console → OAuth認証情報を確認
2. リダイレクトURIに以下が設定されているか確認:
   ```
   https://YOUR_PROJECT_ID.supabase.co/auth/v1/callback
   ```

### エラー: Invalid client

**原因**: SupabaseのClient IDまたはClient Secretが間違っている

**解決策**:
1. Supabase Dashboard → Authentication → Providers → Google
2. Client IDとClient Secretを再確認
3. Google Cloud Consoleで生成した正しい値を入力

### ログイン後アプリに戻らない

**原因**: AndroidManifest.xmlのDeep Link設定が不足

**解決策**:
1. `android/app/src/main/AndroidManifest.xml` を確認
2. Step 3.3の設定を追加

---

## 📊 設定完了チェックリスト

- [ ] Google Cloud Consoleプロジェクト作成完了
- [ ] OAuth同意画面設定完了
- [ ] OAuth認証情報（Client ID/Secret）取得完了
- [ ] Supabase Google Provider有効化完了
- [ ] .envファイル設定完了
- [ ] AndroidManifest.xml設定完了
- [ ] ログインテスト成功

---

**作成日**: 2025年10月1日
**作成者**: ビジネスロジック担当エンジニア
**対象**: 開発チーム全員
