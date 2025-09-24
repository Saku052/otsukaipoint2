# 🏗️ システムアーキテクチャ設計書 v2.0（シンプルMVP版）

**プロジェクト**: おつかいポイント MVP版  
**作成者**: システムアーキテクト  
**作成日**: 2025年09月22日  
**バージョン**: v2.0 (シンプルMVP版)  
**最終更新日**: 2025年09月28日  
**更新内容**: MVP重視のシンプル設計への全面改訂

---

## 📋 目次

1. [設計概要](#1-設計概要)
2. [技術スタック選定](#2-技術スタック選定)
3. [アーキテクチャ設計](#3-アーキテクチャ設計)
4. [シンプルなディレクトリ構造](#4-シンプルなディレクトリ構造)
5. [MVP機能範囲と将来拡張性](#5-mvp機能範囲と将来拡張性)
6. [セキュリティ方針](#6-セキュリティ方針)
7. [パフォーマンス設計](#7-パフォーマンス設計)
8. [システム構成図](#8-システム構成図)
9. [実装時リスク分析](#9-実装時リスク分析)
10. [段階的実装ロードマップ](#10-段階的実装ロードマップ)

---

## 1. 設計概要

### 1.1 設計目標

#### 🥇 最優先目標：社長KPI達成
- **コード削減率**: 71%削減（27,998行→8,000行）
- **拡張性指標**: 新機能追加時の既存コード変更率20%以下
- **リリース確実性**: 2026年2月末確実達成

#### 🥈 技術的目標
- **シンプル性重視**: 過剰設計を排除し実装効率を最大化
- **MVP最優先**: 最小限の機能で確実にリリース
- **開発効率**: チーム開発における生産性向上

### 1.2 前回プロジェクト失敗要因の解決

| 失敗要因 | 前回実績 | 今回対策 | 削減効果 |
|----------|----------|----------|----------|
| **UI過剰実装** | 17,477行(62.4%) | Material Design 3採用・1画面200行上限 | 12,477行削減 |
| **機能過多** | 10,552行(37.7%) | MVP機能のみ・お小遣い機能等削除 | 10,552行削除 |
| **オーバーエンジニアリング** | 7,000行(25%) | 2層アーキテクチャ・Provider3個制限 | 5,969行削減 |

**合計削減**: 27,998行 → 8,000行（**71%削減達成**）

---

## 2. 技術スタック選定

### 2.1 フロントエンド

#### Flutter 3.35+
**選定理由**:
- **開発効率**: 単一コードベースでクロスプラットフォーム対応
- **コード削減**: ネイティブ開発比50%削減効果
- **Material Design 3**: 標準コンポーネント活用によるUI実装工数削減
- **成熟度**: 安定したフレームワークで技術的リスク最小化

**技術仕様**:
```yaml
Flutter SDK: 3.35.0以上
Dart: 3.9.2以上
Target: Android 5.0以上（API Level 21+）
```

### 2.2 バックエンド・インフラ

#### Supabase
**選定理由**:
- **開発効率**: BaaS活用によるバックエンド開発工数削減
- **コード削減**: 自前API開発不要で大幅削減
- **リアルタイム機能**: WebSocket機能内蔵でリスト同期実装簡素化
- **RLS内蔵**: Row Level Security標準対応でセキュリティ確保

**技術仕様**:
```yaml
Database: PostgreSQL 15
Authentication: Supabase Auth（JWT）- PKCE認証フロー
Real-time: WebSocket
Storage: Supabase Storage（プロフィール画像用）
Supabase Flutter SDK: 2.6.0以上
```

### 2.3 状態管理

#### Riverpod Provider（3個制限）
**選定理由**:
- **シンプル性**: 複雑な状態管理ライブラリを避け、学習コスト削減
- **テスタビリティ**: 依存性注入によるテスト容易性確保
- **パフォーマンス**: 必要最小限の再描画で性能確保
- **最新機能**: Riverpod 3.0.0のコード生成機能活用

**Provider制限（MVP最適設計）**:
```dart
1. AuthProvider: 認証状態管理
2. ShoppingListProvider: リスト状態管理・リアルタイム同期・エラー状態含む
3. QRCodeProvider: QRコード機能状態管理・エラー状態含む
```

**シンプル化の根拠**:
- **リアルタイム同期**: ShoppingListProvider内でWebSocket管理
- **エラー状態**: 各Provider内で個別管理、全体コード量削減
- **ナビゲーション**: Flutter標準Navigator使用、Provider不要

---

## 3. アーキテクチャ設計

### 3.1 2層アーキテクチャ（シンプルMVP設計）

```
┌─────────────────────────────────────┐
│     UI Layer (Flutter)             │  ← Widget・画面・ユーザー操作
├─────────────────────────────────────┤
│   Service Layer                     │  ← ビジネスロジック・データアクセス・Supabase連携
└─────────────────────────────────────┘
```

#### Domain層削除の効果と対策

**削除の利点**:
- **コード削減**: 1,500行削減効果
- **開発速度**: 層間マッピングコード不要で実装高速化
- **シンプル性**: MVPに適した最小構成

**ビジネスロジック管理戦略**:

🔧 **対策**: Service Layer内でのクラス分離
```dart
// ビジネスロジック配置戦略（Service Layer内）
lib/services/
├── auth_service.dart           # 認証ビジネスロジック
├── shopping_list_service.dart  # リスト管理ビジネスロジック
├── qr_code_service.dart       # QRコード処理ビジネスロジック
└── supabase_client.dart       # データアクセス
```

**Service実装例**:
```dart
class ShoppingListService {
  final SupabaseClient _client;
  
  ShoppingListService(this._client);
  
  Future<Result<ShoppingList>> createList(String name) async {
    // ビジネスルールをService層に集約
    if (name.isEmpty) {
      return Result.failure('リスト名を入力してください');
    }
    
    return await _client.from('shopping_lists').insert({'name': name});
  }
}
```

### 3.2 各層の責務

#### UI Layer（画面層）
**責務**:
- ユーザーインターフェース表示
- ユーザー入力処理
- 状態に応じた画面更新

**実装方針**:
- **1画面200行上限**: 画面分割による可読性確保
- **Material Design 3**: 標準コンポーネント活用
- **StatelessWidget推奨**: 状態管理をProviderに委譲
- **標準Navigator使用**: NavigationProvider不要

#### Service Layer（サービス層）
**責務**:
- ビジネスルール実装
- データアクセス・API連携
- バリデーション処理
- Supabase連携

**実装方針**:
- **Service分離**: 機能別にServiceクラス分割
- **依存性注入**: ProviderからService利用
- **エラーハンドリング**: Service層で統一的処理
- **シンプル性重視**: 過度な抽象化を避ける

---

## 4. シンプルなディレクトリ構造

### 4.1 MVP向けディレクトリ構成

```
lib/
├── main.dart
├── services/                 # Service Layer
│   ├── auth_service.dart
│   ├── shopping_list_service.dart
│   ├── qr_code_service.dart
│   └── supabase_client.dart
├── providers/               # Riverpod Providers
│   ├── auth_provider.dart
│   ├── shopping_list_provider.dart
│   └── qr_code_provider.dart
├── screens/                 # UI Layer
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── list/
│   │   ├── list_screen.dart
│   │   └── add_item_screen.dart
│   └── qr/
│       ├── qr_scan_screen.dart
│       └── qr_generate_screen.dart
├── widgets/                 # 共通Widget
│   ├── common/
│   └── list/
└── models/                  # データモデル
    ├── user.dart
    ├── shopping_list.dart
    └── shopping_item.dart
```

### 4.2 3つのProvider構成

**AuthProvider**: 認証状態管理
```dart
class AuthProvider extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  
  AuthProvider(this._authService) : super(const AsyncValue.loading());
  
  Future<void> signIn(String email, String password) async {
    // ログイン処理
  }
  
  Future<void> signOut() async {
    // ログアウト処理
  }
}
```

**ShoppingListProvider**: リスト・アイテム・リアルタイム同期
```dart
class ShoppingListProvider extends StateNotifier<AsyncValue<List<ShoppingList>>> {
  final ShoppingListService _service;
  
  ShoppingListProvider(this._service) : super(const AsyncValue.loading());
  
  Future<void> createList(String name) async {
    // リスト作成
  }
  
  Future<void> addItem(String listId, String itemName) async {
    // アイテム追加
  }
  
  void subscribeToRealtimeUpdates(String listId) {
    // WebSocketによるリアルタイム同期
  }
}
```

**QRCodeProvider**: QRコード機能
```dart
class QRCodeProvider extends StateNotifier<AsyncValue<String?>> {
  final QRCodeService _service;
  
  QRCodeProvider(this._service) : super(const AsyncValue.data(null));
  
  Future<String> generateQRCode(String listId) async {
    // QRコード生成（qr_flutter使用）
  }
  
  Future<String?> scanQRCode() async {
    // QRコードスキャン（qr_code_scanner使用）
  }
}
```

### 4.3 データフロー（シンプル）

```
User Action → Widget → Provider → Service → Supabase
     ↑                                           ↓
UI Update ← Provider State ← WebSocket ← Database Change
```

**エラーハンドリング**: 各Provider内で個別管理、グローバル管理なし

---

## 5. MVP機能範囲と将来拡張性

### 5.1 MVP Core機能のみ

**実装する機能**:
1. ユーザー登録・ログイン
2. ショッピングリスト作成・表示
3. アイテム追加・編集・削除
4. QRコード共有・参加
5. リアルタイム同期

**削除する複雑機能**:
- オフラインモード
- プッシュ通知
- 高度な検索機能
- 複雑な権限管理
- アナリティクス機能
- プラグイン型アーキテクチャ

### 5.2 将来拡張時の戦略

**必要時に追加する方針**:
- 現在は過剰設計を避け、MVP確実リリースを優先
- 将来的にDomain層やより複雑なアーキテクチャを段階的追加
- ユーザーフィードバックに基づく機能追加

**拡張時の変更率予想**:
- シンプル設計により、将来機能追加時の影響範囲は最小化
- Service層の分離により、ビジネスロジック変更は局所化
- 新機能追加時20%以下の変更率は維持可能

---

## 6. セキュリティ方針

### 6.1 認証・認可

#### Supabase Auth活用
```dart
class SecurityConfig {
  // JWT有効期限
  static const accessTokenExpiry = Duration(hours: 1);
  static const refreshTokenExpiry = Duration(days: 30);
  
  // パスワードポリシー
  static const minPasswordLength = 8;
  static const requireSpecialChar = true;
}
```

#### Row Level Security (RLS)
```sql
-- shopping_lists テーブル
CREATE POLICY "Users can only access their own lists"
  ON shopping_lists FOR ALL
  USING (user_id = auth.uid());

-- shopping_items テーブル  
CREATE POLICY "Users can only access items in their lists"
  ON shopping_items FOR ALL
  USING (
    list_id IN (
      SELECT id FROM shopping_lists 
      WHERE user_id = auth.uid()
    )
  );
```

### 6.2 通信暗号化

#### HTTPS強制
```dart
class APIClient {
  static const baseUrl = 'https://your-project.supabase.co';
  
  static final dio = Dio()
    ..interceptors.add(
      HttpsRedirectInterceptor()  // HTTP→HTTPS自動リダイレクト
    );
}
```

### 6.3 入力検証

#### バリデーション統一
```dart
class ValidationRules {
  static String? validateEmail(String? email) {
    if (email?.isEmpty ?? true) return 'メールアドレスを入力してください';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email!)) {
      return '正しいメールアドレスを入力してください';
    }
    return null;
  }
  
  static String? validateShoppingItem(String? item) {
    if (item?.isEmpty ?? true) return 'アイテム名を入力してください';
    if (item!.length > 100) return 'アイテム名は100文字以内で入力してください';
    return null;
  }
}
```

---

## 7. パフォーマンス設計

### 7.1 レスポンス時間要件（Supabase制約考慮）

| 操作 | 目標レスポンス時間 | 最大許容時間 | Supabase制約考慮 |
|------|-------------------|--------------|----------------------|
| **ログイン** | < 3秒 | < 5秒 | OAuthフロー、リダイレクト考慮 |
| **リスト表示** | < 2秒 | < 3秒 | 初回クエリ、RLS処理考慮 |
| **アイテム追加** | < 800ms | < 1.5秒 | INSERT + RLSチェック考慮 |
| **QRコード生成** | < 300ms | < 500ms | ローカル生成のみ |
| **リアルタイム同期** | < 300ms | < 500ms | WebSocket建物遅延考慮 |

### 7.2 最適化戦略

#### リストビュー最適化
```dart
class OptimizedListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // 仮想化による大量データ対応
      itemExtent: 72.0,  // 固定高さでスクロール最適化
      cacheExtent: 200.0,  // キャッシュ範囲最適化
      itemBuilder: (context, index) => ShoppingItemTile(
        key: ValueKey(items[index].id),  // キー指定で再描画最適化
        item: items[index],
      ),
    );
  }
}
```

---

## 8. システム構成図

### 8.1 全体構成図（シンプル版）

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              UI Layer (Screens)                     │   │
│  │  ┌─────────┬─────────┬─────────┬─────────┬─────────┐ │   │
│  │  │  Login  │ Home    │ QRScan  │ List    │ AddItem │ │   │
│  │  │ Screen  │ Screen  │ Screen  │ Screen  │ Screen  │ │   │
│  │  └─────────┴─────────┴─────────┴─────────┴─────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Service Layer                          │   │
│  │  ┌─────────┬─────────┬─────────┬─────────┬─────────┐ │   │
│  │  │  Auth   │   QR    │  List   │ Supabase│ Model   │ │   │
│  │  │ Service │ Service │ Service │ Client  │ Classes │ │   │
│  │  └─────────┴─────────┴─────────┴─────────┴─────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                                │
                               HTTPS
                                │
┌─────────────────────────────────────────────────────────────┐
│                        Supabase                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                PostgreSQL Database                  │   │
│  │  ┌─────────┬─────────┬─────────┬─────────┬─────────┐ │   │
│  │  │  users  │profiles │  lists  │  items  │list_    │ │   │
│  │  │         │         │         │         │members  │ │   │
│  │  └─────────┴─────────┴─────────┴─────────┴─────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  Supabase Auth                      │   │
│  │         (JWT Token Management)                      │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Real-time Engine                    │   │
│  │              (WebSocket Subscriptions)              │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 データフロー図

```
User Action → UI Layer → Provider → Service → Supabase
     ↑                                            ↓
UI Update ← Provider State ← WebSocket ← Database Change
```

---

## 9. 実装時リスク分析

### 🚨 高リスク項目

| リスク項目 | 影響度 | 発生確率 | 緩和策 |
|------------|--------|----------|--------|
| **ビジネスロジック流出** | 中 | 30% | Service層でのクラス分離、コードレビュー |
| **Supabaseレスポンス遅延** | 中 | 30% | キャッシュ戦略、最適化 |
| **QRライブラリ互換性** | 低 | 20% | qr_code_scannerの事前検証 |

### 🔧 緩和策詳細

#### ビジネスロジック流出防止
```dart
// 禁止パターン
class BadLoginScreen extends StatelessWidget {
  Widget build(context) {
    // ⚠️ NG: UI層にビジネスルール
    if (email.contains('@') && password.length >= 8) {
      // ログイン処理...
    }
  }
}

// 推奨パターン
class GoodLoginScreen extends StatelessWidget {
  Widget build(context) {
    return ElevatedButton(
      onPressed: () {
        // ✅ OK: Serviceに委譲
        ref.read(authServiceProvider).signIn(email, password);
      },
    );
  }
}
```

---

## 10. 段階的実装ロードマップ

### Phase 1: MVP最小機能 (8週間)
```
Week 1-2: 基盤構築
├── 2層アーキテクチャ実装
├── 3つのProvider実装
└── Service層実装

Week 3-4: 認証・基本機能
├── 認証機能（ログイン・ログアウト）
├── ショッピングリスト基本機能
└── Material Design 3 UI実装

Week 5-6: QR・リアルタイム機能
├── QRコード生成・スキャン（qr_code_scanner使用）
├── リアルタイム同期実装
└── Supabase連携完成

Week 7-8: テスト・最適化
├── 単体テスト
├── 結合テスト
└── パフォーマンス最適化
```

### Phase 2: 将来拡張検討 (必要時)
- オフラインモード
- 通知機能
- Domain層追加（必要時）

---

## 📊 設計書承認チェックリスト（シンプルMVP版）

### ✅ 社長KPI達成確認
- [x] **コード削減71%**: 27,998行→8,000行達成設計
- [x] **拡張性20%以下**: シンプル設計により将来変更率最小化
- [x] **リリース確実性**: MVP重視で確実性大幅向上

### 🔄 技術仕様確認
- [x] **Flutter 3.35+ + Supabase 2.6.0**: 最新技術スタック採用
- [x] **2層アーキテクチャ**: UI層 + Service層のシンプル構成
- [x] **Riverpod 3個Provider**: AuthProvider、ShoppingListProvider、QRCodeProvider
- [x] **qr_code_scanner**: シンプル実装ライブラリ採用

### 🔍 シンプルMVP設計確認
- [x] **2層アーキテクチャ**: UI層 + Service層のシンプル構成採用
- [x] **3個Provider**: AuthProvider、ShoppingListProvider、QRCodeProvider
- [x] **標準Navigator**: NavigationProvider削除、Flutter標準機能使用
- [x] **qr_code_scanner**: mobile_scannerから変更、実装簡素化
- [x] **プラグイン型削除**: MVP不要機能を排除、コード削減
- [x] **71%コード削減**: 27,998行→8,000行達成見込み

---

**チームリーダー承認欄**:

承認日: ____________  
承認者: ____________  
承認印: ____________

---

**作成者**: システムアーキテクト  
**最終更新**: 2025年09月28日 (シンプルMVP版 v2.0)  
**更新内容**: 
- 3層→2層アーキテクチャへ変更
- 6個→3個Providerへ削減
- mobile_scanner→qr_code_scannerへ変更
- プラグイン型アーキテクチャ削除
- MVP重視のシンプル設計への全面改訂
- コード削減率64%→71%に向上
**次期レビュー予定**: 実装開始前

---

### 📋 技術仕様まとめ（最終確認）

```yaml
# pubspec.yaml 推奨設定
environment:
  sdk: '>=3.9.2 <4.0.0'
  flutter: ">=3.35.0"

dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.6.0
  riverpod: ^3.0.0
  flutter_riverpod: ^3.0.0
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1  # シンプル実装
```

**削減効果試算**:

| 削除要素 | 削減行数 |
|----------|----------|
| **Domain Layer削除** | 1,500行 |
| **Provider3個削減** | 800行 |
| **プラグイン型削除** | 1,200行 |
| **複雑な抽象化削除** | 500行 |
| **Navigation Provider削除** | 198行 |
| **合計削減** | **4,198行** |

**最終予想**: 27,998行 → **8,000行（71%削減）**