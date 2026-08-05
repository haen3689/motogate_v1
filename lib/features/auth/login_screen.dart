import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/analytics_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pc = TextEditingController();
  bool _ok = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pc.addListener(() {
      final digits = _pc.text.replaceAll(RegExp(r'[^0-9]'), '');
      setState(() => _ok = digits.length >= 8);
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_ok || _loading) return;
    setState(() => _loading = true);

    final digits = _pc.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final phone = '+856$digits';

    try {
      await ApiAuthService.requestOtp(phone);
      await AnalyticsService.logScreen('login');
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/otp',
          arguments: {'phone': phone},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/images/motogate_logo.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                  child: Text('MotoGate',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary))),
              const SizedBox(height: 4),
              const Center(
                  child: Text('ລະບົບທະບຽນລົດ ແລະ ບໍລິການຕ່າງໆ',
                      style: AppTextStyles.bodySmall)),
              _sectionCard(
                icon: Icons.phone_outlined,
                title: 'ເບີໂທລະສັບ',
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text('+856',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Container(width: 1, height: 30, color: AppColors.grey100),
                      Expanded(
                        child: TextField(
                          controller: _pc,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '20 XXXX XXXX',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : MgButton(
                      label: 'ສົ່ງ OTP',
                      variant: _ok
                          ? MgButtonVariant.primary
                          : MgButtonVariant.disabled,
                      onPressed: _ok ? _sendOtp : null,
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
          {required IconData icon,
          required String title,
          required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}
