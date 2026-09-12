import 'package:odd/data/supabase_config.dart';
import 'package:odd/domain/display_name.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NicknameTakenException implements Exception {
  const NicknameTakenException();
}

/// Session anonyme + profil (pseudo).
class AuthStore {
  const AuthStore();

  bool get isReady => SupabaseConfig.isReady;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> ensureSession() async {
    if (!isReady) {
      return;
    }
    if (_client.auth.currentSession != null) {
      return;
    }
    await _client.auth.signInAnonymously();
  }

  Future<String?> displayName() async {
    if (!isReady) {
      return null;
    }
    await ensureSession();
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return null;
    }
    final row = await _client
        .from('profiles')
        .select('display_name')
        .eq('id', uid)
        .maybeSingle();
    final name = row?['display_name'];
    return name is String ? name : null;
  }

  Future<void> claimName(String raw) async {
    if (!isReady) {
      return;
    }
    final name = DisplayNameRules.normalize(raw);
    if (DisplayNameRules.validate(name) != null) {
      throw ArgumentError.value(raw, 'displayName');
    }
    await ensureSession();
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('not authenticated');
    }
    try {
      await _client.from('profiles').upsert({'id': uid, 'display_name': name});
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const NicknameTakenException();
      }
      rethrow;
    }
  }
}
