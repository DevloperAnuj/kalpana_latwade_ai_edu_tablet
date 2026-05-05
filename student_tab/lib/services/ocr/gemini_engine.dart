import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eduforge_core/eduforge_core.dart';
import 'package:http/http.dart' as http;

import 'ocr_engine.dart';

class GeminiOcrException implements Exception {
  final String message;
  const GeminiOcrException(this.message);

  @override
  String toString() => 'GeminiOcrException: $message';
}

class GeminiEngine implements OcrEngine {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.0-flash:generateContent';
  static const _timeout = Duration(seconds: 15);

  @override
  Future<String> recognize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse('$_endpoint?key=${AiConstants.geminiApiKey}');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': 'Extract all handwritten text from this image. '
                  'Return only the raw text, no explanations. '
                  'Preserve line breaks where clear.',
            },
            {
              'inline_data': {'mime_type': 'image/png', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 2048, 'temperature': 0.1},
    });

    late http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_timeout);
    } on TimeoutException {
      throw const GeminiOcrException('Request timed out');
    } on SocketException catch (e) {
      throw GeminiOcrException('Network error: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw GeminiOcrException('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        (data['candidates'] as List?)
            ?.firstOrNull?['content']?['parts']
                ?.firstOrNull?['text'] as String? ??
        '';
    return text.trim();
  }

  @override
  String get displayName => 'Gemini Flash (Cloud)';

  @override
  bool get requiresInternet => true;

  @override
  EngineType get type => EngineType.gemini;
}
