# 📊 監視・ログ収集設計書（MVP超軽量版）
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント 監視・ログ収集設計書 |
| **バージョン** | v1.0（MVP超軽量版） |
| **修正日** | 2025年09月28日 |
| **作成者** | 技術チームリーダー |
| **承認状況** | MVP超軽量版・print()ログ対応 |
| **対象読者** | 開発チーム・運用チーム |

---

## 🎯 1. MVP超軽量監視戦略

### 1.1 300行コードに最適化された監視

**最小限監視方針**:
- ✅ **ログ方式**: print()のみ使用（複雑なLogger削除）
- ✅ **監視項目**: 5項目に限定（認証・DB・API・エラー・パフォーマンス）
- ✅ **アラート**: Supabase標準機能のみ
- ✅ **ダッシュボード**: Supabase管理画面活用

### 1.2 削除する複雑機能

```
❌ MVP不要機能（削除済み）:
- Logger ライブラリ
- Sentry エラー追跡
- Firebase Analytics
- カスタムダッシュボード
- 複雑なメトリクス収集
- APM ツール
- ログ集約サービス
```

---

## 📱 2. アプリ監視（超シンプル）

### 2.1 print()ログ実装

```dart
// lib/services/auth_service.dart
class AuthService {
  Future<void> signInWithGoogle() async {
    try {
      print('[AUTH] Google認証開始');
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      print('[AUTH] Google認証成功');
    } catch (e) {
      print('[ERROR] 認証エラー: $e');
    }
  }
  
  Future<void> signOut() async {
    try {
      print('[AUTH] ログアウト開始');
      await _client.auth.signOut();
      print('[AUTH] ログアウト完了');
    } catch (e) {
      print('[ERROR] ログアウトエラー: $e');
    }
  }
}
```

### 2.2 データアクセス監視

```dart
// lib/services/data_service.dart
class DataService {
  Future<List<Map<String, dynamic>>> getLists(String familyId) async {
    try {
      print('[DATA] リスト取得開始: $familyId');
      final result = await _client
          .from('shopping_lists')
          .select()
          .eq('family_id', familyId);
      print('[DATA] リスト取得完了: ${result.length}件');
      return result;
    } catch (e) {
      print('[ERROR] リスト取得エラー: $e');
      return [];
    }
  }
  
  Future<void> addItem(String listId, String name) async {
    try {
      print('[DATA] アイテム追加開始: $name');
      await _client.from('shopping_items').insert({
        'list_id': listId,
        'name': name,
        'created_by': _client.auth.currentUser!.id,
      });
      print('[DATA] アイテム追加完了: $name');
    } catch (e) {
      print('[ERROR] アイテム追加エラー: $e');
    }
  }
}
```

### 2.3 リアルタイム監視

```dart
// lib/services/realtime_service.dart
class RealtimeService {
  void subscribeToList(String listId, Function(Map) onUpdate) {
    try {
      print('[REALTIME] 購読開始: $listId');
      _client
          .channel('list_$listId')
          .on(RealtimeListenTypes.postgresChanges,
              ChannelFilter(event: '*', schema: 'public'),
              (payload, [ref]) {
                print('[REALTIME] データ変更: $payload');
                onUpdate(payload);
              })
          .subscribe();
      print('[REALTIME] 購読完了: $listId');
    } catch (e) {
      print('[ERROR] リアルタイムエラー: $e');
    }
  }
}
```

---

## 🖥️ 3. Supabase監視（標準機能活用）

### 3.1 Supabaseダッシュボード監視

**基本メトリクス**:
- **API使用量**: リクエスト数/日
- **データベース**: 接続数・クエリ数
- **認証**: ログイン数・エラー数
- **ストレージ**: 使用量・転送量
- **リアルタイム**: 接続数・メッセージ数

### 3.2 監視設定（Supabase管理画面）

```sql
-- 基本的な監視クエリ（Supabase SQL Editorで実行）

-- 1. 日次ユーザー数
SELECT DATE(created_at) as date, COUNT(*) as daily_users
FROM auth.users 
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date;

-- 2. アクティブリスト数
SELECT COUNT(*) as active_lists
FROM shopping_lists 
WHERE updated_at >= NOW() - INTERVAL '1 day';

-- 3. エラー発生傾向（アプリログから推測）
SELECT DATE(created_at) as date, 
       COUNT(*) as failed_requests
FROM shopping_items 
WHERE created_at >= NOW() - INTERVAL '7 days'
  AND name LIKE '%error%'
GROUP BY DATE(created_at);
```

---

## 🚨 4. アラート設定（最小限）

### 4.1 Supabase標準アラート

**設定項目**:
1. **API制限**: 80%到達時
2. **DB接続**: 上限近接時
3. **ストレージ**: 容量不足時
4. **認証エラー**: 異常増加時

### 4.2 Flutter アプリ内アラート

```dart
// 簡単なエラー表示
class ErrorHandler {
  static void showError(BuildContext context, String message) {
    print('[ERROR] UI表示: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('エラー: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  static void showSuccess(BuildContext context, String message) {
    print('[SUCCESS] UI表示: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

---

## 📈 5. パフォーマンス監視（基本のみ）

### 5.1 レスポンス時間測定

```dart
// 簡単なパフォーマンス測定
class PerformanceMonitor {
  static Future<T> measureTime<T>(
    String operation, 
    Future<T> Function() function
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      print('[PERF] $operation: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      print('[PERF] $operation エラー: ${stopwatch.elapsedMilliseconds}ms - $e');
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }
}

// 使用例
class DataService {
  Future<List<Map<String, dynamic>>> getLists(String familyId) async {
    return PerformanceMonitor.measureTime(
      'リスト取得',
      () => _client.from('shopping_lists').select().eq('family_id', familyId),
    );
  }
}
```

### 5.2 基本パフォーマンス目標

| 操作 | 目標時間 | 監視方法 |
|------|----------|----------|
| **ログイン** | < 3秒 | print()ログ |
| **リスト表示** | < 2秒 | print()ログ |
| **アイテム追加** | < 1秒 | print()ログ |
| **QRコード生成** | < 0.5秒 | print()ログ |

---

## 📋 6. ログ管理（最小限）

### 6.1 開発環境ログ

```dart
// デバッグビルドでのみ詳細ログ
void logDebug(String message) {
  if (kDebugMode) {
    print('[DEBUG] $message');
  }
}

void logInfo(String message) {
  print('[INFO] $message');
}

void logError(String message, [Object? error]) {
  print('[ERROR] $message');
  if (error != null) {
    print('[ERROR] Details: $error');
  }
}
```

### 6.2 本番環境ログ（最小限）

```dart
// 本番環境では重要なログのみ
void logProduction(String level, String message) {
  if (!kDebugMode && level == 'ERROR') {
    print('[$level] $message');
  }
}
```

---

## 🔧 7. 運用手順（超シンプル）

### 7.1 日次チェック項目

```
📋 日次運用チェックリスト:
□ Supabaseダッシュボード確認（5分）
□ API使用量チェック
□ エラー率確認
□ レスポンス時間確認
□ アクティブユーザー数確認
```

### 7.2 障害対応手順

```
🚨 障害発生時の対応:
1. Supabaseステータス確認
2. アプリログ確認（print出力）
3. API制限確認
4. ユーザー報告確認
5. 必要に応じてSupabaseサポートに連絡
```

---

## 💰 8. コスト監視（MVP版）

### 8.1 Supabase使用量監視

**監視項目**:
- **月間API呼び出し**: 50万回/月
- **データベース容量**: 500MB
- **認証ユーザー数**: 10万ユーザー
- **ストレージ**: 1GB
- **帯域幅**: 5GB

### 8.2 コスト削減策

```
💡 MVP運用でのコスト削減:
- 不要なログ削除（print最小限）
- 画像圧縮（QRコードのみ）
- リアルタイム接続最適化
- キャッシュ活用
- API呼び出し最小化
```

---

## ✅ 9. MVP達成確認

### 9.1 超軽量化目標

- [x] **ログライブラリ削除**: print()のみ使用
- [x] **監視項目5個**: 認証・DB・API・エラー・パフォーマンス
- [x] **Supabase標準活用**: カスタムダッシュボード不要
- [x] **運用手順簡素化**: 日次5分チェックのみ

### 9.2 必要最小限の機能確保

- [x] **エラー検出**: print()で十分
- [x] **パフォーマンス監視**: 基本測定のみ
- [x] **アラート**: Supabase標準機能
- [x] **ダッシュボード**: Supabase管理画面

---

**技術チームリーダー**: MVP原則に沿った超軽量監視設計  
**修正日**: 2025年09月28日  
**実装時間**: 1日以内（print()実装のみ）  
**運用負荷**: 日次5分チェック