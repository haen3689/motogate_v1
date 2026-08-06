import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/terms_screen.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/auth/license_setup_screen.dart';
import 'features/home/main_shell.dart';
import 'features/vehicle/vehicle_list_screen.dart';
import 'features/vehicle/vehicle_detail_screen.dart';
import 'features/vehicle/add_vehicle_screen.dart';
import 'features/vehicle/scan_ocr_screen.dart';
import 'features/vehicle/vehicle_fee_payment_screen.dart';
import 'features/vehicle/vehicle_photos_screen.dart';
import 'features/vehicle/paid_vehicle_picker_screen.dart';
import 'features/insurance/insurance_select_vehicle_screen.dart';
import 'features/insurance/insurance_company_select_screen.dart';
import 'features/insurance/insurance_package_list_screen.dart';
import 'features/insurance/insurance_payment_screen.dart';
import 'features/roadtax/roadtax_select_vehicle_screen.dart';
import 'features/roadtax/roadtax_select_year_screen.dart';
import 'features/roadtax/roadtax_confirm_screen.dart';
import 'features/inspection/inspection_center_list_screen.dart';
import 'features/inspection/inspection_booking_screen.dart';
import 'features/services/service_list_screen.dart';
import 'features/services/service_detail_screen.dart';
import 'features/services/service_map_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/profile/change_phone_screen.dart';
import 'features/profile/profile_edit_screen.dart';
import 'features/chat/chat_list_screen.dart';
import 'features/chat/chat_conversation_screen.dart';
import 'features/notifications/notification_center_screen.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/documents/document_list_screen.dart';
import 'features/common/payment_method_screen.dart';
import 'features/common/payment_success_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings s) {
    switch (s.name) {
      case '/':
        return _r(const SplashScreen(), s);
      case '/welcome':
        return _r(const WelcomeScreen(), s);
      case '/onboarding':
        return _r(const OnboardingScreen(), s);
      case '/login':
        return _r(const LoginScreen(), s);
      case '/otp':
        return _r(const OtpScreen(), s);
      case '/terms':
        return _r(const TermsScreen(), s);
      case '/profile/setup':
        return _r(const ProfileSetupScreen(), s);
      case '/license/setup':
        return _r(const LicenseSetupScreen(), s);
      case '/home':
        return _r(const MainShell(), s);
      case '/vehicles':
        return _r(const VehicleListScreen(), s);
      case '/vehicle/detail':
        final v = s.arguments as Map<String, dynamic>;
        return _r(VehicleDetailScreen(vehicle: v), s);
      case '/vehicle/add':
        return _r(const AddVehicleScreen(), s);
      case '/vehicle/manual_entry':
        return _r(const ScanOcrScreen(), s);
      case '/vehicle/pay-fee':
        final v = s.arguments as Map<String, dynamic>;
        return _r(VehicleFeePaymentScreen(vehicle: v), s);
      case '/vehicle/documents-picker':
        return _r(const PaidVehiclePickerScreen(), s);
      case '/vehicle/photos-picker':
        return _r(
            const PaidVehiclePickerScreen(
                title: 'ເລືອກລົດເບິ່ງຮູບພາບ', targetRoute: '/vehicle/photos'),
            s);
      case '/vehicle/photos':
        final v = s.arguments as Map<String, dynamic>;
        return _r(VehiclePhotosScreen(vehicle: v), s);
      case '/insurance':
        return _r(const InsuranceSelectVehicleScreen(), s);
      case '/insurance/companies':
        final v = s.arguments as Map<String, dynamic>;
        return _r(InsuranceCompanySelectScreen(vehicle: v), s);
      case '/insurance/packages':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            InsurancePackageListScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              company: args['company'] as Map<String, dynamic>,
              packages: (args['packages'] as List).cast<Map<String, dynamic>>(),
            ),
            s);
      case '/insurance/payment':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            InsurancePaymentScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              company: args['company'] as Map<String, dynamic>,
              package: args['package'] as Map<String, dynamic>,
            ),
            s);
      case '/insurance/success':
        final args = s.arguments as Map<String, dynamic>?;
        return _r(
            PaymentSuccessScreen(
              title: args?['title']?.toString() ?? 'ປະກັນໄພ',
              amount: args?['amount']?.toString() ?? '',
            ),
            s);
      case '/roadtax':
        return _r(const RoadtaxSelectVehicleScreen(), s);
      case '/roadtax/year':
        return _r(const RoadtaxSelectYearScreen(), s);
      case '/roadtax/confirm':
        return _r(const RoadtaxConfirmScreen(), s);
      case '/roadtax/payment':
        return _r(
            PaymentMethodScreen(
                title: 'Road Tax',
                amount: '350,000 LAK',
                description: 'KT 1234',
                onSuccess: () {}),
            s);
      case '/roadtax/success':
        return _r(
            const PaymentSuccessScreen(
                title: 'Road Tax', amount: '350,000 LAK'),
            s);
      case '/inspection':
        return _r(const InspectionCenterListScreen(), s);
      case '/inspection/booking':
        return _r(const InspectionBookingScreen(), s);
      case '/services/repair':
        return _r(const ServiceListScreen(type: ServiceType.repair), s);
      case '/services/dealer':
        return _r(const ServiceListScreen(type: ServiceType.dealer), s);
      case '/services/towing':
        return _r(const ServiceListScreen(type: ServiceType.towing), s);
      case '/services/detail':
        return _r(const ServiceDetailScreen(), s);
      case '/services/map':
        return _r(const ServiceMapScreen(), s);
      case '/profile/edit':
        return _r(const ProfileEditScreen(), s);
      case '/settings':
        return _r(const SettingsScreen(), s);
      case '/profile/change-phone':
        return _r(const ChangePhoneScreen(), s);
      case '/chat':
        return _r(const ChatListScreen(), s);
      case '/chat/conversation':
        return _r(const ChatConversationScreen(), s);
      case '/notifications':
        return _r(const NotificationCenterScreen(), s);
      case '/transactions/detail':
        return _r(const TransactionDetailScreen(), s);
      case '/documents':
        final args = s.arguments;
        final vehicle = args != null ? args as Map<String, dynamic> : null;
        return _r(DocumentListScreen(vehicle: vehicle), s);
      default:
        return _r(
            Scaffold(body: Center(child: Text('Not found: ${s.name}'))), s);
    }
  }

  static MaterialPageRoute _r(Widget p, RouteSettings s) =>
      MaterialPageRoute(builder: (_) => p, settings: s);
}
