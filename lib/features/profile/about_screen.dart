import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'v${info.version}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ແນະນຳກ່ຽວກັບ MotoGate'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.two_wheeler, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 14),
                const Text('MotoGate Lao', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                if (_version.isNotEmpty)
                  Text(_version, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
              ]),
            ),
            const SizedBox(height: 26),
            _card(
              'MotoGate ແມ່ນຫຍັງ',
              'MotoGate Lao ແມ່ນແອັບພລິເຄຊັນທີ່ຊ່ວຍໃຫ້ເຈົ້າຂອງລົດຈັກ ແລະ ລົດໃຫຍ່ຢູ່ ສປປ ລາວ ຈັດການ '
                  'ເອກະສານ ແລະ ບໍລິການທີ່ກ່ຽວຂ້ອງກັບພາຫະນະຂອງທ່ານໄດ້ງ່າຍຂຶ້ນ ຜ່ານມືຖືເຄື່ອງດຽວ.',
            ),
            const SizedBox(height: 14),
            _card(
              'ບໍລິການທີ່ມີໃນແອັບ',
              '• ຊຳລະຄ່າທາງປະຈຳປີ ແລະ ອັບໂຫລດຫຼັກຖານການຊຳລະ\n'
                  '• ຊື້ ແລະ ຕິດຕາມປະກັນໄພລົດ\n'
                  '• ຈອງຄິວກວດສະພາບເຕັກນິກຢູ່ສູນທີ່ໃກ້ທ່ານ\n'
                  '• ຄົ້ນຫາສູນສ້ອມແປງ, ຮ້ານຂາຍລົດ ແລະ ບໍລິການລາກລົດ 24 ຊົ່ວໂມງ\n'
                  '• ເກັບເອກະສານລົດ ແລະ ໃບຂັບຂີ່ໄວ້ໃນທີ່ດຽວ, ພ້ອມແຈ້ງເຕືອນກ່ອນໝົດອາຍຸ',
            ),
            const SizedBox(height: 14),
            _card(
              'ຕິດຕໍ່ພວກເຮົາ',
              'ມີຄຳຖາມ ຫຼື ຕ້ອງການຄວາມຊ່ວຍເຫຼືອ? ສົ່ງຂໍ້ຄວາມຫາທີມງານໄດ້ທີ່ໜ້າ "ສາຍດ່ວນ" ໃນເມນູໂປຣໄຟລ໌.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryLight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(body, style: AppTextStyles.bodySmall.copyWith(height: 1.7, color: AppColors.grey600)),
          ],
        ),
      );
}
