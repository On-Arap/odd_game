/// Une ligne du classement (secondes).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.time,
    this.isMe = false,
  });

  final int rank;
  final String displayName;
  final double time;
  final bool isMe;
}

class Leaderboard {
  const Leaderboard({required this.entries, this.myRank, this.myTime});

  final List<LeaderboardEntry> entries;
  final int? myRank;
  final double? myTime;
}

int secondsToMs(double seconds) => (seconds * 1000).round();

double msToSeconds(int ms) => ms / 1000.0;
