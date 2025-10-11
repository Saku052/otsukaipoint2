import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_service.dart';

/// RealtimeServiceのProvider
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();

  // Providerが破棄される時にクリーンアップ
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
