import 'package:flutter/material.dart';

import '../../../models/generation_result.dart';

/// Read-only tree view of mindmap nodes. Root node (parentId == null) is shown
/// at the top; children are indented. Teachers can regenerate but not edit here.
class MindmapTab extends StatelessWidget {
  final Mindmap mindmap;

  const MindmapTab({super.key, required this.mindmap});

  @override
  Widget build(BuildContext context) {
    final nodes = mindmap.nodes;
    final root = nodes.where((n) => n.parentId == null).toList();

    if (nodes.isEmpty) {
      return const Center(child: Text('No mindmap data.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: root.map((r) => _NodeTile(node: r, allNodes: nodes, depth: 0)).toList(),
    );
  }
}

class _NodeTile extends StatelessWidget {
  final MindmapNode node;
  final List<MindmapNode> allNodes;
  final int depth;

  const _NodeTile({
    required this.node,
    required this.allNodes,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final children = allNodes.where((n) => n.parentId == node.id).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                depth == 0 ? Icons.hub : Icons.circle,
                size: depth == 0 ? 20 : 10,
                color: depth == 0
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.label,
                  style: depth == 0
                      ? Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: colorScheme.primary)
                      : Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (children.isNotEmpty)
            ...children.map(
              (child) => _NodeTile(
                node: child,
                allNodes: allNodes,
                depth: depth + 1,
              ),
            ),
        ],
      ),
    );
  }
}
