import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_auth_service.dart';

class LicenseSetupScreen extends StatefulWidget {
  const LicenseSetupScreen({super.key});
  @override
  State<LicenseSetupScreen> createState() => _LicenseSetupScreenState();
}

class _LicenseSetupScreenState extends State<LicenseSetupScreen> {
  final _licenseNameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _loading = false;
  bool _initializing = true;
  String? _licenseType;
  DateTime? _expiryDate;
  File? _licenseImage;

  static const _licenseTypes = ['A', 'B', 'C', 'D', 'E', 'AB', 'ABC', 'ABCD', 'ABCDE'];

  bool get _canSave =>
      _licenseNameCtrl.text.trim().isNotEmpty &&
      _licenseCtrl.text.trim().isNotEmpty &&
      _licenseType != null &&
      _expiryDate != null;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _licenseNameCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  // ຜູ້ໃຊ້ທີ່ມີຂໍ້ມູນໃບຂັບຂີ່ຢູ່ແລ້ວແຕ່ຂາດຮູບ (ເຂົ້າມາຈາກ card ໃນ ເອກະສານ) ຕ້ອງເຫັນ
  // ຂໍ້ມູນເກົ່າຂອງຕົນເອງ ບໍ່ແມ່ນຟອມຫວ່າງ — ບໍ່ດັ່ງນັ້ນຈະຕ້ອງພິມທຸກຊ່ອງໃໝ່ພຽງແຄ່ຈະ
  // ແນບຮູບ. ຄ້າງ _initializing ໄວ້ຈົນກວ່າຈະໂຫລດແລ້ວ, ເພາະ DropdownButtonFormField
  // ໃຊ້ initialValue ໄດ້ແຕ່ຕອນ build ຄັ້ງທຳອິດເທົ່ານັ້ນ.
  Future<void> _loadExisting() async {
    try {
      final u = await ApiAuthService.me();
      final type = u['license_type']?.toString();
      final expiry = DateTime.tryParse(u['license_expiry_date']?.toString() ?? '');
      if (mounted) {
        setState(() {
          _licenseNameCtrl.text = u['license_name']?.toString() ?? '';
          _licenseCtrl.text = u['license_number']?.toString() ?? '';
          _licenseType = _licenseTypes.contains(type) ? type : null;
          _expiryDate = expiry;
        });
      }
    } catch (_) {
      // ໂຫລດບໍ່ໄດ້ — ປ່ອຍເປັນຟອມຫວ່າງ, ຜູ້ໃຊ້ຍັງກົດ "ຂ້າມ" ໄດ້ຢູ່
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xfile != null) setState(() => _licenseImage = File(xfile.path));
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_canSave || _loading) return;
    setState(() => _loading = true);
    try {
      await ApiAuthService.updateProfile(
        licenseName: _licenseNameCtrl.text.trim(),
        licenseNumber: _licenseCtrl.text.trim(),
        licenseType: _licenseType,
        licenseExpiryDate: _fmtDate(_expiryDate!),
        licenseImage: _licenseImage,
      );
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
        setState(() => _loading = false);
      }
    }
  }

  void _skip() => Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ເພີ່ມຂໍ້ມູນໃບຂັບຂີ'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section tag
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  const Text('ໃບຂັບຂີ', style: AppTextStyles.titleSmall),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEEED7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ບໍ່ບັງຄັບ',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBC770C))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text("ຕື່ມຂໍ້ມູນ ຫຼື ກົດ 'ຂ້າມ' ຖ້າລູກຄ້າບໍ່ມີໃບຂັບຂີ",
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),

            // Form card
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryLight),
              ),
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('ຊື່ໃບຂັບຂີ'),
                  const SizedBox(height: 8),
                  _input(_licenseNameCtrl, 'ຊື່ຕາມທີ່ພິມຢູ່ໃນໃບຂັບຂີ'),
                  const SizedBox(height: 16),
                  _fieldLabel('ເລກໃບຂັບຂີ'),
                  const SizedBox(height: 8),
                  _input(_licenseCtrl, 'ປ້ອນເລກໃບຂັບຂີ'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('ວັນໝົດອາຍຸ'),
                            const SizedBox(height: 8),
                            _datePicker(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('ປະເພດ'),
                            const SizedBox(height: 8),
                            _typeDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Photo section
            const Text('ຮູບໃບຂັບຂີ', style: AppTextStyles.titleSmall),
            const SizedBox(height: 12),

            // Upload area
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: AspectRatio(
                aspectRatio: 1.586, // standard ID/license card proportions
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primaryLight,
                        width: 1.5,
                        style: BorderStyle.solid),
                  ),
                  child: _licenseImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.file(_licenseImage!, fit: BoxFit.cover,
                              width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.photo_camera_outlined,
                                  color: AppColors.grey400, size: 20),
                            ),
                            const SizedBox(height: 8),
                            Text('ໜ້າໃບຂັບຂີ',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text('JPG / PNG',
                                style: AppTextStyles.caption.copyWith(fontSize: 9.5)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Camera action row
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_camera_outlined,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('ກົດຖ່າຍຮູບ ຫຼື ເລືອກຈາກ Gallery',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.black, fontWeight: FontWeight.w500, fontSize: 12.5)),
                  ),
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      width: 80,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Text('ຖ່າຍຮູບ',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Info note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ℹ', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ຮູບຈະຖືກໃຊ້ verify ຂໍ້ມູນ — ຄວນຊັດ ໝູນຊ້າຍ 90° ຖ້າຈຳເປັນ',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primaryDark, fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
              MgButton(
                label: 'ບັນທຶກ ແລະ ສຳເລັດ ✓',
                variant: _canSave ? MgButtonVariant.primary : MgButtonVariant.disabled,
                onPressed: _canSave ? _save : null,
              ),
            const SizedBox(height: 12),

            // Skip button
            GestureDetector(
              onTap: _loading ? null : _skip,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryLight, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text('ຂ້າມ — ລູກຄ້າບໍ່ມີໃບຂັບຂີ',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.grey500, fontSize: 13.5)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4D4D4D)));

  Widget _input(TextEditingController ctrl, String hint) => SizedBox(
        height: 46,
        child: TextField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey350),
            filled: true,
            fillColor: AppColors.primarySurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10.5, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      );

  Widget _datePicker() => GestureDetector(
        onTap: _pickExpiry,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 8.5),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            _expiryDate != null ? _displayDate(_expiryDate!) : 'ວວ/ດດ/ປປປປ',
            style: AppTextStyles.bodySmall.copyWith(
              color: _expiryDate != null ? AppColors.black : AppColors.grey350,
              fontSize: 13,
            ),
          ),
        ),
      );

  Widget _typeDropdown() => SizedBox(
        height: 46,
        child: DropdownButtonFormField<String>(
          initialValue: _licenseType,
          isDense: true,
          isExpanded: true,
          hint: Text('ເລືອກ ▾',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey350, fontSize: 13)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.primarySurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          items: _licenseTypes
              .map((t) => DropdownMenuItem(
                  value: t, child: Text('ປະເພດ $t', style: AppTextStyles.bodySmall)))
              .toList(),
          onChanged: (v) => setState(() => _licenseType = v),
        ),
      );
}
