import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/ui/mapmaker_screen.dart';
import 'package:odd/ui/menu_screen.dart';

class OddApp extends StatelessWidget {
  const OddApp({super.key});

  static String initialRoute() {
    if (!kIsWeb) {
      return '/';
    }
    final path = Uri.base.path;
    if (path == '/mapmaker' || path.endsWith('/mapmaker')) {
      return '/mapmaker';
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ODD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E0F16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5A3D),
          surface: Color(0xFF1A1C28),
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: initialRoute(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/mapmaker':
            if (!kIsWeb) {
              return MaterialPageRoute<void>(
                builder: (_) => const MenuScreen(),
              );
            }
            return MaterialPageRoute<void>(
              builder: (_) => const MapMakerScreen(),
            );
          case '/':
          default:
            return MaterialPageRoute<void>(
              builder: (_) => const MenuScreen(),
            );
        }
      },
    );
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mapMaker = kIsWeb && OddApp.initialRoute() == '/mapmaker';
  if (!mapMaker) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  runApp(const OddApp());
}
