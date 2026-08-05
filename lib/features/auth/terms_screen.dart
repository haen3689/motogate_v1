import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});
  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const MgHeader(title: 'ເງື່ອນໄຂການໃຊ້ງານ', showBack: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ຂໍ້ຕົກລົງການໃຊ້ງານ MotoGate', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _section('1. ການຍອມຮັບເງື່ອນໄຂ',
                      'ການໃຊ້ແອັບພລິເຄຊັນ MotoGate ຖືວ່າທ່ານໄດ້ຍອມຮັບເງື່ອນໄຂ ແລະ ຂໍ້ກຳນົດທັງໝົດທີ່ລະບຸໄວ້ໃນເອກະສານນີ້.'),
                  _section('2. ການລົງທະບຽນ',
                      'ທ່ານຕ້ອງໃຫ້ຂໍ້ມູນທີ່ຖືກຕ້ອງ ແລະ ຄົບຖ້ວນໃນການລົງທະບຽນ. ທ່ານຮັບຜິດຊອບໃນການຮັກສາຄວາມລັບຂອງບັນຊີຂອງທ່ານ.'),
                  _section('3. ການໃຊ້ງານທີ່ຍອມຮັບໄດ້',
                      'ທ່ານຕ້ອງໃຊ້ແອັບຯ ສຳລັບຈຸດປະສົງທີ່ຖືກຕ້ອງຕາມກົດໝາຍເທົ່ານັ້ນ. ຫ້າມໃຊ້ໃນລັກສະນະທີ່ລະເມີດກົດໝາຍ ຫຼື ສ້າງຄວາມເສຍຫາຍແກ່ຜູ້ອື່ນ.'),
                  _section('4. ຄວາມເປັນສ່ວນຕົວ',
                      'ຂໍ້ມູນສ່ວນຕົວຂອງທ່ານຈະຖືກເກັບຮັກສາໄວ້ຢ່າງລັບ ແລະ ປອດໄພ ຕາມນະໂຍບາຍຄວາມເປັນສ່ວນຕົວຂອງ MotoGate.'),
                  _section('5. ການປ່ຽນແປງ',
                      'MotoGate ສະຫງວນສິດໃນການປ່ຽນແປງເງື່ອນໄຂເຫຼົ່ານີ້ໄດ້ທຸກເວລາ. ການໃຊ້ງານຕໍ່ໄປຖືວ່າທ່ານຍອມຮັບການປ່ຽນແປງດັ່ງກ່າວ.'),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _accepted = !_accepted),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _accepted ? AppColors.primary : AppColors.grey100, width: 2),
                          color: _accepted ? AppColors.primary : AppColors.white,
                        ),
                        child: _accepted ? const Icon(Icons.check, size: 14, color: AppColors.white) : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('ຂ້ອຍໄດ້ອ່ານ ແລະ ຍອມຮັບເງື່ອນໄຂການໃຊ້ງານ', style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MgButton(
                  label: 'ດຳເນີນການຕໍ່',
                  variant: _accepted ? MgButtonVariant.primary : MgButtonVariant.disabled,
                  onPressed: _accepted
                      ? () => Navigator.of(context).pushNamedAndRemoveUntil('/profile/setup', (_) => false)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body, style: AppTextStyles.bodySmall.copyWith(height: 1.6)),
          ],
        ),
      );
}
