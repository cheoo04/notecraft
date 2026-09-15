import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system validé pour NoteCraft.
/// Pas de jaune/or : les états "Express" vs "Affiné" se distinguent
/// uniquement par la couleur d'accent (teal) et un gris neutre.
class AppColors {
  static const accentTeal = Color(0xFF0F766E);
  static const inkDark = Color(0xFF111827);
  static const canvasGrey = Color(0xFFFAFAFA);
  static const neutralBorder = Color(0xFFE5E7EB);
  static const neutralFill = Color(0xFFF3F4F6);
}

class AppTheme {
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvasGrey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentTeal,
        primary: AppColors.accentTeal,
        surface: AppColors.canvasGrey,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: AppColors.inkDark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: AppColors.inkDark,
        ),
        bodyMedium: GoogleFonts.inter(color: AppColors.inkDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvasGrey,
        elevation: 0,
        foregroundColor: AppColors.inkDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
