import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_config.dart';

class AppConfigService {
  final _supabase = Supabase.instance.client;

  Future<AppConfig?> fetchConfig() async {
    try {
      final response = await _supabase
          .from('app_config')
          .select('config')
          .eq('id', 1)
          .maybeSingle();

      if (response != null && response['config'] != null) {
        return AppConfig.fromJson(response['config']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch app configuration: $e');
    }
  }

  Future<void> updateConfig(AppConfig config) async {
    try {
      await _supabase.from('app_config').upsert({
        'id': 1,
        'config': config.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update app configuration: $e');
    }
  }
}
