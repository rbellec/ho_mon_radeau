# FEATURE-007 : Pages publiques des radeaux

## Description
Chaque radeau dispose d'une page publique accessible à tous les utilisateurs (connectés ou non) présentant les informations essentielles de l'équipage : nom, description, membres, photo du radeau, et lien vers le forum. Cette page permet aux personnes intéressées de découvrir les radeaux et éventuellement demander à les rejoindre.

## Objectif
Offrir une vitrine publique pour chaque radeau afin de faciliter la découverte et la formation des équipages. Permettre la transparence sur la composition des radeaux tout en respectant la vie privée des membres qui ne souhaitent pas être identifiés publiquement.

## Utilisateurs concernés
- **Visiteurs non connectés** : Peuvent consulter la liste et les pages des radeaux
- **Utilisateurs connectés** : Peuvent consulter et demander à rejoindre
- **Membres de l'équipage** : Voient leur profil affiché selon leurs préférences
- **Gestionnaires** : Peuvent modifier les informations publiques du radeau

## Comportement attendu

### Liste des radeaux

#### Page d'accueil ou page "Radeaux"
Affichage de tous les radeaux avec :
- **Photo du radeau** (si définie)
- **Nom du radeau**
- **Description courte** (premiers 150 caractères)
- **Nombre de membres** (ex: "12 membres")
- **Statut** : Badge "Participant" ou "Proposé"
- **Lien** : Vers la page publique du radeau

#### Ordre d'affichage
- **Radeaux participants (validés)** en premier
- Puis **radeaux proposés (non validés)**
- Tri alphabétique dans chaque catégorie (ou par date de création)

#### Filtres (optionnel)
- Afficher seulement les participants
- Afficher seulement les proposés
- Recherche par nom

### Page publique d'un radeau

#### URL
`/[année]/radeaux/[nom-du-radeau]` ou `/[année]/radeaux/[id]`

Exemples :
- `/2026/radeaux/fun-radeau`
- `/2027/radeaux/fun-radeau`

Le même nom de radeau peut exister pour différentes éditions, mais chaque radeau est **unique par édition**.

#### Contenu affiché

**En-tête :**
```
[Photo du radeau]

RADEAU [NOM]
Badge : [Participant] ou [Proposé]

Description
-----------
[Texte complet de la description]

Discussion sur le forum
[Lien vers Discourse] (si défini)
```

**Membres de l'équipage :**
```
Membres (12)
------------
[Photo] Pseudo1
[Photo] Pseudo2
[?] Matelot sans pseudonyme
[Photo] Pseudo3
...

+ 3 matelots secrets
```

**Fichiers publics :**
```
Documents et liens
------------------
→ Photo du radeau en construction [lien externe]
→ Plan du radeau [lien Google Drive]
→ Playlist Spotify de l'équipage [lien externe]
```

**Actions (si utilisateur connecté) :**
- Bouton "Demander à rejoindre cet équipage" (voir FEATURE-005)
- Ou message "Vous êtes membre de cet équipage"
- Ou message "Vous êtes déjà membre d'un autre équipage"

## Règles métier

### Éditions annuelles

Chaque événement Tutto Blu correspond à une **édition** (année) :
- Un radeau est **unique par édition** (ex: "Fun Radeau 2026")
- Le **même nom de radeau** peut être réutilisé d'une année sur l'autre
- Mais ce ne sera **pas le même radeau ni le même équipage**
- Un radeau peut être lié aux radeaux du même nom des éditions précédentes (historique)
- Un équipage est lié à **une seule édition**

**Exemples :**
- "Fun Radeau" existe en 2025 (événement passé, non traité dans l'app)
- "Fun Radeau" existe en 2026 (événement actuel)
- "Fun Radeau" existera probablement en 2027 (futur)

**Règle d'unicité :** Le nom du radeau doit être unique **pour une édition donnée**, mais peut être réutilisé pour d'autres éditions.

### Visibilité des données

#### Toujours public
- Nom du radeau
- Description du radeau
- Photo du radeau
- Nombre de membres
- Statut (participant/proposé)
- Lien forum Discourse
- Liens vers fichiers/documents externes

#### Conditionnel (selon préférences membre)
- **Pseudo :** Toujours affiché s'il existe
- **Photo de profil :**
  - Si paramètre "photo publique" = true : affichée
  - Sinon : photo par défaut ou initiales

#### Jamais public
- Rôles des membres (capitaine, lead construction, etc.)
- Données personnelles (nom, prénom, email, téléphone)
- Informations CUF et bidons (sauf si décidé autrement)
- Discussions internes de l'équipage

### Matelot sans pseudonyme
- Utilisateur inscrit sans pseudo défini
- Affiché comme "Matelot sans pseudonyme" avec photo générique
- **Compté** dans le nombre de membres

### Matelots secrets
- Membres qui n'ont pas de pseudo OU qui ont masqué leur photo
- Affichage en bas de liste : "+ X matelots secrets"
- **Comptés** dans le nombre total de membres

### Photo du radeau
- Stockée dans l'application (pas de lien externe)
- Format : JPG/PNG
- Modifiable par les gestionnaires uniquement

### Fichiers publics
- **Liens externes uniquement** (Google Drive, Notion, Dropbox, etc.)
- Pas d'upload de fichiers dans l'app (sauf photos)
- Chaque lien a un titre et une URL

## Interface utilisateur

### Page liste des radeaux
```
Radeaux Tutto Blu

[Recherche : ___________] [Filtres ▼]

PARTICIPANTS (12 radeaux)
-------------------------
┌─────────────────────────────────────┐
│ [Photo]  Radeau La Loutre           │
│          "Un radeau écolo avec..."  │
│          15 membres                 │
│          [Voir le radeau]           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ [Photo]  Radeau Le Kraken           │
│          "Pirates des lacs de..."   │
│          8 membres                  │
│          [Voir le radeau]           │
└─────────────────────────────────────┘

PROPOSÉS (5 radeaux)
--------------------
┌─────────────────────────────────────┐
│ [Photo]  Radeau L'Albatros          │
│          "En cours de formation..." │
│          3 membres                  │
│          [Voir le radeau]           │
└─────────────────────────────────────┘
```

### Page publique du radeau
```
┌─────────────────────────────────────────────┐
│                                             │
│        [Photo du radeau - grande]           │
│                                             │
└─────────────────────────────────────────────┘

RADEAU LA LOUTRE [Badge: Participant]

Description
-----------
Notre radeau est construit avec des matériaux de récup
et une bonne dose d'énergie collective. On cherche des
personnes motivées pour nous rejoindre !

💬 Discussion sur le forum
→ https://tuttoblu.discourse.group/t/radeau-la-loutre

Membres de l'équipage (15)
---------------------------
[Photo] Alice42      [Photo] BobBuilder
[Photo] Charlie      [?] Matelot sans pseudonyme
[Photo] Diana        [Photo] Enzo
...
+ 2 matelots secrets

Documents et liens
------------------
→ Photos de la construction
  https://drive.google.com/...
→ Plan technique du radeau
  https://docs.google.com/...

[Demander à rejoindre cet équipage]

---
← Retour à la liste des radeaux
```

### Page pour visiteur non connecté
Même affichage mais :
- Pas de bouton "Demander à rejoindre"
- Message : "Connectez-vous pour demander à rejoindre un équipage"

## Dépendances
- **FEATURE-001** (Inscription) : Gestion des pseudos et photos
- **FEATURE-003** (Création équipage) : Structure du radeau
- **FEATURE-004** (Gestionnaires) : Modification des infos publiques
- **FEATURE-005** (Adhésion) : Bouton "Demander à rejoindre"
- **FEATURE-009** (Validation admin) : Statut participant/proposé

## Notes techniques

### Implémentation

#### Base de données

**Table des éditions :**
```elixir
create table :editions do
  add :year, :integer, null: false
  add :name, :string  # ex: "Tutto Blu 2026"
  add :is_current, :boolean, default: false
  add :start_date, :date
  add :end_date, :date

  timestamps()
end

create unique_index(:editions, [:year])
```

**Tables existantes + ajouts :**
```elixir
alter table :rafts do
  add :edition_id, references(:editions), null: false
  add :description_short, :string, limit: 150
  add :picture_url, :string
  add :previous_raft_id, references(:rafts)  # Lien vers radeau même nom édition précédente
end

# Nom unique PAR ÉDITION (pas globalement unique)
create unique_index(:rafts, [:name, :edition_id])
create index(:rafts, [:edition_id])

alter table :crews do
  add :edition_id, references(:editions), null: false
end

create index(:crews, [:edition_id])

create table :raft_links do
  add :raft_id, references(:rafts), null: false
  add :title, :string, null: false
  add :url, :string, null: false
  add :position, :integer, default: 0

  timestamps()
end

create index(:raft_links, [:raft_id, :position])
```

#### Routes
```elixir
scope "/", HoMonRadeauWeb do
  pipe_through :browser

  get "/", PageController, :index           # Liste des radeaux
  get "/radeaux", RaftController, :index    # Liste des radeaux
  get "/radeaux/:slug", RaftController, :show  # Page publique
end
```

#### Controller
```elixir
defmodule HoMonRadeauWeb.RaftController do
  def index(conn, params) do
    # Lister tous les radeaux, triés par validated puis par nom
    rafts =
      from(r in Raft,
        left_join: c in Crew, on: c.raft_id == r.id,
        left_join: cm in CrewMember, on: cm.crew_id == c.id,
        group_by: r.id,
        select: %{
          raft: r,
          member_count: count(cm.id)
        },
        order_by: [desc: r.validated, asc: r.name]
      )
      |> Repo.all()

    render(conn, "index.html", rafts: rafts)
  end

  def show(conn, %{"slug" => slug}) do
    raft = Events.get_raft_by_slug(slug)
    crew = Events.get_crew_by_raft(raft)

    # Récupérer les membres avec visibilité
    members = Events.get_public_crew_members(crew)

    # Compter les matelots secrets
    secret_count = Events.count_secret_members(crew)

    # Liens publics
    links = Events.get_raft_public_links(raft)

    current_user = conn.assigns[:current_user]
    user_crew = if current_user, do: Events.get_user_crew(current_user), else: nil

    render(conn, "show.html",
      raft: raft,
      members: members,
      secret_count: secret_count,
      links: links,
      user_crew: user_crew
    )
  end
end
```

#### Contexte
```elixir
defmodule HoMonRadeau.Events do
  def get_public_crew_members(crew) do
    from(cm in CrewMember,
      where: cm.crew_id == ^crew.id,
      join: u in User, on: u.id == cm.user_id,
      where: not is_nil(u.nickname),  # A un pseudo
      select: %{
        nickname: u.nickname,
        profile_picture: u.profile_picture_url,
        picture_public: u.profile_picture_public
      },
      order_by: u.nickname
    )
    |> Repo.all()
  end

  def count_secret_members(crew) do
    from(cm in CrewMember,
      where: cm.crew_id == ^crew.id,
      join: u in User, on: u.id == cm.user_id,
      where: is_nil(u.nickname) or u.profile_picture_public == false
    )
    |> Repo.aggregate(:count)
  end

  def get_raft_public_links(raft) do
    from(rl in RaftLink,
      where: rl.raft_id == ^raft.id,
      order_by: rl.position
    )
    |> Repo.all()
  end
end
```

### Sécurité
- Pas d'authentification requise pour consulter
- Vérifier les permissions pour modifier (gestionnaires uniquement)
- Validation des URLs pour les liens externes
- Sanitization de la description (pas de HTML malicieux)

### Performance
- Index sur `rafts.validated` pour trier rapidement
- Index sur `rafts.name` pour recherche
- Précharger les relations (crew, members) avec Ecto
- Cache de la liste des radeaux (optionnel)

### UX
- Photos de placeholder si pas de photo définie
- Message clair si aucun membre visible ("Cet équipage est en formation")
- Lien vers forum cliquable et visible
- Design responsive pour mobile
- Cards attrayantes sur la liste des radeaux
