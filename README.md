# 🌟 Good App — Dossier de Reprise Technique & Architecture

## 1. Vision du projet

**Good App** est une application mobile/sociale d’événements permettant à des utilisateurs de :
- découvrir des événements publics et privés dans Paris,
- créer leurs propres événements,
- rejoindre ou demander à rejoindre un événement,
- discuter avec les autres participants dans un chat dédié temps réel,
- liker des événements pour les retrouver facilement,
- visualiser les événements sur une carte interactive.

L’application vise une expérience simple, directe et orientée usage réel, mélangeant les mécaniques d'un **annuaire d’événements**, d'un **réseau social léger**, d'une **messagerie de groupe**, et d'une **carte interactive**.

---

## 2. Objectifs fonctionnels

### Côté utilisateur
- créer un compte et se connecter,
- consulter les événements disponibles,
- voir les détails d’un événement (lieu, date, description, photos),
- liker / unliker un événement,
- rejoindre directement un événement public,
- demander à rejoindre un événement privé,
- accéder aux discussions des événements auxquels il participe **réellement**,
- envoyer et recevoir des messages en temps réel,
- visualiser les événements sur la carte,
- gérer son profil.

### Côté créateur d’événement
- créer un événement (titre, lieu, latitude/longitude, date, visibilité),
- devenir **automatiquement** membre de son propre événement (statut `owner`, `accepted`),
- accéder automatiquement à la discussion générée pour l'événement,
- voir les demandes de participation sur ses événements privés pour les accepter ou les refuser.

---

## 3. Stack technique

### Frontend
- **Framework :** Flutter (cible principale : Web et Mobile Android/iOS).
- **Navigation :** GoRouter.
- **État / Injection :** Riverpod.
- **Carte :** `flutter_map` + OpenStreetMap + `latlong2`.
- **Client Backend :** PocketBase Dart SDK.

### Backend
- **Base de données / API / Auth :** PocketBase (Go/SQLite).
- **Logique métier métier :** Hooks JavaScript (`pb_hooks`) exécutés par le moteur Goja.
- **Temps réel :** Mécanisme natif SSE (Server-Sent Events) de PocketBase.

---

## 4. Choix techniques et justification

### 4.1 Pourquoi Flutter ?
Permet de développer rapidement et itérer vite sur une même base de code pour le Web (démonstration facile) et le Mobile, tout en conservant une UI riche, cohérente et très réactive.

### 4.2 Pourquoi PocketBase ?
Un backend Backend-as-a-Service ultra léger contenant tout le nécessaire en un seul exécutable natif : base de données relationnelle, authentification, stockage de fichiers et abonnements temps réel. Parfait pour ce MVP afin d'accélérer le delivery.

### 4.3 Pourquoi une architecture modulaire par *features* ?
Le code Flutter est rangé par domaine métier (`auth`, `events`, `chat`, `map`, `profile`) et en sous-couches (`data` et `presentation`). Cela garantit un code scalable, testable, et facile à reprendre par un autre développeur, contrairement à un simple dossier "écrans".

### 4.4 Pourquoi un backend "source de vérité" ?
Point fondamental de l'architecture : **le backend est souverain**.
C'est lui (via ses Hooks JS ou scripts d'administration) qui :
- crée la conversation liée,
- gère l'adhésion implicite du créateur,
- s'assure des décomptes et de la cohérence,
- empêche l'accès au Chat à toute personne dont le statut "event_members" n'est pas strictement `accepted`.
Cela interdit toute altération/hack par un client Flutter compromis.

---

## 5. Architecture générale

### 5.1 Structure du Frontend (Flutter)
```text
lib/
├── core/                  # Briques transverses : client PB, routeur, thèmes
├── features/              # Fonctionnalités métier
│   ├── auth/              # Connexion / Inscription / Splash
│   ├── chat/              # Listes des discussions / Écran de Chat détaillé
│   ├── events/            # Liste / Détail / Formulaire de création / Likes
│   ├── map/               # Carte interactive OSM
│   └── profile/           # Gestion du profil et des statistiques
├── shared/                # Widgets transverses (ex: event_card) & Providers globaux
└── main.dart              # Point d'entrée
```

### 5.2 Structure du Backend (PocketBase)
```text
backend_pocketbase/
├── pb_hooks/
│   └── main.pb.js         # Logique métier serveur (auto-relations, sécurisation)
├── scripts/
│   └── seed_demo_data.js  # Déploiement du jeu de données pour les démonstrations
├── pb_data/               # Dossier généré : SQLite, Logs, Fichiers uploadés
└── pocketbase.exe         # Moteur serveur Pocketbase
```

---

## 6. Base de données & Modèle Relationnel

Le système repose sur **6 collections principales** :

1. **`users`** : L'authentification (nom, email, avatar, bio).
2. **`events`** : L'événement central (titre, start_date, is_public, creator, location_name, lat, lng...). Pointé par le créateur.
3. **`event_members`** : La table pivot décisive.
   - Lie un `event` et un `user`.
   - `status` : "pending", "accepted", "rejected".
   - `role` : "member", "owner".
4. **`event_likes`** : Table pivot des favoris (un utilisateur ajoute un événement à ses favoris).
5. **`conversations`** : Le conteneur du chat, lié relationnellement en 1-1 avec un `event`.
6. **`messages`** : La table persistante hébergeant les messages d'une discussion, pointant vers `conversations` et `author` (User).

---

## 7. Règles Métier Backend (Les Hooks JS)

Les scripts dans `main.pb.js` orchestrent silencieusement :

1. **Création d'événement (`onRecordAfterCreateRequest`) :**
   Crée automatiquement et de façon sécurisée le dossier `conversation` ainsi que le ticket `event_members` en mode owner/accepted pour le créateur.
2. **Auto-Like et compteurs (`onRecordAfterCreateRequest` sur membres) :**
   Enregistre automatiquement un *like* si le membre est accepté et force la recomptabilisation propre (`members_count`, `likes_count`) directement en SQL brut pour éviter les blocages de la base de données.
3. **Sécurité Chat Strict (`onRecordCreateRequest` messages) :**
   Vérifie directement la présence d'une entrée "accepted" dans `event_members`. Rejette immédiatement en erreur "BadRequest 400" dans le cas contraire.

---

## 8. Données de Test & Lancement

L'application est fournie avec un script de provisionnement (`seed_demo_data.js`) extrêmement robuste. Il crée **31 comptes** liés par des interactions complexes, générant dynamiquement des *événements*, des *messages* et des *likes* pour que l'App vive instantanément au lancement.

### Comptes de démo disponibles :
* **Un compte testeur :** `test@goodapp.com`
* **10 profils créateurs :** `creator1@demo.com` ... `creator10@demo.com`
* **20 profils participants :** `participant1@demo.com` ... `participant20@demo.com`

**⚠️ MOT DE PASSE UNIQUE (pour tous les comptes) :** `azertyuiop`

---

## 9. Déploiement et Démarrage Local

Pour que l'intégralité du projet fonctionne sur une machine :

### A. Lancer le Serveur (Pocketbase)
```bash
# Dans le dossier backend_pocketbase
.\pocketbase.exe serve
# Le port 8090 doit être libre.
```

### B. Peupler la base de Démo (Seed)
```bash
# Dans un terminal distinct, depuis backend_pocketbase/scripts/
node seed_demo_data.js
# Vérifiez que le script indique "DONE!" et donne le nombre final d'utilisateurs.
```

### C. Lancer le Front-End (Flutter)
```bash
# Dans le dossier frontend_flutter/
flutter run
# Choisissez la plateforme Web (Edge/Chrome) ou l'émulateur Mobile (Android/iOS).
```

---

## 10. Conclusion & Dette technique réglée

Le projet a fait l'objet d'une remise à plat importante sur les composants cruciaux :
1. **Les Hooks PocketBase :** Remplacés par des syntaxes sécurisées (`try/catch` avec logs et Requêtes SQL natives) supportées par le runtime Goja interne (PocketBase v0.22) pour parer aux erreurs inattendues de verrouillage transactionnel et empêcher l'émission de Code HTTP 400 non désiré au Frontend.
2. **Le Seed :** Gère un parsing propre des dates (`toISOString` modifié) supporté validement par la DB sans faille. Il répare de manière auto-suffisante la base de données.
3. **Routing Chat Stabilisé :** La convention unique a été entérinée : Le routage utilise systématiquement `eventId` (`/chat/:eventId`), laissant le provider Flutter interroger l'identifiant exact de la discussion à l'arrivée sur la vue, favorisant un affichage fluide.

**L'application est dans un état V1 complet, prêt pour une présentation et une interopérabilité directe.**
