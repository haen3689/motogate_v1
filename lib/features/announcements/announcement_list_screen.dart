import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/announcement_service.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});
  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  List<AnnouncementModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await AnnouncementService.getAll();
    AnnouncementService.markSeen();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ປະກາດ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.campaign_outlined, color: AppColors.grey300, size: 40),
                      const SizedBox(height: 12),
                      const Text('ຍັງບໍ່ມີປະກາດ', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 16),
                      MgButton(label: 'ລອງໃໝ່', onPressed: _load),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(22),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(_items[i]),
                  ),
                ),
    );
  }

  Widget _card(AnnouncementModel a) => GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/announcements/detail', arguments: a),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (a.imageUrl != null)
              Image.network(a.imageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                if ((a.body ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(a.body!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
                ],
                const SizedBox(height: 8),
                Text(DateFormat('dd/MM/yyyy').format(a.createdAt.toLocal()),
                    style: AppTextStyles.caption.copyWith(color: AppColors.grey400)),
              ]),
            ),
          ]),
        ),
      );
}
