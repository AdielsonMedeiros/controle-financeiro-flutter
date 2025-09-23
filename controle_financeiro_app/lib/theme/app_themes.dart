

import 'package:flutter/material.dart';


abstract class AppColorsLight {
  static const Color primaria = Color(0xFF4F46E5);
  static const Color fundo = Color(0xFFF8FAFC);
  static const Color container = Color(0xFFFFFFFF);
  static const Color texto = Color(0xFF1E293B);
  static const Color textoSuave = Color(0xFF64748B);
  static const Color sucesso = Color(0xFF10B981);
  static const Color erro = Color(0xFFEF4444);
  static const Color borda = Color(0xFFE2E8F0);
}


abstract class AppColorsDark {
  static const Color primaria = Color(0xFF4F46E5);
  static const Color fundo = Color(0xFF111827);
  static const Color container = Color(0xFF1F2937);
  static const Color texto = Color(0xFFF3F4F6);
  static const Color textoSuave = Color(0xFF9CA3AF);
  static const Color sucesso = Color(0xFF10B981);
  static const Color erro = Color(0xFFEF4444);
  static const Color borda = Color(0xFF374151);
}


class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColorsLight.fundo,
    primaryColor: AppColorsLight.primaria,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.primaria,
      secondary: AppColorsLight.sucesso,
      error: AppColorsLight.erro,
      surface: AppColorsLight.container,
      onSurface: AppColorsLight.texto,
      background: AppColorsLight.fundo,
      onBackground: AppColorsLight.texto,
      outline: AppColorsLight.borda, 
      onSurfaceVariant: AppColorsLight.textoSuave, 
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColorsLight.texto,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColorsLight.textoSuave),
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsDark.fundo,
    primaryColor: AppColorsDark.primaria,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.primaria,
      secondary: AppColorsDark.sucesso,
      error: AppColorsDark.erro,
      surface: AppColorsDark.container,
      onSurface: AppColorsDark.texto,
      background: AppColorsDark.fundo,
      onBackground: AppColorsDark.texto,
      outline: AppColorsDark.borda, 
      onSurfaceVariant: AppColorsDark.textoSuave, 
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColorsDark.texto,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColorsDark.textoSuave),
    ),
    useMaterial3: true,
  );
}