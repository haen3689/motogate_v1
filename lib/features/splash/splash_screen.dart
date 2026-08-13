import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_client.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/fcm_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    FcmService.initialize();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.9, curve: Curves.easeOut)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.9, curve: Curves.easeIn)),
    );

    _controller.forward();
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final token = await ApiClient.getToken();
    if (token != null) {
      try {
        await ApiAuthService.me();
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        return;
      } on DioException catch (e) {
        // Only a real "your token is invalid/expired" response should log
        // the user out. Network hiccups, timeouts, or a flaky server (5xx)
        // must NOT wipe a perfectly valid saved token — otherwise a user
        // who just logged in gets bounced back to onboarding the moment
        // they reopen the app on a bad connection.
        if (e.response?.statusCode == 401) {
          await ApiClient.clearToken();
        } else if (mounted) {
          // Trust the cached session and let them in; HomeScreen will
          // retry the user fetch itself.
          Navigator.of(context).pushReplacementNamed('/home');
          return;
        }
      } catch (_) {
        // Unexpected non-network error decoding the response etc. — treat
        // as a real auth failure rather than risk looping forever.
        await ApiClient.clearToken();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(onboardingDone ? '/welcome' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  const Spacer(flex: 34),
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 103,
                        height: 103,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(38),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Image.asset('assets/images/motogate_logo.png',
                            fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: const Text('AutoPass',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Text('ລະບົບທະບຽນລົດ ແລະ ບໍລິການ',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.white.withAlpha(217))),
                    ),
                  ),
                  const Spacer(flex: 66),
                ],
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Text('v1.0.0',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.white.withAlpha(153))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
