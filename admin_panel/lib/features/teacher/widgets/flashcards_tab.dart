import 'package:flutter/material.dart';

import '../../../models/generation_result.dart';

/// Editable list of flashcards. Tapping a card opens an edit dialog.
class FlashcardsTab extends StatefulWidget {
  final List<Flashcard> flashcards;
  final ValueChanged<List<Flashcard>> onChanged;

  const FlashcardsTab({
    super.key,
    required this.flashcards,
    required this.onChanged,
  });

  @override
  State<FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  late List<Flashcard> _cards;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.flashcards);
  }

  @override
  void didUpdateWidget(FlashcardsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flashcards != widget.flashcards) {
      setState(() => _cards = List.from(widget.flashcards));
    }
  }

  void _edit(int index) async {
    final edited = await showDialog<Flashcard>(
      context: context,
      builder: (_) => _EditFlashcardDialog(card: _cards[index]),
    );
    if (edited != null) {
      setState(() => _cards[index] = edited);
      widget.onChanged(List.unmodifiable(_cards));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const Center(child: Text('No flashcards generated.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}',
                  style: const TextStyle(fontSize: 12)),
            ),
            title: Text(
              card.term,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(card.definition),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => _edit(index),
            ),
          ),
        );
      },
    );
  }
}

class _EditFlashcardDialog extends StatefulWidget {
  final Flashcard card;

  const _EditFlashcardDialog({required this.card});

  @override
  State<_EditFlashcardDialog> createState() => _EditFlashcardDialogState();
}

class _EditFlashcardDialogState extends State<_EditFlashcardDialog> {
  late final TextEditingController _termCtrl;
  late final TextEditingController _defCtrl;

  @override
  void initState() {
    super.initState();
    _termCtrl = TextEditingController(text: widget.card.term);
    _defCtrl = TextEditingController(text: widget.card.definition);
  }

  @override
  void dispose() {
    _termCtrl.dispose();
    _defCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Flashcard'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _termCtrl,
              decoration: const InputDecoration(
                labelText: 'Term',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _defCtrl,
              decoration: const InputDecoration(
                labelText: 'Definition',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            Flashcard(
              term: _termCtrl.text.trim(),
              definition: _defCtrl.text.trim(),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
