import 'api_client.dart';

class ApiInsuranceService {
  static final _dio = ApiClient.instance;

  static Future<List<Map<String, dynamic>>> companies() async {
    final res = await _dio.get('/insurance_companies');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<List<Map<String, dynamic>>> myInsurances() async {
    final res = await _dio.get('/insurances');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<Map<String, dynamic>> create({
    required int vehicleId,
    required String company,
    required String package,
    required num amount,
    required String status,
    String? startDate,
    String? endDate,
  }) async {
    final res = await _dio.post('/insurances', data: {
      'vehicle_id': vehicleId,
      'company': company,
      'package': package,
      'amount': amount,
      'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ປະເພດລົດທີ່ຄິດຄ່າທຳນຽມປະກັນໄພຕາມ "ຈຳນວນບ່ອນນັ່ງ" ແທນ CC (ລົດຕູ້, ລົດເມ)
  static const seatBasedTypes = ['van', 'bus'];

  /// ປະເພດລົດທີ່ຄິດຄ່າທຳນຽມປະກັນໄພຕາມ "ນ້ຳໜັກ (ຕັນ)" ແທນ CC (ລົດລາກ, ລົດພ່ວງ)
  static const weightBasedTypes = ['towtruck', 'trailer'];

  /// ກັ່ນຕອງແພັກເກັດປະກັນໄພທີ່ເໝາະສົມກັບປະເພດ, ຂະໜາດ (CC/ບ່ອນນັ່ງ/ນ້ຳໜັກ) ແລະ ປະເພດການນຳໃຊ້ຂອງລົດ
  static List<Map<String, dynamic>> matchingPackages(
    List<dynamic> packages,
    Map<String, dynamic> vehicle,
  ) {
    final vType = vehicle['vehicle_type']?.toString();
    final vUsageType = vehicle['usage_type']?.toString();
    return packages.cast<Map<String, dynamic>>().where((p) {
      if (p['status']?.toString() != 'active') return false;
      final pType = p['vehicle_type']?.toString();
      if (pType != null && vType != null && pType != vType) return false;

      final pUsageType = p['usage_type']?.toString();
      if (pUsageType != null &&
          pUsageType.isNotEmpty &&
          pUsageType != vUsageType) {
        return false;
      }

      if (pType != null && seatBasedTypes.contains(pType)) {
        final seats = int.tryParse(vehicle['seat_count']?.toString() ?? '');
        if (seats != null) {
          final minSeats = num.tryParse(p['min_seats']?.toString() ?? '')?.toInt();
          final maxSeats = num.tryParse(p['max_seats']?.toString() ?? '')?.toInt();
          if (minSeats != null && seats < minSeats) return false;
          if (maxSeats != null && seats > maxSeats) return false;
        }
      } else if (pType != null && weightBasedTypes.contains(pType)) {
        final weight = num.tryParse(vehicle['weight']?.toString() ?? '');
        if (weight != null) {
          final minWeight = num.tryParse(p['min_weight']?.toString() ?? '');
          final maxWeight = num.tryParse(p['max_weight']?.toString() ?? '');
          if (minWeight != null && weight < minWeight) return false;
          if (maxWeight != null && weight > maxWeight) return false;
        }
      } else {
        final cc = int.tryParse(vehicle['cc']?.toString() ?? '');
        if (cc != null) {
          final minCc = num.tryParse(p['min_cc']?.toString() ?? '')?.toInt();
          final maxCc = num.tryParse(p['max_cc']?.toString() ?? '')?.toInt();
          if (minCc != null && cc < minCc) return false;
          if (maxCc != null && cc > maxCc) return false;
        }
      }
      return true;
    }).toList();
  }
}
