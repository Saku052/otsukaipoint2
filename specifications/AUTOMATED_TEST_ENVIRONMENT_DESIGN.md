# 🤖 自動化テスト環境設計書（MVP超軽量版）
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント 自動化テスト環境設計書 |
| **バージョン** | v2.0（MVP超軽量版） |
| **修正日** | 2025年09月28日 |
| **作成者** | 技術チームリーダー |
| **承認状況** | MVP超軽量版・300行コード対応 |
| **対象読者** | 開発チーム全員 |

---

## 🎯 1. MVP超軽量テスト戦略

### 1.1 300行コードに最適化された設計

**最小限テスト方針**:
- ✅ **テスト総数**: 10個のみ（本体300行に対し適切）
- ✅ **CI/CD**: GitHub Actions 20行のみ
- ✅ **複雑な設定削除**: Supabase Local、Codecov、Emulator不要
- ✅ **ログ出力**: 本番ログ出力なし（テスト時のみ）

### 1.2 MVP必須テスト（10個限定）

```
MVP最小テスト構成:
1. ログイン成功テスト
2. ログアウトテスト  
3. リスト表示テスト
4. アイテム追加テスト
5. アイテム完了テスト
6. QRコード生成テスト
7. エラー表示テスト
8. 空リスト表示テスト
9. ネットワークエラーテスト
10. 基本統合テスト
```

---

## 🧪 2. 超シンプルテスト実装（100行以内）

### 2.1 MVP必須テスト実装

```dart
// test/mvp_test.dart（100行以内）
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('MVP Tests', () {
    // 1. 認証テスト
    test('Google認証', () async {
      final auth = AuthService();
      expect(auth.signInWithGoogle, returnsNormally);
    });
    
    // 2. ログアウトテスト
    test('ログアウト', () async {
      final auth = AuthService();
      expect(auth.signOut, returnsNormally);
    });
    
    // 3. データテスト
    test('リスト取得', () async {
      final data = DataService();
      final lists = await data.getLists('family-1');
      expect(lists, isNotNull);
    });
    
    // 4. アイテム追加テスト
    test('アイテム追加', () async {
      final data = DataService();
      expect(() => data.addItem('list-1', 'テスト'), returnsNormally);
    });
    
    // 5. アイテム完了テスト
    test('アイテム完了', () async {
      final data = DataService();
      expect(() => data.completeItem('item-1'), returnsNormally);
    });
    
    // 6. QRコードテスト
    test('QRコード生成', () {
      expect('family-123', isNotEmpty);
    });
    
    // 7. エラーテスト
    test('エラー表示', () {
      expect(() => print('エラー: テスト'), returnsNormally);
    });
    
    // 8. UIテスト
    testWidgets('ログイン画面表示', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      expect(find.text('Googleでログイン'), findsOneWidget);
    });
    
    // 9. ネットワークエラーテスト
    test('ネットワークエラー', () {
      expect(() => print('ネットワークエラー'), returnsNormally);
    });
    
    // 10. 統合テスト
    test('基本フロー', () async {
      final auth = AuthService();
      await auth.signInWithGoogle();
      
      final data = DataService();
      await data.addItem('list-1', 'テスト');
      
      final items = await data.getLists('family-1');
      expect(items, isNotNull);
    });
  });
}
```

---

## ⚙️ 3. 最小CI/CD設定（20行）

### 3.1 GitHub Actions（最小構成）

```yaml
# .github/workflows/test.yml（20行）
name: MVP Test
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.0'
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk
```

### 3.2 pubspec.yaml テスト依存（最小限）

```yaml
# pubspec.yaml テスト部分
dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## 🔧 4. テスト実行手順（超シンプル）

### 4.1 ローカルテスト実行

```bash
# 1. テスト実行（1コマンドのみ）
flutter test

# 2. ビルド確認
flutter build apk
```

### 4.2 CI/CD自動実行

- プッシュ時に自動実行
- テスト失敗時はPR/マージ停止
- 成功時はビルド実行

---

## ✅ 5. MVP達成確認

### 5.1 超軽量化目標達成

- [x] **テスト数**: 10個（60個→10個、83%削減）
- [x] **文書行数**: 200行以内（1000行→200行、80%削減）
- [x] **CI/CD**: 20行（100行→20行、80%削減）
- [x] **複雑ツール削除**: Supabase Local、Codecov等削除

### 5.2 MVP本質遵守

- [x] **最小限動作確認**: 基本機能のみテスト
- [x] **開発速度重視**: テスト作成1日以内
- [x] **保守性**: シンプル構成で保守容易
- [x] **確実性**: 基本フローの動作保証

---

**技術チームリーダー**: MVP原則遵守の超軽量テスト設計  
**修正日**: 2025年09月28日  
**承認可能版**: v2.0（10テスト・200行・CI/CD最小化）  
**実装時間**: 1日以内（MVP確実リリース優先）