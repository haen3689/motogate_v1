import 'api_client.dart';

/// Polls the generic Payment status endpoint (BCEL OnePay). Creation of a
/// payment happens inside each payable's own create call (e.g.
/// ApiRoadTaxService.create), which already returns the initial payment
/// map — this is only used to check on it afterwards.
class ApiPaymentService {
  static final _dio = ApiClient.instance;

  static Future<Map<String, dynamic>> show(String uuid) async {
    final res = await _dio.get('/payments/$uuid');
    return res.data['data'] as Map<String, dynamic>;
  }
}
