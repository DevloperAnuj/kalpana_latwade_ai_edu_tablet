import 'package:flutter/material.dart';

import '../../../models/generation_result.dart';

/// Editable list of infographic sections. Tapping a section opens an edit dialog.
class InfographicTab extends StatefulWidget {
  final Infographic infographic;
  final ValueChanged<Infographic> onChanged;

  const InfographicTab({
    super.key,
    required this.infographic,
    required this.onChanged,
  });

  @override
  State<InfographicTab> createState() => _InfographicTabState();
}

class _InfographicTabState extends State<InfographicTab> {
  late List<InfographicSection> _sections;

  @override
  void initState() {
    super.initState();
    _sections = List.from(widget.infographic.sections);
  }

  @override
  void didUpdateWidget(InfographicTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.infographic != widget.infographic) {
      setState(() => _sections = List.from(widget.infographic.sections));
    }
  }

  void _edit(int index) async {
    final edited = await showDialog<InfographicSection>(
      context: context,
      builder: (_) => _EditSectionDialog(section: _sections[index]),
    );
    if (edited != null) {
      setState(() => _sections[index] = edited);
      widget.onChanged(Infographic(sections: List.unmodifiable(_sections)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sections.isEmpty) {
      return const Center(child: Text('No infographic data.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _sections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final section = _sections[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _resolveIcon(section.iconReference),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit section',
                      onPressed: () => _edit(index),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...section.bullets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(b)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _resolveIcon(String? ref) {
    return switch (ref?.toLowerCase()) {
      'science' => Icons.science,
      'nature' => Icons.nature,
      'lightbulb' => Icons.lightbulb_outline,
      'water_drop' => Icons.water_drop,
      'star' => Icons.star_outline,
      'book' => Icons.menu_book,
      'timeline' => Icons.timeline,
      'group' => Icons.group_outlined,
      'settings' => Icons.settings_outlined,
      'check' => Icons.check_circle_outline,
      _ => Icons.info_outline,
    };
  }
}

class _EditSectionDialog extends StatefulWidget {
  final InfographicSection section;

  const _EditSectionDialog({required this.section});

  @override
  State<_EditSectionDialog> createState() => _EditSectionDialogState();
}

class _EditSectionDialogState extends State<_EditSectionDialog> {
  late final TextEditingController _titleCtrl;
  late final List<TextEditingController> _bulletCtrls;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.section.title);
    _bulletCtrls = widget.section.bullets
        .map((b) => TextEditingController(text: b))
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _bulletCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Section'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Section title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Bullet points:'),
              const SizedBox(height: 8),
              ..._bulletCtrls.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: 'Bullet ${entry.key + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
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
            widget.section.copyWith(
              title: _titleCtrl.text.trim(),
              bullets: _bulletCtrls
                  .map((c) => c.text.trim())
                  .where((t) => t.isNotEmpty)
                  .toList(),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
