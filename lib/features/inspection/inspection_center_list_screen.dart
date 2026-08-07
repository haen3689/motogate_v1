import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_client.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
    _locateUser();
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
      appBar: const MgHeader(title: 'ສູນກວດສະພາບລົດ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load)
              : _centers.isEmpty
                  ? _message('ບໍ່ພົບສູນກວດສະພາບລົດ', retry: _load)
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
                          MgSearchBar(
                            hintText: 'ຄົ້ນຫາສູນກວດສະພາບລົດ',
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: centers.isEmpty
                            ? _message('ບໍ່ພົບສູນທີ່ຄົ້ນຫາ')
                            : RefreshIndicator(
                                color: AppColors.primary,
                                onRefresh: _load,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                                  itemCount: centers.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _centerRow(centers[i]),
                                ),
                              ),
                      ),
                    ]),
    );
  }

  Widget _centerRow(Map<String, dynamic> center) {
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

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/inspection/vehicle', arguments: center),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null
                ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _logoFallback())
                : _logoFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$serviceCount ບໍລິການ',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ),
                ],
              ]),
              if (distance != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 13),
                  const SizedBox(width: 3),
                  Text('ຫ່າງຈາກທ່ານ ${distance.toStringAsFixed(1)} km',
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey600)),
                ]),
              ],
            ]),
          ),
          const SizedBox(width: 6),
          if (hasCoords)
            GestureDetector(
              onTap: () => _openInMaps(lat.toDouble(), lng.toDouble()),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 17),
              ),
            ),
          const Icon(Icons.chevron_right, color: AppColors.grey300, size: 22),
        ]),
      ),
    );
  }

  Widget _logoFallback() => Container(
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 26),
      );

  Widget _message(String text, {VoidCallback? retry}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 16),
              MgButton(label: 'ລອງໃໝ່', onPressed: retry),
            ],
          ]),
        ),
      );
}
