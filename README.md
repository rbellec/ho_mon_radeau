# HoMonRadeaaaUUUUUHOAUUUUOOOOOOO !

> Application web d'auto-gestion pour l'événement [Tutto Blu](https://tuttoblu.discourse.group/)

## 🎯 Objectif

Cette application facilite l'organisation de **Tutto Blu**, un événement unique où les participant·es construisent leurs propres radeaux puis les mettent à l'eau pour créer ensemble un village flottant éphémère sur un lac.

L'application permet aux équipages de :
- S'inscrire et former des équipages
- Gérer leur radeau (membres, rôles, ressources)
- Commander les bidons de flottaison
- Payer la cotisation (CUF)
- Coordonner avec l'organisation et les équipes support

**Cible :** ~500 participant·es, événement annuel, utilisation occasionnelle (2-3 fois/semaine en phase de préparation).

## 🤝 Comment participer ?

### 1. Consulter la documentation des features

**👉 La première étape est de lire les spécifications détaillées dans [`docs/features/`](./docs/features/)**

Vous y trouverez :
- **16 features complètement spécifiées** avec cas d'usage, règles métier, maquettes UI, et notes techniques
- La liste complète dans [`docs/features/README.md`](./docs/features/README.md)

### 2. Proposer des améliorations

- **Ouvrir une issue** sur GitHub pour discuter d'une feature, signaler un bug, ou proposer une amélioration
- **Créer une Pull Request** avec vos modifications
- Les PR sur la **documentation des features** sont les bienvenues !

### 3. Contribuer au code

Le projet est en **développement actif**.

Si vous souhaitez contribuer au code :
- Lisez [`CLAUDE.md`](./CLAUDE.md) pour les conventions du projet
- Le code doit être en **anglais** (noms de variables, commentaires)
- La documentation doit être en **français**

## 🤖 Développement assisté par IA (Ralph Loop)

Ce projet utilise la technique **[Ralph Loop](https://ghuntley.com/ralph/)** — une boucle d'itération continue avec Claude Code qui implémente les features automatiquement à partir des spécifications dans `docs/features/`.

```bash
# Lancer une boucle d'implémentation automatique
/ralph-loop:ralph-loop "$(cat PROMPT.md)" --completion-promise "MVP COMPLETE" --max-iterations 30
```

Les spécifications dans `docs/features/` servent de source de vérité pour l'IA comme pour les développeur·euses humain·es.

## 📚 Stack Technique

### Backend
- **Elixir** (latest stable) - Langage fonctionnel, concurrent, fiable
- **Phoenix Framework** (latest stable) - Framework web moderne
- **PostgreSQL 16** - Base de données relationnelle
- **Docker + Docker Compose** - Containerisation

### Frontend
- **Phoenix LiveView** - Interface réactive sans JavaScript complexe
- Approche minimaliste : fonctionnalité avant esthétique

### Authentification
- **phx.gen.auth** - Authentification email/password avec validation
- Pas de SSO externe (indépendance vis-à-vis des grandes plateformes)

### Infrastructure
- **Développement :** Docker Compose local
- **Production :** Fly.io
- **Stockage fichiers :** Tigris (S3-compatible, Fly.io)
- **Email dev :** Mailcatcher
- **Admin :** Kaffy (interface CRUD intégrée)

## 🚀 Installation Rapide

### Prérequis
- Docker & Docker Compose
- Git

### Démarrage
```bash
# Clone
git clone [repository-url]
cd ho_mon_radeau

# Démarrer les services
docker compose up

# L'application sera accessible sur :
# - App : http://localhost:4000
# - Mailcatcher : http://localhost:1080
```

### Commandes Utiles
```bash
# Shell Elixir dans le container
docker compose exec app iex -S mix

# Migrations
docker compose run --rm app mix ecto.migrate

# Tests + vérification complète (compile, format, tests)
docker compose run --rm -e MIX_ENV=test app mix precommit

# Tests seuls
docker compose run --rm -e MIX_ENV=test app mix test

# Format code
docker compose run --rm app mix format

# Arrêter les services
docker compose down

# Créer des données de test (dev uniquement)
docker compose exec app mix run priv/repo/seeds_dev.exs
```

### Données de test

```bash
# Créer les utilisateurs et radeaux de test
docker compose exec app mix run priv/repo/seeds_dev.exs

# Comptes de test :
# Admin    : admin@tuttoblu.test / password123
# Marins   : marin1@example.com … marin4@example.com / password123
# En attente : nouveau1@example.com / password123
```

## 📂 Structure du Projet

```
ho_mon_radeau/
├── CLAUDE.md              # Conventions et configuration du projet
├── README.md              # Ce fichier
├── docker-compose.yml     # Services Docker (PostgreSQL, Phoenix, Mailcatcher)
├── Dockerfile             # Image Phoenix/Elixir
├── docs/
│   └── features/          # 📖 Documentation complète des features (COMMENCEZ ICI)
├── lib/
│   ├── ho_mon_radeau/     # Business logic (contextes, schémas)
│   └── ho_mon_radeau_web/ # Phoenix web layer (LiveViews, controllers)
├── config/                # Configuration Phoenix
├── priv/                  # Assets, migrations
└── test/                  # Tests
```

## 🌍 Philosophie du Projet

- **Simplicité d'abord** - Solutions directes plutôt que sur-ingénierie
- **Auto-gestion** - Favoriser l'autonomie des participant·es
- **Open Source** - Transparence et contributions bienvenues
- **Indépendance** - Pas de dépendance aux grandes plateformes, liberté de choix des outils
- **Documentation exhaustive** - Pour faciliter les contributions

## 📝 Licence

À définir

---

**Pour toute question :** Ouvrez une issue sur GitHub ou consultez le [forum Tutto Blu](https://tuttoblu.discourse.group/)
