import 'package:flutter_test/flutter_test.dart';
import 'package:odd/domain/display_name.dart';

void main() {
  test('accepts a 3–16 character nickname', () {
    expect(DisplayNameRules.validate('odd'), isNull);
    expect(DisplayNameRules.validate('Odd_Player_1'), isNull);
  });

  test('rejects short, long, or punctuation names', () {
    expect(DisplayNameRules.validate('ab'), DisplayNameError.tooShort);
    expect(
      DisplayNameRules.validate('this_name_is_way_too'),
      DisplayNameError.tooLong,
    );
    expect(DisplayNameRules.validate('hello!'), DisplayNameError.badChars);
  });
}
