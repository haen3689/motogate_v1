import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/announcement_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  const AnnouncementDetailScreen({super.key});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  bool _viewTracked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewTracked) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AnnouncementModel) {
      _viewTracked = true;
      AnnouncementService.markViewed(args.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final a = args is AnnouncementModel ? args : null;

    if (a == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: MgHeader(title: 'ປະກາດ'),
        body: Center(child: Text('ບໍ່ພົບຂໍ້ມູນ')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ລາຍລະອຽດປະກາດ'),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (a.imageUrl != null)
            Image.network(a.imageUrl!, width: double.infinity, height: 220, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(a.createdAt.toLocal()),
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey400)),
              const SizedBox(height: 20),
              if ((a.body ?? '').isNotEmpty)
                Text(a.body!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600, height: 1.6)),
            ]),
          ),
        ]),
      ),
    );
  }
}
