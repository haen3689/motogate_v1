import 'dart:io';
import 'package:dio/dio.dart';
import 'advertisement_service.dart';
import 'api_client.dart';

class ApiAuthService {
  static final _dio = ApiClient.instance;

  /// ຂໍ OTP ຈາກ Rails → Rails ສົ່ງ SMS ຜ່ານ Telbiz
  static Future<void> requestOtp(String phoneNumber) async {
    await _dio.post('/auth/request_otp', data: {
      'phone_number': phoneNumber,
    });
  }

  /// ຢືນຢັນ OTP → ໄດ້ JWT token
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

  /// Login ດ້ວຍ phone number ຫຼັງຈາກ Telbiz OTP verified
  static Future<Map<String, dynamic>> loginPhone(String phoneNumber) async {
    final res = await _dio.post('/auth/login_phone', data: {
      'phone_number': phoneNumber,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    await ApiClient.saveToken(data['token'] as String);
    await AdPopupPrefs.reset();
    return data['user'] as Map<String, dynamic>;
  }

  /// ຂໍຂໍ້ມູນ user ປັດຈຸບັນ
  static Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/auth/me');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ສົ່ງ FCM token ໄປ Rails
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

  /// Requests a short-lived, single-purpose token for the "QR CODE
  /// ເອກະສານ" verification page (scanned by a third party, not this
  /// device) — separate from the long-lived login token. When [vehicleId]
  /// is given, the resulting verification page is scoped to just that
  /// vehicle instead of all of the user's vehicles.
  static Future<Map<String, dynamic>> requestVerifyToken({dynamic vehicleId}) async {
    final res = await _dio.post('/auth/verify_token', data: {
      if (vehicleId != null) 'vehicle_id': vehicleId,
    });
    return res.data['data'] as Map<String, dynamic>;
  }

  static Future<void> logout() => ApiClient.clearToken();

  static String errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'].toString();
    return 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່';
  }
}
