import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Details'),
      body: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, height: 200, color: AppColors.primaryLight, child: const Icon(Icons.store, size: 64, color: AppColors.primary)),
        Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Service Shop', style: AppTextStyles.h3), const SizedBox(height: 8),
          const Row(children: [Icon(Icons.location_on, color: AppColors.grey500, size: 16), SizedBox(width: 4), Text('Village XYZ', style: AppTextStyles.bodySmall)]),
          const SizedBox(height: 20), const Text('About', style: AppTextStyles.titleMedium), const SizedBox(height: 8),
          Text('Full vehicle repair with experienced mechanics.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600)),
          const SizedBox(height: 32),
          Row(children: [Expanded(child: MgButton(label: 'Call', icon: Icons.phone, onPressed: () {})), const SizedBox(width: 12), Expanded(child: MgButton(label: 'Directions', icon: Icons.directions, variant: MgButtonVariant.secondary, onPressed: () {}))])]))])));
  }
}
