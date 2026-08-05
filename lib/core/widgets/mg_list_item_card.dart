import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
class MgListItemCard extends StatelessWidget {
  final String title; final String subtitle; final String? trailing; final IconData icon; final Color iconColor; final VoidCallback? onTap; final Widget? badge;
  const MgListItemCard({super.key, required this.title, required this.subtitle, this.trailing, this.icon = Icons.build, this.iconColor = AppColors.primary, this.onTap, this.badge});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey100)),
      child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: AppTextStyles.titleSmall)), if (badge != null) badge!]), const SizedBox(height: 4), Text(subtitle, style: AppTextStyles.bodySmall)])),
        if (trailing != null) ...[const SizedBox(width: 8), Text(trailing!, style: AppTextStyles.caption)], const SizedBox(width: 4), const Icon(Icons.chevron_right, color: AppColors.grey300, size: 20)])));
  }
}
