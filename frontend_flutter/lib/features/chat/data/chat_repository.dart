import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';
import 'chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  final currentUser = ref.watch(authStateProvider);
  return ChatRepository(pb, currentUser);
});

final conversationDetailProvider = FutureProvider.autoDispose.family<ConversationModel, String>((ref, id) async {
  return ref.watch(chatRepositoryProvider).fetchConversationDetail(id);
});

final conversationByEventProvider = FutureProvider.autoDispose.family<ConversationModel, String>((ref, eventId) async {
  return ref.watch(chatRepositoryProvider).fetchConversationByEvent(eventId);
});

final messagesProvider = FutureProvider.autoDispose.family<List<MessageModel>, String>((ref, conversationId) async {
  return ref.watch(chatRepositoryProvider).fetchMessages(conversationId);
});

final conversationsListProvider = FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  return ref.watch(chatRepositoryProvider).fetchMyConversations();
});

class ChatRepository {
  final PocketBase _pb;
  final RecordModel? _user;

  ChatRepository(this._pb, this._user);

  /// Récupère UNIQUEMENT les conversations des événements où l'utilisateur est accepted.
  Future<List<ConversationModel>> fetchMyConversations() async {
    if (_user == null) return [];

    final memberships = await _pb.collection('event_members').getFullList(
      filter: 'user = "${_user!.id}" && status = "accepted"',
    );

    if (memberships.isEmpty) return [];

    // 2. Construire le filtre global pour récupérer les Conversations
    final eventIds = memberships.map((m) => m.getStringValue('event')).toSet().toList();
    final filterParts = eventIds.map((id) => 'event = "$id"').toList();
    final filter = filterParts.join(' || ');

    // 3. Récupérer les conversations correspondantes
    final records = await _pb.collection('conversations').getFullList(
      filter: filter,
      expand: 'event,event.creator',
      sort: '-created',
    );
    return records.map((r) => ConversationModel.fromRecord(r)).toList();
  }

  Future<ConversationModel> fetchConversationByEvent(String eventId) async {
    if (_user == null) throw Exception("Non authentifié");

    // Vérifier s'il est membre accepté ou owner
    final membership = await _pb.collection('event_members').getList(
      page: 1, perPage: 1,
      filter: 'event = "$eventId" && user = "${_user!.id}" && status = "accepted"',
    );

    if (membership.items.isEmpty) {
      throw Exception("Vous devez être membre accepté pour accéder à cette discussion.");
    }

    try {
      final record = await _pb.collection('conversations').getFirstListItem(
        'event = "$eventId"',
        expand: 'event,event.creator',
      );
      return ConversationModel.fromRecord(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw Exception("CONVERSATION_NOT_FOUND");
      }
      rethrow;
    }
  }

  Future<ConversationModel> fetchConversationDetail(String id) async {
    final record = await _pb.collection('conversations').getOne(id, expand: 'event,event.creator');
    return ConversationModel.fromRecord(record);
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    final records = await _pb.collection('messages').getFullList(
      filter: 'conversation = "$conversationId"',
      expand: 'author',
      sort: 'created',
    );
    return records.map((r) => MessageModel.fromRecord(r)).toList();
  }

  void subscribeToMessages(String conversationId, Function(MessageModel) onNewMessage) {
    _pb.collection('messages').subscribe('*', (e) {
      if (e.action == 'create') {
        final message = MessageModel.fromRecord(e.record!);
        if (message.conversationId == conversationId) {
          onNewMessage(message);
        }
      }
    }, expand: 'author');
  }

  void unsubscribeMessages() {
    _pb.collection('messages').unsubscribe('*');
  }

  Future<void> sendMessage(String conversationId, String content) async {
    if (_user == null) throw Exception("Non authentifié");
    await _pb.collection('messages').create(body: {
      "conversation": conversationId,
      "author": _user?.id,
      "content": content.trim(),
    });
  }
}
