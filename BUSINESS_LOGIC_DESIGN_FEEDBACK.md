# 🚨 ビジネスロジック詳細設計書 - 修正指示書（第2版）
## 技術チームリーダー承認否決 - 最終警告

---

## 📄 承認状況

| 項目 | 状況 |
|------|------|
| **承認結果** | ❌ **否決** |
| **承認者** | 技術チームリーダー |
| **判定日** | 2025年09月23日 |
| **再提出期限** | 2025年09月24日 12:00 |

---

## 🚨 **重大問題: CEO KPI違反** - データベース・UI/UX設計書との整合性必須

### ⚡ **他の承認済み設計書を参考にすること**
- ✅ データベース詳細設計書：シンプルで実装可能なSQL設計
- ✅ UI/UX詳細設計書：1Widget平均30行の軽量設計
- ❌ ビジネスロジック詳細設計書：過剰な抽象化で実装困難

### ❌ **コード削減64%達成不可能** - 具体的な削減例を提示

#### 問題点1: UseCase過剰複雑化
```dart
// 【問題例】CreateShoppingListUseCase - 75行
// MVP段階では過剰設計
class CreateShoppingListUseCase {
  // 20行の依存性注入
  // 30行のバリデーション
  // 25行のビジネスルール
}

// 【修正要求】シンプル化 - 目標20行以下
class CreateListUseCase {
  final ListRepository _repository;
  
  CreateListUseCase(this._repository);
  
  Future<ShoppingList> call(String name, String familyId) async {
    // バリデーション（3行）
    if (name.isEmpty) throw ValidationException('リスト名は必須です');
    if (name.length > 50) throw ValidationException('リスト名は50文字以内');
    
    // 作成処理（5行）
    final list = ShoppingList(
      id: generateUuid(),
      name: name,
      familyId: familyId,
      createdAt: DateTime.now(),
    );
    
    // 保存（1行）
    return await _repository.create(list);
  }
} // 合計：約15行
```

#### 問題点2: 値オブジェクト乱用
```dart
// 【問題】不要な値オブジェクト
class UserId { final String value; }
class UserName { final String value; }
class FamilyId { final String value; }

// 【修正要求】MVP段階は String で十分
// BAD: 値オブジェクト乱用
class UserId { 
  final String value;
  UserId(this.value);
  // 不要なメソッド多数...
}

// GOOD: シンプルな型定義
typedef UserId = String;
typedef FamilyId = String;
// これだけで型安全性は確保できる
```

### ❌ **拡張性20%以下達成困難**

#### 問題点3: UseCase間高結合
```dart
// 【問題】複雑な依存関係
class CompleteItemUseCase {
  final ItemRepository itemRepo;
  final NotificationService notifyService; 
  final ValidationService validationService;
  final LoggingService loggingService;
  // 4つの依存関係 = 変更影響大
}

// 【修正要求】依存関係最小化 - 最大2個
class CompleteItemUseCase {
  final ItemRepository _repository; // 依存1個のみ
  
  CompleteItemUseCase(this._repository);
  
  Future<void> call(String itemId, String userId) async {
    // シンプルな完了処理
    await _repository.updateStatus(itemId, 'completed', userId);
  }
} // 他のサービスは不要
```

---

## 🔧 **必須修正事項（優先順位順）** - 具体例付き

### ⚠️ **前提：Supabase連携仕様書との整合性**
Supabase連携仕様書が完成しているため、その内容と整合性を取ること：
- Supabase Clientの使用方法に準拠
- RLSを前提とした設計（複雑なビジネスロジックは不要）
- リアルタイム同期を考慮した軽量設計

### 🥇 **最優先: コード量削減**

1. **UseCase簡素化** (現状75行 → 目標20行以下)
   - 過剰なバリデーション削除
   - ビジネスルール最小化
   - 依存性注入簡素化

2. **値オブジェクト削減** (現状15個 → 目標5個以下)
   - MVP必須のみ残存
   - String/int型で代替
   - 型安全性とのバランス

3. **ドメインサービス削減** (現状8個 → 目標3個以下)
   - 本当に必要な共通処理のみ
   - UseCase内直接実装を許容

### 🥈 **第2優先: 依存関係整理**

1. **UseCase依存最小化** (現状平均3-4個 → 目標1-2個)
   - Repository以外の依存削除検討
   - サービス層統合

2. **Provider設計明確化**
   - 6Provider制限への具体的マッピング
   - UseCase→Provider対応表作成

### 🥉 **第3優先: パフォーマンス対応**

1. **実行時間保証** (目標200ms以下)
   - 重いドメインオブジェクト生成削除
   - キャッシュ戦略見直し

---

## 📊 **修正目標値**

| 項目 | 現状 | 目標 | 削減率 |
|------|------|------|--------|
| **UseCase平均行数** | 60-80行 | 15-25行 | **65%削減** |
| **値オブジェクト数** | 15個 | 5個 | **67%削減** |
| **ドメインサービス数** | 8個 | 3個 | **63%削減** |
| **UseCase依存関係** | 3-4個 | 1-2個 | **50%削減** |

**期待コード削減率**: **64%達成**

---

## 🎯 **具体的な実装例** - これを参考に修正

```dart
// ✅ GOOD: シンプルなエンティティ（10行）
class ShoppingList {
  final String id;
  final String familyId;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ShoppingList({required this.id, ...});
}

// ✅ GOOD: 軽量なUseCase（15行）
class GetActiveListsUseCase {
  final ListRepository _repository;
  
  GetActiveListsUseCase(this._repository);
  
  Future<List<ShoppingList>> call(String familyId) async {
    return await _repository.getByFamily(familyId, status: 'active');
  }
}

// ✅ GOOD: シンプルなRepository interface（5行）
abstract class ListRepository {
  Future<ShoppingList> create(ShoppingList list);
  Future<List<ShoppingList>> getByFamily(String familyId, {String? status});
  Future<void> update(ShoppingList list);
  Future<void> delete(String id);
}
```

## ✅ **再承認要件**

### 必須チェック項目
- [ ] UseCase平均行数25行以下
- [ ] 値オブジェクト5個以下
- [ ] UseCase依存関係2個以下  
- [ ] Provider6個制限への明確なマッピング
- [ ] 拡張シナリオで変更率20%以下の実証

### 承認基準
1. **簡潔性**: MVPに必要最小限の実装
2. **保守性**: 理解しやすいコード構造
3. **拡張性**: 将来機能追加時の影響最小化
4. **パフォーマンス**: 200ms実行時間要件達成

---

## 📞 **修正作業指示**

### ビジネスロジック担当エンジニアへ
1. **即座着手**: コード量削減を最優先
2. **相談歓迎**: 設計判断に迷った場合は技術チームリーダーに相談
3. **進捗報告**: 修正進捗を毎日報告

### 期待する修正アプローチ
- **機能削除**: MVP不要な機能の大胆な削除
- **設計簡素化**: 過度な抽象化の排除
- **実装重視**: 理論より実装効率を優先

---

**発行者**: 技術チームリーダー  
**発行日**: 2025年09月23日  
**有効期限**: 2025年09月24日 12:00まで

---

## 🔴 **最終警告事項**

1. **期限厳守**: 24日12:00までに必ず再提出すること
2. **KPI達成必須**: コード削減64%の具体的な証明を含めること
3. **実装可能性**: 実際に動作するコードレベルの設計であること
4. **他設計書参照**: 承認済みのDB・UI/UX設計書の設計思想を参考にすること

### 📊 **削減率の計算方法**
```
前回プロジェクト: UseCase平均100行、エンティティ平均80行
今回目標: UseCase平均20行、エンティティ平均15行
削減率 = (100-20)/100 * 0.5 + (80-15)/80 * 0.5 = 40% + 40.6% = 80.6%
※ 最低でも64%以上の削減を証明すること
```