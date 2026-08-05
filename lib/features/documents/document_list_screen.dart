import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/api_inspection_service.dart';
import '../../core/services/api_insurance_service.dart';
import '../../core/services/api_road_tax_service.dart';
import '../../core/services/api_vehicle_service.dart';
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

  bool get _singleVehicleMode => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _load();
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

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('ກຳລັງພັດທະນາ')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: 'ເບິ່ງຂໍ້ມູນເອກະສານ', actions: [
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
                        const SizedBox(height: 12),
                      ],
                      for (final v in _sortedVehicles) ...[
                        _inspectionRow(v),
                        const SizedBox(height: 12),
                      ],
                      for (final v in _sortedVehicles) ...[
                        _roadTaxRow(v),
                        const SizedBox(height: 12),
                      ],
                      for (final v in _sortedVehicles) ...[
                        _insuranceRow(v),
                        const SizedBox(height: 12),
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
          bandLabel: 'DRIVER LICENSE',
          icon: Icons.person),
      title: 'ໃບຂັບຂີ່',
      line1: _user?['license_type'] != null ? 'CLASS: ${_user?['license_type']}' : '',
      line2: expiry != null ? 'ໝົດອາຍຸ: ${_formatDate(expiry)}' : 'ຍັງບໍ່ໄດ້ຕື່ມຂໍ້ມູນ',
      status: status,
      onTap: () => (imageUrl != null && imageUrl.isNotEmpty)
          ? _viewImage(imageUrl)
          : Navigator.of(context).pushNamed('/license/setup'),
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
    final status = record == null
        ? _DocStatus.missing
        : record['status']?.toString() == 'passed'
            ? _DocStatus.valid
            : record['status']?.toString() == 'failed'
                ? _DocStatus.expired
                : _DocStatus.missing;
    final plate = v['plate_number']?.toString();
    return _docRow(
      mock: _mockCard(
          bgColor: const Color(0xFF2AB659),
          bandColor: const Color(0xFF1A8C47),
          bandLabel: 'TECHNICAL INSPECTION',
          icon: Icons.fact_check_outlined),
      title: 'ກວດກາເຕັກນິກ',
      line1: 'ທະບຽນ: ${plate?.isNotEmpty == true ? plate! : '-'}',
      line2: record != null
          ? 'ວັນທີ: ${_formatDate(record['appointment_at']?.toString()) ?? '-'}'
          : 'ຍັງບໍ່ໄດ້ກວດກາ',
      status: status,
      onTap: () => Navigator.of(context).pushNamed('/vehicle/detail', arguments: v),
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
  }) {
    return GestureDetector(
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
            SizedBox(width: 108, child: mock),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: AppTextStyles.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
                    if (line1.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(line1, style: AppTextStyles.caption.copyWith(fontSize: 10.5)),
                    ],
                    if (line2.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(line2, style: AppTextStyles.caption.copyWith(fontSize: 10.5)),
                    ],
                    const SizedBox(height: 4),
                    Text('status: ${_statusLabel(status)}',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _statusColor(status))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(child: _statusIcon(status)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statusIcon(_DocStatus status) {
    final (bg, fg, icon) = switch (status) {
      _DocStatus.valid => (const Color(0xFFE0F7E9), const Color(0xFF009951), Icons.check),
      _DocStatus.expired => (const Color(0xFFFCE0E0), const Color(0xFFCC1010), Icons.close),
      _DocStatus.missing => (const Color(0xFFFEF3C7), const Color(0xFFCA8A04), Icons.priority_high),
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: 26),
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
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Text(bandLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: Center(
            child: bigText != null && bigText.isNotEmpty
                ? Text(bigText,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900))
                : Icon(icon ?? Icons.description_outlined, color: Colors.white.withValues(alpha: 0.9), size: 26),
          ),
        ),
      ]),
    );
  }

  Widget _qrBanner() => GestureDetector(
        onTap: _showComingSoon,
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
