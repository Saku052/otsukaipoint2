import 'package:supabase_flutter/supabase_flutter.dart';

/// データサービス（MVP超軽量版）
///
/// 家族・リスト・アイテムのCRUD機能を提供
class DataService {
  final _client = Supabase.instance.client;

  /// プロフィール作成（初回ログイン時）
  Future<void> createProfile(String name) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw '未認証';

      await _client.from('profiles').insert({'id': userId, 'name': name});
      print('プロフィール作成成功');
    } catch (e) {
      print('プロフィール作成エラー: $e');
      rethrow;
    }
  }

  /// 家族作成
  Future<String> createFamily(String familyName) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw '未認証';

      // 家族作成
      final family = await _client
          .from('families')
          .insert({'name': familyName, 'created_by_user_id': userId})
          .select()
          .single();

      final familyId = family['id'] as String;

      // 自分を家族メンバーに追加
      await _client.from('family_members').insert({
        'family_id': familyId,
        'user_id': userId,
      });

      print('家族作成成功: $familyId');
      return familyId;
    } catch (e) {
      print('家族作成エラー: $e');
      rethrow;
    }
  }

  /// 家族参加（QRコードから）
  Future<void> joinFamily(String familyId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw '未認証';

      await _client.from('family_members').insert({
        'family_id': familyId,
        'user_id': userId,
      });
      print('家族参加成功');
    } catch (e) {
      print('家族参加エラー: $e');
      rethrow;
    }
  }

  /// リスト作成
  Future<void> createList(String familyId, String title) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw '未認証';

      await _client.from('shopping_lists').insert({
        'family_id': familyId,
        'title': title,
        'created_by_user_id': userId,
      });
      print('リスト作成成功');
    } catch (e) {
      print('リスト作成エラー: $e');
      rethrow;
    }
  }

  /// リスト取得（家族のすべてのリスト）
  Future<List<Map<String, dynamic>>> getLists(String familyId) async {
    try {
      final lists = await _client
          .from('shopping_lists')
          .select('*, shopping_items(*)')
          .eq('family_id', familyId)
          .order('created_at');

      print('リスト取得成功: ${lists.length}件');
      return List<Map<String, dynamic>>.from(lists);
    } catch (e) {
      print('リスト取得エラー: $e');
      rethrow;
    }
  }

  /// アイテム追加
  Future<void> createItem(String listId, String name) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw '未認証';

      await _client.from('shopping_items').insert({
        'shopping_list_id': listId,
        'name': name,
        'created_by_user_id': userId,
      });
      print('アイテム追加成功');
    } catch (e) {
      print('アイテム追加エラー: $e');
      rethrow;
    }
  }

  /// アイテム完了切り替え
  Future<void> toggleItem(String itemId, bool completed) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw '未認証';

      await _client
          .from('shopping_items')
          .update({
            'completed': completed,
            'completed_by_user_id': completed ? userId : null,
            'completed_at': completed ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', itemId);

      print('アイテム更新成功');
    } catch (e) {
      print('アイテム更新エラー: $e');
      rethrow;
    }
  }

  /// アイテム削除
  Future<void> deleteItem(String itemId) async {
    try {
      await _client.from('shopping_items').delete().eq('id', itemId);
      print('アイテム削除成功');
    } catch (e) {
      print('アイテム削除エラー: $e');
      rethrow;
    }
  }
}
