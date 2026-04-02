import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return AuthRepository(pb);
});

class AuthRepository {
  final PocketBase _pb;

  AuthRepository(this._pb);

  /// Getter pour l'utilisateur actuel
  RecordModel? get currentUser => _pb.authStore.model as RecordModel?;

  /// État d'authentification
  bool get isAuthenticated => _pb.authStore.isValid;

  /// Inscription (Register)
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final body = <String, dynamic>{
        "username": username,
        "email": email,
        "emailVisibility": true,
        "password": password,
        "passwordConfirm": passwordConfirm,
        "name": username, // Utilise le username comme nom par défaut
      };

      await _pb.collection('users').create(body: body);
    } catch (e) {
      rethrow;
    }
  }

  /// Connexion (Login)
  Future<void> login(String email, String password) async {
    try {
      await _pb.collection('users').authWithPassword(email, password);
    } catch (e) {
      rethrow;
    }
  }

  /// Déconnexion (Logout)
  void logout() {
    _pb.authStore.clear();
  }

  /// Stream qui écoute les changements dans l'AuthStore
  Stream<AuthStoreEvent> authStateChanges() {
    return _pb.authStore.onChange;
  }
}
