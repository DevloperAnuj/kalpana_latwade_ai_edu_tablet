import 'package:flutter/material.dart';

import '../../../models/generation_result.dart';

/// Editable list of MCQ questions. Each question has editable text, options,
/// a correct-answer dropdown, and an explanation field.
class QuizTab extends StatefulWidget {
  final List<QuizQuestion> questions;
  final ValueChanged<List<QuizQuestion>> onChanged;

  const QuizTab({
    super.key,
    required this.questions,
    required this.onChanged,
  });

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  late List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
  }

  @override
  void didUpdateWidget(QuizTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questions != widget.questions) {
      setState(() => _questions = List.from(widget.questions));
    }
  }

  void _edit(int index) async {
    final edited = await showDialog<QuizQuestion>(
      context: context,
      builder: (_) => _EditQuestionDialog(question: _questions[index]),
    );
    if (edited != null) {
      setState(() => _questions[index] = edited);
      widget.onChanged(List.unmodifiable(_questions));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Center(child: Text('No quiz questions generated.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final q = _questions[index];
        const labels = ['A', 'B', 'C', 'D'];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text('${index + 1}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        q.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit question',
                      onPressed: () => _edit(index),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...q.options.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          e.key == q.correct
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: e.key == q.correct
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text('${labels[e.key]}. ${e.value}'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
                Text(
                  'Explanation: ${q.explanation}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Edit dialog ─────────────────────────────────────────────────────────────

class _EditQuestionDialog extends StatefulWidget {
  final QuizQuestion question;

  const _EditQuestionDialog({required this.question});

  @override
  State<_EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<_EditQuestionDialog> {
  late final TextEditingController _textCtrl;
  late final List<TextEditingController> _optionCtrls;
  late final TextEditingController _explCtrl;
  late int _correct;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.question.text);
    _optionCtrls = widget.question.options
        .map((o) => TextEditingController(text: o))
        .toList();
    _explCtrl = TextEditingController(text: widget.question.explanation);
    _correct = widget.question.correct;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    _explCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['A', 'B', 'C', 'D'];

    return AlertDialog(
      title: const Text('Edit Question'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Question text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ..._optionCtrls.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(
                          labelText: 'Option ${labels[e.key]}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 4),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Correct answer',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButton<int>(
                  value: _correct,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: List.generate(
                    4,
                    (i) => DropdownMenuItem(value: i, child: Text(labels[i])),
                  ),
                  onChanged: (v) => setState(() => _correct = v ?? _correct),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _explCtrl,
                decoration: const InputDecoration(
                  labelText: 'Explanation',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            QuizQuestion(
              text: _textCtrl.text.trim(),
              options: _optionCtrls.map((c) => c.text.trim()).toList(),
              correct: _correct,
              explanation: _explCtrl.text.trim(),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
