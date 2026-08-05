import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class RoadtaxConfirmScreen extends StatelessWidget {
  const RoadtaxConfirmScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Confirm'),
      body: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Details', style: AppTextStyles.titleMedium), const SizedBox(height: 16),
            _r('Vehicle','KT 1234 - Toyota Camry'), _r('Year','2027'), _r('Fee','350,000 LAK'), const Divider(height: 24), _r('Total','350,000 LAK', bold: true)])),
        const Spacer(), MgButton(label: 'Pay Now', onPressed: () => Navigator.of(context).pushNamed('/roadtax/payment')), const SizedBox(height: 16)])));
  }
  Widget _r(String l, String v, {bool bold = false}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: AppTextStyles.bodySmall), Text(v, style: bold ? AppTextStyles.titleSmall.copyWith(color: AppColors.primary) : AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))]));
}
