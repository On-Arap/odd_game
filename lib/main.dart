import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:odd/app.dart';

/// Point d'entrée : URLs propres sur le web, puis l'app.
void main() {
  // Sans ça, Flutter web ajoute un `#` dans l'URL.
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  bootstrap();
}
