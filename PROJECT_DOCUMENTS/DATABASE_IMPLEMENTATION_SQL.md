# 🗄️ データベース実装SQL
# おつかいポイント MVP版

---

## 📄 文書情報

| 項目 | 内容 |
|------|------|
| **文書タイトル** | おつかいポイント データベース実装SQL |
| **バージョン** | v1.0 |
| **作成日** | 2025年10月6日 |
| **作成者** | ビジネスロジック担当エンジニア |
| **承認状況** | 実装準備完了 |
| **対象読者** | DevOpsエンジニア、ビジネスロジック担当 |
| **前提文書** | データベース詳細設計書（MVP版）v2.0 |

---

## 🎯 実装サマリー

### 構成概要
- **テーブル数**: 5個（users, families, family_members, shopping_lists, shopping_items）
- **インデックス数**: 5個（最小限のパフォーマンス確保）
- **RLSポリシー数**: 5個（シンプルな認証ベース）
- **トリガー数**: 4個（updated_at自動更新のみ）
- **推定総行数**: 約150行

### MVP設計原則
- ✅ **シンプル性最優先**: お買い物リスト共有の本質のみ実装
- ✅ **5テーブル限定**: MVP必須機能のみ
- ✅ **5インデックス限定**: 最小限のパフォーマンス確保
- ✅ **シンプルRLS**: 過度に細分化されたポリシーを統合
- ✅ **自動更新**: updated_atの自動更新のみ

### 削減効果
| 項目 | 従来設計 | MVP設計 | 削減率 |
|------|----------|---------|--------|
| **テーブル数** | 16テーブル | 5テーブル | **69%削減** |
| **インデックス数** | 15個 | 5個 | **67%削減** |
| **RLSポリシー数** | 25個 | 5個 | **80%削減** |
| **トリガー/関数** | 12個 | 5個 | **58%削減** |
| **実装行数** | 約2,000行 | 約150行 | **92%削減** |

---

## 📝 実装手順

### Step 1: テーブル作成
### Step 2: インデックス作成
### Step 3: RLSポリシー設定
### Step 4: トリガー設定
### Step 5: テストデータ投入（オプション）

**実行環境**: Supabase SQL EditorまたはSupabase CLIマイグレーション

---

## 1️⃣ テーブル作成SQL

```sql
-- ===============================================
-- おつかいポイント MVP データベーススキーマ
-- 5テーブル構成
-- ===============================================

-- 1. usersテーブル（ユーザー管理）
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(10) NOT NULL CHECK (role IN ('parent', 'child')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE users IS 'ユーザー管理（MVP基本機能）';
COMMENT ON COLUMN users.auth_id IS 'Supabase Auth連携用UUID';
COMMENT ON COLUMN users.role IS '親または子の役割';

-- 2. familiesテーブル（家族グループ管理）
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE families IS '家族グループ管理';
COMMENT ON COLUMN families.created_by_user_id IS '家族を作成したユーザー';

-- 3. family_membersテーブル（家族メンバー関係）
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(family_id, user_id)
);

COMMENT ON TABLE family_members IS '家族メンバー関係管理';
COMMENT ON CONSTRAINT family_members_family_id_user_id_key ON family_members IS '同じユーザーが同じ家族に重複参加防止';

-- 4. shopping_listsテーブル（お買い物リスト管理）
CREATE TABLE shopping_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE shopping_lists IS 'お買い物リスト管理';

-- 5. shopping_itemsテーブル（お買い物アイテム管理）
CREATE TABLE shopping_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shopping_list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_by_user_id UUID REFERENCES users(id),
    completed_at TIMESTAMPTZ,
    created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE shopping_items IS 'お買い物アイテム管理';
COMMENT ON COLUMN shopping_items.completed IS 'アイテム完了フラグ';
```

---

## 2️⃣ インデックス作成SQL（5個のみ）

```sql
-- ===============================================
-- MVP必須インデックス（パフォーマンス最適化）
-- ===============================================

-- 1. 認証ID検索（ログイン時に使用）
CREATE INDEX idx_users_auth_id ON users(auth_id);

-- 2. 家族メンバー取得（家族ID→メンバー一覧）
CREATE INDEX idx_family_members_family_id ON family_members(family_id);

-- 3. 家族のリスト取得（家族ID→リスト一覧）
CREATE INDEX idx_shopping_lists_family_id ON shopping_lists(family_id);

-- 4. リストのアイテム取得（リストID→アイテム一覧）
CREATE INDEX idx_shopping_items_list_id ON shopping_items(shopping_list_id);

-- 5. ユーザーのメンバーシップ取得（ユーザーID→参加家族）
CREATE INDEX idx_family_members_user_id ON family_members(user_id);
```

---

## 3️⃣ RLSポリシー設定SQL（簡素化版）

```sql
-- ===============================================
-- Row Level Security (RLS) ポリシー設定
-- MVP簡素化版：5ポリシー
-- ===============================================

-- RLS有効化
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;

-- 1. users: 自分の情報のみアクセス可能
CREATE POLICY users_policy ON users
    FOR ALL
    TO authenticated
    USING (auth_id = auth.uid());

-- 2. families: 参加している家族のみアクセス可能
CREATE POLICY families_policy ON families
    FOR ALL
    TO authenticated
    USING (
        id IN (
            SELECT family_id FROM family_members
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

-- 3. family_members: 参加している家族のメンバー情報のみアクセス可能
CREATE POLICY family_members_policy ON family_members
    FOR ALL
    TO authenticated
    USING (
        family_id IN (
            SELECT family_id FROM family_members
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

-- 4. shopping_lists: 参加している家族のリストのみアクセス可能
CREATE POLICY shopping_lists_policy ON shopping_lists
    FOR ALL
    TO authenticated
    USING (
        family_id IN (
            SELECT family_id FROM family_members
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

-- 5. shopping_items: 参加している家族のリストのアイテムのみアクセス可能
CREATE POLICY shopping_items_policy ON shopping_items
    FOR ALL
    TO authenticated
    USING (
        shopping_list_id IN (
            SELECT id FROM shopping_lists
            WHERE family_id IN (
                SELECT family_id FROM family_members
                WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
            )
        )
    );
```

---

## 4️⃣ トリガー設定SQL（更新日時自動更新）

```sql
-- ===============================================
-- 更新日時自動更新トリガー（MVP最小限）
-- ===============================================

-- トリガー関数定義
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 各テーブルにトリガー適用
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_families_updated_at
    BEFORE UPDATE ON families
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_lists_updated_at
    BEFORE UPDATE ON shopping_lists
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_items_updated_at
    BEFORE UPDATE ON shopping_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

---

## 5️⃣ テスト用サンプルデータSQL（オプション）

```sql
-- ===============================================
-- MVP機能テスト用サンプルデータ
-- ===============================================

-- サンプルユーザー（親）
INSERT INTO users (auth_id, name, role) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'ママ', 'parent');

-- サンプルユーザー（子）
INSERT INTO users (auth_id, name, role) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'たろう', 'child');

-- サンプル家族
INSERT INTO families (name, created_by_user_id) VALUES
('田中家', (SELECT id FROM users WHERE name = 'ママ'));

-- 家族メンバー追加
INSERT INTO family_members (family_id, user_id) VALUES
((SELECT id FROM families WHERE name = '田中家'), (SELECT id FROM users WHERE name = 'ママ')),
((SELECT id FROM families WHERE name = '田中家'), (SELECT id FROM users WHERE name = 'たろう'));

-- サンプルお買い物リスト
INSERT INTO shopping_lists (family_id, title, created_by_user_id) VALUES
((SELECT id FROM families WHERE name = '田中家'), '今日のお買い物', (SELECT id FROM users WHERE name = 'ママ'));

-- サンプルお買い物アイテム
INSERT INTO shopping_items (shopping_list_id, name, created_by_user_id) VALUES
((SELECT id FROM shopping_lists WHERE title = '今日のお買い物'), '牛乳', (SELECT id FROM users WHERE name = 'ママ')),
((SELECT id FROM shopping_lists WHERE title = '今日のお買い物'), 'パン', (SELECT id FROM users WHERE name = 'ママ'));
```

---

## 🔍 動作確認SQL

```sql
-- ===============================================
-- 実装確認クエリ
-- ===============================================

-- 1. テーブル作成確認
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('users', 'families', 'family_members', 'shopping_lists', 'shopping_items');

-- 2. インデックス確認
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('users', 'families', 'family_members', 'shopping_lists', 'shopping_items');

-- 3. RLS有効化確認
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('users', 'families', 'family_members', 'shopping_lists', 'shopping_items');

-- 4. ポリシー確認
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'public';

-- 5. トリガー確認
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public';
```

---

## 📊 テーブル構成図

```
┌─────────────────────────────────────────────┐
│            users (ユーザー)                   │
│  - id (PK)                                  │
│  - auth_id (UNIQUE) ← Supabase Auth連携     │
│  - name                                     │
│  - role (parent/child)                      │
└─────────────┬───────────────────────────────┘
              │
              ├─────────────────┐
              │                 │
┌─────────────▼───────────┐   ┌▼─────────────────────┐
│  families (家族)         │   │ family_members       │
│  - id (PK)              │◄──┤  (家族メンバー関係)   │
│  - name                 │   │  - id (PK)           │
│  - created_by_user_id   │   │  - family_id (FK)    │
└─────────────┬───────────┘   │  - user_id (FK)      │
              │               └──────────────────────┘
              │
┌─────────────▼─────────────────┐
│  shopping_lists               │
│   (お買い物リスト)              │
│  - id (PK)                    │
│  - family_id (FK)             │
│  - title                      │
│  - created_by_user_id (FK)    │
└─────────────┬─────────────────┘
              │
┌─────────────▼─────────────────┐
│  shopping_items               │
│   (お買い物アイテム)            │
│  - id (PK)                    │
│  - shopping_list_id (FK)      │
│  - name                       │
│  - completed (BOOLEAN)        │
│  - completed_by_user_id (FK)  │
│  - completed_at               │
│  - created_by_user_id (FK)    │
└───────────────────────────────┘
```

---

## 🚀 Supabase実装方法

### 方法1: Supabase SQL Editor（推奨）

1. Supabaseダッシュボードにアクセス
2. プロジェクトを選択
3. 左メニューから「SQL Editor」を選択
4. 新規クエリを作成
5. 上記SQLを順番に実行（Step 1 → 2 → 3 → 4）

### 方法2: Supabase CLIマイグレーション

```bash
# 新規マイグレーションファイル作成
supabase migration new create_mvp_schema

# マイグレーションファイルに上記SQLをコピー
# supabase/migrations/20250101000000_create_mvp_schema.sql

# マイグレーション実行
supabase db push

# リモートDBに適用
supabase db push --db-url $DATABASE_URL
```

---

## ✅ 実装チェックリスト

### データベース構築
- [ ] Step 1: テーブル作成SQL実行完了
- [ ] Step 2: インデックス作成SQL実行完了
- [ ] Step 3: RLSポリシー設定SQL実行完了
- [ ] Step 4: トリガー設定SQL実行完了
- [ ] Step 5: テストデータ投入完了（オプション）

### 動作確認
- [ ] テーブル作成確認（5テーブル）
- [ ] インデックス確認（5インデックス）
- [ ] RLS有効化確認（5テーブル）
- [ ] ポリシー確認（5ポリシー）
- [ ] トリガー確認（4トリガー）

### 機能テスト
- [ ] ユーザー登録テスト
- [ ] 家族作成テスト
- [ ] メンバー追加テスト
- [ ] リスト作成テスト
- [ ] アイテム追加テスト
- [ ] アイテム完了テスト
- [ ] RLSセキュリティテスト

---

## 🔐 セキュリティ確認事項

### RLSポリシー確認
- ✅ 全テーブルでRLS有効化済み
- ✅ 認証済みユーザーのみアクセス可能
- ✅ 自分の家族のデータのみアクセス可能
- ✅ auth.uid()による認証確認実装済み
- ✅ CASCADE削除で孤立データ防止

### アクセス制御
- ✅ 未認証ユーザーはすべてのテーブルにアクセス不可
- ✅ ユーザーは自分の情報のみ参照・更新可能
- ✅ 家族メンバーのみ家族データにアクセス可能
- ✅ リストは家族メンバー間で共有可能

---

## 📈 パフォーマンス指標

### インデックス効果
- **ログイン**: auth_idインデックスにより高速化
- **家族データ取得**: family_idインデックスにより高速化
- **リスト取得**: shopping_list_idインデックスにより高速化
- **メンバー検索**: user_idインデックスにより高速化

### 推定パフォーマンス
- ログイン認証: <50ms
- リスト取得: <100ms
- アイテム追加: <50ms
- リアルタイム同期: <200ms

---

## 🔄 更新履歴

- 2025年10月6日: 初版作成・実装準備完了 (ビジネスロジック担当)

---

**作成者**: ビジネスロジック担当エンジニア
**作成日**: 2025年10月6日
**バージョン**: v1.0
**実装環境**: Supabase PostgreSQL
**対象フェーズ**: Week 1 Day 3-4（データサービス実装）
