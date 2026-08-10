import 'api_client.dart';

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    this.body,
    this.imageUrl,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? body;
  final String? imageUrl;
  final DateTime createdAt;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final image = json['image_url'] as String?;
    return AnnouncementModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      imageUrl: (image != null && image.isNotEmpty) ? '${ApiClient.webBaseUrl}$image' : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class AnnouncementService {
  static final _dio = ApiClient.instance;

  static Future<List<AnnouncementModel>> getAll() async {
    try {
      final res = await _dio.get('/announcements');
      final list = res.data['data'] as List<dynamic>;
      return list.map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches the single announcement and registers a real view on the
  /// server — call this when the user actually opens the detail screen,
  /// not just when it appears in the list.
  static Future<AnnouncementModel?> markViewed(int id) async {
    try {
      final res = await _dio.get('/announcements/$id');
      return AnnouncementModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Resets the home-screen bell badge — call when the announcements list
  /// screen opens, since that's the moment everything currently listed
  /// counts as "seen".
  static Future<void> markSeen() async {
    try {
      await _dio.post('/announcements/mark_seen');
    } catch (_) {
      // best-effort
    }
  }
}
