import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/family_provider.dart';
import '../providers/data_provider.dart';
import 'list_screen.dart';

/// QRスキャン画面（PRD v1.3対応）
/// 子ユーザーが親のQRコードをスキャンして家族に参加
class QRScanScreen extends ConsumerStatefulWidget {
  const QRScanScreen({super.key});

  @override
  ConsumerState<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends ConsumerState<QRScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// QRコードスキャン成功時の処理
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? familyId = barcodes.first.rawValue;
    if (familyId == null || familyId.isEmpty) {
      _showError('無効なQRコードです');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 現在のユーザーIDを取得
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showError('ユーザー認証が必要です');
        setState(() => _isProcessing = false);
        return;
      }

      // 家族に参加
      await ref
          .read(familyServiceProvider)
          .addMember(familyId: familyId, userId: userId);

      if (!mounted) return;

      // リスト一覧を取得
      final lists = await ref.read(dataServiceProvider).getLists(familyId);

      if (!mounted) return;

      if (lists.isNotEmpty) {
        // 最初のリストIDを取得
        final listId = lists.first['id'] as String;
        print('家族参加成功、リストID取得: $listId');

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
        _showError('お買い物リストが見つかりません');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showError('家族への参加に失敗しました: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードスキャン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '親のQRコードをスキャンしてください',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'QRコードを枠内に収めてください',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
