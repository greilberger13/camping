import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseDatabase {
  const SupabaseDatabase._(this.client);

  final SupabaseClient client;
  static SupabaseClient? _cachedClient;
  static Future<SupabaseClient>? _initializing;
  static Future<void>? _signingIn;

  static Future<SupabaseDatabase?> connect({
    SupabaseConfig config = SupabaseConfig.empty,
  }) async {
    if (!config.isConfigured) {
      return null;
    }

    final client = await _clientFor(config);

    if (client.auth.currentSession == null) {
      await (_signingIn ??= _signIn(client));
    }

    return SupabaseDatabase._(client);
  }

  static Future<SupabaseClient> _clientFor(SupabaseConfig config) async {
    final cachedClient = _cachedClient;
    if (cachedClient != null) {
      return cachedClient;
    }

    return _initializing ??= _initialize(config);
  }

  static Future<void> _signIn(SupabaseClient client) async {
    try {
      if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously();
      }
    } finally {
      _signingIn = null;
    }
  }

  static Future<SupabaseClient> _initialize(SupabaseConfig config) async {
    try {
      await Supabase.initialize(
        url: config.url,
        anonKey: config.anonKey,
      );
      _cachedClient = Supabase.instance.client;
      return _cachedClient!;
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }
}
