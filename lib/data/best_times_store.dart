import 'dart:convert';

import 'package:odd/domain/best_times.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BestTimesStore {
  static const _key = 'personal_bests_v1';

  /// Lit les PB depuis SharedPreferences.
  Future<BestTimes> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const BestTimes({});
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const BestTimes({});
    }
    return BestTimes({
      for (final entry in decoded.entries)
        if (entry.value is num) entry.key.toString(): (entry.value as num).toDouble(),
    });
  }

  /// Enregistre un run s'il bat le PB, puis persiste.
  Future<BestTimes> record(String levelId, double time) async {
    final current = await load();
    final next = current.record(levelId, time);
    if (identical(next, current)) {
      return current;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.byLevelId),
    );
    return next;
  }
}
