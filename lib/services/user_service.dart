import 'package:supabase_flutter/supabase_flutter.dart';

/// ユーザー管理サービス（PRD v1.3対応）
/// ユーザー登録、取得、役割管理を担当
class UserService {
  final _client = Supabase.instance.client;

  /// ユーザー登録（PRD v1.3: roleをSupabaseに保存）
  ///
  /// [name] ユーザー名
  /// [role] ユーザー役割 ('parent' or 'child')
  ///
  /// デバイス変更・再インストール時の永続性確保のため、
  /// roleをSupabase profilesテーブルに保存
  Future<void> createUser({required String name, required String role}) async {
    try {
      await _client.from('profiles').insert({
        'id': _client.auth.currentUser!.id,
        'name': name,
        'role': role, // PRD v1.3: デバイス変更・再インストール時の永続性確保
      });
      print('ユーザー登録完了: $name ($role)');
    } catch (e) {
      print('ユーザー登録エラー: $e');
      rethrow;
    }
  }

  /// ユーザー情報取得（roleを含む）
  ///
  /// 既存ユーザーログイン時に使用
  /// profilesテーブルからユーザー情報とroleを取得
  ///
  /// Returns: ユーザー情報のMap（id, name, roleを含む）、
  ///          ユーザーが存在しない場合はnull
  Future<Map<String, dynamic>?> getUser() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', _client.auth.currentUser!.id)
          .single();
      print('ユーザー取得: ${response['name']} (${response['role']})');
      return response;
    } catch (e) {
      print('ユーザー取得エラー: $e');
      return null;
    }
  }

  /// ユーザー登録済みチェック
  ///
  /// Google OAuth認証成功後、新規/既存ユーザー判定に使用
  ///
  /// Returns: true - 既存ユーザー（profilesに存在）
  ///          false - 新規ユーザー（profilesに未存在）
  Future<bool> isUserRegistered() async {
    final user = await getUser();
    return user != null;
  }
}
