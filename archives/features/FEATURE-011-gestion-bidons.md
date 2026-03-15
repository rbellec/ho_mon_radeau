# FEATURE-011 : Gestion des bidons

## Description
Les bidons sont la seule ressource centralisée de l'événement Tutto Blu. Ils permettent aux radeaux de flotter et sont loués par les équipages. Cette feature gère le processus complet : demande de bidons par les équipages, calcul automatique du montant, paiement hors app, et validation du paiement par l'équipe bidons.

## Objectif
Centraliser et suivre les demandes de bidons pour tous les radeaux. Faciliter la gestion logistique pour l'équipe bidons en offrant une vue d'ensemble des demandes et des paiements. Permettre aux équipages de connaître clairement le montant à payer et le statut de leur demande.

## Utilisateurs concernés
- **Membres d'équipage** : Peuvent faire ou modifier une demande de bidons
- **Équipe bidons** : Centralise les demandes, valide les paiements
- **Administrateurs** : Peuvent modifier le tarif des bidons et valider les paiements
- **Gestionnaires d'équipage** : Peuvent gérer les demandes de leur radeau

## Comportement attendu

### Demande de bidons

#### Qui peut faire une demande ?
- **Tous les membres de l'équipage** peuvent faire ou modifier une demande
- Une seule demande active par radeau
- Historique des demandes validées (demandes additionnelles possibles)

#### Formulaire de demande
1. Membre accède à la section "Bidons" sur la page privée du radeau
2. Formulaire simple :
   - **Nombre de bidons** (obligatoire)
   - Note/commentaire (optionnel)
3. Calcul automatique du montant : `nombre × tarif par bidon`
4. Affichage du RIB pour le paiement
5. Soumission de la demande

#### Statuts d'une demande
- **Aucune demande** : Pas encore de demande faite
- **Demande en attente** : Demande faite, paiement non validé
- **Paiement validé** : Équipe bidons a validé la réception du paiement

### Modification d'une demande

#### Avant validation de paiement
Modification possible à tout moment par :
- N'importe quel membre de l'équipage
- Membre de l'équipe bidons
- Administrateur

#### Après validation de paiement
- **Pas de modification directe**
- Nécessite une **demande additionnelle** (nouvelle demande)
- L'ancienne demande est conservée dans l'historique
- Pas de remise si besoin de moins de bidons (option en tête, discutée plus tard)

### Validation du paiement

#### Par l'équipe bidons ou admin
1. Accès à l'interface de gestion des bidons
2. Liste de toutes les demandes avec leur statut
3. Bouton "Valider le paiement" pour les demandes en attente
4. Confirmation et validation
5. Le montant de la demande est **figé** (ne change plus même si le tarif change)

### Historique des demandes

Pour chaque radeau, affichage de l'historique :
```
Demande #1 - 80 bidons - 400€ - Payé le 15/01/2025 ✓
Demande #2 - 20 bidons - 100€ - En attente ⏳

Total : 100 bidons - 500€
```

### Tarif des bidons

#### Gestion par les admins
- Tarif fixe par bidon (ex: 5€/bidon)
- Modifiable uniquement par les administrateurs
- Changement : soit en BDD, soit via interface admin
- **Important** : Une fois une demande payée, le montant ne change plus

#### Affichage du tarif
- Visible sur la page de demande de bidons
- Visible sur l'interface de l'équipe bidons
- Calculé automatiquement pour chaque demande

### Radeau sans bidons (0 bidon)

Certains radeaux utilisent d'autres modes de flottaison :
- Autorisé
- Demande de 0 bidon possible
- Affichage clair : "0 bidon - Mode de flottaison alternatif"

### Interface équipe bidons

Page de gestion centralisée :
- Liste de tous les radeaux avec leurs demandes
- Filtres : En attente / Validé / Aucune demande
- Actions : Valider paiement, Modifier demande
- Statistiques : Total de bidons demandés, Total payé, Total en attente

## Règles métier

### Demandes et modifications
- **Une seule demande active** par radeau à un instant T
- **Modification libre** avant validation de paiement
- **Demande additionnelle** après validation (nouvelle demande)

### Paiement hors application
- Le paiement se fait **hors application** (virement, liquide, etc.)
- L'application sert uniquement à :
  - Enregistrer les demandes
  - Calculer les montants
  - Afficher le RIB
  - Valider que le paiement a été reçu

### Montant figé
- Une fois le paiement validé, le montant ne change plus
- Même si le tarif par bidon change ultérieurement
- Protège les équipages des variations de prix

### Gestion du stock
- Stock limité (réalité de l'événement)
- Bidons avec défauts découverts au début de l'événement
- **Gestion du stock = feature ultérieure** (à discuter plus tard)
- Pour l'instant : gestion des limites et priorités en discutant directement (pas par l'app)

### Permissions de validation
- **Équipe bidons** : Peut valider les paiements
- **Administrateurs** : Peuvent valider les paiements
- **Gestionnaires d'équipage** : Ne peuvent pas valider leurs propres paiements

## Interface utilisateur

### Page privée du radeau - Section bidons
```
Bidons
------
Demande actuelle : 80 bidons
Montant : 400 € (5€/bidon)
Statut : ✓ Paiement validé le 15/01/2025

Demande additionnelle : 20 bidons
Montant : 100 € (5€/bidon)
Statut : ⏳ En attente de paiement

Total : 100 bidons - 500€

[Faire une nouvelle demande]

Historique
----------
#1 - 80 bidons - 400€ - Validé le 15/01/2025
#2 - 20 bidons - 100€ - En attente

---
💡 Pour d'autres modes de flottaison, demandez 0 bidon.
```

### Formulaire de demande
```
Demander des bidons

Nombre de bidons *
[___80___]

Tarif actuel : 5 € / bidon
Montant total : 400 €

Note (optionnel)
[Nous avons besoin de bidons supplémentaires pour...]

---
Paiement

RIB de l'association :
IBAN : FR76 XXXX XXXX XXXX XXXX XXXX XXX
BIC : XXXXXXXX
Libellé : Bidons - Radeau [NOM]

⚠️ N'oubliez pas d'indiquer le nom de votre radeau dans le libellé du virement.

[Envoyer la demande] [Annuler]
```

### Interface équipe bidons
```
Gestion des bidons

Statistiques
------------
Total demandé : 1.240 bidons
Total validé : 980 bidons (49.000€)
En attente : 260 bidons (13.000€)

Filtres
[Tous ▼] [En attente] [Validés] [Aucune demande]

Liste des demandes
------------------
| Radeau       | Bidons | Montant | Statut      | Date demande | Actions            |
|--------------|--------|---------|-------------|--------------|-------------------|
| La Loutre    | 80     | 400€    | En attente  | 10/01/2025   | [Valider paiement] [Modifier] |
| Le Kraken    | 60     | 300€    | Validé ✓    | 05/01/2025   | [Voir] |
| L'Albatros   | 0      | 0€      | -           | -            | Pas de demande |
| Le Phénix    | 120    | 600€    | Validé ✓    | 08/01/2025   | [Voir] |
```

### Modal validation paiement
```
┌──────────────────────────────────────────┐
│ Valider le paiement                      │
│                                          │
│ Radeau : La Loutre                       │
│ Demande : 80 bidons                      │
│ Montant : 400 €                          │
│                                          │
│ Confirmez-vous avoir reçu le paiement ? │
│                                          │
│ [Confirmer] [Annuler]                    │
└──────────────────────────────────────────┘
```

### Page admin - Configuration
```
Configuration des bidons

Tarif par bidon
[__5__] €

Dernière modification : 01/12/2024 par Admin1

RIB pour paiements
IBAN : [FR76 XXXX XXXX XXXX XXXX XXXX XXX]
BIC : [XXXXXXXX]

[Enregistrer]

⚠️ Attention : Modifier le tarif n'affectera pas les demandes déjà payées.
```

## Dépendances
- **FEATURE-003** (Création équipage) : Radeau et équipage
- **FEATURE-008** (Pages privées) : Affichage section bidons
- **FEATURE-010** (Équipes transverses) : Équipe bidons

## Notes techniques

### Implémentation

#### Base de données
```elixir
create table :drum_requests do
  add :crew_id, references(:crews), null: false
  add :quantity, :integer, null: false
  add :unit_price, :decimal, precision: 10, scale: 2, null: false
  add :total_amount, :decimal, precision: 10, scale: 2, null: false
  add :status, :string, default: "pending", null: false  # pending, paid
  add :note, :text
  add :paid_at, :datetime
  add :validated_by_id, references(:users)

  timestamps()
end

create index(:drum_requests, [:crew_id])
create index(:drum_requests, [:status])

create table :drum_settings do
  add :unit_price, :decimal, precision: 10, scale: 2, null: false
  add :rib_iban, :string
  add :rib_bic, :string

  timestamps()
end
```

#### Schéma Elixir
```elixir
defmodule HoMonRadeau.Drums.DrumRequest do
  schema "drum_requests" do
    belongs_to :crew, Crew
    field :quantity, :integer
    field :unit_price, :decimal
    field :total_amount, :decimal
    field :status, :string, default: "pending"
    field :note, :string
    field :paid_at, :utc_datetime
    belongs_to :validated_by, User

    timestamps()
  end

  @statuses ~w(pending paid)

  def changeset(drum_request, attrs) do
    drum_request
    |> cast(attrs, [:quantity, :note])
    |> validate_required([:quantity])
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> calculate_amounts()
  end

  defp calculate_amounts(changeset) do
    case get_change(changeset, :quantity) do
      nil -> changeset
      quantity ->
        unit_price = Drums.get_current_unit_price()
        total = Decimal.mult(Decimal.new(quantity), unit_price)

        changeset
        |> put_change(:unit_price, unit_price)
        |> put_change(:total_amount, total)
    end
  end
end
```

#### Contexte
```elixir
defmodule HoMonRadeau.Drums do
  def create_drum_request(crew, attrs) do
    %DrumRequest{crew_id: crew.id}
    |> DrumRequest.changeset(attrs)
    |> Repo.insert()
  end

  def update_drum_request(request, attrs) do
    if request.status == "pending" do
      request
      |> DrumRequest.changeset(attrs)
      |> Repo.update()
    else
      {:error, :already_paid}
    end
  end

  def validate_payment(request, validated_by_user) do
    request
    |> Ecto.Changeset.change(%{
      status: "paid",
      paid_at: DateTime.utc_now(),
      validated_by_id: validated_by_user.id
    })
    |> Repo.update()
  end

  def get_crew_drum_requests(crew) do
    from(dr in DrumRequest,
      where: dr.crew_id == ^crew.id,
      order_by: [desc: dr.inserted_at]
    )
    |> Repo.all()
  end

  def get_crew_drums_summary(crew) do
    requests = get_crew_drum_requests(crew)

    %{
      total_quantity: Enum.reduce(requests, 0, fn r, acc -> if r.status == "paid", do: acc + r.quantity, else: acc end),
      total_amount: Enum.reduce(requests, Decimal.new(0), fn r, acc -> if r.status == "paid", do: Decimal.add(acc, r.total_amount), else: acc end),
      pending_quantity: Enum.reduce(requests, 0, fn r, acc -> if r.status == "pending", do: acc + r.quantity, else: acc end),
      pending_amount: Enum.reduce(requests, Decimal.new(0), fn r, acc -> if r.status == "pending", do: Decimal.add(acc, r.total_amount), else: acc end),
      requests: requests
    }
  end

  def get_current_unit_price() do
    settings = Repo.one(DrumSettings) || %DrumSettings{unit_price: Decimal.new(5)}
    settings.unit_price
  end

  def update_unit_price(new_price) do
    settings = Repo.one(DrumSettings) || %DrumSettings{}

    settings
    |> DrumSettings.changeset(%{unit_price: new_price})
    |> Repo.insert_or_update()
  end

  def list_all_drum_requests(filters \\ %{}) do
    base_query = from(dr in DrumRequest,
      join: c in Crew, on: c.id == dr.crew_id,
      join: r in Raft, on: r.id == c.raft_id,
      preload: [crew: {c, raft: r}],
      order_by: [desc: dr.inserted_at]
    )

    base_query
    |> filter_by_status(filters[:status])
    |> Repo.all()
  end

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status), do: where(query, [dr], dr.status == ^status)
end
```

#### Routes
```elixir
scope "/", HoMonRadeauWeb do
  pipe_through [:browser, :require_authenticated_user]

  # Pour les membres d'équipage
  post "/radeaux/:id/bidons", DrumRequestController, :create
  put "/radeaux/:id/bidons/:request_id", DrumRequestController, :update
end

scope "/", HoMonRadeauWeb do
  pipe_through [:browser, :require_authenticated_user, :require_drums_team]

  # Pour l'équipe bidons
  get "/bidons", DrumsTeamController, :index
  post "/bidons/:request_id/valider", DrumsTeamController, :validate_payment
end

scope "/admin", HoMonRadeauWeb.Admin do
  pipe_through [:browser, :require_authenticated_user, :require_admin]

  get "/bidons/config", DrumsConfigController, :edit
  put "/bidons/config", DrumsConfigController, :update
end
```

#### Permissions
```elixir
defmodule HoMonRadeauWeb.Plugs.RequireDrumsTeam do
  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns.current_user

    if Events.is_member_of_team?(user, "drums_team") or user.is_admin do
      conn
    else
      conn
      |> put_flash(:error, "Accès réservé à l'équipe bidons.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end
end
```

### Sécurité
- Vérifier que l'utilisateur est membre de l'équipage avant de permettre une demande
- Vérifier les permissions (équipe bidons/admin) avant validation de paiement
- Empêcher la modification d'une demande payée
- Logger toutes les validations de paiement
- Protection CSRF sur tous les formulaires

### Performance
- Index sur `drum_requests.crew_id` pour retrouver les demandes d'un radeau
- Index sur `drum_requests.status` pour filtrer les demandes
- Utiliser Decimal pour les calculs monétaires (pas de float)

### UX
- Calcul automatique du montant lors de la saisie
- RIB clairement visible et copiable
- Indication du statut avec icônes claires (✓ ⏳)
- Historique visible pour suivre les demandes successives
- Message clair si modification impossible après paiement
- Statistiques visuelles pour l'équipe bidons
