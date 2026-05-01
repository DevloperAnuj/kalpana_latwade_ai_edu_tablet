import 'dart:math';

import 'package:eduforge_core/eduforge_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/class_model.dart';

class ClassRepository {
  ClassRepository(this._supabase);
  final SupabaseClient _supabase;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _rng = Random.secure();

  String _generateCode() =>
      List.generate(6, (_) => _chars[_rng.nextInt(_chars.length)]).join();

  /// Validates that [code] is 6 uppercase alphanumeric characters.
  static bool isValidJoinCode(String code) =>
      RegExp(r'^[A-Z0-9]{6}$').hasMatch(code);

  Future<List<ClassModel>> fetchClasses(String teacherId) async {
    try {
      final data = await RetryPolicy.run(() => _supabase
          .from('classes')
          .select('*, class_students(count)')
          .eq('teacher_id', teacherId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false));

      return (data as List)
          .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  Future<ClassModel> createClass(String teacherId, String name) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Class name cannot be empty.');
    }

    try {
      // Fetch existing active codes to avoid collision
      final existing = await _supabase
          .from('classes')
          .select('join_code')
          .isFilter('deleted_at', null);
      final existingCodes = (existing as List)
          .map((e) => (e as Map<String, dynamic>)['join_code'] as String)
          .toSet();

      String code;
      var attempts = 0;
      do {
        code = _generateCode();
        if (++attempts > 10) {
          throw const DatabaseException('Could not generate a unique join code.');
        }
      } while (existingCodes.contains(code));

      final row = await RetryPolicy.run(() => _supabase
          .from('classes')
          .insert({'teacher_id': teacherId, 'name': name.trim(), 'join_code': code})
          .select('*, class_students(count)')
          .single());

      return ClassModel.fromJson(row);
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Soft-deletes a class by setting deleted_at to now.
  Future<void> deleteClass(String classId) async {
    try {
      await RetryPolicy.run(() => _supabase
          .from('classes')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', classId));
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Restores a soft-deleted class.
  Future<void> restoreClass(String classId) async {
    try {
      await _supabase
          .from('classes')
          .update({'deleted_at': null}).eq('id', classId);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Permanently deletes a class record.
  Future<void> permanentlyDeleteClass(String classId) async {
    try {
      await _supabase.from('classes').delete().eq('id', classId);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Returns soft-deleted classes for the trash screen.
  Future<List<ClassModel>> fetchTrashedClasses(String teacherId) async {
    try {
      final data = await _supabase
          .from('classes')
          .select('*, class_students(count)')
          .eq('teacher_id', teacherId)
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);

      return (data as List)
          .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }
}
