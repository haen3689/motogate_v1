import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Transaction Detail'),
      body: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [const MgBadge(label: 'Completed', variant: MgBadgeVariant.success), const SizedBox(height: 16),
          Text('350,000 LAK', style: AppTextStyles.h2.copyWith(color: AppColors.primary)), const SizedBox(height: 24),
          _r('Type','Road Tax'), _r('Vehicle','KT 1234'), _r('Date','14/07/2026'), _r('Method','BCEL One')]))));
  }
  Widget _r(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: AppTextStyles.bodySmall), Text(v, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))]));
}
