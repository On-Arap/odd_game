import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache local des payloads maps téléchargés depuis Supabase.
class MapCacheStore {
  static const campaignKey = 'remote_campaign_maps';
  static const dailyKey = 'remote_daily_map';

  Future<void> saveCampaign(List<Map<String, dynamic>> payloads) {
    return _write(campaignKey, jsonEncode(payloads));
  }

  Future<List<Map<String, dynamic>>?> loadCampaign() async {
    return _readList(campaignKey);
  }

  Future<void> saveDaily(Map<String, dynamic> payload) {
    return _write(dailyKey, jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> loadDaily() async {
    return _readMap(dailyKey);
  }

  Future<void> _write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<List<Map<String, dynamic>>?> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return null;
    }
    return [
      for (final item in decoded)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Future<Map<String, dynamic>?> _readMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  }
}
