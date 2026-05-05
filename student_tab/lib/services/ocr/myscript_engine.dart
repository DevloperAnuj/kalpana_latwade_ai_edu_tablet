import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/models/stroke_data.dart';
import 'ocr_engine.dart';

class MyScriptEngine implements OcrEngine {
  static const _channel = MethodChannel('inc.imalpha.eduforge/myscript');

  Future<String> recognizeStrokes(List<StrokeData> strokes) async {
    // Skip eraser strokes — MyScript only processes pen ink.
    final penStrokes = strokes.where((s) => !s.isEraser).toList();
    if (penStrokes.isEmpty) return '';

    final encoded = jsonEncode(penStrokes
        .map((s) => {
              'points': s.points
                  .map((p) => {
                        'x': p.x,
                        'y': p.y,
                        't': p.timestamp,
                        'p': p.pressure.clamp(0.0, 1.0),
                      })
                  .toList(),
            })
        .toList());

    try {
      final result = await _channel.invokeMethod<String>(
        'recognizeStrokes',
        {'strokes': encoded},
      );
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('MyScript: ${e.message}');
    }
  }

  // OcrEngine requires this but MyScript doesn't use image files.
  @override
  Future<String> recognize(String imagePath) async => '';

  @override
  String get displayName => 'MyScript iink (Offline)';

  @override
  bool get requiresInternet => false;

  @override
  EngineType get type => EngineType.myScript;
}
