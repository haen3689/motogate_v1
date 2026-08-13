import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:showcaseview/showcaseview.dart';
import 'core/services/coach_mark_tour.dart';
import 'core/theme/app_theme.dart';
import 'app_router.dart';
import 'firebase_options.dart';

// Must be registered before runApp — top-level function required by Firebase
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const AutoPassApp());
}

class AutoPassApp extends StatelessWidget {
  const AutoPassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoPass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      builder: (context, child) => ShowCaseWidget(
        globalTooltipActions: CoachMarkTour.globalActions,
        builder: (context) => child!,
      ),
    );
  }
}
