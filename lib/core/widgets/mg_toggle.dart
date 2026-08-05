import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
class MgToggle extends StatelessWidget {
  final bool value; final ValueChanged<bool>? onChanged;
  const MgToggle({super.key, required this.value, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => onChanged?.call(!value), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 46, height: 26,
      decoration: BoxDecoration(color: value ? AppColors.primary : const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(13)),
      child: AnimatedAlign(duration: const Duration(milliseconds: 200), alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(margin: const EdgeInsets.all(3), width: 20, height: 20, decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle)))));
  }
}
