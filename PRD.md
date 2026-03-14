# Product Requirements Document — HoMonRadeau

> Application d'auto-gestion de l'événement **Tutto Blu**
> Version 1.0 — Mars 2026

---

## 1. Vue d'ensemble

### 1.1 Contexte

**Tutto Blu** est un événement annuel où des participants forment des équipages, construisent des radeaux, puis organisent "la dérive" sur un lac. L'application HoMonRadeau centralise la gestion logistique de l'événement : inscription des participants, constitution des équipages, gestion des ressources (bidons, CUF) et communication avec l'organisation.

### 1.2 Philosophie produit

- **Compléter, ne pas remplacer** : L'app complète le forum Discourse et WhatsApp — elle ne les remplace pas.
- **Minimaliste** : Limiter les features locales. La communication se fait hors app.
- **Autonomie des équipages** : Les équipages se gèrent eux-mêmes, l'organisation intervient pour valider.

### 1.3 Stack technique

- **Language** : Elixir (latest stable)
- **Framework** : Phoenix (latest stable) + LiveView
- **Base de données** : PostgreSQL 16
- **Auth** : `phx.gen.auth` (email + magic link)
- **Admin** : Kaffy (CRUD brut) + LiveViews custom (workflows métier)
- **Stockage fichiers** : Tigris S3-compatible (Fly.io) — photos, fiches d'inscription
- **Déploiement** : Fly.io

---

## 2. Utilisateurs et rôles

| Rôle | Description |
|------|-------------|
| **Visiteur** | Non connecté. Peut consulter les pages publiques. |
| **Utilisateur non validé** | Compte créé, email vérifié. Voit tout mais ne peut pas rejoindre un équipage. |
| **Utilisateur validé** | Validé par l'équipe d'accueil. Peut rejoindre ou créer un équipage. |
| **Membre d'équipage** | Appartient à un radeau. Accès à la page privée de son radeau. |
| **Gestionnaire d'équipage** | Manage son équipage (ajout de membres, demandes d'adhésion). |
| **Capitaine** | Interlocuteur principal entre l'organisation et l'équipage. |
| **Équipe transverse** | Membre d'une équipe fonctionnelle (Accueil, SAFE, Bidons, Sécurité, Médecine). |
| **Admin** | Accès complet. Valide participants, radeaux, paiements. |

---

## 3. Entités principales

### Éditions

Chaque événement Tutto Blu = une édition annuelle. Les radeaux et équipages sont liés à une édition.

- Unicité du nom de radeau **par édition** (pas globalement)
- URLs : `/[année]/radeaux/[nom]` (ex: `/2026/radeaux/fun-radeau`)

### Radeau / Équipage

Relation **1-1** : un radeau (objet physique) ↔ un équipage (groupe de personnes). Les deux termes sont souvent interchangeables dans le langage courant.

- Un utilisateur ne peut être membre que d'**un seul équipage** à la fois
- Un utilisateur peut être membre de **plusieurs équipes transverses** en parallèle

---

## 4. Features

### Priorités

| Priorité | Description |
|----------|-------------|
| **P0 — MVP** | Nécessaire pour le lancement. Bloquant. |
| **P1** | Important mais non bloquant pour le MVP. |
| **P2** | Nice-to-have, planifié pour plus tard. |

---

### FEATURE-001 — Inscription utilisateur `P0`

**Objectif** : Permettre à toute personne de créer un compte.

**Formulaire d'inscription :**
- Email (obligatoire, unique) — validation par lien email
- Pseudo (optionnel) — toujours public si renseigné
- Mot de passe (obligatoire, min. 6 caractères)

**Données optionnelles à l'inscription** (requises pour participer à l'événement) :
- Nom / Prénom
- Photo de profil (stockée dans l'app, visibilité configurable)
- Numéro de téléphone

**Statut après inscription :** `non validé`

**Règles métier :**
- Le pseudo est toujours public s'il est défini
- Les utilisateurs sans pseudo sont affichés comme "Matelot sans pseudonyme"
- Photo de profil : publique (affichée partout) ou privée (affichée uniquement dans son équipage et aux admins)

---

### FEATURE-002 — Validation des nouveaux participants `P0`

**Objectif** : Valider les nouveaux inscrits avant de les autoriser à rejoindre un équipage. Assure la conformité avec la préfecture et préserve l'esprit de l'événement.

**Workflow :**
1. Utilisateur s'inscrit → statut `non validé`
2. Entretien hors application (WhatsApp, téléphone)
3. Équipe d'accueil (ou admin) valide dans l'app → statut `validé`

**Droits de validation :**
- **Admins** : Voient tous les utilisateurs avec données personnelles complètes. Peuvent valider et révoquer.
- **Équipe d'accueil** : Voient uniquement les pseudos. Validation par pseudo ou coordonnées.

**Méthodes de validation :**
- Option 1 : Cliquer "Valider" à côté d'un pseudo
- Option 2 : Entrer email ou numéro de téléphone dans un formulaire (demandé directement à la personne)

**Règles :**
- La validation est **irréversible** par défaut (un admin peut la retirer si nécessaire)
- Les utilisateurs "connus" peuvent être pré-validés à l'inscription

**Accès utilisateur non validé :**
- ✅ Peut voir tout le contenu public
- ✅ Peut consulter la liste des radeaux
- ❌ Ne peut PAS s'inscrire à un radeau

**Message à afficher** : "Votre compte doit être validé par l'équipe d'accueil avant de pouvoir rejoindre un radeau. Un membre de l'équipe vous contactera prochainement."

---

### FEATURE-003 — Création d'équipage `P0`

**Objectif** : Permettre aux utilisateurs validés de créer un radeau.

**Conditions :**
- Utilisateur doit être validé (FEATURE-002)
- Utilisateur ne doit pas déjà être membre d'un équipage

**Formulaire :**
- Nom du radeau (obligatoire, unique par édition)
- Description (optionnelle, publique)
- Lien forum Discourse (optionnel)

**Après création :**
- Créateur = premier gestionnaire automatiquement
- Statut initial = `radeau proposé`
- Redirection vers la page privée du radeau

**Radeaux abandonnés :**
Si plus aucun membre → radeau abandonné. Les admins peuvent l'effacer ou y affecter un nouveau membre (gestionnaire par défaut).

---

### FEATURE-004 — Gestion des gestionnaires `P0`

**Objectif** : Permettre la gestion des droits de gestionnaire au sein d'un équipage.

**Règles :**
- Pas de hiérarchie entre gestionnaires (créateur = autres gestionnaires)
- Le créateur peut quitter l'équipage même s'il n'y a plus d'autre gestionnaire
- Si plus aucun gestionnaire : un admin peut promouvoir un membre (pas de promotion automatique)
- Tous les gestionnaires ont les mêmes droits

---

### FEATURE-005 — Adhésion à un équipage `P0`

**Objectif** : Permettre aux utilisateurs validés de rejoindre un équipage.

**Méthodes :**
1. **Ajout direct** : Un gestionnaire recherche un utilisateur (par pseudo ou email) et l'ajoute directement
2. **Demande d'adhésion** : L'utilisateur clique "Demander à rejoindre" sur la page publique, avec message de motivation optionnel. Les gestionnaires voient la liste et valident.

**Restrictions :**
- Seuls les utilisateurs validés peuvent être ajoutés directement
- Un utilisateur non validé peut soumettre une demande, mais elle est marquée "En attente de validation utilisateur" — les gestionnaires ne peuvent que la refuser
- Un utilisateur ne peut appartenir qu'à un seul équipage

**Demandes multiples :**
- Un utilisateur peut envoyer des demandes à plusieurs radeaux simultanément
- Si accepté dans un radeau, ses autres demandes en attente sont **automatiquement annulées**

**États sur la page publique :**
- "Demander à rejoindre" (si validé, pas encore membre)
- "Vous êtes membre de ce radeau"
- "Vous êtes déjà membre d'un autre équipage"

---

### FEATURE-006 — Rôles dans l'équipage `P1`

**Objectif** : Permettre l'auto-déclaration des rôles fonctionnels au sein d'un équipage.

**Rôles auto-déclarables (par le membre lui-même) :**
- Lead construction (`lead_construction`)
- Cuisine (`cook`)
- Interlocuteur SAFE (`safe_liaison`)

**Rôles attribués par un gestionnaire :**
- Capitaine (`is_captain`) — un seul par radeau
- Gestionnaire (`is_manager`) — voir FEATURE-004

**Règles :**
- Un membre peut avoir **plusieurs rôles** standards simultanément
- **Un seul capitaine** par radeau — nommer un nouveau capitaine **retire automatiquement** le rôle à l'ancien
- Capitaine n'est **pas affiché publiquement** (affiché dans la liste admin pour faciliter le contact)
- La page privée affiche la section "Rôles à pourvoir" avec alertes visuelles pour les rôles manquants

---

### FEATURE-007 — Pages publiques des radeaux `P0`

**Objectif** : Vitrine publique de chaque radeau, accessible sans connexion.

**Liste des radeaux :**
- Photo + Nom + Description courte + Nombre de membres + Badge statut (Participant / Proposé)
- Ordre : participants en premier, puis proposés, tri alphabétique dans chaque groupe

**Page publique d'un radeau (`/[année]/radeaux/[nom]`) :**
- Photo, nom, description, badge statut
- Lien forum Discourse
- Liste des membres : pseudos + photos (si publiques) + "Matelot sans pseudonyme"
- Compteur "+ X matelots secrets"
- Liens/documents publics (liens externes uniquement)
- Bouton "Demander à rejoindre" (si connecté et validé)

**Données toujours publiques :**
- Nom du radeau, description, photo du radeau, nombre de membres, statut, lien forum

**Données jamais publiques :**
- Rôles, nom/prénom/email/téléphone des membres, CUF, bidons

---

### FEATURE-008 — Pages privées des radeaux `P0`

**Objectif** : Espace de gestion interne, visible uniquement par les membres de l'équipage.

**Redirection après connexion :**
- Membre d'un équipage → page privée de son radeau (`/mon-radeau`)
- Non-membre → liste des radeaux

**Sections :**
1. En-tête : nom, photo, badge statut, bouton modifier (gestionnaires)
2. État de l'équipage : capitaine, rôles à pourvoir, liste gestionnaires
3. CUF : participants déclarés, CUF restant à régler, statut (gérable par capitaine)
4. Bidons : demande actuelle, montant, statut (gérable par gestionnaires)
5. Membres + demandes d'adhésion (onglets)
6. Outils : lien forum Discourse, lien WhatsApp (éditable par gestionnaires), documents internes
7. Rappel cotisation base flottante (placeholder, non géré dans l'app)

**Visibilité des données entre membres :**
- Sur la page privée, les membres voient les coordonnées complètes des autres membres : pseudo, email, nom/prénom, téléphone (si renseignés), photos (publiques ET privées)

**Accès :**
- Membres de l'équipage uniquement
- Administrateurs ont accès à toutes les pages privées (lecture + intervention)

---

### FEATURE-009 — Validation admin des radeaux `P1`

**Objectif** : Permettre à l'organisation de valider officiellement les radeaux participants.

**Statuts :**
- `proposé` : Radeau créé, non encore validé par l'admin. Peut fonctionner normalement (membres, bidons, CUF).
- `participant` : Validé par l'admin, radeau officiellement inscrit à l'événement.

**Impact de la validation :**
- Badge visuel différent sur les pages publiques/privées
- Ordre d'affichage dans les listes (participants en premier)
- La validation est **réversible** (un admin peut invalider un radeau validé)

**Critères de validation :** laissés à l'appréciation de l'admin (équipage constitué, capitaine nommé, engagement confirmé, etc.)

**Interface admin :**
- Tableau avec recherche multi-critères : nom, statut, équipage complet, CUF payée, nombre d'équipiers, bidons
- Colonnes triables : nom, statut, membres, CUF, bidons, date création
- Affichage du capitaine pour faciliter le contact

---

### FEATURE-010 — Équipes transverses `P1`

**Objectif** : Gérer les équipes fonctionnelles de l'événement (différentes des équipages).

**Types d'équipes (définis en dur dans le code) :**
- `welcome_team` — Accueil des nouveaux
- `safe_team` — Équipe SAFE
- `drums_team` — Équipe Bidons
- `security` — Sécurité
- `medical` — Médecine

**Différences avec les équipages :**
- Non listées parmi les radeaux
- Pas de page publique (ou minimale)
- Visibles uniquement par leurs membres et les admins
- Pas de bouton "Rejoindre" : recrutement par discussions externes (WhatsApp, forum)
- Le coordinateur ajoute les membres directement dans l'app
- Un utilisateur peut être membre de plusieurs équipes transverses simultanément
- Pas de CUF, pas de bidons (pas de construction)
- **Être dans une équipe transverse ne suffit pas pour participer à l'événement** — il faut aussi être membre d'un radeau (ou avoir un statut admin/orga)

---

### FEATURE-011 — Gestion des bidons `P1`

**Objectif** : Centraliser les demandes de bidons (ressource de flottaison) par équipage.

**Contexte :**
- Bidons = seule ressource centralisée de l'événement
- En location, paiement hors application
- Demande possible uniquement après constitution et validation du radeau

**Statuts :**
1. Aucune demande faite
2. Demande en attente
3. Paiement validé

**Workflow :**
1. L'équipage détermine le nombre de bidons nécessaires
2. Un membre de l'équipage fait la demande dans l'app
3. L'équipe bidons centralise les demandes
4. Paiement effectué hors app
5. L'équipe bidons signale la réception du paiement dans l'app

**Règles :**
- Tous les membres d'un équipage peuvent faire / modifier une demande (avant validation)
- Une seule demande active par radeau
- Modifications additionnelles possibles après validation
- Tarif par bidon affiché, calcul automatique du total
- Montant figé une fois payé (même si le tarif change ensuite)
- RIB affiché dans l'app
- Radeaux sans bidons autorisés (affichent 0)

**Données publiques :** nombre de bidons demandés, statut de paiement

---

### FEATURE-012 — CUF (Cotisation Urbaine Flottante) `P1`

**Objectif** : Gérer la cotisation d'inscription à l'événement, perçue par radeau.

**Contexte :**
- Cotisation perçue par radeau (pas par individu)
- **Déclaration nominative** : le capitaine sélectionne nommément chaque participant
- Montant fixe par personne, fixé vers mars
- Nombre total de participants à l'événement est limité

**Workflow :**
1. Le capitaine sélectionne les membres participants (nominatif) dans l'app
2. L'app calcule automatiquement le montant total
3. Paiement effectué hors app (virement avec RIB affiché)
4. L'admin valide à réception du paiement → membres passent au statut `participant`

**Statuts des membres d'un équipage :**
1. `candidat` — Utilisateur non validé par l'équipe d'accueil
2. `en attente` — Validé, membre de l'équipage, non encore déclaré comme participant
3. `participant` — CUF payée et validée
4. `non participant` — Membre impliqué dans la préparation mais ne participera pas à l'événement

**Règles importantes :**
- La CUF est une **inscription nominative**, pas juste un nombre
- Un radeau peut temporairement avoir plus ou moins de membres que le nombre déclaré
- Régularisation obligatoire avant participation effective
- Capitaine = obligatoirement un participant (exception temporaire possible avant validation CUF)
- Montant figé une fois payé (même si le tarif change)
- Changements après déclaration : possibles mais nécessitent validation admin

**Affichage sur la page équipage :**
- Candidats (si > 0)
- Membres en attente
- Participants (CUF payée)
- "CUF restant à régler" (peut être négatif si désistement)

**Page admin — récapitulatif global :**
- Participants validés / limite de l'événement (à afficher quand connue)
- En attente de validation
- Total CUF perçue

---

### FEATURE-013 — Fiches d'inscription `P0`

**Objectif** : Gérer les fiches d'inscription obligatoires (documents signés et scannés) pour chaque participant.

**Types de fiches :**
- **Fiche participant** : pour tous les membres non-capitaines
- **Fiche capitaine** : pour les capitaines uniquement — remplace la fiche participant (pas les deux)

**Workflow participant :**
1. Après validation par l'équipe d'accueil ET inscription dans un équipage
2. Encart visible sur sa page profil / page équipage : "Obligatoire avant le [DATE] : renseigner votre fiche d'inscription"
3. Téléchargement du document PDF (lien depuis l'édition), signature, scan
4. Upload dans l'app → statut `en attente`
5. Admin review → `approuvée` ou `rejetée` (avec motif)
6. En cas de rejet : upload d'une nouvelle version possible à tout moment (historique conservé)

**Statuts d'une fiche :**
| État | Description |
|------|-------------|
| (aucune) | Pas encore uploadée |
| `pending` | Uploadée, en attente de review admin |
| `approved` | Validée par un admin |
| `rejected` | Rejetée, nouvelle soumission requise |

**Règles :**
- Un participant ne peut pas supprimer ses fiches (admins seulement)
- L'historique des versions est conservé, la fiche courante = la plus récente
- Date limite liée à l'édition (`registration_deadline`)

**Notifications :**
- Email au participant si rejet (avec motif)
- Email aux gestionnaires de l'équipage si rejet d'un membre
- Banner d'alerte sur la page privée du radeau si fiches manquantes/rejetées

**Vue gestionnaire (page privée) :**
- Tableau récapitulatif : membre / type de fiche / statut (✓ / ⏳ / ⚠️ rejetée / ❌ manquante)

**Interface admin :**
- Liste des fiches à valider avec filtres (statut, radeau, type)
- Vue par radeau : nombre de fiches manquantes par équipage
- Actions : visualiser, approuver, rejeter avec motif
- Bouton "Envoyer rappel" par participant ou par radeau

**Stockage :** Tigris (S3-compatible, Fly.io) — URLs pré-signées pour l'accès aux fichiers

---

### FEATURE-014 — Interface d'administration `P0`

**Objectif** : Fournir aux admins une interface complète combinant Kaffy (données brutes) et des LiveViews custom (workflows métier).

**Séparation Kaffy / LiveViews custom :**

| Outil | Responsabilité |
|-------|---------------|
| **Kaffy** (`/admin`) | CRUD brut : utilisateurs, éditions, radeaux, équipages, membres, demandes d'adhésion, fiches |
| **LiveViews custom** (`/admin/...`) | Workflows : validation users, validation radeaux, CUF, bidons, fiches, tableau départs |

**Kaffy = console de dernier recours** pour corriger des données ou intervenir dans des situations exceptionnelles. Les interfaces quotidiennes de l'organisation sont les LiveViews custom.

**Gestion des éditions (via Kaffy uniquement) :**
- Créer une édition : `year`, `name`, `is_current`, `start_date`, `end_date`
- Paramètres de l'édition : `registration_deadline`, `participant_form_url`, `captain_form_url`
- Activer une édition : passer `is_current = true` (une seule à la fois)

**Configuration globale (via LiveViews dédiées) :**
- Tarif bidon + RIB → page "Gestion bidons"
- Montant CUF + RIB + limite participants → page "Gestion CUF"

---

### FEATURE-015 — Page profil utilisateur `P0`

**Objectif** : Permettre à chaque utilisateur de consulter et modifier ses informations personnelles, uploader sa photo de profil, et voir son statut dans l'application.

**Accès :** `/mon-profil` — lien depuis la navigation principale

**Informations affichables :**
- Statut du compte (validé / en attente)
- Pseudo, prénom, nom, téléphone (modifiables)
- Photo de profil avec visibilité configurable
- Email (lecture seule, modifiable via flux phx.gen.auth)
- Équipage et équipes transverses actuels

**Upload de photo de profil :**
- Formats : JPEG, PNG, WebP — taille max 5 MB
- Stockage sur Tigris (même infrastructure que les fiches, FEATURE-013)
- Clé : `profile_pictures/{user_id}/{timestamp}_{filename}`
- URL pré-signée générée à l'affichage (expiration courte)
- L'ancienne photo est supprimée de Tigris à chaque remplacement

**Visibilité photo :**
- Publique → affichée partout (pages publiques des radeaux)
- Privée → affichée uniquement dans les équipages et aux admins

**Note :** Si prénom ou nom sont manquants, l'app affiche un rappel visible ("requis pour participer à l'événement").

---

### FEATURE-016 — Quitter un équipage `P1`

**Objectif** : Permettre à un membre de quitter volontairement son équipage, avec notification à l'équipage et suivi admin des départs ayant un impact CUF.

**Workflow :**
1. Bouton "Quitter l'équipage" sur la page privée du radeau
2. Confirmation simple si pas de CUF concernée
3. **Avertissement** si le membre est déclaré comme participant dans une CUF :
   > "Vous êtes déclaré·e comme participant·e dans la CUF. Le capitaine devra régulariser."
4. Départ enregistré → notification aux gestionnaires → "CUF restant" devient négatif si CUF concernée

**Cas particuliers :**
- Dernier gestionnaire → avertissement supplémentaire (équipage sans gestionnaire)
- Capitaine → rôle retiré automatiquement, avertissement affiché

**Tableau de suivi des départs (admin uniquement) :**
- Accessible à `/admin/departures`
- Colonnes : membre, équipage, date, statut CUF au départ, capitaine/gestionnaire au moment du départ
- Filtres par équipage, statut CUF, date
- Outil de consultation uniquement (pas d'actions depuis ce tableau)

**Table `crew_departures` :** enregistre chaque départ avec statut CUF au moment du départ, `was_captain`, `was_manager`, et si retrait par un gestionnaire ou départ volontaire.

---

## 5. Règles transverses

### Données privées vs publiques

| Donnée | Visibilité |
|--------|------------|
| Pseudo utilisateur | Toujours public (si défini) |
| Nom du radeau | Toujours public |
| Description du radeau | Toujours public |
| Photo du radeau | Toujours public |
| Photo de profil | Configurable par l'utilisateur |
| Nom / Prénom / Email / Téléphone | Privé (admins uniquement) |
| Rôles dans l'équipage | Privé |
| Capitaine | Privé (liste admin uniquement) |

### Fichiers et pièces jointes

- **Principe** : Liens externes uniquement (Google Drive, Notion, Dropbox…)
- **Exception** : Photos de radeau et photos de profil → stockées dans l'app

### Unicité par édition

- Nom de radeau unique **par édition** (peut être réutilisé les années suivantes)
- Un utilisateur = un seul équipage par édition
- URL des radeaux : `/[année]/radeaux/[nom]`

---

## 6. Flux utilisateur principaux

### Nouveau participant

```
Inscription → Validation email → [Non validé]
     → Entretien équipe accueil → [Validé]
     → Rejoindre un équipage OU Créer un radeau
     → Remplir fiche d'inscription
     → Déclarer participation (CUF) → [Participant]
```

### Création d'un équipage

```
[Utilisateur validé]
     → Créer un radeau (nom unique par édition)
     → Devient gestionnaire automatiquement
     → Statut radeau = "Proposé"
     → Inviter / accepter des membres
     → Nommer un capitaine
     → Demander des bidons
     → Déclarer CUF
     → Admin valide → Statut = "Participant"
```

### Rejoindre un équipage

```
[Utilisateur validé]
     → Parcourir liste des radeaux
     → Page publique → "Demander à rejoindre"
     OU être ajouté directement par un gestionnaire
     → Gestionnaire valide la demande
     → [Membre de l'équipage]
```

---

## 7. Hors scope (actuel)

- Gestion du stock de bidons sur place
- Cotisation base flottante (placeholder prévu dans la page radeau)
- Validation des rôles obligatoires avant participation
- Remboursements bidons
- Historique des paiements détaillé
- Notifications push / emails automatiques (hors validation email)

---

## 8. Références

- Features détaillées : `docs/features/FEATURE-XXX-*.md`
- Clarifications et décisions : `docs/features/notes-clarifications.md`
- Forum Discourse : https://tuttoblu.discourse.group/
- Guide d'implémentation : `NEXT_STEPS.md`
- Conventions techniques : `CLAUDE.md`
