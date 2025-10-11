import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';

/// DataServiceのProvider
final dataServiceProvider = Provider<DataService>((ref) {
  return DataService();
});
