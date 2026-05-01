part of 'ai_key_bloc.dart';

abstract class AiKeyEvent extends Equatable {
  const AiKeyEvent();

  @override
  List<Object?> get props => [];
}

class FetchAiKey extends AiKeyEvent {
  const FetchAiKey();
}
