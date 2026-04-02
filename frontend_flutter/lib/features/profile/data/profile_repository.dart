import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';
import 'package:frontend_flutter/features/events/data/event_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return ProfileRepository(ref, pb);
});

// Provider pour les stats du profil
final profileStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(profileRepositoryProvider).getProfileStats();
});

// Provider pour les événements de l'utilisateur
final myEventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  return ref.watch(profileRepositoryProvider).getMyEvents();
});

class ProfileRepository {
  final Ref _ref;
  final PocketBase _pb;

  ProfileRepository(this._ref, this._pb);

  Future<Map<String, int>> getProfileStats() async {
    final user = _ref.read(authStateProvider);
    if (user == null) return {"joined": 0, "hosted": 0};

    final joined = await _pb.collection('event_members').getList(page: 1, perPage: 1, filter: 'user = "${user.id}" && status = "accepted"');
    final hosted = await _pb.collection('events').getList(page: 1, perPage: 1, filter: 'creator = "${user.id}"');

    return {
      "joined": joined.totalItems,
      "hosted": hosted.totalItems,
    };
  }

  Future<List<EventModel>> getMyEvents() async {
    final user = _ref.read(authStateProvider);
    if (user == null) return [];

    final records = await _pb.collection('events').getList(
      page: 1, 
      perPage: 5, 
      filter: 'creator = "${user.id}"',
      sort: '-created'
    );
    return records.items.map((r) => EventModel.fromRecord(r)).toList();
  }

  Future<void> updateProfile({String? name, String? bio}) async {
    final user = _ref.read(authStateProvider);
    if (user == null) throw Exception('Utilisateur non connecté');

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;

    await _pb.collection('users').update(user.id, body: body);
    _ref.read(authStateProvider.notifier).refresh();
  }

  void logout() {
    _ref.read(authStateProvider.notifier).logout();
  }
}
