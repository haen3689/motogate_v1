import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/plate_type_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import 'roadtax_step_indicator.dart';

final _money = NumberFormat('#,##0');

class RoadtaxConfirmScreen extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final int taxYear;
  final num amount;
  const RoadtaxConfirmScreen({
    super.key,
    required this.vehicle,
    required this.taxYear,
    required this.amount,
  });

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

  @override
  Widget build(BuildContext context) {
    final plate = vehicle['plate_number']?.toString() ?? '—';
    final province = vehicle['province']?.toString();
    final showProvince = PlateTypeCache.instance.showProvince(vehicle['plate_type']?.toString());
    final brandModel = [vehicle['brand'], vehicle['model']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    final type = _typeLabel(vehicle['vehicle_type']?.toString());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ຢືນຢັນຂໍ້ມູນ'),
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
                  MgPlateBadge(
                      plateNumber: plate,
                      province: vehicle['province']?.toString(),
                      plateType: vehicle['plate_type']?.toString()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(brandModel.isEmpty ? type : '$brandModel · $type',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              const RoadtaxStepIndicator(currentStep: 1, labels: ['ເລືອກປີ', 'ຢືນຢັນ', 'ຊຳລະເງິນ']),
              const SizedBox(height: 24),
              Text('ລາຍລະອຽດ',
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (showProvince && province != null && province.isNotEmpty) _row('ແຂວງ', province),
                  if (brandModel.isNotEmpty) _row('ຍີ່ຫໍ້/ລຸ້ນ', brandModel),
                  _row('ປະເພດ', type),
                  _row('ປີພາສີ', '$taxYear'),
                  const Divider(height: 24, color: AppColors.grey100),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('ຍອດຊຳລະທັງໝົດ', style: AppTextStyles.titleSmall),
                    Text('${_money.format(amount)} ກີບ',
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: MgButton(
              label: 'ຢືນຢັນ ແລະ ຊຳລະເງິນ',
              onPressed: () => Navigator.of(context).pushNamed('/roadtax/payment', arguments: {
                'vehicle': vehicle,
                'taxYear': taxYear,
                'amount': amount,
              }),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTextStyles.bodySmall),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}
