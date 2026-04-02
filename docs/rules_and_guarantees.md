# Règles d'accès — Ce que PocketBase garantit vs Flutter

## Principe général

PocketBase garantit les **permissions CRUD** par collection, mais **ne peut pas** :
- Masquer des champs individuels selon le statut d'un utilisateur
- Faire des sous-requêtes complexes multi-collection dans une règle (ex: vérifier membership dans messages)

Flutter est responsable de **la logique d'affichage** et des **vérifications métier** avant d'appeler l'API.

---

## Tableau de responsabilités

| Règle métier | PocketBase | Flutter |
|---|---|---|
| Seul un utilisateur connecté peut voir les profils | ✅ | |
| Seul le propriétaire peut modifier son profil | ✅ | |
| Tout le monde peut voir la liste des événements | ✅ | |
| Seul un connecté peut créer un événement | ✅ | |
| Seul le créateur peut modifier/supprimer un événement | ✅ | |
| Les détails d'un event privé sont masqués aux non-membres | | ✅ |
| Les photos d'un event privé ne sont pas affichées aux non-membres | | ✅ |
| Le chat d'un event privé est inaccessible aux non-membres | | ✅ (ne pas afficher l'écran) |
| Un user ne peut créer un event_member qu'avec son propre user id | ✅ | |
| Seul le créateur peut accepter/refuser/modifier un event_member | ✅ | |
| Un user peut quitter ou annuler sa demande | ✅ | |
| Le créateur peut retirer un membre | ✅ | |
| Événement public → rejoindre directement (status: accepted) | | ✅ (choisir le bon status) |
| Événement privé → demander (status: pending) | | ✅ (choisir le bon status) |
| Un user ne peut pas se retirer s'il est owner | | ✅ (vérifier rôle avant DELETE) |
| Un user ne peut liker qu'une seule fois | ✅ (index unique) | |
| Seul le propriétaire du like peut le supprimer | ✅ | |
| Seul un membre accepted peut voir le chat | ✅ (@collection rule) | ✅ (Vérif UI) |
| Seul un membre accepted peut envoyer un message | ✅ (Hook JS serveur) | ✅ (Vérif UI) |
| Les messages ne sont pas modifiables | ✅ (règle Update vide) | |
| Seul l'auteur peut supprimer un message | ✅ | |
| La conversation est créée automatiquement avec l'event | ✅ (hook JS) | |
| Le créateur devient membre accepted/owner automatiquement | ✅ (hook JS) | |
| likes_count est mis à jour automatiquement | ✅ (hook JS) | |
| members_count est mis à jour automatiquement | ✅ (hook JS) | |

---

## Stratégie événements privés V1 — Détail

### Ce que PocketBase fait
- La règle `List` et `View` de `events` est ouverte (`""`)
- Tous les champs de l'event sont techniquement accessibles via l'API
- Un utilisateur avancé peut appeler l'API REST directement et obtenir `photos`, `description`, etc.

### Ce que Flutter fait
Sur `event_detail_screen`, **avant d'afficher le contenu complet**, Flutter vérifie :
```
1. Charger l'event → récupérer is_public et creator
2. Si is_public = true → afficher tout
3. Si is_public = false :
   a. Vérifier event_members où event=X AND user=currentUser AND status=accepted
   b. Si trouvé → afficher tout (détail + photos + bouton chat)
   c. Sinon → afficher seulement titre, date, lieu + message "Événement privé"
              + bouton "Demander à rejoindre"
```

### Niveau de sécurité
- **Suffisant pour V1** : les utilisateurs normaux ne voient jamais le contenu protégé
- **Non suffisant pour production sensible** : les données sont accessibles via API directe
- **V2** : renforcer via PocketBase hooks JS qui filtrent les champs à la volée selon le membership

---

## Cas particuliers à gérer dans Flutter

### Créer un event_member
```dart
// Événement public → status direct "accepted"
// Événement privé → status "pending"
final status = event.isPublic ? 'accepted' : 'pending';
await pb.collection('event_members').create(body: {
  'event': eventId,
  'user': currentUserId,
  'status': status,
  'role': 'member',
});
```

### Empêcher l'owner de se retirer
```dart
// Vérifier le rôle avant DELETE
if (membership.role == 'owner') {
  // Afficher erreur : "Le créateur ne peut pas quitter son événement"
  return;
}
await pb.collection('event_members').delete(membershipId);
```

### Envoyer un message
```dart
// 1. Flutter vérifie le membership avant d'autoriser l'affichage de l'input
final membership = await pb.collection('event_members').getFirstListItem(
  'event = "$eventId" && user = "$currentUserId" && status = "accepted"'
);

// 2. Le backend garantit la sécurité via le Hook onRecordBeforeCreateRequest
// Même si l'input est forcé, le serveur rejettera le message si le membership n'est pas "accepted".
await pb.collection('messages').create(body: {
  'conversation': conversationId,
  'author': currentUserId,
  'content': 'Hello!',
});
```
