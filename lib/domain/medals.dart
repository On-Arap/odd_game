/// A medal is earned when a run time is less than or equal to its target.
bool medalEarned(double? time, double? target) {
  return time != null && target != null && time <= target;
}

enum MedalKind { bronze, silver, gold }

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
