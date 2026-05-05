enum NotebookType {
  subject,
  chapter,
  topic;

  String get value => name; // 'subject' | 'chapter' | 'topic'

  static NotebookType fromValue(String? v) => switch (v) {
        'subject' => NotebookType.subject,
        'chapter' => NotebookType.chapter,
        _ => NotebookType.topic,
      };

  NotebookType get childType => switch (this) {
        NotebookType.subject => NotebookType.chapter,
        NotebookType.chapter => NotebookType.topic,
        NotebookType.topic => NotebookType.topic,
      };

  String get label => switch (this) {
        NotebookType.subject => 'Subject',
        NotebookType.chapter => 'Chapter',
        NotebookType.topic => 'Topic',
      };
}
