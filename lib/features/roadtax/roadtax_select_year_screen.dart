import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class RoadtaxSelectYearScreen extends StatefulWidget { const RoadtaxSelectYearScreen({super.key}); @override State<RoadtaxSelectYearScreen> createState() => _S(); }
class _S extends State<RoadtaxSelectYearScreen> {
  int _sel = -1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Select Year'),
      body: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Registration Year', style: AppTextStyles.titleMedium), const SizedBox(height: 16),
        ...List.generate(3, (i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GestureDetector(onTap: () => setState(() => _sel = i),
          child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _sel == i ? AppColors.primary : AppColors.grey100, width: _sel == i ? 2 : 1)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Year ${2027 + i}', style: AppTextStyles.titleSmall), if (_sel == i) const Icon(Icons.check_circle, color: AppColors.primary)]))))),
        const Spacer(), MgButton(label: 'Next', variant: _sel >= 0 ? MgButtonVariant.primary : MgButtonVariant.disabled, onPressed: _sel >= 0 ? () => Navigator.of(context).pushNamed('/roadtax/confirm') : null), const SizedBox(height: 16)])));
  }
}
