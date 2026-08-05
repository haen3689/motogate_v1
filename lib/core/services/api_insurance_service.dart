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

  /// ກັ່ນຕອງແພັກເກັດປະກັນໄພທີ່ເໝາະສົມກັບປະເພດ ແລະ ຂະໜາດ CC ຂອງລົດ
  static List<Map<String, dynamic>> matchingPackages(
    List<dynamic> packages,
    Map<String, dynamic> vehicle,
  ) {
    final vType = vehicle['vehicle_type']?.toString();
    final cc = int.tryParse(vehicle['cc']?.toString() ?? '');
    return packages.cast<Map<String, dynamic>>().where((p) {
      if (p['status']?.toString() != 'active') return false;
      final pType = p['vehicle_type']?.toString();
      if (pType != null && vType != null && pType != vType) return false;
      if (cc != null) {
        final minCc = num.tryParse(p['min_cc']?.toString() ?? '')?.toInt();
        final maxCc = num.tryParse(p['max_cc']?.toString() ?? '')?.toInt();
        if (minCc != null && cc < minCc) return false;
        if (maxCc != null && cc > maxCc) return false;
      }
      return true;
    }).toList();
  }
}
