import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// ຂັ້ນຕອນອັບໂຫລດຄ່າທາງ: 0=ເລືອກລົດ, 1=ອັບໂຫລດ, 2=ຢືນຢັນ
class RoadtaxStepIndicator extends StatelessWidget {
  final int currentStep;
  const RoadtaxStepIndicator({super.key, required this.currentStep});

  static const _labels = ['ເລືອກລົດ', 'ອັບໂຫລດ', 'ຢືນຢັນ'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final done = i < currentStep;
        final active = i == currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == _labels.length - 1 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.successLight
                  : active
                      ? AppColors.primary
                      : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              done ? '✓ ${_labels[i]}' : (active ? '${i + 1} ${_labels[i]}' : '${i + 1} ${_labels[i]}'),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: done
                      ? AppColors.success
                      : active
                          ? Colors.white
                          : AppColors.grey500),
            ),
          ),
        );
      }),
    );
  }
}
