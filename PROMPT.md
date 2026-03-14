# Ralph Loop — HoMonRadeau

Tu es un développeur Elixir/Phoenix qui implémente l'application **HoMonRadeau** (gestion de l'événement Tutto Blu).

## Contexte du projet

- Lis `CLAUDE.md` pour les conventions (langue, nommage, stack)
- Lis `AGENTS.md` pour les règles Phoenix/LiveView/Ecto impératives
- Lis `PRD.md` pour la vision produit et toutes les features (source de vérité)
- Lis `docs/features/FEATURE-XXX-*.md` pour les détails d'une feature avant de l'implémenter
- Consulte `git log --oneline -20` pour voir ce qui a déjà été fait

## Critère de vérification automatique

À chaque itération, **la première chose à faire** est de lancer :

```bash
docker compose run --rm app mix precommit
```

Ce script exécute dans l'ordre :
1. `compile --warnings-as-errors` — le code compile sans warning
2. `deps.unlock --unused` — pas de dépendances inutilisées
3. `format` — code formaté selon `mix format`
4. `test` — tous les tests passent (avec migration DB automatique)

**Si `mix precommit` échoue** → corriger les erreurs avant d'implémenter quoi que ce soit de nouveau.

**Si `mix precommit` passe** → identifier la prochaine feature à implémenter.

## Ordre d'implémentation

Respecte les priorités du PRD :

### P0 — MVP (dans cet ordre)
1. FEATURE-001 : Inscription utilisateur ← phx.gen.auth déjà en place
2. FEATURE-002 : Validation des nouveaux participants
3. FEATURE-003 : Création d'équipage
4. FEATURE-004 : Gestion des gestionnaires
5. FEATURE-005 : Adhésion à un équipage
6. FEATURE-007 : Pages publiques des radeaux
7. FEATURE-008 : Pages privées des radeaux
8. FEATURE-013 : Fiches d'inscription
9. FEATURE-014 : Interface admin (Kaffy déjà installé)
10. FEATURE-015 : Page profil utilisateur

### P1 (après MVP)
11. FEATURE-006 : Rôles dans l'équipage
12. FEATURE-009 : Validation admin des radeaux
13. FEATURE-010 : Équipes transverses
14. FEATURE-011 : Gestion des bidons
15. FEATURE-012 : CUF (Cotisation Urbaine Flottante)
16. FEATURE-016 : Quitter un équipage

## Règles d'implémentation

### Avant chaque feature
1. Lire le fichier `docs/features/FEATURE-XXX-*.md` correspondant
2. Vérifier si une migration / un schéma / un contexte existe déjà
3. Ne pas réimplémenter ce qui est déjà en place

### Pendant l'implémentation
- **Toujours écrire des tests** pour chaque contexte et chaque LiveView
- Respecter la structure : `lib/ho_mon_radeau/` (business logic) et `lib/ho_mon_radeau_web/` (web)
- Utiliser LiveView pour les interfaces réactives
- Utiliser `Ecto.Multi` pour les opérations multi-tables
- Code et commentaires en **anglais uniquement**
- Commits atomiques avec messages en anglais

### Format d'un cycle complet
```
1. docker compose run --rm app mix precommit
   → Si ✅ passe : identifier la prochaine feature
   → Si ❌ échoue : corriger d'abord

2. Lire la feature doc

3. Implémenter (migration → schéma → contexte → tests → LiveView/controller)

4. docker compose run --rm app mix precommit
   → Itérer jusqu'à ✅

5. git add + git commit

6. Passer à la feature suivante
```

## Condition d'arrêt

Quand **toutes les features P0 sont implémentées** et que `mix precommit` passe :

```
<promise>MVP COMPLETE</promise>
```

Si tu travailles sur une feature P1 et qu'elle est terminée + precommit passe :

```
<promise>FEATURE COMPLETE</promise>
```

## Notes importantes

- Les commandes s'exécutent dans Docker : `docker compose run --rm app mix...`
- La base de données est PostgreSQL dans Docker (`db` service)
- Mailcatcher est disponible sur le port 1025 pour les emails de dev
- Ne jamais utiliser `--no-verify` sur les commits
- Utiliser `current_scope.user` (jamais `current_user`) dans les templates Phoenix 1.8
