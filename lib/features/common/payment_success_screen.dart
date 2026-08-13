import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String title, amount;
  final String? reference;
  const PaymentSuccessScreen({super.key, required this.title, required this.amount, this.reference});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
              ),
              const SizedBox(height: 24),
              const Text('ຊຳລະເງິນສຳເລັດ', textAlign: TextAlign.center, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  border: Border.all(color: AppColors.primaryLight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ຈຳນວນເງິນ', style: AppTextStyles.bodySmall),
                      Text(amount,
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  if (reference != null && reference!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.primaryLight, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ເລກທີ່ອ້າງອີງ',
                            style: AppTextStyles.caption.copyWith(color: AppColors.grey500, fontSize: 12)),
                        Text(reference!,
                            style: const TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                      ],
                    ),
                  ],
                ]),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: MgButton(
                  label: 'ກັບໜ້າຫຼັກ',
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
