import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/chat/data/chat_repository.dart';
import 'package:frontend_flutter/features/chat/data/chat_models.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';
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

    try {
      // Attendre la confirmation backend avant de vider l'input
      final savedMessage = await ref.read(chatRepositoryProvider).sendMessage(conversationId, content);
      if (mounted) {
        _controller.clear();
        // Injecter directement dans l'état local sans attendre le SSE
        final alreadyExists = _localMessages.any((m) => m.id == savedMessage.id);
        if (!alreadyExists) {
          setState(() {
            _localMessages.add(savedMessage);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Envoi échoué : $e"),
            backgroundColor: Colors.red,
          ),
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
          appBar: AppBar(title: const Text('Discussion inaccessible')),
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Cette discussion est réservée aux participants.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assurez-vous d\'avoir rejoint l\'événement et que votre demande a bien été acceptée par l\'organisateur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Retour'),
                )
              ],
            ),
          )),
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    final theme = Theme.of(context);
    final pb = ref.read(pocketBaseProvider);
    
    final avatarWidget = CircleAvatar(
      radius: 16,
      backgroundColor: theme.primaryColor.withOpacity(0.1),
      backgroundImage: (msg.authorAvatar != null && msg.authorAvatar!.isNotEmpty)
          ? CachedNetworkImageProvider('${pb.baseUrl}/api/files/users/${msg.authorId}/${msg.authorAvatar}')
          : null,
      child: (msg.authorAvatar == null || msg.authorAvatar!.isEmpty)
          ? Icon(Icons.person, size: 20, color: theme.primaryColor)
          : null,
    );
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              avatarWidget,
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
          color: isMe ? theme.primaryColor : const Color(0xFFF1F5F9), // Slate 100 for better text contrast
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)), // Slate 200 setup
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg.authorName ?? 'Participant',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.primaryColor),
                ),
              ),
            Text(
              msg.content,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF0F172A), // Slate 900
                fontSize: 15, 
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.created),
              style: TextStyle(fontSize: 11, color: isMe ? const Color(0xCCFFFFFF) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String conversationId) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))), // Slate 200
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Champ de saisie pour message de discussion',
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _send(conversationId),
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.primaryColor, width: 2),
                    ),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Envoyer le message',
              child: Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _send(conversationId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
