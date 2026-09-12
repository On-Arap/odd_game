import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/app_string.dart';
import 'package:odd/data/supabase_config.dart';
import 'package:odd/ui/admin_screen.dart';
import 'package:odd/ui/mapmaker_screen.dart';
import 'package:odd/ui/menu_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OddApp extends StatelessWidget {
  const OddApp({super.key});

  /// `/` partout ; `/mapmaker` seulement sur le web.
  static String initialRoute() {
    if (!kIsWeb) {
      return '/';
    }
    final path = Uri.base.path;
    if (path == '/mapmaker' || path.endsWith('/mapmaker')) {
      return '/mapmaker';
    }
    if (path == '/admin' || path.endsWith('/admin')) {
      return '/admin';
    }
    return '/';
  }

  static Route<void> routeFor(RouteSettings settings) {
    switch (settings.name) {
      case '/mapmaker':
        // L'éditeur n'existe pas sur mobile : on renvoie au menu.
        if (!kIsWeb) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const MenuScreen(),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MapMakerScreen(),
        );
      case '/admin':
        if (!kIsWeb) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const MenuScreen(),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminScreen(),
        );
      case '/':
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MenuScreen(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppString.appTitle,
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
      // Sans ça, `/admin` et `/mapmaker` empilent aussi `/` (MenuScreen),
      // et le dialog nickname s'affiche par-dessus.
      onGenerateInitialRoutes: (name) => [routeFor(RouteSettings(name: name))],
      onGenerateRoute: (settings) => routeFor(settings),
    );
  }
}

/// Landscape immersif sauf dans l'éditeur web.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    SupabaseConfig.initialized = true;
    debugPrint('Supabase ready (${SupabaseConfig.url})');
  } else {
    debugPrint(
      'Supabase skipped: set SUPABASE_URL and SUPABASE_ANON_KEY '
      '(config "odd_game (supabase debug)").',
    );
  }
  final webTool =
      kIsWeb &&
      (OddApp.initialRoute() == '/mapmaker' ||
          OddApp.initialRoute() == '/admin');
  if (!webTool) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  runApp(const OddApp());
}
