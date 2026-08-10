import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/coach_mark_tour.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/service_center_service.dart';
import '../../core/services/api_inspection_service.dart';

enum ServiceType { repair, dealer, towing }

class ServiceListScreen extends StatefulWidget {
  final ServiceType type;
  const ServiceListScreen({super.key, required this.type});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  List<ServiceCenterModel> _centers = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  double? _userLat;
  double? _userLng;

  // Shared across garage/dealer/towing — same layout, one tour is enough
  // regardless of which of the 3 the user opens first.
  static const _tourSeenPrefKey = 'service_list_tour_seen';
  final _tourKeySearch = GlobalKey();
  final _tourKeyCard = GlobalKey();

  String get _apiType => switch (widget.type) {
        ServiceType.repair => 'garage',
        ServiceType.dealer => 'dealer',
        ServiceType.towing => 'towing',
      };
  String get _t => switch (widget.type) {
        ServiceType.repair => 'ສູນສ້ອມແປງລົດ',
        ServiceType.dealer => 'ຮ້ານຂາຍລົດ',
        ServiceType.towing => 'ບໍລິການລາກລົດ 24ຊມ',
      };
  IconData get _ic => switch (widget.type) {
        ServiceType.repair => Icons.build,
        ServiceType.dealer => Icons.store,
        ServiceType.towing => Icons.local_shipping,
      };

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
      final list = await ServiceCenterService.getByType(_apiType);
      if (mounted) setState(() => _centers = _sorted(list));
      if (list.isNotEmpty) _maybeStartTour();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is DioException ? 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່' : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ຂໍຕຳແໜ່ງປັດຈຸບັນແບບ best-effort — ຖ້າບໍ່ໄດ້ຮັບອະນຸຍາດ ໜ້ານີ້ຍັງໃຊ້ງານໄດ້ປົກກະຕິ
  /// ພຽງແຕ່ບໍ່ສະແດງໄລຍະທາງ/ຈັດຮຽງເທົ່ານັ້ນ.
  Future<void> _locateUser() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
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
      // ບໍ່ສາມາດຂໍຕຳແໜ່ງໄດ້ — ຂ້າມໄປ
    }
  }

  double? _distanceTo(ServiceCenterModel c) {
    if (_userLat == null || _userLng == null || c.lat == null || c.lng == null) return null;
    return ApiInspectionService.distanceKm(_userLat!, _userLng!, c.lat!, c.lng!);
  }

  List<ServiceCenterModel> _sorted(List<ServiceCenterModel> list) {
    if (_userLat == null || _userLng == null) return list;
    final withDist = <MapEntry<ServiceCenterModel, double?>>[
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

  List<ServiceCenterModel> get _filtered {
    if (_query.trim().isEmpty) return _centers;
    final q = _query.trim().toLowerCase();
    return _centers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.location ?? '').toLowerCase().contains(q))
        .toList();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ບໍ່ສາມາດໂທອອກໄດ້'),
          backgroundColor: AppColors.error,
        ));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final centers = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: _t, actions: [
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
              : Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                  child: Column(children: [
                    Showcase(
                      key: _tourKeySearch,
                      title: 'ຄົ້ນຫາ',
                      description: 'ພິມຊື່ ຫຼື ທີ່ຢູ່ເພື່ອຄົ້ນຫາ$_t',
                      targetBorderRadius: BorderRadius.circular(14),
                      child: MgSearchBar(hintText: 'ຄົ້ນຫາ$_t', onChanged: (v) => setState(() => _query = v)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _centers.isEmpty
                          ? _message('ຍັງບໍ່ມີ$_tໃນລະບົບ', retry: _load, icon: _ic)
                          : centers.isEmpty
                              ? _message('ບໍ່ພົບຂໍ້ມູນທີ່ຄົ້ນຫາ', icon: Icons.search_off)
                              : RefreshIndicator(
                                  color: AppColors.primary,
                                  onRefresh: _load,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 22),
                                    itemCount: centers.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (_, i) => _centerCard(centers[i], i),
                                  ),
                                ),
                    ),
                  ]),
                ),
    );
  }

  Widget _centerCard(ServiceCenterModel c, int index) {
    final hasCoords = c.lat != null && c.lng != null;
    final distance = _distanceTo(c);
    final card = GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/services/detail', arguments: c),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              border: Border.all(color: AppColors.primaryLight, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: c.logoUrl != null
                ? Image.network(c.logoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(_ic, color: AppColors.primary, size: 28))
                : Icon(_ic, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              if ((c.location ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.place_outlined, color: AppColors.grey400, size: 13),
                  const SizedBox(width: 3),
                  Expanded(child: Text(c.location!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 11.5))),
                ]),
              ],
              if (c.rating != null || distance != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  if (c.rating != null) ...[
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 2),
                    Text(c.rating!.toStringAsFixed(1), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                  ],
                  if (c.rating != null && distance != null) const SizedBox(width: 10),
                  if (distance != null) ...[
                    const Icon(Icons.near_me_outlined, color: AppColors.primary, size: 14),
                    const SizedBox(width: 2),
                    Text('${distance.toStringAsFixed(1)} km', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ]),
              ],
            ]),
          ),
          Column(children: [
            if ((c.phone ?? '').isNotEmpty)
              _iconBtn(Icons.phone, () => _call(c.phone!)),
            if (hasCoords) ...[
              const SizedBox(height: 8),
              _iconBtn(Icons.map_outlined, () => _openInMaps(c.lat!, c.lng!)),
            ],
          ]),
        ]),
      ),
    );

    if (index != 0) return card;
    return Showcase(
      key: _tourKeyCard,
      title: _t,
      description: 'ກົດເພື່ອເບິ່ງລາຍລະອຽດ, ຫຼືກົດໄອຄອນໂທ/ແຜນທີ່ເພື່ອຕິດຕໍ່ ຫຼື ນຳທາງໄດ້ທັນທີ',
      targetBorderRadius: BorderRadius.circular(20),
      tooltipActions: CoachMarkTour.lastStepActions(context),
      child: card,
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
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
