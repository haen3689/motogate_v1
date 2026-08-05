import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'History', showBack: false),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        MgListItemCard(title: 'Road Tax - KT 1234', subtitle: '350,000 LAK', trailing: '14/07/2026', icon: Icons.article, badge: const MgBadge(label: 'Done', variant: MgBadgeVariant.success), onTap: () => Navigator.of(context).pushNamed('/transactions/detail')),
        const SizedBox(height: 10),
        MgListItemCard(title: 'Insurance - KT 1234', subtitle: '1,200,000 LAK', trailing: '10/07/2026', icon: Icons.security, badge: const MgBadge(label: 'Done', variant: MgBadgeVariant.success), onTap: () => Navigator.of(context).pushNamed('/transactions/detail'))]));
  }
}
