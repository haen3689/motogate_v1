import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
class RoadtaxSelectVehicleScreen extends StatelessWidget {
  const RoadtaxSelectVehicleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Road Tax'),
      body: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        MgListItemCard(title: 'KT 1234 - Toyota Camry', subtitle: 'Expires: 31/12/2026', icon: Icons.directions_car, badge: const MgBadge(label: 'Ready', variant: MgBadgeVariant.success), onTap: () => Navigator.of(context).pushNamed('/roadtax/year'))])));
  }
}
