import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class ChangePhoneScreen extends StatelessWidget {
  const ChangePhoneScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.white, appBar: const MgHeader(title: 'Change Phone'),
      body: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Current Phone', style: AppTextStyles.bodySmall), const SizedBox(height: 8),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)), child: const Text('+856 20 XXXX XXXX', style: AppTextStyles.bodyMedium)),
        const SizedBox(height: 24), Text('New Phone', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
        TextFormField(keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Enter new phone')),
        const Spacer(), MgButton(label: 'Send OTP', onPressed: () {}), const SizedBox(height: 16)])));
  }
}
