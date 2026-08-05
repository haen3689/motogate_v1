import 'package:flutter/material.dart';
import '../models/plate_type_model.dart';
import 'api_plate_type_service.dart';

/// Singleton cache — call [load()] once (e.g. on vehicle list init).
/// Subsequent calls are no-ops. Falls back to yellow/black on miss.
class PlateTypeCache {
  PlateTypeCache._();
  static final instance = PlateTypeCache._();

  final Map<String, PlateTypeModel> _map = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final list = await ApiPlateTypeService.list();
      for (final json in list) {
        final pt = PlateTypeModel.fromJson(json);
        if (pt.plateCode.isNotEmpty) _map[pt.plateCode] = pt;
      }
      _loaded = true;
    } catch (_) {
      // Network error — will retry next time load() is called
    }
  }

  PlateTypeModel? find(String? code) =>
      code == null ? null : _map[code.trim()];

  Color bgColor(String? code) =>
      find(code)?.bgColor ?? const Color(0xFFFFCC00);

  Color fgColor(String? code) =>
      find(code)?.fgColor ?? Colors.black;

  Color borderColor(String? code) =>
      find(code)?.borderColor ?? Colors.black;

  bool showProvince(String? code) =>
      find(code)?.showProvince ?? true;

  List<PlateTypeModel> all() => _map.values.toList();
}
