import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:frontend_flutter/features/auth/data/auth_repository.dart';

/// Un simple état d'authentification qui contient l'utilisateur ou null
final authStateProvider = StateNotifierProvider<AuthNotifier, RecordModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<RecordModel?> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(null) {
    // Initialisation synchrone de l'état actuel de l'authStore
    _updateState();

    // Écoute les changements futurs (connexion/déconnexion)
    _repository.authStateChanges().listen((event) {
      _updateState();
    });
  }

  void _updateState() {
    state = _repository.isAuthenticated ? _repository.currentUser : null;
  }

  Future<void> login(String email, String password) async {
    await _repository.login(email, password);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    await _repository.register(
      username: username,
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }

  void logout() {
    _repository.logout();
  }

  void refresh() {
    _updateState();
  }

  bool get isAuthenticated => state != null;
}
