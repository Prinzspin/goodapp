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

## 2. Nouveautés & Modernisation (v1.5)

L'application a subi une refonte visuelle et technique majeure pour améliorer l'expérience utilisateur et l'accessibilité :

### 🎨 Design System Unifié
- **Couleur Primaire :** Passage à un **Indigo Moderne (`#4F46E5`)** sur l'ensemble de l'application (Headers, Boutons, Icônes).
- **Cohérence Visuelle :** Suppression des couleurs disparates pour une identité de marque forte et professionnelle.
- **Composants Premium :** Utilisation de dégradés subtils, de cartes avec ombres douces et d'une typographie lisible (Inter/Roboto).

### ♿ Accessibilité (WCAG)
- **Mode Contraste Élevé :** Un commutateur global dans le profil permet de basculer l'application sur une palette "High Contrast" (Indigo 950 / Noir / Blanc) avec des bordures renforcées sur tous les éléments interactifs.
- **Optimisation Lecteur d'Écran :** Ajout systématique de labels `Semantics` et de `tooltips` sur les boutons et actions critiques.
- **Simplification :** Retrait des réglages complexes au profit d'une interface auto-adaptative et robuste.

### 🔍 Recherche Intégrée
- Mise en place d'une barre de recherche temps réel sur la page d'accueil permettant de filtrer les événements par **titre**, **lieu** ou **description**.

---

## 3. Stack technique

### Frontend
- **Framework :** Flutter (cible principale : Web et Mobile Android/iOS).
- **Navigation :** GoRouter.
- **État / Injection :** Riverpod.
- **Carte :** `flutter_map` + OpenStreetMap + `latlong2`.
- **Thématisation :** Système de thèmes dynamiques (Light / High Contrast).
- **Client Backend :** PocketBase Dart SDK.

### Backend
- **Base de données / API / Auth :** PocketBase (Go/SQLite).
- **Logique métier métier :** Hooks JavaScript (`pb_hooks`) exécutés par le moteur Goja.
- **Temps réel :** Mécanisme natif SSE (Server-Sent Events) de PocketBase.

---

## 4. Architecture générale

### 5.1 Structure du Frontend (Flutter)
```text
lib/
├── core/                  # Briques transverses : client PB, routeur, thèmes dynamiques
├── features/              # Fonctionnalités métier
│   ├── auth/              # Connexion / Inscription / Splash
│   ├── chat/              # Listes des discussions / Écran de Chat détaillé
│   ├── events/            # Liste / Détail / Formulaire de création / Recherche
│   ├── map/               # Carte interactive OSM
│   └── profile/           # Profil, Statistiques & Réglages Accessibilité
├── shared/                # Widgets transverses & Providers globaux (Auth, Contraste)
└── main.dart              # Point d'entrée & Configuration MaterialApp
```

---

## 5. Guide de Démarrage Local

### A. Lancer le Serveur (Pocketbase)
```bash
# Dans le dossier backend_pocketbase
.\pocketbase.exe serve
```

### B. Peupler la base de Démo (Seed)
```bash
# Dans un terminal distinct, depuis backend_pocketbase/scripts/
node seed_demo_data.js
```

### C. Lancer le Front-End (Flutter)
```bash
# Dans le dossier frontend_flutter/
flutter run
```

---

## 6. Accessibilité & Thèmes (Détail Technique)

L'état de l'accessibilité est géré par un `StateProvider` global (`highContrastProvider`) situé dans `lib/shared/providers/accessibility_provider.dart`. 

Le `MaterialApp` dans `main.dart` écoute ce provider pour basculer entre `AppTheme.lightTheme` et `AppTheme.highContrastTheme`. Tous les composants UI consomment `Theme.of(context)` pour assurer une propagation instantanée des changements de couleurs et de bordures sans rechargement de page.

---

**L'application est dans un état V1.5 complet, moderne, accessible et prêt pour une démonstration.**
