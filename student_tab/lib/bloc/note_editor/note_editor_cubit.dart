import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:eduforge_core/eduforge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/note_page.dart';
import '../../data/models/stroke_data.dart';
import '../../data/repositories/notes_local_repository.dart';
import '../../data/repositories/notes_remote_repository.dart';
import '../../services/ocr/ocr_preferences.dart';
import '../../services/ocr/ocr_service.dart';
import 'note_editor_state.dart';

class NoteEditorCubit extends Cubit<NoteEditorState> {
  NoteEditorCubit({required NotePage page})
      : _local = NotesLocalRepository(),
        _remote = NotesRemoteRepository(),
        super(NoteEditorState(
          page: page,
          strokes: List<StrokeData>.from(page.strokes),
          pattern: page.pattern,
        ));

  final NotesLocalRepository _local;
  final NotesRemoteRepository _remote;

  final List<List<StrokeData>> _undoStack = [];
  final List<List<StrokeData>> _redoStack = [];
  static const int _maxHistory = 30;

  // ── Tool / pen settings ───────────────────────────────────────────────────

  void setTool(DrawingTool tool) => emit(state.copyWith(tool: tool));
  void setPenColor(Color color) => emit(state.copyWith(penColor: color));
  void setPenWidth(double width) => emit(state.copyWith(penWidth: width));
  void setPattern(PagePattern pattern) =>
      emit(state.copyWith(pattern: pattern));

  // ── Stroke management ─────────────────────────────────────────────────────

  void addStroke(StrokeData stroke) {
    if (stroke.isEraser) {
      _eraseIntersecting(stroke);
      return;
    }
    _pushHistory();
    emit(state.copyWith(
      strokes: [...state.strokes, stroke],
      canUndo: true,
      canRedo: false,
    ));
  }

  /// Removes all committed strokes that have any point within the eraser radius.
  void _eraseIntersecting(StrokeData eraser) {
    final radius = eraser.width * 2.0;
    final radiusSq = radius * radius;
    final eraserPts = eraser.points;
    if (eraserPts.isEmpty) return;

    final toRemove = <StrokeData>{};
    outer:
    for (final stroke in state.strokes) {
      for (final sp in stroke.points) {
        for (final ep in eraserPts) {
          final dx = sp.x - ep.x;
          final dy = sp.y - ep.y;
          if (dx * dx + dy * dy <= radiusSq) {
            toRemove.add(stroke);
            continue outer;
          }
        }
      }
    }

    if (toRemove.isEmpty) return;
    _pushHistory();
    emit(state.copyWith(
      strokes: state.strokes.where((s) => !toRemove.contains(s)).toList(),
      canUndo: true,
      canRedo: false,
    ));
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List<StrokeData>.from(state.strokes));
    final previous = _undoStack.removeLast();
    emit(state.copyWith(
      strokes: previous,
      canUndo: _undoStack.isNotEmpty,
      canRedo: true,
    ));
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _pushHistory();
    final next = _redoStack.removeLast();
    emit(state.copyWith(
      strokes: next,
      canUndo: true,
      canRedo: _redoStack.isNotEmpty,
    ));
  }

  void clearPage() {
    _pushHistory();
    emit(state.copyWith(strokes: [], canUndo: true, canRedo: false));
  }

  void _pushHistory() {
    _undoStack.add(List<StrokeData>.from(state.strokes));
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  // ── Save (local only) ─────────────────────────────────────────────────────

  Future<void> save() async {
    emit(state.copyWith(saving: true));
    final updated = state.page.copyWith(
      strokes: state.strokes,
      pattern: state.pattern,
      updatedAt: DateTime.now(),
      isDirty: true,
    );
    try {
      await _local.savePage(updated);
      emit(state.copyWith(
        page: updated,
        saving: false,
        savedAt: () => DateTime.now(),
        saveErrorMessage: () => null,
      ));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'NoteEditorCubit.save');
      emit(state.copyWith(
        saving: false,
        saveErrorMessage: () => 'Could not save — please try again.',
        savedAt: () => null,
      ));
    }
  }

  // ── Upload to cloud ───────────────────────────────────────────────────────

  Future<void> uploadToCloud() async {
    if (state.uploading) return;
    emit(state.copyWith(uploading: true));
    try {
      final toUpload = state.page.copyWith(
        strokes: state.strokes,
        pattern: state.pattern,
        updatedAt: DateTime.now(),
        isDirty: false,
      );
      await _local.savePage(toUpload);
      await _remote.upsertPage(toUpload);
      emit(state.copyWith(page: toUpload, uploading: false));
    } catch (e, st) {
      ErrorLogger.instance
          .logError(e, st, context: 'NoteEditorCubit.uploadToCloud');
      emit(state.copyWith(uploading: false));
    }
  }

  // ── OCR ───────────────────────────────────────────────────────────────────

  Future<void> convertToText(GlobalKey boundaryKey) async {
    emit(state.copyWith(
      convertingText: true,
      convertedText: () => null,
      ocrEngineUsed: () => null,
      ocrFallbackReason: () => null,
    ));

    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      emit(state.copyWith(convertingText: false));
      return;
    }

    if (OcrPreferences.engine == EngineType.myScript) {
      try {
        final result = await OcrService.recognizeStrokes(state.strokes);
        emit(state.copyWith(
          convertingText: false,
          convertedText: () => result.text,
          ocrEngineUsed: () => result.engineUsed,
          ocrFallbackReason: () => null,
        ));
        return;
      } catch (e, st) {
        ErrorLogger.instance
            .logError(e, st, context: 'NoteEditorCubit.myScript');
      }
    }

    final imagePath = await _captureToFile(boundary, state.page.id);
    if (imagePath == null) {
      emit(state.copyWith(convertingText: false));
      return;
    }
    try {
      final result = OcrPreferences.engine == EngineType.myScript
          ? await OcrService.recognizeFallback(
              imagePath, 'MyScript failed — using offline OCR')
          : await OcrService.recognize(imagePath);

      emit(state.copyWith(
        convertingText: false,
        convertedText: () => result.text,
        ocrEngineUsed: () => result.engineUsed,
        ocrFallbackReason: () =>
            result.usedFallback ? result.fallbackReason : null,
      ));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'NoteEditorCubit.ocr');
      emit(state.copyWith(convertingText: false));
    } finally {
      unawaited(
          File(imagePath).delete().catchError((Object _) => File(imagePath)));
    }
  }

  void clearConvertedText() => emit(state.copyWith(
        convertedText: () => null,
        ocrEngineUsed: () => null,
        ocrFallbackReason: () => null,
      ));

  static Future<String?> _captureToFile(
    RenderRepaintBoundary boundary,
    String pageId,
  ) async {
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/eduforge_ocr_$pageId.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }
}
