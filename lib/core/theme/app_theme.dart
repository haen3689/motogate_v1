import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.notoSansLaoTextTheme(ThemeData.light().textTheme),
    colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: AppColors.white, secondary: AppColors.primaryLight, surface: AppColors.white, error: AppColors.error),
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, elevation: 0, centerTitle: true, systemOverlayStyle: SystemUiOverlayStyle.light),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey100)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey100)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2))),
    cardTheme: CardThemeData(color: AppColors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
  );
}
