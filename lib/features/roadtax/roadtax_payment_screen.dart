import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_road_tax_service.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import 'roadtax_step_indicator.dart';

final _money = NumberFormat('#,##0');

class RoadtaxPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final int taxYear;
  final num amount;
  const RoadtaxPaymentScreen({
    super.key,
    required this.vehicle,
    required this.taxYear,
    required this.amount,
  });
  @override
  State<RoadtaxPaymentScreen> createState() => _RoadtaxPaymentScreenState();
}

class _RoadtaxPaymentScreenState extends State<RoadtaxPaymentScreen> {
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

  Future<void> _pay() async {
    if (_submitting || _selectedMethod < 0) return;
    setState(() => _submitting = true);
    try {
      final vehicleId = int.parse(widget.vehicle['id'].toString());
      final created = await ApiRoadTaxService.create(
        vehicleId: vehicleId,
        taxYear: widget.taxYear,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed('/roadtax/qr_payment', arguments: {
        'roadTax': created,
        'vehicle': widget.vehicle,
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
    final plate = widget.vehicle['plate_number']?.toString() ?? '—';
    final province = widget.vehicle['province']?.toString();
    final plateType = widget.vehicle['plate_type']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ຊຳລະຄ່າທາງ'),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  MgPlateBadge(plateNumber: plate, province: province, plateType: plateType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('ຄ່າທາງປີ ${widget.taxYear}',
                        style: AppTextStyles.bodySmall),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              const RoadtaxStepIndicator(currentStep: 2, labels: ['ເລືອກປີ', 'ຢືນຢັນ', 'ຊຳລະເງິນ']),
              const SizedBox(height: 24),
              Text('ສະຫຼຸບຍອດຊຳລະ',
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
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('ຍອດຊຳລະທັງໝົດ', style: AppTextStyles.bodySmall),
                  Text('${_money.format(widget.amount)} ກີບ',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)),
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
}
