// config/supabase_config.dart（10行）
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // テスト用のSupabase URL（実際の値に置き換える必要があります）
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ssnmbokstwtgleejoxww.supabase.co', // テスト用デフォルト
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzbm1ib2tzdHd0Z2xlZWpveHd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwNzMzMzUsImV4cCI6MjA3NDY0OTMzNX0.obvi7S1MwXsfHgte-HObkXqXlJrEqwz41I5_RFkSpWM', // テスト用デフォルト
  );

  static SupabaseClient get client => Supabase.instance.client;
}
