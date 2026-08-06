import 'package:flutter/material.dart';
import '../services/plate_type_cache.dart';

/// ປ້າຍທະບຽນລົດ — ສີພື້ນ/ຂອບ/ໂຕໜັງສືປ່ຽນຕາມ "ປະເພດປ້າຍ" ຈິງ (plate_type) ຄືປ້າຍທະບຽນຈິງ
/// (ຂາວ, ເຫຼືອງ, ແດງ, ຟ້າ ... ຕາມ PlateTypeCache) — ບໍ່ແມ່ນສີດຽວຄົງທີ່
///
/// ຂະໜາດຄົງທີ່ (width/height) ສະເໝີ, ບໍ່ຂຶ້ນກັບຄວາມຍາວຂອງເລກທະບຽນ ຫຼື ວ່າມີແຂວງສະແດງ
/// ຫຼືບໍ່ — ເພື່ອໃຫ້ທຸກປ້າຍໃນ list/banner ຂະໜາດເທົ່າກັນໝົດ
class MgPlateBadge extends StatefulWidget {
  final String plateNumber;
  final String? province;
  final String? plateType;
  final double fontSize;
  final double width;
  final double height;
  const MgPlateBadge({
    super.key,
    required this.plateNumber,
    this.province,
    this.plateType,
    this.fontSize = 12,
    this.width = 78,
    this.height = 44,
  });

  @override
  State<MgPlateBadge> createState() => _MgPlateBadgeState();
}

class _MgPlateBadgeState extends State<MgPlateBadge> {
  @override
  void initState() {
    super.initState();
    PlateTypeCache.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final cache = PlateTypeCache.instance;
    final bg = cache.bgColor(widget.plateType);
    final fg = cache.fgColor(widget.plateType);
    final border = cache.borderColor(widget.plateType);
    final showProvince = cache.showProvince(widget.plateType);

    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        if (showProvince && widget.province != null && widget.province!.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.province!,
                maxLines: 1,
                style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(widget.plateNumber,
              maxLines: 1,
              style: TextStyle(color: fg, fontSize: widget.fontSize, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
