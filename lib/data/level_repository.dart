import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:odd/data/map_cache_store.dart';
import 'package:odd/data/map_catalog_store.dart';
import 'package:odd/domain/level_map.dart';

class LevelRepository {
  LevelRepository({MapCacheStore? cache, MapCatalogStore? catalog})
    : _cache = cache ?? MapCacheStore(),
      _catalog = catalog ?? const MapCatalogStore();

  static const indexAsset = 'assets/maps/index.json';
  static const dailyMapFile = 'daily_rome.json';

  final MapCacheStore _cache;
  final MapCatalogStore _catalog;

  /// Maps campagne : `content.maps` + `map_data`, sinon cache, sinon assets.
  /// Si le cache a déjà les mêmes ids, on ne retélécharge pas les payloads.
  Future<List<LevelMap>> loadAll() async {
    try {
      final ids = await _catalog.campaignIds();
      if (ids != null && ids.isNotEmpty) {
        final cached = await _cache.loadCampaign();
        if (sameIds(payloadIds(cached), ids)) {
          return _parseAll(cached!);
        }
        final remote = await _catalog.payloadsForIds(ids);
        if (remote != null && remote.isNotEmpty) {
          await _cache.saveCampaign(remote);
          return _parseAll(remote);
        }
      }
    } catch (_) {}
    final cached = await _cache.loadCampaign();
    if (cached != null && cached.isNotEmpty) {
      return _parseAll(cached);
    }
    return _loadBundledCampaign();
  }

  /// Daily : `content.dailyMap` + `map_data`, sinon cache, sinon asset.
  Future<LevelMap> loadDaily() async {
    try {
      final id = await _catalog.dailyId();
      if (id != null && id.isNotEmpty) {
        final cached = await _cache.loadDaily();
        if (cached != null && cached['id'] == id) {
          return _parseOne(cached);
        }
        final remote = await _catalog.payloadForId(id);
        if (remote != null) {
          await _cache.saveDaily(remote);
          return _parseOne(remote);
        }
      }
    } catch (_) {}
    final cached = await _cache.loadDaily();
    if (cached != null) {
      return _parseOne(cached);
    }
    return load(dailyMapFile);
  }

  /// `null` si `content.maps` / `dailyMap` sont identiques à l'affichage actuel.
  Future<({List<LevelMap> levels, LevelMap daily})?> loadIfCatalogChanged({
    required List<String> campaignIds,
    required String? dailyId,
  }) async {
    if (!_catalog.isReady) {
      return null;
    }
    try {
      final remoteCampaign = await _catalog.campaignIds();
      final remoteDaily = await _catalog.dailyId();
      if (remoteCampaign == null) {
        return null;
      }
      if (sameIds(campaignIds, remoteCampaign) && dailyId == remoteDaily) {
        return null;
      }
      return (levels: await loadAll(), daily: await loadDaily());
    } catch (_) {
      return null;
    }
  }

  static List<String> payloadIds(List<Map<String, dynamic>>? payloads) {
    if (payloads == null) {
      return const [];
    }
    return [
      for (final payload in payloads)
        if (payload['id'] is String) payload['id'] as String,
    ];
  }

  static bool sameIds(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  /// Parse un JSON de map depuis les assets.
  Future<LevelMap> load(String file) async {
    final source = await rootBundle.loadString('assets/maps/$file');
    return LevelMap.parseJson(source, file: file);
  }

  Future<List<LevelMap>> _loadBundledCampaign() async {
    final raw =
        jsonDecode(await rootBundle.loadString(indexAsset))
            as Map<String, dynamic>;
    final files = (raw['levels'] as List).cast<String>();
    final levels = <LevelMap>[];
    for (final file in files) {
      levels.add(await load(file));
    }
    return levels;
  }

  List<LevelMap> _parseAll(List<Map<String, dynamic>> payloads) {
    return [for (final payload in payloads) _parseOne(payload)];
  }

  LevelMap _parseOne(Map<String, dynamic> payload) {
    final id = payload['id'];
    final file = id is String && id.isNotEmpty ? id : 'remote';
    return LevelMap.fromJson(payload, file: file);
  }
}
