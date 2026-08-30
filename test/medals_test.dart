import 'package:flutter_test/flutter_test.dart';
import 'package:odd/domain/medals.dart';

void main() {
  test('a medal is earned by beating or matching its time', () {
    expect(medalEarned(12, 12), isTrue);
    expect(medalEarned(11.9, 12), isTrue);
    expect(medalEarned(12.1, 12), isFalse);
    expect(medalEarned(null, 12), isFalse);
    expect(medalEarned(10, null), isFalse);
  });

  test('owned medals stay owned even if this run is slower', () {
    expect(
      medalReveal(runTime: 20, previousBest: 11, target: 12),
      MedalReveal.owned,
    );
  });

  test('new medals on this run are marked justEarned', () {
    expect(
      medalReveal(runTime: 11, previousBest: 15, target: 12),
      MedalReveal.justEarned,
    );
    expect(
      medalReveal(runTime: 11, previousBest: null, target: 12),
      MedalReveal.justEarned,
    );
  });

  test('missing target or a slower run stays empty', () {
    expect(
      medalReveal(runTime: 11, previousBest: null, target: null),
      MedalReveal.empty,
    );
    expect(
      medalReveal(runTime: 14, previousBest: 16, target: 12),
      MedalReveal.empty,
    );
  });
}
