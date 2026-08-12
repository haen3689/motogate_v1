import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/services/api_auth_service.dart';
import '../../core/services/api_vehicle_service.dart';
import '../../core/services/plate_type_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({super.key, required this.vehicle});

  final Map<String, dynamic> vehicle;

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Map<String, dynamic> _vehicle;
  bool _shareLoading = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  bool get _isOwner => _vehicle['is_owner'] as bool? ?? true;

  List<Map<String, dynamic>> get _sharedUsers =>
      (_vehicle['shared_users'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  Future<void> _addSharedUser() async {
    final controller = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ເພີ່ມຜູ້ໃຊ້ສຳຮອງ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ຜູ້ໃຊ້ຕ້ອງລົງທະບຽນແອັບ MotoGate ໄວ້ກ່ອນແລ້ວ ຈິ່ງຈະເພີ່ມໄດ້',
              style: TextStyle(fontSize: 12, color: AppColors.grey400),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ເບີໂທລະສັບ',
                hintText: '+856 20 XXXX XXXX',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ຍົກເລີກ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('ເພີ່ມ'),
          ),
        ],
      ),
    );
    if (phone == null || phone.isEmpty || !mounted) return;

    setState(() => _shareLoading = true);
    try {
      final updated = await ApiVehicleService.shareVehicle(_vehicle['id'], phone);
      if (mounted) setState(() => _vehicle = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is DioException
              ? ApiAuthService.errorMessage(e)
              : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _shareLoading = false);
    }
  }

  Future<void> _removeSharedUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ຖອດຜູ້ໃຊ້ສຳຮອງ'),
        content: Text('ຖອດ "${user['name'] ?? user['phone_number']}" ອອກຈາກລົດຄັນນີ້?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ຍົກເລີກ')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ຖອດອອກ')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _shareLoading = true);
    try {
      final updated =
          await ApiVehicleService.unshareVehicle(_vehicle['id'], user['id']);
      if (mounted) setState(() => _vehicle = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is DioException
              ? ApiAuthService.errorMessage(e)
              : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _shareLoading = false);
    }
  }

  String? _formatDate(String? iso, {bool withTime = false}) {
    if (iso == null || iso.isEmpty) return null;
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (!withTime) return date;
    return '$date ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
    final brand = _vehicle['brand']?.toString() ?? '';
    final model = _vehicle['model']?.toString() ?? '';
    final plateNumber = _vehicle['plate_number']?.toString();
    final type = _typeLabel(_vehicle['vehicle_type']?.toString());
    final frontUrl = _vehicle['registration_front_url']?.toString();
    final backUrl = _vehicle['registration_back_url']?.toString();
    final vehiclePhotoUrl = _vehicle['front_photo_url']?.toString();
    final transportBookletUrl = _vehicle['transport_booklet_url']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ລາຍລະອຽດລົດ'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _VehicleDetailPlateBox(
                plateNumber: plateNumber,
                province: _vehicle['province']?.toString(),
                plateType: _vehicle['plate_type']?.toString(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(children: [
                Text([brand, model].where((s) => s.isNotEmpty).join(' '),
                    style: AppTextStyles.h3, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                MgBadge(label: type, variant: MgBadgeVariant.success),
              ]),
            ),
            const SizedBox(height: 28),

            _sectionHeader(Icons.directions_car_outlined, 'ຂໍ້ມູນລົດພື້ນຖານ'),
            const SizedBox(height: 8),
            _sectionCard([
              _infoRow('ຍີ່ຫໍ້', brand),
              _infoRow('ລຸ້ນ', model),
              _infoRow('ສີ', _vehicle['color']?.toString()),
              _infoRow('ປີຜະລິດ', _vehicle['year']?.toString()),
            ]),
            const SizedBox(height: 22),

            _sectionHeader(Icons.badge_outlined, 'ຂໍ້ມູນທະບຽນ'),
            const SizedBox(height: 8),
            _sectionCard([
              _infoRow('ປະເພດປ້າຍທະບຽນ', _vehicle['plate_type']?.toString()),
              _infoRow('ແຂວງ', _vehicle['province']?.toString()),
              _infoRow('ຊື່ເຈົ້າຂອງລົດ', _vehicle['owner_name']?.toString()),
              _infoRow('ວັນໝົດອາຍຸທະບຽນ',
                  _formatDate(_vehicle['registration_expiry_date']?.toString())),
            ]),
            const SizedBox(height: 22),

            _sectionHeader(Icons.settings_outlined, 'ຂໍ້ມູນເຕັກນິກ'),
            const SizedBox(height: 8),
            _sectionCard([
              _infoRow('ຄວາມແຮງ (CC)', _vehicle['cc']?.toString()),
              _infoRow('ເລກຈັກ', _vehicle['engine_number']?.toString()),
              _infoRow('ເລກຖັງ (VIN)', _vehicle['chassis_number']?.toString()),
              _infoRow('ການນຳໃຊ້', _vehicle['usage_type']?.toString()),
              _infoRow('ປະເພດເຄື່ອງຈັກ', _vehicle['fuel_type']?.toString()),
              _infoRow('ຈຳນວນບ່ອນນັ່ງ', _vehicle['seat_count']?.toString()),
              _infoRow('ຈຳນວນເພົາ', _vehicle['axle_count']?.toString()),
              _infoRow('ຈຳນວນສູບ', _vehicle['cylinder_count']?.toString()),
            ]),

            if (frontUrl != null || backUrl != null) ...[
              const SizedBox(height: 22),
              _sectionHeader(Icons.photo_camera_outlined, 'ຮູບພາບປື້ມທະບຽນລົດ'),
              const SizedBox(height: 8),
              Row(children: [
                if (frontUrl != null)
                  Expanded(child: _photoBox(frontUrl)),
                if (frontUrl != null && backUrl != null)
                  const SizedBox(width: 12),
                if (backUrl != null)
                  Expanded(child: _photoBox(backUrl)),
              ]),
            ],

            if (vehiclePhotoUrl != null || transportBookletUrl != null) ...[
              const SizedBox(height: 22),
              _sectionHeader(Icons.directions_car_filled_outlined, 'ຮູບລົດ ແລະ ປື້ມຂົນສົ່ງ'),
              const SizedBox(height: 8),
              Row(children: [
                if (vehiclePhotoUrl != null)
                  Expanded(child: _photoBox(vehiclePhotoUrl)),
                if (vehiclePhotoUrl != null && transportBookletUrl != null)
                  const SizedBox(width: 12),
                if (transportBookletUrl != null)
                  Expanded(child: _photoBox(transportBookletUrl)),
              ]),
            ],

            if (_isOwner) ...[
              const SizedBox(height: 22),
              _sectionHeader(Icons.people_outline, 'ຜູ້ໃຊ້ສຳຮອງ'),
              const SizedBox(height: 8),
              _sharedUsersCard(),
            ],
            const SizedBox(height: 22),

            _sectionHeader(Icons.info_outline, 'ຂໍ້ມູນລະບົບ'),
            const SizedBox(height: 8),
            _sectionCard([
              _infoRow('ວັນທີລົງທະບຽນ', _formatDate(_vehicle['created_at']?.toString(), withTime: true)),
              _infoRow('ອັບເດດລ່າສຸດ', _formatDate(_vehicle['updated_at']?.toString(), withTime: true)),
              _infoRow('ID', _vehicle['id']?.toString()),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) => Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.titleSmall
                .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
      ]);

  Widget _sectionCard(List<Widget> rows) {
    final visible = rows.where((w) => w is! SizedBox).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.grey100),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(children: visible),
    );
  }

  Widget _sharedUsersCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.grey100),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sharedUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('ຍັງບໍ່ມີຜູ້ໃຊ້ສຳຮອງ',
                  style: TextStyle(color: AppColors.grey400, fontSize: 13)),
            )
          else
            ..._sharedUsers.map((u) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: AppColors.grey400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((u['name'] as String?)?.isNotEmpty == true
                                    ? u['name'] as String
                                    : 'ຜູ້ໃຊ້',
                                style: AppTextStyles.bodyMedium),
                            Text(u['phone_number']?.toString() ?? '',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.grey400)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onPressed: _shareLoading ? null : () => _removeSharedUser(u),
                      ),
                    ],
                  ),
                )),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _shareLoading ? null : _addSharedUser,
              icon: _shareLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add, size: 18),
              label: const Text('ເພີ່ມຜູ້ໃຊ້ສຳຮອງ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBox(String url) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url,
            height: 110, width: double.infinity, fit: BoxFit.cover),
      );

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _VehicleDetailPlateBox extends StatefulWidget {
  const _VehicleDetailPlateBox({required this.plateNumber, this.province, this.plateType});

  final String? plateNumber;
  final String? province;
  final String? plateType;

  @override
  State<_VehicleDetailPlateBox> createState() => _VehicleDetailPlateBoxState();
}

class _VehicleDetailPlateBoxState extends State<_VehicleDetailPlateBox> {
  @override
  void initState() {
    super.initState();
    PlateTypeCache.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.plateNumber == null || widget.plateNumber!.isEmpty;
    final cache = PlateTypeCache.instance;
    final bg = isEmpty ? AppColors.primarySurface : cache.bgColor(widget.plateType);
    final fg = isEmpty ? AppColors.black : cache.fgColor(widget.plateType);
    final border = isEmpty ? const Color(0xFF1A1A1A) : cache.borderColor(widget.plateType);
    final showProvince = cache.showProvince(widget.plateType);

    return Container(
      width: 150,
      height: 88,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        if (!isEmpty && showProvince && widget.province != null && widget.province!.isNotEmpty)
          Text(widget.province!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          isEmpty ? 'ຍັງບໍ່ມີທະບຽນ' : widget.plateNumber!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: fg, fontSize: 26, fontWeight: FontWeight.w900),
        ),
      ]),
    );
  }
}
