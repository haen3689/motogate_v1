import 'api_client.dart';

class ApiRoadTaxService {
  static final _dio = ApiClient.instance;

  static Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get('/road_taxes');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }
}
