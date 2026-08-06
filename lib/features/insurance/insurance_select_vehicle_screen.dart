import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_vehicle_service.dart';
import '../../core/services/api_insurance_service.dart';
import '../../core/services/api_auth_service.dart';
import 'insurance_step_indicator.dart';

class InsuranceSelectVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  const InsuranceSelectVehicleScreen({super.key, required this.company});
  @override
  State<InsuranceSelectVehicleScreen> createState() => _InsuranceSelectVehicleScreenState();
}

class _InsuranceSelectVehicleScreenState extends State<InsuranceSelectVehicleScreen> {
  List<Map<String, dynamic>> _paidVehicles = [];
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _selected;

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
      final list = await ApiVehicleService.list();
      final paid = list.where((v) => v['fee_paid'] == true).toList();
      if (mounted) setState(() => _paidVehicles = paid);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is DioException ? ApiAuthService.errorMessage(e) : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _typeLabel(String? type) => switch (type) {
        'motorcycle' => 'ລົດຈັກ',
        'car' => 'ລົດເກັ່ງ',
        'pickup' => 'ລົດກະບະ',
        'suv' => 'ລົດຈິບ',
        'van' => 'ລົດຕູ້',
        'bus' => 'ລົດເມ',
        'towtruck' => 'ລົດລາກ',
        'trailer' => 'ລົດພ່ວງ',
        _ => 'ລົດເກັ່ງ',
      };

  Future<void> _openPicker() async {
    if (_paidVehicles.isEmpty) return;
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => _VehiclePickerSheet(
        vehicles: _paidVehicles,
        selectedId: _selected?['id'],
        typeLabel: _typeLabel,
      ),
    );
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  void _next() {
    if (_selected == null) return;
    final packages = ApiInsuranceService.matchingPackages(
        (widget.company['insurance_packages'] as List?) ?? [], _selected!);
    if (packages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ບໍລິສັດນີ້ບໍ່ມີແພັກເກັດທີ່ເໝາະສົມກັບລົດຄັນນີ້'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    Navigator.of(context).pushNamed('/insurance/packages', arguments: {
      'vehicle': _selected,
      'company': widget.company,
      'packages': packages,
    });
  }

  @override
  Widget build(BuildContext context) {
    final logoPath = widget.company['logo']?.toString();
    final logoUrl =
        logoPath != null && logoPath.isNotEmpty ? '${ApiClient.webBaseUrl}$logoPath' : null;
    final companyName = widget.company['name']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ປະກັນໄພພາຫະນະ'),
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
                                Text('ບໍລິສັດປະກັນໄພ',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                                const SizedBox(height: 1),
                                Text(companyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleSmall
                                        .copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
                              ]),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text('ປ່ຽນ',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        const InsuranceStepIndicator(currentStep: 0),
                        const SizedBox(height: 24),
                        Text('ເລືອກພາຫະນະ',
                            style: AppTextStyles.titleSmall
                                .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('ເລືອກຈາກລົດທີ່ຊຳລະຄ່າທຳນຽມແລ້ວ',
                            style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                        const SizedBox(height: 12),
                        if (_paidVehicles.isEmpty) _noPaidVehicles() else _vehiclePickerRow(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: MgButton(
                        label: 'ຖັດໄປ → ເລືອກແພັກເກັດ',
                        variant: _selected != null ? MgButtonVariant.primary : MgButtonVariant.disabled,
                        onPressed: _selected == null ? null : _next,
                      ),
                    ),
                  ),
                ]),
    );
  }

  Widget _vehiclePickerRow() {
    final selected = _selected;
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected != null ? AppColors.primarySurface : Colors.white,
          border: Border.all(
              color: selected != null ? AppColors.primary : AppColors.grey100,
              width: selected != null ? 1.6 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: selected == null ? _emptyRowContent() : _selectedRowContent(selected),
      ),
    );
  }

  Widget _emptyRowContent() => Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ກົດເພື່ອເລືອກລົດ',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('ຈາກລົດທີ່ຊຳລະຄ່າທຳນຽມແລ້ວ', style: AppTextStyles.caption),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.grey300, size: 22),
      ]);

  Widget _selectedRowContent(Map<String, dynamic> v) {
    final brandModel = [v['brand'], v['model']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    final cc = v['cc']?.toString() ?? '';
    final type = _typeLabel(v['vehicle_type']?.toString());
    final province = v['province']?.toString();
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (province != null && province.isNotEmpty)
            Text(province,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          Text(v['plate_number']?.toString() ?? '—',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
            '${brandModel.isEmpty ? type : '$brandModel · $type'}${cc.isNotEmpty ? ' ${cc}CC' : ''}',
            style: AppTextStyles.bodySmall),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.swap_horiz, color: AppColors.primary, size: 13),
          SizedBox(width: 3),
          Text('ປ່ຽນ',
              style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    ]);
  }

  Widget _noPaidVehicles() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(children: [
          Icon(Icons.directions_car_outlined, color: AppColors.grey300, size: 36),
          SizedBox(height: 12),
          Text('ຍັງບໍ່ມີລົດທີ່ຊຳລະຄ່າທຳນຽມແລ້ວ',
              style: AppTextStyles.titleSmall, textAlign: TextAlign.center),
          SizedBox(height: 6),
          Text('ກະລຸນາຊຳລະຄ່າທຳນຽມລົງທະບຽນລົດຂອງທ່ານກ່ອນ ຈຶ່ງຈະສາມາດຊື້ປະກັນໄພໄດ້',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ]),
      );

  Widget _logoFallback() => Container(
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
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

class _VehiclePickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> vehicles;
  final dynamic selectedId;
  final String Function(String?) typeLabel;
  const _VehiclePickerSheet({required this.vehicles, required this.selectedId, required this.typeLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Text('ລົດທີ່ຊຳລະຄ່າທຳນຽມແລ້ວ',
              style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('ທັງໝົດ ${vehicles.length} ຄັນ · ກົດເລືອກລົດທີ່ຕ້ອງການທຳປະກັນໄພ', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final v = vehicles[i];
                final brand = v['brand']?.toString() ?? '';
                final model = v['model']?.toString() ?? '';
                final cc = v['cc']?.toString() ?? '';
                final year = v['year']?.toString() ?? '';
                final province = v['province']?.toString();
                final isSelected = selectedId != null && v['id'] == selectedId;
                final metaParts = [
                  typeLabel(v['vehicle_type']?.toString()),
                  if (cc.isNotEmpty) '${cc}CC',
                  if (year.isNotEmpty) 'ປີ $year',
                ];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(v),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primarySurface : Colors.white,
                      border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.grey100,
                          width: isSelected ? 1.6 : 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          border: Border.all(color: AppColors.black, width: 1.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          if (province != null && province.isNotEmpty)
                            Text(province,
                                style: const TextStyle(
                                    color: AppColors.black, fontSize: 10, fontWeight: FontWeight.w700)),
                          Text(v['plate_number']?.toString() ?? '—',
                              style: const TextStyle(
                                  color: AppColors.black, fontSize: 13, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text([brand, model].where((s) => s.isNotEmpty).join(' '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(metaParts.join(' · '), style: AppTextStyles.caption),
                        ]),
                      ),
                      Icon(isSelected ? Icons.check_circle : Icons.chevron_right,
                          color: isSelected ? AppColors.primary : AppColors.grey300),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
