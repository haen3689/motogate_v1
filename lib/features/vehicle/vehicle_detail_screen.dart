import 'package:flutter/material.dart';

import '../../core/services/plate_type_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class VehicleDetailScreen extends StatelessWidget {
  const VehicleDetailScreen({super.key, required this.vehicle});

  final Map<String, dynamic> vehicle;

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
    final brand = vehicle['brand']?.toString() ?? '';
    final model = vehicle['model']?.toString() ?? '';
    final plateNumber = vehicle['plate_number']?.toString();
    final type = _typeLabel(vehicle['vehicle_type']?.toString());
    final frontUrl = vehicle['registration_front_url']?.toString();
    final backUrl = vehicle['registration_back_url']?.toString();

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
                province: vehicle['province']?.toString(),
                plateType: vehicle['plate_type']?.toString(),
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
              _infoRow('ສີ', vehicle['color']?.toString()),
              _infoRow('ປີຜະລິດ', vehicle['year']?.toString()),
            ]),
            const SizedBox(height: 22),

            _sectionHeader(Icons.badge_outlined, 'ຂໍ້ມູນທະບຽນ'),
            const SizedBox(height: 8),
            _sectionCard([
              _infoRow('ປະເພດປ້າຍທະບຽນ', vehicle['plate_type']?.toString()),
              _infoRow('ແຂວງ', vehicle['province']?.toString()),
              _infoRow('ຊື່ເຈົ້າຂອງລົດ', vehicle['owner_name']?.toString()),
              _infoRow('ວັນໝົດອາຍຸທະບຽນ',
                  _formatDate(vehicle['registration_expiry_date']?.toString())),
            ]),
            const SizedBox(height: 22),

            _sectionHeader(Icons.settings_outlined, 'ຂໍ້ມູນເຕັກນິກ'),
            const SizedBox(height: 8),
            _sectionCard([
              _infoRow('ຄວາມແຮງ (CC)', vehicle['cc']?.toString()),
              _infoRow('ເລກຈັກ', vehicle['engine_number']?.toString()),
              _infoRow('ເລກຖັງ (VIN)', vehicle['chassis_number']?.toString()),
              _infoRow('ການນຳໃຊ້', vehicle['usage_type']?.toString()),
              _infoRow('ປະເພດເຄື່ອງຈັກ', vehicle['fuel_type']?.toString()),
              _infoRow('ຈຳນວນບ່ອນນັ່ງ', vehicle['seat_count']?.toString()),
              _infoRow('ຈຳນວນເພົາ', vehicle['axle_count']?.toString()),
              _infoRow('ຈຳນວນສູບ', vehicle['cylinder_count']?.toString()),
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
            const SizedBox(height: 22),

            _sectionHeader(Icons.info_outline, 'ຂໍ້ມູນລະບົບ'),
            const SizedBox(height: 8),
            _sectionCard([
              _infoRow('ວັນທີລົງທະບຽນ', _formatDate(vehicle['created_at']?.toString(), withTime: true)),
              _infoRow('ອັບເດດລ່າສຸດ', _formatDate(vehicle['updated_at']?.toString(), withTime: true)),
              _infoRow('ID', vehicle['id']?.toString()),
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
