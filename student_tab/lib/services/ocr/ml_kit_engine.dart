import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_engine.dart';

class MlKitEngine implements OcrEngine {
  @override
  Future<String> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  @override
  String get displayName => 'ML Kit (Offline)';

  @override
  bool get requiresInternet => false;

  @override
  EngineType get type => EngineType.mlKit;
}
