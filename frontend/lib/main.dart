import 'package:flutter/material.dart';
import 'package:sdwb/core/signals/router_signals.dart';
import 'package:sdwb/core/signals/theme_controll_signals.dart';
import 'package:sdwb/core/signals/theme_palette_signals.dart';
import 'package:sdwb/core/theme/theme_palette.dart';
import 'package:sdwb/screens/create/create_screen.dart';
import 'package:signals/signals_flutter.dart';

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
    // ignore: deprecated_member_use
    final currentTheme = themeModeControll.watch(context);
    // ignore: deprecated_member_use
    final paletteIndex = selectedPaletteIndex.watch(context);
    final seedColor = kThemePalettes[paletteIndex].seedColor;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(seedColor, Brightness.light),
      darkTheme: AppTheme.build(seedColor, Brightness.dark),
      themeMode: (currentTheme == 0) ? ThemeMode.light : ThemeMode.dark,
      home: const _AppRouterView(),
    );
  }
}

class _AppRouterView extends StatelessWidget {
  const _AppRouterView();

  @override
  Widget build(BuildContext context) {
    final entry = currentRoute.watch(context);

    switch (entry.route) {
      case AppRoute.home:
        return const HomeScreen();
      case AppRoute.view:
        return const ViewScreen();
      case AppRoute.board:
        return BoardScreen(sala: entry.sala);
      case AppRoute.create:
        return const CreateScreen();
    }
  }
}
