import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
enum ServiceType { repair, dealer, towing }
class ServiceListScreen extends StatelessWidget {
  final ServiceType type; const ServiceListScreen({super.key, required this.type});
  String get _t => switch (type) { ServiceType.repair => 'Repair Shops', ServiceType.dealer => 'Car Dealers', ServiceType.towing => 'Towing' };
  IconData get _ic => switch (type) { ServiceType.repair => Icons.build, ServiceType.dealer => Icons.store, ServiceType.towing => Icons.local_shipping };
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: MgHeader(title: _t),
      body: Padding(padding: const EdgeInsets.all(22), child: Column(children: [const MgSearchBar(), const SizedBox(height: 16),
        Expanded(child: ListView.separated(itemCount: 5, separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => MgListItemCard(title: '$_t ${i+1}', subtitle: 'Village XYZ', trailing: '${(i+1)*2} km', icon: _ic, onTap: () => Navigator.of(context).pushNamed('/services/detail'))))])));
  }
}
