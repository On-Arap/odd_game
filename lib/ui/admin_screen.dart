import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/data/admin_store.dart';
import 'package:odd/data/map_catalog_store.dart';
import 'package:odd/data/supabase_config.dart';
import 'package:odd/game/palette.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  static const maxCampaignMaps = 15;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _store = const AdminStore();
  var _loading = true;
  Object? _error;
  var _saving = false;
  List<CatalogMap> _catalog = const [];
  List<String> _campaignIds = [];
  String? _dailyId;
  String? _purgeMapId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!SupabaseConfig.isReady) {
        throw MapUploadException(AppString.mapUploadNeedBackend);
      }
      final catalog = await _store.listMaps();
      final content = await _store.loadContent();
      final known = {for (final map in catalog) map.id};
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = catalog;
        _campaignIds = [
          for (final id in content.mapIds)
            if (known.contains(id)) id,
        ];
        _dailyId = content.dailyId != null && known.contains(content.dailyId)
            ? content.dailyId
            : null;
        _purgeMapId = catalog.isEmpty ? null : catalog.first.id;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _label(String id) {
    for (final map in _catalog) {
      if (map.id == id) {
        return '${map.name}  ($id)';
      }
    }
    return id;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppString.adminConfirmTitle),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppString.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppString.confirm),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _store.saveContent(mapIds: _campaignIds, dailyId: _dailyId);
      if (!mounted) {
        return;
      }
      _toast(AppString.adminSaved);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _toast(AppString.adminFailed(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _runDanger(
    Future<int> Function() action,
    String Function(int count) done,
  ) async {
    setState(() => _saving = true);
    try {
      final count = await action();
      if (!mounted) {
        return;
      }
      _toast(done(count));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _toast(AppString.adminFailed(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _toggleCampaign(String id, bool selected) {
    if (selected) {
      if (_campaignIds.contains(id)) {
        return;
      }
      if (_campaignIds.length >= AdminScreen.maxCampaignMaps) {
        _toast(AppString.adminTooManyMaps);
        return;
      }
      setState(() => _campaignIds = [..._campaignIds, id]);
      return;
    }
    setState(() => _campaignIds = [..._campaignIds]..remove(id));
  }

  void _toggleDaily(String id, bool selected) {
    setState(() => _dailyId = selected ? id : null);
  }

  Future<void> _deleteMap(CatalogMap map) async {
    if (!await _confirm(AppString.adminConfirmDeleteMap(_label(map.id)))) {
      return;
    }
    setState(() => _saving = true);
    try {
      final count = await _store.deleteMap(map.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = [
          for (final item in _catalog)
            if (item.id != map.id) item,
        ];
        _campaignIds = [..._campaignIds]..remove(map.id);
        if (_dailyId == map.id) {
          _dailyId = null;
        }
        if (_purgeMapId == map.id) {
          _purgeMapId = _catalog.isEmpty ? null : _catalog.first.id;
        }
        _saving = false;
      });
      _toast(AppString.adminDeletedMap(count));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _toast(AppString.adminFailed(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppString.admin),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppString.adminFailed(_error!),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_catalog.isEmpty) {
      return Center(child: Text(AppString.adminNoMaps));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          AppString.adminCampaign,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Palette.menuAccent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppString.adminCampaignHint}  ${_campaignIds.length}/${AdminScreen.maxCampaignMaps}',
          style: const TextStyle(color: Palette.hudMuted),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _catalog.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.84,
          ),
          itemBuilder: (context, index) {
            final map = _catalog[index];
            final campaignIndex = _campaignIds.indexOf(map.id);
            return _AdminMapTile(
              map: map,
              selected: campaignIndex >= 0,
              campaignIndex: campaignIndex >= 0 ? campaignIndex : null,
              isDaily: _dailyId == map.id,
              enabled: !_saving,
              onCampaign: (value) => _toggleCampaign(map.id, value),
              onDaily: (value) => _toggleDaily(map.id, value),
              onDelete: () => _deleteMap(map),
            );
          },
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: Palette.menuAccent),
            child: Text(AppString.adminValidate),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          AppString.adminDanger,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8B1E1E),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 400,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _purgeMapId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  selectedItemBuilder: (context) => [
                    for (final map in _catalog)
                      Text(
                        _label(map.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                  items: [
                    for (final map in _catalog)
                      DropdownMenuItem(
                        value: map.id,
                        child: Text(
                          _label(map.id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _purgeMapId = value),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saving || _purgeMapId == null
                    ? null
                    : () async {
                        final id = _purgeMapId!;
                        if (!await _confirm(
                          AppString.adminConfirmMapTimes(_label(id)),
                        )) {
                          return;
                        }
                        await _runDanger(
                          () => _store.deleteMapTimes(id),
                          AppString.adminDeletedTimes,
                        );
                      },
                child: Text(AppString.adminDeleteMapTimes),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: _saving
                ? null
                : () async {
                    if (!await _confirm(AppString.adminConfirmAllTimes)) {
                      return;
                    }
                    await _runDanger(
                      _store.deleteAllTimes,
                      AppString.adminDeletedTimes,
                    );
                  },
            child: Text(AppString.adminDeleteAllTimes),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: _saving
                ? null
                : () async {
                    if (!await _confirm(AppString.adminConfirmAllUsers)) {
                      return;
                    }
                    await _runDanger(
                      _store.deleteAllUsers,
                      AppString.adminDeletedUsers,
                    );
                  },
            child: Text(AppString.adminDeleteAllUsers),
          ),
        ),
      ],
    );
  }
}

class _AdminMapTile extends StatelessWidget {
  const _AdminMapTile({
    required this.map,
    required this.selected,
    required this.campaignIndex,
    required this.isDaily,
    required this.enabled,
    required this.onCampaign,
    required this.onDaily,
    required this.onDelete,
  });

  final CatalogMap map;
  final bool selected;
  final int? campaignIndex;
  final bool isDaily;
  final bool enabled;
  final ValueChanged<bool> onCampaign;
  final ValueChanged<bool> onDaily;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final preview = _previewBytes(map.previewImg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF161821),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? primary : const Color(0x18FFFFFF),
                width: selected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (preview != null)
                    Image.memory(preview, fit: BoxFit.cover)
                  else
                    const ColoredBox(color: Color(0xFF161821)),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xCC0E1018),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        tooltip: AppString.adminDeleteMap,
                        onPressed: enabled ? onDelete : null,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFE85D5D),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xCC0E1018),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Checkbox(
                            value: selected,
                            onChanged: enabled
                                ? (value) => onCampaign(value == true)
                                : null,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          Tooltip(
                            message: AppString.adminDaily,
                            child: Checkbox(
                              value: isDaily,
                              onChanged: enabled
                                  ? (value) => onDaily(value == true)
                                  : null,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (campaignIndex != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            '${campaignIndex! + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          map.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

Uint8List? _previewBytes(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  var encoded = raw;
  final comma = encoded.indexOf(',');
  if (encoded.startsWith('data:') && comma != -1) {
    encoded = encoded.substring(comma + 1);
  }
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}
