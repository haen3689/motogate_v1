import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/transaction_service.dart';

final _money = NumberFormat('#,###');
final _timeFmt = DateFormat('HH:mm');

const _laoMonths = [
  'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ', 'ພຶດສະພາ', 'ມິຖຸນາ',
  'ກໍລະກົດ', 'ສິງຫາ', 'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
];

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

  MgBadgeVariant _badgeVariant(String status) => switch (status) {
        'failed' => MgBadgeVariant.error,
        _ => MgBadgeVariant.warning,
      };

  String _statusLabel(String status) => switch (status) {
        'failed' => 'ລົ້ມເຫລວ',
        _ => 'ລໍຖ້າ',
      };

  IconData _iconFor(String type) => switch (type) {
        'road_tax' => Icons.article_outlined,
        'insurance' => Icons.security_outlined,
        'inspection' => Icons.fact_check_outlined,
        'vehicle_fee' => Icons.directions_car_outlined,
        _ => Icons.receipt_long_outlined,
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
                      for (final entry in _grouped().entries) ...[
                        _dateGroup(entry.key, entry.value),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
    );
  }

  /// Preserves the backend's created_at-desc ordering; just clusters
  /// consecutive same-day transactions under one date header.
  Map<DateTime, List<TransactionModel>> _grouped() {
    final map = <DateTime, List<TransactionModel>>{};
    for (final t in _items) {
      final local = t.createdAt.toLocal();
      final key = DateTime(local.year, local.month, local.day);
      (map[key] ??= []).add(t);
    }
    return map;
  }

  String _dateLabel(DateTime d) => '${d.day} ${_laoMonths[d.month - 1]} ${d.year}';

  Widget _dateGroup(DateTime date, List<TransactionModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_dateLabel(date),
              style: AppTextStyles.titleSmall.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800)),
          Text('${items.length} ລາຍການ',
              style: const TextStyle(fontSize: 11.5, color: AppColors.grey350, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        const Divider(color: AppColors.grey100, height: 1),
        for (final t in items) _row(t),
      ]),
    );
  }

  Widget _row(TransactionModel t) {
    final failed = t.status == 'failed';
    final success = t.status == 'success';
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/transactions/detail', arguments: t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.grey100, width: 1)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor(t.status).withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(t.type), color: _statusColor(t.status), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.black)),
              const SizedBox(height: 2),
              Text(
                [
                  if (t.reference?.isNotEmpty == true) t.reference!,
                  _timeFmt.format(t.createdAt.toLocal()),
                ].join('  ·  '),
                style: const TextStyle(fontSize: 11, color: AppColors.grey350),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${_money.format(t.amount)} ${success ? 'ກີບ' : ''}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: failed ? AppColors.error : AppColors.primary,
                decoration: failed ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.error,
              ),
            ),
            if (!success) ...[
              const SizedBox(height: 4),
              MgBadge(label: _statusLabel(t.status), variant: _badgeVariant(t.status)),
            ],
          ]),
        ]),
      ),
    );
  }
}
