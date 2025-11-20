import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';

/// UserServiceプロバイダー（PRD v1.3対応）
/// ユーザー役割管理サービスを提供
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});
