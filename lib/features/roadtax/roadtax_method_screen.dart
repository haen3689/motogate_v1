import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class RoadtaxMethodScreen extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  const RoadtaxMethodScreen({super.key, required this.vehicle});

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
    final plateType = vehicle['plate_type']?.toString();
    final brandModel = [vehicle['brand'], vehicle['model']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    final type = _typeLabel(vehicle['vehicle_type']?.toString());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ເສຍຄ່າທາງ'),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              MgPlateBadge(plateNumber: plate, province: province, plateType: plateType),
              const SizedBox(width: 12),
              Expanded(
                child: Text(brandModel.isEmpty ? type : '$brandModel · $type',
                    style: AppTextStyles.bodySmall),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Text('ເລືອກວິທີການເສຍຄ່າທາງ',
              style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('ທ່ານຈະຈ່າຍໃນແອບ ຫຼື ໄດ້ຈ່າຍຢູ່ພະແນກຂົນສົ່ງມາກ່ອນແລ້ວ?',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
          const SizedBox(height: 16),
          _methodCard(
            context,
            icon: Icons.credit_card,
            title: 'ຈ່າຍໃນແອບ',
            subtitle: 'ຄິດໄລ່ລາຄາອັດຕະໂນມັດ ແລະ ຈ່າຍຜ່ານແອບໄດ້ທັນທີ',
            onTap: () => Navigator.of(context).pushNamed('/roadtax/year', arguments: vehicle),
          ),
          const SizedBox(height: 12),
          _methodCard(
            context,
            icon: Icons.upload_file,
            title: 'ອັບໂຫລດຫຼັກຖານ',
            subtitle: 'ຖ້າທ່ານໄດ້ຈ່າຍຄ່າທາງຢູ່ພະແນກຂົນສົ່ງມາກ່ອນແລ້ວ',
            onTap: () => Navigator.of(context).pushNamed('/roadtax/upload', arguments: vehicle),
          ),
        ],
      ),
    );
  }

  Widget _methodCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey300),
        ]),
      ),
    );
  }
}
