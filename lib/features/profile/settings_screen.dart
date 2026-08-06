import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ຕັ້ງຄ່າ'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tipBanner('ປັບແຕ່ງການແຈ້ງເຕືອນ, ພາສາ ແລະ ເບິ່ງຂໍ້ມູນແອັບໄດ້ທີ່ໜ້ານີ້'),
            const SizedBox(height: 18),

            _sectionHeader(Icons.notifications_outlined, 'ການແຈ້ງເຕືອນ'),
            const SizedBox(height: 8),
            _sectionCard([
              _toggleRow(
                icon: Icons.notifications_active_outlined,
                label: 'ຮັບການແຈ້ງເຕືອນ',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
            ]),
            const SizedBox(height: 22),

            _sectionHeader(Icons.palette_outlined, 'ການສະແດງຜົນ'),
            const SizedBox(height: 8),
            _sectionCard([
              _toggleRow(
                icon: Icons.dark_mode_outlined,
                label: 'ໂໝດມືດ',
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
              ),
              const Divider(height: 1, indent: 56),
              _infoRow(Icons.language, 'ພາສາ', 'ລາວ'),
            ]),
            const SizedBox(height: 22),

            _sectionHeader(Icons.info_outline, 'ກ່ຽວກັບແອັບ'),
            const SizedBox(height: 8),
            _sectionCard([
              _infoRow(Icons.smartphone_outlined, 'ເວີຊັນແອັບ', 'v1.0.0'),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Building blocks (shared sectioned-card style) ───────────────────────

  Widget _tipBanner(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF1A1A1A), height: 1.4)),
          ),
        ]),
      );

  Widget _sectionHeader(IconData icon, String title) => Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
      ]);

  Widget _sectionCard(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Column(children: rows),
      );

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          MgToggle(value: value, onChanged: onChanged),
        ]),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        ]),
      );
}
