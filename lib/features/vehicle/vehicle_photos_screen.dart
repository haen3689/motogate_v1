import 'package:flutter/material.dart';
import '../../core/services/api_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

/// A single photo slot in the gallery grid — either a real uploaded photo
/// or a category that has no upload field in the backend yet (shown as a
/// placeholder until that upload is added).
class _PhotoTile {
  const _PhotoTile({required this.label, required this.icon, this.url});
  final String label;
  final IconData icon;
  final String? url;
  bool get hasPhoto => url != null && url!.isNotEmpty;
}

/// 2-column document-photo gallery for a single vehicle, matching the
/// Figma "PhotoGallery v2" design. Reached via [PaidVehiclePickerScreen]
/// the same way the Documents screen is.
class VehiclePhotosScreen extends StatefulWidget {
  const VehiclePhotosScreen({super.key, required this.vehicle});
  final Map<String, dynamic> vehicle;

  @override
  State<VehiclePhotosScreen> createState() => _VehiclePhotosScreenState();
}

class _VehiclePhotosScreenState extends State<VehiclePhotosScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final u = await ApiAuthService.me();
      if (mounted) setState(() => _user = u);
    } catch (_) {
      // Non-fatal — license photo tile just falls back to a placeholder.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_PhotoTile> get _tiles {
    final licenseUrl = _user?['license_image_url']?.toString();
    final regFrontUrl = widget.vehicle['registration_front_url']?.toString();
    final regBackUrl = widget.vehicle['registration_back_url']?.toString();
    return [
      _PhotoTile(label: 'ໃບຂັບຂີ (ໜ້າ)', icon: Icons.badge_outlined, url: licenseUrl),
      const _PhotoTile(label: 'ໃບຂັບຂີ (ຫຼັງ)', icon: Icons.badge_outlined),
      const _PhotoTile(label: 'ລົດ — ດ້ານໜ້າ', icon: Icons.directions_car_filled_outlined),
      _PhotoTile(label: 'ທະບຽນລົດ', icon: Icons.article_outlined, url: regFrontUrl),
      _PhotoTile(label: 'ປຶ້ມຄູ່ມືລົດ', icon: Icons.menu_book_outlined, url: regBackUrl),
      const _PhotoTile(label: 'ສະຫຼາກກວດເຕັກນິກ', icon: Icons.fact_check_outlined),
      const _PhotoTile(label: 'ໃບເສຍຄ່າທາງ', icon: Icons.receipt_long_outlined),
      const _PhotoTile(label: 'ໃບປະກັນໄພ', icon: Icons.shield_outlined),
    ];
  }

  void _openTile(_PhotoTile tile) {
    if (tile.hasPhoto) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => _PhotoViewerDialog(url: tile.url!),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ກຳລັງພັດທະນາ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _tiles;
    final photoCount = tiles.where((t) => t.hasPhoto).length;
    final plate = widget.vehicle['plate_number']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ຮູບພາບເອກະສານ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
              children: [
                Text('ຮູບພາບທີ່ອັບໂຫລດ',
                    style: AppTextStyles.titleSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    '$photoCount ຮູບ — ກົດເພື່ອເບິ່ງເຕັມໜ້າຈໍ'
                    '${plate?.isNotEmpty == true ? '  ·  ທະບຽນ: $plate' : ''}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.grey500, fontSize: 12.5)),
                const SizedBox(height: 16),
                for (var i = 0; i < tiles.length; i += 2) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _photoCard(tiles[i])),
                    const SizedBox(width: 12),
                    Expanded(
                        child: i + 1 < tiles.length
                            ? _photoCard(tiles[i + 1])
                            : const SizedBox.shrink()),
                  ]),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Widget _photoCard(_PhotoTile tile) {
    return GestureDetector(
      onTap: () => _openTile(tile),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryLight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(aspectRatio: 189 / 129, child: _thumb(tile)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Text(tile.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _thumb(_PhotoTile tile) {
    if (!tile.hasPhoto) {
      return Container(
        color: AppColors.grey100,
        child: Center(child: Icon(tile.icon, color: AppColors.grey300, size: 30)),
      );
    }
    return Image.network(
      tile.url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.grey100,
        child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.grey300, size: 28)),
      ),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              color: AppColors.grey100,
              child: const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
            ),
    );
  }
}

/// Full-screen pinch-to-zoom viewer for a single uploaded document photo.
class _PhotoViewerDialog extends StatelessWidget {
  const _PhotoViewerDialog({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(children: [
        InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ]),
    );
  }
}
