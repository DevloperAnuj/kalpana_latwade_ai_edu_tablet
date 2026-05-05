import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

@immutable
class StrokePoint {
  final double x;
  final double y;
  final double pressure;
  final int timestamp; // ms since app start; 0 for strokes loaded from storage

  const StrokePoint(this.x, this.y, this.pressure, [this.timestamp = 0]);

  List<dynamic> toList() => [x, y, pressure, timestamp];

  factory StrokePoint.fromList(List<dynamic> list) => StrokePoint(
        (list[0] as num).toDouble(),
        (list[1] as num).toDouble(),
        (list[2] as num).toDouble(),
        list.length > 3 ? (list[3] as num).toInt() : 0,
      );
}

@immutable
class StrokeData {
  final List<StrokePoint> points;
  final Color color;
  final double width;
  final bool isEraser;

  const StrokeData({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toList()).toList(),
        'color': '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
        'width': width,
        'isEraser': isEraser,
      };

  factory StrokeData.fromJson(Map<String, dynamic> json) {
    final hex = (json['color'] as String? ?? '#000000').replaceAll('#', '');
    final colorInt = int.parse('FF$hex', radix: 16);
    return StrokeData(
      points: (json['points'] as List)
          .map((p) => StrokePoint.fromList(p as List))
          .toList(),
      color: Color(colorInt),
      width: (json['width'] as num).toDouble(),
      isEraser: json['isEraser'] as bool? ?? false,
    );
  }
}
