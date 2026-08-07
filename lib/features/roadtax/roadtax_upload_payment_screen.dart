import 'dart:io';
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

class RoadtaxUploadPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final int taxYear;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final File proofImage;
  const RoadtaxUploadPaymentScreen({
    super.key,
    required this.vehicle,
    required this.taxYear,
    this.paidAt,
    this.expiredAt,
    required this.proofImage,
  });
  @override
  State<RoadtaxUploadPaymentScreen> createState() => _RoadtaxUploadPaymentScreenState();
}

class _RoadtaxUploadPaymentScreenState extends State<RoadtaxUploadPaymentScreen> {
  static const _methods = [
    {'name': 'LAP NET', 'icon': Icons.account_balance},
    {'name': 'BCEL ONE', 'icon': Icons.account_balance},
    {'name': 'APB', 'icon': Icons.account_balance},
    {'name': 'LDB', 'icon': Icons.account_balance},
  ];

  bool _loading = true;
  String? _error;
  num _fee = 0;
  int _selectedMethod = -1;
  bool _submitting = false;

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
      final rates = await ApiRoadTaxService.rates();
      final setting = await ApiRoadTaxService.uploadFeeSetting();
      final rate = ApiRoadTaxService.matchingRate(rates, widget.vehicle);
      final baseAmount = num.tryParse(rate?['price']?.toString() ?? '') ?? 0;
      final fee = ApiRoadTaxService.computeUploadFee(setting, baseAmount);
      if (mounted) setState(() => _fee = fee);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is DioException ? ApiAuthService.errorMessage(e) : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pay() async {
    if (_submitting || _selectedMethod < 0) return;
    setState(() => _submitting = true);
    try {
      final vehicleId = int.parse(widget.vehicle['id'].toString());
      final created = await ApiRoadTaxService.uploadProof(
        vehicleId: vehicleId,
        taxYear: widget.taxYear,
        proofImage: widget.proofImage,
        paidAt: widget.paidAt != null ? _iso(widget.paidAt!) : null,
        expiredAt: widget.expiredAt != null ? _iso(widget.expiredAt!) : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/roadtax/success', (r) => false, arguments: {
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
      appBar: const MgHeader(title: 'ຊຳລະຄ່າທຳນຽມ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load)
              : Column(children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              MgPlateBadge(plateNumber: plate, province: province, plateType: plateType),
                              const SizedBox(width: 10),
                              Text('ປີ ${widget.taxYear}',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 4),
                            Text('ຄ່າທຳນຽມແພລດຟອມສຳລັບການບັນທຶກຫຼັກຖານ',
                                style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                            const SizedBox(height: 8),
                            Text('${_money.format(_fee)} ກີບ',
                                style: const TextStyle(
                                    color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        const RoadtaxStepIndicator(currentStep: 2),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = i),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.grey100, width: selected ? 1.6 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
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
            child: Text(m['name'] as String,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          ),
          Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.grey300, size: 20),
        ]),
      ),
    );
  }

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
