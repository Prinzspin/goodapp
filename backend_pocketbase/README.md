# Backend PocketBase — Application Événements

## Prérequis

- Télécharger le binaire PocketBase depuis https://pocketbase.io/docs
- Placer le binaire dans ce dossier (`backend_pocketbase/`)

## Lancer PocketBase en local

### Linux / macOS
```bash
cd backend_pocketbase
chmod +x pocketbase
./pocketbase serve
```

### Windows
```powershell
cd backend_pocketbase
.\pocketbase.exe serve
```

L'admin UI est disponible à : **http://127.0.0.1:8090/_/**
L'API REST est disponible à : **http://127.0.0.1:8090/api/**

## Premier lancement

1. Ouvrir http://127.0.0.1:8090/_/
2. Créer un compte admin (email + mot de passe)
3. Créer les collections dans l'ordre indiqué dans `docs/schema_pocketbase.md`
4. Configurer les règles d'accès et les index
5. Les hooks JS dans `pb_hooks/main.pb.js` sont chargés **automatiquement** au démarrage

## Structure

```
backend_pocketbase/
├── pb_hooks/
│   └── main.pb.js       # Hooks automatiques (créateur membre, conversation, compteurs)
├── pb_migrations/
│   └── README.md        # Note sur la stratégie de migration V1
├── pb_data/             # Généré automatiquement par PocketBase (dans .gitignore)
├── .gitignore
└── README.md
```

## Documentation complémentaire

- `docs/schema_pocketbase.md` — schéma complet des collections
- `docs/api_endpoints.md` — endpoints utilisés par Flutter
- `docs/rules_and_guarantees.md` — ce que PocketBase garantit vs Flutter
- `docs/setup.md` — guide de setup complet
