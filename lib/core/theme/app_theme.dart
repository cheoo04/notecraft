// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Palette principale NoteCraft
  static const accentTeal = Color(0xFF0F766E);
  static const accentTealLight = Color(0xFFE6F4F2);
  static const inkDark = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const canvasGrey = Color(0xFFFAFAFA);
  static const cardWhite = Colors.white;
  static const neutralBorder = Color(0xFFE5E7EB);
  static const neutralFill = Color(0xFFF3F4F6);

  // Couleurs de badges de matières
  static const badgePhysiqueBg = Color(0xFFE0F2FE);
  static const badgePhysiqueText = Color(0xFF0369A1);
  static const badgeEcoBg = Color(0xFFFEF3C7);
  static const badgeEcoText = Color(0xFFB45309);
  static const badgeDroitBg = Color(0xFFF3E8FF);
  static const badgeDroitText = Color(0xFF6B21A8);
}

class AppTheme {
  static ThemeData get light {
    final baseInter = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvasGrey,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentTeal,
        surface: AppColors.canvasGrey,
        onSurface: AppColors.inkDark,
      ),
      textTheme: baseInter.copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.inkDark,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.inkDark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.inkDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.inkDark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.inkDark,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvasGrey,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.inkDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.inkDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.neutralBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
