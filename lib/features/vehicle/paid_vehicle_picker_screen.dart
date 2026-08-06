import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/services/api_auth_service.dart';
import '../../core/services/api_vehicle_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

/// Lets the user pick one of their fee-paid (fully active/registered)
/// vehicles, then navigates to [targetRoute] (Documents or Photos) scoped
/// to just that vehicle.
class PaidVehiclePickerScreen extends StatefulWidget {
  const PaidVehiclePickerScreen({
    super.key,
    this.title = 'ເລືອກລົດເບິ່ງເອກະສານ',
    this.targetRoute = '/documents',
  });

  final String title;
  final String targetRoute;

  @override
  State<PaidVehiclePickerScreen> createState() => _PaidVehiclePickerScreenState();
}

class _PaidVehiclePickerScreenState extends State<PaidVehiclePickerScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String? _error;

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
      if (mounted) setState(() => _vehicles = paid);
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

  void _openTarget(Map<String, dynamic> vehicle) {
    Navigator.of(context).pushNamed(widget.targetRoute, arguments: vehicle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: widget.title),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load)
              : _vehicles.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          Text('ລົດທີ່ຊຳລະຄ່າທຳນຽມແລ້ວ',
                              style: AppTextStyles.titleSmall
                                  .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          for (final v in _vehicles) ...[
                            _VehicleCard(
                              vehicle: v,
                              typeLabel: _typeLabel(v['vehicle_type']?.toString()),
                              onTap: () => _openTarget(v),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.typeLabel,
    required this.onTap,
  });

  final Map<String, dynamic> vehicle;
  final String typeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = vehicle['brand']?.toString() ?? '';
    final model = vehicle['model']?.toString() ?? '';
    final cc = vehicle['cc']?.toString() ?? '';
    final year = vehicle['year']?.toString() ?? '';
    final plateNumber = vehicle['plate_number']?.toString();
    final province = vehicle['province']?.toString();

    final metaParts = [
      typeLabel,
      if (cc.isNotEmpty) '${cc}CC',
      if (year.isNotEmpty) 'ປີ $year',
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PlateBox(province: province, plateNumber: plateNumber),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [brand, model].where((s) => s.isNotEmpty).join(' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(fontSize: 16),
                  ),
                  if (metaParts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      metaParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 26),
          ],
        ),
      ),
    );
  }
}

class _PlateBox extends StatelessWidget {
  const _PlateBox({required this.province, required this.plateNumber});

  final String? province;
  final String? plateNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: plateNumber == null || plateNumber!.isEmpty
            ? AppColors.primarySurface
            : const Color(0xFFFFD600),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: plateNumber == null || plateNumber!.isEmpty
          ? const Text(
              'ຍັງບໍ່ມີທະບຽນ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.bold),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (province != null && province!.isNotEmpty)
                  Text(
                    province!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 4),
                Text(
                  plateNumber!,
                  style: const TextStyle(
                      color: Color(0xFF1A1A1A), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration:
                  const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 42),
            ),
            const SizedBox(height: 20),
            const Text('ຍັງບໍ່ມີລົດທີ່ຊຳລະຄ່າທຳນຽມແລ້ວ', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            const Text(
              'ກະລຸນາຊຳລະຄ່າທຳນຽມລົງທະບຽນລົດຂອງທ່ານກ່ອນ ຈຶ່ງຈະສາມາດເບິ່ງເອກະສານໄດ້',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
