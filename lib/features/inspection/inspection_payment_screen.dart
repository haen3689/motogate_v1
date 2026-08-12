import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_client.dart';
import '../../core/services/api_inspection_service.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import 'inspection_step_indicator.dart';

final _money = NumberFormat('#,##0');

class InspectionPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> center;
  final Map<String, dynamic> service;
  final DateTime appointmentAt;
  const InspectionPaymentScreen({
    super.key,
    required this.vehicle,
    required this.center,
    required this.service,
    required this.appointmentAt,
  });
  @override
  State<InspectionPaymentScreen> createState() => _InspectionPaymentScreenState();
}

class _InspectionPaymentScreenState extends State<InspectionPaymentScreen> {
  // Only BCEL ONE is actually wired to a live payment gateway (BCEL
  // OnePay). The rest stay listed so the choice looks familiar, but are
  // disabled until a real integration exists for them.
  static const _methods = [
    {'name': 'LAP NET', 'icon': Icons.account_balance, 'enabled': false},
    {'name': 'BCEL ONE', 'icon': Icons.account_balance, 'enabled': true},
    {'name': 'APB', 'icon': Icons.account_balance, 'enabled': false},
    {'name': 'LDB', 'icon': Icons.account_balance, 'enabled': false},
  ];

  int _selectedMethod = -1;
  bool _submitting = false;

  num get _price => num.tryParse(widget.service['price']?.toString() ?? '') ?? 0;

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _pay() async {
    if (_submitting || _selectedMethod < 0) return;
    setState(() => _submitting = true);
    try {
      final vehicleId = int.parse(widget.vehicle['id'].toString());
      final centerId = int.parse(widget.center['id'].toString());
      final created = await ApiInspectionService.create(
        vehicleId: vehicleId,
        inspectionCenterId: centerId,
        appointmentAt: widget.appointmentAt.toIso8601String(),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed('/inspection/qr_payment', arguments: {
        'inspection': created,
        'vehicle': widget.vehicle,
        'center': widget.center,
        'service': widget.service,
        'appointmentAt': widget.appointmentAt,
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? ApiAuthService.errorMessage(e)
          : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoPath = widget.center['logo']?.toString();
    final logoUrl =
        logoPath != null && logoPath.isNotEmpty ? '${ApiClient.webBaseUrl}$logoPath' : null;
    final plate = widget.vehicle['plate_number']?.toString() ?? '—';
    final province = widget.vehicle['province']?.toString();
    final plateType = widget.vehicle['plate_type']?.toString();
    final brandModel = [widget.vehicle['brand'], widget.vehicle['model']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ຊຳລະຄ່າກວດສະພາບລົດ'),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary, width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: logoUrl != null
                        ? Image.network(logoUrl,
                            fit: BoxFit.cover, errorBuilder: (_, __, ___) => _logoFallback())
                        : _logoFallback(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.center['name']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall
                              .copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(brandModel.isEmpty ? plate : '$plate · $brandModel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              const InspectionStepIndicator(currentStep: 2),
              const SizedBox(height: 24),
              Text('ສະຫຼຸບການຈອງ',
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.grey100),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                      child: Text(widget.service['name']?.toString() ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    MgPlateBadge(plateNumber: plate, province: province, plateType: plateType),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.grey100, height: 1),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('ວັນ ແລະ ເວລານັດໝາຍ', style: AppTextStyles.bodySmall),
                    Text(_fmtDateTime(widget.appointmentAt),
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.grey100, height: 1),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('ຍອດຊຳລະທັງໝົດ', style: AppTextStyles.bodySmall),
                    Text('${_money.format(_price)} ກີບ',
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              Text('ວິທີການຊຳລະເງິນ',
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (var i = 0; i < _methods.length; i++) ...[
                _methodTile(i),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: MgButton(
              label: 'ຊຳລະເງິນ',
              isLoading: _submitting,
              variant: _selectedMethod >= 0 ? MgButtonVariant.primary : MgButtonVariant.disabled,
              onPressed: _selectedMethod < 0 ? null : _pay,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _methodTile(int i) {
    final selected = _selectedMethod == i;
    final m = _methods[i];
    final enabled = m['enabled'] as bool;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => setState(() => _selectedMethod = i) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : Colors.white,
            border: Border.all(color: selected ? AppColors.primary : AppColors.grey100, width: selected ? 1.6 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            m['name'] == 'BCEL ONE'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/bcel_one.png', width: 38, height: 38, fit: BoxFit.cover),
                  )
                : Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(m['icon'] as IconData, color: AppColors.primary, size: 20),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['name'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                if (!enabled)
                  Text('ຍັງບໍ່ຮອງຮັບ', style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
              ]),
            ),
            if (enabled)
              Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.grey300, size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _logoFallback() => Container(
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 20),
      );
}
