import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ApiVehicleService {
  static final _dio = ApiClient.instance;

  /// ຄ່າທຳນຽມລົງທະບຽນລົດ ແຍກຕາມປະເພດລົດ — admin ຕັ້ງຄ່າໄດ້ຄົນລະລາຄາຕໍ່ປະເພດ
  static Future<List<Map<String, dynamic>>> feeRates() async {
    final res = await _dio.get('/vehicle_fee_rates');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// ຫາອັດຕາຄ່າທຳນຽມທີ່ກົງກັບປະເພດລົດ — server ຍັງເປັນຄົນຄິດໄລ່ລາຄາທີ່ແທ້ຈິງຕອນສ້າງ payment
  static num? matchingFeeAmount(List<Map<String, dynamic>> rates, String? vehicleType) {
    final rate = rates.cast<Map<String, dynamic>?>().firstWhere(
          (r) => r?['vehicle_type']?.toString() == vehicleType,
          orElse: () => null,
        );
    if (rate == null) return null;
    return num.tryParse(rate['amount']?.toString() ?? '');
  }

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
    File? frontPhoto,
    File? transportBooklet,
  }) async {
    final hasFiles = registrationFront != null ||
        registrationBack != null ||
        frontPhoto != null ||
        transportBooklet != null;
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
        if (frontPhoto != null)
          'front_photo': await MultipartFile.fromFile(frontPhoto.path),
        if (transportBooklet != null)
          'transport_booklet': await MultipartFile.fromFile(transportBooklet.path),
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

  static Future<Map<String, dynamic>> update(
    dynamic vehicleId, {
    String? plateNumber,
    String? brand,
    String? model,
    String? year,
    String? color,
    String? vehicleType,
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
    File? frontPhoto,
    File? transportBooklet,
  }) async {
    final fields = {
      if (plateNumber != null && plateNumber.isNotEmpty) 'plate_number': plateNumber,
      if (brand != null && brand.isNotEmpty)             'brand':          brand,
      if (model != null && model.isNotEmpty)             'model':          model,
      if (year != null && year.isNotEmpty)               'year':           year,
      if (color != null && color.isNotEmpty)             'color':          color,
      if (vehicleType != null && vehicleType.isNotEmpty) 'vehicle_type':   vehicleType,
      if (engineNumber != null && engineNumber.isNotEmpty) 'engine_number': engineNumber,
      if (chassisNumber != null && chassisNumber.isNotEmpty) 'chassis_number': chassisNumber,
      if (cc != null && cc.isNotEmpty)                   'cc':             cc,
      if (province != null && province.isNotEmpty)       'province':       province,
      if (plateType != null && plateType.isNotEmpty)     'plate_type':     plateType,
      if (usageType != null && usageType.isNotEmpty)     'usage_type':     usageType,
      if (ownerName != null && ownerName.isNotEmpty)     'owner_name':     ownerName,
      if (fuelType != null && fuelType.isNotEmpty)       'fuel_type':      fuelType,
      if (seatCount != null && seatCount.isNotEmpty)     'seat_count':     seatCount,
      if (axleCount != null && axleCount.isNotEmpty)     'axle_count':     axleCount,
      if (cylinderCount != null && cylinderCount.isNotEmpty) 'cylinder_count': cylinderCount,
      if (weight != null && weight.isNotEmpty)           'weight':         weight,
      if (registrationExpiryDate != null && registrationExpiryDate.isNotEmpty)
        'registration_expiry_date': registrationExpiryDate,
    };

    final hasFiles = registrationFront != null ||
        registrationBack != null ||
        frontPhoto != null ||
        transportBooklet != null;

    if (hasFiles) {
      final form = FormData.fromMap({
        ...fields,
        if (registrationFront != null)
          'registration_front': await MultipartFile.fromFile(registrationFront.path),
        if (registrationBack != null)
          'registration_back': await MultipartFile.fromFile(registrationBack.path),
        if (frontPhoto != null)
          'front_photo': await MultipartFile.fromFile(frontPhoto.path),
        if (transportBooklet != null)
          'transport_booklet': await MultipartFile.fromFile(transportBooklet.path),
      });
      final res = await _dio.patch('/vehicles/$vehicleId', data: form,
          options: Options(contentType: 'multipart/form-data'));
      return res.data['data'] as Map<String, dynamic>;
    } else {
      final res = await _dio.patch('/vehicles/$vehicleId', data: fields);
      return res.data['data'] as Map<String, dynamic>;
    }
  }

  /// Creates a pending BCEL OnePay Payment for the vehicle's one-time
  /// platform registration fee. fee_paid only flips true server-side once
  /// BCEL actually confirms the payment — this just returns the QR/deeplink.
  static Future<Map<String, dynamic>> payFee(dynamic vehicleId) async {
    final res = await _dio.post('/vehicles/$vehicleId/pay_fee');
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

  /// ເພີ່ມຜູ້ໃຊ້ສຳຮອງ (ຄອບຄົວ/ຄົນໃນຄອບຄົວ) ໃຫ້ເບິ່ງຂໍ້ມູນລົດຄັນນີ້ໄດ້ (ອ່ານໄດ້
  /// ຢ່າງດຽວ, ແກ້ໄຂບໍ່ໄດ້). ຜູ້ຖືກເພີ່ມຕ້ອງລົງທະບຽນແອັບໄວ້ກ່ອນແລ້ວ.
  static Future<Map<String, dynamic>> shareVehicle(
      dynamic vehicleId, String phoneNumber) async {
    final res = await _dio.post('/vehicles/$vehicleId/share', data: {
      'phone_number': phoneNumber,
    });
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ຖອດຜູ້ໃຊ້ສຳຮອງອອກຈາກລົດຄັນນີ້.
  static Future<Map<String, dynamic>> unshareVehicle(
      dynamic vehicleId, dynamic userId) async {
    final res = await _dio.delete('/vehicles/$vehicleId/share/$userId');
    return res.data['data'] as Map<String, dynamic>;
  }
}
