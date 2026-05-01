import 'package:flutter/material.dart';

class MaterialPlaceholderScreen extends StatelessWidget {
  final String topicTitle;

  const MaterialPlaceholderScreen({
    super.key,
    required this.topicTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(topicTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'Materials Coming Soon!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Mindmaps, flashcards, infographic, and quiz\nwill be available in the next update.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
