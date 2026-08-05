import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
class MgHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title; final bool showBack; final List<Widget>? actions; final VoidCallback? onBack;
  const MgHeader({super.key, required this.title, this.showBack = true, this.actions, this.onBack});
  @override Size get preferredSize => const Size.fromHeight(90);
  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.primary, child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [if (showBack) GestureDetector(onTap: onBack ?? () => Navigator.of(context).maybePop(), child: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 24)), if (showBack) const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.white))), if (actions != null) ...actions!]))));
  }
}
