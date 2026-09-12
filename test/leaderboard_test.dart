import 'package:flutter_test/flutter_test.dart';
import 'package:odd/domain/leaderboard.dart';
import 'package:odd/game/hud_state.dart';

void main() {
  test('seconds and milliseconds round-trip on hundredths', () {
    expect(secondsToMs(9.87), 9870);
    expect(msToSeconds(9870), 9.87);
    expect(secondsToMs(13.19), 13190);
  });

  test('formatRunTime shows three fractional digits', () {
    expect(formatRunTime(9.87), '9.870');
    expect(formatRunTime(13.190), '13.190');
    expect(formatRunTime(11.890), '11.890');
    expect(formatRunTime(65.001), '1:05.001');
  });
}
