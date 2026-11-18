import 'package:flutter/material.dart';

const ink = Color(0xFF1E332A);
const forest = Color(0xFF315C45);
const leaf = Color(0xFF6D8D62);
const paper = Color(0xFFF4F1E8);
const sand = Color(0xFFE9E2D3);
const terracotta = Color(0xFFC26E51);
const mutedInk = Color(0xFF788078);

ThemeData buildBroteTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: forest,
    primary: forest,
    secondary: terracotta,
    surface: paper,
    error: const Color(0xFFB64E43),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    fontFamily: 'Aptos',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: ink,
        fontSize: 36,
        height: 1.03,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.3,
      ),
      headlineMedium: TextStyle(
        color: ink,
        fontSize: 27,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        color: ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: mutedInk, fontSize: 12, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.72),
      hintStyle: const TextStyle(color: mutedInk),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: ink.withValues(alpha: 0.09)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: ink.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: forest, width: 1.5),
      ),
    ),
  );
}

String greetingName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'amiga de las plantas';
  return trimmed.split(RegExp(r'\s+')).first;
}

String shortDate(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
