import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../core/network/retry_policy.dart';

class ProfileRepository {
  ProfileRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<({String displayName, String role, String? rollNumber, String email})>
      fetchProfile(String userId) async {
    try {
      final row = await RetryPolicy.run(
        () => _supabase
            .from('profiles')
            .select('display_name, role, roll_number')
            .eq('id', userId)
            .single(),
      );
      return (
        displayName: (row['display_name'] as String?) ?? '',
        role: row['role'] as String,
        rollNumber: row['roll_number'] as String?,
        email: _supabase.auth.currentUser?.email ?? '',
      );
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  Future<void> updateProfile(
    String userId, {
    required String displayName,
    String? rollNumber,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw const ValidationException('Display name cannot be empty.');
    }
    try {
      final trimmedRoll = rollNumber?.trim();
      await RetryPolicy.run(
        () => _supabase.from('profiles').update({
          'display_name': name,
          'roll_number': (trimmedRoll?.isEmpty ?? true) ? null : trimmedRoll,
        }).eq('id', userId),
      );
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }
}
