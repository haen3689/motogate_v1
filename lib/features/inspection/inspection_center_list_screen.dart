import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/api_inspection_service.dart';
import '../../core/services/api_auth_service.dart';

class InspectionCenterListScreen extends StatefulWidget {
  const InspectionCenterListScreen({super.key});
  @override
  State<InspectionCenterListScreen> createState() => _InspectionCenterListScreenState();
}

class _InspectionCenterListScreenState extends State<InspectionCenterListScreen> {
  List<Map<String, dynamic>> _centers = [];
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
      final list = await ApiInspectionService.centers();
      final active = list.where((c) => c['status']?.toString() != 'inactive').toList();
      if (mounted) setState(() => _centers = active);
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
    if (_query.trim().isEmpty) return _centers;
    final q = _query.trim().toLowerCase();
    return _centers
        .where((c) =>
            (c['name']?.toString() ?? '').toLowerCase().contains(q) ||
            (c['location']?.toString() ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final centers = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ສູນກວດສະພາບລົດ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _message(_error!, retry: _load)
              : _centers.isEmpty
                  ? _message('ບໍ່ພົບສູນກວດສະພາບລົດ', retry: _load)
                  : Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('ເລືອກສູນກວດສະພາບລົດ',
                              style: AppTextStyles.titleSmall
                                  .copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('ເລືອກສູນທີ່ໃກ້ ຫຼື ສະດວກສຳລັບທ່ານ',
                              style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                          const SizedBox(height: 14),
                          MgSearchBar(
                            hintText: 'ຄົ້ນຫາສູນກວດສະພາບລົດ',
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: centers.isEmpty
                            ? _message('ບໍ່ພົບສູນທີ່ຄົ້ນຫາ')
                            : RefreshIndicator(
                                color: AppColors.primary,
                                onRefresh: _load,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                                  itemCount: centers.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _centerRow(centers[i]),
                                ),
                              ),
                      ),
                    ]),
    );
  }

  Widget _centerRow(Map<String, dynamic> center) {
    final name = center['name']?.toString() ?? '';
    final location = center['location']?.toString() ?? '';
    final logoPath = center['logo']?.toString();
    final logoUrl =
        logoPath != null && logoPath.isNotEmpty ? '${ApiClient.webBaseUrl}$logoPath' : null;
    final serviceCount = ((center['inspection_services'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((svc) => svc['status']?.toString() == 'active')
        .length;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/inspection/vehicle', arguments: center),
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
                  child: Text('$serviceCount ບໍລິການ',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(location,
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
        child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 26),
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
