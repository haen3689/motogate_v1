import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_payment_service.dart';
import '../../core/services/api_inspection_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

final _money = NumberFormat('#,##0');

/// Shows the BCEL OnePay QR / one-click-pay deeplink for a pending
/// Inspection booking payment, and polls the payment status until BCEL
/// confirms it (or it expires). Mirrors RoadtaxQrPaymentScreen.
class InspectionQrPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> center;
  final Map<String, dynamic> service;
  final DateTime appointmentAt;
  final Map<String, dynamic> inspection;
  const InspectionQrPaymentScreen({
    super.key,
    required this.vehicle,
    required this.center,
    required this.service,
    required this.appointmentAt,
    required this.inspection,
  });

  @override
  State<InspectionQrPaymentScreen> createState() => _InspectionQrPaymentScreenState();
}

class _InspectionQrPaymentScreenState extends State<InspectionQrPaymentScreen> with WidgetsBindingObserver {
  late Map<String, dynamic> _inspection = widget.inspection;
  late Map<String, dynamic> _payment = (widget.inspection['payment'] as Map).cast<String, dynamic>();

  Timer? _pollTimer;
  Timer? _tickTimer;
  Duration _remaining = Duration.zero;
  bool _retrying = false;
  bool _paid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateRemaining();
    _startPolling();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  // The app backgrounds while BCELOne handles the payment (deeplink) — per
  // BCEL's own integration guide, on resume we must explicitly re-check
  // status rather than rely solely on the periodic timer, since Android
  // can suspend timers while backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkStatus();
  }

  void _updateRemaining() {
    final expiresAt = DateTime.tryParse(_payment['expires_at']?.toString() ?? '');
    if (expiresAt == null) return;
    final left = expiresAt.difference(DateTime.now());
    if (mounted) setState(() => _remaining = left.isNegative ? Duration.zero : left);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final uuid = _payment['uuid']?.toString();
    if (uuid == null || _paid) return;
    try {
      final result = await ApiPaymentService.show(uuid);
      if (!mounted) return;
      setState(() => _payment = result);
      if (result['status'] == 'paid') {
        _paid = true;
        _pollTimer?.cancel();
        _tickTimer?.cancel();
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/inspection/success', (r) => false, arguments: {
          'inspection': {..._inspection, 'status': 'confirmed'},
          'vehicle': widget.vehicle,
          'center': widget.center,
          'service': widget.service,
        });
      }
    } catch (_) {
      // Transient network error — next poll tick will retry.
    }
  }

  Future<void> _openBcelOne() async {
    final deeplink = _payment['deeplink']?.toString();
    if (deeplink == null) return;
    try {
      final uri = Uri.parse(deeplink);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _showAppNotFound();
    } catch (_) {
      if (mounted) _showAppNotFound();
    }
  }

  void _showAppNotFound() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('ບໍ່ພົບແອບ BCEL One, ກະລຸນາສະແກນ QR ແທນ'),
      backgroundColor: Colors.red,
    ));
  }

  bool get _isExpired => !_paid && _remaining == Duration.zero && _payment['status'] == 'pending';

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      final vehicleId = int.parse(widget.vehicle['id'].toString());
      final centerId = int.parse(widget.center['id'].toString());
      final created = await ApiInspectionService.create(
        vehicleId: vehicleId,
        inspectionCenterId: centerId,
        appointmentAt: widget.appointmentAt.toIso8601String(),
      );
      if (!mounted) return;
      setState(() {
        _inspection = created;
        _payment = (created['payment'] as Map).cast<String, dynamic>();
        _paid = false;
      });
      _updateRemaining();
      _startPolling();
      _tickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  String get _remainingLabel {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final amount = num.tryParse(_payment['amount']?.toString() ?? '') ?? 0;
    final qrCode = _payment['qr_code']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ສະແກນຈ່າຍ BCEL One'),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.grey100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('ຍອດຊຳລະ', style: AppTextStyles.bodySmall),
              Text('${_money.format(amount)} ກີບ',
                  style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 20),
          if (_isExpired)
            _expiredCard()
          else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.grey100),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: qrCode != null
                    ? QrImageView(
                        data: qrCode,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      )
                    : const SizedBox(width: 220, height: 220, child: Center(child: CircularProgressIndicator())),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text('ໝົດອາຍຸໃນ $_remainingLabel ນາທີ',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: MgButton(
                label: 'ຈ່າຍດ້ວຍແອບ BCEL One (ຄລິກດຽວ)',
                onPressed: _openBcelOne,
              ),
            ),
            const SizedBox(height: 14),
            const Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Expanded(
                child: Text('ກຳລັງລໍຖ້າການຊຳລະເງິນ...', style: AppTextStyles.bodySmall),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _expiredCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.grey100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        const Icon(Icons.timer_off_outlined, color: AppColors.grey300, size: 40),
        const SizedBox(height: 12),
        const Text('QR ນີ້ໝົດອາຍຸແລ້ວ', style: AppTextStyles.titleSmall),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: MgButton(label: 'ສ້າງ QR ໃໝ່', isLoading: _retrying, onPressed: _retry),
        ),
      ]),
    );
  }
}
