import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_vehicle_service.dart';
import '../../core/services/coach_mark_tour.dart';
import '../../core/services/plate_type_cache.dart';
import '../../core/models/plate_type_model.dart';

class ScanOcrScreen extends StatefulWidget {
  const ScanOcrScreen({super.key});
  @override
  State<ScanOcrScreen> createState() => _ScanOcrScreenState();
}

class _ScanOcrScreenState extends State<ScanOcrScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _saving = false;

  // ── Controllers ────────────────────────────────────────────────────────────
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _chassisCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _seatCountCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _vehicleType;
  String? _plateType;
  String? _province;
  String? _usageType;
  String? _fuelType;
  String? _axleCount;
  String? _cylinderCount;
  DateTime? _registrationExpiryDate;
  List<PlateTypeModel> _plateTypes = [];

  static const _provinces = [
    'ນະຄອນຫຼວງວຽງຈັນ',
    'ຜົ້ງສາລີ',
    'ຫຼວງນ້ຳທາ',
    'ອຸດົມໄຊ',
    'ບໍ່ແກ້ວ',
    'ຫຼວງພະບາງ',
    'ຫົວພັນ',
    'ໄຊຍະບູລີ',
    'ຊຽງຂວາງ',
    'ວຽງຈັນ',
    'ບໍລິຄຳໄຊ',
    'ຄຳມ່ວນ',
    'ສະຫວັນນະເຂດ',
    'ສາລະວັນ',
    'ເຊກອງ',
    'ຈຳປາສັກ',
    'ອັດຕະປື',
    'ໄຊສົມບູນ',
  ];
  static const _usageTypes = ['ນຳໃຊ້ສ່ວນຕົວ', 'ນຳໃຊ້ທຸລະກິດ'];
  static const _fuelTypes = ['ແອັດຊັງ', 'ກາຊ່ວນ', 'ໄຟຟ້າ'];
  static const _axleCounts = [
    '2 ລໍ້',
    '4 ລໍ້',
    '6 ລໍ້',
    '8 ລໍ້',
    '10 ລໍ້',
    '12 ລໍ້'
  ];
  static const _cylinderCounts = [
    '1 ສູບ',
    '2 ສູບ',
    '3 ສູບ',
    '4 ສູບ',
    '6 ສູບ',
    '8 ສູບ',
    '12 ສູບ'
  ];

  File? _frontImage;
  File? _backImage;
  File? _vehiclePhoto;
  File? _transportBooklet;

  // Matches the official 8-category vehicle type list.
  static const _types = [
    {'value': 'motorcycle', 'label': 'ລົດຈັກ', 'icon': Icons.motorcycle},
    {'value': 'car', 'label': 'ລົດເກັ່ງ', 'icon': Icons.directions_car},
    {
      'value': 'pickup',
      'label': 'ລົດກະບະ',
      'icon': Icons.directions_car_filled
    },
    {'value': 'suv', 'label': 'ລົດຈິບ', 'icon': Icons.terrain},
    {'value': 'van', 'label': 'ລົດຕູ້', 'icon': Icons.airport_shuttle},
    {'value': 'bus', 'label': 'ລົດເມ', 'icon': Icons.directions_bus},
    {'value': 'towtruck', 'label': 'ລົດລາກ', 'icon': Icons.car_repair},
    {'value': 'trailer', 'label': 'ລົດພ່ວງ', 'icon': Icons.rv_hookup},
  ];

  static const _tourSeenPrefKey = 'manual_entry_tour_seen';
  final _tourKeyBasic = GlobalKey();
  final _tourKeyRegistration = GlobalKey();
  final _tourKeyPhotos = GlobalKey();
  final _tourKeyTechnical = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadPlateTypes();
    _maybeStartTour();
  }

  Future<void> _maybeStartTour() =>
      CoachMarkTour.maybeStart(prefKey: _tourSeenPrefKey, start: _startTour);

  void _startTour() {
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase(
      [_tourKeyBasic, _tourKeyRegistration, _tourKeyPhotos, _tourKeyTechnical],
    );
  }

  Future<void> _loadPlateTypes() async {
    await PlateTypeCache.instance.load();
    if (mounted) {
      setState(() => _plateTypes = PlateTypeCache.instance.all()
        ..sort((a, b) => a.name.compareTo(b.name)));
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _engineCtrl.dispose();
    _chassisCtrl.dispose();
    _ccCtrl.dispose();
    _ownerNameCtrl.dispose();
    _seatCountCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  bool get _valid => _plateCtrl.text.trim().isNotEmpty && _vehicleType != null;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    try {
      final created = await ApiVehicleService.create(
        plateNumber: _plateCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        year: _yearCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        vehicleType: _vehicleType!,
        engineNumber: _engineCtrl.text.trim(),
        chassisNumber: _chassisCtrl.text.trim(),
        cc: _ccCtrl.text.trim(),
        province: _province,
        plateType: _plateType,
        usageType: _usageType,
        ownerName: _ownerNameCtrl.text.trim(),
        fuelType: _fuelType,
        seatCount: _seatCountCtrl.text.trim(),
        axleCount: _axleCount,
        cylinderCount: _cylinderCount,
        weight: _weightCtrl.text.trim(),
        registrationExpiryDate: _registrationExpiryDate == null
            ? null
            : '${_registrationExpiryDate!.year.toString().padLeft(4, '0')}-'
                '${_registrationExpiryDate!.month.toString().padLeft(2, '0')}-'
                '${_registrationExpiryDate!.day.toString().padLeft(2, '0')}',
        registrationFront: _frontImage,
        registrationBack: _backImage,
        frontPhoto: _vehiclePhoto,
        transportBooklet: _transportBooklet,
      );
      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..pop(true);
        Navigator.of(context).pushNamed('/vehicle/pay-fee', arguments: created);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
        setState(() => _saving = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: MgHeader(title: 'ກອກຂໍ້ມູນດ້ວຍຕົນເອງ', actions: [
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
      body: _buildForm(),
    );
  }

  // ── Form view (sectioned redesign) ────────────────────────────────────────
  Widget _buildForm() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Tip banner ──
          _tipBanner(
              'ຕື່ມສະເພາະ "ປ້າຍທະບຽນ" ແລະ "ປະເພດລົດ" ກໍ່ພຽງພໍ ອັນອື່ນຕື່ມພາຍຫຼັງໄດ້'),
          const SizedBox(height: 18),

          // ── Plate badge preview ──
          Center(
            child: Builder(builder: (_) {
              final cache = PlateTypeCache.instance;
              final bg = cache.bgColor(_plateType);
              final fg = cache.fgColor(_plateType);
              final border = cache.borderColor(_plateType);
              final showProv = cache.showProvince(_plateType);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 2),
                ),
                child: Column(children: [
                  if (showProv)
                    Text(
                      _province ?? 'ນະຄອນຫຼວງວຽງຈັນ',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                    ),
                  if (showProv) const SizedBox(height: 2),
                  Text(
                    _plateCtrl.text.isNotEmpty ? _plateCtrl.text : 'ທທ 0000',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: fg,
                        letterSpacing: 2),
                  ),
                ]),
              );
            }),
          ),
          const SizedBox(height: 24),

          // ── Section: Basic vehicle info ──
          _sectionHeader(Icons.directions_car_outlined, 'ຂໍ້ມູນລົດພື້ນຖານ',
              tourKey: _tourKeyBasic,
              tourDescription: 'ຕື່ມຍີ່ຫໍ້, ລຸ້ນ, ປະເພດລົດ, ສີ ແລະ ປີຜະລິດ'),
          const SizedBox(height: 14),
          _row2(
            _field('ຍີ່ຫໍ້', _brandCtrl, 'TOYOTA'),
            _field('ລຸ້ນ', _modelCtrl, 'REVO'),
          ),
          const SizedBox(height: 12),
          _row2(
            _typeDropdown(),
            _field('ສີ', _colorCtrl, 'ສີຂາວ'),
          ),
          const SizedBox(height: 12),
          _field('ປີຜະລິດ', _yearCtrl, '2022', numeric: true),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEF2F2), height: 1),
          const SizedBox(height: 20),

          // ── Section: Registration info ──
          _sectionHeader(Icons.badge_outlined, 'ຂໍ້ມູນທະບຽນ',
              tourKey: _tourKeyRegistration,
              tourDescription: 'ໃສ່ "ປ້າຍທະບຽນ" — ນີ້ແມ່ນຊ່ອງດຽວທີ່ຈຳເປັນ'),
          const SizedBox(height: 14),
          _row2(
            _field('ປ້າຍທະບຽນ', _plateCtrl, 'ທທ 1234',
                caps: true, required: true),
            _plateTypeDropdown(),
          ),
          const SizedBox(height: 12),
          _row2(
            _simpleDropdown('ແຂວງ', _province, _provinces,
                (v) => setState(() => _province = v)),
            _field(
                'ຊື່ເຈົ້າຂອງລົດ (ຕາມທະບຽນ)', _ownerNameCtrl, 'ຊື່ຕາມປື້ມທະບຽນ'),
          ),
          const SizedBox(height: 12),
          _dateField('ວັນໝົດອາຍຸທະບຽນ', _registrationExpiryDate,
              (d) => setState(() => _registrationExpiryDate = d)),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEF2F2), height: 1),
          const SizedBox(height: 20),

          // ── Section: Registration photos ──
          _sectionHeader(Icons.photo_camera_outlined, 'ຮູບພາບປື້ມທະບຽນລົດ',
              tourKey: _tourKeyPhotos,
              tourDescription: 'ຖ່າຍຮູບໜ້າ-ຫຼັງຂອງປື້ມທະບຽນລົດ (ບໍ່ບັງຄັບ)'),
          const SizedBox(height: 14),
          _docUploadLabel('ໃບທະບຽນລົດ (ໜ້າ)'),
          const SizedBox(height: 6),
          _docUploadBox(_frontImage, () async {
            final f = await ImagePicker()
                .pickImage(source: ImageSource.camera, imageQuality: 80);
            if (f != null) setState(() => _frontImage = File(f.path));
          }),
          const SizedBox(height: 12),
          _docUploadLabel('ຂໍ້ມູນປື້ມເຫລືອງ'),
          const SizedBox(height: 6),
          _docUploadBox(_backImage, () async {
            final f = await ImagePicker()
                .pickImage(source: ImageSource.camera, imageQuality: 80);
            if (f != null) setState(() => _backImage = File(f.path));
          }),
          const SizedBox(height: 12),
          _docUploadLabel('ຮູບລົດ (ພາຍນອກ)'),
          const SizedBox(height: 6),
          _docUploadBox(_vehiclePhoto, () async {
            final f = await ImagePicker()
                .pickImage(source: ImageSource.camera, imageQuality: 80);
            if (f != null) setState(() => _vehiclePhoto = File(f.path));
          }),
          const SizedBox(height: 12),
          _docUploadLabel('ປື້ມຂົນສົ່ງ'),
          const SizedBox(height: 6),
          _docUploadBox(_transportBooklet, () async {
            final f = await ImagePicker()
                .pickImage(source: ImageSource.camera, imageQuality: 80);
            if (f != null) setState(() => _transportBooklet = File(f.path));
          }),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEF2F2), height: 1),
          const SizedBox(height: 20),

          // ── Section: Technical info ──
          _sectionHeader(Icons.settings_outlined, 'ຂໍ້ມູນເຕັກນິກ',
              tourKey: _tourKeyTechnical,
              tourDescription:
                  'ລາຍລະອຽດເຕັກນິກຂອງລົດ — ຕື່ມພາຍຫຼັງໄດ້ຖ້າຍັງບໍ່ຮູ້',
              tourIsLast: true),
          const SizedBox(height: 14),
          _row2(
            _simpleDropdown('ປະເພດການນຳໃຊ້', _usageType, _usageTypes,
                (v) => setState(() => _usageType = v)),
            _simpleDropdown('ປະເພດເຄື່ອງຈັກ', _fuelType, _fuelTypes,
                (v) => setState(() => _fuelType = v)),
          ),
          const SizedBox(height: 12),
          _row2(
            _field('ຄວາມແຮງ (CC)', _ccCtrl, '2500', numeric: true),
            _field('ຈຳນວນບ່ອນນັ່ງ', _seatCountCtrl, '4', numeric: true),
          ),
          const SizedBox(height: 12),
          _row2(
            _simpleDropdown('ຈຳນວນເພົາ', _axleCount, _axleCounts,
                (v) => setState(() => _axleCount = v)),
            _simpleDropdown('ຈຳນວນສູບ', _cylinderCount, _cylinderCounts,
                (v) => setState(() => _cylinderCount = v)),
          ),
          const SizedBox(height: 12),
          _field('ນ້ຳໜັກລົດ (ຕັນ)', _weightCtrl, 'ເຊັ່ນ: 5', numeric: true),
          const SizedBox(height: 12),
          _row2(
            _field('ເລກຈັກ', _engineCtrl, '0122445M01245', caps: true),
            _field('ເລກຖັງ (VIN)', _chassisCtrl, '1250122445M01245',
                caps: true),
          ),
          const SizedBox(height: 28),

          // ── Save button ──
          _saving
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : MgButton(
                  label: 'ບັນທຶກຂໍ້ມູນລົດ',
                  variant: _valid
                      ? MgButtonVariant.primary
                      : MgButtonVariant.disabled,
                  onPressed: _valid ? _save : null,
                ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'ບໍ່ຈຳເປັນຕ້ອງຕື່ມຄົບທຸກຊ່ອງ ສາມາດແກ້ໄຂເພີ່ມພາຍຫຼັງໄດ້',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
            ),
          ),
        ]),
      );

  // ── Form helpers ──────────────────────────────────────────────────────────
  Widget _tipBanner(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lightbulb_outline,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall
                    .copyWith(color: const Color(0xFF1A1A1A), height: 1.4)),
          ),
        ]),
      );

  Widget _sectionHeader(IconData icon, String title,
      {GlobalKey? tourKey, String? tourDescription, bool tourIsLast = false}) {
    final header = Row(children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: AppTextStyles.titleSmall
              .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
    ]);
    if (tourKey == null) return header;
    return Showcase(
      key: tourKey,
      title: title,
      description: tourDescription ?? '',
      targetPadding: const EdgeInsets.symmetric(vertical: 4),
      tooltipActions:
          tourIsLast ? CoachMarkTour.lastStepActions(context) : null,
      child: header,
    );
  }

  Widget _row2(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  Widget _field(String label, TextEditingController ctrl, String hint,
          {bool caps = false, bool numeric = false, bool required = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(
          text: TextSpan(children: [
            TextSpan(
                text: label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155))),
            if (required)
              const TextSpan(
                  text: ' *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.red)),
          ]),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          textCapitalization:
              caps ? TextCapitalization.characters : TextCapitalization.none,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFADB5BD)),
            filled: true,
            fillColor: AppColors.primarySurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFD0EEEC), width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFD0EEEC), width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ]);

  Widget _typeDropdown() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ປະເພດ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _vehicleType,
          isExpanded: true,
          hint: const Text('ເລືອກ',
              style: TextStyle(fontSize: 14, color: Color(0xFFADB5BD))),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.primarySurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFD0EEEC), width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFD0EEEC), width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
          ),
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          items: _types
              .map((t) => DropdownMenuItem(
                    value: t['value'] as String,
                    child: Text(t['label'] as String,
                        style: const TextStyle(fontSize: 15)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _vehicleType = v),
        ),
      ]);

  Widget _plateTypeDropdown() {
    final selected = _plateTypes.where((pt) => pt.plateCode == _plateType).toList();
    final current = selected.isEmpty ? null : selected.first;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ປະເພດປ້າຍ',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: _showPlateTypeModal,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD0EEEC), width: 1.5),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                current?.name ?? 'ເລືອກ',
                style: TextStyle(
                    fontSize: 14,
                    color: current == null ? const Color(0xFFADB5BD) : const Color(0xFF1A1A1A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.expand_more, color: Color(0xFF94A3B8), size: 20),
          ]),
        ),
      ),
    ]);
  }

  /// Renders the plate number the user actually typed (falling back to a
  /// placeholder like the top preview does) on top of [pt]'s colors — so
  /// picking a plate type shows exactly how *this* plate would look, not
  /// just an abstract color swatch.
  Widget _plateSwatch(PlateTypeModel pt, {required double width, required double height}) {
    final plateText = _plateCtrl.text.isNotEmpty ? _plateCtrl.text : 'ທທ 0000';
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: pt.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: pt.borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pt.showProvince)
            Text(_province ?? 'ນະຄອນຫຼວງວຽງຈັນ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: pt.fgColor, fontWeight: FontWeight.w700, fontSize: 7)),
          Text(plateText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: pt.fgColor, fontWeight: FontWeight.w900, fontSize: height * 0.36)),
        ],
      ),
    );
  }

  void _showPlateTypeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('ເລືອກປະເພດປ້າຍ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
            ),
          ),
          Flexible(
            child: _plateTypes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('ຍັງບໍ່ມີຂໍ້ມູນປະເພດປ້າຍ', style: TextStyle(color: Color(0xFF94A3B8))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _plateTypes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (_, i) {
                      final pt = _plateTypes[i];
                      final isSelected = pt.plateCode == _plateType;
                      return ListTile(
                        onTap: () {
                          setState(() => _plateType = pt.plateCode);
                          Navigator.of(ctx).pop();
                        },
                        leading: _plateSwatch(pt, width: 84, height: 46),
                        title: Text(pt.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary)
                            : null,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _simpleDropdown(String label, String? value, List<String> items,
          ValueChanged<String?> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: const Text('ເລືອກ',
              style: TextStyle(fontSize: 14, color: Color(0xFFADB5BD))),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.primarySurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFD0EEEC), width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFD0EEEC), width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
          ),
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          items: items
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v,
                        style: const TextStyle(fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ]);

  Widget _dateField(
          String label, DateTime? value, ValueChanged<DateTime?> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(1990),
              lastDate: DateTime(now.year + 20),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD0EEEC), width: 1.5),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  value == null
                      ? 'ເລືອກວັນທີ'
                      : '${value.day.toString().padLeft(2, '0')}/'
                          '${value.month.toString().padLeft(2, '0')}/'
                          '${value.year}',
                  style: TextStyle(
                      fontSize: 15,
                      color: value == null
                          ? const Color(0xFFADB5BD)
                          : const Color(0xFF1A1A1A)),
                ),
              ),
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.primary, size: 18),
            ]),
          ),
        ),
      ]);

  Widget _docUploadLabel(String label) => Text(label,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)));

  Widget _docUploadBox(File? file, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFD0EEEC),
                width: 1.5,
                style: file == null ? BorderStyle.none : BorderStyle.solid),
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(file,
                      fit: BoxFit.cover, width: double.infinity),
                )
              : Row(children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 36,
                    height: 30,
                    decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.document_scanner_outlined,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Text('ອັບໂຫລດຮູບ',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8C8C8C),
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.upload, color: AppColors.primary, size: 20),
                  const SizedBox(width: 16),
                ]),
        ),
      );
}
