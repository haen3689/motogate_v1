import 'api_client.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) => OnboardingSlide(
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        imageUrl: json['image_url'] as String?,
      );
}

class OnboardingService {
  static final _dio = ApiClient.instance;

  static const _fallback = [
    OnboardingSlide(
      title: 'ທະບຽນລົດງ່າຍ',
      subtitle: 'ຈັດການເອກະສານລົດຂອງທ່ານ\nໄດ້ຄົບໃນທີ່ດຽວ',
    ),
    OnboardingSlide(
      title: 'ບໍລິການຄົບຄ້ວາ',
      subtitle: 'ກວດກາເຕັກນິກ ຈ່າຍຄ່າທາງ\nແລະ ປະກັນໄພ ສະດວກໄວ',
    ),
    OnboardingSlide(
      title: 'ແຈ້ງເຕືອນທັນທີ',
      subtitle: 'ຕິດຕາມສະຖານະ ແລະ ຮັບການ\nແຈ້ງເຕືອນທຸກຄັ້ງໂດຍທັນທີ',
    ),
  ];

  static Future<List<OnboardingSlide>> getSlides() async {
    try {
      final res = await _dio.get('/onboarding_slides');
      final list = res.data['data'] as List<dynamic>;
      return list.map((e) => OnboardingSlide.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _fallback;
    }
  }
}
