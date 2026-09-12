import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseDatabase {
  const SupabaseDatabase._(this.client);

  final SupabaseClient client;
  static SupabaseClient? _cachedClient;

  static Future<SupabaseDatabase?> connect({
    SupabaseConfig config = SupabaseConfig.empty,
  }) async {
    if (!config.isConfigured) {
      return null;
    }

    final client = await _clientFor(config);

    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }

    return SupabaseDatabase._(client);
  }

  static Future<SupabaseClient> _clientFor(SupabaseConfig config) async {
    final cachedClient = _cachedClient;
    if (cachedClient != null) {
      return cachedClient;
    }

    await Supabase.initialize(
      url: config.url,
      anonKey: config.anonKey,
    );
    _cachedClient = Supabase.instance.client;
    return _cachedClient!;
  }
}
