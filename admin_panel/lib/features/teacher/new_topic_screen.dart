import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../bloc/draft/draft_cubit.dart';
import '../../bloc/generation/generation_bloc.dart';

class NewTopicScreen extends StatefulWidget {
  final String classId;
  final String className;

  const NewTopicScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<NewTopicScreen> createState() => _NewTopicScreenState();
}

class _NewTopicScreenState extends State<NewTopicScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _pasteCtrl = TextEditingController();
  late final TabController _tabController;

  String _uploadedFileName = '';
  String _uploadedText = '';
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<GenerationBloc>().add(const ResetGeneration());

    // Offer to restore draft after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraftRestore());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pasteCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _offerDraftRestore() {
    final draft = context.read<DraftCubit>().state;
    if (draft.isEmpty || !draft.matchesClass(widget.classId)) return;

    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resume Draft?'),
        content: Text(
          'You have a saved draft: "${draft.topicTitle ?? '(no title)'}".\n'
          'Load it now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Start fresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Load draft'),
          ),
        ],
      ),
    ).then((load) {
      if (load != true) return;
      setState(() {
        _titleCtrl.text = draft.topicTitle ?? '';
        _pasteCtrl.text = draft.lessonContent ?? '';
      });

      final result = draft.generationResult;
      if (result != null && mounted) {
        context.read<GenerationBloc>().add(RestoreResult(
              result: result,
              topicTitle: draft.topicTitle ?? '',
              lessonContent: draft.lessonContent ?? '',
              classId: widget.classId,
            ));
      }
    });
  }

  String get _lessonContent =>
      _tabController.index == 0 ? _pasteCtrl.text.trim() : _uploadedText;

  bool get _canGenerate =>
      _titleCtrl.text.trim().isNotEmpty && _lessonContent.isNotEmpty;

  void _generate() {
    final title = _titleCtrl.text.trim();
    final content = _lessonContent;

    context.read<DraftCubit>().saveDraft(
          topicTitle: title,
          lessonContent: content,
          classId: widget.classId,
        );

    context.read<GenerationBloc>().add(GenerateStudyPack(
          topicTitle: title,
          lessonContent: content,
          classId: widget.classId,
        ));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final ext = (file.extension ?? '').toLowerCase();
    final path = file.path;
    if (path == null) return;

    setState(() {
      _isExtracting = true;
      _uploadedFileName = file.name;
      _uploadedText = '';
    });

    try {
      if (ext == 'txt') {
        _uploadedText = await File(path).readAsString();
      } else if (ext == 'pdf') {
        final bytes = await File(path).readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        _uploadedText = PdfTextExtractor(doc).extractText();
        doc.dispose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read file: $e')),
        );
      }
      _uploadedText = '';
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GenerationBloc, GenerationState>(
      listener: (context, state) {
        if (state is GenerationSuccess) {
          // Save result to draft
          context.read<DraftCubit>().saveDraft(
                topicTitle: state.topicTitle,
                lessonContent: state.lessonContent,
                classId: state.classId,
                result: state.result,
              );
          context.push('/teacher/classes/${widget.classId}/topics/preview');
        } else if (state is GenerationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed at "${state.failedStep}": ${state.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _generate,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('New Topic – ${widget.className}'),
        ),
        body: BlocBuilder<GenerationBloc, GenerationState>(
          builder: (context, state) {
            final loadingState =
                state is GenerationLoading ? state : null;
            final isLoading = loadingState != null;
            final step = loadingState?.step ?? '';
            final progress = loadingState?.progress ?? 0.0;

            return Column(
              children: [
                if (isLoading) ...[
                  LinearProgressIndicator(value: progress),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 16),
                    child: Text(step,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _titleCtrl,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Topic title *',
                              hintText: 'e.g. Photosynthesis',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 20),
                          Text('Lesson content *',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Paste text'),
                              Tab(text: 'Upload file'),
                            ],
                            onTap: (_) => setState(() {}),
                          ),
                          SizedBox(
                            height: 280,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // ── Paste tab ─────────────────────────────
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: TextField(
                                    controller: _pasteCtrl,
                                    enabled: !isLoading,
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Paste your lesson content here…',
                                      border: OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),

                                // ── Upload tab ────────────────────────────
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          FilledButton.icon(
                                            onPressed: isLoading || _isExtracting
                                                ? null
                                                : _pickFile,
                                            icon: const Icon(
                                                Icons.upload_file),
                                            label: const Text(
                                                'Pick .txt or .pdf'),
                                          ),
                                          if (_uploadedFileName.isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _uploadedFileName,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ],
                                          if (_isExtracting)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  left: 12),
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _uploadedText.isEmpty
                                                  ? 'Extracted text will appear here.'
                                                  : _uploadedText,
                                              style: _uploadedText.isEmpty
                                                  ? Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      )
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed:
                                _canGenerate && !isLoading ? _generate : null,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(isLoading
                                ? 'Generating…'
                                : 'Generate Study Pack'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
