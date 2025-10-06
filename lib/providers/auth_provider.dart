import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// AuthServiceのProvider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 認証状態のProvider
final authStateProvider = StreamProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return authService.isAuthenticated;
  });
});
