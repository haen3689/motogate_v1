import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/api_client.dart';
import '../../core/services/advertisement_service.dart';
import '../../core/services/coach_mark_tour.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _user;
  List<Advertisement> _ads = [];

  static const _hotlineSize = Size(54, 51);
  static const _hotlineMargin = 16.0;
  static const _hotlineBottomClearance = 90.0; // keeps clear of bottom nav bar
  Offset? _hotlinePos;

  static const _tourSeenPrefKey = 'home_tour_seen';
  final _tourKeyAddVehicle = GlobalKey();
  final _tourKeyDocuments = GlobalKey();
  final _tourKeyPhotos = GlobalKey();
  final _tourKeyInspection = GlobalKey();
  final _tourKeyRoadTax = GlobalKey();
  final _tourKeyInsurance = GlobalKey();
  final _tourKeyRepair = GlobalKey();
  final _tourKeyDealer = GlobalKey();
  final _tourKeyTowing = GlobalKey();
  final _tourKeyHotline = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _init();
  }

  /// Sequences ads vs. the first-run coach-mark tour so they never render
  /// on top of each other. A brand-new install (tour not seen yet) runs the
  /// tour and skips ad popups just for this one session — the tour already
  /// marks itself seen, so returning users go straight to ads as before.
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final tourAlreadySeen = prefs.getBool(_tourSeenPrefKey) == true;

    await _loadAds();

    if (tourAlreadySeen) {
      _maybeShowAdPopups();
    } else {
      _maybeStartTour();
    }
  }

  Future<void> _loadAds() async {
    final ads = await AdvertisementService.getActive();
    if (mounted) setState(() => _ads = ads);
  }

  /// Shows admin-managed ads (ຈັດການໂຄສະນາ) as a stack of dismissible popup
  /// dialogs on home load, one at a time, instead of the old swipeable
  /// banner. Checking "don't show again" stops the whole queue and is
  /// remembered until the next fresh login (see AdPopupPrefs).
  Future<void> _maybeShowAdPopups() async {
    if (_ads.isEmpty) return;
    if (await AdPopupPrefs.isDismissed()) return;

    for (final ad in _ads) {
      if (!mounted) return;
      final dontShowAgain = await _showAdPopup(ad);
      if (dontShowAgain) {
        await AdPopupPrefs.dismiss();
        break;
      }
    }
  }

  Future<bool> _showAdPopup(Advertisement ad) async {
    final imagePath = ad.imageUrl;
    final imageUrl = (imagePath != null && imagePath.isNotEmpty) ? '${ApiClient.webBaseUrl}$imagePath' : null;
    bool dontShowAgain = false;

    final closedWithDontShowAgain = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Fractions of the current device's screen, so the popup scales to
        // fit phones of any size instead of a fixed pixel box.
        final screen = MediaQuery.of(ctx).size;
        final safePadding = MediaQuery.of(ctx).padding;
        final maxHeight = screen.height - safePadding.top - safePadding.bottom - 32;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: screen.width * 0.045, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: screen.width),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null)
                            Image.network(imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: AppColors.primaryLight))
                          else
                            Container(color: AppColors.primaryLight),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(dontShowAgain),
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ad.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                          if (ad.subtitle != null && ad.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(ad.subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                          ],
                          const SizedBox(height: 16),
                          if (ad.linkUrl != null && ad.linkUrl!.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop(dontShowAgain);
                                  _openAd(ad);
                                },
                                child: const Text('ເບິ່ງລາຍລະອຽດ', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => setDialogState(() => dontShowAgain = !dontShowAgain),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: dontShowAgain,
                                  onChanged: (v) => setDialogState(() => dontShowAgain = v ?? false),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Text('ບໍ່ຕ້ອງສະແດງອີກ ຈົນກວ່າຈະເຂົ້າສູ່ລະບົບໃໝ່',
                                      style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return closedWithDontShowAgain ?? false;
  }

  Future<void> _openAd(Advertisement ad) async {
    AdvertisementService.trackClick(ad.id);
    final url = ad.linkUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _maybeStartTour() =>
      CoachMarkTour.maybeStart(prefKey: _tourSeenPrefKey, start: _startTour);

  void _startTour() {
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase([
      _tourKeyAddVehicle,
      _tourKeyDocuments,
      _tourKeyPhotos,
      _tourKeyInspection,
      _tourKeyRoadTax,
      _tourKeyInsurance,
      _tourKeyRepair,
      _tourKeyDealer,
      _tourKeyTowing,
      _tourKeyHotline,
    ]);
  }

  void reloadUser() => _loadUser();

  Future<void> _loadUser() async {
    try {
      final user = await ApiAuthService.me();
      if (mounted) setState(() => _user = user);
    } catch (_) {}
  }

  String? get _profileImageUrl {
    final url = _user?['profile_image_url']?.toString();
    return (url != null && url.isNotEmpty) ? url : null;
  }

  Widget _buildAvatar() {
    final url = _profileImageUrl;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, color: AppColors.white, size: 30))
          : const Icon(Icons.person, color: AppColors.white, size: 30),
    );
  }

  String get _displayName {
    final fn = _user?['first_name'] ?? '';
    final ln = _user?['last_name'] ?? '';
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    return _user?['name'] ?? 'AutoPass User';
  }

  String get _phone => _user?['phone_number'] ?? '';
  bool get _verified => _user?['verified'] == true;

  void _initHotlinePos(Size screenSize) {
    _hotlinePos ??= Offset(
      screenSize.width - _hotlineSize.width - _hotlineMargin,
      screenSize.height - _hotlineSize.height - _hotlineBottomClearance - 60,
    );
  }

  void _onHotlineDrag(DragUpdateDetails details, Size screenSize) {
    final maxX = screenSize.width - _hotlineSize.width - _hotlineMargin;
    final maxY = screenSize.height - _hotlineSize.height - _hotlineBottomClearance;
    setState(() {
      _hotlinePos = Offset(
        (_hotlinePos!.dx + details.delta.dx).clamp(_hotlineMargin, maxX),
        (_hotlinePos!.dy + details.delta.dy).clamp(_hotlineMargin, maxY),
      );
    });
  }

  void _onHotlineDragEnd(Size screenSize) {
    final maxX = screenSize.width - _hotlineSize.width - _hotlineMargin;
    final snapToRight = (_hotlinePos!.dx + _hotlineSize.width / 2) > screenSize.width / 2;
    setState(() {
      _hotlinePos = Offset(snapToRight ? maxX : _hotlineMargin, _hotlinePos!.dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _initHotlinePos(screenSize);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(children: [
        Column(
          children: [
            _header(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(21, 22, 21, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(Icons.directions_car_outlined, 'ຈັດການພາຫະນະ'),
                  const SizedBox(height: 12),
                  Row(children: [
                    _card('ເພີ່ມຂໍ້ມູນລົດ', 'assets/images/icon_add_vehicle.png', () => Navigator.of(context).pushNamed('/vehicles'),
                        tourKey: _tourKeyAddVehicle,
                        tourTitle: 'ຈັດການພາຫະນະ',
                        tourDescription: 'ເລີ່ມຕົ້ນທີ່ນີ້ — ເພີ່ມຂໍ້ມູນລົດຂອງທ່ານເພື່ອຕິດຕາມທະບຽນ ແລະ ເອກະສານ'),
                    const SizedBox(width: 12),
                    _card('ເບິ່ງເອກະສານ', 'assets/images/icon_documents.png', () => Navigator.of(context).pushNamed('/vehicle/documents-picker'),
                        tourKey: _tourKeyDocuments,
                        tourTitle: 'ເບິ່ງເອກະສານ',
                        tourDescription: 'ເບິ່ງເອກະສານລົດ ແລະ ໃບຂັບຂີ່ຂອງທ່ານທັງໝົດໄດ້ທີ່ນີ້'),
                    const SizedBox(width: 12),
                    _card('ຮູບພາບ', 'assets/images/icon_photos.png',
                        () => Navigator.of(context).pushNamed('/vehicle/photos-picker'),
                        tourKey: _tourKeyPhotos,
                        tourTitle: 'ຮູບພາບເອກະສານ',
                        tourDescription: 'ອັບໂຫລດ ແລະ ເບິ່ງຮູບເອກະສານຕ່າງໆຂອງລົດທ່ານ'),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFEEF2F2), height: 1),
                  const SizedBox(height: 20),

                  _sectionTitle(Icons.miscellaneous_services_outlined, 'ບໍລິການລົດ'),
                  const SizedBox(height: 12),
                  Row(children: [
                    _card('ກວດກາເຕັກນິກ', 'assets/images/icon_inspection.png', () => Navigator.of(context).pushNamed('/inspection'),
                        tourKey: _tourKeyInspection,
                        tourTitle: 'ກວດກາເຕັກນິກ',
                        tourDescription: 'ຈອງຄິວກວດສະພາບເຕັກນິກລົດຂອງທ່ານ'),
                    const SizedBox(width: 12),
                    _card('ຈ່າຍຄ່າທາງ', 'assets/images/icon_road_tax.png', () => Navigator.of(context).pushNamed('/roadtax'),
                        tourKey: _tourKeyRoadTax,
                        tourTitle: 'ຈ່າຍຄ່າທາງ',
                        tourDescription: 'ຊຳລະຄ່າທາງປະຈຳປີຜ່ານແອັບໄດ້ງ່າຍໆ'),
                    const SizedBox(width: 12),
                    _card('ປະກັນໄພ', 'assets/images/icon_insurance.png', () => Navigator.of(context).pushNamed('/insurance'),
                        tourKey: _tourKeyInsurance,
                        tourTitle: 'ປະກັນໄພ',
                        tourDescription: 'ຊື້ ແລະ ຕິດຕາມປະກັນໄພລົດຂອງທ່ານ'),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFEEF2F2), height: 1),
                  const SizedBox(height: 20),

                  _sectionTitle(Icons.apps_outlined, 'ບໍລິການເສີມ'),
                  const SizedBox(height: 12),
                  Row(children: [
                    _card('ສູນສ້ອມແປງລົດ', 'assets/images/icon_repair_center.png', () => Navigator.of(context).pushNamed('/services/repair'),
                        tourKey: _tourKeyRepair,
                        tourTitle: 'ສູນສ້ອມແປງລົດ',
                        tourDescription: 'ຄົ້ນຫາສູນສ້ອມແປງທີ່ໃກ້ທ່ານທີ່ສຸດ'),
                    const SizedBox(width: 12),
                    _card('ຮ້ານຂາຍລົດ', 'assets/images/icon_dealer.png', () => Navigator.of(context).pushNamed('/services/dealer'),
                        tourKey: _tourKeyDealer,
                        tourTitle: 'ຮ້ານຂາຍລົດ',
                        tourDescription: 'ຄົ້ນຫາຮ້ານຂາຍລົດທີ່ໜ້າເຊື່ອຖື'),
                    const SizedBox(width: 12),
                    _card('ລາກລົດ 24ຊມ', 'assets/images/icon_towing.png', () => Navigator.of(context).pushNamed('/services/towing'),
                        tourKey: _tourKeyTowing,
                        tourTitle: 'ບໍລິການລາກລົດ',
                        tourDescription: 'ຕິດຕໍ່ບໍລິການລາກລົດ 24 ຊົ່ວໂມງ'),
                  ]),
                  const SizedBox(height: 22 + 80),
                ],
              ),
            ),
          ),
          ],
        ),
        Positioned(
          left: _hotlinePos!.dx,
          top: _hotlinePos!.dy,
          child: GestureDetector(
            onPanUpdate: (d) => _onHotlineDrag(d, screenSize),
            onPanEnd: (_) => _onHotlineDragEnd(screenSize),
            onTap: () => Navigator.of(context).pushNamed('/chat'),
            child: Showcase(
              key: _tourKeyHotline,
              title: 'ຕິດຕໍ່ພວກເຮົາ',
              description: 'ກົດປຸ່ມນີ້ເພື່ອຕິດຕໍ່ສູນບໍລິການລູກຄ້າ — ລາກຍ້າຍຕຳແໜ່ງໄດ້ຕາມໃຈມັກ',
              targetShapeBorder: const CircleBorder(),
              tooltipActions: CoachMarkTour.lastStepActions(context),
              child: _hotlineBtn(),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 22,
        right: 22,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(_phone,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFD9F5F0))),
                const SizedBox(height: 8),
                if (_verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('✓ ຢືນຢັນແລ້ວ',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF009951))),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _startTour,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) => Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      ]);

  Widget _card(String label, String iconAsset, VoidCallback onTap,
      {GlobalKey? tourKey, String? tourTitle, String? tourDescription}) {
    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                child: Image.asset(iconAsset, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ),
          ],
        ),
      ),
    );

    return Expanded(
      child: tourKey == null
          ? card
          : Showcase(
              key: tourKey,
              title: tourTitle,
              description: tourDescription ?? '',
              targetBorderRadius: BorderRadius.circular(16),
              child: card,
            ),
    );
  }

  Widget _hotlineBtn() => Container(
        width: _hotlineSize.width,
        height: _hotlineSize.height,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🤖', style: TextStyle(fontSize: 18)),
            SizedBox(height: 1),
            Text('Hotline',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.white),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
