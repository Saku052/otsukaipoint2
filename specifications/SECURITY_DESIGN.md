# 🔒 セキュリティ設計書（MVP最小実装版）
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント セキュリティ設計書 |
| **バージョン** | v2.0（MVP最小実装版） |
| **修正日** | 2025年09月28日 |
| **作成者** | 技術チームリーダー |
| **承認状況** | 条件付き承認・最小限実装のみ |
| **実装時間** | 50分で完了 |

---

## 🎯 1. MVP真のセキュリティ戦略

### 1.1 「Supabaseにお任せ」方針

**実装するもの（3つのみ）**:
- ✅ **Google OAuth設定**: 10分
- ✅ **RLS設定**: 30分
- ✅ **環境変数設定**: 10分

**実装しないもの（MVP不要）**:
- ❌ SecurityLogger（print()で十分）
- ❌ AuthWrapper（不要な抽象化）
- ❌ Validator（Supabaseが処理）
- ❌ PerformantSecurity（過剰最適化）
- ❌ セキュリティ監査（MVP不要）

---

## 🔐 2. 認証実装（10分で完了）

### 2.1 AuthService（10行のみ）

```dart
// lib/services/auth_service.dart
class AuthService {
  static Future<void> signIn() async {
    await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
  }
  
  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
  
  static bool get isLoggedIn => 
    Supabase.instance.client.auth.currentUser != null;
}
```

### 2.2 main.dart設定（10行のみ）

```dart
// lib/main.dart
void main() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(MyApp());
}
```

---

## 🛡️ 3. データ保護（30分で完了）

### 3.1 RLS設定（Supabase管理画面で実行）

```sql
-- これだけ実行すれば十分（30分）

-- 1. shopping_lists
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_own_lists" ON shopping_lists 
  FOR ALL USING (auth.uid() = created_by);

-- 2. shopping_items  
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_own_items" ON shopping_items
  FOR ALL USING (
    list_id IN (SELECT id FROM shopping_lists WHERE created_by = auth.uid())
  );

-- 3. family_members
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_own_family" ON family_members
  FOR ALL USING (user_id = auth.uid());
```

### 3.2 自動セキュリティ（実装不要）

**Supabaseが自動処理**:
- **HTTPS暗号化**: 自動
- **SQLインジェクション**: 自動防止
- **データベース暗号化**: AES-256
- **バックアップ暗号化**: 自動
- **XSS対策**: Flutter自動

---

## ⚙️ 4. 環境変数設定（10分で完了）

### 4.1 .env ファイル作成

```bash
# .env（ローカル開発用）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 4.2 Google OAuth設定

**Google Cloud Console**:
1. プロジェクト作成（5分）
2. OAuth認証情報作成（5分）

**Supabase設定**:
1. Google Provider有効化（5分）
2. Client ID/Secret設定（5分）

---

## 📊 5. セキュリティレベル分析

### 5.1 MVP段階で十分なセキュリティ

| 脅威 | 対策 | 実装工数 |
|------|------|----------|
| **不正ログイン** | Google OAuth | ✅ 0分（Supabase） |
| **データ漏洩** | RLS | ✅ 30分 |
| **SQLインジェクション** | パラメータ化 | ✅ 0分（Supabase） |
| **XSS** | サニタイズ | ✅ 0分（Flutter） |
| **CSRF** | トークン | ✅ 0分（Supabase） |

**総実装時間**: 50分

### 5.2 不要な対策（MVP段階）

```
❌ 以下は1000ユーザー超えてから検討:
- 詳細ログ監視
- 侵入検知
- WAF設定
- セキュリティ監査
- 複雑な権限管理
```

---

## ✅ 6. 実装チェックリスト

### 6.1 Step 1: Google OAuth設定（10分）

```
□ Google Cloud Console でプロジェクト作成
□ OAuth認証情報作成  
□ Supabase でGoogle Provider有効化
□ Client ID/Secret設定
```

### 6.2 Step 2: RLS設定（30分）

```
□ shopping_lists RLS有効化
□ shopping_items RLS有効化  
□ family_members RLS有効化
□ 3つのポリシー作成
```

### 6.3 Step 3: アプリ実装（10分）

```
□ AuthService実装（10行）
□ main.dart設定（10行）
□ 環境変数設定
□ 動作確認
```

---

## 🎯 7. 最終判定

### 7.1 実装するもの

**このセクションのみ実装**:
1. Google OAuth設定
2. RLS設定（3ポリシー）
3. 環境変数設定
4. AuthService（20行）

### 7.2 実装しないもの

**以下は削除・実装不要**:
- SecurityLogger
- AuthWrapper  
- Validator
- PerformantSecurity
- セキュリティ監査
- 複雑なバリデーション

---

**技術チームリーダー**: Supabaseにお任せ・50分完了設計  
**修正日**: 2025年09月28日  
**実装時間**: 50分（Google設定10分 + RLS30分 + アプリ10分）  
**セキュリティ方針**: 「セキュリティはSupabaseに任せ、機能開発に集中」