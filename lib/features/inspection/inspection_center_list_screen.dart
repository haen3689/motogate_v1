import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_client.dart';
import '../../core/services/coach_mark_tour.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_inspection_service.dart';
import '../../core/services/api_auth_service.dart';

class InspectionCenterListScreen extends StatefulWidget {
  const InspectionCenterListScreen({super.key});
  @override
  State<InspectionCenterListScreen> createState() => _InspectionCenterListScreenState();
}

class _InspectionCenterListScreenState extends State<InspectionCenterListScreen> {
  List<Map<String, dynamic>> _centers = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  double? _userLat;
  double? _userLng;

  static const _tourSeenPrefKey = 'inspection_centers_tour_seen';
  final _tourKeySearch = GlobalKey();
  final _tourKeyCard = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
    _locateUser();
  }

  Future<void> _maybeStartTour() =>
      CoachMarkTour.maybeStart(prefKey: _tourSeenPrefKey, start: _startTour);

  void _startTour() {
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase([_tourKeySearch, _tourKeyCard]);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiInspectionService.centers();
      final active = list.where((c) => c['status']?.toString() != 'inactive').toList();
      if (mounted) setState(() => _centers = _sorted(active));
      if (active.isNotEmpty) _maybeStartTour();
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is DioException ? ApiAuthService.errorMessage(e) : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ຂໍຕຳແໜ່ງປັດຈຸບັນຂອງຜູ້ໃຊ້ແບບ best-effort — ຖ້າບໍ່ໄດ້ຮັບອະນຸຍາດ ຫຼື ປິດ location
  /// ໜ້າຈໍນີ້ຍັງໃຊ້ງານໄດ້ປົກກະຕິ, ພຽງແຕ່ບໍ່ສະແດງໄລຍະທາງ/ຈັດຮຽງເທົ່ານັ້ນ.
  Future<void> _locateUser() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _centers = _sorted(_centers);
      });
    } catch (_) {
      // ບໍ່ສາມາດຂໍຕຳແໜ່ງໄດ້ — ຂ້າມໄປ, ບໍ່ສະແດງ error ໃຫ້ຜູ້ໃຊ້
    }
  }

  /// ໄລຍະທາງຈາກຜູ້ໃຊ້ໄປສູນ (km) — null ຖ້າບໍ່ມີພິກັດຂອງຜູ້ໃຊ້ ຫຼື ຂອງສູນ
  double? _distanceTo(Map<String, dynamic> center) {
    final lat = num.tryParse(center['latitude']?.toString() ?? '');
    final lng = num.tryParse(center['longitude']?.toString() ?? '');
    if (_userLat == null || _userLng == null || lat == null || lng == null) return null;
    return ApiInspectionService.distanceKm(_userLat!, _userLng!, lat.toDouble(), lng.toDouble());
  }

  /// ຈັດຮຽງໃກ້ສຸດກ່ອນ — ສູນທີ່ບໍ່ມີພິກັດ (ຫຼື ບໍ່ຮູ້ຕຳແໜ່ງຜູ້ໃຊ້) ຈະຢູ່ທ້າຍລາຍການ
  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> list) {
    if (_userLat == null || _userLng == null) return list;
    final withDist = <MapEntry<Map<String, dynamic>, double?>>[
      for (final c in list) MapEntry(c, _distanceTo(c)),
    ];
    withDist.sort((a, b) {
      if (a.value == null && b.value == null) return 0;
      if (a.value == null) return 1;
      if (b.value == null) return -1;
      return a.value!.compareTo(b.value!);
    });
    return withDist.map((e) => e.key).toList();
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ບໍ່ສາມາດເປີດແຜນທີ່ໄດ້'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _centers;
    final q = _query.trim().toLowerCase();
    return _centers
        .where((c) =>
            (c['name']?.toString() ?? '').toLowerCase().contains(q) ||
            (c['location']?.toString() ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final centers = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: 'ສູນກວດສະພາບລົດ', actions: [
        GestureDetector(
          onTap: _startTour,
          child: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: AppColors.white, size: 20),
          ),
        ),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load, icon: Icons.error_outline)
              : _centers.isEmpty
                  ? _message('ບໍ່ພົບສູນກວດສະພາບລົດ', retry: _load, icon: Icons.fact_check_outlined)
                  : Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('ເລືອກສູນກວດສະພາບລົດ',
                              style: AppTextStyles.titleSmall
                                  .copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('ເລືອກສູນທີ່ໃກ້ ຫຼື ສະດວກສຳລັບທ່ານ',
                              style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                          const SizedBox(height: 14),
                          Showcase(
                            key: _tourKeySearch,
                            title: 'ຄົ້ນຫາ',
                            description: 'ພິມຊື່ ຫຼື ທີ່ຢູ່ເພື່ອຄົ້ນຫາສູນກວດສະພາບລົດ',
                            targetBorderRadius: BorderRadius.circular(14),
                            child: MgSearchBar(
                              hintText: 'ຄົ້ນຫາສູນກວດສະພາບລົດ',
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: centers.isEmpty
                            ? _message('ບໍ່ພົບສູນທີ່ຄົ້ນຫາ', icon: Icons.search_off)
                            : RefreshIndicator(
                                color: AppColors.primary,
                                onRefresh: _load,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                                  itemCount: centers.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (_, i) => _centerRow(centers[i], i),
                                ),
                              ),
                      ),
                    ]),
    );
  }

  Widget _centerRow(Map<String, dynamic> center, int index) {
    final name = center['name']?.toString() ?? '';
    final location = center['location']?.toString() ?? '';
    final logoPath = center['logo']?.toString();
    final logoUrl =
        logoPath != null && logoPath.isNotEmpty ? '${ApiClient.webBaseUrl}$logoPath' : null;
    final serviceCount = ((center['inspection_services'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((svc) => svc['status']?.toString() == 'active')
        .length;
    final lat = num.tryParse(center['latitude']?.toString() ?? '');
    final lng = num.tryParse(center['longitude']?.toString() ?? '');
    final hasCoords = lat != null && lng != null;
    final distance = _distanceTo(center);
    final isNearest = index == 0 && distance != null;

    final row = GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/inspection/vehicle', arguments: center),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySurface,
                border: Border.all(color: AppColors.primaryLight, width: 1.5),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: logoUrl != null
                  ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _logoFallback())
                  : _logoFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 6),
                  const _StatusDot(),
                ]),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place_outlined, color: AppColors.grey400, size: 12.5),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                    ),
                  ]),
                ],
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (isNearest) _chip('ໃກ້ທີ່ສຸດ', icon: Icons.stars_rounded, bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309)),
            _chip('$serviceCount ບໍລິການ', icon: Icons.fact_check_outlined, bg: AppColors.primarySurface, fg: AppColors.primary),
            if (distance != null)
              _chip('${distance.toStringAsFixed(1)} km', icon: Icons.near_me_outlined, bg: AppColors.primarySurface, fg: AppColors.primary),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Spacer(),
            if (hasCoords) ...[
              GestureDetector(
                onTap: () => _openInMaps(lat.toDouble(), lng.toDouble()),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 18),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('ເລືອກ', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.white, size: 14),
              ]),
            ),
          ]),
        ]),
      ),
    );

    if (index != 0) return row;
    return Showcase(
      key: _tourKeyCard,
      title: 'ສູນກວດສະພາບລົດ',
      description: 'ເບິ່ງໄລຍະຫ່າງ ແລະ ຈຳນວນບໍລິການ, ກົດແຜນທີ່ເພື່ອນຳທາງ, ຫຼືກົດ "ເລືອກ" ເພື່ອດຳເນີນການຕໍ່',
      targetBorderRadius: BorderRadius.circular(20),
      tooltipActions: CoachMarkTour.lastStepActions(context),
      child: row,
    );
  }

  Widget _chip(String label, {required IconData icon, required Color bg, required Color fg}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: fg, size: 12.5),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _logoFallback() => Container(
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 32),
      );

  Widget _message(String text, {VoidCallback? retry, IconData icon = Icons.info_outline}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: AppColors.grey300, size: 40),
            const SizedBox(height: 12),
            Text(text, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 16),
              MgButton(label: 'ລອງໃໝ່', onPressed: retry),
            ],
          ]),
        ),
      );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        const Text('ເປີດ', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
