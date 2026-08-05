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
      body: Column(children: [
        // ── Header ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 24,
            left: 22, right: 22, bottom: 28,
          ),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(children: [
            // Avatar
            GestureDetector(
              onTap: () async {
                final updated = await Navigator.of(context).pushNamed('/profile/edit');
                if (updated == true) _loadUser();
              },
              child: Stack(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? Image.network(_profileImageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: AppColors.white, size: 40))
                        : const Icon(Icons.person, color: AppColors.white, size: 40),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Icon(Icons.edit, color: AppColors.primary, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingUser)
              const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            else
              Text(
                _name?.isNotEmpty == true ? _name! : 'MotoGate User',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white),
              ),
            const SizedBox(height: 4),
            Text(
              _phone ?? '',
              style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.8)),
            ),
          ]),
        ),

        // ── Menu ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(children: [
              _sec(Icons.person_outline, 'ບັນຊີ', [
                _tile(Icons.person_outline, 'ແກ້ໄຂໂປຣໄຟລ໌', () async {
                  final updated = await Navigator.of(context).pushNamed('/profile/edit');
                  if (updated == true) _loadUser();
                }),
                _tile(Icons.phone_android, 'ປ່ຽນເບີໂທ',
                    () => Navigator.of(context).pushNamed('/profile/change-phone')),
                _tile(Icons.directions_car, 'ພາຫະນະຂອງຂ້ອຍ',
                    () => Navigator.of(context).pushNamed('/vehicles')),
              ]),
              const SizedBox(height: 20),
              _sec(Icons.tune_outlined, 'ທົ່ວໄປ', [
                _tile(Icons.settings_outlined, 'ຕັ້ງຄ່າ',
                    () => Navigator.of(context).pushNamed('/settings')),
                _tile(Icons.headset_mic_outlined, 'ຊ່ວຍເຫຼືອ',
                    () => Navigator.of(context).pushNamed('/chat')),
              ]),
              const SizedBox(height: 24),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Center(
                    child: Text('ອອກຈາກລະບົບ',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.error)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sec(IconData icon, String t, List<Widget> items) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.grey100),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(t, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
        ]),
      ),
      ...items,
    ]),
  );

  Widget _tile(IconData ic, String t, VoidCallback tap) => ListTile(
    leading: Icon(ic, color: AppColors.primary, size: 22),
    title: Text(t, style: AppTextStyles.bodyMedium),
    trailing: const Icon(Icons.chevron_right, color: AppColors.grey300, size: 20),
    onTap: tap,
  );
}
