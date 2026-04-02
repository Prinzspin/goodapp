# Schéma PocketBase — Collections définitives V1

## Ordre de création obligatoire
> Respecter cet ordre pour éviter les erreurs de référence entre relations.
> `users → events → event_members → event_likes → conversations → messages`

---

## 1. `users` — Auth collection native

> Dans l'admin UI : **New collection → Auth**

| Champ | Type | Requis | Options |
|---|---|---|---|
| `name` | Text | ✅ | min: 2, max: 100 |
| `avatar` | File | ❌ | max 1 fichier, types: jpg,jpeg,png,webp, max 5MB |
| `bio` | Text | ❌ | max: 500 |

**Règles d'accès :**
| Opération | Règle |
|---|---|
| List | `@request.auth.id != ""` |
| View | `@request.auth.id != ""` |
| Create | *(géré par l'auth PocketBase)* |
| Update | `id = @request.auth.id` |
| Delete | `id = @request.auth.id` |

---

## 2. `events`

> Dans l'admin UI : **New collection → Base**

| Champ | Type | Requis | Options |
|---|---|---|---|
| `title` | Text | ✅ | min: 3, max: 200 |
| `description` | Text | ❌ | max: 2000 |
| `start_date` | Date | ✅ | |
| `end_date` | Date | ❌ | |
| `location_name` | Text | ❌ | max: 200 |
| `lat` | Number | ❌ | décimal |
| `lng` | Number | ❌ | décimal |
| `is_public` | Bool | ✅ | défaut: `true` |
| `photos` | File | ❌ | max 10 fichiers, types: jpg,jpeg,png,webp, max 10MB chacun |
| `creator` | Relation → users | ✅ | single, cascade delete |
| `likes_count` | Number | ✅ | défaut: `0`, min: 0 |
| `members_count` | Number | ✅ | défaut: `0`, min: 0 |

**Règles d'accès :**
| Opération | Règle |
|---|---|
| List | *(vide = public)* |
| View | *(vide = public)* |
| Create | `@request.auth.id != ""` |
| Update | `creator = @request.auth.id` |
| Delete | `creator = @request.auth.id` |

**Index :**
| Champ(s) | Type |
|---|---|
| `creator` | Index |
| `is_public` | Index |
| `start_date` | Index |

---

## 3. `event_members`

> Dans l'admin UI : **New collection → Base**

| Champ | Type | Requis | Options |
|---|---|---|---|
| `event` | Relation → events | ✅ | single, cascade delete |
| `user` | Relation → users | ✅ | single, cascade delete |
| `status` | Select | ✅ | valeurs: `pending`, `accepted`, `rejected` |
| `role` | Select | ✅ | valeurs: `owner`, `member` — défaut: `member` |

**Règles d'accès :**
| Opération | Règle |
|---|---|
| List | `@request.auth.id != ""` |
| View | `@request.auth.id != ""` |
| Create | `user = @request.auth.id` |
| Update | `event.creator = @request.auth.id` |
| Delete | `user = @request.auth.id \|\| event.creator = @request.auth.id` |

**Index :**
| Champ(s) | Type | Note |
|---|---|---|
| `event` + `user` | **Unique composite** | Empêche les doublons de demande |
| `event` + `status` | Index | Requête membres accepted |

---

## 4. `event_likes`

> Dans l'admin UI : **New collection → Base**

| Champ | Type | Requis | Options |
|---|---|---|---|
| `event` | Relation → events | ✅ | single, cascade delete |
| `user` | Relation → users | ✅ | single, cascade delete |

**Règles d'accès :**
| Opération | Règle |
|---|---|
| List | `@request.auth.id != ""` |
| View | `@request.auth.id != ""` |
| Create | `user = @request.auth.id` |
| Update | *(désactivé — champ vide)* |
| Delete | `user = @request.auth.id` |

**Index :**
| Champ(s) | Type | Note |
|---|---|---|
| `event` + `user` | **Unique composite** | Empêche le double like |

---

## 5. `conversations`

> Dans l'admin UI : **New collection → Base**

| Champ | Type | Requis | Options |
|---|---|---|---|
| `event` | Relation → events | ✅ | single, cascade delete |

**Règles d'accès :**
| Opération | Règle |
|---|---|
| List | `event.creator = @request.auth.id || (@collection.event_members.event = event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = "accepted")` |
| View | `event.creator = @request.auth.id || (@collection.event_members.event = event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = "accepted")` |
| Create | `event.creator = @request.auth.id` *(la conversation est créée par hook, pas par Flutter)* |
| Update | `event.creator = @request.auth.id` |
| Delete | `event.creator = @request.auth.id` |

> ✅ **Garanti PocketBase** : seuls le créateur et les membres accepted voient les conversations.
> La règle `@collection.event_members` effectue un JOIN SQL sous-jacent — compatible PocketBase v0.20+.

**Index :**
| Champ | Type | Note |
|---|---|---|
| `event` | **Unique** | 1 conversation par event |

---

## 6. `messages`

> Dans l'admin UI : **New collection → Base**

| Champ | Type | Requis | Options |
|---|---|---|---|
| `conversation` | Relation → conversations | ✅ | single, cascade delete |
| `author` | Relation → users | ✅ | single, cascade delete |
| `content` | Text | ✅ | min: 1, max: 2000 |

> ⚠️ Ne pas ajouter de champ `updated` — les messages sont immuables.

**Règles d'accès :**
| Opération | Règle | Garanti par |
|---|---|---|
| List | `author = @request.auth.id || (@collection.event_members.event = conversation.event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = "accepted")` | ✅ PocketBase *(cross-join)* |
| View | *(même règle que List)* | ✅ PocketBase |
| Create | `@request.auth.id != "" && author = @request.auth.id` + **validation membership par hook** | ✅ Hook serveur |
| Update | *(désactivé — champ vide)* | ✅ PocketBase |
| Delete | `author = @request.auth.id` | ✅ PocketBase |

> 🔒 **Création de message garantie serveur** : le hook `onRecordBeforeCreateRequest` (Hook 5 dans `main.pb.js`) vérifie le membership **avant toute écriture**, même via appel API direct. C'est la garantie de sécurité principale du chat.

> Pas de champ `updated` — les messages sont immuables.

**Index :**
| Champ(s) | Type | Note |
|---|---|---|
| `conversation` + `created` | Index | Pagination + realtime |
