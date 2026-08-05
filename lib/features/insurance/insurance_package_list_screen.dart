import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

final _money = NumberFormat('#,##0');

class InsurancePackageListScreen extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> company;
  final List<Map<String, dynamic>> packages;
  const InsurancePackageListScreen({
    super.key,
    required this.vehicle,
    required this.company,
    required this.packages,
  });

  num _price(Map<String, dynamic> p) => num.tryParse(p['price']?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final sorted = [...packages]..sort((a, b) => _price(a).compareTo(_price(b)));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: company['name']?.toString() ?? 'ແພັກເກັດ'),
      body: sorted.isEmpty
          ? const Center(
              child: Text('ບໍ່ມີແພັກເກັດສຳລັບລົດນີ້', style: AppTextStyles.bodySmall))
          : ListView.separated(
              padding: const EdgeInsets.all(22),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _pkg(context, sorted[i], recommended: sorted.length > 1 && i == 1),
            ),
    );
  }

  Widget _pkg(BuildContext c, Map<String, dynamic> p, {bool recommended = false}) {
    final price = _price(p);
    final duration = p['duration_months']?.toString() ?? '12';
    final coverage = p['coverage']?.toString() ?? '';
    return GestureDetector(
      onTap: () => Navigator.of(c).pushNamed('/insurance/payment', arguments: {
        'vehicle': vehicle,
        'company': company,
        'package': p,
      }),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: recommended ? AppColors.primary : AppColors.grey100,
              width: recommended ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(p['name']?.toString() ?? '', style: AppTextStyles.titleSmall)),
            if (recommended) const MgBadge(label: 'ແນະນຳ', variant: MgBadgeVariant.success),
          ]),
          const SizedBox(height: 8),
          Text('${_money.format(price)} LAK / $duration ເດືອນ',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
          if (coverage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(coverage,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.black))),
            ]),
          ],
        ]),
      ),
    );
  }
}
