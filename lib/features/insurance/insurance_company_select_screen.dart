import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_insurance_service.dart';
import '../../core/services/api_auth_service.dart';

final _money = NumberFormat('#,##0');

class InsuranceCompanySelectScreen extends StatefulWidget {
  const InsuranceCompanySelectScreen({super.key});
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
      final withPackages = list
          .where((c) => ((c['insurance_packages'] as List?) ?? []).isNotEmpty)
          .toList();
      if (mounted) setState(() => _companies = withPackages);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is DioException ? ApiAuthService.errorMessage(e) : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _companies;
    final q = _query.trim().toLowerCase();
    return _companies
        .where((c) => (c['name']?.toString() ?? '').toLowerCase().contains(q))
        .toList();
  }

  num? _minPrice(Map<String, dynamic> company) {
    final packages = (company['insurance_packages'] as List?) ?? [];
    final prices = packages
        .cast<Map<String, dynamic>>()
        .where((p) => p['status']?.toString() == 'active')
        .map((p) => num.tryParse(p['price']?.toString() ?? ''))
        .whereType<num>()
        .toList();
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final companies = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ປະກັນໄພພາຫະນະ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load, icon: Icons.error_outline)
              : _companies.isEmpty
                  ? _message('ບໍ່ພົບບໍລິສັດປະກັນໄພ', retry: _load, icon: Icons.business_outlined)
                  : Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('ເລືອກບໍລິສັດປະກັນໄພ',
                              style: AppTextStyles.titleSmall
                                  .copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('ປຽບທຽບ ແລະ ເລືອກບໍລິສັດທີ່ທ່ານຕ້ອງການ',
                              style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                          const SizedBox(height: 14),
                          MgSearchBar(
                            hintText: 'ຄົ້ນຫາບໍລິສັດປະກັນໄພ',
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: companies.isEmpty
                            ? _message('ບໍ່ພົບບໍລິສັດທີ່ຄົ້ນຫາ', icon: Icons.search_off)
                            : RefreshIndicator(
                                color: AppColors.primary,
                                onRefresh: _load,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                                  itemCount: companies.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _companyRow(companies[i]),
                                ),
                              ),
                      ),
                    ]),
    );
  }

  Widget _companyRow(Map<String, dynamic> company) {
    final name = company['name']?.toString() ?? '';
    final logoPath = company['logo']?.toString();
    final logoUrl =
        logoPath != null && logoPath.isNotEmpty ? '${ApiClient.webBaseUrl}$logoPath' : null;
    final packageCount = ((company['insurance_packages'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((p) => p['status']?.toString() == 'active')
        .length;
    final minPrice = _minPrice(company);

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/insurance/vehicle', arguments: company),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null
                ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _logoFallback())
                : _logoFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$packageCount ແພັກເກັດ',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
                if (minPrice != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('ເລີ່ມຕົ້ນ ${_money.format(minPrice)} ກີບ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ),
                ],
              ]),
            ]),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppColors.grey300, size: 22),
        ]),
      ),
    );
  }

  Widget _logoFallback() => Container(
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 26),
      );

  Widget _message(String text, {VoidCallback? retry, IconData icon = Icons.info_outline}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: AppColors.grey300, size: 40),
            const SizedBox(height: 12),
            Text(text, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 16),
              MgButton(label: 'ລອງໃໝ່', onPressed: retry),
            ],
          ]),
        ),
      );
}
