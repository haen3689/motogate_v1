import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/images/motogate_logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              const Text('AutoPass',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('ລະບົບທະບຽນລົດ ແລະ ບໍລິການຕ່າງໆ',
                  textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
              const Spacer(flex: 4),
              MgButton(
                label: 'ເຂົ້າສູ່ລະບົບ',
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
