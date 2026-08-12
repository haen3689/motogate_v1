import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/fcm_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _c =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _f = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _sec = 59;
  bool _loading = false;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _phone = args?['phone'];
  }

  void _startTimer() {
    _timer?.cancel();
    _sec = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _sec--);
      if (_sec <= 0) t.cancel();
    });
  }

  bool get _ok => _c.every((c) => c.text.isNotEmpty);
  String get _otp => _c.map((c) => c.text).join();

  Future<void> _verify() async {
    if (!_ok || _loading || _phone == null) return;
    setState(() => _loading = true);
    try {
      final user = await ApiAuthService.verifyOtp(phoneNumber: _phone!, otp: _otp);
      await AuthService.signInAnonymously().catchError((_) {});
      await AnalyticsService.logLogin().catchError((_) {});
      final token = await FcmService.getToken();
      if (token != null) {
        await ApiAuthService.registerDevice(token).catchError((_) {});
      }
      // ຜູ້ໃຊ້ທີ່ເຄີຍປ້ອນໂປຣໄຟລ໌ຄົບແລ້ວ (ມີ first_name) ບໍ່ຕ້ອງຜ່ານ terms/setup ຊ້ຳ
      final hasProfile =
          (user['first_name'] as String?)?.trim().isNotEmpty ?? false;
      final nextRoute = hasProfile ? '/home' : '/terms';
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(nextRoute, (_) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          for (final c in _c) {
            c.clear();
          }
        });
        _f[0].requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is DioException
              ? ApiAuthService.errorMessage(e)
              : e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _resend() async {
    if (_phone == null || _loading || _sec > 0) return;
    setState(() => _loading = true);
    try {
      await ApiAuthService.requestOtp(_phone!);
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is DioException
              ? ApiAuthService.errorMessage(e)
              : e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _c) {
      c.dispose();
    }
    for (final f in _f) {
      f.dispose();
    }
    super.dispose();
  }

  String get _countdown => '00:${_sec.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top bar
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('powered by',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.grey300)),
                      Text('Bluestarinfinity',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Logo
              Container(
                width: 116,
                height: 116,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/images/motogate_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),

              // Title
              const Text('ຢືນຢັນ OTP',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black)),
              const SizedBox(height: 8),

              // Subtitle
              const Text('ລະຫັດ OTP ໄດ້ຖືກສົ່ງໄປຫາເບີ',
                  style: TextStyle(fontSize: 13, color: AppColors.grey400)),
              const SizedBox(height: 4),

              // Phone number
              Text(_phone ?? '+856 20 XXXX XXXX',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              const SizedBox(height: 20),

              // OTP card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                padding: const EdgeInsets.fromLTRB(7, 23, 7, 20),
                child: Column(
                  children: [
                    // Section header
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.password_outlined,
                            color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text('ລະຫັດ OTP',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Hint
                    const Text('ກະລຸນາໃສ່ລະຫັດ OTP 6 ຕົວເລກ',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.grey400)),
                    const SizedBox(height: 15),

                    // OTP boxes — Expanded so they fit any screen width
                    Row(
                      children: List.generate(
                          6,
                          (i) => Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: i < 5 ? 6 : 0),
                                  child: _otpBox(i),
                                ),
                              )),
                    ),
                    const SizedBox(height: 20),

                    // Confirm button
                    SizedBox(
                      width: 290,
                      height: 54,
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : ElevatedButton(
                              onPressed: _ok ? _verify : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _ok ? AppColors.primary : AppColors.grey100,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'ຢືນຢັນ  →',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: _ok
                                        ? AppColors.white
                                        : AppColors.grey300),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Resend row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ບໍ່ໄດ້ຮັບ OTP?  ',
                      style: TextStyle(fontSize: 13, color: AppColors.grey400)),
                  GestureDetector(
                    onTap: _sec <= 0 ? _resend : null,
                    child: Text('ສົ່ງ OTP ໃໝ່',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _sec <= 0
                                ? AppColors.primary
                                : AppColors.grey300)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Countdown
              Text('ຮັບໄດ້ອີກໃນ $_countdown',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey200)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int i) => SizedBox(
        height: 64,
        child: TextField(
          controller: _c[i],
          focusNode: _f[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0x991A1A1A)), // 60% opacity black
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (v) {
            if (v.isNotEmpty && i < 5) _f[i + 1].requestFocus();
            if (v.isEmpty && i > 0) _f[i - 1].requestFocus();
            setState(() {});
            if (_ok && !_loading) _verify();
          },
        ),
      );
}
