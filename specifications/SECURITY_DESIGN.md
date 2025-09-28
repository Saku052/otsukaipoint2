# 🔒 セキュリティ設計書（MVP超軽量版）
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント セキュリティ設計書 |
| **バージョン** | v1.0（MVP超軽量版） |
| **修正日** | 2025年09月28日 |
| **作成者** | 技術チームリーダー |
| **承認状況** | MVP超軽量版・Supabase標準機能活用 |
| **対象読者** | 開発チーム・セキュリティ担当 |

---

## 🎯 1. MVP超軽量セキュリティ戦略

### 1.1 Supabase標準機能活用

**最小限セキュリティ方針**:
- ✅ **認証**: Supabase Auth（OAuth Google）
- ✅ **認可**: Row Level Security（RLS）のみ
- ✅ **暗号化**: Supabase標準（HTTPS・DB暗号化）
- ✅ **監査**: Supabase標準ログ

### 1.2 削除する複雑機能

```
❌ MVP不要機能（削除済み）:
- カスタム認証システム
- 複雑な権限管理
- セキュリティログ詳細分析
- 侵入検知システム
- WAF設定
- 証明書管理
- セキュリティスキャン
```

---

## 🔐 2. 認証・認可（Supabase標準）

### 2.1 Google OAuth認証

```dart
// lib/services/auth_service.dart（超シンプル）
class AuthService {
  final _client = Supabase.instance.client;
  
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      print('[AUTH] Google認証完了');
    } catch (e) {
      print('[ERROR] 認証エラー: $e');
    }
  }
  
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('[AUTH] ログアウト完了');
    } catch (e) {
      print('[ERROR] ログアウトエラー: $e');
    }
  }
  
  bool get isAuthenticated => _client.auth.currentUser != null;
  String? get currentUserId => _client.auth.currentUser?.id;
}
```

### 2.2 Row Level Security（RLS）設定

```sql
-- MVP必須RLSポリシー（Supabase SQL Editorで実行）

-- 1. shopping_lists テーブル
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分のリストのみアクセス可能"
  ON shopping_lists FOR ALL
  USING (created_by = auth.uid());

-- 2. shopping_items テーブル
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分のリストのアイテムのみアクセス可能"
  ON shopping_items FOR ALL
  USING (
    list_id IN (
      SELECT id FROM shopping_lists 
      WHERE created_by = auth.uid()
    )
  );

-- 3. family_members テーブル（QR共有用）
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ファミリーメンバーは所属リストのみアクセス可能"
  ON family_members FOR ALL
  USING (user_id = auth.uid());
```

---

## 🛡️ 3. データ暗号化（Supabase標準）

### 3.1 通信暗号化

**HTTPS強制設定**:
```dart
// 自動的にHTTPS使用（Supabaseデフォルト）
const supabaseUrl = 'https://your-project.supabase.co';
// HTTP通信は自動的にHTTPSにリダイレクト
```

### 3.2 データベース暗号化

**PostgreSQL標準暗号化**:
- **保存時暗号化**: Supabase標準（AES-256）
- **転送時暗号化**: TLS 1.2+
- **バックアップ暗号化**: Supabase自動

### 3.3 機密データ保護

```dart
// アプリ内での機密データ処理
class SecurityHelper {
  // パスワードやAPIキーは環境変数で管理
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );
  
  // 個人情報の最小限保持
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    return '${username.substring(0, 2)}***@$domain';
  }
}
```

---

## 🔍 4. 入力検証・XSS対策

### 4.1 基本的な入力検証

```dart
// lib/utils/validation.dart（超シンプル）
class Validator {
  static String? validateShoppingItem(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'アイテム名を入力してください';
    }
    if (value.length > 100) {
      return 'アイテム名は100文字以内で入力してください';
    }
    // 基本的なHTMLタグ除去
    final cleanValue = value.replaceAll(RegExp(r'<[^>]*>'), '');
    if (cleanValue != value) {
      return '不正な文字が含まれています';
    }
    return null;
  }
  
  static String? validateFamilyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ファミリー名を入力してください';
    }
    if (value.length > 50) {
      return 'ファミリー名は50文字以内で入力してください';
    }
    return null;
  }
}
```

### 4.2 SQLインジェクション対策

```dart
// Supabaseクライアントは自動的にパラメータ化クエリを使用
class DataService {
  Future<void> addItem(String listId, String name) async {
    try {
      // Supabaseが自動的にSQLインジェクションを防止
      await _client.from('shopping_items').insert({
        'list_id': listId,  // パラメータ化される
        'name': name,       // エスケープされる
        'created_by': _client.auth.currentUser!.id,
      });
    } catch (e) {
      print('[ERROR] アイテム追加エラー: $e');
    }
  }
}
```

---

## 🚫 5. アクセス制御

### 5.1 ルートガード（超シンプル）

```dart
// lib/widgets/auth_wrapper.dart
class AuthWrapper extends StatelessWidget {
  final Widget child;
  
  const AuthWrapper({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.session != null) {
          return child;  // ログイン済み
        } else {
          return LoginScreen();  // 未ログイン
        }
      },
    );
  }
}
```

### 5.2 API アクセス制限

```dart
// Supabase RLSで自動的に制限される
// 追加のチェックは不要（MVP方針）
class APISecurityHelper {
  static bool isValidUser() {
    return Supabase.instance.client.auth.currentUser != null;
  }
  
  static String getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('未認証ユーザー');
    return user.id;
  }
}
```

---

## 📋 6. セキュリティ監査（MVP不要）

### 6.1 MVP期間中の監査

**監査方針**: なし（MVP期間中は監査レス）

### 6.2 Supabase標準ログのみ

**自動記録項目**:
- **ログイン・ログアウト**: Supabase Auth自動記録
- **データアクセス**: PostgreSQL標準ログ
- **API呼び出し**: Supabaseダッシュボード

**カスタムログ**: 実装しない（MVP不要）

---

## ⚙️ 7. セキュリティ設定

### 7.1 Supabase プロジェクト設定

```javascript
// Supabase プロジェクト設定（管理画面で設定）
{
  "auth": {
    "providers": {
      "google": {
        "enabled": true,
        "client_id": "your-google-client-id",
        "secret": "your-google-secret"
      }
    },
    "jwt_secret": "your-jwt-secret",
    "jwt_expiry": 3600,
    "refresh_token_rotation_enabled": true
  },
  "database": {
    "ssl_enforcement": true,
    "connection_pooling": true
  }
}
```

### 7.2 Flutter アプリ設定

```dart
// lib/main.dart（セキュリティ設定）
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-supabase-anon-key',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,  // セキュア認証フロー
    ),
  );
  
  runApp(ProviderScope(child: MyApp()));
}
```

---

## 🔄 8. バックアップ・復旧セキュリティ

### 8.1 Supabase標準バックアップ

**自動バックアップ**:
- **頻度**: 日次自動バックアップ
- **保持期間**: 30日間
- **暗号化**: AES-256暗号化
- **アクセス制御**: プロジェクト管理者のみ

### 8.2 復旧手順

```sql
-- 緊急時の最小限復旧（必要最小限のデータのみ）
-- 1. ユーザーデータ確認
SELECT COUNT(*) FROM auth.users;

-- 2. リストデータ確認
SELECT COUNT(*) FROM shopping_lists;

-- 3. アイテムデータ確認
SELECT COUNT(*) FROM shopping_items;

-- 4. 必要に応じてSupabaseサポートに連絡
```

---

## 🛠️ 9. 開発環境セキュリティ

### 9.1 環境変数管理

```bash
# .env（ローカル開発用）
SUPABASE_URL=https://your-dev-project.supabase.co
SUPABASE_ANON_KEY=your-dev-anon-key

# .env.production（本番用）
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY=your-prod-anon-key
```

### 9.2 コード内機密情報排除

```dart
// ❌ 悪い例
const apiKey = 'sk-1234567890abcdef';

// ✅ 良い例
const apiKey = String.fromEnvironment('API_KEY');

// ❌ 悪い例
print('パスワード: $password');

// ✅ 良い例（MVP：print不使用）
// 認証処理のみ、ログ出力なし
```

---

## ⚡ 10. パフォーマンスとセキュリティのバランス

### 10.1 最適化されたセキュリティチェック

```dart
// セキュリティチェックを最小限に抑制
class PerformantSecurity {
  static bool _authCache = false;
  static DateTime _lastCheck = DateTime.now();
  
  static bool isAuthenticated() {
    // 10秒間キャッシュして性能向上
    final now = DateTime.now();
    if (now.difference(_lastCheck).inSeconds < 10) {
      return _authCache;
    }
    
    _authCache = Supabase.instance.client.auth.currentUser != null;
    _lastCheck = now;
    return _authCache;
  }
}
```

---

## ✅ 11. MVP達成確認

### 11.1 セキュリティ基準達成

- [x] **認証**: Google OAuth（Supabase標準）
- [x] **認可**: RLS 3ポリシー設定
- [x] **暗号化**: HTTPS・DB暗号化（Supabase標準）
- [x] **入力検証**: 基本バリデーション
- [x] **監査**: print()ログ・Supabaseログ

### 11.2 MVP適切なセキュリティレベル

- [x] **基本的な脅威対策**: 完了
- [x] **個人情報保護**: RLSで十分
- [x] **複雑な攻撃**: MVP後対応
- [x] **運用負荷**: 最小限

---

**技術チームリーダー**: MVP に適したセキュリティレベル設計  
**修正日**: 2025年09月28日  
**実装時間**: 1日以内（Supabase設定＋RLS）  
**セキュリティレベル**: MVP適切・基本防御完了