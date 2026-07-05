import 'package:flutter/gestures.dart'
    show PointerDeviceKind, PointerHoverEvent;
import 'package:flutter/material.dart';

import '../bloc/note_editor/note_editor_state.dart';
import '../core/theme/app_colors.dart';
import '../data/models/stroke_data.dart';

export '../data/models/page_pattern.dart';

const double kCanvasWidth = 2000;
const double kCanvasHeight = 3000;

/// Scrollable, zoomable handwriting canvas with two independent paint layers:
///
/// 1. [_BackgroundPainter] — draws the page pattern (ruled / grid / graph).
///    Never repainted because of stroke changes.
/// 2. [_StrokePainter] — draws user ink strokes on a transparent surface.
///    Eraser strokes are rendered as a grey outline (visual feedback only);
///    the actual removal happens in NoteEditorCubit so the background is
///    never affected.
class HandwritingCanvas extends StatefulWidget {
  final List<StrokeData> strokes;
  final DrawingTool tool;
  final Color penColor;
  final double penWidth;
  final PagePattern pattern;
  final GlobalKey boundaryKey;
  final void Function(StrokeData stroke) onStrokeComplete;

  const HandwritingCanvas({
    super.key,
    required this.strokes,
    required this.tool,
    required this.penColor,
    required this.penWidth,
    required this.boundaryKey,
    required this.onStrokeComplete,
    this.pattern = PagePattern.ruled,
  });

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  // Palm rejection. Devices with an active pen (e.g. Redmi Pad 2 + Smart Pen)
  // expose it as a separate stylus digitizer that also reports *hover* — the
  // pen is detected above the glass before the palm lands. So: once any
  // stylus event (hover or contact) is seen, touch-kind pointers are barred
  // from drawing for the rest of the session. Finger drawing still works on
  // devices where no stylus ever appears. The radius heuristic is a fallback
  // for a palm landing before the very first stylus event.
  static const _palmRadiusThreshold = 30.0; // logical px

  final _transformController = TransformationController();
  List<StrokePoint> _currentPoints = [];
  int? _activePointer;
  bool _stylusSeen = false;

  // ── Pointer callbacks ─────────────────────────────────────────────────────

  void _noteKind(PointerDeviceKind kind) {
    if (kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus) {
      _stylusSeen = true;
    }
  }

  bool _shouldRejectAsPalm(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return false;
    if (_stylusSeen) return true;
    // A resting palm has a much larger contact patch than a fingertip.
    return event.radiusMajor > _palmRadiusThreshold;
  }

  void _onHover(PointerHoverEvent event) => _noteKind(event.kind);

  void _onDown(PointerDownEvent event) {
    _noteKind(event.kind);
    if (widget.tool == DrawingTool.pan) return;
    if (_shouldRejectAsPalm(event)) return;

    // A stylus takes over even if a touch pointer (palm that slipped through
    // the heuristics) is already drawing — its partial stroke is discarded.
    final isStylus = event.kind != PointerDeviceKind.touch && _stylusSeen;
    if (_activePointer != null && !isStylus) return;

    _activePointer = event.pointer;
    setState(() {
      _currentPoints = [
        StrokePoint(event.localPosition.dx, event.localPosition.dy,
            event.pressure, event.timeStamp.inMilliseconds)
      ];
    });
  }

  void _onMove(PointerMoveEvent event) {
    if (widget.tool == DrawingTool.pan) return;
    if (event.pointer != _activePointer || _currentPoints.isEmpty) return;
    setState(() {
      _currentPoints = [
        ..._currentPoints,
        StrokePoint(event.localPosition.dx, event.localPosition.dy,
            event.pressure, event.timeStamp.inMilliseconds),
      ];
    });
  }

  void _onUp(PointerUpEvent event) {
    if (widget.tool == DrawingTool.pan) return;
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    if (_currentPoints.isEmpty) return;
    final stroke = StrokeData(
      points: List<StrokePoint>.from(_currentPoints),
      color: widget.penColor,
      width: widget.penWidth,
      isEraser: widget.tool == DrawingTool.eraser,
    );
    widget.onStrokeComplete(stroke);
    setState(() => _currentPoints = []);
  }

  void _onCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    setState(() => _currentPoints = []);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPan = widget.tool == DrawingTool.pan;
    final currentStroke = _currentPoints.isEmpty
        ? null
        : StrokeData(
            points: _currentPoints,
            color: widget.penColor,
            width: widget.penWidth,
            isEraser: widget.tool == DrawingTool.eraser,
          );

    return InteractiveViewer(
      transformationController: _transformController,
      constrained: false,
      panEnabled: isPan,
      scaleEnabled: isPan,
      minScale: 0.25,
      maxScale: 5.0,
      child: RepaintBoundary(
        key: widget.boundaryKey,
        child: SizedBox(
          width: kCanvasWidth,
          height: kCanvasHeight,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerHover: _onHover,
            onPointerDown: _onDown,
            onPointerMove: _onMove,
            onPointerUp: _onUp,
            onPointerCancel: _onCancel,
            child: Stack(
              children: [
                // Layer 1: static background (pattern lines)
                CustomPaint(
                  painter: _BackgroundPainter(pattern: widget.pattern),
                  size: const Size(kCanvasWidth, kCanvasHeight),
                ),
                // Layer 2: user strokes (eraser never touches layer 1)
                CustomPaint(
                  painter: _StrokePainter(
                    committed: widget.strokes,
                    current: currentStroke,
                  ),
                  size: const Size(kCanvasWidth, kCanvasHeight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }
}

// ── Background painter ────────────────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  final PagePattern pattern;
  const _BackgroundPainter({required this.pattern});

  static const double _ruledSpacing = 50.0;
  static const double _graphMinor = 25.0;
  static const double _graphMajor = 125.0; // every 5 minor squares
  static const double _gridSpacing = 50.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    switch (pattern) {
      case PagePattern.ruled:
        _drawLines(canvas, size,
            horizontal: true, spacing: _ruledSpacing,
            color: AppColors.ruledLineColor, strokeWidth: 0.8);
      case PagePattern.grid:
        _drawLines(canvas, size,
            horizontal: true, spacing: _gridSpacing,
            color: AppColors.gridLineColor, strokeWidth: 0.6);
        _drawLines(canvas, size,
            horizontal: false, spacing: _gridSpacing,
            color: AppColors.gridLineColor, strokeWidth: 0.6);
      case PagePattern.graph:
        _drawGraphLines(canvas, size);
    }
  }

  void _drawLines(Canvas canvas, Size size,
      {required bool horizontal,
      required double spacing,
      required Color color,
      required double strokeWidth}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    if (horizontal) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  void _drawGraphLines(Canvas canvas, Size size) {
    const minorWidth = 0.5;
    const majorWidth = 1.0;

    final minorPaint = Paint()
      ..color = AppColors.graphMinorColor
      ..strokeWidth = minorWidth;
    final majorPaint = Paint()
      ..color = AppColors.graphMajorColor
      ..strokeWidth = majorWidth;

    // Horizontal
    for (double y = _graphMinor; y < size.height; y += _graphMinor) {
      final isMajor = (y % _graphMajor).abs() < 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          isMajor ? majorPaint : minorPaint);
    }
    // Vertical
    for (double x = _graphMinor; x < size.width; x += _graphMinor) {
      final isMajor = (x % _graphMajor).abs() < 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          isMajor ? majorPaint : minorPaint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.pattern != pattern;
}

// ── Stroke painter ────────────────────────────────────────────────────────────

class _StrokePainter extends CustomPainter {
  final List<StrokeData> committed;
  final StrokeData? current;

  const _StrokePainter({required this.committed, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in committed) {
      _drawStroke(canvas, stroke);
    }
    if (current != null) {
      _drawStroke(canvas, current!);
    }
  }

  void _drawStroke(Canvas canvas, StrokeData stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.isEraser) {
      // Visual feedback only — grey translucent outline.
      // Actual stroke removal is handled in NoteEditorCubit.
      paint
        ..color = Colors.grey.withAlpha(100)
        ..strokeWidth = stroke.width * 4;
    } else {
      paint
        ..color = stroke.color
        ..strokeWidth = stroke.width;
    }

    if (stroke.points.length == 1) {
      final p = stroke.points.first;
      canvas.drawCircle(Offset(p.x, p.y), paint.strokeWidth / 2, paint);
      return;
    }

    final path = Path()
      ..moveTo(stroke.points.first.x, stroke.points.first.y);

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final curr = stroke.points[i];
      final next = stroke.points[i + 1];
      final midX = (curr.x + next.x) / 2;
      final midY = (curr.y + next.y) / 2;
      path.quadraticBezierTo(curr.x, curr.y, midX, midY);
    }

    path.lineTo(stroke.points.last.x, stroke.points.last.y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.committed != committed || old.current != current;
}
