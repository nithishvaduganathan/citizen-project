import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Chat BLoC for AI chatbot
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;

  ChatBloc({required ChatRepository repository})
      : _repository = repository,
        super(ChatInitial()) {
    on<ChatLoadSessions>(_onLoadSessions);
    on<ChatCreateSession>(_onCreateSession);
    on<ChatSelectSession>(_onSelectSession);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatDeleteSession>(_onDeleteSession);
  }

  Future<void> _onLoadSessions(
    ChatLoadSessions event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final response = await _repository.getSessions();
      final sessions = (response['sessions'] as List<dynamic>?) ?? [];
      emit(ChatSessionsLoaded(sessions: sessions.cast<Map<String, dynamic>>()));
    } catch (e) {
      emit(ChatError('Failed to load sessions'));
    }
  }

  Future<void> _onCreateSession(
    ChatCreateSession event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final session = await _repository.createSession(
        title: event.title,
        preferredLanguage: event.preferredLanguage,
      );
      emit(ChatSessionCreated(session: session));
    } catch (e) {
      emit(ChatError('Failed to create session'));
    }
  }

  Future<void> _onSelectSession(
    ChatSelectSession event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final messages = await _repository.getMessages(event.sessionId);
      emit(ChatSessionActive(
        sessionId: event.sessionId,
        messages: messages.cast<Map<String, dynamic>>(),
      ));
    } catch (e) {
      emit(ChatError('Failed to load messages'));
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatSessionActive) return;
    
    final currentState = state as ChatSessionActive;
    
    // Add user message to UI immediately
    final userMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'role': 'user',
      'content': event.content,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    emit(ChatSessionActive(
      sessionId: currentState.sessionId,
      messages: [...currentState.messages, userMessage],
      isTyping: true,
    ));
    
    try {
      final response = await _repository.sendMessage(
        sessionId: event.sessionId,
        content: event.content,
        language: event.language,
      );
      
      final assistantMessage = response['message'] as Map<String, dynamic>;
      
      emit(ChatSessionActive(
        sessionId: currentState.sessionId,
        messages: [...currentState.messages, userMessage, assistantMessage],
        isTyping: false,
        sources: (response['sources'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      ));
    } catch (e) {
      emit(ChatSessionActive(
        sessionId: currentState.sessionId,
        messages: currentState.messages,
        isTyping: false,
        error: 'Failed to send message',
      ));
    }
  }

  Future<void> _onDeleteSession(
    ChatDeleteSession event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _repository.deleteSession(event.sessionId);
      add(ChatLoadSessions());
    } catch (e) {
      emit(ChatError('Failed to delete session'));
    }
  }
}
