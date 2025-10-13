import 'package:supabase_flutter/supabase_flutter.dart';

/// 家族管理サービス（PRD v1.3対応）
/// 家族作成、メンバー管理、リスト取得を担当
class FamilyService {
  final _client = Supabase.instance.client;

  /// 家族作成（PRD v1.3: 親ユーザー初回登録時に自動実行）
  ///
  /// [familyName] 家族名
  ///
  /// Returns: 作成された家族のID
  ///
  /// 処理フロー:
  /// 1. familiesテーブルに家族レコード作成
  /// 2. 作成者を自動的にfamily_membersに追加
  Future<String> createFamily(String familyName) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw '未認証ユーザー';

      // 家族作成
      final response = await _client.from('families').insert({
        'name': familyName,
        'created_by_user_id': userId,
      }).select().single();

      final familyId = response['id'] as String;

      // 作成者を自動的にfamily_membersに追加
      await addMember(familyId: familyId, userId: userId);

      print('家族作成完了: $familyId');
      return familyId;
    } catch (e) {
      print('家族作成エラー: $e');
      rethrow;
    }
  }

  /// 家族メンバー追加（QRスキャン後に実行）
  ///
  /// [familyId] 参加する家族のID
  /// [userId] 追加するユーザーのID
  ///
  /// 子ユーザーがQRコードをスキャンした後、
  /// この関数を呼び出して家族に参加
  Future<void> addMember({
    required String familyId,
    required String userId,
  }) async {
    try {
      await _client.from('family_members').insert({
        'family_id': familyId,
        'user_id': userId,
      });
      print('メンバー追加完了: $userId');
    } catch (e) {
      print('メンバー追加エラー: $e');
      rethrow;
    }
  }

  /// ユーザーの家族取得
  ///
  /// 既存ユーザーログイン時に、所属する家族IDを取得
  ///
  /// Returns: 家族ID、所属していない場合はnull
  Future<String?> getUserFamily() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw '未認証ユーザー';

      final response = await _client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        print('ユーザーは家族に所属していません');
        return null;
      }

      final familyId = response['family_id'] as String;
      print('家族取得完了: $familyId');
      return familyId;
    } catch (e) {
      print('家族取得エラー: $e');
      return null;
    }
  }

  /// リスト取得（家族のすべてのリスト）
  ///
  /// [familyId] 家族ID
  ///
  /// Returns: リストのリスト（shopping_listとshopping_itemsを含む）
  Future<List<Map<String, dynamic>>> getLists(String familyId) async {
    try {
      final lists = await _client
          .from('shopping_lists')
          .select('*, shopping_items(*)')
          .eq('family_id', familyId)
          .order('created_at');

      print('リスト取得完了: ${lists.length}件');
      return List<Map<String, dynamic>>.from(lists);
    } catch (e) {
      print('リスト取得エラー: $e');
      return [];
    }
  }

  /// 家族情報取得
  ///
  /// [familyId] 家族ID
  ///
  /// Returns: 家族情報（名前、作成日など）
  Future<Map<String, dynamic>?> getFamilyInfo(String familyId) async {
    try {
      final response = await _client
          .from('families')
          .select()
          .eq('id', familyId)
          .single();

      print('家族情報取得完了: ${response['name']}');
      return response;
    } catch (e) {
      print('家族情報取得エラー: $e');
      return null;
    }
  }
}
