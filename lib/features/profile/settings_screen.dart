import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _notificationSound = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = 'v${info.version}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ການຕັ້ງຄ່າ'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('ທົ່ວໄປ'),
            const SizedBox(height: 8),
            _card([
              _infoRow('🌐', 'ພາສາ', value: 'ລາວ'),
              _divider(),
              _toggleRow('🔔', 'ການແຈ້ງເຕືອນ', value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v)),
              _divider(),
              _toggleRow('🔊', 'ສຽງແຈ້ງເຕືອນ', value: _notificationSound,
                  onChanged: (v) => setState(() => _notificationSound = v)),
            ]),
            const SizedBox(height: 22),

            _sectionHeader('ອື່ນໆ'),
            const SizedBox(height: 8),
            _card([
              _linkRow('🛡️', 'ນະໂຍບາຍຄວາມເປັນສ່ວນຕົວ', () => Navigator.of(context).pushNamed('/privacy-policy')),
              _divider(),
              _infoRow('📦', 'ເວີຊັນແອັບ', value: _appVersion.isNotEmpty ? _appVersion : '—'),
            ]),
            const SizedBox(height: 22),

            GestureDetector(
              onTap: () async {
                await ApiAuthService.logout();
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                }
              },
              child: Container(
                width: double.infinity,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF5C2C2), width: 1.5),
                ),
                child: Text('ອອກຈາກລະບົບ',
                    style: AppTextStyles.titleSmall.copyWith(color: AppColors.error, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Building blocks ──────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Text(title,
      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 12.5));

  Widget _card(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryLight),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      );

  Widget _divider() => const Divider(height: 1, indent: 12, endIndent: 12, color: AppColors.primaryLight);

  Widget _iconBox(String emoji) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      );

  Widget _infoRow(String emoji, String label, {required String value}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          _iconBox(emoji),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, fontSize: 13.5))),
          Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        ]),
      );

  Widget _toggleRow(String emoji, String label, {required bool value, required ValueChanged<bool> onChanged}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          _iconBox(emoji),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, fontSize: 13.5))),
          MgToggle(value: value, onChanged: onChanged),
        ]),
      );

  Widget _linkRow(String emoji, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            _iconBox(emoji),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, fontSize: 13.5))),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
          ]),
        ),
      );
}
