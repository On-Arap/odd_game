import 'package:odd/data/auth_store.dart';
import 'package:odd/data/supabase_config.dart';
import 'package:odd/domain/best_times.dart';
import 'package:odd/domain/leaderboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lecture / écriture des classements Supabase.
class LeaderboardStore {
  const LeaderboardStore();

  bool get isReady => SupabaseConfig.isReady;

  SupabaseClient get _client => Supabase.instance.client;

  /// Envoie un run ; le SQL n'écrit que s'il bat le PB.
  Future<void> submitBest(String mapId, double seconds) async {
    if (!isReady) {
      return;
    }
    try {
      await const AuthStore().ensureSession();
      await _client.rpc(
        'submit_best_time',
        params: {'p_map_id': mapId, 'p_time_ms': secondsToMs(seconds)},
      );
    } catch (_) {
      // Hors-ligne / pas de profil : le PB local reste la source.
    }
  }

  Future<void> syncLocalBests(BestTimes bests) async {
    if (!isReady) {
      return;
    }
    for (final entry in bests.byLevelId.entries) {
      await submitBest(entry.key, entry.value);
    }
  }

  Future<Leaderboard> forMap(String mapId, {int limit = 10}) async {
    if (!isReady) {
      return const Leaderboard(entries: []);
    }
    await const AuthStore().ensureSession();
    final rows = await _client.rpc(
      'map_leaderboard',
      params: {'p_map_id': mapId, 'p_limit': limit},
    );
    final entries = <LeaderboardEntry>[];
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) {
          continue;
        }
        final rank = row['rank'];
        final name = row['display_name'];
        final ms = row['time_ms'];
        if (rank is! num || name is! String || ms is! num) {
          continue;
        }
        entries.add(
          LeaderboardEntry(
            rank: rank.toInt(),
            displayName: name,
            time: msToSeconds(ms.toInt()),
            isMe: row['is_me'] == true,
          ),
        );
      }
    }

    int? myRank;
    double? myTime;
    final mine = await _client.rpc('my_map_rank', params: {'p_map_id': mapId});
    if (mine is List && mine.isNotEmpty && mine.first is Map) {
      final row = mine.first as Map;
      final rank = row['rank'];
      final ms = row['time_ms'];
      if (rank is num && ms is num) {
        myRank = rank.toInt();
        myTime = msToSeconds(ms.toInt());
      }
    }

    return Leaderboard(entries: entries, myRank: myRank, myTime: myTime);
  }
}
