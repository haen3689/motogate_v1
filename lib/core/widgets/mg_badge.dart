import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
enum MgBadgeVariant { success, warning, error }
class MgBadge extends StatelessWidget {
  final String label; final MgBadgeVariant variant;
  const MgBadge({super.key, required this.label, required this.variant});
  @override
  Widget build(BuildContext context) {
    final bg = switch (variant) { MgBadgeVariant.success => AppColors.successLight, MgBadgeVariant.warning => const Color(0xFFFEEED7), MgBadgeVariant.error => const Color(0xFFFDECEC) };
    final fg = switch (variant) { MgBadgeVariant.success => AppColors.success, MgBadgeVariant.warning => const Color(0xFFBC770C), MgBadgeVariant.error => const Color(0xFFE83333) };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)));
  }
}
