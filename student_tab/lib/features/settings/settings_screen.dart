import 'package:flutter/material.dart';

import '../../services/ocr/ocr_engine.dart';
import '../../services/ocr/ocr_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late EngineType _engine;
  late int _callCount;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _engine = OcrPreferences.engine;
    _callCount = OcrPreferences.monthlyCallCount;
  }

  Future<void> _setEngine(EngineType? type) async {
    if (type == null) return;
    await OcrPreferences.setEngine(type);
    if (mounted) setState(() => _engine = type);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOver = OcrPreferences.isOverQuota;
    final fraction =
        (_callCount / OcrPreferences.monthlyLimit).clamp(0.0, 1.0);
    final nearLimit =
        !isOver && _callCount >= OcrPreferences.monthlyLimit - 5;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── OCR engine ──────────────────────────────────────────────────
          Text(
            'Handwriting Recognition Engine',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Choose which OCR engine powers the "Convert to Text" button '
            'in the note editor.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: RadioGroup<EngineType>(
              groupValue: _engine,
              onChanged: _setEngine,
              child: const Column(
                children: [
                  RadioListTile<EngineType>(
                    title: Text('ML Kit  (Offline)'),
                    subtitle: Text('Fast · free · no internet required'),
                    value: EngineType.mlKit,
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<EngineType>(
                    title: Text('MyScript iink  (Offline)'),
                    subtitle: Text(
                      'World-class handwriting recognition · '
                      'works offline · requires language assets in app',
                    ),
                    value: EngineType.myScript,
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<EngineType>(
                    title: Text('Gemini Flash  (Cloud)'),
                    subtitle: Text(
                      'Highest accuracy for messy or cursive handwriting · '
                      'requires internet · uses monthly quota',
                    ),
                    value: EngineType.gemini,
                  ),
                ],
              ),
            ),
          ),

          // ── Quota (only when Gemini is selected) ────────────────────────
          if (_engine == EngineType.gemini) ...[
            const SizedBox(height: 24),
            Text(
              'Monthly Cloud OCR Quota',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_callCount / ${OcrPreferences.monthlyLimit} calls used this month',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (isOver)
                          Chip(
                            label: const Text('Quota reached'),
                            backgroundColor: cs.errorContainer,
                            labelStyle:
                                TextStyle(color: cs.onErrorContainer, fontSize: 12),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: isOver || nearLimit ? cs.error : cs.primary,
                      ),
                    ),
                    if (nearLimit) ...[
                      const SizedBox(height: 8),
                      Text(
                        'You are close to your monthly limit. '
                        'Switch to ML Kit to avoid losing cloud OCR.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.error,
                        ),
                      ),
                    ] else if (isOver) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Cloud OCR is paused for this month. '
                        'Recognition will automatically fall back to ML Kit. '
                        'Quota resets on the 1st of next month.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // ── Info ────────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Text(
            'About Gemini OCR',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gemini Flash is processed via a secure cloud function — '
                'your handwriting image is sent to Google\'s servers and '
                'deleted after recognition. When offline or over quota, '
                'the app automatically falls back to on-device ML Kit.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
