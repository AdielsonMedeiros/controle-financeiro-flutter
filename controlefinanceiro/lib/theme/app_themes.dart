import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Cores modernas e agradáveis para app financeiro
abstract class AppColorsLight {
  // Primária: Azul profundo (confiança + estabilidade)
  static const Color primaria = Color(0xFF2563EB); // Azul royal
  static const Color primariaClara = Color(0xFF3B82F6);
  static const Color primariaEscura = Color(0xFF1E40AF);
  
  // Secundária: Verde menta (crescimento + frescor)
  static const Color secundaria = Color(0xFF10B981); // Verde esmeralda
  static const Color secundariaClara = Color(0xFF34D399);
  
  // Acentos: Roxo suave (sofisticação)
  static const Color acento = Color(0xFF8B5CF6); // Roxo
  static const Color acentoClaro = Color(0xFFA78BFA);
  
  // Backgrounds: Tons neutros e suaves
  static const Color fundo = Color(0xFFF8FAFC); // Cinza muito claro
  static const Color fundoGradiente1 = Color(0xFFF0F9FF); // Azul muito suave
  static const Color fundoGradiente2 = Color(0xFFF0FDF4); // Verde muito suave
  static const Color container = Color(0xFFFFFFFF);
  
  // Textos
  static const Color texto = Color(0xFF0F172A); // Slate escuro
  static const Color textoSuave = Color(0xFF64748B);
  
  // Status
  static const Color sucesso = Color(0xFF10B981); // Verde
  static const Color aviso = Color(0xFFF59E0B); // Laranja
  static const Color erro = Color(0xFFEF4444); // Vermelho
  static const Color info = Color(0xFF3B82F6); // Azul
  
  // Receitas e Despesas
  static const Color receita = Color(0xFF10B981); // Verde
  static const Color despesa = Color(0xFFF43F5E); // Rosa vermelho
  
  static const Color borda = Color(0xFFE2E8F0);
}

abstract class AppColorsDark {
  // Primária: Azul brilhante
  static const Color primaria = Color(0xFF60A5FA); // Azul claro
  static const Color primariaClara = Color(0xFF93C5FD);
  static const Color primariaEscura = Color(0xFF3B82F6);
  
  // Secundária: Verde menta brilhante
  static const Color secundaria = Color(0xFF34D399); // Verde claro
  static const Color secundariaClara = Color(0xFF6EE7B7);
  
  // Acentos: Roxo neon
  static const Color acento = Color(0xFFA78BFA); // Roxo claro
  static const Color acentoClaro = Color(0xFFC4B5FD);
  
  // Backgrounds: Escuro elegante
  static const Color fundo = Color(0xFF0F172A); // Slate muito escuro
  static const Color fundoGradiente1 = Color(0xFF1E293B); // Azul escuro
  static const Color fundoGradiente2 = Color(0xFF064E3B); // Verde escuro
  static const Color container = Color(0xFF1E293B); // Slate escuro
  
  // Textos
  static const Color texto = Color(0xFFF1F5F9); // Slate claro
  static const Color textoSuave = Color(0xFF94A3B8);
  
  // Status
  static const Color sucesso = Color(0xFF34D399); // Verde
  static const Color aviso = Color(0xFFFBBF24); // Laranja
  static const Color erro = Color(0xFFF87171); // Vermelho
  static const Color info = Color(0xFF60A5FA); // Azul
  
  // Receitas e Despesas
  static const Color receita = Color(0xFF34D399); // Verde
  static const Color despesa = Color(0xFFFB7185); // Rosa claro
  
  static const Color borda = Color(0xFF334155);
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    primaryColor: const Color(0xFF2563EB),
    fontFamily: 'Inter',
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB), // Azul royal
      primaryContainer: Color(0xFF3B82F6),
      secondary: Color(0xFF10B981), // Verde esmeralda
      secondaryContainer: Color(0xFF34D399),
      tertiary: Color(0xFF8B5CF6), // Roxo
      tertiaryContainer: Color(0xFFA78BFA),
      error: Color(0xFFEF4444),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF0F172A),
      outline: Color(0xFFE2E8F0),
      onSurfaceVariant: Color(0xFF64748B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: AppColorsLight.texto,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: AppColorsLight.primaria),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      color: AppColorsLight.container,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLight.primaria,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColorsLight.primaria,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    primaryColor: const Color(0xFF60A5FA),
    fontFamily: 'Inter',
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF60A5FA), // Azul claro
      primaryContainer: Color(0xFF93C5FD),
      secondary: Color(0xFF34D399), // Verde claro
      secondaryContainer: Color(0xFF6EE7B7),
      tertiary: Color(0xFFA78BFA), // Roxo claro
      tertiaryContainer: Color(0xFFC4B5FD),
      error: Color(0xFFF87171),
      surface: Color(0xFF1E293B),
      onPrimary: Color(0xFF0F172A),
      onSecondary: Color(0xFF0F172A),
      onSurface: Color(0xFFF1F5F9),
      outline: Color(0xFF334155),
      onSurfaceVariant: Color(0xFF94A3B8),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: AppColorsDark.texto,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: AppColorsDark.primaria),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      color: AppColorsDark.container,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primaria,
        foregroundColor: AppColorsDark.fundo,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColorsDark.primaria,
      foregroundColor: AppColorsDark.fundo,
      elevation: 4,
    ),
    useMaterial3: true,
  );
}
