import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
enum MgButtonVariant { primary, secondary, disabled }
class MgButton extends StatelessWidget {
  final String label; final VoidCallback? onPressed; final MgButtonVariant variant; final bool isLoading; final IconData? icon;
  const MgButton({super.key, required this.label, this.onPressed, this.variant = MgButtonVariant.primary, this.isLoading = false, this.icon});
  @override
  Widget build(BuildContext context) {
    final isDisabled = variant == MgButtonVariant.disabled || onPressed == null;
    final bg = switch (variant) { MgButtonVariant.primary => AppColors.primary, MgButtonVariant.secondary => AppColors.white, MgButtonVariant.disabled => AppColors.disabled };
    final fg = switch (variant) { MgButtonVariant.primary => AppColors.white, MgButtonVariant.secondary => AppColors.primary, MgButtonVariant.disabled => AppColors.grey350 };
    return SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
      onPressed: isDisabled || isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: fg, disabledBackgroundColor: AppColors.disabled, disabledForegroundColor: AppColors.grey350, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: variant == MgButtonVariant.secondary ? const BorderSide(color: AppColors.primary) : BorderSide.none)),
      child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)], Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))]),
    ));
  }
}
