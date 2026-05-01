import 'package:supabase/supabase.dart';

import 'supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static SupabaseClient get client {
    final activeClient = _client;
    if (activeClient == null) {
      throw StateError('Supabase nao configurado.');
    }

    return activeClient;
  }

  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    _client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
  }
}
