import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// ຂັ້ນຕອນຄ່າທາງ — ແຖບ pill 3 ຊ່ອງເຕັມຄວາມກວ້າງ (ຕາມແບບ Figma)
class RoadtaxStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  const RoadtaxStepIndicator({
    super.key,
    required this.currentStep,
    this.labels = const ['ເລືອກລົດ', 'ອັບໂຫລດ', 'ຢືນຢັນ'],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final done = i < currentStep;
        final active = i == currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
            child: _pill(i + 1, labels[i], done: done, active: active),
          ),
        );
      }),
    );
  }

  Widget _pill(int number, String label, {required bool done, required bool active}) {
    final bg = active
        ? AppColors.primary
        : done
            ? AppColors.primaryLight
            : AppColors.grey50;
    final fg = active
        ? AppColors.white
        : done
            ? AppColors.primaryDark
            : AppColors.grey400;
    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (done)
          Icon(Icons.check, color: fg, size: 13)
        else
          Text('$number', style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: fg, fontSize: 11.5, fontWeight: active ? FontWeight.w800 : FontWeight.w700)),
      ]),
    );
  }
}
