import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/ui/menu_screen.dart';

class OddApp extends StatelessWidget {
  const OddApp({super.key});

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
      home: const MenuScreen(),
    );
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const OddApp());
}
