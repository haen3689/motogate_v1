import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ApiRoadTaxService {
  static final _dio = ApiClient.instance;

  static Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get('/road_taxes');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<List<Map<String, dynamic>>> rates() async {
    final res = await _dio.get('/road_tax_rates');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// ຄ່າທຳນຽມແພລດຟອມ (ສຳລັບການອັບໂຫລດຫຼັກຖານ) — admin ຕັ້ງຄ່າໄດ້ ເປັນຈຳນວນເງິນຄົງທີ່ ຫຼື ເປີເຊັນ
  static Future<Map<String, dynamic>> uploadFeeSetting() async {
    final res = await _dio.get('/road_tax_setting');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ຄິດໄລ່ຄ່າທຳນຽມແພລດຟອມ ຈາກ setting + ລາຄາຄ່າທາງອ້າງອີງ (matched rate) — mirrors
  /// RoadTaxSetting#compute_fee server-side; server still computes the
  /// authoritative value again when the record is actually created.
  static num computeUploadFee(Map<String, dynamic> setting, num baseAmount) {
    final feeType = setting['fee_type']?.toString();
    if (feeType == 'percent') {
      final percentRate = num.tryParse(setting['percent_rate']?.toString() ?? '') ?? 0;
      return (percentRate / 100) * baseAmount;
    }
    return num.tryParse(setting['flat_amount']?.toString() ?? '') ?? 0;
  }

  /// ປະເພດລົດທີ່ຄິດຄ່າທາງຕາມ "ຈຳນວນບ່ອນນັ່ງ" ແທນ CC
  static const seatBasedTypes = ['van', 'bus'];

  /// ປະເພດລົດທີ່ຄິດຄ່າທາງຕາມ "ນ້ຳໜັກ (ຕັນ)" ແທນ CC
  static const weightBasedTypes = ['towtruck', 'trailer'];

  /// ຄົ້ນຫາອັດຕາຄ່າທາງທີ່ກົງກັບລົດ (CC/ບ່ອນນັ່ງ/ນ້ຳໜັກ ຕາມປະເພດລົດ) — mirrors the
  /// server-side RoadTaxRate.for_vehicle matching so the app can show the real
  /// price before confirming; the server still computes/validates it on create.
  static Map<String, dynamic>? matchingRate(
    List<Map<String, dynamic>> rates,
    Map<String, dynamic> vehicle,
  ) {
    final vType = vehicle['vehicle_type']?.toString();
    for (final r in rates) {
      if (r['status']?.toString() != 'active') continue;
      final rType = r['vehicle_type']?.toString();
      if (rType != null && vType != null && rType != vType) continue;

      if (rType != null && seatBasedTypes.contains(rType)) {
        final seats = int.tryParse(vehicle['seat_count']?.toString() ?? '');
        if (seats != null) {
          final minSeats = num.tryParse(r['min_seats']?.toString() ?? '')?.toInt();
          final maxSeats = num.tryParse(r['max_seats']?.toString() ?? '')?.toInt();
          if (minSeats != null && seats < minSeats) continue;
          if (maxSeats != null && seats > maxSeats) continue;
        }
      } else if (rType != null && weightBasedTypes.contains(rType)) {
        final weight = num.tryParse(vehicle['weight']?.toString() ?? '');
        if (weight != null) {
          final minWeight = num.tryParse(r['min_weight']?.toString() ?? '');
          final maxWeight = num.tryParse(r['max_weight']?.toString() ?? '');
          if (minWeight != null && weight < minWeight) continue;
          if (maxWeight != null && weight > maxWeight) continue;
        }
      } else {
        final cc = int.tryParse(vehicle['cc']?.toString() ?? '');
        if (cc != null) {
          final minCc = num.tryParse(r['min_cc']?.toString() ?? '')?.toInt();
          final maxCc = num.tryParse(r['max_cc']?.toString() ?? '')?.toInt();
          if (minCc != null && cc < minCc) continue;
          if (maxCc != null && cc > maxCc) continue;
        }
      }
      return r;
    }
    return null;
  }

  /// ຈ່າຍຄ່າທາງໃນແອບ — ລາຄາຄິດໄລ່ຢູ່ server ຈາກ RoadTaxRate, client ບໍ່ໄດ້ສົ່ງລາຄາເອງ
  static Future<Map<String, dynamic>> create({
    required int vehicleId,
    required int taxYear,
    String? expiredAt,
  }) async {
    final res = await _dio.post('/road_taxes', data: {
      'vehicle_id': vehicleId,
      'tax_year': taxYear,
      'source': 'app_payment',
      if (expiredAt != null) 'expired_at': expiredAt,
    });
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ອັບໂຫລດຫຼັກຖານຈ່າຍຄ່າທາງນອກລະບົບ — ບັນທຶກເປັນ "ຈ່າຍແລ້ວ" ທັນທີ
  static Future<Map<String, dynamic>> uploadProof({
    required int vehicleId,
    required int taxYear,
    required File proofImage,
    String? paidAt,
    String? expiredAt,
  }) async {
    final form = FormData.fromMap({
      'vehicle_id': vehicleId,
      'tax_year': taxYear,
      'source': 'external_upload',
      if (paidAt != null) 'paid_at': paidAt,
      if (expiredAt != null) 'expired_at': expiredAt,
      'proof_image': await MultipartFile.fromFile(proofImage.path),
    });
    final res = await _dio.post('/road_taxes', data: form,
        options: Options(contentType: 'multipart/form-data'));
    return res.data['data'] as Map<String, dynamic>;
  }
}
