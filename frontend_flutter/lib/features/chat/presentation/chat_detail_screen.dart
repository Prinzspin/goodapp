import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/chat/data/chat_repository.dart';
import 'package:frontend_flutter/features/chat/data/chat_models.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const ChatDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<MessageModel> _localMessages = [];
  bool _isInit = false;
  String? _activeConversationId;

  void _setupRealtime(String conversationId) {
    if (_activeConversationId == conversationId) return;
    
    // Nettoyer l'ancien abonnement
    ref.read(chatRepositoryProvider).unsubscribeMessages();
    _activeConversationId = conversationId;

    ref.read(chatRepositoryProvider).subscribeToMessages(conversationId, (newMessage) {
      if (!mounted) return;
      final alreadyExists = _localMessages.any((m) => m.id == newMessage.id);
      if (!alreadyExists) {
        setState(() {
          _localMessages.add(newMessage);
          _scrollToBottom();
        });
      }
    });
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
  void dispose() {
    if (_activeConversationId != null) {
      ref.read(chatRepositoryProvider).unsubscribeMessages();
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String conversationId) async {
    if (_controller.text.trim().isEmpty) return;
    final content = _controller.text.trim();
    _controller.clear();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(conversationId, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final convAsync = ref.watch(conversationByEventProvider(widget.eventId));
    final currentUser = ref.watch(authStateProvider);

    return convAsync.when(
      data: (conv) {
        // Une fois la conversation chargée, on peut charger les messages
        final messagesAsync = ref.watch(messagesProvider(conv.id));
        _setupRealtime(conv.id);

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => context.push('/event/${conv.eventId}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conv.event?.title ?? 'Discussion', style: const TextStyle(fontSize: 16)),
                  const Text('Voir l\'événement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (initialMessages) {
                    if (!_isInit) {
                      _localMessages.clear();
                      _localMessages.addAll(initialMessages);
                      _isInit = true;
                      _scrollToBottom();
                    }
                    if (_localMessages.isEmpty) {
                      return const Center(child: Text('Aucun message pour le moment'));
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _localMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _localMessages[index];
                        final isMe = msg.authorId == currentUser?.id;
                        return _buildMessageBubble(msg, isMe);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Center(child: Text('Accès refusé ou erreur: $e')),
                ),
              ),
              _buildInput(conv.id),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, __) {
        if (e.toString().contains("CONVERSATION_NOT_FOUND")) {
          return Scaffold(
            appBar: AppBar(title: const Text('Discussion')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.speaker_notes_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Discussion indisponible pour cet événement.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Erreur')),
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Vous n\'avez pas accès à cette discussion.\nAssurez-vous d\'avoir rejoint l\'événement et d\'être accepté.\n\nDétail technique : $e', textAlign: TextAlign.center),
          )),
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  msg.authorName ?? 'Participant',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.deepPurple),
                ),
              ),
            Text(
              msg.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(msg.created),
              style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String conversationId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(conversationId),
                decoration: const InputDecoration(
                  hintText: 'Écrire un message...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.deepPurple),
              onPressed: () => _send(conversationId),
            ),
          ],
        ),
      ),
    );
  }
}
