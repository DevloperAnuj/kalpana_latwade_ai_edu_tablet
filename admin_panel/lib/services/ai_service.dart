import 'dart:convert';

import 'package:eduforge_core/eduforge_core.dart';
import 'package:http/http.dart' as http;

import '../models/generation_result.dart';

/// Wraps sequential Gemini Flash calls for study-pack generation.
/// Constructed per-generation with the resolved API key, topic title,
/// and (possibly-truncated) lesson content.
class AiService {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static const _timeout = Duration(seconds: 60);
  final String _apiKey;
  final String _topicTitle;
  final String _lessonContent;

  AiService({
    required String apiKey,
    required String topicTitle,
    required String lessonContent,
  })  : _apiKey = apiKey,
        _topicTitle = topicTitle,
        _lessonContent = InputSanitiser.sanitiseAndTruncate(lessonContent);

  // ── Internal HTTP helper ──────────────────────────────────────────────────

  Future<dynamic> _call(String prompt) async {
    final uri = Uri.parse('$_endpoint?key=$_apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.3,
      },
    });

    Future<http.Response> doRequest() =>
        http.post(uri, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(_timeout);

    late http.Response response;

    // Attempt 1
    try {
      response = await doRequest();
    } catch (_) {
      await Future.delayed(const Duration(seconds: 3));
      response = await doRequest();
    }

    // Retry on transient errors (429 rate-limit, 503 overload)
    if (response.statusCode == 429 || response.statusCode == 503) {
      final wait = response.statusCode == 429
          ? const Duration(seconds: 10)
          : const Duration(seconds: 5);
      await Future.delayed(wait);
      response = await doRequest();
    }

    // Second retry if still failing
    if (response.statusCode == 429 || response.statusCode == 503) {
      await Future.delayed(const Duration(seconds: 15));
      response = await doRequest();
    }

    if (response.statusCode != 200) {
      final snippet =
          response.body.substring(0, response.body.length.clamp(0, 300));
      if (response.statusCode == 429) {
        throw Exception('Gemini rate limit. Please try again in a moment.');
      }
      if (response.statusCode == 503) {
        throw Exception(
            'Gemini is temporarily overloaded. Please try again in a few seconds.');
      }
      throw Exception('Gemini ${response.statusCode}: $snippet');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates in Gemini response');
    }

    final parts =
        (candidates[0]['content'] as Map<String, dynamic>)['parts'] as List;
    String text = (parts[0] as Map<String, dynamic>)['text'] as String;

    // Strip any markdown fences the model may add despite response_mime_type
    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    return jsonDecode(text);
  }

  // ── Public generation methods ─────────────────────────────────────────────

  Future<Mindmap> generateMindmap() async {
    final prompt = '''You are an educational AI assistant.
Topic: $_topicTitle
Lesson:
$_lessonContent

Generate a mindmap as JSON. ONLY JSON, no markdown, no explanation.
Schema: {"nodes":[{"id":"n1","label":"Root concept","parentId":null},{"id":"n2","label":"Sub-concept","parentId":"n1"}]}
Rules:
- First node has parentId null (root = topic title)
- Include 6–10 child nodes for key concepts
- Use unique IDs like n1, n2, n3...''';

    final result = await _call(prompt);
    return Mindmap.fromJson(result as Map<String, dynamic>);
  }

  Future<List<Flashcard>> generateFlashcards() async {
    final prompt = '''You are an educational AI assistant.
Topic: $_topicTitle
Lesson:
$_lessonContent

Generate 8–12 flashcards as JSON. ONLY JSON, no markdown, no explanation.
Schema: {"flashcards":[{"term":"short term","definition":"clear explanation in 1-2 sentences"}]}
Rules:
- Term: 1–5 words
- Definition: educational, accurate, 1–3 sentences
- Cover the most important concepts''';

    final result = await _call(prompt);
    List<dynamic> list;
    if (result is Map<String, dynamic>) {
      list = (result['flashcards'] ??
              result['cards'] ??
              result['items'] ??
              result.values.first) as List;
    } else if (result is List) {
      list = result;
    } else {
      throw Exception('Unexpected flashcards format');
    }
    return list.map((e) => Flashcard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Infographic> generateInfographic() async {
    final prompt = '''You are an educational AI assistant.
Topic: $_topicTitle
Lesson:
$_lessonContent

Generate an infographic layout as JSON. ONLY JSON, no markdown, no explanation.
Schema: {"sections":[{"title":"Section Title","bullets":["Fact 1","Fact 2"],"iconReference":"science"}]}
Rules:
- 3–5 sections covering distinct aspects
- 2–4 bullet points per section (concise facts)
- iconReference: a Material icon name (e.g. "lightbulb", "nature", "water_drop", "science")''';

    final result = await _call(prompt);
    return Infographic.fromJson(result as Map<String, dynamic>);
  }

  Future<TableData> generateTable() async {
    final prompt = '''You are an educational AI assistant.
Topic: $_topicTitle
Lesson:
$_lessonContent

Generate a structured summary table as JSON. ONLY JSON, no markdown, no explanation.
Schema: {"headers":["Column A","Column B"],"rows":[["val1","val2"]]}
Rules:
- 2–4 headers
- 5–10 data rows; every row has the same number of cells as headers
- Present comparisons, key facts, or structured information from the lesson''';

    final result = await _call(prompt);
    return TableData.fromJson(result as Map<String, dynamic>);
  }

  Future<Quiz> generateQuiz() async {
    final prompt = '''You are an educational AI assistant.
Topic: $_topicTitle
Lesson:
$_lessonContent

Generate exactly 10 multiple-choice questions as JSON. ONLY JSON, no markdown, no explanation.
Schema: {"questions":[{"text":"Question?","options":["A","B","C","D"],"correct":0,"explanation":"Why A is correct."}]}
Rules:
- Exactly 4 options per question
- "correct" is 0-indexed (0=A, 1=B, 2=C, 3=D)
- Explanation: 1–2 sentences explaining why the answer is correct
- Vary difficulty; test understanding not just recall''';

    final result = await _call(prompt);
    return Quiz.fromJson(result as Map<String, dynamic>);
  }
}
