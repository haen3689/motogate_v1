import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://motogate-api.onrender.com/api/v1',
  );

  static String get webBaseUrl =>
      _baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');

  static const _storage = FlutterSecureStorage();
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _build();
    return _dio!;
  }

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 2. ปรับแต่ง HttpClient Adapter เพื่อป้องกัน SSL / Connection Reset บน Android Device
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) =>
                true; // รองรับ SSL Certificate
        client.idleTimeout = const Duration(seconds: 60);
        return client;
      },
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        print('Dio error intercepted');
        print('  uri: ${err.requestOptions.uri}');
        print('  method: ${err.requestOptions.method}');
        print('  type: ${err.type}');
        print('  message: ${err.message}');
        print('  error: ${err.error}');
        print('  response status: ${err.response?.statusCode}');
        print('  response data: ${err.response?.data}');

        final isConnectionError =
            err.type == DioExceptionType.connectionError ||
                err.type == DioExceptionType.connectionTimeout ||
                err.error.toString().contains('connection reset by peer');

        if (isConnectionError && err.requestOptions.extra['isRetry'] != true) {
          try {
            final options = err.requestOptions;
            options.extra['isRetry'] = true;
            await Future.delayed(const Duration(seconds: 2));

            final response = await dio.request(
              options.path,
              data: options.data,
              queryParameters: options.queryParameters,
              options: Options(
                method: options.method,
                headers: options.headers,
                extra: options.extra,
              ),
            );
            return handler.resolve(response);
          } catch (retryError) {
            return handler.next(err);
          }
        }
        handler.next(err);
      },
    ));

    return dio;
  }

  static Future<void> saveToken(String token) =>
      _storage.write(key: 'jwt_token', value: token);

  static Future<String?> getToken() => _storage.read(key: 'jwt_token');

  static Future<void> clearToken() => _storage.delete(key: 'jwt_token');
}
