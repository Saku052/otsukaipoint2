import 'package:supabase_flutter/supabase_flutter.dart';

/// 認証サービス（MVP超軽量版）
///
/// Google OAuth認証、ログイン・ログアウト機能を提供
class AuthService {
  final _client = Supabase.instance.client;

  /// Googleでログイン
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      print('ログイン成功'); // MVP: print()のみ
    } catch (e) {
      print('ログインエラー: $e');
      rethrow;
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('ログアウト成功');
    } catch (e) {
      print('ログアウトエラー: $e');
    }
  }

  /// 認証状態確認
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// 現在のユーザーID取得
  String? get userId => _client.auth.currentUser?.id;
}
