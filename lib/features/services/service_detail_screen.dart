import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/service_center_service.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key});

  IconData _iconFor(String type) => switch (type) {
        'garage' => Icons.build,
        'dealer' => Icons.store,
        'towing' => Icons.local_shipping,
        _ => Icons.storefront,
      };

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ບໍ່ສາມາດໂທອອກໄດ້'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _openInMaps(BuildContext context, double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ບໍ່ສາມາດເປີດແຜນທີ່ໄດ້'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final center = args is ServiceCenterModel ? args : null;

    if (center == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: MgHeader(title: 'ລາຍລະອຽດ'),
        body: Center(child: Text('ບໍ່ພົບຂໍ້ມູນ')),
      );
    }

    final hasCoords = center.lat != null && center.lng != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: center.name),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            height: 200,
            color: AppColors.primaryLight,
            child: center.logoUrl != null
                ? Image.network(center.logoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(_iconFor(center.serviceType), size: 64, color: AppColors.primary))
                : Icon(_iconFor(center.serviceType), size: 64, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(center.name, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              if ((center.location ?? '').isNotEmpty)
                Row(children: [
                  const Icon(Icons.location_on, color: AppColors.grey500, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(center.location!, style: AppTextStyles.bodySmall)),
                ]),
              if (center.rating != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 4),
                  Text(center.rating!.toStringAsFixed(1), style: AppTextStyles.titleMedium),
                ]),
              ],
              if ((center.ownerName ?? '').isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('ຂໍ້ມູນ', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Text('ເຈົ້າຂອງ/ຜູ້ຮັບຜິດຊອບ: ${center.ownerName}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600)),
              ],
              if ((center.phone ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('ເບີໂທ: ${center.phone}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600)),
              ],
              const SizedBox(height: 32),
              Row(children: [
                Expanded(
                  child: MgButton(
                    label: 'ໂທ',
                    icon: Icons.phone,
                    onPressed: (center.phone ?? '').isEmpty ? null : () => _call(context, center.phone!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MgButton(
                    label: 'ແຜນທີ່',
                    icon: Icons.directions,
                    variant: MgButtonVariant.secondary,
                    onPressed: hasCoords ? () => _openInMaps(context, center.lat!, center.lng!) : null,
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
