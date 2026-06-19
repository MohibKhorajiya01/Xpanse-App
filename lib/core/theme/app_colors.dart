import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFFA29BFE);
  
  // Background colors
  static const Color backgroundDark = Color(0xFF0F0F1B);
  static const Color cardDark = Color(0xFF1D1D2B);
  static const Color surfaceDark = Color(0xFF252538);

  // Functional colors
  static const Color income = Color(0xFF00B894);
  static const Color expense = Color(0xFFD63031);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color textPremium = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFFB2BEC3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [backgroundDark, cardDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF55E6C1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFD63031), Color(0xFFFAB1A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism effect colors
  static Color glassBackground = Colors.white.withValues(alpha: 0.1);
  static Color glassBorder = Colors.white.withValues(alpha: 0.2);
}
