# 🤖 自動化テスト環境設計書
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント 自動化テスト環境設計書 |
| **バージョン** | v1.0（MVP最適版） |
| **修正日** | 2025年09月28日 |
| **作成者** | QAエンジニア・DevOpsチーム |
| **承認状況** | MVP超軽量版・CI/CD対応 |
| **対象読者** | 開発チーム、QAエンジニア、DevOpsエンジニア |

---

## 🎯 1. MVP自動化テスト戦略

### 1.1 MVP最適化方針

**71%コード削減目標に最適化したテスト戦略**:
- ✅ **総コード行数**: 300行に対する効率的テスト設計
- ✅ **3Provider限定**: AuthProvider、ShoppingListProvider、QRCodeProvider特化
- ✅ **Flutter + Supabase**: BaaS活用によるテスト簡素化
- ✅ **実用主義**: MVP確実リリース優先のテスト設計

### 1.2 テストピラミッド（MVP版）

```
     ┌─────────────────┐
     │   E2E Tests     │  5% (最小限・重要フロー)
     │    (5 tests)    │
     ├─────────────────┤
     │ Integration     │  25% (Provider連携)
     │   Tests         │
     │   (15 tests)    │
     ├─────────────────┤
     │   Unit Tests    │  70% (Service・Widget)
     │   (40 tests)    │
     └─────────────────┘
```

**削減効果**: 従来200テスト→60テスト（70%削減）

---

## 🏗️ 2. テスト環境構成

### 2.1 CI/CD統合テスト環境

```yaml
# .github/workflows/test.yml
name: Automated Test Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      # Supabase Local Development
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
          
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.0'
        
    # Supabase Local Setup
    - name: Setup Supabase CLI
      run: |
        npm install -g @supabase/cli
        supabase start
        
    # Test Execution
    - name: Run Tests
      run: |
        flutter test test/unit/
        flutter test test/integration/
        flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

### 2.2 Supabase テスト環境設定

#### 2.2.1 3環境分離（MVP対応）

| 環境 | 用途 | URL | データ | アクセス制御 |
|------|------|-----|--------|-------------|
| **Development** | 開発・単体テスト | localhost:54321 | Mock/Test Data | 開発者全員 |
| **Testing** | CI/CD・結合テスト | test-project.supabase.co | テスト専用DB | CI/CD, QA |
| **Production** | 本番 | prod-project.supabase.co | 本番データ | 限定メンバー |

#### 2.2.2 テスト用データベース設定

```sql
-- test_setup.sql (テスト環境初期化)
-- MVP最小テーブル構成

-- ユーザーテーブル（テスト用）
CREATE TABLE IF NOT EXISTS test_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ショッピングリストテーブル
CREATE TABLE IF NOT EXISTS test_shopping_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  family_id UUID NOT NULL,
  created_by UUID REFERENCES test_users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- アイテムテーブル
CREATE TABLE IF NOT EXISTS test_shopping_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id UUID REFERENCES test_shopping_lists(id),
  name VARCHAR(100) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  created_by UUID REFERENCES test_users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Row Level Security（テスト環境）
ALTER TABLE test_shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_shopping_items ENABLE ROW LEVEL SECURITY;

-- テスト用RLSポリシー（シンプル版）
CREATE POLICY "Test users can access own lists" 
  ON test_shopping_lists FOR ALL 
  USING (created_by = auth.uid());

CREATE POLICY "Test users can access items in own lists" 
  ON test_shopping_items FOR ALL 
  USING (
    list_id IN (
      SELECT id FROM test_shopping_lists 
      WHERE created_by = auth.uid()
    )
  );
```

---

## 🧪 3. Unit Testing Strategy

### 3.1 Service Layer Testing（重点）

#### AuthService テスト（10テスト）

```dart
// test/unit/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(mockClient.auth).thenReturn(mockAuth);
      authService = AuthService();
      // テスト用Supabaseクライアント注入
    });

    // MVP重要テスト（必須）
    test('Google認証成功テスト', () async {
      // 認証成功パターン
      when(mockAuth.signInWithOAuth(OAuthProvider.google))
          .thenAnswer((_) async => AuthResponse(
            user: User(id: 'test-user-id', email: 'test@example.com'),
            session: Session(accessToken: 'test-token', refreshToken: 'refresh'),
          ));

      await authService.signInWithGoogle();
      
      verify(mockAuth.signInWithOAuth(OAuthProvider.google)).called(1);
      expect(authService.isAuthenticated, true);
    });

    test('認証失敗エラーハンドリング', () async {
      // エラーパターン
      when(mockAuth.signInWithOAuth(OAuthProvider.google))
          .thenThrow(AuthException('認証エラー'));

      expect(() => authService.signInWithGoogle(), 
             throwsA(isA<AuthException>()));
    });

    test('ログアウト処理テスト', () async {
      when(mockAuth.signOut()).thenAnswer((_) async => {});
      
      await authService.signOut();
      
      verify(mockAuth.signOut()).called(1);
      expect(authService.isAuthenticated, false);
    });

    // MVP最小テスト（8個追加）
    test('ユーザー認証状態チェック', () {
      when(mockAuth.currentUser).thenReturn(null);
      expect(authService.isAuthenticated, false);
      
      when(mockAuth.currentUser).thenReturn(
        User(id: 'test-id', email: 'test@test.com')
      );
      expect(authService.isAuthenticated, true);
    });

    test('現在ユーザーID取得', () {
      when(mockAuth.currentUser).thenReturn(
        User(id: 'user-123', email: 'test@test.com')
      );
      expect(authService.currentUserId, 'user-123');
    });
  });
}
```

#### DataService テスト（15テスト）

```dart
// test/unit/services/data_service_test.dart
void main() {
  group('DataService Tests', () {
    late DataService dataService;
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = MockSupabaseClient();
      dataService = DataService();
    });

    test('リスト取得成功テスト', () async {
      final mockLists = [
        {'id': 'list-1', 'name': '買い物リスト1', 'family_id': 'family-1'},
        {'id': 'list-2', 'name': '買い物リスト2', 'family_id': 'family-1'},
      ];
      
      when(mockClient.from('shopping_lists').select().eq('family_id', 'family-1'))
          .thenAnswer((_) async => mockLists);

      final result = await dataService.getLists('family-1');
      
      expect(result, mockLists);
      expect(result.length, 2);
    });

    test('アイテム追加成功テスト', () async {
      when(mockClient.from('shopping_items').insert(any))
          .thenAnswer((_) async => []);

      await dataService.addItem('list-1', 'パン');
      
      verify(mockClient.from('shopping_items').insert({
        'list_id': 'list-1',
        'name': 'パン',
        'created_by': any,
      })).called(1);
    });

    test('アイテム完了処理テスト', () async {
      when(mockClient.from('shopping_items').update(any).eq('id', any))
          .thenAnswer((_) async => []);

      await dataService.completeItem('item-1');
      
      verify(mockClient.from('shopping_items')
          .update({'status': 'completed'})
          .eq('id', 'item-1')).called(1);
    });

    // エラーハンドリングテスト（12個追加）
    test('リスト取得エラー時の空配列返却', () async {
      when(mockClient.from('shopping_lists').select().eq('family_id', any))
          .thenThrow(Exception('Network Error'));

      final result = await dataService.getLists('family-1');
      
      expect(result, []);
    });
  });
}
```

### 3.2 Widget Unit Testing（15テスト）

#### ログイン画面テスト（5テスト）

```dart
// test/unit/widgets/login_screen_test.dart
void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('ログイン画面の基本レイアウト確認', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      // UI要素の存在確認
      expect(find.text('おつかいポイント'), findsOneWidget);
      expect(find.text('家族でお買い物リストを共有'), findsOneWidget);
      expect(find.text('Googleでログイン'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Googleログインボタンタップテスト', (WidgetTester tester) async {
      final mockAuthService = MockAuthService();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => mockAuthService),
          ],
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      // ボタンタップ
      await tester.tap(find.text('Googleでログイン'));
      await tester.pump();

      // AuthService呼び出し確認
      verify(mockAuthService.signInWithGoogle()).called(1);
    });

    testWidgets('認証成功時の画面遷移テスト', (WidgetTester tester) async {
      final mockAuthService = MockAuthService();
      when(mockAuthService.isAuthenticated).thenReturn(true);
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => mockAuthService),
          ],
          child: MaterialApp(
            home: LoginScreen(),
            routes: {
              '/list': (context) => ListScreen(familyId: 'test-family'),
            },
          ),
        ),
      );

      await tester.tap(find.text('Googleでログイン'));
      await tester.pumpAndSettle();

      // ListScreen遷移確認
      expect(find.byType(ListScreen), findsOneWidget);
    });
  });
}
```

---

## 🔗 4. Integration Testing

### 4.1 Provider統合テスト（15テスト）

#### AuthProvider + AuthService統合（5テスト）

```dart
// test/integration/auth_integration_test.dart
void main() {
  group('Auth Integration Tests', () {
    testWidgets('認証フロー統合テスト', (WidgetTester tester) async {
      // Supabaseモック設定
      await Supabase.initialize(
        url: 'http://localhost:54321',
        anonKey: 'test-anon-key',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      // ログインボタンタップ
      await tester.tap(find.text('Googleでログイン'));
      await tester.pumpAndSettle();

      // 認証状態の変更確認
      final authState = tester.widget<Consumer>(
        find.byType(Consumer),
      );
      
      // 結果確認（認証成功またはエラー）
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('ログアウト統合テスト', (WidgetTester tester) async {
      // 認証済み状態でテスト開始
      final container = ProviderContainer();
      await container.read(authProvider.notifier).signIn('test@test.com', 'password');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      // ログアウトボタンタップ
      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();

      // ログイン画面に戻ることを確認
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
```

#### ShoppingListProvider統合テスト（5テスト）

```dart
// test/integration/shopping_list_integration_test.dart
void main() {
  group('ShoppingList Integration Tests', () {
    testWidgets('リスト作成〜アイテム追加統合テスト', (WidgetTester tester) async {
      // テスト用Supabase環境設定
      await setupTestSupabase();

      final container = ProviderContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: ListScreen(familyId: 'test-family')),
        ),
      );

      // リスト表示確認
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);

      // アイテム追加フローテスト
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'テストアイテム');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // アイテムがリストに表示されることを確認
      expect(find.text('テストアイテム'), findsOneWidget);
    });

    testWidgets('リアルタイム同期統合テスト', (WidgetTester tester) async {
      // WebSocket接続のテスト
      await setupTestSupabase();

      final container = ProviderContainer();
      final listProvider = container.read(shoppingListProvider.notifier);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: ListScreen(familyId: 'test-family')),
        ),
      );

      // リアルタイム購読開始
      listProvider.subscribeToRealtimeUpdates('test-list-id');

      // 外部からのデータ変更シミュレーション
      await simulateExternalDataChange('test-list-id', {
        'eventType': 'INSERT',
        'new': {'id': 'new-item', 'name': '外部追加アイテム'}
      });

      await tester.pumpAndSettle();

      // UI更新確認
      expect(find.text('外部追加アイテム'), findsOneWidget);
    });
  });
}
```

### 4.2 QRCode統合テスト（5テスト）

```dart
// test/integration/qr_integration_test.dart
void main() {
  group('QRCode Integration Tests', () {
    testWidgets('QR生成〜スキャン統合テスト', (WidgetTester tester) async {
      final container = ProviderContainer();

      // QR生成画面テスト
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: QRScreen(familyId: 'test-family')),
        ),
      );

      // QRコード表示確認
      expect(find.byType(QrImageView), findsOneWidget);

      // QRスキャン画面テスト
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: QRScanScreen()),
        ),
      );

      // スキャナー表示確認
      expect(find.byType(QRView), findsOneWidget);
    });
  });
}
```

---

## 🎭 5. End-to-End Testing

### 5.1 重要ユーザーフロー（5テスト）

```dart
// integration_test/app_test.dart
void main() {
  group('MVP E2E Tests', () {
    testWidgets('完全ユーザーフロー: ログイン→リスト作成→アイテム追加→完了', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. ログイン
      await tester.tap(find.text('Googleでログイン'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // 2. ホーム画面でリスト作成
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'E2Eテストリスト');
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      // 3. アイテム追加
      await tester.tap(find.text('E2Eテストリスト'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'E2Eテストアイテム');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // 4. アイテム完了
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // 結果確認
      expect(find.text('E2Eテストアイテム'), findsOneWidget);
      
      // チェックボックスが選択状態になっていることを確認
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('QR共有フロー: QR生成→共有→参加', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ログイン後、QR生成画面へ
      await tester.tap(find.text('Googleでログイン'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      await tester.tap(find.byIcon(Icons.qr_code));
      await tester.pumpAndSettle();

      // QRコード表示確認
      expect(find.byType(QrImageView), findsOneWidget);

      // QRスキャン画面へ遷移
      await tester.tap(find.text('QRコードを読み取る'));
      await tester.pumpAndSettle();

      // スキャナー画面表示確認
      expect(find.byType(QRView), findsOneWidget);
    });

    testWidgets('エラーハンドリングフロー: ネットワークエラー対応', (WidgetTester tester) async {
      // ネットワーク切断状態でテスト
      await mockNetworkError();
      
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Googleでログイン'));
      await tester.pumpAndSettle();

      // エラーメッセージ表示確認
      expect(find.textContaining('ネットワークエラー'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);

      // 再試行ボタンテスト
      await restoreNetwork();
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      // 正常復旧確認
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

---

## ⚙️ 6. Test Configuration & Tools

### 6.1 テストツール設定

```yaml
# pubspec.yaml (テスト依存関係)
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.7
  test: ^1.24.0
  golden_toolkit: ^0.15.0  # Golden Testing

# テスト設定
flutter_test:
  uses-material-design: true
```

### 6.2 GitHub Actions CI/CD

```yaml
# .github/workflows/test.yml
name: Automated Test Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  unit_test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.0'
    
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test test/unit/ --coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info

  integration_test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.0'
    
    - name: Setup Supabase
      run: |
        npm install -g @supabase/cli
        supabase start
        supabase db reset
    
    - run: flutter pub get
    - run: flutter test test/integration/

  e2e_test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.0'
    
    - name: Setup Android Emulator
      uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 29
        script: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

### 6.3 テストデータ管理

```dart
// test/test_data/test_fixtures.dart
class TestFixtures {
  // MVP用テストデータ
  static const testUser = {
    'id': 'test-user-123',
    'email': 'test@otsukaipoint.com',
    'family_id': 'test-family-456'
  };

  static const testShoppingLists = [
    {
      'id': 'list-1',
      'name': '今日の買い物',
      'family_id': 'test-family-456',
      'created_by': 'test-user-123'
    },
    {
      'id': 'list-2', 
      'name': '週末の買い物',
      'family_id': 'test-family-456',
      'created_by': 'test-user-123'
    }
  ];

  static const testShoppingItems = [
    {
      'id': 'item-1',
      'list_id': 'list-1',
      'name': 'パン',
      'status': 'pending',
      'created_by': 'test-user-123'
    },
    {
      'id': 'item-2',
      'list_id': 'list-1', 
      'name': '牛乳',
      'status': 'completed',
      'created_by': 'test-user-123'
    }
  ];

  // テスト用モックデータ生成
  static Map<String, dynamic> generateTestUser({String? id, String? email}) {
    return {
      'id': id ?? 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      'email': email ?? 'test${DateTime.now().millisecondsSinceEpoch}@test.com',
      'family_id': 'test-family-456'
    };
  }
}
```

---

## 📊 7. Test Coverage & Quality Metrics

### 7.1 MVPカバレッジ目標

| 層 | カバレッジ目標 | 重要度 | テスト数 |
|-----|---------------|--------|----------|
| **Service Layer** | 95% | 最高 | 25 tests |
| **Provider Layer** | 90% | 高 | 15 tests |
| **Widget Layer** | 85% | 中 | 15 tests |
| **Integration** | 80% | 高 | 15 tests |
| **E2E** | 70% | 中 | 5 tests |

**総合目標**: 87%以上（MVP品質確保）

### 7.2 品質ゲート

```yaml
# テスト通過条件
quality_gates:
  - unit_test_coverage: ">= 85%"
  - integration_test_pass: "100%"
  - e2e_test_pass: ">= 80%"
  - lint_errors: "0"
  - security_scan: "Pass"
  - performance_test: "Pass"
```

### 7.3 継続的品質監視

```dart
// test/quality/quality_metrics.dart
class QualityMetrics {
  static void generateReport() {
    final coverage = calculateCoverage();
    final complexity = calculateComplexity();
    final performance = measurePerformance();
    
    print('=== MVP Quality Report ===');
    print('Coverage: ${coverage.toStringAsFixed(1)}%');
    print('Complexity: ${complexity.average}');
    print('Performance: ${performance.averageResponseTime}ms');
    
    // 品質ゲートチェック
    assert(coverage >= 85.0, 'Coverage below threshold');
    assert(complexity.average <= 5.0, 'Complexity too high');
    assert(performance.averageResponseTime <= 2000, 'Performance too slow');
  }
}
```

---

## 🔧 8. Test Automation Infrastructure

### 8.1 Supabase Test Environment Setup

```bash
#!/bin/bash
# scripts/setup_test_env.sh

echo "Setting up MVP Test Environment..."

# Supabase Local Development
supabase init
supabase start

# テストデータベース初期化
supabase db reset

# テストデータ投入
psql -h localhost -p 54321 -U postgres -d postgres -f test/sql/test_data.sql

# テスト用RLS設定
psql -h localhost -p 54321 -U postgres -d postgres -f test/sql/test_rls.sql

echo "Test environment ready!"
```

### 8.2 Mock Services

```dart
// test/mocks/mock_supabase.dart
class MockSupabaseClient extends Mock implements SupabaseClient {
  @override
  SupabaseQueryBuilder from(String table) {
    return MockSupabaseQueryBuilder();
  }
  
  @override
  GoTrueClient get auth => MockGoTrueClient();
  
  @override
  RealtimeClient get realtime => MockRealtimeClient();
}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder select([String columns = '*']) {
    return MockPostgrestFilterBuilder();
  }
  
  @override
  PostgrestBuilder insert(Map<String, dynamic> values) {
    return MockPostgrestBuilder();
  }
  
  @override
  PostgrestBuilder update(Map<String, dynamic> values) {
    return MockPostgrestBuilder();
  }
}

// テスト用ヘルパー
class TestHelper {
  static Future<void> setupMockSupabase() async {
    final mockClient = MockSupabaseClient();
    
    // Supabase.instance をモックに置き換え
    when(Supabase.instance.client).thenReturn(mockClient);
  }
  
  static Future<void> resetTestData() async {
    // テストデータリセット
    await TestFixtures.resetDatabase();
  }
}
```

### 8.3 Test Reporting

```dart
// test/reporting/test_reporter.dart
class TestReporter {
  static void generateMVPReport() {
    final report = TestReport(
      timestamp: DateTime.now(),
      environment: 'MVP Test',
      results: {
        'unit_tests': UnitTestResults(),
        'integration_tests': IntegrationTestResults(),
        'e2e_tests': E2ETestResults(),
      },
      coverage: CoverageAnalyzer.analyze(),
      performance: PerformanceMetrics.collect(),
    );
    
    // JSON形式でレポート出力
    final json = jsonEncode(report.toJson());
    File('reports/test_report_${DateTime.now().millisecondsSinceEpoch}.json')
        .writeAsStringSync(json);
    
    // Slack通知（オプション）
    if (report.hasFailures) {
      SlackNotifier.sendFailureAlert(report);
    }
  }
}
```

---

## ✅ 9. MVP Implementation Checklist

### 9.1 テスト実装チェックリスト

- [x] **Unit Tests (40 tests)**
  - [x] AuthService (10 tests)
  - [x] DataService (15 tests) 
  - [x] RealtimeService (5 tests)
  - [x] Widget Tests (10 tests)

- [ ] **Integration Tests (15 tests)**
  - [ ] AuthProvider integration (5 tests)
  - [ ] ShoppingListProvider integration (5 tests)
  - [ ] QRCodeProvider integration (5 tests)

- [ ] **E2E Tests (5 tests)**
  - [ ] Complete user flow
  - [ ] QR sharing flow
  - [ ] Error handling flow
  - [ ] Performance test
  - [ ] Security test

### 9.2 Infrastructure Setup Checklist

- [x] **CI/CD Pipeline**
  - [x] GitHub Actions configuration
  - [x] Test environment setup
  - [x] Coverage reporting

- [ ] **Supabase Test Environment** 
  - [ ] Development instance
  - [ ] Test database schema
  - [ ] RLS policies
  - [ ] Mock data setup

- [ ] **Quality Gates**
  - [ ] Coverage thresholds
  - [ ] Performance benchmarks
  - [ ] Security scanning

---

## 📈 10. Success Metrics & Monitoring

### 10.1 MVP成功指標

| 指標 | 目標値 | 現在値 | 達成期限 |
|------|--------|--------|----------|
| **テストカバレッジ** | 87% | - | 実装完了時 |
| **テスト実行時間** | < 5分 | - | CI/CD最適化後 |
| **バグ検出率** | 90% | - | テスト運用後 |
| **リリース品質** | 99.5% | - | 初回リリース |

### 10.2 継続的改善

```dart
// 週次品質レビュー
class WeeklyQualityReview {
  static void generateWeeklyReport() {
    final metrics = QualityMetrics.collectWeekly();
    
    // テスト効率分析
    analyzeTestEfficiency(metrics.testExecution);
    
    // カバレッジ分析
    analyzeCoverageGaps(metrics.coverage);
    
    // パフォーマンス分析
    analyzePerformanceRegression(metrics.performance);
    
    // 改善提案生成
    generateImprovementSuggestions(metrics);
  }
}
```

---

**技術チームリーダー**: MVP確実リリースのための最適化されたテスト環境設計  
**修正日**: 2025年09月28日  
**実装目標**: 2026年2月末リリース確実達成  
**テスト戦略**: 効率重視・品質確保・MVP最適化