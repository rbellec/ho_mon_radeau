# FEATURE-010 : Équipes transverses

## Description
Les équipes transverses sont des groupes fonctionnels qui opèrent à travers tous les radeaux pour assurer des services centralisés : équipe d'accueil des nouveaux, équipe SAFE, équipe bidons, sécurité, médecine, etc. Ces équipes ne sont pas des radeaux mais fonctionnent de manière similaire en termes de gestion des membres.

## Objectif
Organiser les fonctions support de l'événement en permettant aux bénévoles de s'inscrire dans des équipes transverses. Fournir un espace de coordination pour ces équipes tout en les distinguant clairement des équipages de radeaux. Permettre aux membres de ces équipes d'avoir des droits spécifiques dans l'application (ex: équipe accueil valide les nouveaux, équipe bidons valide les paiements).

## Utilisateurs concernés
- **Bénévoles** : Peuvent rejoindre une ou plusieurs équipes transverses
- **Coordinateurs d'équipes** : Gèrent leur équipe transverse
- **Administrateurs** : Créent et gèrent les équipes transverses
- **Membres des radeaux** : Peuvent également être membres d'équipes transverses

## Comportement attendu

### Types d'équipes transverses

Équipes identifiées :
- **Accueil des nouveaux** : Validation des nouveaux participants
- **SAFE** : Consentement, sécurité émotionnelle
- **Bidons** : Gestion et validation des paiements de bidons
- **Sécurité** : Sécurité physique sur l'événement
- **Médecine** : Soins et premiers secours
- _(Autres équipes à ajouter selon les besoins)_

### Différences avec les radeaux

#### Similitudes
- Ont des membres
- Ont des coordinateurs (équivalent gestionnaires)
- Peuvent avoir une page privée de coordination
- Les membres peuvent se déclarer sur des rôles

#### Différences
- **Pas de radeau physique** associé
- **Pas listées dans la liste des radeaux**
- **Pas de page publique** (ou très minimale)
- **Visibilité restreinte** : membres + admins uniquement
- **Pas de CUF** (car ce ne sont pas des participants au même titre)
- **Pas de bidons** (pas de construction)
- **Multi-appartenance** : un utilisateur peut être membre de son radeau ET d'une ou plusieurs équipes transverses

### Création d'équipes transverses

#### Par les administrateurs uniquement
1. Page admin "Équipes transverses"
2. Bouton "Créer une équipe transverse"
3. Formulaire :
   - Nom de l'équipe (obligatoire)
   - Description
   - Type/fonction (liste déroulante)
   - Coordinateur initial (optionnel)

#### Types de permissions spéciales
Certaines équipes ont des droits particuliers dans l'app :
- **Accueil des nouveaux** : Validation des utilisateurs (FEATURE-002)
- **Bidons** : Validation des paiements de bidons (FEATURE-011)
- **Admins** : Tous les droits

### Adhésion aux équipes transverses

#### Pour un utilisateur
- **Pas de formulaire d'adhésion dans l'application**
- **Pas de bouton "Rejoindre"**
- Le recrutement se fait par **discussions externes** (WhatsApp, forum, en personne)
- Une fois le recrutement validé en externe, un coordinateur ajoute le membre dans l'app

#### Gestion par le coordinateur
- Ajouter des membres directement (après validation externe)
- Retirer des membres
- Nommer d'autres coordinateurs
- Pas de système de demandes d'adhésion dans l'app

### Page privée d'équipe transverse

Structure similaire aux pages privées de radeau mais adaptée :
```
ÉQUIPE [NOM]
Type : [Accueil / SAFE / Bidons / etc.]

Description
-----------
[Description de la mission de l'équipe]

Coordinateurs (2)
-----------------
[Liste des coordinateurs]

Membres (15)
------------
[Liste des membres]

Outils
------
💬 Canal WhatsApp
📁 Documents partagés
```

### Visibilité

#### Pour les membres de l'équipe
- Voient la page privée de leur équipe
- Voient la liste des autres membres avec coordonnées
- Accès aux outils de coordination

#### Pour les non-membres
- **Ne voient pas les équipes transverses** dans la navigation générale
- Exception : les équipes transverses peuvent être mentionnées sur certaines pages (ex: "Contactez l'équipe SAFE")

#### Pour les administrateurs
- Voient toutes les équipes transverses
- Peuvent créer/modifier/supprimer des équipes
- Peuvent ajouter/retirer des membres

## Règles métier

### Multi-appartenance
- Un utilisateur peut être membre de **son radeau + une ou plusieurs équipes transverses**
- Pas de limite au nombre d'équipes transverses rejointes

### Distinction radeau/équipe transverse
- **Radeaux** : Visibles publiquement, participent à l'événement, ont un radeau physique
- **Équipes transverses** : Visibles uniquement par membres + admins, fonctions support, pas de radeau

### Permissions spéciales
Certaines équipes ont des droits dans l'app :
- Type stocké en base : `welcome_team`, `safe_team`, `drums_team`, `security`, `medical`, `other`
- Vérification du type avant d'accorder des permissions spéciales

### Coordinateurs
- Gestion identique aux gestionnaires de radeau
- Peuvent nommer d'autres coordinateurs
- Peuvent ajouter/retirer des membres
- Pas de hiérarchie entre coordinateurs

### Participation à l'événement
- Être membre d'une équipe transverse **ne suffit pas** pour participer à l'événement
- Il faut également être membre d'un radeau (ou avoir un statut spécial admin/orga)

## Interface utilisateur

### Page admin - Équipes transverses
```
Administration - Équipes transverses

[+ Créer une équipe transverse]

Liste des équipes (6)
---------------------
| Nom                    | Type          | Membres | Coordinateurs | Actions |
|------------------------|---------------|---------|---------------|---------|
| Accueil des nouveaux   | welcome_team  | 8       | 2             | [Voir] [Modifier] |
| SAFE                   | safe_team     | 12      | 3             | [Voir] [Modifier] |
| Bidons                 | drums_team    | 5       | 1             | [Voir] [Modifier] |
| Sécurité               | security      | 10      | 2             | [Voir] [Modifier] |
| Médecine               | medical       | 6       | 2             | [Voir] [Modifier] |
```

### Formulaire de création (admin)
```
Créer une équipe transverse

Nom de l'équipe *
[Accueil des nouveaux_____________]

Type/Fonction *
[welcome_team ▼]
  - welcome_team (Accueil des nouveaux)
  - safe_team (SAFE)
  - drums_team (Bidons)
  - security (Sécurité)
  - medical (Médecine)
  - other (Autre)

Description
[_____________________________]
[_____________________________]

Coordinateur initial (optionnel)
[Rechercher un utilisateur...]

[Créer] [Annuler]
```

### Page "Équipes transverses" (utilisateur)
```
Équipes transverses - Tutto Blu

Les équipes transverses assurent les fonctions support de l'événement.
Le recrutement se fait par discussions directes avec les coordinateurs.

Mes équipes
-----------
✓ SAFE - 12 membres
  Coordinateurs : Alice, Bob, Charlie
  [Voir la page de l'équipe]

Autres équipes
--------------
Accueil des nouveaux - 8 membres
"Rencontre et validation des nouveaux participants"
Coordinateurs : Diana, Enzo

Bidons - 5 membres
"Gestion de la location des bidons"
Coordinateurs : Fatima

Sécurité - 10 membres
"Assure la sécurité physique sur l'événement"
Coordinateurs : Gabriel, Hélène

💬 Pour rejoindre une équipe, contactez directement les coordinateurs
   via le forum ou WhatsApp.
```

### Page privée d'équipe transverse
```
ÉQUIPE SAFE
Type : Équipe transverse

Description
-----------
L'équipe SAFE veille au respect du consentement et au bien-être
émotionnel de tous les participants de Tutto Blu.

Coordinateurs (3)
-----------------
[Photo] Alice - alice@example.com
[Photo] Bob - bob@example.com
[Photo] Charlie - charlie@example.com

Membres (12)
------------
[Liste des membres avec coordonnées]

Outils
------
💬 Groupe WhatsApp
→ https://chat.whatsapp.com/...

📁 Documents partagés
→ https://drive.google.com/...
```

## Dépendances
- **FEATURE-001** (Inscription) : Base utilisateur
- **FEATURE-002** (Validation nouveaux) : Équipe accueil valide les nouveaux
- **FEATURE-011** (Bidons) : Équipe bidons valide les paiements

## Notes techniques

### Implémentation

#### Base de données
Réutiliser la structure crew/crew_members avec un flag :
```elixir
alter table :crews do
  add :is_transverse, :boolean, default: false
  add :transverse_type, :string
  add :description, :text
end

create index(:crews, [:is_transverse])
create index(:crews, [:transverse_type])
```

**Valeurs de transverse_type :**
- `welcome_team`
- `safe_team`
- `drums_team`
- `security`
- `medical`
- `other`

#### Schéma Elixir
```elixir
defmodule HoMonRadeau.Events.Crew do
  schema "crews" do
    belongs_to :raft, Raft  # Null si équipe transverse
    field :is_transverse, :boolean, default: false
    field :transverse_type, :string
    field :name, :string  # Nom de l'équipe transverse
    field :description, :text

    has_many :members, CrewMember
  end
end
```

#### Routes
```elixir
scope "/", HoMonRadeauWeb do
  pipe_through [:browser, :require_authenticated_user]

  get "/equipes-transverses", TransverseTeamController, :index
  get "/equipes-transverses/:id", TransverseTeamController, :show
  # Pas de route join - l'ajout se fait par les coordinateurs
end

scope "/admin", HoMonRadeauWeb.Admin do
  pipe_through [:browser, :require_authenticated_user, :require_admin]

  resources "/equipes-transverses", TransverseTeamController
end

scope "/equipes-transverses/:id", HoMonRadeauWeb do
  pipe_through [:browser, :require_authenticated_user, :require_coordinator]

  post "/membres", TransverseTeamController, :add_member
  delete "/membres/:member_id", TransverseTeamController, :remove_member
end
```

#### Contexte
```elixir
defmodule HoMonRadeau.Events do
  def list_transverse_teams() do
    from(c in Crew,
      where: c.is_transverse == true,
      order_by: c.name
    )
    |> Repo.all()
  end

  def get_user_transverse_teams(user) do
    from(c in Crew,
      join: cm in CrewMember, on: cm.crew_id == c.id,
      where: cm.user_id == ^user.id and c.is_transverse == true
    )
    |> Repo.all()
  end

  def create_transverse_team(attrs) do
    %Crew{}
    |> Crew.changeset(Map.put(attrs, :is_transverse, true))
    |> Repo.insert()
  end

  def is_member_of_team?(user, team_type) do
    from(cm in CrewMember,
      join: c in Crew, on: c.id == cm.crew_id,
      where: cm.user_id == ^user.id and c.transverse_type == ^team_type
    )
    |> Repo.exists?()
  end
end
```

#### Permissions
```elixir
defmodule HoMonRadeauWeb.Plugs.RequireWelcomeTeam do
  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns.current_user

    if Events.is_member_of_team?(user, "welcome_team") or user.is_admin do
      conn
    else
      conn
      |> put_flash(:error, "Accès réservé à l'équipe d'accueil.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end
end
```

### Sécurité
- Seuls les admins peuvent créer/modifier des équipes transverses
- Vérifier les permissions avant d'afficher les pages privées
- Vérifier le type d'équipe avant d'accorder des permissions spéciales
- Logger les adhésions/retraits

### Performance
- Index sur `crews.is_transverse` pour filtrer rapidement
- Index sur `crews.transverse_type` pour vérifier les permissions
- Précharger les membres dans les listes

### UX
- Distinction visuelle claire entre radeaux et équipes transverses
- Badge "Équipe transverse" sur les pages
- Navigation séparée (pas dans la même liste que les radeaux)
- Indication du nombre de membres dans chaque équipe
- Possibilité de rejoindre facilement plusieurs équipes
