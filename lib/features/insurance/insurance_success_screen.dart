import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

final _money = NumberFormat('#,##0');

class InsuranceSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> insurance;
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> company;
  final Map<String, dynamic> package;
  const InsuranceSuccessScreen({
    super.key,
    required this.insurance,
    required this.vehicle,
    required this.company,
    required this.package,
  });

  String get _certNumber {
    final id = int.tryParse(insurance['id']?.toString() ?? '') ?? 0;
    final year = DateTime.now().year % 100;
    return 'BT$year-${id.toString().padLeft(7, '0')}';
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final amount = num.tryParse(insurance['amount']?.toString() ?? '') ??
        num.tryParse(package['price']?.toString() ?? '') ??
        0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 52),
              ),
            ),
            const SizedBox(height: 20),
            const Text('ຊຳລະເງິນສຳເລັດ', textAlign: TextAlign.center, style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('${company['name'] ?? ''} · ${package['name'] ?? ''}',
                textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                border: Border.all(color: AppColors.primaryLight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('ເລກທີ່ໃບຢັ້ງຢືນ',
                      style: AppTextStyles.caption.copyWith(color: AppColors.grey500, fontSize: 12)),
                  Text(_certNumber,
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
                const SizedBox(height: 14),
                const Divider(color: AppColors.primaryLight, height: 1),
                const SizedBox(height: 14),
                _row('ພາຫະນະ', vehicle['plate_number']?.toString() ?? '—'),
                const SizedBox(height: 10),
                _row('ບໍລິສັດປະກັນໄພ', company['name']?.toString() ?? '—'),
                const SizedBox(height: 10),
                _row('ແພັກເກັດ', package['name']?.toString() ?? '—'),
                const SizedBox(height: 10),
                _row('ວັນທີ່ເລີ່ມ', _fmtDate(insurance['start_date']?.toString())),
                const SizedBox(height: 10),
                _row('ວັນທີ່ໝົດອາຍຸ', _fmtDate(insurance['end_date']?.toString())),
                const SizedBox(height: 14),
                const Divider(color: AppColors.primaryLight, height: 1),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('ຈຳນວນເງິນ', style: AppTextStyles.titleSmall),
                  Text('${_money.format(amount)} ກີບ',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ]),
            ),
            const SizedBox(height: 28),
            MgButton(
                label: 'ກັບໜ້າຫຼັກ',
                onPressed: () =>
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
