import 'package:pocketbase/pocketbase.dart';
import 'package:frontend_flutter/features/events/data/event_model.dart';

class ConversationModel {
  final String id;
  final String eventId;
  final EventModel? event;

  ConversationModel({
    required this.id,
    required this.eventId,
    this.event,
  });

  factory ConversationModel.fromRecord(RecordModel record) {
    return ConversationModel(
      id: record.id,
      eventId: record.getStringValue('event'),
      event: record.expand['event'] != null 
          ? EventModel.fromRecord(record.expand['event']![0]) 
          : null,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String authorId;
  final String content;
  final DateTime created;
  final String? authorName;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.authorId,
    required this.content,
    required this.created,
    this.authorName,
  });

  factory MessageModel.fromRecord(RecordModel record) {
    return MessageModel(
      id: record.id,
      conversationId: record.getStringValue('conversation'),
      authorId: record.getStringValue('author'),
      content: record.getStringValue('content'),
      created: DateTime.parse(record.created),
      authorName: record.expand['author']?[0].getStringValue('name'),
    );
  }
}
