import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Colors;

import '../../data/models/note_page.dart';
import '../../data/models/page_pattern.dart';
import '../../data/models/stroke_data.dart';
import '../../services/ocr/ocr_engine.dart';

export '../../data/models/page_pattern.dart';
export '../../services/ocr/ocr_engine.dart' show EngineType;

enum DrawingTool { pen, eraser, pan }

class NoteEditorState extends Equatable {
  final NotePage page;
  final List<StrokeData> strokes;
  final DrawingTool tool;
  final Color penColor;
  final double penWidth;
  final PagePattern pattern;
  final bool canUndo;
  final bool canRedo;
  final bool saving;
  final bool uploading;
  final bool convertingText;
  final String? convertedText;
  final EngineType? ocrEngineUsed;
  final String? ocrFallbackReason;
  // Set to DateTime.now() on each successful save so every save triggers the listener.
  final DateTime? savedAt;
  final String? saveErrorMessage;

  const NoteEditorState({
    required this.page,
    required this.strokes,
    this.tool = DrawingTool.pen,
    this.penColor = Colors.black,
    this.penWidth = 3.0,
    this.pattern = PagePattern.ruled,
    this.canUndo = false,
    this.canRedo = false,
    this.saving = false,
    this.uploading = false,
    this.convertingText = false,
    this.convertedText,
    this.ocrEngineUsed,
    this.ocrFallbackReason,
    this.savedAt,
    this.saveErrorMessage,
  });

  bool get isDirty => page.isDirty;

  NoteEditorState copyWith({
    NotePage? page,
    List<StrokeData>? strokes,
    DrawingTool? tool,
    Color? penColor,
    double? penWidth,
    PagePattern? pattern,
    bool? canUndo,
    bool? canRedo,
    bool? saving,
    bool? uploading,
    bool? convertingText,
    String? Function()? convertedText,
    EngineType? Function()? ocrEngineUsed,
    String? Function()? ocrFallbackReason,
    DateTime? Function()? savedAt,
    String? Function()? saveErrorMessage,
  }) =>
      NoteEditorState(
        page: page ?? this.page,
        strokes: strokes ?? this.strokes,
        tool: tool ?? this.tool,
        penColor: penColor ?? this.penColor,
        penWidth: penWidth ?? this.penWidth,
        pattern: pattern ?? this.pattern,
        canUndo: canUndo ?? this.canUndo,
        canRedo: canRedo ?? this.canRedo,
        saving: saving ?? this.saving,
        uploading: uploading ?? this.uploading,
        convertingText: convertingText ?? this.convertingText,
        convertedText:
            convertedText != null ? convertedText() : this.convertedText,
        ocrEngineUsed:
            ocrEngineUsed != null ? ocrEngineUsed() : this.ocrEngineUsed,
        ocrFallbackReason: ocrFallbackReason != null
            ? ocrFallbackReason()
            : this.ocrFallbackReason,
        savedAt: savedAt != null ? savedAt() : this.savedAt,
        saveErrorMessage: saveErrorMessage != null
            ? saveErrorMessage()
            : this.saveErrorMessage,
      );

  @override
  List<Object?> get props => [
        page, strokes, tool, penColor, penWidth, pattern,
        canUndo, canRedo, saving, uploading, convertingText,
        convertedText, ocrEngineUsed, ocrFallbackReason,
        savedAt, saveErrorMessage,
      ];
}
