# FEATURE-012 : CUF (Cotisation Urbaine Flottante)

## Description
La CUF (Cotisation Urbaine Flottante) est la cotisation pour participer à l'événement Tutto Blu. Elle est perçue par radeau : chaque équipage déclare un nombre de participants et paye la CUF pour ce nombre. La CUF sert également d'inscription nominative pour l'événement et définit le statut de "participant" des membres.

## Objectif
Gérer l'inscription et le paiement des participants via une cotisation par radeau. Suivre le nombre de participants validés pour respecter la limite de l'événement. Permettre une gestion flexible avec régularisation possible en cas de changements de composition d'équipage. Offrir une vue d'ensemble aux administrateurs sur le nombre de participants inscrits.

## Utilisateurs concernés
- **Capitaine** : Gère la CUF de son équipage (déclaration, suivi)
- **Membres de l'équipage** : Voient leur statut de participation
- **Administrateurs** : Valident les paiements CUF et suivent le nombre total de participants

## Comportement attendu

### Statuts des membres d'un équipage

Chaque membre peut avoir l'un des statuts suivants :

1. **Candidat** : Utilisateur non validé, en attente d'entretien avec l'équipe d'accueil
2. **Membre en attente de validation** : Utilisateur validé, membre de l'équipage, mais pas encore déclaré comme participant
3. **Participant** : CUF payée et validée pour cette personne
4. **Non participant** : Membre de l'équipage mais ne participera pas à l'événement (ex: aide à la construction uniquement)

### Rôle du capitaine

Le **capitaine est l'interface entre l'organisation et l'équipage** :
- C'est lui qui gère la CUF
- Il déclare le nombre de participants nominatifs
- Il s'occupe du paiement (hors app)
- Le capitaine est **obligatoirement un participant**
- **Exception temporaire** : Il peut être nommé capitaine avant d'être participant validé (arrive tard dans la timeline)

### Déclaration des participants

#### Par le capitaine uniquement
1. Accès à la section "CUF" sur la page privée du radeau
2. Sélection des membres qui seront participants (nominatif)
3. Calcul automatique : `nombre de participants × montant CUF`
4. Affichage du RIB pour paiement
5. Soumission de la déclaration

#### Changements après déclaration
- Changements possibles mais **nécessitent validation admin**
- Détails du processus de régularisation à préciser ultérieurement
- **Pour l'instant** : Le capitaine peut modifier la liste avant validation admin

### Validation par l'administrateur

#### Réception du paiement
1. Admin accède à l'interface de gestion CUF
2. Liste des déclarations en attente
3. Validation du paiement reçu
4. Les membres déclarés passent au statut "Participant"

#### Montant
- **Montant fixe par personne** (ex: 50€/personne)
- Sera fixé en mars environ
- Modifiable par les admins
- Une fois une CUF payée, le montant ne change plus (figé)

### Affichage sur la page de l'équipage

#### Pour tous les membres
```
Cotisation Urbaine Flottante (CUF)
-----------------------------------
Participants déclarés : 10
Membres actuels : 12
CUF restant à régler : 2

Statut : ⚠️ En attente de validation admin

Répartition :
- Candidats : 1 (seulement si il y en a)
- Membres en attente : 2
- Participants (CUF payée) : 10
- Non participants : 1
```

#### Nombre CUF restant à régler
- Peut être **positif** : membres de plus que participants déclarés
- Peut être **négatif** : désistement, membre qui quitte l'équipage
- Affiché clairement avec explication

### Règles de participation

#### Capitaine obligatoirement participant
- Le capitaine **doit être un participant** pour que l'équipage puisse participer
- Exception : peut être nommé capitaine avant validation CUF (timeline)

#### Membres non participants
- Peuvent aider à la construction en amont
- Ne participent pas à l'événement final
- Statut explicite "Non participant"

### Limite totale de participants

#### Nombre maximum
- Limite totale de participants pour l'événement (nombre pas encore connu)
- Sera affiché dans la **page admin** avec nombre de participants validés

#### Suivi en temps réel
```
Participants Tutto Blu
----------------------
Participants validés : 387 / [LIMITE]
En attente de validation : 45
```

## Règles métier

### CUF par radeau (pas par personne)
- Déclaration groupée par le capitaine
- Paiement groupé pour l'équipage
- Inscription nominative des participants

### Flexibilité temporaire
- Un radeau peut avoir temporairement plus ou moins de membres que le nombre de CUF payées
- **Mais** régularisation nécessaire car places limitées
- Membres sans CUF réglée ne pourront pas participer

### Montant figé
- Une fois la CUF validée, le montant ne change plus
- Même si le tarif change ultérieurement
- Protège les participants des variations de prix

### Changements de composition
- Possible avec validation admin
- Processus détaillé à définir plus tard
- Pour l'instant : modification possible avant validation

### Cotisation base flottante (hors CUF)
- **Cotisation séparée** pour les nuits passées sur la base lors de la construction
- **Non gérée dans l'app** pour le moment
- Rappel visible sur la page du radeau avec **placeholder**
- Montant basé sur le nombre de nuits

## Interface utilisateur

### Page privée du radeau - Section CUF (tous les membres)
```
Cotisation Urbaine Flottante (CUF)
-----------------------------------
La CUF est la cotisation pour participer à l'événement.
Elle est gérée collectivement par radeau.

Statut actuel
-------------
Participants déclarés : 10
CUF restant à régler : 2 (12 membres - 10 déclarés)

Statut : ⚠️ Déclaration en attente de validation

Répartition des membres
------------------------
👤 Candidats : 0
⏳ En attente de validation : 2
✓ Participants : 10
❌ Non participants : 0

[Gérer la CUF] (capitaine uniquement)

---
ℹ️ Cotisation à la base flottante
Une cotisation séparée sera demandée pour les nuits
passées sur la base lors de la construction.
Montant estimé : XXX € (selon nombre de nuits)
[Plus d'informations]
```

### Interface capitaine - Gestion CUF
```
Gérer la CUF - Radeau La Loutre

Montant CUF : 50 € / personne

Sélectionner les participants
------------------------------
☑ Alice (Gestionnaire, Capitaine)
☑ Bob (Gestionnaire, Lead construction)
☑ Charlie (Cuisine)
☑ Diana
☑ Enzo
☑ Fatima
☑ Gabriel
☑ Hélène
☑ Iris
☑ Jules
☐ Kevin (Non participant - aide construction uniquement)
☐ Laura (Candidat - en attente validation équipe accueil)

Participants sélectionnés : 10
Montant total : 500 €

Paiement
--------
RIB de l'association :
IBAN : FR76 XXXX XXXX XXXX XXXX XXXX XXX
BIC : XXXXXXXX
Libellé : CUF - Radeau La Loutre - 10 participants

⚠️ N'oubliez pas d'indiquer le nom de votre radeau et le nombre
de participants dans le libellé du virement.

[Valider la déclaration] [Annuler]
```

### Interface admin - Gestion CUF
```
Administration - CUF (Cotisation Urbaine Flottante)

Vue d'ensemble
--------------
Participants validés : 387
En attente de validation : 45
Limite événement : [À définir]

Montant CUF : 50 € / personne
[Modifier le montant]

Déclarations en attente
-----------------------
| Radeau      | Participants | Montant | Date déclaration | Actions            |
|-------------|--------------|---------|------------------|-------------------|
| La Loutre   | 10           | 500€    | 10/01/2025       | [Valider paiement] [Voir détails] |
| Le Kraken   | 8            | 400€    | 12/01/2025       | [Valider paiement] [Voir détails] |

Déclarations validées
---------------------
| Radeau      | Participants | Montant | Date validation | Validé par |
|-------------|--------------|---------|-----------------|------------|
| L'Albatros  | 15           | 750€    | 05/01/2025      | Admin1     |
| Le Phénix   | 12           | 600€    | 08/01/2025      | Admin2     |

Statistiques
------------
Total CUF perçue : 19.350 €
Moyenne participants / radeau : 11,5
```

### Modal validation paiement CUF
```
┌──────────────────────────────────────────┐
│ Valider le paiement CUF                  │
│                                          │
│ Radeau : La Loutre                       │
│ Participants déclarés : 10               │
│   - Alice                                │
│   - Bob                                  │
│   - Charlie                              │
│   - ... (voir liste complète)            │
│                                          │
│ Montant : 500 €                          │
│                                          │
│ Les 10 membres sélectionnés passeront    │
│ au statut "Participant".                 │
│                                          │
│ Confirmez-vous avoir reçu le paiement ? │
│                                          │
│ [Confirmer] [Annuler]                    │
└──────────────────────────────────────────┘
```

## Dépendances
- **FEATURE-003** (Création équipage) : Radeau et équipage
- **FEATURE-006** (Rôles) : Le capitaine gère la CUF
- **FEATURE-008** (Pages privées) : Affichage section CUF

## Notes techniques

### Implémentation

#### Base de données
```elixir
create table :cuf_declarations do
  add :crew_id, references(:crews), null: false
  add :participant_count, :integer, null: false
  add :unit_price, :decimal, precision: 10, scale: 2, null: false
  add :total_amount, :decimal, precision: 10, scale: 2, null: false
  add :status, :string, default: "pending", null: false  # pending, validated
  add :validated_at, :datetime
  add :validated_by_id, references(:users)

  timestamps()
end

create index(:cuf_declarations, [:crew_id])
create index(:cuf_declarations, [:status])

# Ajouter aux crew_members
alter table :crew_members do
  add :participation_status, :string, default: "pending"
  # pending, participant, non_participant
end

create table :cuf_settings do
  add :unit_price, :decimal, precision: 10, scale: 2
  add :total_limit, :integer  # Limite totale de participants
  add :rib_iban, :string
  add :rib_bic, :string

  timestamps()
end
```

#### Schéma Elixir
```elixir
defmodule HoMonRadeau.CUF.Declaration do
  schema "cuf_declarations" do
    belongs_to :crew, Crew
    field :participant_count, :integer
    field :unit_price, :decimal
    field :total_amount, :decimal
    field :status, :string, default: "pending"
    field :validated_at, :utc_datetime
    belongs_to :validated_by, User

    # Liste des user_ids participants
    field :participant_ids, {:array, :integer}, virtual: true

    timestamps()
  end

  def changeset(declaration, attrs) do
    declaration
    |> cast(attrs, [:participant_count])
    |> validate_required([:participant_count])
    |> validate_number(:participant_count, greater_than: 0)
    |> calculate_amounts()
  end

  defp calculate_amounts(changeset) do
    case get_change(changeset, :participant_count) do
      nil -> changeset
      count ->
        unit_price = CUF.get_current_unit_price()
        total = Decimal.mult(Decimal.new(count), unit_price)

        changeset
        |> put_change(:unit_price, unit_price)
        |> put_change(:total_amount, total)
    end
  end
end
```

#### Contexte
```elixir
defmodule HoMonRadeau.CUF do
  def create_declaration(crew, participant_user_ids) do
    participant_count = length(participant_user_ids)

    Multi.new()
    |> Multi.insert(:declaration, %Declaration{crew_id: crew.id}
      |> Declaration.changeset(%{participant_count: participant_count})
    )
    |> Multi.run(:update_members, fn _repo, %{declaration: _decl} ->
      # Marquer les membres comme participants
      from(cm in CrewMember,
        where: cm.crew_id == ^crew.id and cm.user_id in ^participant_user_ids
      )
      |> Repo.update_all(set: [participation_status: "pending_validation"])

      {:ok, :updated}
    end)
    |> Repo.transaction()
  end

  def validate_declaration(declaration, admin_user) do
    Multi.new()
    |> Multi.update(:declaration, Declaration.changeset(declaration, %{
      status: "validated",
      validated_at: DateTime.utc_now(),
      validated_by_id: admin_user.id
    }))
    |> Multi.run(:finalize_participants, fn _repo, %{declaration: _decl} ->
      # Passer les membres pending_validation à participant
      from(cm in CrewMember,
        where: cm.crew_id == ^declaration.crew_id
          and cm.participation_status == "pending_validation"
      )
      |> Repo.update_all(set: [participation_status: "participant"])

      {:ok, :finalized}
    end)
    |> Repo.transaction()
  end

  def get_crew_cuf_summary(crew) do
    declaration = get_current_declaration(crew)
    members = Events.get_crew_members_full(crew)

    candidate_count = Enum.count(members, fn m -> !m.user.validated end)
    pending_count = Enum.count(members, fn m ->
      m.user.validated and m.participation_status == "pending"
    end)
    participant_count = Enum.count(members, fn m ->
      m.participation_status == "participant"
    end)
    non_participant_count = Enum.count(members, fn m ->
      m.participation_status == "non_participant"
    end)

    declared_count = if declaration, do: declaration.participant_count, else: 0
    remaining = length(members) - declared_count

    %{
      declaration: declaration,
      declared_count: declared_count,
      current_member_count: length(members),
      remaining_cuf: remaining,
      candidate_count: candidate_count,
      pending_count: pending_count,
      participant_count: participant_count,
      non_participant_count: non_participant_count
    }
  end

  def get_total_participants_stats() do
    validated = from(cm in CrewMember,
      where: cm.participation_status == "participant"
    ) |> Repo.aggregate(:count)

    pending = from(cm in CrewMember,
      where: cm.participation_status == "pending_validation"
    ) |> Repo.aggregate(:count)

    settings = Repo.one(CUFSettings)
    limit = if settings, do: settings.total_limit, else: nil

    %{
      validated: validated,
      pending: pending,
      limit: limit
    }
  end

  def get_current_unit_price() do
    settings = Repo.one(CUFSettings) || %CUFSettings{unit_price: Decimal.new(50)}
    settings.unit_price
  end
end
```

#### Routes
```elixir
scope "/", HoMonRadeauWeb do
  pipe_through [:browser, :require_authenticated_user, :require_captain]

  post "/radeaux/:id/cuf", CUFController, :create
  put "/radeaux/:id/cuf/:declaration_id", CUFController, :update
end

scope "/admin", HoMonRadeauWeb.Admin do
  pipe_through [:browser, :require_authenticated_user, :require_admin]

  get "/cuf", CUFAdminController, :index
  post "/cuf/:declaration_id/valider", CUFAdminController, :validate
  get "/cuf/config", CUFConfigController, :edit
  put "/cuf/config", CUFConfigController, :update
end
```

#### Permissions
```elixir
defmodule HoMonRadeauWeb.Plugs.RequireCaptain do
  def init(opts), do: opts

  def call(conn, _opts) do
    crew_id = conn.params["id"]
    user = conn.assigns.current_user

    if Events.is_captain?(crew_id, user) do
      conn
    else
      conn
      |> put_flash(:error, "Seul le capitaine peut gérer la CUF.")
      |> redirect(to: Routes.crew_path(conn, :show_private, crew_id))
      |> halt()
    end
  end
end
```

### Sécurité
- Seul le capitaine peut déclarer les participants
- Seuls les admins peuvent valider les paiements
- Logger toutes les déclarations et validations
- Empêcher la modification après validation (sans processus de régularisation)
- Protection CSRF sur tous les formulaires

### Performance
- Index sur `cuf_declarations.status` pour filtrer
- Index sur `crew_members.participation_status` pour compter
- Utiliser Decimal pour les calculs monétaires

### UX
- Affichage clair du nombre CUF restant à régler
- Explication si négatif (désistement)
- Sélection visuelle des participants (checkboxes)
- Calcul automatique du montant
- RIB clairement visible et copiable
- Placeholder visible pour cotisation base flottante
- Statistiques visuelles pour les admins
- Badge "Participant" visible sur le profil dans l'équipage
