import 'package:flutter/material.dart';

import '../../../models/generation_result.dart';

/// Editable spreadsheet-style table. Each cell is a TextField.
class TableTab extends StatefulWidget {
  final TableData tableData;
  final ValueChanged<TableData> onChanged;

  const TableTab({
    super.key,
    required this.tableData,
    required this.onChanged,
  });

  @override
  State<TableTab> createState() => _TableTabState();
}

class _TableTabState extends State<TableTab> {
  late List<String> _headers;
  late List<List<TextEditingController>> _cellCtrls;

  @override
  void initState() {
    super.initState();
    _init(widget.tableData);
  }

  void _init(TableData data) {
    _headers = List.from(data.headers);
    _cellCtrls = data.rows
        .map((row) => row.map((v) => TextEditingController(text: v)).toList())
        .toList();
  }

  @override
  void didUpdateWidget(TableTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tableData != widget.tableData) {
      for (final row in _cellCtrls) {
        for (final c in row) {
          c.dispose();
        }
      }
      setState(() => _init(widget.tableData));
    }
  }

  @override
  void dispose() {
    for (final row in _cellCtrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _notifyChanged() {
    final rows = _cellCtrls
        .map((row) => row.map((c) => c.text).toList())
        .toList();
    widget.onChanged(TableData(headers: _headers, rows: rows));
  }

  @override
  Widget build(BuildContext context) {
    if (_headers.isEmpty) {
      return const Center(child: Text('No table data.'));
    }

    const cellWidth = 160.0;
    const cellHeight = 48.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: _headers
                  .map(
                    (h) => Container(
                      width: cellWidth,
                      height: cellHeight,
                      margin: const EdgeInsets.only(right: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        h,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
            ),
            // Data rows
            ..._cellCtrls.asMap().entries.map(
              (rowEntry) => Row(
                children: rowEntry.value.asMap().entries.map(
                  (cellEntry) {
                    return Container(
                      width: cellWidth,
                      height: cellHeight,
                      margin: const EdgeInsets.only(right: 4, bottom: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: TextField(
                        controller: cellEntry.value,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                        onChanged: (_) => _notifyChanged(),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
