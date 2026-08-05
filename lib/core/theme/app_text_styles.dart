import 'package:flutter/material.dart';
import 'app_colors.dart';
class AppTextStyles {
  AppTextStyles._();
  static const TextStyle h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.black);
  static const TextStyle h2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.black);
  static const TextStyle h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.black);
  static const TextStyle titleLarge = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black);
  static const TextStyle titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black);
  static const TextStyle titleSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.black);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.black);
  static const TextStyle bodySmall = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.grey500);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grey500);
  static const TextStyle caption = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w400, color: AppColors.grey350);
}
