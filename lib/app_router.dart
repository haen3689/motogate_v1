import 'dart:io';
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
import 'features/insurance/insurance_qr_payment_screen.dart';
import 'features/insurance/insurance_success_screen.dart';
import 'features/roadtax/roadtax_method_screen.dart';
import 'features/roadtax/roadtax_select_year_screen.dart';
import 'features/roadtax/roadtax_upload_proof_screen.dart';
import 'features/roadtax/roadtax_upload_payment_screen.dart';
import 'features/roadtax/roadtax_confirm_screen.dart';
import 'features/roadtax/roadtax_payment_screen.dart';
import 'features/roadtax/roadtax_qr_payment_screen.dart';
import 'features/roadtax/roadtax_success_screen.dart';
import 'features/inspection/inspection_center_list_screen.dart';
import 'features/inspection/inspection_select_vehicle_screen.dart';
import 'features/inspection/inspection_booking_screen.dart';
import 'features/inspection/inspection_payment_screen.dart';
import 'features/inspection/inspection_qr_payment_screen.dart';
import 'features/inspection/inspection_success_screen.dart';
import 'features/services/service_list_screen.dart';
import 'features/services/service_detail_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/profile/about_screen.dart';
import 'features/profile/privacy_policy_screen.dart';
import 'features/profile/profile_edit_screen.dart';
import 'features/chat/chat_list_screen.dart';
import 'features/chat/chat_conversation_screen.dart';
import 'features/announcements/announcement_list_screen.dart';
import 'features/announcements/announcement_detail_screen.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/documents/document_list_screen.dart';

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
        final args = s.arguments as Map<String, dynamic>?;
        return _r(TermsScreen(readOnly: args?['readOnly'] as bool? ?? false), s);
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
      case '/vehicle/edit':
        final v = s.arguments as Map<String, dynamic>;
        return _r(ScanOcrScreen(vehicle: v), s);
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
        return _r(const InsuranceCompanySelectScreen(), s);
      case '/insurance/vehicle':
        final company = s.arguments as Map<String, dynamic>;
        return _r(InsuranceSelectVehicleScreen(company: company), s);
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
      case '/insurance/qr_payment':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            InsuranceQrPaymentScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              company: args['company'] as Map<String, dynamic>,
              package: args['package'] as Map<String, dynamic>,
              insurance: args['insurance'] as Map<String, dynamic>,
            ),
            s);
      case '/insurance/success':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            InsuranceSuccessScreen(
              insurance: args['insurance'] as Map<String, dynamic>,
              vehicle: args['vehicle'] as Map<String, dynamic>,
              company: args['company'] as Map<String, dynamic>,
              package: args['package'] as Map<String, dynamic>,
              payment: args['payment'] as Map<String, dynamic>?,
            ),
            s);
      case '/roadtax':
        return _r(
            const PaidVehiclePickerScreen(
                title: 'ເລືອກລົດເສຍຄ່າທາງ', targetRoute: '/roadtax/method'),
            s);
      case '/roadtax/method':
        final v = s.arguments as Map<String, dynamic>;
        return _r(RoadtaxMethodScreen(vehicle: v), s);
      case '/roadtax/year':
        final v = s.arguments as Map<String, dynamic>;
        return _r(RoadtaxSelectYearScreen(vehicle: v), s);
      case '/roadtax/upload':
        final v = s.arguments as Map<String, dynamic>;
        return _r(RoadtaxUploadProofScreen(vehicle: v), s);
      case '/roadtax/upload/payment':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            RoadtaxUploadPaymentScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              taxYear: args['taxYear'] as int,
              paidAt: args['paidAt'] as DateTime?,
              expiredAt: args['expiredAt'] as DateTime?,
              proofImage: args['proofImage'] as File,
            ),
            s);
      case '/roadtax/confirm':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            RoadtaxConfirmScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              taxYear: args['taxYear'] as int,
              amount: args['amount'] as num,
            ),
            s);
      case '/roadtax/payment':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            RoadtaxPaymentScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              taxYear: args['taxYear'] as int,
              amount: args['amount'] as num,
            ),
            s);
      case '/roadtax/qr_payment':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            RoadtaxQrPaymentScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              roadTax: args['roadTax'] as Map<String, dynamic>,
            ),
            s);
      case '/roadtax/success':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            RoadtaxSuccessScreen(
              roadTax: args['roadTax'] as Map<String, dynamic>,
              vehicle: args['vehicle'] as Map<String, dynamic>,
              payment: args['payment'] as Map<String, dynamic>?,
            ),
            s);
      case '/inspection':
        return _r(const InspectionCenterListScreen(), s);
      case '/inspection/vehicle':
        final center = s.arguments as Map<String, dynamic>;
        return _r(InspectionSelectVehicleScreen(center: center), s);
      case '/inspection/booking':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            InspectionBookingScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              center: args['center'] as Map<String, dynamic>,
              services: (args['services'] as List).cast<Map<String, dynamic>>(),
            ),
            s);
      case '/inspection/payment':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            InspectionPaymentScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              center: args['center'] as Map<String, dynamic>,
              service: args['service'] as Map<String, dynamic>,
              appointmentAt: args['appointmentAt'] as DateTime,
            ),
            s);
      case '/inspection/qr_payment':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            InspectionQrPaymentScreen(
              vehicle: args['vehicle'] as Map<String, dynamic>,
              center: args['center'] as Map<String, dynamic>,
              service: args['service'] as Map<String, dynamic>,
              appointmentAt: args['appointmentAt'] as DateTime,
              inspection: args['inspection'] as Map<String, dynamic>,
            ),
            s);
      case '/inspection/success':
        final args = s.arguments as Map<String, dynamic>;
        return _r(
            InspectionSuccessScreen(
              inspection: args['inspection'] as Map<String, dynamic>,
              vehicle: args['vehicle'] as Map<String, dynamic>,
              center: args['center'] as Map<String, dynamic>,
              service: args['service'] as Map<String, dynamic>,
              payment: args['payment'] as Map<String, dynamic>?,
            ),
            s);
      case '/services/repair':
        return _r(const ServiceListScreen(type: ServiceType.repair), s);
      case '/services/dealer':
        return _r(const ServiceListScreen(type: ServiceType.dealer), s);
      case '/services/towing':
        return _r(const ServiceListScreen(type: ServiceType.towing), s);
      case '/services/detail':
        return _r(const ServiceDetailScreen(), s);
      case '/profile/edit':
        return _r(const ProfileEditScreen(), s);
      case '/settings':
        return _r(const SettingsScreen(), s);
      case '/about':
        return _r(const AboutScreen(), s);
      case '/privacy-policy':
        return _r(const PrivacyPolicyScreen(), s);
      case '/chat':
        return _r(const ChatListScreen(), s);
      case '/chat/conversation':
        return _r(const ChatConversationScreen(), s);
      case '/announcements':
        return _r(const AnnouncementListScreen(), s);
      case '/announcements/detail':
        return _r(const AnnouncementDetailScreen(), s);
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
