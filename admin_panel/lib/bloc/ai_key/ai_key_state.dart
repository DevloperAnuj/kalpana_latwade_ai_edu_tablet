part of 'ai_key_bloc.dart';

abstract class AiKeyState extends Equatable {
  const AiKeyState();

  @override
  List<Object?> get props => [];
}

class AiKeyInitial extends AiKeyState {
  const AiKeyInitial();
}

class AiKeyLoading extends AiKeyState {
  const AiKeyLoading();
}

class AiKeyLoaded extends AiKeyState {
  final String key;

  const AiKeyLoaded(this.key);

  @override
  List<Object?> get props => [key];
}

class AiKeyError extends AiKeyState {
  final String message;

  const AiKeyError(this.message);

  @override
  List<Object?> get props => [message];
}
