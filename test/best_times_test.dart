import 'package:flutter_test/flutter_test.dart';
import 'package:odd/domain/best_times.dart';

void main() {
  test('record keeps the faster time', () {
    var bests = const BestTimes({});
    bests = bests.record('warmup', 12.5);
    expect(bests.forLevel('warmup'), 12.5);
    bests = bests.record('warmup', 13.0);
    expect(bests.forLevel('warmup'), 12.5);
    bests = bests.record('warmup', 11.0);
    expect(bests.forLevel('warmup'), 11.0);
  });

  test('total is null until every map has a PB', () {
    const ids = ['a', 'b', 'c'];
    var bests = const BestTimes({});
    expect(bests.totalFor(ids), isNull);
    bests = bests.record('a', 1).record('b', 2);
    expect(bests.totalFor(ids), isNull);
    bests = bests.record('c', 3.5);
    expect(bests.totalFor(ids), 6.5);
  });
}
