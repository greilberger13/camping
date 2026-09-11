class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
  });

  final String url;
  final String anonKey;

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static const empty = SupabaseConfig(url: '', anonKey: '');

  static SupabaseConfig fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    return SupabaseConfig(url: url, anonKey: anonKey);
  }
}
