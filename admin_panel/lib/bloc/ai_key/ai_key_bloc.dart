import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eduforge_core/eduforge_core.dart';

part 'ai_key_event.dart';
part 'ai_key_state.dart';

class AiKeyBloc extends Bloc<AiKeyEvent, AiKeyState> {
  AiKeyBloc() : super(const AiKeyInitial()) {
    on<FetchAiKey>(_onFetch);
    on<RefreshAiKey>(_onRefresh);
  }

  final _supabase = Supabase.instance.client;

  // In-memory cache only — never persisted to disk.
  String? _cached;

  Future<void> _onFetch(FetchAiKey event, Emitter<AiKeyState> emit) async {
    if (_cached != null) {
      emit(AiKeyLoaded(_cached!));
      return;
    }
    await _doFetch(emit);
  }

  Future<void> _onRefresh(
      RefreshAiKey event, Emitter<AiKeyState> emit) async {
    _cached = null; // evict cache
    emit(const AiKeyLoading());
    await _doFetch(emit);
  }

  Future<void> _doFetch(Emitter<AiKeyState> emit) async {
    emit(const AiKeyLoading());
    try {
      final key = await _supabase.rpc<String>('get_gemini_api_key');
      _cached = key;
      emit(AiKeyLoaded(key));
    } on PostgrestException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'AiKeyBloc');
      // Permission denied codes from PostgREST / Postgres
      if (e.code == '42501' || e.code == 'PGRST301' || e.message.contains('permission')) {
        emit(const AiKeyExpired());
      } else {
        emit(AiKeyError(e.message));
      }
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'AiKeyBloc');
      emit(AiKeyError(e.toString()));
    }
  }
}
