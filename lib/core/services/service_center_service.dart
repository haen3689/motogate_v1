import 'api_client.dart';

class ServiceCenterModel {
  const ServiceCenterModel({
    required this.id,
    required this.name,
    this.location,
    this.phone,
    this.logoUrl,
    this.ownerName,
    this.rating,
    required this.serviceType,
    this.lat,
    this.lng,
  });

  final int id;
  final String name;
  final String? location;
  final String? phone;
  final String? logoUrl;
  final String? ownerName;
  final double? rating;
  final String serviceType;
  final double? lat;
  final double? lng;

  factory ServiceCenterModel.fromJson(Map<String, dynamic> json) {
    final logo = json['logo'] as String?;
    return ServiceCenterModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      phone: json['phone'] as String?,
      logoUrl: (logo != null && logo.isNotEmpty) ? '${ApiClient.webBaseUrl}$logo' : null,
      ownerName: json['owner_name'] as String?,
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null,
      serviceType: json['service_type'] as String? ?? '',
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }
}

class ServiceCenterService {
  static final _dio = ApiClient.instance;

  /// type is one of: garage, dealer, towing. Empty on failure.
  static Future<List<ServiceCenterModel>> getByType(String type) async {
    try {
      final res = await _dio.get('/service_centers', queryParameters: {'type': type});
      final list = res.data['data'] as List<dynamic>;
      return list.map((e) => ServiceCenterModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<ServiceCenterModel?> getById(int id) async {
    try {
      final res = await _dio.get('/service_centers/$id');
      return ServiceCenterModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
