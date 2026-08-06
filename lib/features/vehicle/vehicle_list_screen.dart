import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/services/api_auth_service.dart';
import '../../core/services/api_vehicle_service.dart';
import '../../core/services/coach_mark_tour.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String? _error;

  static const _tourSeenPrefKey = 'vehicle_list_tour_seen';
  final _tourKeyStats = GlobalKey();
  final _tourKeyFirstCard = GlobalKey();
  final _tourKeyFab = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiVehicleService.list();
      if (mounted) setState(() => _vehicles = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is DioException
            ? ApiAuthService.errorMessage(e)
            : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _maybeStartTour();
    }
  }

  Future<void> _maybeStartTour() {
    if (_error != null) return Future.value();
    return CoachMarkTour.maybeStart(prefKey: _tourSeenPrefKey, start: _startTour);
  }

  void _startTour() {
    if (!mounted) return;
    final keys = _vehicles.isEmpty
        ? [_tourKeyFab]
        : [_tourKeyStats, _tourKeyFirstCard, _tourKeyFab];
    ShowCaseWidget.of(context).startShowCase(keys);
  }

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

  Future<void> _openAdd() async {
    final added = await Navigator.of(context).pushNamed('/vehicle/add');
    if (added == true) _load();
  }

  Future<void> _openPayFee(Map<String, dynamic> vehicle) async {
    await Navigator.of(context).pushNamed('/vehicle/pay-fee', arguments: vehicle);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: 'ລາຍການລົດ', showBack: false, actions: [
        GestureDetector(
          onTap: _startTour,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: AppColors.white, size: 20),
          ),
        ),
      ]),
      body: Stack(children: [
        _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load)
              : _vehicles.isEmpty
                  ? _EmptyState(onAddTap: _openAdd)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        children: [
                          _sectionTitle(Icons.bar_chart_outlined, 'ພາບລວມ'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Showcase(
                                  key: _tourKeyStats,
                                  title: 'ພາບລວມ',
                                  description: 'ເບິ່ງສະຫຼຸບຈຳນວນລົດຂອງທ່ານໄດ້ທີ່ນີ້',
                                  targetBorderRadius: BorderRadius.circular(14),
                                  child: _StatChip(
                                    icon: Icons.directions_car_outlined,
                                    value: '${_vehicles.length}',
                                    label: 'ຄັນທັງໝົດ',
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatChip(
                                  icon: Icons.motorcycle_outlined,
                                  value:
                                      '${_vehicles.where((v) => v['vehicle_type'] == 'motorcycle').length}',
                                  label: 'ລົດຈັກ',
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatChip(
                                  icon: Icons.directions_car_filled_outlined,
                                  value:
                                      '${_vehicles.where((v) => v['vehicle_type'] != 'motorcycle').length}',
                                  label: 'ລົດ 4 ລໍ້',
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFEEF2F2), height: 1),
                          const SizedBox(height: 20),
                          _sectionTitle(Icons.directions_car_outlined, 'ລາຍການລົດ'),
                          const SizedBox(height: 12),
                          for (final entry in _vehicles.asMap().entries) ...[
                            entry.key == 0
                                ? Showcase(
                                    key: _tourKeyFirstCard,
                                    title: 'ລາຍການລົດ',
                                    description: 'ກົດເບິ່ງລາຍລະອຽດລົດແຕ່ລະຄັນໄດ້ທີ່ນີ້',
                                    targetBorderRadius: BorderRadius.circular(20),
                                    child: _VehicleCard(
                                      vehicle: entry.value,
                                      typeLabel: _typeLabel(entry.value['vehicle_type']?.toString()),
                                      onTap: () => Navigator.of(context)
                                          .pushNamed('/vehicle/detail', arguments: entry.value),
                                      onPayFeeTap: () => _openPayFee(entry.value),
                                    ),
                                  )
                                : _VehicleCard(
                                    vehicle: entry.value,
                                    typeLabel: _typeLabel(entry.value['vehicle_type']?.toString()),
                                    onTap: () => Navigator.of(context)
                                        .pushNamed('/vehicle/detail', arguments: entry.value),
                                    onPayFeeTap: () => _openPayFee(entry.value),
                                  ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
      ]),
      floatingActionButton: Showcase(
        key: _tourKeyFab,
        title: 'ເພີ່ມລົດ',
        description: 'ກົດປຸ່ມນີ້ເພື່ອເພີ່ມຂໍ້ມູນລົດຄັນໃໝ່',
        targetBorderRadius: BorderRadius.circular(20),
        tooltipActions: CoachMarkTour.lastStepActions(context),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onPressed: _openAdd,
          child: const Icon(Icons.add, color: Colors.white, size: 34),
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) => Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(text,
            style: AppTextStyles.titleSmall
                .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
      ]);

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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.typeLabel,
    required this.onTap,
    required this.onPayFeeTap,
  });

  final Map<String, dynamic> vehicle;
  final String typeLabel;
  final VoidCallback onTap;
  final VoidCallback onPayFeeTap;

  @override
  Widget build(BuildContext context) {
    final brand = vehicle['brand']?.toString() ?? '';
    final model = vehicle['model']?.toString() ?? '';
    final cc = vehicle['cc']?.toString() ?? '';
    final year = vehicle['year']?.toString() ?? '';
    final plateNumber = vehicle['plate_number']?.toString();
    final province = vehicle['province']?.toString();
    final feePaid = vehicle['fee_paid'] == true;

    final metaParts = [
      typeLabel,
      if (cc.isNotEmpty) '${cc}CC',
      if (year.isNotEmpty) 'ປີ $year',
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PlateBox(province: province, plateNumber: plateNumber),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [brand, model].where((s) => s.isNotEmpty).join(' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(fontSize: 16),
                  ),
                  if (metaParts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      metaParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                  if (!feePaid) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PayFeeButton(onTap: onPayFeeTap),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 26),
          ],
        ),
      ),
    );
  }
}

class _PayFeeButton extends StatelessWidget {
  const _PayFeeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.black, size: 14),
            const SizedBox(width: 4),
            Text(
              'ຊຳລະຄ່າທຳນຽມ',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.black,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlateBox extends StatelessWidget {
  const _PlateBox({required this.province, required this.plateNumber});

  final String? province;
  final String? plateNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: plateNumber == null || plateNumber!.isEmpty
            ? AppColors.primarySurface
            : const Color(0xFFFFD600),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: plateNumber == null || plateNumber!.isEmpty
          ? const Text(
              'ຍັງບໍ່ມີທະບຽນ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.bold),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (province != null && province!.isNotEmpty)
                  Text(
                    province!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 4),
                Text(
                  plateNumber!,
                  style: const TextStyle(
                      color: Color(0xFF1A1A1A), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.grey100),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration:
                  const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.directions_car_outlined, color: AppColors.primary, size: 42),
            ),
            const SizedBox(height: 20),
            const Text('ຍັງບໍ່ມີລົດໃນລະບົບ', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            const Text(
              'ເພີ່ມລົດຄັນທຳອິດເພື່ອເລີ່ມຕິດຕາມທະບຽນ ແລະ ເອກະສານຂອງທ່ານ',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            MgButton(label: 'ເພີ່ມລົດ', icon: Icons.add, onPressed: onAddTap),
          ],
        ),
      ),
    );
  }
}
