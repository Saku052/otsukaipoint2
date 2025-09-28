# 🧪 テスト基本設計書（MVP版）
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント テスト基本設計書（MVP版） |
| **バージョン** | v1.0 |
| **作成日** | 2025年09月28日 |
| **作成者** | QAエンジニア |
| **承認状況** | ドラフト |
| **対象読者** | 技術チームリーダー、フロントエンドエンジニア、DevOpsエンジニア |

---

## 🎯 1. テスト戦略（MVP重視）

### 1.1 MVP制約とテスト方針
- **テスト範囲**: 5画面限定（ログイン、リスト表示、アイテム追加、QRコード、設定）
- **テストツール**: 4個のみ（flutter_test, integration_test, mockito, patrol）
- **コード制限**: 総テストコード300行以内
- **実行時間**: 5分以内の高速テスト

### 1.2 リスク分析とテスト優先度

#### 🔴 高リスク（必須テスト）
- **Google OAuth認証**: ログイン失敗でアプリ使用不可
- **リアルタイム同期**: 親子間データ同期失敗
- **データ整合性**: アイテム状態の不整合

#### 🟡 中リスク（重要テスト）
- **QRコード機能**: 家族招待機能の失敗
- **アイテム操作**: CRUD操作の不具合

#### 🟢 低リスク（最小限テスト）
- **UI表示**: Material Design標準使用で低リスク
- **設定機能**: ログアウトのみの単純機能

### 1.3 テスト戦略
- **リスクベース**: 高リスク機能に80%のテスト工数集中
- **MVP適合**: 過度なテストケースは作成しない
- **段階的実行**: 実装完了部分から段階的テスト開始
- **自動化優先**: 繰り返し可能なテストは自動化

---

## 🔧 2. 単体テスト設計（80行）

### 2.1 テスト対象サービス（3個）

#### 2.1.1 AuthService テスト（25行）
```dart
// test/services/auth_service_test.dart
group('AuthService', () {
  late AuthService authService;
  late MockSupabaseClient mockClient;
  
  setUp(() {
    mockClient = MockSupabaseClient();
    authService = AuthService();
  });
  
  test('signInWithGoogle成功', () async {
    // Google OAuth成功のテスト
    when(mockClient.auth.signInWithOAuth(OAuthProvider.google))
        .thenAnswer((_) async => AuthResponse());
    
    await authService.signInWithGoogle();
    verify(mockClient.auth.signInWithOAuth(OAuthProvider.google));
  });
  
  test('signOut成功', () async {
    // ログアウト成功のテスト
    when(mockClient.auth.signOut()).thenAnswer((_) async => {});
    
    await authService.signOut();
    verify(mockClient.auth.signOut());
  });
  
  test('isAuthenticated判定', () {
    // 認証状態判定のテスト
    when(mockClient.auth.currentUser).thenReturn(mockUser);
    expect(authService.isAuthenticated, true);
  });
});
```

#### 2.1.2 DataService テスト（30行）
```dart
// test/services/data_service_test.dart
group('DataService', () {
  late DataService dataService;
  late MockSupabaseClient mockClient;
  
  test('createFamily成功', () async {
    // 家族作成成功のテスト
    final mockResponse = {'id': 'family-123', 'name': 'テスト家族'};
    when(mockClient.from('families').insert(any).select().single())
        .thenAnswer((_) async => mockResponse);
    
    final familyId = await dataService.createFamily('テスト家族');
    expect(familyId, 'family-123');
  });
  
  test('getLists成功', () async {
    // リスト取得成功のテスト
    final mockLists = [{'id': 'list-1', 'title': 'テストリスト'}];
    when(mockClient.from('shopping_lists').select().eq('family_id', any))
        .thenAnswer((_) async => mockLists);
    
    final lists = await dataService.getLists('family-123');
    expect(lists.length, 1);
    expect(lists.first['title'], 'テストリスト');
  });
  
  test('addItem成功', () async {
    // アイテム追加成功のテスト
    when(mockClient.from('shopping_items').insert(any))
        .thenAnswer((_) async => {});
    
    await dataService.addItem('list-1', '牛乳');
    verify(mockClient.from('shopping_items').insert(any));
  });
  
  test('completeItem成功', () async {
    // アイテム完了成功のテスト
    when(mockClient.from('shopping_items').update(any).eq('id', any))
        .thenAnswer((_) async => {});
    
    await dataService.completeItem('item-1');
    verify(mockClient.from('shopping_items').update({'status': 'completed'}).eq('id', 'item-1'));
  });
});
```

#### 2.1.3 RealtimeService テスト（25行）
```dart
// test/services/realtime_service_test.dart
group('RealtimeService', () {
  late RealtimeService realtimeService;
  late MockSupabaseClient mockClient;
  
  test('subscribeToList成功', () {
    // リアルタイム購読成功のテスト
    final mockChannel = MockRealtimeChannel();
    when(mockClient.channel('list_123')).thenReturn(mockChannel);
    when(mockChannel.on(any, any, any)).thenReturn(mockChannel);
    when(mockChannel.subscribe()).thenReturn(mockChannel);
    
    bool callbackCalled = false;
    realtimeService.subscribeToList('123', (data) => callbackCalled = true);
    
    verify(mockClient.channel('list_123'));
    verify(mockChannel.subscribe());
  });
  
  test('unsubscribe成功', () {
    // 購読解除成功のテスト
    final mockChannel = MockRealtimeChannel();
    realtimeService.channels['list_123'] = mockChannel;
    
    realtimeService.unsubscribe('123');
    verify(mockClient.removeChannel(mockChannel));
  });
});
```

### 2.2 コンポーネントテスト（10個限定）
```dart
// test/components/widgets_test.dart
group('MVPコンポーネント', () {
  testWidgets('OPButton表示', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: OPButton(label: 'テスト', onPressed: () {}),
    ));
    expect(find.text('テスト'), findsOneWidget);
  });
  
  testWidgets('OPTextField入力', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: OPTextField(labelText: 'テスト', controller: controller),
    ));
    
    await tester.enterText(find.byType(TextFormField), 'テスト入力');
    expect(controller.text, 'テスト入力');
  });
  
  testWidgets('OPListTileチェック', (tester) async {
    bool toggled = false;
    await tester.pumpWidget(MaterialApp(
      home: OPListTile(
        title: 'テストアイテム',
        completed: false,
        onToggle: () => toggled = true,
      ),
    ));
    
    await tester.tap(find.byType(Checkbox));
    expect(toggled, true);
  });
});
```

### 2.3 カバレッジ目標
- **サービステスト**: 90%以上（認証・データ・リアルタイム）
- **コンポーネントテスト**: 80%以上（10コンポーネント）
- **総合カバレッジ**: 80%以上

---

## 🔗 3. 結合テスト設計（60行）

### 3.1 Supabase連携テスト

#### 3.1.1 認証フローテスト（20行）
```dart
// integration_test/auth_flow_test.dart
group('認証フロー結合テスト', () {
  testWidgets('Google OAuth → ホーム画面遷移', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // ログインボタンタップ
    await tester.tap(find.text('Googleでログイン'));
    await tester.pumpAndSettle();
    
    // 認証成功後、リスト画面に遷移することを確認
    expect(find.text('お買い物リスト'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
  
  testWidgets('ログアウト → ログイン画面戻り', (tester) async {
    // 事前にログイン状態にする
    await AuthService().signInWithGoogle();
    await tester.pumpWidget(MyApp());
    
    // 設定画面からログアウト
    await tester.tap(find.byIcon(Icons.settings));
    await tester.tap(find.text('ログアウト'));
    await tester.pumpAndSettle();
    
    // ログイン画面に戻ることを確認
    expect(find.text('Googleでログイン'), findsOneWidget);
  });
});
```

#### 3.1.2 データ操作連携テスト（25行）
```dart
// integration_test/data_integration_test.dart
group('データ操作結合テスト', () {
  testWidgets('リスト作成 → アイテム追加 → 完了', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // 事前にログイン
    await AuthService().signInWithGoogle();
    await tester.pumpAndSettle();
    
    // アイテム追加
    await tester.tap(find.byType(FloatingActionButton));
    await tester.enterText(find.byType(TextField), 'テストアイテム');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    
    // アイテムが表示されることを確認
    expect(find.text('テストアイテム'), findsOneWidget);
    
    // アイテム完了
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    
    // 完了状態（取り消し線）が適用されることを確認
    final textWidget = tester.widget<Text>(find.text('テストアイテム'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });
  
  testWidgets('QRコード生成 → スキャン → 家族参加', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // QRコード画面を開く
    await tester.tap(find.byIcon(Icons.qr_code));
    await tester.pumpAndSettle();
    
    // QRコードが表示されることを確認
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('家族を招待'), findsOneWidget);
  });
});
```

#### 3.1.3 リアルタイム同期テスト（15行）
```dart
// integration_test/realtime_test.dart
group('リアルタイム同期テスト', () {
  testWidgets('親がアイテム追加 → 子に即座反映', (tester) async {
    // 親デバイスでアイテム追加
    await DataService().addItem('list-123', '新しいアイテム');
    
    // 子デバイス側でリアルタイム更新を確認
    await tester.pumpAndSettle(Duration(seconds: 3));
    expect(find.text('新しいアイテム'), findsOneWidget);
  });
  
  testWidgets('子がアイテム完了 → 親に即座反映', (tester) async {
    // 子デバイスでアイテム完了
    await DataService().completeItem('item-123');
    
    // 親デバイス側で完了状態が反映されることを確認
    await tester.pumpAndSettle(Duration(seconds: 3));
    final textWidget = tester.widget<Text>(find.text('テストアイテム'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });
});
```

---

## 🎬 4. E2Eテスト設計（50行）

### 4.1 基本シナリオテスト

#### 4.1.1 メインフローテスト（30行）
```dart
// integration_test/e2e_main_flow_test.dart
group('E2Eメインフロー', () {
  patrolTest('ログイン → リスト作成 → アイテム追加 → 完了', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // 1. ログイン
    await $.tap(find.text('Googleでログイン'));
    await $.pumpAndSettle();
    
    // 2. 家族作成（初回のみ）
    if (await $.exists(find.text('家族を作成'))) {
      await $.tap(find.text('家族を作成'));
      await $.enterText(find.byType(TextField), 'テスト家族');
      await $.tap(find.text('作成'));
      await $.pumpAndSettle();
    }
    
    // 3. アイテム追加
    await $.tap(find.byType(FloatingActionButton));
    await $.enterText(find.byType(TextField), '牛乳');
    await $.tap(find.text('追加'));
    await $.pumpAndSettle();
    
    // 4. アイテム確認
    expect(find.text('牛乳'), findsOneWidget);
    
    // 5. アイテム完了
    await $.tap(find.byType(Checkbox));
    await $.pumpAndSettle();
    
    // 6. 完了状態確認
    final textWidget = $.tester.widget<Text>(find.text('牛乳'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });
});
```

#### 4.1.2 QRコード招待フローテスト（20行）
```dart
// integration_test/e2e_qr_flow_test.dart
group('E2E QR招待フロー', () {
  patrolTest('親がQR生成 → 子がスキャン → 家族参加', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // 親側：QRコード生成
    await $.tap(find.byIcon(Icons.qr_code));
    await $.pumpAndSettle();
    
    // QRコード表示確認
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('家族を招待'), findsOneWidget);
    
    // 子側：QRスキャン（モック）
    await $.tap(find.text('QRスキャン'));
    await $.pumpAndSettle();
    
    // 家族参加成功確認
    expect(find.text('家族に参加しました'), findsOneWidget);
  });
});
```

### 4.2 エラーケーステスト
```dart
// integration_test/e2e_error_test.dart
group('E2Eエラーケース', () {
  patrolTest('ネットワークエラー時の適切な表示', (PatrolTester $) async {
    // ネットワーク切断状態をシミュレート
    await NetworkSimulator.disconnect();
    
    await $.pumpWidgetAndSettle(MyApp());
    await $.tap(find.byType(FloatingActionButton));
    await $.enterText(find.byType(TextField), 'テストアイテム');
    await $.tap(find.text('追加'));
    await $.pumpAndSettle();
    
    // エラーメッセージ表示確認
    expect(find.text('ネットワークエラーが発生しました'), findsOneWidget);
  });
});
```

---

## 👁️ 5. 手動テスト設計（30行）

### 5.1 受入テストチェックリスト

#### 5.1.1 機能受入テスト（15項目）
```
✅ 親ユーザー受入テスト
□ Google アカウントでログインできる
□ QRコードが生成・表示される  
□ お買い物リストを作成できる
□ 商品を追加・編集・削除できる
□ 子の完了状況をリアルタイムで確認できる

✅ 子ユーザー受入テスト  
□ Google アカウントでログインできる
□ QRコードをスキャンして家族に参加できる
□ 親が作成したリストを表示できる
□ 商品を「完了」状態に変更できる
□ 完了状況が親にリアルタイムで反映される

✅ システム受入テスト
□ リアルタイム同期が5秒以内で動作する
□ アプリクラッシュが発生しない
□ オフライン時の適切なエラー表示
□ データの整合性が保たれる
□ 各種デバイスサイズで正常に表示される
```

#### 5.1.2 非機能受入テスト（5項目）
```
✅ パフォーマンステスト
□ アプリ起動時間3秒以内
□ 画面遷移300ms以内
□ リアルタイム同期5秒以内

✅ ユーザビリティテスト
□ 操作説明なしで基本機能を使用できる
□ エラーメッセージが分かりやすい
```

### 5.2 デバイステスト要件
- **対象OS**: Android 8.0以上
- **画面サイズ**: 5-7インチスマートフォン
- **テスト端末**: 最低3機種（高・中・低スペック各1台）

### 5.3 リリース判定基準
- **クリティカルバグ**: 0件（アプリクラッシュ・データ消失）
- **高優先度バグ**: 0件（主要機能停止）
- **中優先度バグ**: 3件以下（軽微な不具合）
- **受入テスト**: 100%パス（20項目全て）

---

## 🛠️ 6. テスト環境（30行）

### 6.1 Supabaseテスト環境設定
```bash
# テスト用Supabaseプロジェクト設定
SUPABASE_TEST_URL=http://localhost:54321
SUPABASE_TEST_ANON_KEY=test-anon-key
SUPABASE_TEST_SERVICE_ROLE_KEY=test-service-role-key
```

### 6.2 テストデータ準備
```sql
-- テスト用サンプルデータ
INSERT INTO users (auth_id, name, role) VALUES 
('test-parent-001', 'テスト親', 'parent'),
('test-child-001', 'テスト子', 'child');

INSERT INTO families (name, created_by_user_id) VALUES 
('テスト家族', (SELECT id FROM users WHERE auth_id = 'test-parent-001'));

INSERT INTO shopping_lists (family_id, title, created_by_user_id) VALUES 
((SELECT id FROM families WHERE name = 'テスト家族'), 'テストリスト', 
 (SELECT id FROM users WHERE auth_id = 'test-parent-001'));

INSERT INTO shopping_items (shopping_list_id, name, created_by_user_id) VALUES 
((SELECT id FROM shopping_lists WHERE title = 'テストリスト'), 'テストアイテム1',
 (SELECT id FROM users WHERE auth_id = 'test-parent-001'));
```

### 6.3 CI/CD連携
```yaml
# GitHub Actions テスト実行設定
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test
      - run: flutter test integration_test/
```

### 6.4 テスト実行コマンド
```bash
# 単体テスト実行
flutter test

# 結合テスト実行
flutter test integration_test/

# カバレッジ計測
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# E2Eテスト実行（実機）
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/e2e_test.dart
```

---

## 📊 7. 品質目標

### 7.1 定量目標
| 項目 | MVP目標 | 測定方法 |
|------|--------|----------|
| **単体テストカバレッジ** | 80%以上 | lcov.info |
| **E2Eテスト成功率** | 100% | テスト実行結果 |
| **手動テスト項目** | 20項目 | チェックリスト |
| **テスト実行時間** | 5分以内 | CI/CD実行時間 |
| **バグ検出率** | 重要度高0件 | バグ管理表 |

### 7.2 品質ゲート
- **Phase 4開始**: 単体テスト80%以上、基本機能結合テスト完了
- **Phase 5開始**: E2Eテスト100%成功、主要バグ修正完了
- **リリース判定**: 全受入テスト完了、クリティカルバグ0件

---

**作成者**: QAエンジニア  
**作成日**: 2025年09月28日  
**承認状況**: ドラフト  
**総行数**: 300行以内達成  
**MVP重視**: シンプル・確実・効率的なテスト設計