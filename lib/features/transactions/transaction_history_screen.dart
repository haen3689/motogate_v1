import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/transaction_service.dart';

final _money = NumberFormat('#,###');
final _dateFmt = DateFormat('dd/MM/yyyy');

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

  Color _statusColor(String status) => switch (status) {
        'success' => AppColors.success,
        'failed' => AppColors.error,
        _ => AppColors.warning,
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.grey100, width: 1.5)),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('ລາຍການ',
                              style: TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.grey400)),
                          Text('ຍອດເງິນ',
                              style: TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.grey400)),
                        ]),
                      ),
                      for (final entry in _grouped().entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
                          child: Text(entry.key,
                              style: const TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.grey500)),
                        ),
                        for (final t in entry.value) _row(t),
                      ],
                    ],
                  ),
                ),
    );
  }

  /// Preserves the backend's created_at-desc ordering; just clusters
  /// consecutive same-day transactions under one date header.
  Map<String, List<TransactionModel>> _grouped() {
    final map = <String, List<TransactionModel>>{};
    for (final t in _items) {
      final key = _dateFmt.format(t.createdAt.toLocal());
      (map[key] ??= []).add(t);
    }
    return map;
  }

  Widget _row(TransactionModel t) {
    final failed = t.status == 'failed';
    final label = t.description?.isNotEmpty == true ? t.description! : t.typeLabel;
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/transactions/detail', arguments: t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.grey100, width: 1)),
        ),
        child: Row(children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: _statusColor(t.status), shape: BoxShape.circle),
          ),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(children: [
                TextSpan(
                    text: label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black)),
                if (t.reference?.isNotEmpty == true)
                  TextSpan(
                      text: '  ·  ${t.reference}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.grey350)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money.format(t.amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: failed ? AppColors.error : AppColors.black,
              decoration: failed ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.error,
            ),
          ),
        ]),
      ),
    );
  }
}
