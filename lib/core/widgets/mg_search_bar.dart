import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
class MgSearchBar extends StatelessWidget {
  final String hintText; final ValueChanged<String>? onChanged;
  const MgSearchBar({super.key, this.hintText = 'Search...', this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(height: 50, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey100)),
      child: TextField(onChanged: onChanged, decoration: InputDecoration(hintText: hintText, prefixIcon: const Icon(Icons.search, color: AppColors.grey500, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))));
  }
}
