import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';
import '../providers/data_provider.dart';
import 'list_screen.dart';

/// ログイン画面（PRD v1.3対応）
///
/// Google OAuthでログイン後、新規/既存ユーザーを判定して適切な画面へ遷移
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 既存セッションチェック
    _checkExistingSession();
    // OAuth認証完了を監視
    _setupAuthListener();
  }

  /// 既存セッションがあれば自動ログイン
  Future<void> _checkExistingSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
      await _handleAuthComplete();
    }
  }

  /// OAuth認証状態変更を監視
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        // OAuth認証完了後の処理
        _handleAuthComplete();
      }
    });
  }

  /// OAuth認証完了後の処理（PRD v1.3対応）
  Future<void> _handleAuthComplete() async {
    if (_isLoading) return; // 二重処理防止

    setState(() => _isLoading = true);

    try {
      // ユーザー登録チェック
      final isRegistered = await ref
          .read(userServiceProvider)
          .isUserRegistered();

      if (!mounted) return;

      if (isRegistered) {
        // 既存ユーザー: 家族チェック
        final familyId = await ref.read(familyServiceProvider).getUserFamily();

        if (!mounted) return;

        if (familyId != null) {
          // 家族所属済み → 買い物リスト画面へ
          print('買い物リスト画面へ遷移 family_id: $familyId');

          // リスト一覧を取得
          final lists = await ref.read(dataServiceProvider).getLists(familyId);

          if (!mounted) return;

          if (lists.isNotEmpty) {
            // 最初のリストIDを取得
            final listId = lists.first['id'] as String;
            print('リストID取得: $listId');

            // ListScreenへ遷移
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ListScreen(familyId: familyId, listId: listId),
              ),
            );
          } else {
            // リストが存在しない場合
            print('リストが存在しません');
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('お買い物リストが見つかりません')));
          }
        } else {
          // 家族未所属 → QRスキャン画面へ（孤児状態）
          print('QRスキャン画面へ遷移');
          Navigator.pushReplacementNamed(context, '/qr_scan');
        }
      } else {
        // 新規ユーザー → 役割選択画面へ
        print('役割選択画面へ遷移');
        Navigator.pushReplacementNamed(context, '/role_selection');
      }
    } catch (e) {
      print('認証後エラー: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('認証後エラー: $e')));
      }
    }
  }

  /// Google OAuth開始
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // Google OAuth認証開始（ブラウザが開く）
      await ref.read(authServiceProvider).signInWithGoogle();
      // 認証完了は onAuthStateChange で検知
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ログインエラー: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('おつかいポイント')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('家族でお買い物リストを共有', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Googleでログイン'),
                  ),
          ],
        ),
      ),
    );
  }
}
