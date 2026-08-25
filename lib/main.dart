import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:odd/app.dart';

void main() {
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  bootstrap();
}
