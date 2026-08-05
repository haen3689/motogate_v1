import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mg_header.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MgHeader(title: 'Notifications', showBack: false),
        body: ListView(padding: const EdgeInsets.all(22), children: [
          _n(Icons.check_circle, AppColors.success, 'Road Tax Renewed',
              'KT 1234 renewed successfully', '2h ago', true),
          _n(Icons.security, AppColors.primary, 'Insurance Expiring',
              'KT 1234 expires in 30 days', '1d ago', false),
          _n(Icons.campaign, AppColors.warning, 'Promotion',
              '20% off new insurance', '3d ago', false)
        ]));
  }

  Widget _n(IconData ic, Color c, String t, String s, String time, bool u) =>
      Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: u ? AppColors.primarySurface : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.grey100)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(ic, color: c, size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(t, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Text(s, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 6),
                  Text(time, style: AppTextStyles.caption)
                ])),
            if (u)
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle))
          ]));
}
