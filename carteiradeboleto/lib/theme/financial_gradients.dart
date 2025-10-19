import 'package:flutter/material.dart';

class FinancialGradients {
  // Gradiente principal - Verde dinheiro
  static const LinearGradient money = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF059669), // Verde escuro
      Color(0xFF10B981), // Verde médio
      Color(0xFF34D399), // Verde claro
    ],
  );

  // Gradiente dourado - Riqueza/Ouro
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD97706), // Âmbar escuro
      Color(0xFFF59E0B), // Âmbar médio
      Color(0xFFFBBF24), // Dourado claro
    ],
  );

  // Gradiente azul - Confiança/Estabilidade
  static const LinearGradient trust = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0891B2), // Azul escuro
      Color(0xFF0EA5E9), // Azul médio
      Color(0xFF38BDF8), // Azul claro
    ],
  );

  // Gradiente de sucesso
  static const LinearGradient success = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
  );

  // Gradiente de alerta
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFD97706),
      Color(0xFFF59E0B),
    ],
  );

  // Gradiente de erro
  static const LinearGradient error = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFDC2626),
      Color(0xFFEF4444),
    ],
  );

  // Gradiente sutil para fundos
  static LinearGradient backgroundSubtle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              const Color(0xFF052E16).withOpacity(0.3),
              const Color(0xFF0C1F17).withOpacity(0.1),
              Colors.transparent,
            ]
          : [
              const Color(0xFF059669).withOpacity(0.02),
              const Color(0xFFF0FDF4),
              const Color(0xFFD97706).withOpacity(0.01),
            ],
    );
  }

  // Gradiente para cards
  static LinearGradient cardGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF0C1F17),
              const Color(0xFF052E16).withOpacity(0.8),
            ]
          : [
              Colors.white,
              const Color(0xFF059669).withOpacity(0.02),
            ],
    );
  }
}