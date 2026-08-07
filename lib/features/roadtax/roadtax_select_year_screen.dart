import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_road_tax_service.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import 'roadtax_step_indicator.dart';

final _money = NumberFormat('#,##0');
const _yearStepLabels = ['ເລືອກປີ', 'ຢືນຢັນ', 'ຊຳລະເງິນ'];

class RoadtaxSelectYearScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const RoadtaxSelectYearScreen({super.key, required this.vehicle});
  @override
  State<RoadtaxSelectYearScreen> createState() => _RoadtaxSelectYearScreenState();
}

class _RoadtaxSelectYearScreenState extends State<RoadtaxSelectYearScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _rate;
  int? _selectedYear;

  late final List<int> _years;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    _years = [now, now + 1, now + 2];
    _selectedYear = now;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rates = await ApiRoadTaxService.rates();
      final rate = ApiRoadTaxService.matchingRate(rates, widget.vehicle);
      if (mounted) setState(() => _rate = rate);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is DioException ? ApiAuthService.errorMessage(e) : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  num get _price => num.tryParse(_rate?['price']?.toString() ?? '') ?? 0;

  String _typeLabel(String? type) => switch (type) {
        'motorcycle' => 'ລົດຈັກ',
        'car' => 'ລົດເກັ່ງ',
        'pickup' => 'ລົດກະບະ',
        'suv' => 'ລົດຈິບ',
        'van' => 'ລົດຕູ້',
        'bus' => 'ລົດເມ',
        'towtruck' => 'ລົດລາກ',
        'trailer' => 'ລົດພ່ວງ',
        _ => 'ລົດເກັ່ງ',
      };

  @override
  Widget build(BuildContext context) {
    final plate = widget.vehicle['plate_number']?.toString() ?? '—';
    final province = widget.vehicle['province']?.toString();
    final plateType = widget.vehicle['plate_type']?.toString();
    final brandModel = [widget.vehicle['brand'], widget.vehicle['model']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    final type = _typeLabel(widget.vehicle['vehicle_type']?.toString());
    final vehicleLabel = brandModel.isEmpty ? type : '$brandModel · $type';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ເສຍຄ່າທາງ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load)
              : _rate == null
                  ? _message('ບໍ່ພົບອັດຕາຄ່າທາງສຳລັບລົດຄັນນີ້ ກະລຸນາຕິດຕໍ່ບໍລິຫານ', retry: _load)
                  : Column(children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(children: [
                                MgPlateBadge(plateNumber: plate, province: province, plateType: plateType),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(vehicleLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 20),
                            const RoadtaxStepIndicator(currentStep: 0, labels: _yearStepLabels),
                            const SizedBox(height: 24),
                            Text('ເລືອກປີພາສີ',
                                style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('ເລືອກປີທີ່ທ່ານຕ້ອງການເສຍຄ່າທາງ',
                                style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                            const SizedBox(height: 16),
                            Row(
                              children: _years
                                  .map((y) => Expanded(child: _yearChip(y)))
                                  .expand((w) => [w, const SizedBox(width: 10)])
                                  .toList()
                                ..removeLast(),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                const Text('ຄ່າທາງ', style: AppTextStyles.bodySmall),
                                Text('${_money.format(_price)} ກີບ',
                                    style: const TextStyle(
                                        color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w800)),
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
                            label: 'ຖັດໄປ',
                            onPressed: () => Navigator.of(context).pushNamed('/roadtax/confirm', arguments: {
                              'vehicle': widget.vehicle,
                              'taxYear': _selectedYear,
                              'amount': _price,
                            }),
                          ),
                        ),
                      ),
                    ]),
    );
  }

  Widget _yearChip(int year) {
    final selected = _selectedYear == year;
    return GestureDetector(
      onTap: () => setState(() => _selectedYear = year),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.grey100, width: selected ? 1.6 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$year',
            style: TextStyle(
                color: selected ? Colors.white : AppColors.black,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _message(String text, {VoidCallback? retry}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 16),
              MgButton(label: 'ລອງໃໝ່', onPressed: retry),
            ],
          ]),
        ),
      );
}
