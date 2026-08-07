import 'dart:math';
import 'api_client.dart';

class ApiInspectionService {
  static final _dio = ApiClient.instance;

  /// ຄິດໄລ່ໄລຍະທາງລະຫວ່າງ 2 ຈຸດ (ຫົວໜ່ວຍ: ກິໂລແມັດ) ດ້ວຍສູດ Haversine
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // Earth radius km
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);

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
