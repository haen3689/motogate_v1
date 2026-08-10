import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/api_client.dart';
import '../../core/services/api_inspection_service.dart';
import '../../core/services/api_insurance_service.dart';
import '../../core/services/api_road_tax_service.dart';
import '../../core/services/api_vehicle_service.dart';
import '../../core/services/coach_mark_tour.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

enum _DocStatus { valid, expired, missing }

class DocumentListScreen extends StatefulWidget {
  /// When provided, the screen is scoped to just this single vehicle
  /// (e.g. reached from the fee-paid vehicle picker) instead of aggregating
  /// documents across all of the user's vehicles.
  final Map<String, dynamic>? vehicle;

  const DocumentListScreen({super.key, this.vehicle});
  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _roadTaxes = [];
  List<Map<String, dynamic>> _inspections = [];
  List<Map<String, dynamic>> _insurances = [];
  bool _loading = true;
  String? _error;

  static const _tourSeenPrefKey = 'documents_tour_seen';
  final _tourKeyCard = GlobalKey();
  final _tourKeyStatus = GlobalKey();
  final _tourKeyQr = GlobalKey();

  bool get _singleVehicleMode => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _maybeStartTour() =>
      CoachMarkTour.maybeStart(prefKey: _tourSeenPrefKey, start: _startTour);

  void _startTour() {
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase([_tourKeyCard, _tourKeyStatus, _tourKeyQr]);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_singleVehicleMode) {
        final results = await Future.wait([
          ApiAuthService.me(),
          ApiRoadTaxService.list(),
          ApiInspectionService.list(),
          ApiInsuranceService.myInsurances(),
        ]);
        if (mounted) {
          setState(() {
            _user = results[0] as Map<String, dynamic>;
            _vehicles = [widget.vehicle!];
            _roadTaxes = (results[1] as List).cast<Map<String, dynamic>>();
            _inspections = (results[2] as List).cast<Map<String, dynamic>>();
            _insurances = (results[3] as List).cast<Map<String, dynamic>>();
          });
        }
      } else {
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
            _vehicles = (results[1] as List).cast<Map<String, dynamic>>();
            _roadTaxes = (results[2] as List).cast<Map<String, dynamic>>();
            _inspections = (results[3] as List).cast<Map<String, dynamic>>();
            _insurances = (results[4] as List).cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is DioException
            ? ApiAuthService.errorMessage(e)
            : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (_error == null) _maybeStartTour();
  }

  List<Map<String, dynamic>> get _sortedVehicles {
    if (_singleVehicleMode) return _vehicles;
    final list = [..._vehicles];
    list.sort((a, b) =>
        (a['plate_number']?.toString() ?? '').compareTo(b['plate_number']?.toString() ?? ''));
    return list;
  }

  /// Most recent record of [records] belonging to vehicle [vehicleId].
  Map<String, dynamic>? _latestFor(List<Map<String, dynamic>> records, dynamic vehicleId,
      {String dateKey = 'created_at'}) {
    final matches =
        records.where((r) => r['vehicle_id'].toString() == vehicleId.toString()).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final da = DateTime.tryParse(a[dateKey]?.toString() ?? '') ?? DateTime(1970);
      final db = DateTime.tryParse(b[dateKey]?.toString() ?? '') ?? DateTime(1970);
      return db.compareTo(da);
    });
    return matches.first;
  }

  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  _DocStatus _statusFromExpiry(String? expiryIso) {
    if (expiryIso == null || expiryIso.isEmpty) return _DocStatus.missing;
    final d = DateTime.tryParse(expiryIso);
    if (d == null) return _DocStatus.missing;
    return d.isBefore(DateTime.now()) ? _DocStatus.expired : _DocStatus.valid;
  }

  String _statusLabel(_DocStatus s) => switch (s) {
        _DocStatus.valid => 'ຢືນຢັນ',
        _DocStatus.expired => 'ໝົດອາຍຸ',
        _DocStatus.missing => 'ຍັງບໍ່ມີຂໍ້ມູນ',
      };

  Color _statusColor(_DocStatus s) => switch (s) {
        _DocStatus.valid => const Color(0xFF009951),
        _DocStatus.expired => const Color(0xFFCC1010),
        _DocStatus.missing => const Color(0xFFCA8A04),
      };

  void _viewImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
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
      ),
    );
  }

  /// Requests a fresh short-lived, signed verification link from the
  /// backend and shows it as a QR. Because the token is signed and
  /// expires server-side (not just hidden client-side), a screenshotted
  /// QR stops working on its own — reusing it isn't a matter of the app
  /// UI, the backend itself will reject it after expiry.
  Future<void> _showMyQrCode() async {
    if (_sortedVehicles.isEmpty && _user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ຍັງບໍ່ມີຂໍ້ມູນພຽງພໍ ກະລຸນາລອງໃໝ່')));
      return;
    }
    Map<String, dynamic> tokenData;
    try {
      tokenData = await ApiAuthService.requestVerifyToken(vehicleId: widget.vehicle?['id']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is DioException
                ? ApiAuthService.errorMessage(e)
                : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່')));
      }
      return;
    }
    if (!mounted) return;

    final token = tokenData['token'] as String;
    final expiresAt = DateTime.parse(tokenData['expires_at'] as String);
    final url = '${ApiClient.webBaseUrl}/verify/$token';

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _QrCodeDialog(
        url: url,
        expiresAt: expiresAt,
        phone: _user?['phone_number']?.toString() ?? '',
        plate: widget.vehicle?['plate_number']?.toString(),
        onRegenerate: _showMyQrCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: 'ເບິ່ງຂໍ້ມູນເອກະສານ', actions: [
        GestureDetector(
          onTap: _startTour,
          child: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: AppColors.white, size: 20),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/vehicles'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(children: [
              Icon(Icons.directions_car_outlined, color: AppColors.white, size: 16),
              SizedBox(width: 4),
              Text('ດູຕາມລົດ',
                  style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const SizedBox(width: 4),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                    children: [
                      _licenseRow(),
                      const SizedBox(height: 12),
                      for (final v in _sortedVehicles) ...[
                        _vehicleRegRow(v),
                        const SizedBox(height: 14),
                      ],
                      for (final v in _sortedVehicles) ...[
                        _inspectionRow(v),
                        const SizedBox(height: 14),
                      ],
                      for (final v in _sortedVehicles) ...[
                        _roadTaxRow(v),
                        const SizedBox(height: 14),
                      ],
                      for (final v in _sortedVehicles) ...[
                        _insuranceRow(v),
                        const SizedBox(height: 14),
                      ],
                      if (_vehicles.isEmpty) _emptyVehicles(),
                      const SizedBox(height: 10),
                      _qrBanner(),
                    ],
                  ),
                ),
    );
  }

  // ── Rows ──────────────────────────────────────────────────────────────────

  Widget _licenseRow() {
    final expiry = _user?['license_expiry_date']?.toString();
    final status = _statusFromExpiry(expiry);
    final imageUrl = _user?['license_image_url']?.toString();
    return _docRow(
      mock: _mockCard(
          bgColor: const Color(0xFF0F5A96),
          bandColor: const Color(0xFF0A3C6C),
          bandLabel: 'ໃບຂັບຂີ່',
          icon: Icons.person),
      title: 'ໃບຂັບຂີ່',
      line1: _user?['license_type'] != null ? 'ປະເພດ: ${_user?['license_type']}' : '',
      line2: expiry != null ? 'ໝົດອາຍຸ: ${_formatDate(expiry)}' : 'ຍັງບໍ່ໄດ້ຕື່ມຂໍ້ມູນ',
      status: status,
      onTap: () => (imageUrl != null && imageUrl.isNotEmpty)
          ? _viewImage(imageUrl)
          : Navigator.of(context).pushNamed('/license/setup'),
      cardTourKey: _tourKeyCard,
      cardTourTitle: 'ບັດເອກະສານ',
      cardTourDescription: 'ແຕ່ລະບັດແມ່ນເອກະສານໜຶ່ງປະເພດ — ກົດເພື່ອເບິ່ງຮູບ ຫຼື ຕື່ມຂໍ້ມູນທີ່ຍັງຂາດ',
      statusTourKey: _tourKeyStatus,
      statusTourTitle: 'ສະຖານະເອກະສານ',
      statusTourDescription: '✓ ສີຂຽວ = ຖືກຕ້ອງ, ✕ ສີແດງ = ໝົດອາຍຸ, ! ສີເຫຼືອງ = ຍັງບໍ່ມີຂໍ້ມູນ',
    );
  }

  Widget _vehicleRegRow(Map<String, dynamic> v) {
    final plate = v['plate_number']?.toString();
    final frontUrl = v['registration_front_url']?.toString();
    final backUrl = v['registration_back_url']?.toString();
    final hasDocs = (frontUrl?.isNotEmpty ?? false) || (backUrl?.isNotEmpty ?? false);
    return _docRow(
      mock: _mockCard(
          bgColor: const Color(0xFFC7DEEB),
          bandColor: const Color(0xFF5C8BAE),
          bandLabel: 'ໃບທະບຽນລົດ',
          icon: Icons.directions_car),
      title: 'ທະບຽນລົດ',
      line1: 'ທະບຽນ: ${plate?.isNotEmpty == true ? plate! : '-'}',
      line2: hasDocs ? '' : 'ຍັງບໍ່ໄດ້ຕື່ມຂໍ້ມູນ',
      status: hasDocs ? _DocStatus.valid : _DocStatus.missing,
      onTap: () => Navigator.of(context).pushNamed('/vehicle/detail', arguments: v),
    );
  }

  Widget _inspectionRow(Map<String, dynamic> v) {
    final record = _latestFor(_inspections, v['id']);
    final recordStatus = record?['status']?.toString();
    final status = recordStatus == 'completed'
        ? _DocStatus.valid
        : recordStatus == 'cancelled'
            ? _DocStatus.expired
            : _DocStatus.missing;
    final plate = v['plate_number']?.toString();
    final stickerPath = record?['sticker']?.toString();
    final stickerUrl =
        stickerPath != null && stickerPath.isNotEmpty ? '${ApiClient.webBaseUrl}$stickerPath' : null;
    final appointmentText = 'ວັນທີ: ${_formatDate(record?['appointment_at']?.toString()) ?? '-'}';
    return _docRow(
      mock: _mockCard(
          bgColor: const Color(0xFF2AB659),
          bandColor: const Color(0xFF1A8C47),
          bandLabel: 'ກວດກາເຕັກນິກ',
          icon: Icons.fact_check_outlined),
      title: 'ກວດກາເຕັກນິກ',
      line1: 'ທະບຽນ: ${plate?.isNotEmpty == true ? plate! : '-'}',
      line2: record == null
          ? 'ຍັງບໍ່ໄດ້ກວດກາ'
          : stickerUrl != null
              ? '$appointmentText · ກົດເບິ່ງສະຕິກເກີ້'
              : appointmentText,
      status: status,
      onTap: () => stickerUrl != null
          ? _viewImage(stickerUrl)
          : Navigator.of(context).pushNamed('/vehicle/detail', arguments: v),
    );
  }

  Widget _roadTaxRow(Map<String, dynamic> v) {
    final record = _latestFor(_roadTaxes, v['id']);
    final expiry = record?['expired_at']?.toString();
    final status = _statusFromExpiry(expiry);
    final plate = v['plate_number']?.toString();
    return _docRow(
      mock: _mockCard(
          bgColor: const Color(0xFF0F9B8E),
          bandColor: const Color(0xFF0A7E72),
          bandLabel: 'ຄ່າທາງ',
          bigText: record?['tax_year']?.toString()),
      title: 'ຄ່າທາງ',
      line1: 'ທະບຽນ: ${plate?.isNotEmpty == true ? plate! : '-'}',
      line2: expiry != null ? 'ໝົດອາຍຸ: ${_formatDate(expiry)}' : 'ຍັງບໍ່ໄດ້ຈ່າຍຄ່າທາງ',
      status: status,
      onTap: () => Navigator.of(context).pushNamed('/vehicle/detail', arguments: v),
    );
  }

  Widget _insuranceRow(Map<String, dynamic> v) {
    final record = _latestFor(_insurances, v['id'], dateKey: 'start_date');
    final expiry = record?['end_date']?.toString();
    final status = _statusFromExpiry(expiry);
    final plate = v['plate_number']?.toString();
    return _docRow(
      mock: _mockCard(
          bgColor: const Color(0xFF0F5A96),
          bandColor: const Color(0xFF0A3C6C),
          bandLabel: (record?['company']?.toString() ?? 'ປະກັນໄພ').toUpperCase(),
          icon: Icons.shield_outlined),
      title: 'ປະກັນໄພ',
      line1: 'ທະບຽນ: ${plate?.isNotEmpty == true ? plate! : '-'}',
      line2: expiry != null ? 'ໝົດອາຍຸ: ${_formatDate(expiry)}' : 'ຍັງບໍ່ມີປະກັນໄພ',
      status: status,
      onTap: () => Navigator.of(context).pushNamed('/vehicle/detail', arguments: v),
    );
  }

  // ── Building blocks ───────────────────────────────────────────────────────

  Widget _docRow({
    required Widget mock,
    required String title,
    required String line1,
    required String line2,
    required _DocStatus status,
    required VoidCallback onTap,
    GlobalKey? cardTourKey,
    String? cardTourTitle,
    String? cardTourDescription,
    GlobalKey? statusTourKey,
    String? statusTourTitle,
    String? statusTourDescription,
  }) {
    final statusWidget = _statusIcon(status);
    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: 140, child: mock),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: AppTextStyles.titleSmall.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                    if (line1.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(line1, style: AppTextStyles.caption.copyWith(fontSize: 13.5)),
                    ],
                    if (line2.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(line2, style: AppTextStyles.caption.copyWith(fontSize: 13.5)),
                    ],
                    const SizedBox(height: 7),
                    Text('status: ${_statusLabel(status)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _statusColor(status))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: statusTourKey == null
                    ? statusWidget
                    : Showcase(
                        key: statusTourKey,
                        title: statusTourTitle ?? '',
                        description: statusTourDescription ?? '',
                        targetShapeBorder: const CircleBorder(),
                        child: statusWidget,
                      ),
              ),
            ),
          ]),
        ),
      ),
    );

    return cardTourKey == null
        ? card
        : Showcase(
            key: cardTourKey,
            title: cardTourTitle ?? '',
            description: cardTourDescription ?? '',
            targetBorderRadius: BorderRadius.circular(16),
            child: card,
          );
  }

  Widget _statusIcon(_DocStatus status) {
    final (bg, fg, icon) = switch (status) {
      _DocStatus.valid => (const Color(0xFFE0F7E9), const Color(0xFF009951), Icons.check),
      _DocStatus.expired => (const Color(0xFFFCE0E0), const Color(0xFFCC1010), Icons.close),
      _DocStatus.missing => (const Color(0xFFFEF3C7), const Color(0xFFCA8A04), Icons.priority_high),
    };
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: 32),
    );
  }

  /// Small colored "document type" mockup card (not a real photo) — a quick
  /// visual identifier per category, matching the Figma reference's color
  /// story without needing the user's actual uploaded scan.
  Widget _mockCard({
    required Color bgColor,
    required Color bandColor,
    required String bandLabel,
    IconData? icon,
    String? bigText,
  }) {
    return Container(
      color: bgColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: bandColor,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          child: Text(bandLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: Center(
            child: bigText != null && bigText.isNotEmpty
                ? Text(bigText,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))
                : Icon(icon ?? Icons.description_outlined, color: Colors.white.withValues(alpha: 0.9), size: 36),
          ),
        ),
      ]),
    );
  }

  Widget _qrBanner() => Showcase(
        key: _tourKeyQr,
        title: 'QR CODE ເອກະສານ',
        description: 'ໃຫ້ເຈົ້າໜ້າທີ່ສະແກນ QR ນີ້ເພື່ອກວດສອບເອກະສານທັງໝົດຂອງທ່ານ ໂດຍບໍ່ຕ້ອງເປີດເອກະສານເອງ',
        targetBorderRadius: BorderRadius.circular(20),
        tooltipActions: CoachMarkTour.lastStepActions(context),
        child: GestureDetector(
          onTap: _showMyQrCode,
          child: Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.qr_code_2, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('QR CODE ເອກະສານ',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('ສະແກນເພື່ອກວດສອບເອກະສານທັງໝົດ',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 24),
            ]),
          ),
        ),
      );

  Widget _emptyVehicles() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          const Icon(Icons.directions_car_outlined, color: AppColors.grey300, size: 36),
          const SizedBox(height: 10),
          const Text('ຍັງບໍ່ມີລົດໃນລະບົບ', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          MgButton(
              label: 'ເພີ່ມລົດ',
              icon: Icons.add,
              onPressed: () => Navigator.of(context).pushNamed('/vehicle/add')),
        ]),
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

/// Shows the backend-issued QR with a live countdown to its server-side
/// expiry. When time runs out the QR is visually blocked and swapped for
/// a "generate new one" prompt instead of just sitting there scannable.
class _QrCodeDialog extends StatefulWidget {
  const _QrCodeDialog({
    required this.url,
    required this.expiresAt,
    required this.phone,
    this.plate,
    required this.onRegenerate,
  });

  final String url;
  final DateTime expiresAt;
  final String phone;
  final String? plate;
  final Future<void> Function() onRegenerate;

  @override
  State<_QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<_QrCodeDialog> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = widget.expiresAt.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _remaining = remaining.isNegative ? Duration.zero : remaining);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _mmss {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == Duration.zero;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.qr_code_2, color: AppColors.primary, size: 30),
          const SizedBox(height: 8),
          Text('QR CODE ເອກະສານ',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('ສະແດງໃຫ້ເຈົ້າໜ້າທີ່ສະແກນເພື່ອກວດສອບເອກະສານ',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
          const SizedBox(height: 20),
          Stack(alignment: Alignment.center, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey100),
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: widget.url,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A1A1A)),
                dataModuleStyle:
                    const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1A1A)),
              ),
            ),
            if (expired)
              Container(
                width: 252,
                height: 252,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_off_outlined, color: AppColors.grey500, size: 32),
                    SizedBox(height: 8),
                    Text('QR ໝົດອາຍຸແລ້ວ',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                  ],
                ),
              ),
          ]),
          const SizedBox(height: 16),
          if (!expired)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('ໝົດອາຍຸໃນ $_mmss',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
            ])
          else
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await widget.onRegenerate();
              },
              child: const Text('ສ້າງ QR ໃໝ່',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 12),
          Text(widget.phone, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
          if (widget.plate?.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Text('ທະບຽນ: ${widget.plate}',
                style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: MgButton(label: 'ປິດ', onPressed: () => Navigator.of(context).pop()),
          ),
        ]),
      ),
    );
  }
}
