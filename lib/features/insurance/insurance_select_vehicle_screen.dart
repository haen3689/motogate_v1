import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_vehicle_service.dart';
import '../../core/services/api_auth_service.dart';

class InsuranceSelectVehicleScreen extends StatefulWidget {
  const InsuranceSelectVehicleScreen({super.key});
  @override
  State<InsuranceSelectVehicleScreen> createState() => _InsuranceSelectVehicleScreenState();
}

class _InsuranceSelectVehicleScreenState extends State<InsuranceSelectVehicleScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiVehicleService.list();
      if (mounted) setState(() => _vehicles = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is DioException ? ApiAuthService.errorMessage(e) : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _typeLabel(String? type) => switch (type) {
        'motorcycle' => 'ລົດຈັກ',
        'truck' => 'ລົດບັນທຸກ',
        _ => 'ລົດເບົາ',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ເລືອກລົດ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load)
              : _vehicles.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(22),
                        itemCount: _vehicles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final v = _vehicles[i];
                          final brandModel = [v['brand'], v['model']]
                              .where((s) => s != null && s.toString().isNotEmpty)
                              .join(' ');
                          final cc = v['cc']?.toString() ?? '';
                          final type = _typeLabel(v['vehicle_type']?.toString());
                          return MgListItemCard(
                            title: v['plate_number']?.toString() ?? '—',
                            subtitle: '${brandModel.isEmpty ? type : '$brandModel · $type'}${cc.isNotEmpty ? ' ${cc}CC' : ''}',
                            icon: Icons.directions_car,
                            onTap: () => Navigator.of(context)
                                .pushNamed('/insurance/companies', arguments: v),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.directions_car_outlined, color: AppColors.grey300, size: 48),
            const SizedBox(height: 16),
            const Text('ທ່ານຍັງບໍ່ມີລົດ', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            const Text('ກະລຸນາເພີ່ມລົດກ່ອນຊື້ປະກັນໄພ',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            MgButton(
                label: 'ເພີ່ມລົດ',
                onPressed: () => Navigator.of(context).pushNamed('/vehicle/add')),
          ]),
        ),
      );

  Widget _message(String text, {VoidCallback? retry}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 16),
              MgButton(label: 'ລອງໃໝ່', onPressed: retry),
            ],
          ]),
        ),
      );
}
