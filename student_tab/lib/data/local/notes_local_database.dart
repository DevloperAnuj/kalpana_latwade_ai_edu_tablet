import 'package:hive_flutter/hive_flutter.dart';

const _kNotebooks = 'notebooks';
const _kNotePages = 'note_pages';
const _kNotesMeta = 'notes_meta';

abstract final class NotesLocalDatabase {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(_kNotebooks),
      Hive.openBox(_kNotePages),
      Hive.openBox(_kNotesMeta),
    ]);
    _initialized = true;
  }

  static Box get notebooks => Hive.box(_kNotebooks);
  static Box get notePages => Hive.box(_kNotePages);
  static Box get meta => Hive.box(_kNotesMeta);
}
