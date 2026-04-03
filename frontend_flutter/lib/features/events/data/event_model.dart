import 'package:pocketbase/pocketbase.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? locationName;
  final double? lat;
  final double? lng;
  final bool isPublic;
  final List<String> photos;
  final String creatorId;
  final int likesCount;
  final int membersCount;
  final RecordModel? expandCreator;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    this.locationName,
    this.lat,
    this.lng,
    required this.isPublic,
    required this.photos,
    required this.creatorId,
    required this.likesCount,
    required this.membersCount,
    this.expandCreator,
  });

  factory EventModel.fromRecord(RecordModel record) {
    return EventModel(
      id: record.id,
      title: record.getStringValue('title'),
      description: record.getStringValue('description'),
      startDate: DateTime.parse(record.getStringValue('start_date')),
      endDate: record.getStringValue('end_date').isNotEmpty 
          ? DateTime.parse(record.getStringValue('end_date')) 
          : null,
      locationName: record.getStringValue('location_name'),
      lat: record.getDoubleValue('lat'),
      lng: record.getDoubleValue('lng'),
      isPublic: record.getBoolValue('is_public'),
      photos: List<String>.from(record.getListValue<String>('photos') ?? []),
      creatorId: record.getStringValue('creator'),
      likesCount: record.getIntValue('likes_count'),
      membersCount: record.getIntValue('members_count'),
      expandCreator: record.expand['creator']?[0],
    );
  }
}

class EventMemberModel {
  final String id;
  final String eventId;
  final String userId;
  final String status; // pending, accepted, rejected
  final String role;   // owner, member
  final String? userName;

  EventMemberModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.role,
    this.userName,
  });

  factory EventMemberModel.fromRecord(RecordModel record) {
    final expandedUser = record.expand['user']?[0];
    return EventMemberModel(
      id: record.id,
      eventId: record.getStringValue('event'),
      userId: record.getStringValue('user'),
      status: record.getStringValue('status'),
      role: record.getStringValue('role'),
      userName: expandedUser?.getStringValue('name'),
    );
  }
}
