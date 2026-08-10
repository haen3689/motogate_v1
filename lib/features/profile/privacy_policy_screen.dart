import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const MgHeader(title: 'ນະໂຍບາຍຄວາມເປັນສ່ວນຕົວ'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ນະໂຍບາຍຄວາມເປັນສ່ວນຕົວ MotoGate', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            _section('1. ຂໍ້ມູນທີ່ພວກເຮົາເກັບກຳ',
                'ເມື່ອທ່ານໃຊ້ MotoGate ພວກເຮົາເກັບກຳ: ເບີໂທລະສັບ ແລະ ຊື່-ນາມສະກຸນ (ສຳລັບເຂົ້າສູ່ລະບົບ), '
                    'ຂໍ້ມູນເອກະສານສ່ວນຕົວ ເຊັ່ນ ບັດປະຈຳຕົວ/ໜັງສືຜ່ານແດນ ແລະ ໃບຂັບຂີ່ (ພ້ອມຮູບພາບ), '
                    'ຂໍ້ມູນພາຫະນະ (ທະບຽນ, ຍີ່ຫໍ້, ເລກຈັກ, ເລກໂຄງລົດ), ແລະ ຮູບໂປຣໄຟລ໌ຂອງທ່ານ (ຖ້າອັບໂຫລດ).'),
            _section('2. ວິທີການໃຊ້ຂໍ້ມູນ',
                'ຂໍ້ມູນຂອງທ່ານຖືກໃຊ້ເພື່ອ: ຢືນຢັນຕົວຕົນຕອນເຂົ້າສູ່ລະບົບ, ດຳເນີນການຊຳລະຄ່າທາງ/ປະກັນໄພ/ຈອງກວດສະພາບ '
                    'ໃນນາມທ່ານ, ແຈ້ງເຕືອນກ່ອນເອກະສານໝົດອາຍຸ, ແລະ ຕິດຕໍ່ທ່ານກໍລະນີມີບັນຫາກ່ຽວກັບການບໍລິການ.'),
            _section('3. ຕຳແໜ່ງທີ່ຕັ້ງ (Location)',
                'ແອັບຯ ອາດຂໍໃຊ້ຕຳແໜ່ງທີ່ຕັ້ງຂອງທ່ານ ເພື່ອຄິດໄລ່ໄລຍະຫ່າງໄປຫາສູນສ້ອມແປງ, ຮ້ານຂາຍລົດ ຫຼື ບໍລິການ '
                    'ລາກລົດທີ່ໃກ້ທ່ານທີ່ສຸດເທົ່ານັ້ນ — ບໍ່ໄດ້ບັນທຶກ ຫຼື ຕິດຕາມຕຳແໜ່ງຂອງທ່ານໄວ້ຖາວອນ.'),
            _section('4. ການເກັບຮັກສາ ແລະ ຄວາມປອດໄພ',
                'ຂໍ້ມູນຂອງທ່ານຖືກເກັບຮັກສາໄວ້ໃນລະບົບຂອງ MotoGate ຢ່າງປອດໄພ ແລະ ຈະບໍ່ຖືກຂາຍ ຫຼື ແບ່ງປັນໃຫ້ '
                    'ບຸກຄົນທີ່ສາມເພື່ອຈຸດປະສົງທາງກາລະຕະຫຼາດ. ຂໍ້ມູນຈະຖືກແບ່ງປັນສະເພາະກັບຄູ່ຮ່ວມທຸລະກິດ (ເຊັ່ນ '
                    'ບໍລິສັດປະກັນໄພ ຫຼື ສູນກວດສະພາບ) ເທົ່າທີ່ຈຳເປັນເພື່ອດຳເນີນການບໍລິການທີ່ທ່ານຮ້ອງຂໍເທົ່ານັ້ນ.'),
            _section('5. ສິດຂອງທ່ານ',
                'ທ່ານສາມາດແກ້ໄຂຂໍ້ມູນສ່ວນຕົວຂອງທ່ານໄດ້ທຸກເວລາຈາກໜ້າ "ຂໍ້ມູນສ່ວນຕົວ" ໃນແອັບຯ. ຫາກຕ້ອງການລຶບ '
                    'ບັນຊີ ຫຼື ມີຄຳຖາມກ່ຽວກັບຂໍ້ມູນຂອງທ່ານ ກະລຸນາຕິດຕໍ່ທີມງານຜ່ານໜ້າ "ສາຍດ່ວນ".'),
            _section('6. ການປ່ຽນແປງນະໂຍບາຍ',
                'MotoGate ອາດປັບປຸງນະໂຍບາຍນີ້ເປັນບາງຄັ້ງຄາວ ການໃຊ້ງານແອັບຯ ຕໍ່ໄປຫຼັງການປ່ຽນແປງ ຖືວ່າທ່ານ '
                    'ຮັບຊາບ ແລະ ຍອມຮັບນະໂຍບາຍສະບັບໃໝ່.'),
            const SizedBox(height: 8),
          ],
        ),
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
