/// Personal bests keyed by level id (seconds).
class BestTimes {
  const BestTimes(this.byLevelId);

  final Map<String, double> byLevelId;

  double? forLevel(String id) => byLevelId[id];

  /// Somme des PB, ou null si une map n'a pas encore de temps.
  double? totalFor(Iterable<String> levelIds) {
    var sum = 0.0;
    for (final id in levelIds) {
      final time = byLevelId[id];
      if (time == null) {
        return null;
      }
      sum += time;
    }
    return sum;
  }

  /// Garde le temps le plus rapide (égalité : on ne remplace pas).
  BestTimes record(String levelId, double time) {
    final current = byLevelId[levelId];
    if (current != null && current <= time) {
      return this;
    }
    return BestTimes({...byLevelId, levelId: time});
  }
}
