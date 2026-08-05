import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _idNumberCtrl  = TextEditingController();
  final _villageCtrl   = TextEditingController();
  final _picker        = ImagePicker();

  bool    _loading     = false;
  bool    _isNationalId = true;
  String? _gender;
  String? _province;
  String? _district;
  String? _phone;
  DateTime? _dob;
  DateTime? _idExpiry;
  File?   _docImage;

  static const _genders = ['ຊາຍ', 'ຍິງ', 'ອື່ນໆ'];

  static const _districts = [
    'ເມືອງຈັນທະບູລີ',
    'ເມືອງຫາດຊາຍຟອງ',
    'ເມືອງປາກງື່ມ',
    'ເມືອງນາຊາຍທອງ',
    'ເມືອງສັງທອງ',
    'ເມືອງສີໂຄດຕະບອງ',
    'ເມືອງສີສັດຕະນາກ',
    'ເມືອງໄຊເສດຖາ',
    'ເມືອງໄຊທານີ',
  ];

  static const _provinces = [
    'ແຂວງຜົ້ງສາລີ',
    'ແຂວງຫຼວງນໍ້າທາ',
    'ແຂວງບໍ່ແກ້ວ',
    'ແຂວງອຸດົມໄຊ',
    'ແຂວງຫຼວງພະບາງ',
    'ແຂວງຫົວພັນ',
    'ແຂວງໄຊຍະບູລີ',
    'ແຂວງຊຽງຂວາງ',
    'ນະຄອນຫຼວງວຽງຈັນ',
    'ແຂວງວຽງຈັນ',
    'ແຂວງບໍລິຄຳໄຊ',
    'ແຂວງຄຳມ່ວນ',
    'ແຂວງສະຫວັນນະເຂດ',
    'ແຂວງໄຊສົມບູນ',
    'ແຂວງສາລະວັນ',
    'ແຂວງເຊກອງ',
    'ແຂວງຈຳປາສັກ',
    'ແຂວງອັດຕາປື',
  ];

  bool get _valid =>
      _firstNameCtrl.text.trim().isNotEmpty &&
      _lastNameCtrl.text.trim().isNotEmpty &&
      _gender != null &&
      _dob != null &&
      _province != null &&
      _district != null &&
      _villageCtrl.text.trim().isNotEmpty &&
      _idNumberCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    ApiAuthService.me().then((u) {
      if (mounted) setState(() => _phone = u['phone_number']?.toString());
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _idNumberCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xfile != null) setState(() => _docImage = File(xfile.path));
  }

  Future<void> _pickDate({required bool isDob}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDob ? (_dob ?? DateTime(1990)) : (_idExpiry ?? now.add(const Duration(days: 365 * 5))),
      firstDate: isDob ? DateTime(1950) : now,
      lastDate: isDob ? now : DateTime(now.year + 20),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isDob ? _dob = picked : _idExpiry = picked);
  }

  Future<void> _next() async {
    if (!_valid || _loading) return;
    setState(() => _loading = true);
    try {
      await ApiAuthService.updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        gender: _gender,
        dateOfBirth: _fmtDate(_dob!),
        province: _province,
        district: _district ?? '',
        village: _villageCtrl.text.trim(),
        idType: _isNationalId ? 'national_id' : 'passport',
        idNumber: _idNumberCtrl.text.trim(),
        idExpiryDate: _idExpiry != null ? _fmtDate(_idExpiry!) : null,
        idCardImage: _docImage,
      );
      if (mounted) Navigator.of(context).pushNamed('/license/setup');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: const MgHeader(title: 'ເພີ່ມຂໍ້ມູນລູກຄ້າ', showBack: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: ຂໍ້ມູນສ່ວນຕົວ ─────────────────────────────────
            _sectionCard(
              icon: Icons.person_outline_rounded,
              title: 'ຂໍ້ມູນສ່ວນຕົວ',
              children: [
                // ID type switcher
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF7F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    _tab('ບັດປະຈຳຕົວ', _isNationalId, () => setState(() => _isNationalId = true)),
                    _tab('Passport', !_isNationalId, () => setState(() => _isNationalId = false)),
                  ]),
                ),
                const SizedBox(height: 14),

                // ຊື່ | ນາມສະກຸນ
                _row2(
                  _field('ຊື່ແທ້', req: true, child: _input(_firstNameCtrl, 'ປ້ອນຊື່ແທ້')),
                  _field('ນາມສະກຸນ', req: true, child: _input(_lastNameCtrl, 'ປ້ອນນາມສະກຸນ')),
                ),
                const SizedBox(height: 12),

                // ເພດ | ວັນເດືອນປີເກີດ
                _row2(
                  _field('ເພດ', req: true, child: _dropdown(
                    value: _gender, hint: 'ເລືອກ', items: _genders,
                    onChanged: (v) => setState(() => _gender = v),
                  )),
                  _field('ວັນເດືອນປີເກີດ', req: true, child: _dateTile(
                    value: _dob != null ? _displayDate(_dob!) : null,
                    hint: '01/01/1995',
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickDate(isDob: true),
                  )),
                ),
                const SizedBox(height: 12),

                // ເລກບັດ | ວັນໝົດອາຍຸ
                _row2(
                  _field(_isNationalId ? 'ເລກບັດປະຈຳຕົວ' : 'ເລກ Passport', req: true,
                    child: _input(_idNumberCtrl, '1234567890123')),
                  _field('ວັນໝົດອາຍຸ', req: false, child: _dateTile(
                    value: _idExpiry != null ? _displayDate(_idExpiry!) : null,
                    hint: '31/12/2028',
                    icon: Icons.event_outlined,
                    onTap: () => _pickDate(isDob: false),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Section 2: ທີ່ຢູ່ ──────────────────────────────────────────
            _sectionCard(
              icon: Icons.location_on_outlined,
              title: 'ທີ່ຢູ່',
              children: [
                // ແຂວງ | ເບີໂທ
                _row2(
                  _field('ແຂວງ', req: true, child: _dropdown(
                    value: _province, hint: 'ເລືອກ', items: _provinces,
                    onChanged: (v) => setState(() => _province = v),
                  )),
                  _field('ເບີໂທ', req: false, child: _readonlyField(_phone ?? '')),
                ),
                const SizedBox(height: 12),

                // ເມືອງ | ບ້ານ
                _row2(
                  _field('ເມືອງ', req: true, child: _dropdown(
                    value: _district, hint: 'ເລືອກ', items: _districts,
                    onChanged: (v) => setState(() => _district = v),
                  )),
                  _field('ບ້ານ', req: true, child: _input(_villageCtrl, 'ປ້ອນຊື່ບ້ານ')),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Section 3: ຮູບເອກະສານ ────────────────────────────────────
            _sectionCard(
              icon: Icons.credit_card_outlined,
              title: 'ຮູບເອກະສານ',
              children: [
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: AspectRatio(
                    aspectRatio: 1.586, // standard ID card proportions
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLight, width: 1.5),
                      ),
                      child: _docImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(_docImage!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Container(
                                width: 38, height: 30,
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.credit_card_outlined, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(height: 8),
                              Text('ໜ້າບັດ / Passport',
                                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.black)),
                              const SizedBox(height: 2),
                              Text('ຖ່າຍ ຫຼື ອັບໂຫລດ • JPG PNG',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                            ]),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _uploadBtn(Icons.photo_library_outlined, 'Gallery', () => _pickImage(ImageSource.gallery))),
                  const SizedBox(width: 10),
                  Expanded(child: _uploadBtn(Icons.camera_alt_outlined, 'ຖ່າຍຮູບ', () => _pickImage(ImageSource.camera))),
                ]),
              ],
            ),
            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────────────────
            _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : MgButton(
                    label: 'ບັນທຶກ ແລະ ຖັດໄປ →',
                    variant: _valid ? MgButtonVariant.primary : MgButtonVariant.disabled,
                    onPressed: _valid ? _next : null,
                  ),
          ],
        ),
      ),
    );
  }

  // ── Layout helpers ────────────────────────────────────────────────────────

  Widget _sectionCard({required IconData icon, required String title, required List<Widget> children}) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.primary, size: 17),
            ),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
          const SizedBox(height: 14),
          Divider(color: AppColors.primaryLight.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  Widget _row2(Widget a, Widget b) => Row(children: [
    Expanded(child: a), const SizedBox(width: 12), Expanded(child: b),
  ]);

  Widget _field(String label, {required bool req, required Widget child}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          if (req) const Text(' *', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFFFC0404))),
        ]),
        const SizedBox(height: 6),
        child,
      ]);

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
          fontSize: 13.5, fontWeight: FontWeight.w700,
          color: active ? AppColors.white : AppColors.grey500)),
      ),
    ),
  );

  Widget _input(TextEditingController ctrl, String hint) => SizedBox(
    height: 46,
    child: TextField(
      controller: ctrl,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.black),
      decoration: _deco(hint),
    ),
  );

  Widget _readonlyField(String value) => Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 10.5),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.primaryLight, width: 1.5),
    ),
    alignment: Alignment.centerLeft,
    child: Text(
      value.isNotEmpty ? value : '020xxxxxxxx',
      style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w500,
        color: value.isNotEmpty ? AppColors.black : AppColors.grey350),
    ),
  );

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) =>
      SizedBox(
        height: 46,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isDense: true,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: AppColors.grey350)),
          decoration: _deco(null),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22),
          items: items.map((t) => DropdownMenuItem(
            value: t,
            child: Text(t, style: const TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: onChanged,
        ),
      );

  Widget _dateTile({String? value, required String hint, required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10.5),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
          ),
          child: Row(children: [
            Expanded(child: Text(
              value ?? hint,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: value != null ? AppColors.black : AppColors.grey350),
            )),
            Icon(icon, color: AppColors.primary, size: 18),
          ]),
        ),
      );

  Widget _uploadBtn(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ),
  );

  InputDecoration _deco(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: AppColors.grey350),
    filled: true,
    fillColor: AppColors.primarySurface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
  );
}
