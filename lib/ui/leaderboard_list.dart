import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/data/leaderboard_store.dart';
import 'package:odd/domain/leaderboard.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';

/// Classement d'une map, chargé depuis Supabase.
class LeaderboardList extends StatefulWidget {
  const LeaderboardList({
    super.key,
    required this.mapId,
    this.revision = 0,
  });

  final String mapId;
  final int revision;

  @override
  State<LeaderboardList> createState() => _LeaderboardListState();
}

class _LeaderboardListState extends State<LeaderboardList> {
  late Future<Leaderboard> _future;

  @override
  void initState() {
    super.initState();
    _future = const LeaderboardStore().forMap(widget.mapId);
  }

  @override
  void didUpdateWidget(covariant LeaderboardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapId != widget.mapId ||
        oldWidget.revision != widget.revision) {
      _future = const LeaderboardStore().forMap(widget.mapId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Leaderboard>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Status(AppString.leaderboardLoadError);
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Palette.menuAccent),
          );
        }
        final board = snapshot.data!;
        if (board.entries.isEmpty) {
          return _Status(AppString.leaderboardEmpty);
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: board.entries.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 6);
                },
                itemBuilder: (context, index) {
                  return LeaderboardRankRow(entry: board.entries[index]);
                },
              ),
            ),
            if (board.myRank != null && board.myTime != null) ...[
              const SizedBox(height: 8),
              Text(
                AppString.myRank(board.myRank!, formatRunTime(board.myTime!)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Palette.hudMuted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Status extends StatelessWidget {
  const _Status(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Palette.hudMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LeaderboardRankRow extends StatelessWidget {
  const LeaderboardRankRow({super.key, required this.entry});

  final LeaderboardEntry entry;

  Color get _rankColor {
    return switch (entry.rank) {
      1 => Palette.coin,
      2 => const Color(0xFFC5CDD8),
      3 => const Color(0xFFC47B4A),
      _ => entry.isMe ? Palette.menuAccent : Palette.hudMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF161821),
        borderRadius: BorderRadius.circular(10),
        border: entry.isMe
            ? Border.all(color: Palette.menuAccent.withValues(alpha: 0.7))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(fontWeight: FontWeight.w800, color: _rankColor),
              ),
            ),
            Expanded(
              child: Text(
                entry.displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: entry.isMe ? FontWeight.w800 : FontWeight.w600,
                  color: Palette.hud,
                ),
              ),
            ),
            Text(
              formatRunTime(entry.time),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: entry.isMe ? Palette.coin : Palette.hud,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
