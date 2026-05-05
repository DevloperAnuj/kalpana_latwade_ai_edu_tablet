enum EngineType {
  mlKit,
  gemini,
  myScript;

  String get label => switch (this) {
        EngineType.mlKit => 'ML Kit',
        EngineType.gemini => 'Gemini',
        EngineType.myScript => 'MyScript',
      };
}

abstract class OcrEngine {
  Future<String> recognize(String imagePath);
  String get displayName;
  bool get requiresInternet;
  EngineType get type;
}
