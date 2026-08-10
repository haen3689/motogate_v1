import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/transaction_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});
  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await TransactionService.getAll();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  IconData _iconFor(String type) => switch (type) {
        'road_tax' => Icons.article,
        'insurance' => Icons.security,
        'inspection' => Icons.fact_check_outlined,
        _ => Icons.receipt_long,
      };

  MgBadgeVariant _badgeVariantFor(String status) => switch (status) {
        'success' => MgBadgeVariant.success,
        'failed' => MgBadgeVariant.error,
        _ => MgBadgeVariant.warning,
      };

  String _statusLabel(String status) => switch (status) {
        'success' => 'ສຳເລັດ',
        'failed' => 'ລົ້ມເຫລວ',
        _ => 'ລໍຖ້າ',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ປະຫວັດ', showBack: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.receipt_long_outlined, color: AppColors.grey300, size: 40),
                      const SizedBox(height: 12),
                      const Text('ຍັງບໍ່ມີປະຫວັດທຸລະກຳ', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 16),
                      MgButton(label: 'ລອງໃໝ່', onPressed: _load),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(22),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = _items[i];
                      return MgListItemCard(
                        title: t.description?.isNotEmpty == true ? t.description! : t.typeLabel,
                        subtitle: '${NumberFormat('#,###').format(t.amount)} LAK',
                        trailing: DateFormat('dd/MM/yyyy').format(t.createdAt.toLocal()),
                        icon: _iconFor(t.type),
                        badge: MgBadge(label: _statusLabel(t.status), variant: _badgeVariantFor(t.status)),
                        onTap: () => Navigator.of(context).pushNamed('/transactions/detail', arguments: t),
                      );
                    },
                  ),
                ),
    );
  }
}
