import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/api_client.dart';
import '../../core/services/api_insurance_service.dart';
import '../../core/services/api_road_tax_service.dart';
import '../../core/services/api_inspection_service.dart';
import '../../core/services/api_vehicle_service.dart';
import '../../core/services/coach_mark_tour.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

/// A single photo slot in the gallery grid. View-only — every photo here
/// comes from its own dedicated flow (profile, vehicle registration,
/// inspection booking, road-tax payment, insurance purchase); this screen
/// never uploads anything itself.
class _PhotoTile {
  const _PhotoTile({required this.label, required this.icon, this.url});
  final String label;
  final IconData icon;
  final String? url;
  bool get hasPhoto => url != null && url!.isNotEmpty;
}

/// 2-column document-photo gallery for a single vehicle, matching the
/// Figma "PhotoGallery v2" design. Reached via [PaidVehiclePickerScreen]
/// the same way the Documents screen is.
class VehiclePhotosScreen extends StatefulWidget {
  const VehiclePhotosScreen({super.key, required this.vehicle});
  final Map<String, dynamic> vehicle;

  @override
  State<VehiclePhotosScreen> createState() => _VehiclePhotosScreenState();
}

class _VehiclePhotosScreenState extends State<VehiclePhotosScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _vehicle;
  List<Map<String, dynamic>> _roadTaxes = [];
  List<Map<String, dynamic>> _inspections = [];
  List<Map<String, dynamic>> _insurances = [];
  bool _loading = true;

  static const _tourSeenPrefKey = 'vehicle_photos_tour_seen';
  final _tourKeyProgress = GlobalKey();
  final _tourKeyCard = GlobalKey();

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _loadData();
  }

  Future<void> _maybeStartTour() =>
      CoachMarkTour.maybeStart(prefKey: _tourSeenPrefKey, start: _startTour);

  void _startTour() {
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase([_tourKeyProgress, _tourKeyCard]);
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiAuthService.me(),
        ApiVehicleService.list(),
        ApiRoadTaxService.list(),
        ApiInspectionService.list(),
        ApiInsuranceService.myInsurances(),
      ]);
      if (mounted) {
        setState(() {
          _user = results[0] as Map<String, dynamic>;
          final vehicles = results[1] as List<Map<String, dynamic>>;
          _vehicle = vehicles.firstWhere(
            (v) => v['id'].toString() == widget.vehicle['id'].toString(),
            orElse: () => widget.vehicle,
          );
          _roadTaxes = results[2] as List<Map<String, dynamic>>;
          _inspections = results[3] as List<Map<String, dynamic>>;
          _insurances = results[4] as List<Map<String, dynamic>>;
        });
      }
    } catch (_) {
      // Non-fatal — photo tiles just fall back to placeholders.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _maybeStartTour();
  }

  /// First road-tax record for this vehicle with an uploaded payment-proof
  /// photo attached — already an absolute URL from the server.
  String? get _roadTaxProofUrl {
    final vehicleId = widget.vehicle['id'];
    for (final t in _roadTaxes) {
      if (t['vehicle_id'] != vehicleId) continue;
      final url = t['proof_image_url']?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  /// First inspection record for this vehicle with an uploaded sticker —
  /// stored as a relative path, needs the web base URL prefixed.
  String? get _inspectionStickerUrl {
    final vehicleId = widget.vehicle['id'];
    for (final i in _inspections) {
      if (i['vehicle_id'] != vehicleId) continue;
      final path = i['sticker']?.toString();
      if (path != null && path.isNotEmpty) return '${ApiClient.webBaseUrl}$path';
    }
    return null;
  }

  /// Most recent insurance record for this vehicle, for its document photo.
  Map<String, dynamic>? get _insuranceForVehicle {
    final vehicleId = widget.vehicle['id'];
    final matches = _insurances.where((i) => i['vehicle_id'].toString() == vehicleId.toString());
    return matches.isEmpty ? null : matches.first;
  }

  List<_PhotoTile> get _tiles {
    final licenseUrl = _user?['license_image_url']?.toString();
    final vehicle = _vehicle ?? widget.vehicle;
    final regFrontUrl = vehicle['registration_front_url']?.toString();
    final regBackUrl = vehicle['registration_back_url']?.toString();
    final frontPhotoUrl = vehicle['front_photo_url']?.toString();
    final insuranceDocUrl = _insuranceForVehicle?['document_image_url']?.toString();
    return [
      _PhotoTile(label: 'ໃບຂັບຂີ', icon: Icons.badge_outlined, url: licenseUrl),
      _PhotoTile(
          label: 'ລົດ — ດ້ານໜ້າ', icon: Icons.directions_car_filled_outlined, url: frontPhotoUrl),
      _PhotoTile(label: 'ທະບຽນລົດ', icon: Icons.article_outlined, url: regFrontUrl),
      _PhotoTile(label: 'ປຶ້ມຄູ່ມືລົດ', icon: Icons.menu_book_outlined, url: regBackUrl),
      _PhotoTile(label: 'ສະຫຼາກກວດເຕັກນິກ', icon: Icons.fact_check_outlined, url: _inspectionStickerUrl),
      _PhotoTile(label: 'ໃບເສຍຄ່າທາງ', icon: Icons.receipt_long_outlined, url: _roadTaxProofUrl),
      _PhotoTile(label: 'ໃບປະກັນໄພ', icon: Icons.shield_outlined, url: insuranceDocUrl),
    ];
  }

  // View-only — no photo is ever uploaded from this screen, only viewed
  // full-screen if it already exists.
  void _openTile(_PhotoTile tile) {
    if (!tile.hasPhoto) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _PhotoViewerDialog(url: tile.url!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _tiles;
    final photoCount = tiles.where((t) => t.hasPhoto).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: 'ຮູບພາບເອກະສານ', actions: [
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
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
              children: [
                Showcase(
                  key: _tourKeyProgress,
                  title: 'ຄວາມຄືບໜ້າ',
                  description: 'ຕິດຕາມຈຳນວນຮູບເອກະສານທີ່ມີທຽບກັບທັງໝົດ',
                  targetBorderRadius: BorderRadius.circular(16),
                  child: _progressCard(photoCount, tiles.length),
                ),
                for (var i = 0; i < tiles.length; i += 2) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: i == 0
                            ? Showcase(
                                key: _tourKeyCard,
                                title: 'ບັດຮູບພາບ',
                                description: 'ກົດຮູບທີ່ມີເພື່ອເບິ່ງເຕັມໜ້າຈໍ',
                                targetBorderRadius: BorderRadius.circular(14),
                                tooltipActions: CoachMarkTour.lastStepActions(context),
                                child: _photoCard(tiles[i]),
                              )
                            : _photoCard(tiles[i])),
                    const SizedBox(width: 12),
                    Expanded(
                        child:
                            i + 1 < tiles.length ? _photoCard(tiles[i + 1]) : const SizedBox.shrink()),
                  ]),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Widget _progressCard(int filled, int total) {
    final plate = widget.vehicle['plate_number']?.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: total == 0 ? 0 : filled / total,
                strokeWidth: 5,
                backgroundColor: AppColors.grey100,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Center(
                child: Text('$filled/$total',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ມີຮູບແລ້ວ $filled ຈາກ $total',
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                  'ກົດຮູບເພື່ອເບິ່ງເຕັມໜ້າຈໍ'
                  '${plate?.isNotEmpty == true ? '  ·  ທະບຽນ: $plate' : ''}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey500, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _photoCard(_PhotoTile tile) {
    return GestureDetector(
      onTap: () => _openTile(tile),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryLight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(aspectRatio: 189 / 118, child: _thumb(tile)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(children: [
              Expanded(
                child: Text(tile.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              _statusTag(tile),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusTag(_PhotoTile tile) {
    if (tile.hasPhoto) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
        child: const Text('ມີ',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
      child: const Text('ບໍ່ມີ',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.grey500)),
    );
  }

  Widget _thumb(_PhotoTile tile) {
    if (!tile.hasPhoto) {
      return Container(
        color: AppColors.grey100,
        child: Center(
          child: Icon(tile.icon, color: AppColors.grey300, size: 30),
        ),
      );
    }
    return Image.network(
      tile.url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.grey100,
        child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.grey300, size: 28)),
      ),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              color: AppColors.grey100,
              child: const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
            ),
    );
  }
}

/// Full-screen pinch-to-zoom viewer for a single uploaded document photo.
class _PhotoViewerDialog extends StatelessWidget {
  const _PhotoViewerDialog({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(children: [
        InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ]),
    );
  }
}
