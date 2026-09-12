/// A medal is earned when a run time is less than or equal to its target.
bool medalEarned(double? time, double? target) {
  return time != null && target != null && time <= target;
}

enum MedalKind { bronze, silver, gold }

/// Meilleure récompense déjà débloquée (auteur > or > argent > bronze).
enum BestAward { none, bronze, silver, gold, author }

BestAward bestAwardFor({
  required double? best,
  required double? bronzeTime,
  required double? silverTime,
  required double? goldTime,
  required double? authorTime,
}) {
  if (medalEarned(best, authorTime)) {
    return BestAward.author;
  }
  if (medalEarned(best, goldTime)) {
    return BestAward.gold;
  }
  if (medalEarned(best, silverTime)) {
    return BestAward.silver;
  }
  if (medalEarned(best, bronzeTime)) {
    return BestAward.bronze;
  }
  return BestAward.none;
}

/// How a medal should appear on the win screen.
enum MedalReveal { empty, owned, justEarned }

MedalReveal medalReveal({
  required double runTime,
  required double? previousBest,
  required double? target,
}) {
  if (target == null) {
    return MedalReveal.empty;
  }
  if (medalEarned(previousBest, target)) {
    return MedalReveal.owned;
  }
  if (medalEarned(runTime, target)) {
    return MedalReveal.justEarned;
  }
  return MedalReveal.empty;
}
