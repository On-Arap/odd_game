/// Clés publiques via `--dart-define`. Jamais la service role.
abstract final class SupabaseConfig {
  static const _rawUrl = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Project URL seule (`https://xxxx.supabase.co`), sans `/rest/v1`.
  static String get url {
    var value = _rawUrl.trim();
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    const rest = '/rest/v1';
    if (value.endsWith(rest)) {
      value = value.substring(0, value.length - rest.length);
    }
    return value;
  }

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Vrai après [Supabase.initialize] dans bootstrap.
  static var initialized = false;

  static bool get isReady => isConfigured && initialized;
}
