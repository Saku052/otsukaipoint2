import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/family_service.dart';

/// FamilyServiceプロバイダー（PRD v1.3対応）
/// 家族管理サービスを提供
final familyServiceProvider = Provider<FamilyService>((ref) {
  return FamilyService();
});
