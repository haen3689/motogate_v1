import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MgBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const MgBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.primaryLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 86,
          child: Row(
            children: [
              _item('🏠', 'ໜ້າຫຼັກ', 0),
              _item('🔔', 'ປະກາດ', 1),
              _item('📋', 'ປະຫວັດ', 2),
              _item('👤', 'ໂປຣໄຟລ໌', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String emoji, String label, int i) {
    final active = currentIndex == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji,
                style: TextStyle(
                    fontSize: 22,
                    color: active ? AppColors.primary : AppColors.grey400)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: active ? AppColors.primary : AppColors.grey400)),
          ],
        ),
      ),
    );
  }
}
