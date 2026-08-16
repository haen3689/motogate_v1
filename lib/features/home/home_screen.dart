import 'dart:async';
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

  /// Shows admin-managed ads (ຈັດການໂຄສະນາ) as a single swipeable popup on
  /// home load — one dialog, all ads as horizontally-swipeable pages, so
  /// the user can flip through them like a carousel instead of closing and
  /// reopening a dialog per ad. Checking "don't show again" is remembered
  /// until the next fresh login (see AdPopupPrefs).
  Future<void> _maybeShowAdPopups() async {
    if (_ads.isEmpty) return;
    if (await AdPopupPrefs.isDismissed()) return;
    if (!mounted) return;

    final dontShowAgain = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, __, ___) => _AdPopup(ads: _ads, onOpenAd: _openAd),
      transitionBuilder: (ctx, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child),
        );
      },
    );

    if (dontShowAgain ?? false) await AdPopupPrefs.dismiss();
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

/// One dialog for the whole ad queue — a horizontally swipeable carousel
/// (instead of a dialog-per-ad stack) so the user can flip between ads
/// without closing and reopening the popup. Pops `true` if "don't show
/// again" was checked when dismissed.
class _AdPopup extends StatefulWidget {
  final List<Advertisement> ads;
  final void Function(Advertisement) onOpenAd;

  const _AdPopup({required this.ads, required this.onOpenAd});

  @override
  State<_AdPopup> createState() => _AdPopupState();
}

class _AdPopupState extends State<_AdPopup> {
  static const _autoAdvanceInterval = Duration(seconds: 4);

  final _pageController = PageController();
  int _page = 0;
  bool _dontShowAgain = false;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  // Only worth auto-advancing when there's more than one ad to cycle
  // through; restarted on every page change (manual swipe or auto) so the
  // interval always counts from when a page last became visible.
  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (widget.ads.length <= 1) return;
    _autoAdvanceTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      // Always step to the next raw page index (never back to 0) so the
      // carousel keeps sliding the same direction — 1→2→3→1→2→3 — instead
      // of animating backwards when it wraps past the last ad. `_page` is
      // an unbounded index; the actual ad is `_page % widget.ads.length`
      // (see `_adIndex`), and the PageView itself has no fixed itemCount
      // so it can keep building "past the end" forever.
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // `_page` is the raw, unbounded PageView index (can exceed widget.ads
  // length, or go negative from a manual backward swipe past the start) —
  // this maps it back to the actual ad via Dart's always-non-negative `%`.
  int get _adIndex => _page % widget.ads.length;

  @override
  Widget build(BuildContext context) {
    final ad = widget.ads[_adIndex];
    final hasLink = ad.linkUrl != null && ad.linkUrl!.isNotEmpty;

    // Fractions of the current device's screen, so the popup scales to fit
    // phones of any size instead of a fixed pixel box.
    final screen = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;
    final maxHeight = screen.height - safePadding.top - safePadding.bottom - 32;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: screen.width * 0.045, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: screen.width),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 14)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      // Unbounded (null) when there's more than one ad, so
                      // the index can keep climbing past widget.ads.length
                      // forever instead of being clamped at the last page —
                      // that's what lets auto-advance and forward swipes
                      // wrap around as 1→2→3→1→2→3 instead of bouncing
                      // back to page 0.
                      itemCount: widget.ads.length > 1 ? null : 1,
                      onPageChanged: (i) {
                        setState(() => _page = i);
                        _startAutoAdvance();
                      },
                      itemBuilder: (_, i) {
                        final path = widget.ads[i % widget.ads.length].imageUrl;
                        final url = (path != null && path.isNotEmpty) ? '${ApiClient.webBaseUrl}$path' : null;
                        // `contain` (not `cover`) so a landscape ad image is
                        // never cropped at the sides to fill this portrait
                        // slot — any leftover space letterboxes against the
                        // same fallback color instead of losing part of the
                        // image.
                        return Container(
                          color: AppColors.primaryLight,
                          child: url != null
                              ? Image.network(url,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(color: AppColors.primaryLight))
                              : null,
                        );
                      },
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('ໂຄສະນາ',
                            style: TextStyle(
                                color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(_dontShowAgain),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.close_rounded, color: AppColors.black, size: 19),
                        ),
                      ),
                    ),
                    if (widget.ads.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < widget.ads.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _adIndex ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _adIndex ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ad.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.black)),
                    if (ad.subtitle != null && ad.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(ad.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.grey600, height: 1.4)),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: hasLink
                              ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                              : null,
                          color: hasLink ? null : AppColors.grey50,
                          border: hasLink ? null : Border.all(color: AppColors.grey100, width: 1.5),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: hasLink
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 6))]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              Navigator.of(context).pop(_dontShowAgain);
                              if (hasLink) widget.onOpenAd(ad);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(hasLink ? 'ເບິ່ງລາຍລະອຽດ' : 'ຮັບຊາບແລ້ວ',
                                      style: TextStyle(
                                          color: hasLink ? Colors.white : AppColors.grey900,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                  if (hasLink) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _dontShowAgain ? AppColors.primary : AppColors.grey200, width: 2),
                              color: _dontShowAgain ? AppColors.primary : AppColors.white,
                            ),
                            child: _dontShowAgain ? const Icon(Icons.check, size: 13, color: AppColors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('ບໍ່ຕ້ອງສະແດງອີກ ຈົນກວ່າຈະເຂົ້າສູ່ລະບົບໃໝ່',
                                style: TextStyle(fontSize: 12.5, color: AppColors.grey600)),
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
    );
  }
}
