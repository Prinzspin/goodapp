import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider pour l'instance singleton de PocketBase
final pocketBaseProvider = Provider<PocketBase>((ref) {
  // Configuration de l'URL selon la plateforme (local dev)
  // Android: 10.0.2.2 pour accéder au localhost de la machine hôte
  // iOS/Web/Desktop: 127.0.0.1
  String baseUrl = 'http://127.0.0.1:8090';
  
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    baseUrl = 'http://10.0.2.2:8090';
  }

  return PocketBase(baseUrl);
});
