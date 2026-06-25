import 'package:flutter/material.dart';

class ThemePalette {
  final String name;
  final Color seedColor;

  const ThemePalette({required this.name, required this.seedColor});
}

const kThemePalettes = <ThemePalette>[
  ThemePalette(name: 'Sakura', seedColor: Color(0xFFE0729E)),
  ThemePalette(name: 'Sereno', seedColor: Color(0xFF5B8DEF)),
  ThemePalette(name: 'Menta', seedColor: Color(0xFF4FAE8E)),
  ThemePalette(name: 'Lavanda', seedColor: Color(0xFF8B7FE8)),
  ThemePalette(name: 'Sunset', seedColor: Color(0xFFE0915F)),
];
