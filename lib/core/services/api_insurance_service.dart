import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ApiInsuranceService {
  static final _dio = ApiClient.instance;

  static Future<List<Map<String, dynamic>>> companies() async {
    final res = await _dio.get('/insurance_companies');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  static Future<List<Map<String, dynamic>>> myInsurances() async {
    final res = await _dio.get('/insurances');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// ດຶງຂໍ້ມູນປະກັນໄພຫຼ້າສຸດ — ໃຊ້ຫຼັງຈ່າຍເງິນສຳເລັດ ເພື່ອໃຫ້ໄດ້ certificate_number/
  /// start_date/end_date ຕົວຈິງທີ່ server ຄິດໄລ່ຕອນຢືນຢັນການຈ່າຍ (ບໍ່ແມ່ນຄ່າເກົ່າ
  /// ຕອນສ້າງລາຍການ pending)
  static Future<Map<String, dynamic>> show(dynamic insuranceId) async {
    final res = await _dio.get('/insurances/$insuranceId');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ຊື້ປະກັນໄພຜ່ານ BCEL OnePay — ລາຄາຄິດໄລ່ຢູ່ server ຈາກ InsurancePackage
  /// (company + package name), client ບໍ່ໄດ້ສົ່ງລາຄາ/ວັນທີ່ເອງ. Returns the
  /// created (pending) insurance merged with its `payment` (QR/deeplink).
  static Future<Map<String, dynamic>> create({
    required int vehicleId,
    required String company,
    required String package,
  }) async {
    final res = await _dio.post('/insurances', data: {
      'vehicle_id': vehicleId,
      'company': company,
      'package': package,
    });
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ລິ້ງໃບຢັ້ງຢືນປະກັນໄພ (PDF) — ເປີດຜ່ານ browser ພາຍນອກ, ເລີຍຕ້ອງຝັງ token
  /// ໄວ້ໃນ query param ເພາະເປີດຢູ່ນອກແອບບໍ່ມີ Authorization header ຄືກັນກັບ Dio
  static Future<String> certificateUrl(dynamic insuranceId) async {
    final token = await ApiClient.getToken();
    return '${_dio.options.baseUrl}/insurances/$insuranceId/certificate?token=$token';
  }

  /// Attaches a photo of the physical policy document to an insurance the
  /// user already has on file — used by the ຮູບພາບ gallery.
  static Future<Map<String, dynamic>> uploadDocument(dynamic insuranceId, File photo) async {
    final form = FormData.fromMap({'document_image': await MultipartFile.fromFile(photo.path)});
    final res = await _dio.patch('/insurances/$insuranceId/upload_document', data: form,
        options: Options(contentType: 'multipart/form-data'));
    return res.data['data'] as Map<String, dynamic>;
  }

  /// ປະເພດລົດທີ່ຄິດຄ່າທຳນຽມປະກັນໄພຕາມ "ຈຳນວນບ່ອນນັ່ງ" ແທນ CC (ລົດຕູ້, ລົດເມ)
  static const seatBasedTypes = ['van', 'bus'];

  /// ປະເພດລົດທີ່ຄິດຄ່າທຳນຽມປະກັນໄພຕາມ "ນ້ຳໜັກ (ຕັນ)" ແທນ CC (ລົດລາກ, ລົດພ່ວງ)
  static const weightBasedTypes = ['towtruck', 'trailer'];

  /// ກັ່ນຕອງແພັກເກັດປະກັນໄພທີ່ເໝາະສົມກັບປະເພດ, ຂະໜາດ (CC/ບ່ອນນັ່ງ/ນ້ຳໜັກ) ແລະ ປະເພດການນຳໃຊ້ຂອງລົດ
  static List<Map<String, dynamic>> matchingPackages(
    List<dynamic> packages,
    Map<String, dynamic> vehicle,
  ) {
    final vType = vehicle['vehicle_type']?.toString();
    final vUsageType = vehicle['usage_type']?.toString();
    return packages.cast<Map<String, dynamic>>().where((p) {
      if (p['status']?.toString() != 'active') return false;
      final pType = p['vehicle_type']?.toString();
      if (pType != null && vType != null && pType != vType) return false;

      final pUsageType = p['usage_type']?.toString();
      if (pUsageType != null &&
          pUsageType.isNotEmpty &&
          pUsageType != vUsageType) {
        return false;
      }

      if (pType != null && seatBasedTypes.contains(pType)) {
        final seats = int.tryParse(vehicle['seat_count']?.toString() ?? '');
        if (seats != null) {
          final minSeats = num.tryParse(p['min_seats']?.toString() ?? '')?.toInt();
          final maxSeats = num.tryParse(p['max_seats']?.toString() ?? '')?.toInt();
          if (minSeats != null && seats < minSeats) return false;
          if (maxSeats != null && seats > maxSeats) return false;
        }
      } else if (pType != null && weightBasedTypes.contains(pType)) {
        final weight = num.tryParse(vehicle['weight']?.toString() ?? '');
        if (weight != null) {
          final minWeight = num.tryParse(p['min_weight']?.toString() ?? '');
          final maxWeight = num.tryParse(p['max_weight']?.toString() ?? '');
          if (minWeight != null && weight < minWeight) return false;
          if (maxWeight != null && weight > maxWeight) return false;
        }
      } else {
        final cc = int.tryParse(vehicle['cc']?.toString() ?? '');
        if (cc != null) {
          final minCc = num.tryParse(p['min_cc']?.toString() ?? '')?.toInt();
          final maxCc = num.tryParse(p['max_cc']?.toString() ?? '')?.toInt();
          if (minCc != null && cc < minCc) return false;
          if (maxCc != null && cc > maxCc) return false;
        }
      }
      return true;
    }).toList();
  }
}
