# HoMonRadeaaaUUUUUHOAUUUUOOOOOOO !

> Application web d'auto-gestion pour événements

## Motif

Cette application permet l'auto-gestion d'événements par les participants eux-mêmes, en réduisant la charge organisationnelle et en favorisant l'autonomie collective.

**Cas d'usage cible :** Événements de 500 participants maximum avec utilisation occasionnelle (2-3 fois par semaine).

## Stack Technique

### Backend
- **Elixir** (latest stable) - Langage fonctionnel, concurrent, fiable
- **Phoenix Framework** (latest stable) - Framework web moderne
- **PostgreSQL 16** - Base de données relationnelle
- **Docker + Docker Compose** - Containerisation et orchestration

### Frontend
- **Phoenix LiveView** - Interface réactive temps réel sans JavaScript complexe
- Approche minimaliste : fonctionnalité avant esthétique

### Authentification
- **phx.gen.auth** - Authentification native Phoenix
- Login/password avec validation email
- Reset password par email
- Pas de SSO (choix délibéré anti-GAFAM)

### Infrastructure
- **Développement :** Docker Compose local
- **Production :** Fly.io (déploiement simple via git push)
- **Email dev :** Mailcatcher
- **Traffic attendu :** Très faible (500 users max, usage occasionnel)

## Méthode de Développement

### Philosophie
- **Simplicité d'abord** - Solutions les plus simples et directes
- **Dernières versions stables** - Pas de legacy, toujours à jour
- **Documentation bilingue** - Code en anglais, docs features en français
- **Docker-first** - Environnement reproductible

### Workflow
1. **Planification** - Features documentées dans `docs/features/`
2. **Développement** - TDD avec tests automatisés
3. **Revue** - Code review via commits
4. **Déploiement** - `fly deploy` vers production

### Structure du Projet
```
ho_mon_radeau/
├── CLAUDE.md              # Configuration projet (conventions, stack)
├── README.md              # Ce fichier
├── docker-compose.yml     # Services Docker
├── Dockerfile             # Image Phoenix
├── lib/                   # Code Elixir
│   ├── ho_mon_radeau/     # Business logic
│   └── ho_mon_radeau_web/ # Phoenix web layer
├── docs/
│   └── features/          # Documentation features (français)
├── config/                # Configuration Phoenix
├── priv/                  # Assets, migrations
└── test/                  # Tests
```

## Installation Rapide

### Prérequis
- Docker & Docker Compose
- Git

### Démarrage
```bash
# Clone
git clone [repository-url]
cd ho_mon_radeau

# Démarrer les services
docker-compose up

# L'application est accessible sur http://localhost:4000
# Mailcatcher sur http://localhost:1080
```

### Commandes Utiles
```bash
# Shell Elixir dans le container
docker-compose exec app iex -S mix

# Migrations
docker-compose exec app mix ecto.migrate

# Tests
docker-compose exec app mix test

# Format code
docker-compose exec app mix format
```

## Déploiement

### Fly.io
```bash
# Premier déploiement
fly launch

# Déploiements suivants
fly deploy

# Voir les logs
fly logs
```

## Contribution

Voir `CLAUDE.md` pour les conventions de code et de documentation.

## Licence

À définir
