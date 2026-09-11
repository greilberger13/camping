import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseDatabase {
  const SupabaseDatabase._(this.client);

  final SupabaseClient client;

  static Future<SupabaseDatabase?> connect({
    SupabaseConfig config = SupabaseConfig.empty,
  }) async {
    if (!config.isConfigured) {
      return null;
    }

    await Supabase.initialize(
      url: config.url,
      anonKey: config.anonKey,
    );

    return SupabaseDatabase._(Supabase.instance.client);
  }
}
