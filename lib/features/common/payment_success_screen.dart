import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class PaymentSuccessScreen extends StatelessWidget {
  final String title, amount;
  const PaymentSuccessScreen({super.key, required this.title, required this.amount});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.white, body: SafeArea(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Spacer(), Container(width: 100, height: 100, decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle), child: const Icon(Icons.check_circle, color: AppColors.success, size: 56)),
      const SizedBox(height: 24), const Text('Payment Successful!', style: AppTextStyles.h3), const SizedBox(height: 8), Text(title, style: AppTextStyles.bodySmall), const SizedBox(height: 24),
      Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Amount', style: AppTextStyles.bodySmall), Text(amount, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))])])),
      const Spacer(), MgButton(label: 'Back to Home', onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false))]))));
  }
}
