import 'package:odd/app_string.dart';
import 'package:odd/data/auth_store.dart';
import 'package:odd/data/map_catalog_store.dart';
import 'package:odd/data/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogMap {
  const CatalogMap({required this.id, required this.name, this.previewImg});

  final String id;
  final String name;
  final String? previewImg;
}

class AdminContent {
  const AdminContent({required this.mapIds, this.dailyId});

  final List<String> mapIds;
  final String? dailyId;
}

/// Lecture / écriture admin (`content` + purges).
class AdminStore {
  const AdminStore();

  bool get isReady => SupabaseConfig.isReady;

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<CatalogMap>> listMaps() async {
    await _ensureReady();
    final rows = await _client
        .from('map_data')
        .select('id, name, previewImg')
        .order('name');
    return [
      for (final row in rows)
        if (row['id'] is String)
          CatalogMap(
            id: row['id'] as String,
            name: (row['name'] as String?) ?? row['id'] as String,
            previewImg: row['previewImg'] as String?,
          ),
    ];
  }

  Future<AdminContent> loadContent() async {
    await _ensureReady();
    final rows = await _client.from('content').select('key, value').inFilter(
      'key',
      ['maps', 'dailyMap'],
    );
    var mapIds = <String>[];
    String? dailyId;
    for (final row in rows) {
      final key = row['key'];
      final value = row['value'];
      if (key == 'maps' && value is List) {
        mapIds = [
          for (final item in value)
            if (item is String && item.isNotEmpty) item,
        ];
      }
      if (key == 'dailyMap' && value is String && value.isNotEmpty) {
        dailyId = value;
      }
    }
    return AdminContent(mapIds: mapIds, dailyId: dailyId);
  }

  Future<void> saveContent({
    required List<String> mapIds,
    String? dailyId,
  }) async {
    await _ensureReady();
    if (mapIds.length > 15) {
      throw MapUploadException(AppString.adminTooManyMaps);
    }
    await _client.rpc(
      'save_content',
      params: {'p_maps': mapIds, 'p_daily': dailyId},
    );
  }

  Future<int> deleteMap(String mapId) async {
    await _ensureReady();
    final deleted = await _client.rpc(
      'delete_map',
      params: {'p_map_id': mapId},
    );
    return _asInt(deleted);
  }

  Future<int> deleteMapTimes(String mapId) async {
    await _ensureReady();
    final deleted = await _client.rpc(
      'delete_map_times',
      params: {'p_map_id': mapId},
    );
    return _asInt(deleted);
  }

  Future<int> deleteAllTimes() async {
    await _ensureReady();
    return _asInt(await _client.rpc('delete_all_times'));
  }

  Future<int> deleteAllUsers() async {
    await _ensureReady();
    return _asInt(await _client.rpc('delete_all_users'));
  }

  Future<void> _ensureReady() async {
    if (!isReady) {
      throw MapUploadException(AppString.mapUploadNeedBackend);
    }
    await const AuthStore().ensureSession();
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
