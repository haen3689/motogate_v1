import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ApiOcrService {
  static Future<String> scan(File imageFile) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'ocr_scan.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });

    final response = await ApiClient.instance.post(
      '/ocr/scan',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    return (response.data['data']['text'] as String?) ?? '';
  }
}
