import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Auth events
  static Future<void> logLogin() =>
      _analytics.logLogin(loginMethod: 'phone_otp');

  // Vehicle events
  static Future<void> logAddVehicle(String vehicleType) =>
      _analytics.logEvent(name: 'add_vehicle', parameters: {'type': vehicleType});

  // Service events
  static Future<void> logViewService(String serviceName) =>
      _analytics.logEvent(name: 'view_service', parameters: {'name': serviceName});

  static Future<void> logPurchase({
    required String serviceType,
    required double amount,
  }) =>
      _analytics.logPurchase(
        currency: 'LAK',
        value: amount,
        items: [AnalyticsEventItem(itemName: serviceType)],
      );

  // Screen tracking
  static Future<void> logScreen(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  static Future<void> setUserPhone(String phone) =>
      _analytics.setUserId(id: phone);
}
