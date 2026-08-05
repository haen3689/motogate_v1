import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
class ServiceMapScreen extends StatelessWidget {
  const ServiceMapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Map'),
      body: Stack(children: [
        Container(color: AppColors.grey50, child: const Center(child: Icon(Icons.map, size: 64, color: AppColors.grey300))),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(22), decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [const MgSearchBar(), const SizedBox(height: 16),
            MgListItemCard(title: 'Repair Shop ABC', subtitle: '2.5 km', icon: Icons.build, onTap: () => Navigator.of(context).pushNamed('/services/detail'))])))]));
  }
}
