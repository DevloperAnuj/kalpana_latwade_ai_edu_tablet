// Data models for student material viewers.
// Mirrors the teacher app's generation_result.dart — read-only, no toJson/copyWith needed.

class MindmapNode {
  final String id;
  final String label;
  final String? parentId;

  const MindmapNode({required this.id, required this.label, this.parentId});

  factory MindmapNode.fromJson(Map<String, dynamic> j) => MindmapNode(
        id: j['id'] as String,
        label: j['label'] as String,
        parentId: j['parentId'] as String?,
      );
}

class Flashcard {
  final String term;
  final String definition;

  const Flashcard({required this.term, required this.definition});

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        term: j['term'] as String,
        definition: j['definition'] as String,
      );
}

class InfographicSection {
  final String title;
  final List<String> bullets;
  final String? iconReference;

  const InfographicSection({
    required this.title,
    required this.bullets,
    this.iconReference,
  });

  factory InfographicSection.fromJson(Map<String, dynamic> j) =>
      InfographicSection(
        title: j['title'] as String,
        bullets: (j['bullets'] as List).cast<String>(),
        iconReference: j['iconReference'] as String?,
      );
}

class TableData {
  final List<String> headers;
  final List<List<String>> rows;

  const TableData({required this.headers, required this.rows});

  factory TableData.fromJson(Map<String, dynamic> j) => TableData(
        headers: (j['headers'] as List).cast<String>(),
        rows: (j['rows'] as List)
            .map((r) => (r as List).cast<String>())
            .toList(),
      );
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final int correct;
  final String explanation;

  const QuizQuestion({
    required this.text,
    required this.options,
    required this.correct,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        text: j['text'] as String,
        options: (j['options'] as List).cast<String>(),
        correct: j['correct'] as int,
        explanation: (j['explanation'] as String?) ?? '',
      );
}
