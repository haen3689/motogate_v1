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
      _PhotoTile(label: 'ໃບຂັບຂີ', icon: Icons.badge_outlined, url: licenseUrl),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ຮູບພາບເອກະສານ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
              children: [
                _progressCard(photoCount, tiles.length),
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

  Widget _progressCard(int filled, int total) {
    final plate = widget.vehicle['plate_number']?.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: total == 0 ? 0 : filled / total,
                strokeWidth: 5,
                backgroundColor: AppColors.grey100,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Center(
                child: Text('$filled/$total',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ອັບໂຫລດແລ້ວ $filled ຈາກ $total',
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                  'ກົດຮູບເພື່ອເບິ່ງເຕັມໜ້າຈໍ'
                  '${plate?.isNotEmpty == true ? '  ·  ທະບຽນ: $plate' : ''}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey500, fontSize: 12)),
            ],
          ),
        ),
      ]),
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
          AspectRatio(aspectRatio: 189 / 118, child: _thumb(tile)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(children: [
              Expanded(
                child: Text(tile.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              _statusTag(tile.hasPhoto),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusTag(bool has) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: has ? const Color(0xFFDCFCE7) : AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(has ? 'ມີ' : 'ບໍ່ມີ',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: has ? const Color(0xFF16A34A) : AppColors.grey500)),
      );

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
