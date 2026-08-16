import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/services/auth_service.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({super.key});
  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  String? _name;
  String? _phone;
  String? _profileImageUrl;
  bool _verified = false;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final data = await ApiAuthService.me();
      final u = data['user'] as Map<String, dynamic>? ?? data;
      final first = u['first_name']?.toString() ?? '';
      final last  = u['last_name']?.toString() ?? '';
      setState(() {
        _name            = '$first $last'.trim().isNotEmpty ? '$first $last'.trim() : (u['name']?.toString());
        _phone           = u['phone_number']?.toString();
        _profileImageUrl = u['profile_image_url']?.toString();
        _verified        = u['verified'] == true;
        _loadingUser     = false;
      });
    } catch (_) {
      setState(() => _loadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(children: [
          _header(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(children: [
              _card([
                _tile(Icons.person_outline, 'ຂໍ້ມູນສ່ວນຕົວ', () async {
                  final updated = await Navigator.of(context).pushNamed('/profile/edit');
                  if (updated == true) _loadUser();
                }),
                _tile(Icons.settings_outlined, 'ການຕັ້ງຄ່າ',
                    () => Navigator.of(context).pushNamed('/settings')),
                _tile(Icons.description_outlined, 'ເງື່ອນໄຂແລະຂໍ້ກຳນົດ',
                    () => Navigator.of(context).pushNamed('/terms', arguments: {'readOnly': true})),
                _tile(Icons.headset_mic_outlined, 'ສາຍດ່ວນ',
                    () => Navigator.of(context).pushNamed('/chat'), isLast: true),
              ]),
              const SizedBox(height: 16),
              _card([
                _tile(Icons.info_outline, 'ແນະນຳກ່ຽວກັບ AutoPass Lao',
                    () => Navigator.of(context).pushNamed('/about')),
                _tile(
                  Icons.logout,
                  'ອອກຈາກລະບົບ',
                  () async {
                    await ApiAuthService.logout();
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    }
                  },
                  color: AppColors.error,
                  isLast: true,
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 24,
          left: 22,
          right: 22,
          bottom: 28,
        ),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Column(children: [
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.of(context).pushNamed('/profile/edit');
              if (updated == true) _loadUser();
            },
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                  clipBehavior: Clip.antiAlias,
                  child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? Image.network(_profileImageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: AppColors.grey300, size: 44))
                      : const Icon(Icons.person, color: AppColors.grey300, size: 44),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingUser)
            const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          else
            Text(
              _name?.isNotEmpty == true ? _name! : 'AutoPass User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.white),
            ),
          const SizedBox(height: 4),
          Text(
            _phone ?? '',
            style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.85)),
          ),
          if (_verified) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                const SizedBox(width: 5),
                Text('ໄດ້ຢືນຢັນແລ້ວ',
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ]),
            ),
          ],
        ]),
      );

  // ── Menu building blocks ─────────────────────────────────────────────

  Widget _card(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.primaryLight),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      );

  Widget _tile(IconData icon, String label, VoidCallback onTap, {Color? color, bool isLast = false}) => Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color ?? AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: color ?? AppColors.black, fontWeight: FontWeight.w500, fontSize: 13.5)),
                ),
                Icon(Icons.chevron_right, color: color ?? AppColors.primary, size: 20),
              ]),
            ),
          ),
          if (!isLast) const Divider(height: 1, indent: 13, endIndent: 13, color: AppColors.primaryLight),
        ],
      );
}
