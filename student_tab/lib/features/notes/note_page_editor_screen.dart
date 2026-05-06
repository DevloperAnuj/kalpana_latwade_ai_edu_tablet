import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/note_editor/note_editor_cubit.dart';
import '../../bloc/note_editor/note_editor_state.dart';
import '../../data/models/note_page.dart';
import 'package:go_router/go_router.dart';

import '../../services/ocr/ocr_preferences.dart';
import '../../widgets/handwriting_canvas.dart';

class NotePageEditorScreen extends StatefulWidget {
  final NotePage page;
  final String pageTitle;

  const NotePageEditorScreen({
    super.key,
    required this.page,
    required this.pageTitle,
  });

  @override
  State<NotePageEditorScreen> createState() => _NotePageEditorScreenState();
}

class _NotePageEditorScreenState extends State<NotePageEditorScreen> {
  final _boundaryKey = GlobalKey();
  late final NoteEditorCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = NoteEditorCubit(page: widget.page);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    await _cubit.save();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<NoteEditorCubit, NoteEditorState>(
        listenWhen: (prev, curr) =>
            curr.convertedText != prev.convertedText ||
            curr.ocrFallbackReason != prev.ocrFallbackReason ||
            curr.savedAt != prev.savedAt ||
            curr.saveErrorMessage != prev.saveErrorMessage,
        listener: (context, state) {
          if (state.saveErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.saveErrorMessage!),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state.savedAt != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved to device'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
          if (state.ocrFallbackReason != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.ocrFallbackReason!),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          if (state.convertedText != null) {
            _showOcrResult(context, state.convertedText!, state.ocrEngineUsed);
          }
        },
        builder: (context, state) {
          return PopScope(
            onPopInvokedWithResult: (_, _) => _onWillPop(),
            child: Scaffold(
              appBar: _buildAppBar(context, state),
              body: Column(
                children: [
                  _Toolbar(boundaryKey: _boundaryKey),
                  Expanded(
                    child: Stack(
                      children: [
                        HandwritingCanvas(
                          strokes: state.strokes,
                          tool: state.tool,
                          penColor: state.penColor,
                          penWidth: state.penWidth,
                          pattern: state.pattern,
                          boundaryKey: _boundaryKey,
                          onStrokeComplete: (stroke) =>
                              context.read<NoteEditorCubit>().addStroke(stroke),
                        ),
                        if (state.tool == DrawingTool.pan)
                          Positioned(
                            left: 12,
                            bottom: 20,
                            child: _PanExitButton(
                              onTap: () => context
                                  .read<NoteEditorCubit>()
                                  .setTool(DrawingTool.pen),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, NoteEditorState state) {
    final cubit = context.read<NoteEditorCubit>();
    final activeEngine = OcrPreferences.engine;

    return AppBar(
      title: Text(widget.pageTitle),
      actions: [
        // ── Save locally ────────────────────────────────────────────────────
        if (state.saving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save to device',
            onPressed: () => cubit.save(),
          ),

        // ── Upload to cloud ─────────────────────────────────────────────────
        if (state.uploading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: Icon(
              state.isDirty
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_done_outlined,
            ),
            tooltip: state.isDirty ? 'Upload to cloud' : 'Synced to cloud',
            onPressed: state.isDirty ? () => cubit.uploadToCloud() : null,
          ),

        // ── OCR engine chip ─────────────────────────────────────────────────
        _EngineChip(engine: activeEngine),

        // ── OCR: convert current page ────────────────────────────────────────
        if (state.convertingText)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.text_fields_outlined),
            tooltip: 'Convert handwriting to text',
            onPressed: () => cubit.convertToText(_boundaryKey),
          ),
      ],
    );
  }

  void _showOcrResult(
      BuildContext context, String text, EngineType? engineUsed) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Recognised Text')),
            const SizedBox(width: 8),
            _EngineChip(engine: engineUsed ?? OcrPreferences.engine, small: true),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            text.isEmpty
                ? '(No text recognised — try writing more clearly)'
                : text,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<NoteEditorCubit>().clearConvertedText();
              Navigator.of(ctx).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Toolbar ───────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final GlobalKey boundaryKey;
  const _Toolbar({required this.boundaryKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteEditorCubit, NoteEditorState>(
      builder: (context, state) {
        final cubit = context.read<NoteEditorCubit>();
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // ── Primary tools: always visible, outside scroll view ──────────
              _ToolBtn(
                icon: Icons.edit,
                label: 'Pen',
                selected: state.tool == DrawingTool.pen,
                onTap: () => cubit.setTool(DrawingTool.pen),
              ),
              _ToolBtn(
                icon: Icons.phonelink_erase,
                label: 'Eraser',
                selected: state.tool == DrawingTool.eraser,
                onTap: () => cubit.setTool(DrawingTool.eraser),
              ),
              _ToolBtn(
                icon: Icons.pan_tool_outlined,
                label: 'Pan',
                selected: state.tool == DrawingTool.pan,
                onTap: () => cubit.setTool(DrawingTool.pan),
              ),
              const VerticalDivider(width: 12),
              // ── Secondary tools: scrollable ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StrokeWidthDropdown(
                        value: state.penWidth,
                        onChanged: cubit.setPenWidth,
                      ),
                      const VerticalDivider(width: 16),
                      _ColorDot(
                          color: Colors.black,
                          selected: state.penColor == Colors.black,
                          onTap: () => cubit.setPenColor(Colors.black)),
                      _ColorDot(
                          color: Colors.blue,
                          selected: state.penColor == Colors.blue,
                          onTap: () => cubit.setPenColor(Colors.blue)),
                      _ColorDot(
                          color: Colors.red,
                          selected: state.penColor == Colors.red,
                          onTap: () => cubit.setPenColor(Colors.red)),
                      _ColorDot(
                          color: Colors.green,
                          selected: state.penColor == Colors.green,
                          onTap: () => cubit.setPenColor(Colors.green)),
                      const VerticalDivider(width: 16),
                      _PatternPicker(
                        current: state.pattern,
                        onSelect: cubit.setPattern,
                      ),
                      const VerticalDivider(width: 16),
                      _ToolBtn(
                        icon: Icons.undo,
                        label: 'Undo',
                        selected: false,
                        enabled: state.canUndo,
                        onTap: cubit.undo,
                      ),
                      _ToolBtn(
                        icon: Icons.redo,
                        label: 'Redo',
                        selected: false,
                        enabled: state.canRedo,
                        onTap: cubit.redo,
                      ),
                      _ToolBtn(
                        icon: Icons.delete_sweep_outlined,
                        label: 'Clear',
                        selected: false,
                        onTap: () => _confirmClear(context, cubit),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context, NoteEditorCubit cubit) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear page?'),
        content: const Text('All strokes on this page will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              cubit.clearPage();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ── Stroke width dropdown ─────────────────────────────────────────────────────

class _StrokeWidthDropdown extends StatelessWidget {
  final double value;
  final void Function(double) onChanged;

  const _StrokeWidthDropdown({required this.value, required this.onChanged});

  static const _options = [1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0, 12.0];

  // Snap incoming value to the nearest option (handles legacy slider values)
  double get _snapped => _options.reduce((a, b) =>
      (a - value).abs() <= (b - value).abs() ? a : b);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<double>(
        value: _snapped,
        underline: const SizedBox.shrink(),
        isDense: true,
        items: _options.map((w) {
          return DropdownMenuItem<double>(
            value: w,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  child: Center(
                    child: Container(
                      height: w.clamp(1.0, 10.0),
                      width: 20,
                      decoration: BoxDecoration(
                        color: cs.onSecondaryContainer,
                        borderRadius: BorderRadius.circular(w / 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${w.toInt()}px',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ── Pattern picker ────────────────────────────────────────────────────────────

class _PatternPicker extends StatelessWidget {
  final PagePattern current;
  final void Function(PagePattern) onSelect;
  const _PatternPicker({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<PagePattern>(
      tooltip: 'Page pattern',
      initialValue: current,
      onSelected: onSelect,
      offset: const Offset(0, 36),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(current.icon, size: 16, color: cs.onSecondaryContainer),
            const SizedBox(width: 4),
            Text(
              current.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down,
                size: 14, color: cs.onSecondaryContainer),
          ],
        ),
      ),
      itemBuilder: (_) => PagePattern.values
          .map((p) => PopupMenuItem(
                value: p,
                child: Row(
                  children: [
                    Icon(p.icon, size: 18),
                    const SizedBox(width: 10),
                    Text(p.label),
                    if (p == current) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 16),
                    ],
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── Tool button ───────────────────────────────────────────────────────────────

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 20,
              color: !enabled
                  ? cs.onSurface.withAlpha(60)
                  : selected
                      ? cs.onPrimary
                      : cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ── Engine chip ───────────────────────────────────────────────────────────────

/// Read-only badge showing the active OCR engine. Navigates to Settings on tap.
class _EngineChip extends StatelessWidget {
  final EngineType engine;
  final bool small;

  const _EngineChip({required this.engine, this.small = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, icon, tip) = switch (engine) {
      EngineType.gemini => (
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
        Icons.cloud_outlined,
        'Using Gemini Flash (cloud) — tap to change in Settings',
      ),
      EngineType.myScript => (
        cs.primaryContainer,
        cs.onPrimaryContainer,
        Icons.draw_outlined,
        'Using MyScript iink (offline) — tap to change in Settings',
      ),
      EngineType.mlKit => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        Icons.phone_android_outlined,
        'Using ML Kit (offline) — tap to change in Settings',
      ),
    };

    return Tooltip(
      message: tip,
      child: GestureDetector(
        onTap: () => context.push('/settings'),
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: 4, vertical: small ? 4 : 8),
          padding: EdgeInsets.symmetric(
              horizontal: small ? 6 : 10, vertical: small ? 2 : 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: small ? 12 : 14, color: fg),
              SizedBox(width: small ? 3 : 4),
              Text(
                engine.label,
                style: TextStyle(
                  fontSize: small ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pan exit overlay ──────────────────────────────────────────────────────────

class _PanExitButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PanExitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withAlpha(90),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 16, color: cs.onPrimary),
            const SizedBox(width: 6),
            Text(
              'Back to Pen',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Color dot ─────────────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
        ),
      ),
    );
  }
}
