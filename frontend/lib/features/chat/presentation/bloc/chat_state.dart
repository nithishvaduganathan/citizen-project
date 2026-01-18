part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatSessionsLoaded extends ChatState {
  final List<Map<String, dynamic>> sessions;

  const ChatSessionsLoaded({required this.sessions});

  @override
  List<Object?> get props => [sessions];
}

class ChatSessionCreated extends ChatState {
  final Map<String, dynamic> session;

  const ChatSessionCreated({required this.session});

  @override
  List<Object?> get props => [session];
}

class ChatSessionActive extends ChatState {
  final String sessionId;
  final List<Map<String, dynamic>> messages;
  final bool isTyping;
  final List<Map<String, dynamic>>? sources;
  final String? error;

  const ChatSessionActive({
    required this.sessionId,
    required this.messages,
    this.isTyping = false,
    this.sources,
    this.error,
  });

  @override
  List<Object?> get props => [sessionId, messages, isTyping, sources, error];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
