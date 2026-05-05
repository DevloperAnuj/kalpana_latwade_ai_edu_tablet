import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/note_page.dart';
import '../../data/models/stroke_data.dart';
import '../../data/repositories/notes_local_repository.dart';

/// Shows all pages of a notebook as a grid of cards.
/// Pages are loaded directly from local storage (fast, no BLoC needed here).
class NotebookDetailScreen extends StatefulWidget {
  final String notebookId;
  final String notebookTitle;

  const NotebookDetailScreen({
    super.key,
    required this.notebookId,
    required this.notebookTitle,
  });

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  final _repo = NotesLocalRepository();
  List<NotePage> _pages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _pages = _repo.getPages(widget.notebookId);
    });
  }

  Future<void> _addPage() async {
    final pageNumber =
        _pages.isEmpty ? 1 : _pages.map((p) => p.pageNumber).reduce((a, b) => a > b ? a : b) + 1;
    final now = DateTime.now();
    final page = NotePage(
      id: NotesLocalRepository.generateId(),
      notebookId: widget.notebookId,
      pageNumber: pageNumber,
      createdAt: now,
      updatedAt: now,
      isDirty: true,
    );
    await _repo.savePage(page);
    if (!mounted) return;
    _load();
    await context.push(
      '/student/notes/${widget.notebookId}/page/${page.id}',
      extra: 'Page $pageNumber',
    );
    if (mounted) _load();
  }

  Future<void> _deletePage(NotePage page) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete page?'),
        content: Text('Page ${page.pageNumber} will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.deletePage(page.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.notebookTitle)),
      body: _pages.isEmpty ? _emptyState() : _grid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPage,
        icon: const Icon(Icons.add),
        label: const Text('New Page'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No pages yet.',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Tap "New Page" to start writing.'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _addPage,
            icon: const Icon(Icons.add),
            label: const Text('New Page'),
          ),
        ],
      ),
    );
  }

  Widget _grid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _pages.length,
      itemBuilder: (context, index) => _PageCard(
        page: _pages[index],
        onTap: () async {
          await context.push(
            '/student/notes/${widget.notebookId}/page/${_pages[index].id}',
            extra: 'Page ${_pages[index].pageNumber}',
          );
          _load();
        },
        onDelete: () => _deletePage(_pages[index]),
      ),
    );
  }
}

// ── Page card ─────────────────────────────────────────────────────────────────

class _PageCard extends StatelessWidget {
  final NotePage page;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PageCard({
    required this.page,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                child: page.strokes.isEmpty
                    ? Center(
                        child: Icon(Icons.edit_outlined,
                            size: 40,
                            color: theme.colorScheme.outlineVariant),
                      )
                    : CustomPaint(
                        painter: _MiniPreviewPainter(page.strokes),
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      page.title ?? 'Page ${page.pageNumber}',
                      style: theme.textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline,
                        size: 18, color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini preview painter ──────────────────────────────────────────────────────

class _MiniPreviewPainter extends CustomPainter {
  final List<StrokeData> strokes;
  const _MiniPreviewPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    const srcW = 2000.0;
    const srcH = 3000.0;
    final scale =
        (size.width / srcW).clamp(0.0, size.height / srcH);

    canvas.save();
    canvas.scale(scale, scale);

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.isEraser ? Colors.white : stroke.color
        ..strokeWidth = stroke.width * 0.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(stroke.points.first.x, stroke.points.first.y);
      for (final p in stroke.points) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MiniPreviewPainter old) => old.strokes != strokes;
}
