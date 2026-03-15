# FEATURE-013 : Fiches d'inscription

## Description
Gestion des fiches d'inscription obligatoires pour participer à l'événement. Chaque participant doit fournir un document scanné (fiche d'inscription signée). Les capitaines ont une fiche spécifique différente des autres participants.

## Objectif
S'assurer que tous les participants ont fourni les documents administratifs nécessaires avant l'événement. Permettre aux administrateurs de suivre l'état des fiches, de les valider, et d'envoyer des rappels aux retardataires.

## Utilisateurs concernés
- **Participants** : Doivent uploader leur fiche d'inscription (participant ou capitaine selon leur rôle)
- **Capitaines** : Doivent uploader la fiche capitaine (pas la fiche participant)
- **Gestionnaires d'équipage** : Voient le statut des fiches de leur équipage, reçoivent les notifications
- **Administrateurs** : Valident/rejettent les fiches, envoient les rappels, gèrent les documents

## Comportement attendu

### Pour le participant
1. Après validation par l'équipe d'accueil ET inscription dans un équipage
2. Sur sa page profil ou page équipage, voit un encart :
   - "**Obligatoire avant le [DATE]** : Renseigner votre fiche d'inscription"
3. En cliquant, accède à une page dédiée avec :
   - Texte explicatif sur la fiche à remplir
   - Lien vers le document à télécharger (fiche participant OU fiche capitaine selon son rôle)
   - Formulaire d'upload du scan
4. Après upload, la fiche est en statut "en attente de validation"
5. Peut uploader une nouvelle version à tout moment (l'historique est conservé)
6. Ne peut PAS supprimer ses fiches

### Pour les capitaines
- Un capitaine remplit **uniquement** la fiche capitaine
- La fiche capitaine remplace la fiche participant (pas les deux)

### Pour les gestionnaires d'équipage
1. Sur la page privée du radeau, voient un récapitulatif :
   - Liste des membres avec statut de leur fiche (✓ validée, ⏳ en attente, ⚠️ rejetée, ❌ manquante)
2. Reçoivent un email quand une fiche d'un membre est rejetée
3. Voient un banner d'alerte si des fiches sont manquantes ou rejetées

### Pour les administrateurs
1. **Page dédiée "Fiches d'inscription"** avec :
   - Liste des fiches à valider (statut "pending")
   - Vue par radeau : nombre de fiches manquantes par équipage
   - Filtres : par statut, par radeau, par type (participant/capitaine)

2. **Actions de validation :**
   - Visualiser la fiche uploadée
   - Approuver la fiche
   - Rejeter la fiche avec motif (déclenche email au participant + notification équipage)

3. **Rappels :**
   - Bouton "Envoyer rappel" pour relancer les participants sans fiche
   - Possibilité d'envoi groupé par radeau
   - (Optionnel futur) Envoi automatique hebdomadaire

4. **Gestion des fichiers :**
   - Peuvent supprimer les fiches (après l'événement typiquement)
   - Accès à l'historique des versions

## Règles métier

### Types de fiches
- **Fiche participant** : Pour tous les membres d'équipage non-capitaines
- **Fiche capitaine** : Pour les capitaines uniquement (remplace la fiche participant)

### Qui doit fournir une fiche ?
- Utilisateur validé par l'équipe d'accueil
- ET membre d'un équipage
- Type de fiche déterminé par le rôle `is_captain` dans l'équipage

### États d'une fiche
| État | Description |
|------|-------------|
| (aucune) | Pas encore uploadée |
| `pending` | Uploadée, en attente de review admin |
| `approved` | Validée par un admin |
| `rejected` | Rejetée, le participant doit en soumettre une nouvelle |

### Historique
- Chaque upload crée un nouvel enregistrement
- Les anciennes versions sont conservées
- Seuls les admins peuvent supprimer des fiches
- La fiche "courante" est la plus récente

### Deadline
- Date limite définie au niveau de l'édition (`registration_deadline`)
- Affichée clairement dans l'interface utilisateur
- Les rappels mentionnent cette date

### Notifications lors d'un rejet
- Email envoyé au participant concerné
- Email envoyé aux gestionnaires de l'équipage
- Banner affiché sur la page du radeau

## Interface utilisateur

### Page upload fiche (participant)
```
┌─────────────────────────────────────────────────────────────┐
│  📋 Fiche d'inscription                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Pour participer à Tutto Blu, vous devez remplir et signer │
│  votre fiche d'inscription.                                 │
│                                                             │
│  📅 Date limite : [DATE]                                    │
│                                                             │
│  1. Téléchargez le document :                              │
│     📄 [Fiche participant] ou [Fiche capitaine]            │
│                                                             │
│  2. Remplissez-le et signez-le                             │
│                                                             │
│  3. Scannez-le ou prenez une photo lisible                 │
│                                                             │
│  4. Uploadez-le ci-dessous :                               │
│     ┌─────────────────────────────────────┐                │
│     │  [Glisser-déposer ou Parcourir]     │                │
│     └─────────────────────────────────────┘                │
│                                                             │
│  Statut actuel : [✓ Validée / ⏳ En attente / ⚠️ Rejetée]  │
│                                                             │
│  [Si rejetée : motif du rejet affiché ici]                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Page radeau privée - Section fiches
```
┌─────────────────────────────────────────────────────────────┐
│  📋 Fiches d'inscription de l'équipage                      │
├─────────────────────────────────────────────────────────────┤
│  Deadline : 15 juin 2025                                    │
│                                                             │
│  Membre          │ Type      │ Statut                       │
│  ─────────────────┼───────────┼─────────────────────────────│
│  @pseudo1        │ Capitaine │ ✓ Validée                   │
│  @pseudo2        │ Particip. │ ⏳ En attente                │
│  @pseudo3        │ Particip. │ ⚠️ Rejetée                   │
│  @pseudo4        │ Particip. │ ❌ Manquante                 │
│                                                             │
│  ⚠️ 2 fiches manquantes ou invalides                        │
└─────────────────────────────────────────────────────────────┘
```

### Page admin - Gestion des fiches
```
┌─────────────────────────────────────────────────────────────┐
│  📋 Administration - Fiches d'inscription                   │
├─────────────────────────────────────────────────────────────┤
│  Filtres : [Statut ▼] [Radeau ▼] [Type ▼]                  │
│                                                             │
│  📊 Résumé :                                                │
│  • 45 fiches validées                                       │
│  • 12 fiches en attente de review                          │
│  • 8 fiches manquantes                                      │
│                                                             │
│  [Envoyer rappels aux fiches manquantes]                   │
├─────────────────────────────────────────────────────────────┤
│  Fiches à valider :                                         │
│                                                             │
│  Participant    │ Radeau        │ Type    │ Uploadée │ Action│
│  ────────────────┼───────────────┼─────────┼──────────┼───────│
│  @pseudo1       │ Les Flotteurs │ Capit.  │ 02/06    │ [👁️][✓][✗]│
│  @pseudo2       │ Radeau Ivre   │ Partic. │ 01/06    │ [👁️][✓][✗]│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Page admin - Vue par radeau
```
┌─────────────────────────────────────────────────────────────┐
│  📋 Fiches par radeau                                       │
├─────────────────────────────────────────────────────────────┤
│  Radeau           │ Membres │ Validées │ Attente │ Manquantes│
│  ──────────────────┼─────────┼──────────┼─────────┼──────────│
│  Les Flotteurs    │ 8       │ 6        │ 1       │ 1        │
│  Radeau Ivre      │ 5       │ 3        │ 0       │ 2        │
│  L'Épave Joyeuse  │ 6       │ 6        │ 0       │ 0  ✓     │
│                                                             │
│  [Rappel Les Flotteurs] [Rappel Radeau Ivre]               │
└─────────────────────────────────────────────────────────────┘
```

## Dépendances
- **FEATURE-001** (Inscription utilisateur) : Utilisateur inscrit
- **FEATURE-002** (Validation participants) : Utilisateur validé
- **FEATURE-005** (Adhésion équipage) : Membre d'un équipage
- **FEATURE-006** (Rôles équipage) : Détermination capitaine vs participant
- **Service de stockage** : Tigris (S3-compatible) sur Fly.io
- **Service d'email** : Envoi des notifications et rappels

## Notes techniques

### Base de données

#### Modification table `editions`
```elixir
alter table(:editions) do
  add :registration_deadline, :date
  add :participant_form_url, :string  # Lien vers le PDF fiche participant
  add :captain_form_url, :string      # Lien vers le PDF fiche capitaine
end
```

#### Nouvelle table `registration_forms`
```elixir
create table(:registration_forms) do
  add :user_id, references(:users, on_delete: :delete_all), null: false
  add :edition_id, references(:editions, on_delete: :delete_all), null: false
  add :form_type, :string, null: false  # "participant" | "captain"
  add :file_key, :string, null: false   # Clé S3/Tigris
  add :file_name, :string, null: false  # Nom original du fichier
  add :file_size, :integer              # Taille en bytes
  add :content_type, :string            # MIME type
  add :status, :string, default: "pending"  # pending | approved | rejected
  add :rejection_reason, :text
  add :reviewed_at, :utc_datetime
  add :reviewed_by_id, references(:users, on_delete: :nilify_all)
  add :uploaded_at, :utc_datetime, null: false

  timestamps(type: :utc_datetime)
end

create index(:registration_forms, [:user_id])
create index(:registration_forms, [:edition_id])
create index(:registration_forms, [:status])
create index(:registration_forms, [:user_id, :edition_id])
```

### Stockage Tigris/S3

#### Configuration
```elixir
# config/runtime.exs
config :ho_mon_radeau, :storage,
  bucket: System.get_env("TIGRIS_BUCKET"),
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  endpoint: System.get_env("AWS_ENDPOINT_URL_S3")
```

#### Structure des clés
```
registration_forms/{edition_id}/{user_id}/{timestamp}_{filename}
```

#### Dépendance
```elixir
# mix.exs
{:ex_aws, "~> 2.5"},
{:ex_aws_s3, "~> 2.5"},
{:hackney, "~> 1.20"}
```

### Logique métier

#### Détermination du type de fiche requis
```elixir
def required_form_type(user, edition) do
  case Events.get_crew_member_for_user(user, edition) do
    nil -> nil  # Pas dans un équipage
    %{is_captain: true} -> :captain
    _ -> :participant
  end
end
```

#### Fiche courante d'un utilisateur
```elixir
def get_current_form(user_id, edition_id) do
  from(rf in RegistrationForm,
    where: rf.user_id == ^user_id and rf.edition_id == ^edition_id,
    order_by: [desc: rf.uploaded_at],
    limit: 1
  )
  |> Repo.one()
end
```

#### Statut global de fiche
```elixir
def form_status(user, edition) do
  case get_current_form(user.id, edition.id) do
    nil -> :missing
    %{status: "approved"} -> :approved
    %{status: "rejected"} -> :rejected
    %{status: "pending"} -> :pending
  end
end
```

### Emails

#### Templates à créer
- `registration_form_rejected.html.heex` : Notification de rejet au participant
- `registration_form_rejected_crew.html.heex` : Notification aux gestionnaires
- `registration_form_reminder.html.heex` : Rappel pour fiche manquante

### Sécurité
- Validation du type MIME (PDF, images uniquement)
- Limite de taille de fichier (ex: 10 MB)
- URLs pré-signées pour accès aux fichiers (expiration courte)
- Vérification des permissions avant upload/visualisation

### Performance
- Index sur `(user_id, edition_id)` pour recherche rapide
- Index sur `status` pour filtrage admin
- Pagination sur les listes admin
