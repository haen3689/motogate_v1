import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

final _money = NumberFormat('#,##0');

class InspectionSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> inspection;
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> center;
  final Map<String, dynamic> service;
  final Map<String, dynamic>? payment;
  const InspectionSuccessScreen({
    super.key,
    required this.inspection,
    required this.vehicle,
    required this.center,
    required this.service,
    this.payment,
  });

  String get _bookingNumber {
    final ref = payment?['reference']?.toString();
    if (ref != null && ref.isNotEmpty) return ref;

    final id = int.tryParse(inspection['id']?.toString() ?? '') ?? 0;
    final year = DateTime.now().year % 100;
    return 'IN$year-${id.toString().padLeft(7, '0')}';
  }

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String? status) => switch (status) {
        'confirmed' => 'ຢືນຢັນແລ້ວ',
        'pending' => 'ລໍຖ້າ',
        'completed' => 'ສຳເລັດ',
        'cancelled' => 'ຍົກເລີກ',
        _ => status ?? '—',
      };

  @override
  Widget build(BuildContext context) {
    final amount = num.tryParse(inspection['amount']?.toString() ?? '') ??
        num.tryParse(service['price']?.toString() ?? '') ??
        0;
    final centerName = inspection['center_name']?.toString() ?? center['name']?.toString() ?? '—';
    final serviceName = inspection['service_name']?.toString() ?? service['name']?.toString() ?? '—';
    final appointmentAt = inspection['appointment_at']?.toString();
    final status = inspection['status']?.toString();

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
            const Text('ຈອງກວດສະພາບລົດສຳເລັດ', textAlign: TextAlign.center, style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('$centerName · $serviceName',
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
                  Text('ເລກທີ່ອ້າງອີງ',
                      style: AppTextStyles.caption.copyWith(color: AppColors.grey500, fontSize: 12)),
                  Text(_bookingNumber,
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
                const SizedBox(height: 14),
                const Divider(color: AppColors.primaryLight, height: 1),
                const SizedBox(height: 14),
                _row('ພາຫະນະ', vehicle['plate_number']?.toString() ?? '—'),
                const SizedBox(height: 10),
                _row('ສູນກວດສະພາບລົດ', centerName),
                const SizedBox(height: 10),
                _row('ບໍລິການ', serviceName),
                const SizedBox(height: 10),
                _row('ວັນ ແລະ ເວລານັດໝາຍ', _fmtDateTime(appointmentAt)),
                const SizedBox(height: 10),
                _row('ສະຖານະ', _statusLabel(status)),
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
