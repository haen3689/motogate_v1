import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _licenseNameCtrl = TextEditingController();
  final _licenseNumCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _phone;
  String? _gender;
  String? _province;
  String? _idType;
  String? _licenseType;
  DateTime? _dob;
  DateTime? _idExpiry;
  DateTime? _licenseExpiry;

  // current image URLs from server
  String? _profileImageUrl;
  String? _idCardImageUrl;
  String? _licenseImageUrl;

  // newly picked files
  File? _profileImageFile;
  File? _idCardImageFile;
  File? _licenseImageFile;

  static const _genders = ['ຊາຍ', 'ຍິງ', 'ອື່ນໆ'];
  static const _idTypes = ['national_id', 'passport'];
  static const _licTypes = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'AB',
    'ABC',
    'ABCD',
    'ABCDE'
  ];
  static const _provinces = [
    'ນະຄອນຫຼວງວຽງຈັນ',
    'ວຽງຈັນ',
    'ບໍລິຄຳໄຊ',
    'ຄຳມ່ວນ',
    'ສະຫວັນນະເຂດ',
    'ສາລະວັນ',
    'ເຊກອງ',
    'ຈຳປາສັກ',
    'ອັດຕາປື',
    'ຫຼວງພະບາງ',
    'ຫຼວງນໍ້າທາ',
    'ອຸດົມໄຊ',
    'ບໍ່ແກ້ວ',
    'ຜົ້ງສາລີ',
    'ໄຊຍະບູລີ',
    'ຊຽງຂວາງ',
    'ໄຊສົມບູນ',
    'ຮົ່ວພັນ',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _idNumberCtrl.dispose();
    _licenseNameCtrl.dispose();
    _licenseNumCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final data = await ApiAuthService.me();
      final u = data['user'] as Map<String, dynamic>? ?? data;
      setState(() {
        _phone = u['phone_number']?.toString();
        _firstNameCtrl.text = u['first_name']?.toString() ?? '';
        _lastNameCtrl.text = u['last_name']?.toString() ?? '';
        _gender =
            _genders.contains(u['gender']) ? u['gender'] as String? : null;
        _province = _provinces.contains(u['province'])
            ? u['province'] as String?
            : null;
        _districtCtrl.text = u['district']?.toString() ?? '';
        _villageCtrl.text = u['village']?.toString() ?? '';
        _idType = u['id_type']?.toString();
        _idNumberCtrl.text = u['id_number']?.toString() ?? '';
        _licenseType = u['license_type']?.toString();
        _licenseNameCtrl.text = u['license_name']?.toString() ?? '';
        _licenseNumCtrl.text = u['license_number']?.toString() ?? '';
        _profileImageUrl = u['profile_image_url']?.toString();
        _idCardImageUrl = u['id_card_image_url']?.toString();
        _licenseImageUrl = u['license_image_url']?.toString();

        final dobStr = u['date_of_birth']?.toString();
        if (dobStr != null) _dob = DateTime.tryParse(dobStr);

        final idExpStr = u['id_expiry_date']?.toString();
        if (idExpStr != null) _idExpiry = DateTime.tryParse(idExpStr);

        final licExpStr = u['license_expiry_date']?.toString();
        if (licExpStr != null) _licenseExpiry = DateTime.tryParse(licExpStr);

        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ໂຫລດຂໍ້ມູນຜິດພາດ: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource src, String field) async {
    final xf = await _picker.pickImage(source: src, imageQuality: 85);
    if (xf == null) return;
    final file = File(xf.path);
    setState(() {
      if (field == 'profile') {
        _profileImageFile = file;
      } else if (field == 'id_card')
        _idCardImageFile = file;
      else if (field == 'license') _licenseImageFile = file;
    });
  }

  Future<void> _pickDate(String field) async {
    final now = DateTime.now();
    final initial = field == 'dob'
        ? (_dob ?? DateTime(1990))
        : field == 'id_expiry'
            ? (_idExpiry ?? now.add(const Duration(days: 365 * 5)))
            : (_licenseExpiry ?? now.add(const Duration(days: 365 * 5)));
    final first = field == 'dob' ? DateTime(1950) : now;
    final last = field == 'dob' ? now : DateTime(now.year + 20);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (field == 'dob') {
        _dob = picked;
      } else if (field == 'id_expiry')
        _idExpiry = picked;
      else
        _licenseExpiry = picked;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = await ApiAuthService.updateProfile(
        firstName: _firstNameCtrl.text.trim().isNotEmpty
            ? _firstNameCtrl.text.trim()
            : null,
        lastName: _lastNameCtrl.text.trim().isNotEmpty
            ? _lastNameCtrl.text.trim()
            : null,
        gender: _gender,
        dateOfBirth: _dob != null ? _fmt(_dob!) : null,
        province: _province,
        district: _districtCtrl.text.trim().isNotEmpty
            ? _districtCtrl.text.trim()
            : null,
        village: _villageCtrl.text.trim().isNotEmpty
            ? _villageCtrl.text.trim()
            : null,
        idType: _idType,
        idNumber: _idNumberCtrl.text.trim().isNotEmpty
            ? _idNumberCtrl.text.trim()
            : null,
        idExpiryDate: _idExpiry != null ? _fmt(_idExpiry!) : null,
        licenseName: _licenseNameCtrl.text.trim().isNotEmpty
            ? _licenseNameCtrl.text.trim()
            : null,
        licenseNumber: _licenseNumCtrl.text.trim().isNotEmpty
            ? _licenseNumCtrl.text.trim()
            : null,
        licenseType: _licenseType,
        licenseExpiryDate:
            _licenseExpiry != null ? _fmt(_licenseExpiry!) : null,
        profileImage: _profileImageFile,
        idCardImage: _idCardImageFile,
        licenseImage: _licenseImageFile,
      );

      if (mounted) {
        // อัพเดต URL จาก server response ทันที + ล้าง File objects
        setState(() {
          _profileImageUrl =
              updated['profile_image_url']?.toString() ?? _profileImageUrl;
          _idCardImageUrl =
              updated['id_card_image_url']?.toString() ?? _idCardImageUrl;
          _licenseImageUrl =
              updated['license_image_url']?.toString() ?? _licenseImageUrl;
          _profileImageFile = null;
          _idCardImageFile = null;
          _licenseImageFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ບັນທຶກສຳເລັດ ✓'),
              backgroundColor: AppColors.primary),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _display(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ແກ້ໄຂໂປຣໄຟລ໌'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatarSection(),
            const SizedBox(height: 20),
            _sectionCard(
              icon: Icons.person_outline,
              title: 'ຂໍ້ມູນສ່ວນຕົວ',
              child: Column(children: [
                _row2(
                  _field('ຊື່', _firstNameCtrl, 'ຊື່'),
                  _field('ນາມສະກຸນ', _lastNameCtrl, 'ນາມສະກຸນ'),
                ),
                const SizedBox(height: 12),
                _row2(
                  _dropdown('ເພດ', _genders, _gender,
                      labels: const ['ຊາຍ', 'ຍິງ', 'ອື່ນໆ'],
                      onChanged: (v) => setState(() => _gender = v)),
                  _dateTap('ວັນເດືອນປີເກີດ', _dob, () => _pickDate('dob')),
                ),
                const SizedBox(height: 12),
                _field('ເບີໂທ (ບໍ່ສາມາດແກ້ໄຂ)', null, _phone ?? '',
                    readonly: true),
              ]),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.location_on_outlined,
              title: 'ທີ່ຢູ່',
              child: Column(children: [
                _dropdown('ແຂວງ', _provinces, _province,
                    onChanged: (v) => setState(() => _province = v)),
                const SizedBox(height: 12),
                _row2(
                  _field('ເມືອງ', _districtCtrl, 'ເມືອງ'),
                  _field('ບ້ານ', _villageCtrl, 'ບ້ານ'),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.badge_outlined,
              title: 'ບັດປະຈຳຕົວ / Passport',
              child: Column(children: [
                _row2(
                  _dropdown('ປະເພດ', _idTypes, _idType,
                      labels: const ['ບັດປະຈຳຕົວ', 'Passport'],
                      onChanged: (v) => setState(() => _idType = v)),
                  _dateTap(
                      'ວັນໝົດອາຍຸ', _idExpiry, () => _pickDate('id_expiry')),
                ),
                const SizedBox(height: 12),
                _field('ເລກບັດ', _idNumberCtrl, 'xxxxxxxxxxxxxxxxx'),
                const SizedBox(height: 12),
                _imgPicker(
                    'ຮູບບັດ', _idCardImageFile, _idCardImageUrl, 'id_card'),
              ]),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.directions_car_outlined,
              title: 'ໃບຂັບຂີ່',
              child: Column(children: [
                _row2(
                  _dropdown('ປະເພດ', _licTypes, _licenseType,
                      onChanged: (v) => setState(() => _licenseType = v)),
                  _dateTap('ວັນໝົດອາຍຸ', _licenseExpiry,
                      () => _pickDate('license_expiry')),
                ),
                const SizedBox(height: 12),
                _field('ຊື່ໃບຂັບຂີ່', _licenseNameCtrl,
                    'ຊື່ຕາມທີ່ພິມຢູ່ໃນໃບຂັບຂີ່'),
                const SizedBox(height: 12),
                _field('ເລກໃບຂັບຂີ່', _licenseNumCtrl, 'xxxxxxxxx'),
                const SizedBox(height: 12),
                _imgPicker('ຮູບໃບຂັບຂີ່', _licenseImageFile, _licenseImageUrl,
                    'license'),
              ]),
            ),
            const SizedBox(height: 24),
            _saving
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : MgButton(
                    label: 'ບັນທຶກການປ່ຽນແປງ',
                    variant: MgButtonVariant.primary,
                    onPressed: _save,
                  ),
          ],
        ),
      ),
    );
  }

  // ── Avatar section ──
  Widget _avatarSection() {
    Widget avatar;
    if (_profileImageFile != null) {
      avatar = Image.file(_profileImageFile!,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      avatar = Image.network(_profileImageUrl!,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else {
      avatar = const Icon(Icons.person, color: AppColors.white, size: 44);
    }

    return Center(
      child: Column(children: [
        GestureDetector(
          onTap: () => _showImgSourceSheet('profile'),
          child: Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: avatar,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: AppColors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('ກົດເພື່ອປ່ຽນຮູບໂປຣໄຟລ໌',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
      ]),
    );
  }

  // ── Image picker row ──
  Widget _imgPicker(String label, File? file, String? url, String field) {
    final hasImg = file != null || (url != null && url.isNotEmpty);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(label),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => _showImgSourceSheet(field),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasImg ? AppColors.primary : AppColors.primaryLight,
              width: hasImg ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImg
              ? Stack(fit: StackFit.expand, children: [
                  file != null
                      ? Image.file(file, fit: BoxFit.cover)
                      : Image.network(url!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('ປ່ຽນຮູບ',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.primary, size: 28),
                  const SizedBox(height: 6),
                  Text('ກົດເພື່ອອັບໂຫຼດ',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ]),
        ),
      ),
    ]);
  }

  void _showImgSourceSheet(String field) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined,
                color: AppColors.primary),
            title: const Text('ຖ່າຍຮູບ'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera, field);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppColors.primary),
            title: const Text('ເລືອກຈາກ Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery, field);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Helpers ──
  Widget _sectionCard(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1e9e82)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(children: [
            Icon(icon, color: AppColors.white, size: 16),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ]),
    );
  }

  Widget _row2(Widget a, Widget b) => Row(children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ]);

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: .04));

  Widget _field(String label, TextEditingController? ctrl, String hint,
      {bool readonly = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(label),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        readOnly: readonly,
        onChanged: (_) => setState(() {}),
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.grey350),
          filled: true,
          fillColor:
              readonly ? const Color(0xFFF1F5F9) : AppColors.primarySurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _dropdown(String label, List<String> values, String? current,
      {List<String>? labels, required ValueChanged<String?> onChanged}) {
    final displayLabels = labels ?? values;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(label),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        initialValue:
            (current != null && values.contains(current)) ? current : null,
        isExpanded: true,
        isDense: true,
        hint: Text('ເລືອກ',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey350)),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.primarySurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        items: List.generate(
            values.length,
            (i) => DropdownMenuItem(
                  value: values[i],
                  child: Text(displayLabels[i], style: AppTextStyles.bodySmall),
                )),
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _dateTap(String label, DateTime? date, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(label),
      const SizedBox(height: 5),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryLight),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            date != null ? _display(date) : 'ວວ/ດດ/ປປປປ',
            style: AppTextStyles.bodySmall.copyWith(
              color: date != null ? AppColors.black : AppColors.grey350,
            ),
          ),
        ),
      ),
    ]);
  }
}
