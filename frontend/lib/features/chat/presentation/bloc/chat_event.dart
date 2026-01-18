part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadSessions extends ChatEvent {}

class ChatCreateSession extends ChatEvent {
  final String? title;
  final String preferredLanguage;

  const ChatCreateSession({
    this.title,
    this.preferredLanguage = 'en',
  });

  @override
  List<Object?> get props => [title, preferredLanguage];
}

class ChatSelectSession extends ChatEvent {
  final String sessionId;

  const ChatSelectSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ChatSendMessage extends ChatEvent {
  final String sessionId;
  final String content;
  final String language;

  const ChatSendMessage({
    required this.sessionId,
    required this.content,
    this.language = 'en',
  });

  @override
  List<Object?> get props => [sessionId, content, language];
}

class ChatDeleteSession extends ChatEvent {
  final String sessionId;

  const ChatDeleteSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
