import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';
import 'package:frontend_flutter/features/events/data/event_model.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  final currentUser = ref.watch(authStateProvider);
  return EventsRepository(pb, currentUser);
});

final eventsListProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  return ref.watch(eventsRepositoryProvider).fetchEvents();
});

final eventMembershipProvider = FutureProvider.autoDispose.family<EventMemberModel?, String>((ref, eventId) async {
  return ref.watch(eventsRepositoryProvider).getMembership(eventId);
});

final eventDetailProvider = FutureProvider.autoDispose.family<EventModel, String>((ref, eventId) async {
  return ref.watch(eventsRepositoryProvider).fetchEventDetail(eventId);
});

final likedEventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  return ref.watch(eventsRepositoryProvider).fetchLikedEvents();
});

// Provider pour les demandes pending d'un événement (visible par le créateur)
final pendingMembersProvider = FutureProvider.autoDispose.family<List<EventMemberModel>, String>((ref, eventId) async {
  return ref.watch(eventsRepositoryProvider).fetchPendingMembers(eventId);
});

class EventsRepository {
  final PocketBase _pb;
  final RecordModel? _user;

  EventsRepository(this._pb, this._user);

  Future<List<EventModel>> fetchEvents() async {
    final records = await _pb.collection('events').getFullList(
      sort: '-start_date',
      expand: 'creator',
    );
    return records.map((r) => EventModel.fromRecord(r)).toList();
  }

  Future<EventModel> fetchEventDetail(String eventId) async {
    final record = await _pb.collection('events').getOne(
      eventId,
      expand: 'creator',
    );
    return EventModel.fromRecord(record);
  }

  Future<List<EventModel>> fetchLikedEvents() async {
    if (_user == null) return [];
    final records = await _pb.collection('event_likes').getFullList(
      filter: 'user = "${_user?.id}"',
      expand: 'event,event.creator',
    );
    return records
        .map((r) => r.expand['event']?[0])
        .whereType<RecordModel>()
        .map((r) => EventModel.fromRecord(r))
        .toList();
  }

  Future<bool> isEventLiked(String eventId) async {
    if (_user == null) return false;
    try {
      final records = await _pb.collection('event_likes').getList(
        page: 1, perPage: 1,
        filter: 'event = "$eventId" && user = "${_user?.id}"',
      );
      return records.items.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleLike(String eventId) async {
    if (_user == null) return;
    final records = await _pb.collection('event_likes').getList(
      page: 1, perPage: 1,
      filter: 'event = "$eventId" && user = "${_user?.id}"',
    );
    if (records.items.isNotEmpty) {
      await _pb.collection('event_likes').delete(records.items.first.id);
    } else {
      await _pb.collection('event_likes').create(body: {
        "event": eventId,
        "user": _user?.id,
      });
    }
  }

  Future<EventMemberModel?> getMembership(String eventId) async {
    if (_user == null) return null;
    try {
      final records = await _pb.collection('event_members').getList(
        page: 1, perPage: 1,
        filter: 'event = "$eventId" && user = "${_user?.id}"',
      );
      if (records.items.isNotEmpty) {
        return EventMemberModel.fromRecord(records.items.first);
      }

      // FALLBACK FLUTTER (Résolution de la Race Condition Backend Hook) :
      // Si le membership automatique n'a pas encore eu le temps d'être écrit, 
      // mais qu'on est le créateur, on est d'office le owner et accepted !
      final eventRecord = await _pb.collection('events').getOne(eventId);
      if (eventRecord.getStringValue('creator') == _user?.id) {
        return EventMemberModel(
            id: 'auto_creator_${_pb.authStore.model?.id}',
            eventId: eventId,
            userId: _user!.id,
            status: 'accepted',
            role: 'owner',
        );
      }
    } catch (_) {}
    return null;
  }

  /// Rejoindre un événement.
  /// - Public : status = accepted
  /// - Privé  : status = pending
  /// Vérifie d'abord qu'on n'est pas déjà membre.
  Future<void> joinEvent(String eventId, bool isPublic) async {
    if (_user == null) throw Exception('Utilisateur non connecté');

    // Vérification anti-doublon pure
    final existing = await getMembership(eventId);
    if (existing != null && !existing.id.startsWith('auto_')) {
      throw Exception('Vous avez déjà une demande ou participation pour cet événement.');
    }

    try {
      await _pb.collection('event_members').create(body: {
        'event': eventId,
        'user': _user?.id,
        'status': isPublic ? 'accepted' : 'pending',
        'role': 'member',
      });
    } on ClientException catch (e) {
      // PALLIATIF DU BUG DES HOOKS BACKEND POCKETBASE :
      // PB v0.22+ lance parfois une erreur 400 si un hook `AfterCreateSuccess` échoue silencieusement
      // ALORS QUE la donnée a bien été enregistrée en base. 
      // On re-vérifie immédiatement l'état réel pour éviter le faux négatif visuel.
      final actualState = await getMembership(eventId);
      if (actualState == null || actualState.id.startsWith('auto_')) {
        throw Exception(e.response['message'] ?? e.toString());
      }
      // La donnée est bien en base ! On ignore gracieusement l'erreur réseau et on continue le flux.
    }
  }

  /// Récupérer les demandes pending pour un événement donné
  Future<List<EventMemberModel>> fetchPendingMembers(String eventId) async {
    final records = await _pb.collection('event_members').getFullList(
      filter: 'event = "$eventId" && status = "pending"',
      expand: 'user',
    );
    return records.map((r) => EventMemberModel.fromRecord(r)).toList();
  }

  /// Accepter une demande de participation
  Future<void> acceptMember(String membershipId) async {
    await _pb.collection('event_members').update(membershipId, body: {
      'status': 'accepted',
    });
  }

  /// Refuser une demande de participation
  Future<void> rejectMember(String membershipId) async {
    await _pb.collection('event_members').update(membershipId, body: {
      'status': 'rejected',
    });
  }

  Future<void> createEvent({
    required String title, required String description,
    required DateTime startDate, required bool isPublic, String? locationName,
    double? lat, double? lng,
  }) async {
    if (_user == null) throw Exception("Non authentifié");
    await _pb.collection('events').create(body: {
      "title": title, "description": description, "start_date": startDate.toIso8601String(),
      "is_public": isPublic, "location_name": locationName ?? "", 
      "lat": lat ?? 0.0, "lng": lng ?? 0.0,
      "creator": _user?.id,
      "likes_count": 0, "members_count": 0,
    });
  }
}