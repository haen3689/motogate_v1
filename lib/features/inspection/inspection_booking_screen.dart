import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
class InspectionBookingScreen extends StatefulWidget { const InspectionBookingScreen({super.key}); @override State<InspectionBookingScreen> createState() => _S(); }
class _S extends State<InspectionBookingScreen> {
  DateTime? _d; int _t = -1;
  final _ts = ['08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Book Inspection'),
      body: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Select Date', style: AppTextStyles.titleMedium), const SizedBox(height: 12),
        GestureDetector(onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90))); if (d != null) setState(() => _d = d); },
          child: Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey100)),
            child: Row(children: [const Icon(Icons.calendar_today, color: AppColors.primary, size: 20), const SizedBox(width: 12), Text(_d != null ? '${_d!.day}/${_d!.month}/${_d!.year}' : 'Choose date', style: AppTextStyles.bodyMedium)]))),
        const SizedBox(height: 24), const Text('Select Time', style: AppTextStyles.titleMedium), const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: List.generate(_ts.length, (i) => GestureDetector(onTap: () => setState(() => _t = i),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: _t == i ? AppColors.primary : AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _t == i ? AppColors.primary : AppColors.grey100)),
            child: Text(_ts[i], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _t == i ? AppColors.white : AppColors.black)))))),
        const SizedBox(height: 32),
        MgButton(label: 'Confirm', variant: _d != null && _t >= 0 ? MgButtonVariant.primary : MgButtonVariant.disabled, onPressed: _d != null && _t >= 0 ? () => Navigator.of(context).pop() : null)])));
  }
}
