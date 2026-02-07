# Guide d'implémentation - HoMonRadeau

> Ce fichier guide la prochaine session Claude Code pour démarrer l'implémentation de l'application Phoenix.

## 📍 État actuel du projet

✅ **Phase de spécification TERMINÉE**

- **12 features complètement documentées** dans `docs/features/`
- Toutes les règles métier définies
- Tous les cas d'usage décrits
- Notes techniques et schémas de base de données fournis
- 3 commits effectués :
  - `76c19bb` : Specs initiales complètes
  - `b6051ef` : Corrections basées sur feedback
  - `63fce02` : README mis à jour

## 🎯 Objectif de la prochaine session

**Initialiser l'application Phoenix et implémenter les premières features MVP.**

## 🚀 Étapes d'implémentation

### Phase 1 : Initialisation du projet Phoenix

#### 1.1 Générer l'application Phoenix

```bash
# Dans le container Docker
docker-compose run --rm app mix phx.new . --app ho_mon_radeau --database postgres

# Ou si vous préférez générer hors container puis copier
mix phx.new ho_mon_radeau --database postgres
```

**Important :**
- L'application s'appelle `ho_mon_radeau` (snake_case)
- Les modules seront `HoMonRadeau.*` (PascalCase)
- Utiliser PostgreSQL comme base de données

#### 1.2 Configurer la base de données

Mettre à jour `config/dev.exs` avec les paramètres Docker :

```elixir
config :ho_mon_radeau, HoMonRadeau.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "db",  # Nom du service Docker
  database: "ho_mon_radeau_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

#### 1.3 Créer la base de données

```bash
docker-compose run --rm app mix ecto.create
```

### Phase 2 : Authentification de base (FEATURE-001)

#### 2.1 Générer phx.gen.auth

```bash
docker-compose run --rm app mix phx.gen.auth Accounts User users
```

Cela génère :
- Le contexte `Accounts`
- Le schéma `User`
- Les controllers, views, templates d'authentification
- Les migrations

#### 2.2 Ajouter les champs personnalisés au schéma User

Créer une migration pour ajouter les champs de FEATURE-001 :

```bash
docker-compose run --rm app mix ecto.gen.migration add_user_fields
```

Champs à ajouter (voir `docs/features/FEATURE-001-inscription-utilisateur.md`) :
- `nickname` (string, nullable)
- `first_name` (string, nullable)
- `last_name` (string, nullable)
- `phone_number` (string, nullable)
- `profile_picture_url` (string, nullable)
- `profile_picture_public` (boolean, default: false)
- `validated` (boolean, default: false) - pour FEATURE-002

#### 2.3 Exécuter les migrations

```bash
docker-compose run --rm app mix ecto.migrate
```

### Phase 3 : Système d'éditions (FEATURE-007)

Créer la table `editions` en premier car elle est référencée par `rafts` et `crews`.

```bash
docker-compose run --rm app mix ecto.gen.migration create_editions
```

Contenu de la migration (voir `docs/features/FEATURE-007-pages-publiques-radeaux.md`) :

```elixir
create table(:editions) do
  add :year, :integer, null: false
  add :name, :string
  add :is_current, :boolean, default: false
  add :start_date, :date
  add :end_date, :date

  timestamps()
end

create unique_index(:editions, [:year])
```

Créer également le contexte et le schéma :

```bash
docker-compose run --rm app mix phx.gen.context Events Edition editions year:integer name:string is_current:boolean start_date:date end_date:date
```

### Phase 4 : Radeaux et Équipages (FEATURE-003)

#### 4.1 Créer les tables rafts et crews

```bash
docker-compose run --rm app mix ecto.gen.migration create_rafts_and_crews
```

Voir les schémas détaillés dans :
- `docs/features/FEATURE-003-creation-equipage.md`
- `docs/features/FEATURE-007-pages-publiques-radeaux.md`

Tables principales :
- `rafts` (avec `edition_id`)
- `crews` (avec `edition_id`)
- `crew_members` (avec champs `is_manager`, `is_captain`, `roles`, `participation_status`)

**Important :** Index unique sur `[:name, :edition_id]` pour les rafts.

#### 4.2 Créer les contextes Elixir

```bash
docker-compose run --rm app mix phx.gen.context Events Raft rafts
docker-compose run --rm app mix phx.gen.context Events Crew crews
docker-compose run --rm app mix phx.gen.context Events CrewMember crew_members
```

### Phase 5 : Ordre d'implémentation des features MVP (P0)

Suivre cet ordre pour les features prioritaires :

1. **FEATURE-001** : Inscription utilisateur ✅ (fait en Phase 2)
2. **FEATURE-002** : Validation des nouveaux participants
   - Ajouter le contexte de validation
   - Interface pour équipe d'accueil
3. **FEATURE-003** : Création d'équipage ✅ (structure en Phase 4)
4. **FEATURE-004** : Gestion des gestionnaires
5. **FEATURE-005** : Adhésion à un équipage
6. **FEATURE-007** : Pages publiques des radeaux
7. **FEATURE-008** : Pages privées des radeaux

### Phase 6 : Tests

Pour chaque feature implémentée :
- Tests unitaires des contextes (`test/ho_mon_radeau/`)
- Tests d'intégration des controllers (`test/ho_mon_radeau_web/controllers/`)
- Tests LiveView si applicable

```bash
docker-compose run --rm app mix test
```

## 📚 Documentation de référence

**Toutes les spécifications sont dans `docs/features/` :**

- **Index complet** : `docs/features/README.md`
- **Clarifications et décisions** : `docs/features/notes-clarifications.md`
- **Chaque feature** : `docs/features/FEATURE-XXX-*.md`

**Chaque fichier de feature contient :**
- Description et objectifs
- Comportements attendus
- Règles métier
- Interface utilisateur
- Notes techniques (schémas DB, contextes Elixir, routes)
- Dépendances

## ⚙️ Conventions importantes

Lire `CLAUDE.md` pour les conventions complètes. Rappels importants :

### Langue
- **Code et commentaires** : Anglais uniquement
- **Documentation** : Français (dans `docs/`)
- **Commits** : Anglais

### Nommage
- Application : `ho_mon_radeau` (snake_case)
- Modules : `HoMonRadeau.*` (PascalCase)
- Tables DB : snake_case
- Routes : kebab-case

### Structure du code
```
lib/
├── ho_mon_radeau/           # Business logic
│   ├── accounts/            # Contexte Users
│   ├── events/              # Contexte Rafts, Crews, etc.
│   ├── cuf/                 # Contexte CUF
│   └── drums/               # Contexte Bidons
└── ho_mon_radeau_web/       # Web layer
    ├── controllers/
    ├── live/                # LiveView
    ├── views/
    └── templates/
```

## 🔍 Points d'attention critiques

### 1. Système d'éditions
- **TOUJOURS** associer rafts et crews à une édition
- Index unique : `[:name, :edition_id]` pour les rafts
- Créer l'édition courante au démarrage si elle n'existe pas

### 2. Un seul équipage par utilisateur
- Un user ne peut être membre que d'**un seul équipage**
- Mais peut être membre de **plusieurs équipes transverses**
- Vérifier cette règle dans les validations

### 3. Équipes transverses
- En **nombre limité** (Accueil, SAFE, Bidons, Sécurité, Médecine)
- Gérées plutôt **en dur dans le code** avec types spécifiques
- Champ `transverse_type` avec valeurs fixes : `welcome_team`, `safe_team`, `drums_team`, `security`, `medical`, `other`

### 4. Montants figés
- Une fois CUF ou bidons payés, le montant **ne change plus**
- Stocker le `unit_price` au moment de la transaction

### 5. Capitaine obligatoirement participant
- Le capitaine doit être un participant (CUF payée)
- Exception temporaire : peut être nommé avant validation CUF

## 🎨 Interface et UX

- Utiliser **Phoenix LiveView** pour les interfaces réactives
- Approche **minimaliste** : fonctionnalité avant esthétique
- Pas de framework CSS complexe (Tailwind basique suffit)
- Messages flash pour les confirmations/erreurs
- Formulaires simples et clairs

## 🧪 Commandes utiles pendant le développement

```bash
# Démarrer l'application
docker-compose up

# Shell interactif Elixir
docker-compose exec app iex -S mix

# Créer une migration
docker-compose run --rm app mix ecto.gen.migration nom_migration

# Exécuter les migrations
docker-compose run --rm app mix ecto.migrate

# Rollback d'une migration
docker-compose run --rm app mix ecto.rollback

# Générer un contexte
docker-compose run --rm app mix phx.gen.context Contexte Schema table champ:type

# Générer un controller LiveView
docker-compose run --rm app mix phx.gen.live Contexte Schema schemas champ:type

# Tests
docker-compose run --rm app mix test

# Tests avec couverture
docker-compose run --rm app mix test --cover

# Format du code
docker-compose run --rm app mix format

# Analyse statique (Credo)
docker-compose run --rm app mix credo
```

## 📦 Dépendances supplémentaires potentielles

À ajouter dans `mix.exs` si besoin :

```elixir
defp deps do
  [
    # ... deps existantes
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:ex_machina, "~> 2.7", only: :test},  # Pour les factories de test
    {:faker, "~> 0.17", only: :test}       # Pour générer des données de test
  ]
end
```

## 🚨 Avant de commencer à coder

1. ✅ **Lire attentivement** les features dans `docs/features/`
2. ✅ **Comprendre** les relations entre les entités (rafts, crews, users, editions)
3. ✅ **Vérifier** les règles d'unicité et les contraintes
4. ✅ **Suivre** l'ordre d'implémentation recommandé (phases 1-5)
5. ✅ **Tester** après chaque feature implémentée

## 💡 Conseils pour Claude Code

- **Lire les fichiers de features** avant d'implémenter
- **Utiliser les notes techniques** fournies (schémas DB, contextes)
- **Respecter les conventions** du projet (langue, nommage)
- **Tester progressivement** plutôt que tout implémenter d'un coup
- **Poser des questions** si une règle métier n'est pas claire
- **Commiter régulièrement** avec des messages descriptifs

## 📞 En cas de question

- Consulter `docs/features/notes-clarifications.md`
- Vérifier `CLAUDE.md` pour les conventions
- Ouvrir une issue sur GitHub si besoin de clarification

---

**Prêt à coder ! 🚀**

Commencez par la Phase 1 (Initialisation Phoenix) et suivez les phases dans l'ordre.
