# API Endpoints PocketBase — Référence Flutter

> Base URL : `http://127.0.0.1:8090` (local) — à remplacer par l'URL de prod

---

## Authentification

| Action | Méthode | Endpoint |
|---|---|---|
| Inscription | POST | `/api/collections/users/records` |
| Connexion | POST | `/api/collections/users/auth-with-password` |
| Refresh token | POST | `/api/collections/users/auth-refresh` |
| Déconnexion | *(client-side)* | `pb.authStore.clear()` |

---

## Utilisateurs

| Action | Méthode | Endpoint |
|---|---|---|
| Voir un profil | GET | `/api/collections/users/records/:id` |
| Modifier mon profil | PATCH | `/api/collections/users/records/:id` |

---

## Événements

| Action | Méthode | Endpoint |
|---|---|---|
| Lister tous les événements | GET | `/api/collections/events/records` |
| Lister avec filtre/tri | GET | `/api/collections/events/records?filter=...&sort=...` |
| Détail d'un événement | GET | `/api/collections/events/records/:id` |
| Créer un événement | POST | `/api/collections/events/records` |
| Modifier un événement | PATCH | `/api/collections/events/records/:id` |
| Supprimer un événement | DELETE | `/api/collections/events/records/:id` |

### Filtres utiles
```
# Événements publics uniquement
filter=is_public=true

# Événements à venir
filter=start_date>="2025-01-01 00:00:00"

# Par créateur
filter=creator="USER_ID"

# Tri par date
sort=start_date

# Avec expand du créateur
expand=creator
```

---

## Membres d'événement

| Action | Méthode | Endpoint |
|---|---|---|
| Lister les membres d'un event | GET | `/api/collections/event_members/records?filter=event="ID"` |
| Vérifier mon membership | GET | `/api/collections/event_members/records?filter=event="ID"&&user="MY_ID"` |
| Rejoindre / demander | POST | `/api/collections/event_members/records` |
| Accepter / refuser (créateur) | PATCH | `/api/collections/event_members/records/:id` |
| Quitter / annuler / retirer | DELETE | `/api/collections/event_members/records/:id` |

---

## Likes

| Action | Méthode | Endpoint |
|---|---|---|
| Liker un événement | POST | `/api/collections/event_likes/records` |
| Vérifier si j'ai liké | GET | `/api/collections/event_likes/records?filter=event="ID"&&user="MY_ID"` |
| Unliker | DELETE | `/api/collections/event_likes/records/:id` |
| Mes likes | GET | `/api/collections/event_likes/records?filter=user="MY_ID"&expand=event` |

---

## Chat

| Action | Méthode | Endpoint |
|---|---|---|
| Trouver la conversation d'un event | GET | `/api/collections/conversations/records?filter=event="ID"` |
| Lister les messages | GET | `/api/collections/messages/records?filter=conversation="ID"&sort=created` |
| Envoyer un message | POST | `/api/collections/messages/records` |
| Supprimer un message | DELETE | `/api/collections/messages/records/:id` |

### Realtime (SSE)
```dart
// S'abonner aux nouveaux messages d'une conversation
pb.collection('messages').subscribe('*', (e) {
  if (e.record?.get('conversation') == conversationId) {
    // Ajouter le message à la liste
  }
});

// Se désabonner (dans dispose())
pb.collection('messages').unsubscribe('*');
```

---

## Upload de photos (événement)

```dart
// Lors de la création ou modification d'un événement
final formData = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/collections/events/records'));
formData.files.add(await http.MultipartFile.fromPath('photos', filePath));
```

> Via le SDK Dart PocketBase :
```dart
await pb.collection('events').update(eventId, files: [
  http.MultipartFile.fromBytes('photos', bytes, filename: 'photo.jpg'),
]);
```
