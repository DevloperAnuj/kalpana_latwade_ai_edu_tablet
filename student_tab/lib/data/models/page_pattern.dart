import 'package:flutter/material.dart';

enum PagePattern {
  ruled,
  grid,
  graph;

  String get value => name;

  static PagePattern fromValue(String? v) => switch (v) {
        'grid' => PagePattern.grid,
        'graph' => PagePattern.graph,
        _ => PagePattern.ruled,
      };

  String get label => switch (this) {
        PagePattern.ruled => 'Ruled',
        PagePattern.grid => 'Grid',
        PagePattern.graph => 'Graph',
      };

  IconData get icon => switch (this) {
        PagePattern.ruled => Icons.format_line_spacing,
        PagePattern.grid => Icons.grid_4x4,
        PagePattern.graph => Icons.grid_on,
      };
}
