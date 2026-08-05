import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
class MgServiceCard extends StatelessWidget {
  final String title; final IconData icon; final Color? iconColor; final VoidCallback? onTap;
  const MgServiceCard({super.key, required this.title, required this.icon, this.iconColor, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: 110, height: 110, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey100)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24)),
        const SizedBox(height: 10), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.black, fontWeight: FontWeight.w600, fontSize: 11.5), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis))])));
  }
}
