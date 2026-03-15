# FEATURE-006 : Rôles dans l'équipage

## Description
Permet aux membres d'un équipage de se déclarer sur différents rôles nécessaires au bon fonctionnement du radeau : capitaine, lead construction, cuisine, interlocuteur SAFE. Certains rôles comme capitaine et gestionnaire ne peuvent pas être auto-attribués.

## Objectif
Structurer l'organisation interne des équipages en clarifiant les responsabilités de chacun. Identifier les compétences et motivations des membres pour faciliter la répartition des tâches. Certains rôles seront obligatoires pour la validation de participation (feature ultérieure).

## Utilisateurs concernés
- **Membres de l'équipage** : Peuvent se déclarer sur des rôles (sauf capitaine et gestionnaire)
- **Gestionnaires** : Peuvent attribuer le rôle de capitaine
- **Capitaine** : Rôle spécifique avec responsabilités particulières (notamment CUF)
- **Administrateurs** : Peuvent voir et modifier tous les rôles

## Comportement attendu

### Rôles disponibles

#### Rôles standards (auto-déclaration possible)
- **Lead construction** : Responsable de la construction du radeau
- **Cuisine** : Responsable de l'organisation des repas
- **Interlocuteur SAFE** : Point de contact pour les questions de consentement et sécurité
- _(Autres rôles à définir ultérieurement)_

#### Rôles spéciaux (attribution par gestionnaire)
- **Capitaine** : Interface entre l'organisation et l'équipage
  - **Un seul capitaine par radeau**
  - Gère la CUF (FEATURE-012)
  - Obligatoirement participant à l'événement
- **Gestionnaire** : Gestion de l'équipage (voir FEATURE-004)

### Auto-déclaration de rôle

#### Pour un membre
1. Accède à la page privée du radeau
2. Section "Mon profil dans l'équipage"
3. Liste des rôles disponibles avec checkboxes
4. Coche les rôles qui l'intéressent
5. Sauvegarde → rôles visibles immédiatement

#### Règles d'auto-déclaration
- **Un membre peut avoir plusieurs rôles** (sauf capitaine)
- **Pas de validation requise** pour les rôles standards
- Les rôles sont **visibles de tous les membres** de l'équipage

### Attribution du rôle capitaine

#### Par un gestionnaire
1. Accède à la liste des membres
2. Menu déroulant "Rôles" à côté d'un membre
3. Option "Nommer capitaine"
4. Confirmation : "Voulez-vous nommer [PSEUDO] comme capitaine ?"
5. Si déjà un capitaine : "Attention : [AUTRE_PSEUDO] est déjà capitaine. Cette action lui retirera ce rôle."

#### Règles spécifiques au capitaine
- **Un seul capitaine par radeau**
- Nommer un nouveau capitaine **retire automatiquement le rôle** à l'ancien
- Le capitaine **doit être un participant** (CUF payée) pour que l'équipage puisse participer
- **Exception temporaire :** Un membre peut être nommé capitaine avant d'être participant validé (timeline)

### Affichage des rôles

#### Page privée du radeau
```
Membres de l'équipage
---------------------
[Photo] Pseudo1 (Gestionnaire, Capitaine) ★
[Photo] Pseudo2 (Gestionnaire, Lead construction)
[Photo] Pseudo3 (Cuisine, Interlocuteur SAFE)
[Photo] Pseudo4 (pas de rôle)

Rôles à pourvoir
----------------
⚠️ Capitaine : Pseudo1
✓ Lead construction : Pseudo2
✓ Cuisine : Pseudo3
✓ Interlocuteur SAFE : Pseudo3
```

#### Page publique du radeau
- Les rôles ne sont **pas affichés publiquement** (y compris le capitaine)
- Seule la liste des membres avec pseudos/photos

#### Page admin - Liste des radeaux
- Le **capitaine est affiché** dans la liste des radeaux pour les administrateurs
- Permet aux admins de voir rapidement qui est l'interlocuteur de chaque radeau

## Règles métier

### Multiplicité des rôles
- **Un membre peut avoir plusieurs rôles** standards
- **Capitaine : un seul par radeau** (exclusivité)
- **Gestionnaire : plusieurs possibles** (voir FEATURE-004)

### Auto-déclaration vs Attribution
- **Auto-déclaration :** Lead construction, Cuisine, Interlocuteur SAFE
- **Attribution par gestionnaire :** Capitaine, Gestionnaire

### Rôles obligatoires (validation participation)
- Liste des rôles obligatoires à définir ultérieurement (FEATURE validation participation)
- Pour l'instant : identifier clairement les rôles manquants sur la page privée

### Capitaine et participation
- Le capitaine est **obligatoirement un participant**
- Mais peut être nommé capitaine **avant d'être participant validé** (CUF payée)
- Restriction d'accès aux fonctions capitaine tant que pas participant ? **À clarifier**

## Interface utilisateur

### Section "Mon profil dans l'équipage" (membre)
```
Mon profil dans l'équipage
--------------------------
Mes rôles :
☐ Lead construction
☑ Cuisine
☐ Interlocuteur SAFE

[Enregistrer]

Note : Le rôle de capitaine est attribué par les gestionnaires.
```

### Attribution capitaine (gestionnaire)
```
Membres
-------
[Photo] Pseudo1
Rôles : Cuisine
[▼ Actions]
  - Nommer capitaine
  - Retirer de l'équipage
  - Nommer gestionnaire
```

**Confirmation nommer capitaine :**
```
Nommer capitaine

Voulez-vous nommer [PSEUDO] comme capitaine de l'équipage ?

Le capitaine est l'interface entre l'organisation et l'équipage.
Il/Elle devra notamment gérer la CUF (cotisation).

[Attention : Pseudo2 est actuellement capitaine. Cette action lui retirera ce rôle.]

[Confirmer] [Annuler]
```

### Vue d'ensemble des rôles (gestionnaire)
```
État des rôles
--------------
✓ Capitaine : Pseudo1
✓ Lead construction : Pseudo2
⚠️ Cuisine : personne
✓ Interlocuteur SAFE : Pseudo3
✓ Gestionnaires : Pseudo1, Pseudo4 (2)

[Gérer les rôles]
```

## Dépendances
- **FEATURE-003** (Création équipage) : Structure de base
- **FEATURE-004** (Gestionnaires) : Permissions pour attribuer capitaine
- **FEATURE-005** (Adhésion) : Membres de l'équipage
- **FEATURE-012** (CUF) : Le capitaine gère la CUF
- **FEATURE validation participation** (ultérieure) : Rôles obligatoires

## Notes techniques

### Implémentation

#### Base de données
Utiliser la table `crew_members` existante :
```elixir
alter table :crew_members do
  add :roles, {:array, :string}, default: []
  add :is_captain, :boolean, default: false
end

# Index pour rechercher le capitaine rapidement
create index(:crew_members, [:crew_id, :is_captain])
```

**Valeurs possibles pour roles :**
- "lead_construction"
- "cook"
- "safe_liaison"
- _(autres à ajouter ultérieurement)_

#### Schéma Elixir
```elixir
defmodule HoMonRadeau.Events.CrewMember do
  schema "crew_members" do
    belongs_to :crew, Crew
    belongs_to :user, User
    field :is_manager, :boolean, default: false
    field :is_captain, :boolean, default: false
    field :roles, {:array, :string}, default: []
    # ...
  end

  @available_roles ~w(lead_construction cook safe_liaison)

  def changeset(crew_member, attrs) do
    crew_member
    |> cast(attrs, [:roles, :is_captain, :is_manager])
    |> validate_subset(:roles, @available_roles)
  end
end
```

#### Contexte Elixir
```elixir
defmodule HoMonRadeau.Events do
  def update_member_roles(crew_member, roles) do
    crew_member
    |> CrewMember.changeset(%{roles: roles})
    |> Repo.update()
  end

  def assign_captain(crew, user_id) do
    Multi.new()
    # Retirer le rôle capitaine à l'ancien capitaine (si existant)
    |> Multi.run(:remove_old_captain, fn _repo, _ ->
      from(cm in CrewMember,
        where: cm.crew_id == ^crew.id and cm.is_captain == true
      )
      |> Repo.update_all(set: [is_captain: false])

      {:ok, :removed}
    end)
    # Attribuer le rôle capitaine au nouveau
    |> Multi.update(:new_captain, fn _ ->
      crew_member = get_crew_member(crew.id, user_id)

      CrewMember.changeset(crew_member, %{is_captain: true})
    end)
    |> Repo.transaction()
  end

  def get_captain(crew) do
    from(cm in CrewMember,
      where: cm.crew_id == ^crew.id and cm.is_captain == true,
      preload: [:user]
    )
    |> Repo.one()
  end

  def get_missing_roles(crew) do
    required_roles = ["lead_construction", "cook", "safe_liaison"]

    assigned_roles =
      from(cm in CrewMember,
        where: cm.crew_id == ^crew.id,
        select: cm.roles
      )
      |> Repo.all()
      |> List.flatten()
      |> Enum.uniq()

    required_roles -- assigned_roles
  end
end
```

#### Permissions
- Modifier ses propres rôles : membre de l'équipage
- Attribuer capitaine : gestionnaire uniquement
- Voir tous les rôles : membre de l'équipage

### Sécurité
- Vérifier que le membre modifie uniquement ses propres rôles
- Vérifier que seul un gestionnaire peut attribuer le capitaine
- Logger les changements de capitaine
- Constraint : un seul capitaine par crew

### Performance
- Index sur `crew_members.is_captain` pour retrouver rapidement le capitaine
- Utiliser array PostgreSQL pour les rôles multiples

### UX
- Interface simple avec checkboxes pour l'auto-déclaration
- Confirmation claire lors du changement de capitaine
- Badge "Capitaine ★" visible dans la liste des membres
- Alerte visuelle pour les rôles manquants
- Tooltip expliquant chaque rôle au survol
