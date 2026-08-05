import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../common/payment_method_screen.dart';
import '../../core/services/api_insurance_service.dart';
import '../../core/services/api_auth_service.dart';

final _money = NumberFormat('#,##0');

class InsurancePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> company;
  final Map<String, dynamic> package;
  const InsurancePaymentScreen({
    super.key,
    required this.vehicle,
    required this.company,
    required this.package,
  });
  @override
  State<InsurancePaymentScreen> createState() => _InsurancePaymentScreenState();
}

class _InsurancePaymentScreenState extends State<InsurancePaymentScreen> {
  bool _submitting = false;

  num get _price => num.tryParse(widget.package['price']?.toString() ?? '') ?? 0;

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pay() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final vehicleId = int.parse(widget.vehicle['id'].toString());
      final duration = int.tryParse(widget.package['duration_months']?.toString() ?? '') ?? 12;
      final start = DateTime.now();
      final end = DateTime(start.year, start.month + duration, start.day);
      await ApiInsuranceService.create(
        vehicleId: vehicleId,
        company: widget.company['name']?.toString() ?? '',
        package: widget.package['name']?.toString() ?? '',
        amount: _price,
        status: 'active',
        startDate: _iso(start),
        endDate: _iso(end),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/insurance/success', (r) => false, arguments: {
        'title': '${widget.company['name']} · ${widget.package['name']}',
        'amount': '${_money.format(_price)} LAK',
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? ApiAuthService.errorMessage(e)
          : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaymentMethodScreen(
      title: 'ຊຳລະຄ່າປະກັນໄພ',
      amount: '${_money.format(_price)} LAK',
      description: '${widget.package['name']} · ${widget.company['name']}',
      onSuccess: _pay,
    );
  }
}
