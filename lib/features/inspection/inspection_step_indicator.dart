import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// ຂັ້ນຕອນກວດສະພາບລົດ: 0=ເລືອກລົດ, 1=ເລືອກການຈອງ, 2=ຊຳລະເງິນ
class InspectionStepIndicator extends StatelessWidget {
  final int currentStep;
  const InspectionStepIndicator({super.key, required this.currentStep});

  static const _labels = ['ເລືອກລົດ', 'ເລືອກການຈອງ', 'ຊຳລະເງິນ'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStep = i ~/ 2;
          final done = leftStep < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: done ? AppColors.primary : AppColors.grey100,
            ),
          );
        }
        final step = i ~/ 2;
        final done = step < currentStep;
        final active = step == currentStep;
        return _pill(step + 1, _labels[step], done: done, active: active);
      }),
    );
  }

  Widget _pill(int number, String label, {required bool done, required bool active}) {
    final bg = done || active ? AppColors.primary : AppColors.grey100;
    final fg = done || active ? AppColors.white : AppColors.grey500;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: done
            ? const Icon(Icons.check, color: AppColors.white, size: 15)
            : Text('$number', style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800)),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active ? AppColors.primary : (done ? AppColors.black : AppColors.grey500))),
    ]);
  }
}
