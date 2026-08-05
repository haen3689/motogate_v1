import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_insurance_service.dart';
import '../../core/services/api_auth_service.dart';

class InsuranceCompanySelectScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const InsuranceCompanySelectScreen({super.key, required this.vehicle});
  @override
  State<InsuranceCompanySelectScreen> createState() => _InsuranceCompanySelectScreenState();
}

class _InsuranceCompanySelectScreenState extends State<InsuranceCompanySelectScreen> {
  List<Map<String, dynamic>> _companies = [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final list = await ApiInsuranceService.companies();
      if (mounted) setState(() => _companies = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is DioException ? ApiAuthService.errorMessage(e) : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matched = _companies
        .map((c) => (
              company: c,
              packages: ApiInsuranceService.matchingPackages(
                  (c['insurance_packages'] as List?) ?? [], widget.vehicle),
            ))
        .where((e) => e.packages.isNotEmpty)
        .where((e) => _query.isEmpty ||
            (e.company['name']?.toString().toLowerCase() ?? '').contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ເລືອກບໍລິສັດປະກັນໄພ'),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          MgSearchBar(hintText: 'ຄົ້ນຫາບໍລິສັດ...', onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _message(_error!, retry: _load)
                    : matched.isEmpty
                        ? _message('ບໍ່ພົບບໍລິສັດປະກັນໄພທີ່ເໝາະສົມກັບລົດນີ້')
                        : ListView.separated(
                            itemCount: matched.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final entry = matched[i];
                              final phone = entry.company['phone']?.toString() ?? '';
                              return MgListItemCard(
                                title: entry.company['name']?.toString() ?? '',
                                subtitle:
                                    '${entry.packages.length} ແພັກເກັດ${phone.isNotEmpty ? ' · $phone' : ''}',
                                icon: Icons.security,
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/insurance/packages',
                                  arguments: {
                                    'vehicle': widget.vehicle,
                                    'company': entry.company,
                                    'packages': entry.packages,
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ]),
      ),
    );
  }

  Widget _message(String text, {VoidCallback? retry}) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          if (retry != null) ...[
            const SizedBox(height: 12),
            MgButton(label: 'ລອງໃໝ່', onPressed: retry),
          ],
        ]),
      );
}
