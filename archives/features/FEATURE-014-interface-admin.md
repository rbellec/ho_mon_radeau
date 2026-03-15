# FEATURE-014 : Interface d'administration

## Description
L'interface d'administration combine deux approches complémentaires : **Kaffy** pour les opérations CRUD sur les données brutes, et des **LiveViews custom** pour les workflows métier (validations, suivi, actions contextuelles). Cette séparation évite de surcharger Kaffy avec de la logique métier complexe tout en évitant de ré-implémenter du CRUD simple.

## Objectif
Donner aux administrateurs un accès complet à toutes les données et opérations de l'application, avec des interfaces adaptées à chaque type d'action : tableau de bord brut pour la consultation/correction de données, interfaces dédiées pour les workflows qui nécessitent du contexte et des règles métier.

## Utilisateurs concernés
- **Administrateurs** uniquement

## Séparation Kaffy / LiveViews custom

### Kaffy — Données brutes
Accès via `/admin` (route Kaffy).

Gère le CRUD direct sur :

| Groupe | Ressources |
|--------|-----------|
| **Comptes** | Utilisateurs (voir/modifier les champs, promouvoir admin) |
| **Événements** | Éditions, Radeaux, Équipages, Membres d'équipage, Demandes d'adhésion |
| **Inscriptions** | Fiches d'inscription |

Kaffy est la console de dernier recours pour corriger des données, modifier des champs manuellement, ou intervenir dans des situations exceptionnelles non prévues par les LiveViews custom.

### LiveViews custom — Workflows métier
Accès via `/admin/...` (routes Phoenix custom).

| Interface | Description |
|-----------|-------------|
| **Validation utilisateurs** | Liste des non-validés, actions valider/révoquer, recherche par pseudo/email/téléphone (FEATURE-002) |
| **Validation radeaux** | Tableau avec filtres multi-critères, actions valider/invalider, affichage capitaine (FEATURE-009) |
| **Validation CUF** | Liste des déclarations en attente, validation paiement, stats globales (FEATURE-012) |
| **Validation bidons** | Liste des demandes, validation paiement, config tarif + RIB (FEATURE-011) |
| **Fiches d'inscription** | Review des fiches uploadées, approve/reject, rappels, vue par radeau (FEATURE-013) |
| **Membres ayant quitté** | Tableau des départs pour suivi CUF (FEATURE-017) |
| **Dashboard** | Vue d'ensemble : stats participants, radeaux, CUF, fiches |

## Gestion des éditions

Les éditions sont gérées **exclusivement via Kaffy**. Il n'y a pas d'interface dédiée — le volume (une édition par an) ne le justifie pas.

### Champs d'une édition
- `year` : Année (ex: 2026)
- `name` : Nom affiché (ex: "Tutto Blu 2026")
- `is_current` : Boolean — une seule édition courante à la fois
- `start_date` / `end_date` : Dates de l'événement
- `registration_deadline` : Date limite pour les fiches d'inscription
- `participant_form_url` : URL du PDF fiche participant
- `captain_form_url` : URL du PDF fiche capitaine

### Workflow annuel
1. Admin crée la nouvelle édition via Kaffy
2. Passe `is_current = true` sur la nouvelle, `false` sur l'ancienne
3. L'application utilise automatiquement l'édition courante pour toutes les nouvelles créations

## Configuration globale

Les paramètres opérationnels sont modifiables via les interfaces LiveViews dédiées (pas via Kaffy) car ils ont des effets métier :

| Paramètre | Interface |
|-----------|-----------|
| Tarif bidon (€/bidon) | Page "Gestion bidons" |
| RIB bidons (IBAN/BIC) | Page "Gestion bidons" |
| Montant CUF (€/personne) | Page "Gestion CUF" |
| RIB CUF (IBAN/BIC) | Page "Gestion CUF" |
| Limite totale participants | Page "Gestion CUF" |

## Accès et sécurité

- Accès conditionné à `user.is_admin == true`
- Plug `RequireAdmin` sur toutes les routes `/admin/...`
- Kaffy configuré pour exiger l'authentification admin (`HoMonRadeauWeb.KaffyConfig`)
- Les équipes transverses (accueil, bidons) ont accès uniquement à leurs interfaces dédiées — pas à l'admin global

## Dépendances
- **Kaffy** : `{:kaffy, "~> 0.13"}` dans `mix.exs`
- Toutes les features admin : FEATURE-002, 009, 011, 012, 013, 017
