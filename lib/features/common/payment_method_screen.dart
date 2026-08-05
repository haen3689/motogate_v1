import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class PaymentMethodScreen extends StatefulWidget {
  final String title, amount, description; final VoidCallback onSuccess;
  const PaymentMethodScreen({super.key, required this.title, required this.amount, required this.description, required this.onSuccess});
  @override State<PaymentMethodScreen> createState() => _S();
}
class _S extends State<PaymentMethodScreen> {
  int _sel = -1;
  final _m = const [{'name':'BCEL One','icon':Icons.account_balance},{'name':'JDB Bank','icon':Icons.account_balance},{'name':'Cash','icon':Icons.payments}];
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: MgHeader(title: widget.title),
      body: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [const Text('Amount', style: AppTextStyles.bodySmall), const SizedBox(height: 4), Text(widget.amount, style: AppTextStyles.h2.copyWith(color: AppColors.primary)), const SizedBox(height: 4), Text(widget.description, style: AppTextStyles.caption)])),
        const SizedBox(height: 24), const Text('Payment Method', style: AppTextStyles.titleMedium), const SizedBox(height: 12),
        ...List.generate(_m.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GestureDetector(onTap: () => setState(() => _sel = i),
          child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _sel == i ? AppColors.primary : AppColors.grey100, width: _sel == i ? 2 : 1)),
            child: Row(children: [Icon(_m[i]['icon'] as IconData, color: AppColors.primary), const SizedBox(width: 16), Text(_m[i]['name'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)), const Spacer(), if (_sel == i) const Icon(Icons.check_circle, color: AppColors.primary)]))))),
        const Spacer(), MgButton(label: 'Pay Now', variant: _sel >= 0 ? MgButtonVariant.primary : MgButtonVariant.disabled, onPressed: _sel >= 0 ? widget.onSuccess : null), const SizedBox(height: 16)])));
  }
}
