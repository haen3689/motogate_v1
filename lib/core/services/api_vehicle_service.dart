import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ApiVehicleService {
  static final _dio = ApiClient.instance;

  static Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get('/vehicles');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<Map<String, dynamic>> create({
    required String plateNumber,
    String? brand,
    String? model,
    String? year,
    String? color,
    required String vehicleType,
    String? engineNumber,
    String? chassisNumber,
    String? cc,
    String? province,
    String? plateType,
    String? usageType,
    String? ownerName,
    String? fuelType,
    String? seatCount,
    String? axleCount,
    String? cylinderCount,
    String? weight,
    String? registrationExpiryDate,
    File? registrationFront,
    File? registrationBack,
  }) async {
    final hasFiles = registrationFront != null || registrationBack != null;
    final extraFields = {
      if (ownerName != null && ownerName.isNotEmpty) 'owner_name': ownerName,
      if (fuelType != null && fuelType.isNotEmpty) 'fuel_type': fuelType,
      if (seatCount != null && seatCount.isNotEmpty) 'seat_count': seatCount,
      if (axleCount != null && axleCount.isNotEmpty) 'axle_count': axleCount,
      if (cylinderCount != null && cylinderCount.isNotEmpty)
        'cylinder_count': cylinderCount,
      if (weight != null && weight.isNotEmpty) 'weight': weight,
      if (registrationExpiryDate != null && registrationExpiryDate.isNotEmpty)
        'registration_expiry_date': registrationExpiryDate,
    };

    if (hasFiles) {
      final form = FormData.fromMap({
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        if (brand != null && brand.isNotEmpty)         'brand':              brand,
        if (model != null && model.isNotEmpty)         'model':              model,
        if (year != null && year.isNotEmpty)           'year':               year,
        if (color != null && color.isNotEmpty)         'color':              color,
        if (engineNumber != null && engineNumber.isNotEmpty) 'engine_number': engineNumber,
        if (chassisNumber != null && chassisNumber.isNotEmpty) 'chassis_number': chassisNumber,
        if (cc != null && cc.isNotEmpty)               'cc':                 cc,
        if (province != null && province.isNotEmpty)   'province':           province,
        if (plateType != null && plateType.isNotEmpty) 'plate_type':         plateType,
        if (usageType != null && usageType.isNotEmpty) 'usage_type':         usageType,
        ...extraFields,
        if (registrationFront != null)
          'registration_front': await MultipartFile.fromFile(registrationFront.path),
        if (registrationBack != null)
          'registration_back': await MultipartFile.fromFile(registrationBack.path),
      });
      final res = await _dio.post('/vehicles', data: form,
          options: Options(contentType: 'multipart/form-data'));
      return res.data['data'] as Map<String, dynamic>;
    } else {
      final res = await _dio.post('/vehicles', data: {
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        if (brand != null && brand.isNotEmpty)         'brand':          brand,
        if (model != null && model.isNotEmpty)         'model':          model,
        if (year != null && year.isNotEmpty)           'year':           year,
        if (color != null && color.isNotEmpty)         'color':          color,
        if (engineNumber != null && engineNumber.isNotEmpty) 'engine_number': engineNumber,
        if (chassisNumber != null && chassisNumber.isNotEmpty) 'chassis_number': chassisNumber,
        if (cc != null && cc.isNotEmpty)               'cc':             cc,
        if (province != null && province.isNotEmpty)   'province':       province,
        if (plateType != null && plateType.isNotEmpty) 'plate_type':     plateType,
        if (usageType != null && usageType.isNotEmpty) 'usage_type':     usageType,
        ...extraFields,
      });
      return res.data['data'] as Map<String, dynamic>;
    }
  }

  /// Marks a vehicle's one-time platform registration fee as paid, after the
  /// (mock) payment flow succeeds.
  static Future<Map<String, dynamic>> markFeePaid(dynamic vehicleId) async {
    final res = await _dio.put('/vehicles/$vehicleId', data: {'fee_paid': true});
    return res.data['data'] as Map<String, dynamic>;
  }

  /// Uploads/replaces the vehicle's own front-view photo (separate from the
  /// registration-book scans) — used by the ຮູບພາບ gallery.
  static Future<Map<String, dynamic>> uploadFrontPhoto(dynamic vehicleId, File photo) async {
    final form = FormData.fromMap({'front_photo': await MultipartFile.fromFile(photo.path)});
    final res = await _dio.patch('/vehicles/$vehicleId', data: form,
        options: Options(contentType: 'multipart/form-data'));
    return res.data['data'] as Map<String, dynamic>;
  }
}
