part of 'ai_key_bloc.dart';

abstract class AiKeyEvent extends Equatable {
  const AiKeyEvent();

  @override
  List<Object?> get props => [];
}

class FetchAiKey extends AiKeyEvent {
  const FetchAiKey();
}

/// Forces a fresh RPC call, evicting any cached key.
class RefreshAiKey extends AiKeyEvent {
  const RefreshAiKey();
}
