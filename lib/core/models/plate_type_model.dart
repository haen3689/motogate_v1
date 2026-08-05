import 'package:flutter/material.dart';

class PlateTypeModel {
  final String plateCode;
  final String name;
  final String colorClass;
  final bool showProvince;

  const PlateTypeModel({
    required this.plateCode,
    required this.name,
    required this.colorClass,
    required this.showProvince,
  });

  factory PlateTypeModel.fromJson(Map<String, dynamic> json) => PlateTypeModel(
        plateCode:    json['plate_code']?.toString() ?? '',
        name:         json['name']?.toString() ?? '',
        colorClass:   json['color_class']?.toString() ?? 'plate-yellow',
        showProvince: json['show_province'] == true,
      );

  Color get bgColor     => _bg(colorClass);
  Color get fgColor     => _fg(colorClass);
  Color get borderColor => _border(colorClass);

  static Color _bg(String c) => switch (c) {
        'plate-blue'          => const Color(0xFF1E3A8A),
        'plate-red'           => const Color(0xFFDC2626),
        'plate-red-underline' => const Color(0xFFDC2626),
        'plate-yellow'        => const Color(0xFFFFCC00),
        'plate-yellow-blue'   => const Color(0xFFFFCC00),
        _                     => Colors.white,
      };

  static Color _fg(String c) => switch (c) {
        'plate-blue'            => Colors.white,
        'plate-red'             => Colors.white,
        'plate-red-underline'   => Colors.white,
        'plate-yellow'          => Colors.black,
        'plate-yellow-blue'     => const Color(0xFF3B82F6),
        'plate-white'           => Colors.black,
        'plate-white-darkblue'  => const Color(0xFF1E3A8A),
        'plate-white-lightblue' => const Color(0xFF60A5FA),
        'plate-white-1percent'  => const Color(0xFF2563EB),
        'plate-white-foreign'   => const Color(0xFF2563EB),
        'plate-diplomat'        => const Color(0xFF2563EB),
        _                       => Colors.black,
      };

  static Color _border(String c) => switch (c) {
        'plate-blue'            => const Color(0xFF1E3A8A),
        'plate-red'             => const Color(0xFF7F1D1D),
        'plate-red-underline'   => const Color(0xFF7F1D1D),
        'plate-yellow'          => Colors.black,
        'plate-yellow-blue'     => const Color(0xFF3B82F6),
        'plate-white'           => Colors.black,
        'plate-white-darkblue'  => const Color(0xFF1E3A8A),
        'plate-white-lightblue' => const Color(0xFF60A5FA),
        'plate-white-1percent'  => const Color(0xFF2563EB),
        'plate-white-foreign'   => const Color(0xFF2563EB),
        'plate-diplomat'        => const Color(0xFF2563EB),
        _                       => Colors.black,
      };
}
