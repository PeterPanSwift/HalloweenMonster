import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const HalloweenMonsterApp());
}

class HalloweenMonsterApp extends StatelessWidget {
  const HalloweenMonsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '萬聖節妖怪圖鑑',
      debugShowCheckedModeBanner: false,
      theme: buildSpookyTheme(),
      home: const HomeScreen(),
    );
  }
}
