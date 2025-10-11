import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// ログイン画面（MVP超軽量版）
///
/// Google OAuthでログインするシンプルな画面
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('おつかいポイント'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '家族でお買い物リストを共有',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await authService.signInWithGoogle();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ログインエラー: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Googleでログイン'),
            ),
          ],
        ),
      ),
    );
  }
}
