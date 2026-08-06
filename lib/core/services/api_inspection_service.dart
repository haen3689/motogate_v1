import 'api_client.dart';

class ApiInspectionService {
  static final _dio = ApiClient.instance;

  static Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get('/inspections');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<List<Map<String, dynamic>>> centers() async {
    final res = await _dio.get('/inspection_centers');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// ກັ່ນຕອງບໍລິການກວດສະພາບທີ່ເໝາະສົມກັບປະເພດ ແລະ CC ຂອງລົດ
  static List<Map<String, dynamic>> matchingServices(
    List<dynamic> services,
    Map<String, dynamic> vehicle,
  ) {
    final vType = vehicle['vehicle_type']?.toString();
    return services.cast<Map<String, dynamic>>().where((svc) {
      if (svc['status']?.toString() != 'active') return false;
      final sType = svc['vehicle_type']?.toString();
      if (sType != null && sType.isNotEmpty && vType != null && sType != vType) {
        return false;
      }

      final cc = int.tryParse(vehicle['cc']?.toString() ?? '');
      if (cc != null) {
        final minCc = num.tryParse(svc['min_cc']?.toString() ?? '')?.toInt();
        final maxCc = num.tryParse(svc['max_cc']?.toString() ?? '')?.toInt();
        if (minCc != null && cc < minCc) return false;
        if (maxCc != null && cc > maxCc) return false;
      }
      return true;
    }).toList();
  }

  static Future<Map<String, dynamic>> create({
    required int vehicleId,
    required int inspectionCenterId,
    required String appointmentAt,
    String? notes,
  }) async {
    final res = await _dio.post('/inspections', data: {
      'vehicle_id': vehicleId,
      'inspection_center_id': inspectionCenterId,
      'appointment_at': appointmentAt,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return res.data['data'] as Map<String, dynamic>;
  }
}
