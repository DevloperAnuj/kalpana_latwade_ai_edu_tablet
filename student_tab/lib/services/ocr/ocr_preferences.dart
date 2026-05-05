import 'package:hive/hive.dart';

import '../../data/local/notes_local_database.dart';
import 'ocr_engine.dart';

abstract final class OcrPreferences {
  static const _engineKey = 'ocr_engine';
  static const _countKey = 'ocr_monthly_count';
  static const _monthKey = 'ocr_month';
  static const monthlyLimit = 100;

  static Box get _box => NotesLocalDatabase.meta;

  static EngineType get engine {
    final raw = _box.get(_engineKey, defaultValue: 'mlKit') as String;
    return EngineType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => EngineType.mlKit,
    );
  }

  static Future<void> setEngine(EngineType type) =>
      _box.put(_engineKey, type.name);

  static int get monthlyCallCount {
    _resetIfNewMonth();
    return _box.get(_countKey, defaultValue: 0) as int;
  }

  static bool get isOverQuota => monthlyCallCount >= monthlyLimit;

  static Future<void> incrementCallCount() async {
    _resetIfNewMonth();
    final count = _box.get(_countKey, defaultValue: 0) as int;
    await _box.put(_countKey, count + 1);
  }

  static void _resetIfNewMonth() {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final stored = _box.get(_monthKey, defaultValue: '') as String;
    if (stored != month) {
      _box.put(_monthKey, month);
      _box.put(_countKey, 0);
    }
  }
}
