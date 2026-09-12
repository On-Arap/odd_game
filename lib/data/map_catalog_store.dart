import 'dart:convert';

import 'package:odd/app_string.dart';
import 'package:odd/data/auth_store.dart';
import 'package:odd/data/supabase_config.dart';
import 'package:odd/domain/level_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapUploadException implements Exception {
  const MapUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExistingMapInfo {
  const ExistingMapInfo({required this.name, required this.timeCount});

  final String name;
  final int timeCount;
}

class ParsedMapUpload {
  const ParsedMapUpload({
    required this.id,
    required this.name,
    required this.data,
  });

  final String id;
  final String name;
  final Map<String, dynamic> data;
}

/// Lecture `content` / `map_data`, upload depuis le map maker.
class MapCatalogStore {
  const MapCatalogStore();

  bool get isReady => SupabaseConfig.isReady;

  SupabaseClient get _client => Supabase.instance.client;

  ParsedMapUpload parseJson(String source) {
    late final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw FormatException(AppString.expectedJsonObject);
      }
      data = Map<String, dynamic>.from(decoded);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw FormatException(AppString.invalidJson);
    }
    final map = LevelMap.fromJson(data, file: 'upload.json');
    return ParsedMapUpload(id: map.id, name: map.name, data: data);
  }

  Future<ExistingMapInfo?> existingMap(String id) async {
    await _ensureReady();
    final row = await _client
        .from('map_data')
        .select('name')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    final times = await _client
        .from('best_times')
        .select('user_id')
        .eq('map_id', id);
    return ExistingMapInfo(
      name: row['name'] as String? ?? id,
      timeCount: times.length,
    );
  }

  /// Nouvelle map. N'écrit pas dans `content`.
  Future<void> insertMap(ParsedMapUpload map, {String? previewImg}) async {
    await _ensureReady();
    await _client.from('map_data').insert({
      'id': map.id,
      'name': map.name,
      'data': map.data,
      'previewImg': previewImg,
    });
  }

  /// Écrase la map et supprime les temps associés.
  Future<void> replaceMap(ParsedMapUpload map, {String? previewImg}) async {
    await _ensureReady();
    await _client.rpc(
      'replace_map',
      params: {
        'p_id': map.id,
        'p_name': map.name,
        'p_data': map.data,
        'p_preview': previewImg,
      },
    );
  }

  Future<void> _ensureReady() async {
    if (!isReady) {
      throw MapUploadException(AppString.mapUploadNeedBackend);
    }
    await const AuthStore().ensureSession();
  }

  Future<List<String>?> campaignIds() async {
    if (!isReady) {
      return null;
    }
    return _contentStringList('maps');
  }

  Future<String?> dailyId() async {
    if (!isReady) {
      return null;
    }
    return _contentString('dailyMap');
  }

  Future<List<Map<String, dynamic>>?> campaignPayloads() async {
    final ids = await campaignIds();
    if (ids == null || ids.isEmpty) {
      return null;
    }
    return payloadsForIds(ids);
  }

  Future<List<Map<String, dynamic>>?> payloadsForIds(List<String> ids) async {
    if (!isReady || ids.isEmpty) {
      return null;
    }
    final rows = await _client
        .from('map_data')
        .select('id, data')
        .inFilter('id', ids);
    final byId = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final data = _asMap(row['data']);
      final id = row['id'];
      if (data != null && id is String) {
        byId[id] = data;
      }
    }
    final ordered = <Map<String, dynamic>>[
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    return ordered.isEmpty ? null : ordered;
  }

  Future<Map<String, dynamic>?> dailyPayload() async {
    final id = await dailyId();
    if (id == null || id.isEmpty) {
      return null;
    }
    return payloadForId(id);
  }

  Future<Map<String, dynamic>?> payloadForId(String id) async {
    if (!isReady || id.isEmpty) {
      return null;
    }
    final row = await _client
        .from('map_data')
        .select('data')
        .eq('id', id)
        .maybeSingle();
    return _asMap(row?['data']);
  }

  Future<List<String>?> _contentStringList(String key) async {
    final value = await _contentValue(key);
    if (value is! List) {
      return null;
    }
    return [
      for (final item in value)
        if (item is String && item.isNotEmpty) item,
    ];
  }

  Future<String?> _contentString(String key) async {
    final value = await _contentValue(key);
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  Future<Object?> _contentValue(String key) async {
    final row = await _client
        .from('content')
        .select('value')
        .eq('key', key)
        .maybeSingle();
    return row?['value'];
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
