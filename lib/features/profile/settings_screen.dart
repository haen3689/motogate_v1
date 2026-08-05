import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class SettingsScreen extends StatefulWidget { const SettingsScreen({super.key}); @override State<SettingsScreen> createState() => _S(); }
class _S extends State<SettingsScreen> {
  bool _n = true, _d = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Settings'),
      body: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Container(decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          _t(Icons.notifications_outlined, 'Notifications', MgToggle(value: _n, onChanged: (v) => setState(() => _n = v))), const Divider(height: 1, indent: 56),
          _t(Icons.dark_mode_outlined, 'Dark Mode', MgToggle(value: _d, onChanged: (v) => setState(() => _d = v))), const Divider(height: 1, indent: 56),
          _t(Icons.language, 'Language', const Text('Lao', style: AppTextStyles.bodySmall)), const Divider(height: 1, indent: 56),
          _t(Icons.info_outline, 'Version', const Text('v1.0.0', style: AppTextStyles.bodySmall))]))));
  }
  Widget _t(IconData ic, String t, Widget tr) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [Icon(ic, color: AppColors.primary, size: 22), const SizedBox(width: 16), Expanded(child: Text(t, style: AppTextStyles.bodyMedium)), tr]));
}
