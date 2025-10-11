import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';

/// QRコード画面（MVP超軽量版）
///
/// 家族招待用のQRコード表示・スキャン機能
/// 注意: qr_flutter パッケージは後で追加
class QRScreen extends ConsumerWidget {
  final String familyId;

  const QRScreen({
    super.key,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // MVP: QRコード表示エリア（後でqr_flutter実装）
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code, size: 100),
                    const SizedBox(height: 8),
                    Text(
                      familyId.substring(0, 8),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'QRコードを見せて家族を招待',
                style: TextStyle(fontSize: 16),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('家族IDをコピーしました')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('家族IDをコピー'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  // MVP: QRスキャン機能（後で実装）
                  final controller = TextEditingController();
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('家族IDを入力'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: '家族ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('参加'),
                        ),
                      ],
                    ),
                  );

                  if (result == true && controller.text.isNotEmpty) {
                    try {
                      final dataService = ref.read(dataServiceProvider);
                      await dataService.joinFamily(controller.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('家族に参加しました')),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('参加エラー: $e')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QRコードスキャン'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
