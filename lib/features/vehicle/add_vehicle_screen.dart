import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/services/coach_mark_tour.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class _AddVehicleMethod {
  const _AddVehicleMethod(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap,
      this.tourKey,
      this.tourIsLast = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final GlobalKey? tourKey;
  final bool tourIsLast;
}

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});
  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  static const _tourSeenPrefKey = 'add_vehicle_tour_seen';
  final _tourKeyManual = GlobalKey();
  final _tourKeySearch = GlobalKey();

  @override
  void initState() {
    super.initState();
    _maybeStartTour();
  }

  Future<void> _maybeStartTour() =>
      CoachMarkTour.maybeStart(prefKey: _tourSeenPrefKey, start: _startTour);

  void _startTour() {
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase([_tourKeyManual, _tourKeySearch]);
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('ກຳລັງພັດທະນາ')));
  }

  void _openManualEntry(BuildContext context) {
    Navigator.of(context).pushNamed('/vehicle/manual_entry');
  }

  @override
  Widget build(BuildContext context) {
    final methods = [
      _AddVehicleMethod(
        icon: Icons.edit_note_outlined,
        title: 'ກອກຂໍ້ມູນເອງ',
        subtitle: 'ປ້ອນຂໍ້ມູນລົດດ້ວຍຕົນເອງທີລະຊ່ອງ',
        onTap: () => _openManualEntry(context),
        tourKey: _tourKeyManual,
      ),
      _AddVehicleMethod(
        icon: Icons.search_outlined,
        title: 'ຄົ້ນຫາດ້ວຍເລກທະບຽນ',
        subtitle: 'ດຶງຂໍ້ມູນລົດຈາກຖານຂໍ້ມູນກົມຂົນສົ່ງໂດຍກົງ',
        onTap: () => _showComingSoon(context),
        tourKey: _tourKeySearch,
        tourIsLast: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MgHeader(title: 'ເພີ່ມຂໍ້ມູນລົດ', actions: [
        GestureDetector(
          onTap: _startTour,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline,
                color: AppColors.white, size: 20),
          ),
        ),
      ]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const Text('ເລືອກວິທີເພີ່ມຂໍ້ມູນລົດຂອງທ່ານ',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: 16),
            for (final m in methods) ...[
              _MethodTile(method: m),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method});

  final _AddVehicleMethod method;

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      onTap: method.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                border: Border.all(color: AppColors.primaryLight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(method.icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(method.subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );

    if (method.tourKey == null) return tile;
    return Showcase(
      key: method.tourKey!,
      title: method.title,
      description: method.subtitle,
      targetBorderRadius: BorderRadius.circular(16),
      tooltipActions: method.tourIsLast ? CoachMarkTour.lastStepActions(context) : null,
      child: tile,
    );
  }
}
