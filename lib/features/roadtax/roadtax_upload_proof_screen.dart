import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_road_tax_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import 'roadtax_step_indicator.dart';

const _warnBg = Color(0xFFFEEED7);
const _warnBorder = Color(0xFFBC770C);
final _money = NumberFormat('#,##0');

class RoadtaxUploadProofScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const RoadtaxUploadProofScreen({super.key, required this.vehicle});
  @override
  State<RoadtaxUploadProofScreen> createState() => _RoadtaxUploadProofScreenState();
}

class _RoadtaxUploadProofScreenState extends State<RoadtaxUploadProofScreen> {
  late final List<int> _years;
  int? _selectedYear;
  DateTime? _paidAt;
  DateTime? _expiredAt;
  File? _proofImage;

  bool _loadingFee = true;
  num? _fee;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _years = [now.year, now.year + 1, now.year + 2];
    _selectedYear = now.year;
    _paidAt = now;
    _expiredAt = DateTime(now.year, 12, 31);
    _loadFee();
  }

  Future<void> _loadFee() async {
    setState(() => _loadingFee = true);
    try {
      final rates = await ApiRoadTaxService.rates();
      final setting = await ApiRoadTaxService.uploadFeeSetting();
      final rate = ApiRoadTaxService.matchingRate(rates, widget.vehicle);
      final baseAmount = num.tryParse(rate?['price']?.toString() ?? '') ?? 0;
      final fee = ApiRoadTaxService.computeUploadFee(setting, baseAmount);
      if (mounted) setState(() => _fee = fee);
    } catch (_) {
      // Fee preview is best-effort here — the payment screen fetches and
      // confirms it authoritatively regardless.
    } finally {
      if (mounted) setState(() => _loadingFee = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final f = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (f != null) setState(() => _proofImage = File(f.path));
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('ຖ່າຍຮູບ'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('ເລືອກຈາກຄັງຮູບ'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final y in _years)
            ListTile(
              title: Text('$y', textAlign: TextAlign.center),
              onTap: () => Navigator.of(context).pop(y),
            ),
        ]),
      ),
    );
    if (picked != null) setState(() => _selectedYear = picked);
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onPicked(picked);
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'ເລືອກວັນທີ'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool get _valid =>
      _selectedYear != null && _paidAt != null && _expiredAt != null && _proofImage != null;

  void _next() {
    if (!_valid) return;
    Navigator.of(context).pushNamed('/roadtax/upload/payment', arguments: {
      'vehicle': widget.vehicle,
      'taxYear': _selectedYear,
      'paidAt': _paidAt,
      'expiredAt': _expiredAt,
      'proofImage': _proofImage,
    });
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

  @override
  Widget build(BuildContext context) {
    final plate = widget.vehicle['plate_number']?.toString() ?? '—';
    final province = widget.vehicle['province']?.toString();
    final plateType = widget.vehicle['plate_type']?.toString();
    final brandModel = [widget.vehicle['brand'], widget.vehicle['model']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ')
        .toUpperCase();
    final vehicleLabel =
        brandModel.isEmpty ? _typeLabel(widget.vehicle['vehicle_type']?.toString()) : brandModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ອັບໂຫລດ'),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
            children: [
              const RoadtaxStepIndicator(currentStep: 1),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  border: Border.all(color: AppColors.primaryLight),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(children: [
                  MgPlateBadge(plateNumber: plate, province: province, plateType: plateType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(vehicleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.black)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _warnBg,
                  border: Border.all(color: _warnBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, color: _warnBorder, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ຍັງບໍ່ທັນເຊື່ອມຕໍ່ກັບໜ່ວຍງານລັດ',
                          style: TextStyle(color: _warnBorder, fontSize: 11.5, fontWeight: FontWeight.w800)),
                      SizedBox(height: 3),
                      Text('ກະລຸນາອັບໂຫລດໃບຮັບເງິນຄ່າທາງທີ່ຈ່າຍແລ້ວ',
                          style: TextStyle(color: _warnBorder, fontSize: 10.5)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              Text('ເລືອກວິທີເພີ່ມຂໍ້ມູນ',
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: _methodCard(selected: true, icon: Icons.upload_outlined, label: 'ອັບໂຫລດຮູບ', sub: 'Gallery / ຖ່າຍໃໝ່')),
                const SizedBox(width: 10),
                Expanded(
                  child: _methodCard(
                    selected: false,
                    icon: Icons.qr_code_scanner,
                    label: 'ສະແກນ QR',
                    sub: 'ຈາກໃບຮັບເງິນ',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('ຄຸນສົມບັດນີ້ກຳລັງພັດທະນາ'),
                    )),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              _uploadBox(),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _quickAction(
                      icon: Icons.photo_camera_outlined,
                      label: 'ຖ່າຍຮູບ',
                      onTap: () => _pickImage(ImageSource.camera)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _quickAction(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery)),
                ),
              ]),
              const SizedBox(height: 24),
              Text('ຂໍ້ມູນຄ່າທາງ',
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _fieldLabel('ປີຄ່າທາງ', required: true)),
                const SizedBox(width: 12),
                Expanded(child: _fieldLabel('ວັນທີ່ຈ່າຍ', required: true)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: _tapField(
                    text: _selectedYear?.toString() ?? '—',
                    trailing: const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),
                    onTap: _pickYear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tapField(
                    text: _fmtDate(_paidAt),
                    trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 15),
                    onTap: () => _pickDate(_paidAt, (d) => setState(() => _paidAt = d)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _fieldLabel('ວັນໝົດອາຍຸ', required: true)),
                const SizedBox(width: 12),
                Expanded(child: _fieldLabel('ຄ່າບັນທຶກ ແລະ ຢືນຢັນ')),
              ]),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: _tapField(
                    text: _fmtDate(_expiredAt),
                    trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 15),
                    onTap: () => _pickDate(_expiredAt, (d) => setState(() => _expiredAt = d)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _loadingFee
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : Text(_fee == null ? '—' : '${_money.format(_fee!)} ກີບ',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: MgButton(
              label: 'ຖັດໄປ → ຊຳລະ ແລະ ຢືນຢັນ',
              variant: _valid ? MgButtonVariant.primary : MgButtonVariant.disabled,
              onPressed: _valid ? _next : null,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) => RichText(
        text: TextSpan(children: [
          TextSpan(
              text: text,
              style: const TextStyle(color: Color(0xFF4D4D4D), fontSize: 11.5, fontWeight: FontWeight.w600)),
          if (required)
            const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFFC0404), fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _tapField({required String text, required Widget trailing, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.black)),
            ),
            trailing,
          ]),
        ),
      );

  Widget _methodCard({
    required bool selected,
    required IconData icon,
    required String label,
    required String sub,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.primaryLight, width: selected ? 2.5 : 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 3))]
              : null,
        ),
        child: Stack(children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.grey500, size: 21),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.primary : AppColors.black)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.grey500)),
          ]),
          if (selected)
            Positioned(
              top: 0,
              right: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _quickAction({required IconData icon, required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w800)),
          ]),
        ),
      );

  Widget _uploadBox() => GestureDetector(
        onTap: _showSourcePicker,
        child: Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: _proofImage != null
              ? Stack(fit: StackFit.expand, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(_proofImage!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 8),
                  const Text('ກົດອັບໂຫລດໃບຮັບເງິນຄ່າທາງ',
                      style: TextStyle(color: AppColors.black, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  const Text('JPG, PNG · ສູງສຸດ 10MB', style: TextStyle(color: AppColors.grey500, fontSize: 10)),
                ]),
        ),
      );
}
