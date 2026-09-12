enum DisplayNameError { tooShort, tooLong, badChars }

/// Pseudo 3–16 caractères, lettres / chiffres / underscore.
abstract final class DisplayNameRules {
  static const minLength = 3;
  static const maxLength = 16;
  static final allowed = RegExp(r'^[A-Za-z0-9_]+$');

  static DisplayNameError? validate(String raw) {
    final name = raw.trim();
    if (name.length < minLength) {
      return DisplayNameError.tooShort;
    }
    if (name.length > maxLength) {
      return DisplayNameError.tooLong;
    }
    if (!allowed.hasMatch(name)) {
      return DisplayNameError.badChars;
    }
    return null;
  }

  static String normalize(String raw) => raw.trim();
}
