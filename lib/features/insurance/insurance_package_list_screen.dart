import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import 'insurance_step_indicator.dart';

final _money = NumberFormat('#,##0');

class InsurancePackageListScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> company;
  final List<Map<String, dynamic>> packages;
  const InsurancePackageListScreen({
    super.key,
    required this.vehicle,
    required this.company,
    required this.packages,
  });

  @override
  State<InsurancePackageListScreen> createState() => _InsurancePackageListScreenState();
}

class _InsurancePackageListScreenState extends State<InsurancePackageListScreen> {
  static const _collapsedCount = 3;
  bool _showAll = false;
  Map<String, dynamic>? _selected;

  num _price(Map<String, dynamic> p) => num.tryParse(p['price']?.toString() ?? '') ?? 0;

  void _showDetails(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Text(p['name']?.toString() ?? '', style: AppTextStyles.titleSmall.copyWith(fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_money.format(_price(p))} ກີບ',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
              Text('/ ${p['duration_months'] ?? 12} ເດືອນ', style: AppTextStyles.bodySmall),
            ]),
          ),
          if ((p['coverage']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('ຄວາມຄຸ້ມຄອງ',
                style: AppTextStyles.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(p['coverage'].toString(), style: AppTextStyles.bodySmall.copyWith(height: 1.6)),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: MgButton(label: 'ປິດ', onPressed: () => Navigator.of(context).pop()),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.packages]..sort((a, b) => _price(a).compareTo(_price(b)));
    final shown = _showAll || sorted.length <= _collapsedCount
        ? sorted
        : sorted.take(_collapsedCount).toList();
    final logoPath = widget.company['logo']?.toString();
    final logoUrl =
        logoPath != null && logoPath.isNotEmpty ? '${ApiClient.webBaseUrl}$logoPath' : null;
    final description = widget.company['description']?.toString() ?? '';
    final plate = widget.vehicle['plate_number']?.toString() ?? '—';
    final brandModel = [widget.vehicle['brand'], widget.vehicle['model']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ປະກັນໄພພາຫະນະ'),
      body: sorted.isEmpty
          ? const Center(
              child: Text('ບໍ່ມີແພັກເກັດສຳລັບລົດນີ້', style: AppTextStyles.bodySmall))
          : Column(children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.primary, width: 1.2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: logoUrl != null
                              ? Image.network(logoUrl,
                                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => _logoFallback())
                              : _logoFallback(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(widget.company['name']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleSmall
                                    .copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                                brandModel.isEmpty ? plate : '$plate · $brandModel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    const InsuranceStepIndicator(currentStep: 1),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('ລາຄາ ແລະ ການຄຸ້ມກັນ',
                          style:
                              AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                      if (sorted.length > _collapsedCount)
                        GestureDetector(
                          onTap: () => setState(() => _showAll = !_showAll),
                          child: Text(_showAll ? 'ສະແດງໜ້ອຍລົງ' : 'ສະແດງເພີ່ມເຕີມ',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    for (final p in shown) ...[
                      _packageCard(p),
                      const SizedBox(height: 10),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('ກ່ຽວກັບບໍລິສັດ',
                          style:
                              AppTextStyles.titleSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.grey100),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(description,
                            style: AppTextStyles.bodySmall.copyWith(height: 1.6)),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: MgButton(
                    label: 'ຢືນຢັນ',
                    variant: _selected != null ? MgButtonVariant.primary : MgButtonVariant.disabled,
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.of(context).pushNamed('/insurance/payment', arguments: {
                              'vehicle': widget.vehicle,
                              'company': widget.company,
                              'package': _selected,
                            }),
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _logoFallback() => Container(
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
      );

  Widget _packageCard(Map<String, dynamic> p) {
    final selected = _selected != null && _selected!['id'] == p['id'];
    return GestureDetector(
      onTap: () => setState(() => _selected = p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.grey100, width: selected ? 1.6 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(p['name']?.toString() ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.grey300, size: 20),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_money.format(_price(p))} ກີບ',
                style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 5),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('/ ${p['duration_months'] ?? 12} ເດືອນ', style: AppTextStyles.caption),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showDetails(p),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('ລາຍລະອຽດ',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11.5)),
                const Icon(Icons.chevron_right, color: AppColors.primary, size: 15),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}
