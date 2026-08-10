import 'api_client.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.reference,
    this.description,
    required this.createdAt,
  });

  final int id;
  final String type; // road_tax | insurance | inspection | service
  final double amount;
  final String status; // pending | success | failed
  final String? reference;
  final String? description;
  final DateTime createdAt;

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as int,
        type: json['transaction_type']?.toString() ?? '',
        amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
        status: json['status']?.toString() ?? 'pending',
        reference: json['reference']?.toString(),
        description: json['description']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  String get typeLabel {
    switch (type) {
      case 'road_tax':
        return 'ຄ່າທາງ';
      case 'insurance':
        return 'ປະກັນໄພ';
      case 'inspection':
        return 'ກວດສະພາບລົດ';
      default:
        return 'ບໍລິການ';
    }
  }
}

class TransactionService {
  static final _dio = ApiClient.instance;

  static Future<List<TransactionModel>> getAll() async {
    try {
      final res = await _dio.get('/transactions');
      final list = res.data['data'] as List<dynamic>;
      return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
