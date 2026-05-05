import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eduforge_core/eduforge_core.dart';

import '../../data/models/stroke_data.dart';
import 'gemini_engine.dart';
import 'ml_kit_engine.dart';
import 'myscript_engine.dart';
import 'ocr_engine.dart';
import 'ocr_preferences.dart';

class OcrResult {
  final String text;
  final EngineType engineUsed;
  final bool usedFallback;
  final String? fallbackReason;

  const OcrResult({
    required this.text,
    required this.engineUsed,
    this.usedFallback = false,
    this.fallbackReason,
  });
}

abstract final class OcrService {
  static final _mlKit = MlKitEngine();
  static final _gemini = GeminiEngine();
  static final _myScript = MyScriptEngine();

  // ── Stroke-based (MyScript) ───────────────────────────────────────────────

  /// Recognises strokes using MyScript. Throws on failure — caller handles
  /// fallback.
  static Future<OcrResult> recognizeStrokes(List<StrokeData> strokes) async {
    final text = await _myScript.recognizeStrokes(strokes);
    return OcrResult(text: text, engineUsed: EngineType.myScript);
  }

  /// Always uses ML Kit regardless of the current preference. Used as the
  /// fallback when MyScript fails.
  static Future<OcrResult> recognizeFallback(
    String imagePath,
    String reason,
  ) async {
    final text = await _mlKit.recognize(imagePath);
    return OcrResult(
      text: text,
      engineUsed: EngineType.mlKit,
      usedFallback: true,
      fallbackReason: reason,
    );
  }

  // ── Image-based (ML Kit / Gemini) ─────────────────────────────────────────

  static Future<OcrResult> recognize(String imagePath) async {
    final preferred = OcrPreferences.engine;

    if (preferred == EngineType.gemini) {
      if (OcrPreferences.isOverQuota) {
        return recognizeFallback(
          imagePath,
          'Monthly cloud OCR quota reached (${OcrPreferences.monthlyLimit} calls)',
        );
      }
      if (!await _hasInternet()) {
        return recognizeFallback(imagePath, 'No internet — using offline OCR');
      }
      try {
        final text = await _gemini.recognize(imagePath);
        await OcrPreferences.incrementCallCount();
        return OcrResult(text: text, engineUsed: EngineType.gemini);
      } catch (e, st) {
        ErrorLogger.instance.logError(e, st, context: 'OcrService.gemini');
        return recognizeFallback(imagePath, 'Gemini failed — using offline OCR');
      }
    }

    final text = await _mlKit.recognize(imagePath);
    return OcrResult(text: text, engineUsed: EngineType.mlKit);
  }

  static Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }
}
