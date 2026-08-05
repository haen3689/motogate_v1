import 'package:flutter/material.dart';
import '../../core/services/api_vehicle_service.dart';
import '../common/payment_method_screen.dart';
import '../common/payment_success_screen.dart';

/// One-time platform registration fee, shown right after a vehicle is added.
/// Wraps the shared mock payment flow (same pattern as road tax / insurance)
/// and marks the vehicle's `fee_paid` flag once "paid".
class VehicleFeePaymentScreen extends StatelessWidget {
  const VehicleFeePaymentScreen({super.key, required this.vehicle});

  final Map<String, dynamic> vehicle;

  static const amount = '200,000 LAK';

  @override
  Widget build(BuildContext context) {
    final plate = vehicle['plate_number']?.toString();
    return PaymentMethodScreen(
      title: 'ຄ່າທຳນຽມລົງທະບຽນລົດ',
      amount: amount,
      description: plate?.isNotEmpty == true ? 'ທະບຽນ: $plate' : 'ຄ່າທຳນຽມລົງທະບຽນລົດຄັນໃໝ່',
      onSuccess: () async {
        try {
          await ApiVehicleService.markFeePaid(vehicle['id']);
        } catch (_) {
          // Mock flow — proceed to the success screen even if the flag
          // update fails; the user already "paid" and can retry later.
        }
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const PaymentSuccessScreen(
                title: 'ຄ່າທຳນຽມລົງທະບຽນລົດ',
                amount: amount,
              ),
            ),
          );
        }
      },
    );
  }
}
