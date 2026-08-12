import 'dart:io';
import 'package:dio/dio.dart';
import 'advertisement_service.dart';
import 'api_client.dart';

class ApiAuthService {
  static final _dio = ApiClient.instance;

  /// ขอ OTP จาก Rails → Rails ส่ง SMS ผ่าน Telbiz
  static Future<bool> requestOtp(String phoneNumber) async {
    try {
      final response = await _dio.post('/auth/request_otp', data: {
        'phone_number': phoneNumber,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Request OTP failed');
      print('  uri: ${e.requestOptions.uri}');
      print('  method: ${e.requestOptions.method}');
      print('  type: ${e.type}');
      print('  message: ${e.message}');
      print('  error: ${e.error}');
      print('  response status: ${e.response?.statusCode}');
      print('  response data: ${e.response?.data}');
      rethrow; // ส่ง Exception ต่อให้ UI จัดการแสดงผล
    }
  }

  /// ยืนยัน OTP → ได้ JWT token
  static Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/verify_otp', data: {
      'phone_number': phoneNumber,
      'otp': otp,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    await ApiClient.saveToken(data['token'] as String);
    await AdPopupPrefs.reset();
    return data['user'] as Map<String, dynamic>;
  }

  /// Login ด้วย phone number หลังจาก Telbiz OTP verified
  static Future<Map<String, dynamic>> loginPhone(String phoneNumber) async {
    final res = await _dio.post('/auth/login_phone', data: {
      'phone_number': phoneNumber,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    await ApiClient.saveToken(data['token'] as String);
    await AdPopupPrefs.reset();
    return data['user'] as Map<String, dynamic>;
  }

  /// ขอข้อมูล user ปัจจุบัน
  static Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/auth/me');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ส่ง FCM token ไป Rails
  static Future<void> registerDevice(String fcmToken) async {
    await _dio.post('/auth/register_device', data: {
      'fcm_token': fcmToken,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? gender,
    String? dateOfBirth,
    String? province,
    String? district,
    String? village,
    String? idType,
    String? idNumber,
    String? idExpiryDate,
    String? licenseNumber,
    String? licenseType,
    String? licenseExpiryDate,
    File? idCardImage,
    File? licenseImage,
    File? profileImage,
  }) async {
    final form = FormData.fromMap({
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (province != null) 'province': province,
      if (district != null) 'district': district,
      if (village != null) 'village': village,
      if (idType != null) 'id_type': idType,
      if (idNumber != null) 'id_number': idNumber,
      if (idExpiryDate != null) 'id_expiry_date': idExpiryDate,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (licenseType != null) 'license_type': licenseType,
      if (licenseExpiryDate != null) 'license_expiry_date': licenseExpiryDate,
      if (idCardImage != null)
        'id_card_image': await MultipartFile.fromFile(
          idCardImage.path,
          filename: 'id_card.jpg',
        ),
      if (licenseImage != null)
        'license_image': await MultipartFile.fromFile(
          licenseImage.path,
          filename: 'license.jpg',
        ),
      if (profileImage != null)
        'profile_image': await MultipartFile.fromFile(
          profileImage.path,
          filename: 'profile.jpg',
        ),
    });

    final res = await _dio.put(
      '/auth/profile',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data['data']['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> requestVerifyToken(
      {dynamic vehicleId}) async {
    final res = await _dio.post('/auth/verify_token', data: {
      if (vehicleId != null) 'vehicle_id': vehicleId,
    });
    return res.data['data'] as Map<String, dynamic>;
  }

  static Future<void> logout() => ApiClient.clearToken();

  static String errorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.error.toString().contains('connection reset by peer')) {
      return 'ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບເຊີເວີໄດ້ (Connection Reset) ກະລຸນາກົດลองใหม่อีกครั้ง';
    }
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'].toString();
    return 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່';
  }
}
