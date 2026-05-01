import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ai_key_event.dart';
part 'ai_key_state.dart';

class AiKeyBloc extends Bloc<AiKeyEvent, AiKeyState> {
  AiKeyBloc() : super(const AiKeyInitial()) {
    on<FetchAiKey>(_onFetchAiKey);
  }

  final _supabase = Supabase.instance.client;

  Future<void> _onFetchAiKey(
    FetchAiKey event,
    Emitter<AiKeyState> emit,
  ) async {
    emit(const AiKeyLoading());
    try {
      final key = await _supabase.rpc<String>('get_ai_api_key');
      emit(AiKeyLoaded(key));
    } on PostgrestException catch (e) {
      emit(AiKeyError(e.message));
    } catch (e) {
      emit(AiKeyError(e.toString()));
    }
  }
}
