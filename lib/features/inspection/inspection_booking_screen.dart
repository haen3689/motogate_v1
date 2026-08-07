import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import 'inspection_step_indicator.dart';

final _money = NumberFormat('#,##0');

class InspectionBookingScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> center;
  final List<Map<String, dynamic>> services;
  const InspectionBookingScreen({
    super.key,
    required this.vehicle,
    required this.center,
    required this.services,
  });

  @override
  State<InspectionBookingScreen> createState() => _InspectionBookingScreenState();
}

class _InspectionBookingScreenState extends State<InspectionBookingScreen> {
  static const _times = ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'];

  Map<String, dynamic>? _selectedService;
  DateTime? _date;
  int _timeIndex = -1;

  num _price(Map<String, dynamic> svc) => num.tryParse(svc['price']?.toString() ?? '') ?? 0;

  DateTime? get _appointmentAt {
    if (_date == null || _timeIndex < 0) return null;
    final parts = _times[_timeIndex].split(':');
    return DateTime(_date!.year, _date!.month, _date!.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  void _showDetails(Map<String, dynamic> svc) {
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
          Text(svc['name']?.toString() ?? '', style: AppTextStyles.titleSmall.copyWith(fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_money.format(_price(svc))} ກີບ',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
            ]),
          ),
          if ((svc['detail']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('ລາຍລະອຽດ',
                style: AppTextStyles.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(svc['detail'].toString(), style: AppTextStyles.bodySmall.copyWith(height: 1.6)),
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

  void _next() {
    final appt = _appointmentAt;
    if (_selectedService == null || appt == null) return;
    Navigator.of(context).pushNamed('/inspection/payment', arguments: {
      'vehicle': widget.vehicle,
      'center': widget.center,
      'service': _selectedService,
      'appointmentAt': appt,
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.services]..sort((a, b) => _price(a).compareTo(_price(b)));
    final logoPath = widget.center['logo']?.toString();
    final logoUrl =
        logoPath != null && logoPath.isNotEmpty ? '${ApiClient.webBaseUrl}$logoPath' : null;
    final plate = widget.vehicle['plate_number']?.toString() ?? '—';
    final brandModel = [widget.vehicle['brand'], widget.vehicle['model']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    final canContinue = _selectedService != null && _appointmentAt != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ຈອງກວດສະພາບລົດ'),
      body: sorted.isEmpty
          ? const Center(
              child: Text('ບໍ່ມີບໍລິການສຳລັບລົດນີ້', style: AppTextStyles.bodySmall))
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
                            Text(widget.center['name']?.toString() ?? '',
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
                    const InspectionStepIndicator(currentStep: 1),
                    const SizedBox(height: 24),
                    Text('ເລືອກບໍລິການກວດສະພາບ',
                        style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    for (final svc in sorted) ...[
                      _serviceCard(svc),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 20),
                    Text('ນັດໝາຍວັນ ແລະ ເວລາ',
                        style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.grey100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('ວັນທີ', style: AppTextStyles.labelMedium),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (d != null) setState(() => _date = d);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _date != null ? AppColors.primarySurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _date != null ? AppColors.primary : AppColors.grey100,
                                  width: _date != null ? 1.6 : 1),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                  _date != null
                                      ? '${_date!.day}/${_date!.month}/${_date!.year}'
                                      : 'ເລືອກວັນທີ',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: _date != null ? FontWeight.w700 : FontWeight.w400)),
                              const Spacer(),
                              const Icon(Icons.chevron_right, color: AppColors.grey300, size: 18),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.grey100, height: 1),
                        const SizedBox(height: 16),
                        const Text('ເວລາ', style: AppTextStyles.labelMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(
                            _times.length,
                            (i) => GestureDetector(
                              onTap: () => setState(() => _timeIndex = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                decoration: BoxDecoration(
                                  color: _timeIndex == i ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: _timeIndex == i ? AppColors.primary : AppColors.grey100),
                                ),
                                child: Text(_times[i],
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _timeIndex == i ? AppColors.white : AppColors.black)),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: MgButton(
                    label: 'ຖັດໄປ → ຊຳລະເງິນ',
                    variant: canContinue ? MgButtonVariant.primary : MgButtonVariant.disabled,
                    onPressed: canContinue ? _next : null,
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _logoFallback() => Container(
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 20),
      );

  Widget _serviceCard(Map<String, dynamic> svc) {
    final selected = _selectedService != null && _selectedService!['id'] == svc['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedService = svc),
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
              child: Text(svc['name']?.toString() ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.grey300, size: 20),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_money.format(_price(svc))} ກີບ',
                style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showDetails(svc),
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
