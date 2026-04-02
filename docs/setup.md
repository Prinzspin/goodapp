# Guide de Setup — Backend PocketBase

## 1. Télécharger PocketBase

Aller sur https://pocketbase.io/docs et télécharger le binaire correspondant à ton OS :

| OS | Fichier |
|---|---|
| Windows (64-bit) | `pocketbase_X.X.X_windows_amd64.zip` |
| macOS (ARM) | `pocketbase_X.X.X_darwin_arm64.zip` |
| macOS (Intel) | `pocketbase_X.X.X_darwin_amd64.zip` |
| Linux (64-bit) | `pocketbase_X.X.X_linux_amd64.zip` |

Extraire le binaire et le placer dans `backend_pocketbase/`.

---

## 2. Lancer PocketBase

```bash
# Linux / macOS
cd backend_pocketbase
chmod +x pocketbase
./pocketbase serve

# Windows PowerShell
cd backend_pocketbase
.\pocketbase.exe serve
```

> ✅ Admin UI : http://127.0.0.1:8090/_/
> ✅ API REST : http://127.0.0.1:8090/api/

---

## 3. Créer le compte admin

Lors du premier lancement, ouvrir http://127.0.0.1:8090/_/ et créer un compte admin (email + mot de passe).

---

## 4. Créer les collections

> **Respecter l'ordre suivant** pour éviter les erreurs de relations.

### Ordre de création
1. `users` (Auth collection)
2. `events`
3. `event_members`
4. `event_likes`
5. `conversations`
6. `messages`

Se référer à `docs/schema_pocketbase.md` pour les champs exacts, les règles et les index de chaque collection.

---

## 5. Configurer les index

Pour chaque collection, aller dans **Settings → Indexes** et ajouter :

| Collection | Champ(s) | Type |
|---|---|---|
| `events` | `creator` | Index classique |
| `events` | `is_public` | Index classique |
| `events` | `start_date` | Index classique |
| `event_members` | `event, user` | **UNIQUE** |
| `event_members` | `event, status` | Index classique |
| `event_likes` | `event, user` | **UNIQUE** |
| `conversations` | `event` | **UNIQUE** |
| `messages` | `conversation, created` | Index classique |

---

## 6. Vérifier les hooks JS

Le fichier `pb_hooks/main.pb.js` est chargé automatiquement par PocketBase au démarrage.

Pour vérifier :
1. Relancer PocketBase
2. Créer un événement via l'admin UI
3. Vérifier dans la collection `conversations` → une entrée doit avoir été créée automatiquement
4. Vérifier dans `event_members` → le créateur doit apparaître avec `status: accepted` et `role: owner`

---

## 7. Variables d'environnement (optionnel)

Pour personnaliser l'URL et le port :
```bash
./pocketbase serve --http="0.0.0.0:8080"
```

Pour un usage en production, définir une URL publique et configurer CORS :
```bash
./pocketbase serve --http="0.0.0.0:8090" --origins="https://ton-domaine.com"
```

---

## 8. Accès depuis le téléphone (développement)

Pour tester depuis un device physique ou un émulateur Android :

1. Trouver l'IP locale de la machine : `ipconfig` (Windows) ou `ifconfig` (macOS/Linux)
2. Lancer PocketBase sur `0.0.0.0` : `./pocketbase serve --http="0.0.0.0:8090"`
3. Dans Flutter, remplacer `127.0.0.1` par l'IP locale (ex: `192.168.1.42`)

> ⚠️ L'émulateur Android utilise `10.0.2.2` pour accéder au localhost de la machine hôte.

---

## 9. Sauvegarde des données

Le dossier `pb_data/` contient la base SQLite et les fichiers uploadés.
Pour sauvegarder :
```bash
cp -r pb_data/ pb_data_backup/
```

> `pb_data/` est dans `.gitignore` — ne jamais committer ce dossier.
