import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/chat_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/injection.dart';

/// Chat page for AI chatbot
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedLanguage = 'en';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>()..add(ChatLoadSessions()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Legal Assistant'),
          actions: [
            PopupMenuButton<String>(
              initialValue: _selectedLanguage,
              onSelected: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                const PopupMenuItem(
                  value: 'ta',
                  child: Text('தமிழ் (Tamil)'),
                ),
                const PopupMenuItem(
                  value: 'hi',
                  child: Text('हिन्दी (Hindi)'),
                ),
              ],
              icon: const Icon(Icons.language),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.read<ChatBloc>().add(
                      ChatCreateSession(preferredLanguage: _selectedLanguage),
                    );
              },
            ),
          ],
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatSessionCreated) {
              context.read<ChatBloc>().add(
                    ChatSelectSession(state.session['id'] as String),
                  );
            }
            if (state is ChatSessionActive) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            if (state is ChatLoading) {
              return const LoadingIndicator(message: 'Loading...');
            }

            if (state is ChatSessionsLoaded) {
              if (state.sessions.isEmpty) {
                return _EmptySessionsView(
                  onCreateSession: () {
                    context.read<ChatBloc>().add(
                          ChatCreateSession(preferredLanguage: _selectedLanguage),
                        );
                  },
                );
              }
              return _SessionsListView(
                sessions: state.sessions,
                onSelect: (sessionId) {
                  context.read<ChatBloc>().add(ChatSelectSession(sessionId));
                },
                onDelete: (sessionId) {
                  context.read<ChatBloc>().add(ChatDeleteSession(sessionId));
                },
              );
            }

            if (state is ChatSessionActive) {
              return Column(
                children: [
                  Expanded(
                    child: _MessagesListView(
                      messages: state.messages,
                      scrollController: _scrollController,
                      isTyping: state.isTyping,
                    ),
                  ),
                  _MessageInputBar(
                    controller: _messageController,
                    onSend: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        context.read<ChatBloc>().add(
                              ChatSendMessage(
                                sessionId: state.sessionId,
                                content: _messageController.text.trim(),
                                language: _selectedLanguage,
                              ),
                            );
                        _messageController.clear();
                      }
                    },
                    isEnabled: !state.isTyping,
                  ),
                ],
              );
            }

            if (state is ChatError) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<ChatBloc>().add(ChatLoadSessions());
                },
              );
            }

            return const EmptyStateView(
              icon: Icons.chat_bubble_outline,
              title: 'Start a conversation',
              subtitle: 'Ask questions about Indian Constitution and laws',
            );
          },
        ),
      ),
    );
  }
}

class _EmptySessionsView extends StatelessWidget {
  final VoidCallback onCreateSession;

  const _EmptySessionsView({required this.onCreateSession});

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.chat_bubble_outline,
      title: 'No conversations yet',
      subtitle: 'Start a new chat to ask questions about Indian Constitution, laws, and civic matters.',
      action: ElevatedButton.icon(
        onPressed: onCreateSession,
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
    );
  }
}

class _SessionsListView extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final Function(String) onSelect;
  final Function(String) onDelete;

  const _SessionsListView({
    required this.sessions,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.chat),
            ),
            title: Text(session['title'] as String? ?? 'Chat'),
            subtitle: Text(
              'Messages: ${session['message_count'] ?? 0}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onDelete(session['id'] as String),
            ),
            onTap: () => onSelect(session['id'] as String),
          ),
        );
      },
    );
  }
}

class _MessagesListView extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final bool isTyping;

  const _MessagesListView({
    required this.messages,
    required this.scrollController,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const _TypingIndicator();
        }

        final message = messages[index];
        final isUser = message['role'] == 'user';

        return _MessageBubble(
          content: message['content'] as String,
          isUser: isUser,
          sources: !isUser
              ? (message['sources'] as List<dynamic>?)?.cast<Map<String, dynamic>>()
              : null,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final List<Map<String, dynamic>>? sources;

  const _MessageBubble({
    required this.content,
    required this.isUser,
    this.sources,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isUser ? Colors.white : null,
                ),
              ),
            ),
            if (sources != null && sources!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Sources:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ...sources!.map((source) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• ${source['article'] ?? source['title']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEnabled;

  const _MessageInputBar({
    required this.controller,
    required this.onSend,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: isEnabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask about Indian laws...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isEnabled ? onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
