import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QRコード画面（PRD v1.3対応）
///
/// 親ユーザーが家族IDのQRコードを表示して子ユーザーを招待
class QRScreen extends ConsumerWidget {
  final String familyId;

  const QRScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRコード')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // qr_flutterを使ってQRコード表示
              QrImageView(
                data: familyId,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'QRコードを見せて家族を招待',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '家族ID: ${familyId.substring(0, 8)}...',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: familyId));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('家族IDをコピーしました')));
                },
                icon: const Icon(Icons.copy),
                label: const Text('家族IDをコピー'),
              ),
              const SizedBox(height: 16),
              const Text(
                '子ユーザーはこのQRコードをスキャンして家族に参加できます',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
