import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
class InspectionCenterListScreen extends StatelessWidget {
  const InspectionCenterListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Inspection Centers'),
      body: Padding(padding: const EdgeInsets.all(22), child: Column(children: [const MgSearchBar(), const SizedBox(height: 16),
        Expanded(child: ListView.separated(itemCount: 4, separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => MgListItemCard(title: 'Center ${i+1}', subtitle: 'Village XYZ', trailing: '${(i+1)*3} km', icon: Icons.fact_check, onTap: () => Navigator.of(context).pushNamed('/inspection/booking'))))])));
  }
}
