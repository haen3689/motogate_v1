import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class Advertisement {
  const Advertisement({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.linkUrl,
  });

  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? linkUrl;

  factory Advertisement.fromJson(Map<String, dynamic> json) => Advertisement(
        id: json['id'] as int,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        imageUrl: json['image_url'] as String?,
        linkUrl: json['link_url'] as String?,
      );
}

class AdvertisementService {
  static final _dio = ApiClient.instance;

  /// Empty on failure/no ads configured — callers fall back to their own
  /// default banner rather than showing nothing.
  static Future<List<Advertisement>> getActive() async {
    try {
      final res = await _dio.get('/advertisements');
      final list = res.data['data'] as List<dynamic>;
      return list.map((e) => Advertisement.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fire-and-forget click tracking — never blocks or surfaces errors to
  /// the tap handler, the user's navigation to the ad's link matters more
  /// than whether the count made it to the server.
  static Future<void> trackClick(int id) async {
    try {
      await _dio.post('/advertisements/$id/click');
    } catch (_) {
      // best-effort
    }
  }
}

/// Tracks whether the user checked "don't show again" on the ad popup —
/// persisted so it survives app restarts, but reset on every fresh login
/// (see ApiAuthService.verifyOtp/loginPhone) since that's the "ຈົນກວ່າຈະ
/// ເຂົ້າສູ່ລະບົບໃໝ່" boundary the checkbox promises.
class AdPopupPrefs {
  static const _key = 'ads_dismissed_until_relogin';

  static Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
