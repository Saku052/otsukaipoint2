import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/family_provider.dart';

/// 役割選択画面（PRD v1.3対応）
/// Google OAuth認証後、新規ユーザーが役割（親/子）を選択
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 親として登録
  Future<void> _registerAsParent() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('名前を入力してください');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 親ユーザー登録
      await ref.read(userServiceProvider).createUser(
            name: name,
            role: 'parent',
          );

      // 家族作成画面へ遷移
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/family_create');
    } catch (e) {
      _showError('登録に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 子として登録
  Future<void> _registerAsChild() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('名前を入力してください');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 子ユーザー登録
      await ref.read(userServiceProvider).createUser(
            name: name,
            role: 'child',
          );

      // QRスキャン画面へ遷移
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/qr_scan');
    } catch (e) {
      _showError('登録に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('役割選択'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'おつかいポイントへようこそ！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'あなたの名前',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            const Text(
              'どちらとして登録しますか？',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _registerAsParent,
              icon: const Icon(Icons.family_restroom),
              label: const Text('親として登録'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _registerAsChild,
              icon: const Icon(Icons.child_care),
              label: const Text('子として登録'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
