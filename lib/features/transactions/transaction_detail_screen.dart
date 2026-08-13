import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/transaction_service.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

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
    final args = ModalRoute.of(context)?.settings.arguments;
    final t = args is TransactionModel ? args : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ລາຍລະອຽດທຸລະກຳ'),
      body: t == null
          ? const Center(child: Text('ບໍ່ພົບຂໍ້ມູນ', style: AppTextStyles.bodySmall))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  MgBadge(label: _statusLabel(t.status), variant: _badgeVariantFor(t.status)),
                  const SizedBox(height: 16),
                  Text('${NumberFormat('#,###').format(t.amount)} LAK',
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 24),
                  _r('ປະເພດ', t.typeLabel),
                  _r('ຍອດຊຳລະ', '${NumberFormat('#,###').format(t.amount)} LAK'),
                  if (t.referenceNo?.isNotEmpty == true) _r('ເລກອ້າງອິງ', t.referenceNo!),
                  if (t.invoiceNo?.isNotEmpty == true) _r('ເລກໃບບິນ', t.invoiceNo!),
                  if (t.merchantRefNo?.isNotEmpty == true) _r('ເລກອ້າງອິງຮ້ານຄ້າ', t.merchantRefNo!),
                  if (t.reference?.isNotEmpty == true) _r('ທະບຽນລົດ', t.reference!),
                  if (t.description?.isNotEmpty == true) _r('ລາຍລະອຽດ', t.description!),
                  _r('ວັນທີ', DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt.toLocal())),
                ]),
              ),
            ),
    );
  }

  Widget _r(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: AppTextStyles.bodySmall),
          Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
        ]),
      );
}
