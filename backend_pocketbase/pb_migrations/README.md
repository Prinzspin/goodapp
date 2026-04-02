# pb_migrations

En V1, les collections sont créées et configurées **manuellement via l'admin UI PocketBase** (`http://127.0.0.1:8090/_/`).

Ce dossier est réservé pour les futures migrations automatisées si le projet évolue vers une gestion de schéma versionnée.

## Pourquoi pas de migrations en V1 ?

PocketBase génère automatiquement des fichiers de migration Go lorsqu'on modifie le schéma via l'admin UI (dans `pb_data/`).
Pour la V1, l'admin UI est suffisante et plus simple à maintenir.

## En V2+

Si le projet a besoin de migrations reproductibles (CI/CD, multi-environnements), utiliser :
- Les fichiers `pb_migrations/*.go` générés automatiquement
- Ou écrire des migrations JS dans `pb_hooks/` avec `migrate(...)`
