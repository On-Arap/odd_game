/// Personal bests keyed by level id (seconds).
class BestTimes {
  const BestTimes(this.byLevelId);

  final Map<String, double> byLevelId;

  double? forLevel(String id) => byLevelId[id];

  /// Sum of PBs for [levelIds], or null if any map is missing a time.
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

  /// Keep the faster time. Equal times do not replace the stored PB.
  BestTimes record(String levelId, double time) {
    final current = byLevelId[levelId];
    if (current != null && current <= time) {
      return this;
    }
    return BestTimes({...byLevelId, levelId: time});
  }
}
