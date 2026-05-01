import 'package:flutter/material.dart';

import '../../../models/generation_result.dart';

// ── Layout constants ──────────────────────────────────────────────────────────

const double _kRootW = 210.0;
const double _kNodeW = 148.0;
const double _kNodeH = 40.0;
const double _kHGap = 52.0; // horizontal gap between parent right-edge and children
const double _kRowGap = 14.0; // vertical gap between sibling slots

double _mmX(int depth) =>
    depth == 0 ? 0.0 : _kRootW + _kHGap + (depth - 1) * (_kNodeW + _kHGap);

double _mmW(int depth) => depth == 0 ? _kRootW : _kNodeW;

// ── Public widget (drop-in replacement for the old list view) ─────────────────

class MindmapTab extends StatelessWidget {
  final Mindmap mindmap;

  const MindmapTab({super.key, required this.mindmap});

  @override
  Widget build(BuildContext context) {
    final nodes = mindmap.nodes;

    if (nodes.isEmpty) {
      return const Center(child: Text('No mindmap data.'));
    }

    final childrenMap = <String?, List<MindmapNode>>{};
    for (final n in nodes) {
      childrenMap.putIfAbsent(n.parentId, () => []).add(n);
    }

    final roots = childrenMap[null] ?? [];
    if (roots.isEmpty) {
      return const Center(child: Text('No mindmap data.'));
    }

    // ── Position every node ───────────────────────────────────────────────────
    final positions = <String, Offset>{};
    final depths = <String, int>{};

    double totalH = 0;
    for (final root in roots) {
      totalH += _layout(root, 0, totalH, childrenMap, positions, depths);
    }

    // ── Collect bezier edges ──────────────────────────────────────────────────
    final edges = <_Edge>[];
    _collectEdges(roots, childrenMap, positions, depths, edges);

    // ── Canvas size ───────────────────────────────────────────────────────────
    int maxDepth = 0;
    for (final d in depths.values) {
      if (d > maxDepth) maxDepth = d;
    }
    final canvasW = _mmX(maxDepth) + _mmW(maxDepth) + 40;
    final canvasH = totalH + 40;

    final cs = Theme.of(context).colorScheme;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(80),
      minScale: 0.25,
      maxScale: 3.5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: canvasW,
          height: canvasH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _EdgePainter(
                    edges: edges,
                    lineColor: cs.primary.withValues(alpha: 0.45),
                  ),
                ),
              ),
              ...positions.entries.map((e) {
                final node = nodes.firstWhere((n) => n.id == e.key);
                final depth = depths[e.key]!;
                return Positioned(
                  left: e.value.dx,
                  top: e.value.dy - _kNodeH / 2,
                  child: _NodeBox(
                    label: node.label,
                    width: _mmW(depth),
                    isRoot: depth == 0,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Layout algorithm ──────────────────────────────────────────────────────────

double _layout(
  MindmapNode node,
  int depth,
  double startY,
  Map<String?, List<MindmapNode>> childrenMap,
  Map<String, Offset> positions,
  Map<String, int> depths,
) {
  depths[node.id] = depth;
  final children = childrenMap[node.id] ?? [];

  if (children.isEmpty) {
    positions[node.id] = Offset(_mmX(depth), startY + _kNodeH / 2);
    return _kNodeH + _kRowGap;
  }

  double childY = startY;
  for (final child in children) {
    childY += _layout(child, depth + 1, childY, childrenMap, positions, depths);
  }

  final firstCY = positions[children.first.id]!.dy;
  final lastCY = positions[children.last.id]!.dy;
  positions[node.id] = Offset(_mmX(depth), (firstCY + lastCY) / 2);

  return childY - startY;
}

void _collectEdges(
  List<MindmapNode> nodes,
  Map<String?, List<MindmapNode>> childrenMap,
  Map<String, Offset> positions,
  Map<String, int> depths,
  List<_Edge> edges,
) {
  for (final node in nodes) {
    final children = childrenMap[node.id] ?? [];
    if (children.isEmpty) continue;

    final pPos = positions[node.id]!;
    final pDepth = depths[node.id]!;
    final fromX = pPos.dx + _mmW(pDepth);

    for (final child in children) {
      final cPos = positions[child.id]!;
      edges.add(_Edge(from: Offset(fromX, pPos.dy), to: Offset(cPos.dx, cPos.dy)));
    }
    _collectEdges(children, childrenMap, positions, depths, edges);
  }
}

// ── Edge data + painter ───────────────────────────────────────────────────────

class _Edge {
  final Offset from, to;
  const _Edge({required this.from, required this.to});
}

class _EdgePainter extends CustomPainter {
  final List<_Edge> edges;
  final Color lineColor;

  const _EdgePainter({required this.edges, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final e in edges) {
      final cpX = e.from.dx + (e.to.dx - e.from.dx) * 0.5;
      final path = Path()
        ..moveTo(e.from.dx, e.from.dy)
        ..cubicTo(cpX, e.from.dy, cpX, e.to.dy, e.to.dx, e.to.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.edges != edges || old.lineColor != lineColor;
}

// ── Node box ──────────────────────────────────────────────────────────────────

class _NodeBox extends StatelessWidget {
  final String label;
  final double width;
  final bool isRoot;

  const _NodeBox({
    required this.label,
    required this.width,
    required this.isRoot,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: _kNodeH,
      decoration: BoxDecoration(
        color: isRoot ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRoot ? cs.primary : cs.primary.withValues(alpha: 0.5),
          width: isRoot ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: isRoot ? 0.22 : 0.08),
            blurRadius: isRoot ? 12 : 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: isRoot ? cs.onPrimaryContainer : cs.onSurface,
          fontSize: isRoot ? 13 : 12,
          fontWeight: isRoot ? FontWeight.w600 : FontWeight.w400,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}
