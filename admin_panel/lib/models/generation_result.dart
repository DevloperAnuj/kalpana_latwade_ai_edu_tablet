// Data models for AI-generated study pack materials.
// All types include fromJson/toJson for draft persistence and Supabase storage.

// ── Mindmap ───────────────────────────────────────────────────────────────────

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'parentId': parentId,
      };
}

class Mindmap {
  final List<MindmapNode> nodes;

  const Mindmap({required this.nodes});

  factory Mindmap.fromJson(Map<String, dynamic> j) => Mindmap(
        nodes: (j['nodes'] as List)
            .map((e) => MindmapNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };
}

// ── Flashcards ────────────────────────────────────────────────────────────────

class Flashcard {
  final String term;
  final String definition;

  const Flashcard({required this.term, required this.definition});

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        term: j['term'] as String,
        definition: j['definition'] as String,
      );

  Map<String, dynamic> toJson() => {'term': term, 'definition': definition};

  Flashcard copyWith({String? term, String? definition}) => Flashcard(
        term: term ?? this.term,
        definition: definition ?? this.definition,
      );
}

// ── Infographic ───────────────────────────────────────────────────────────────

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

  Map<String, dynamic> toJson() => {
        'title': title,
        'bullets': bullets,
        'iconReference': iconReference,
      };

  InfographicSection copyWith({
    String? title,
    List<String>? bullets,
    String? iconReference,
  }) =>
      InfographicSection(
        title: title ?? this.title,
        bullets: bullets ?? this.bullets,
        iconReference: iconReference ?? this.iconReference,
      );
}

class Infographic {
  final List<InfographicSection> sections;

  const Infographic({required this.sections});

  factory Infographic.fromJson(Map<String, dynamic> j) => Infographic(
        sections: (j['sections'] as List)
            .map((e) => InfographicSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

// ── Table ─────────────────────────────────────────────────────────────────────

class TableData {
  final List<String> headers;
  final List<List<String>> rows;

  const TableData({required this.headers, required this.rows});

  factory TableData.fromJson(Map<String, dynamic> j) => TableData(
        headers: (j['headers'] as List).cast<String>(),
        rows: (j['rows'] as List)
            .map((row) => (row as List).cast<String>())
            .toList(),
      );

  Map<String, dynamic> toJson() => {'headers': headers, 'rows': rows};
}

// ── Quiz ──────────────────────────────────────────────────────────────────────

class QuizQuestion {
  final String text;
  final List<String> options; // exactly 4
  final int correct; // 0–3
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
        correct: (j['correct'] as num).toInt(),
        explanation: j['explanation'] as String,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'options': options,
        'correct': correct,
        'explanation': explanation,
      };

  QuizQuestion copyWith({
    String? text,
    List<String>? options,
    int? correct,
    String? explanation,
  }) =>
      QuizQuestion(
        text: text ?? this.text,
        options: options ?? this.options,
        correct: correct ?? this.correct,
        explanation: explanation ?? this.explanation,
      );
}

class Quiz {
  final List<QuizQuestion> questions;

  const Quiz({required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
        questions: (j['questions'] as List)
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

// ── GenerationResult ──────────────────────────────────────────────────────────

class GenerationResult {
  final Mindmap mindmap;
  final List<Flashcard> flashcards;
  final Infographic infographic;
  final TableData table;
  final Quiz quiz;

  const GenerationResult({
    required this.mindmap,
    required this.flashcards,
    required this.infographic,
    required this.table,
    required this.quiz,
  });

  factory GenerationResult.fromJson(Map<String, dynamic> j) => GenerationResult(
        mindmap: Mindmap.fromJson(j['mindmap'] as Map<String, dynamic>),
        flashcards: (j['flashcards'] as List)
            .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
            .toList(),
        infographic:
            Infographic.fromJson(j['infographic'] as Map<String, dynamic>),
        table: TableData.fromJson(j['table'] as Map<String, dynamic>),
        quiz: Quiz.fromJson(j['quiz'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'mindmap': mindmap.toJson(),
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        'infographic': infographic.toJson(),
        'table': table.toJson(),
        'quiz': quiz.toJson(),
      };

  GenerationResult copyWith({
    Mindmap? mindmap,
    List<Flashcard>? flashcards,
    Infographic? infographic,
    TableData? table,
    Quiz? quiz,
  }) =>
      GenerationResult(
        mindmap: mindmap ?? this.mindmap,
        flashcards: flashcards ?? this.flashcards,
        infographic: infographic ?? this.infographic,
        table: table ?? this.table,
        quiz: quiz ?? this.quiz,
      );
}
