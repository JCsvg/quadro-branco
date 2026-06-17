import 'package:flutter/material.dart';

/// Telas
import 'screens/home/home_screen.dart';
import 'screens/board/board_screen.dart';
import 'screens/view/view_screen.dart';

import 'core/theme/app_theme.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        'board': (context) => const BoardScreen(),
        'view': (context) => const ViewScreen(),
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
    );
  }
}
