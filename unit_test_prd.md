# Plan de Tests Unitaires

## Resume

### Etat actuel de la couverture

Le projet dispose de **15 fichiers de test** couvrant partiellement **26 modules business logic** et **35 modules web**. La couverture est correcte pour le contexte `Accounts` (authentification) et acceptable pour `Events` (editions, roles, departs, equipes transverses), mais plusieurs pans importants manquent de tests :

- **Schemas** : aucun test unitaire direct sur les changesets (tous testes indirectement via les contextes)
- **Events (rafts, crews, join requests, registration forms, raft links)** : non testes
- **Storage** : aucun test
- **Notifiers** : aucun test
- **LiveViews** : seuls ProfileLive, Admin.RaftLive.Index et Admin.TransverseTeamLive sont testes. Il manque 11 LiveViews.
- **Controllers** : bonne couverture pour auth, mais pas pour les cas limites

### Statistiques

| Categorie | Modules | Modules testes | Couverture |
|---|---|---|---|
| Business Logic (contexts) | 4 | 4 | Partielle |
| Schemas | 12 | 0 (indirect) | Manquante |
| Notifiers | 2 | 0 | Manquante |
| Storage | 1 | 0 | Manquante |
| Controllers | 6 | 4 | Bonne |
| LiveViews | 14 | 3 | Faible |
| Auth (plugs + on_mount) | 1 | 1 | Bonne |

---

## Tests Existants

| Fichier de test | Ce qu'il couvre |
|---|---|
| `test/ho_mon_radeau/accounts_test.exs` | get_user_by_email, get_user_by_email_and_password, get_user!, register_user, sudo_mode?, change_user_email, deliver_user_update_email_instructions, update_user_email, change_user_password, update_user_password, generate_user_session_token, get_user_by_session_token, get_user_by_magic_link_token, login_user_by_magic_link, delete_user_session_token, deliver_login_instructions, User inspect |
| `test/ho_mon_radeau/events_test.exs` | Editions (CRUD, current, dates), crew member roles (update_member_roles, set_captain, get_captain, remove_captain, get_roles_summary), crew departures (leave_crew, list_crew_departures), transverse teams (CRUD, members, team type check) |
| `test/ho_mon_radeau/cuf_test.exs` | CUF settings, create_declaration, validate_declaration, get_crew_cuf_summary, get_participant_stats |
| `test/ho_mon_radeau/drums_test.exs` | Drum settings, create/update/validate drum requests, get_crew_summary, get_pending_request |
| `test/ho_mon_radeau_web/user_auth_test.exs` | log_in_user, log_out_user, fetch_current_scope_for_user, require_sudo_mode, redirect_if_user_is_authenticated, require_authenticated_user |
| `test/ho_mon_radeau_web/controllers/page_controller_test.exs` | GET / |
| `test/ho_mon_radeau_web/controllers/user_registration_controller_test.exs` | GET/POST /users/register |
| `test/ho_mon_radeau_web/controllers/user_session_controller_test.exs` | GET/POST /users/log-in, magic link, DELETE /users/log-out |
| `test/ho_mon_radeau_web/controllers/user_settings_controller_test.exs` | GET/PUT /users/settings, confirm-email |
| `test/ho_mon_radeau_web/controllers/error_json_test.exs` | 404/500 JSON rendering |
| `test/ho_mon_radeau_web/controllers/error_html_test.exs` | 404/500 HTML rendering |
| `test/ho_mon_radeau_web/live/profile_live_test.exs` | Profile rendering, validation badge, name warning, form validation, profile update, crew membership display |
| `test/ho_mon_radeau_web/live/admin/raft_live_test.exs` | Admin raft list, validate/invalidate raft, filter by status/name, non-admin redirect |
| `test/ho_mon_radeau_web/live/admin/transverse_team_live_test.exs` | Team list, create, delete, member management, coordinator toggle |

---

## Tests Manquants ou Insuffisants

### Module: HoMonRadeau.Accounts

- **Fichier:** `lib/ho_mon_radeau/accounts.ex`
- **Test existant:** `test/ho_mon_radeau/accounts_test.exs`
- **Tests a ajouter:**
  - [ ] `get_user/1` - retourne nil quand l'utilisateur n'existe pas
  - [ ] `get_user/1` - retourne l'utilisateur quand il existe
  - [ ] `change_user_registration/2` - retourne un changeset valide sans hashage de mot de passe
  - [ ] `display_name/1` - retourne le nickname quand il est present
  - [ ] `display_name/1` - retourne "matelot sans pseudonyme" quand nickname est nil
  - [ ] `display_name/1` - retourne "matelot sans pseudonyme" quand nickname est vide
  - [ ] `validate_user/1` - marque l'utilisateur comme valide
  - [ ] `invalidate_user/1` - revoque la validation
  - [ ] `list_pending_validation_users/0` - retourne les utilisateurs confirmes non valides
  - [ ] `list_pending_validation_users/0` - ne retourne pas les utilisateurs non confirmes
  - [ ] `list_validated_users/0` - retourne uniquement les utilisateurs valides, tries par nickname
  - [ ] `list_all_users/0` - retourne tous les utilisateurs confirmes
  - [ ] `search_users/1` - retourne les utilisateurs correspondant a l'email
  - [ ] `search_users/1` - retourne les utilisateurs correspondant au nickname
  - [ ] `search_users/1` - ne retourne pas les utilisateurs non confirmes
  - [ ] `search_users/1` - limite a 10 resultats
  - [ ] `can_participate?/1` - retourne false si non valide
  - [ ] `can_participate?/1` - retourne false si first_name est nil ou vide
  - [ ] `can_participate?/1` - retourne false si last_name est nil ou vide
  - [ ] `can_participate?/1` - retourne true si valide avec prenom et nom
  - [ ] `update_user_profile/2` - met a jour le profil avec des donnees valides
  - [ ] `update_user_profile/2` - echoue avec des donnees invalides (nickname trop court)
  - [ ] `change_user_profile/2` - retourne un changeset pour le profil

---

### Module: HoMonRadeau.Accounts.User

- **Fichier:** `lib/ho_mon_radeau/accounts/user.ex`
- **Test existant:** Aucun test direct (teste indirectement via Accounts)
- **Tests a ajouter:**
  - [ ] `email_changeset/3` - valide le format d'email (@ requis, pas d'espaces)
  - [ ] `email_changeset/3` - valide la longueur max (160 caracteres)
  - [ ] `email_changeset/3` - verifie que l'email a change quand validate_unique est true
  - [ ] `email_changeset/3` - ne verifie pas l'unicite quand validate_unique est false
  - [ ] `password_changeset/3` - valide la longueur min (6) et max (72)
  - [ ] `password_changeset/3` - valide la confirmation du mot de passe
  - [ ] `password_changeset/3` - hashe le mot de passe quand hash_password est true
  - [ ] `password_changeset/3` - ne hashe pas quand hash_password est false
  - [ ] `registration_changeset/3` - accepte email, password et nickname
  - [ ] `registration_changeset/3` - valide le nickname (min 2, max 50 caracteres)
  - [ ] `profile_changeset/2` - valide nickname, first_name, last_name, phone_number
  - [ ] `profile_changeset/2` - valide le format du numero de telephone
  - [ ] `profile_changeset/2` - rejette un numero de telephone avec des caracteres invalides
  - [ ] `validation_changeset/2` - cast le champ validated
  - [ ] `confirm_changeset/1` - definit confirmed_at a maintenant
  - [ ] `valid_password?/2` - retourne true pour un mot de passe valide
  - [ ] `valid_password?/2` - retourne false pour un mot de passe invalide
  - [ ] `valid_password?/2` - retourne false quand pas de hashed_password (timing attack protection)

---

### Module: HoMonRadeau.Accounts.UserToken

- **Fichier:** `lib/ho_mon_radeau/accounts/user_token.ex`
- **Test existant:** Aucun test direct (teste indirectement via Accounts)
- **Tests a ajouter:**
  - [ ] `build_session_token/1` - genere un token avec contexte "session"
  - [ ] `build_session_token/1` - utilise authenticated_at de l'utilisateur si present
  - [ ] `build_session_token/1` - utilise DateTime.utc_now si authenticated_at est nil
  - [ ] `verify_session_token_query/1` - retourne une query valide
  - [ ] `build_email_token/2` - genere un token hashe avec le contexte fourni
  - [ ] `verify_magic_link_token_query/1` - retourne :error pour un token invalide (base64)
  - [ ] `verify_magic_link_token_query/1` - retourne une query pour un token valide
  - [ ] `verify_change_email_token_query/2` - retourne :error pour un token invalide
  - [ ] `verify_change_email_token_query/2` - retourne une query pour un token valide avec contexte "change:*"

---

### Module: HoMonRadeau.Accounts.UserNotifier

- **Fichier:** `lib/ho_mon_radeau/accounts/user_notifier.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] `deliver_update_email_instructions/2` - envoie un email avec l'URL de mise a jour
  - [ ] `deliver_login_instructions/2` - envoie des instructions de confirmation pour un utilisateur non confirme
  - [ ] `deliver_login_instructions/2` - envoie des instructions magic link pour un utilisateur confirme
  - [ ] Verifier que l'expediteur est configure correctement ("Ho Mon Radeau")

---

### Module: HoMonRadeau.Accounts.Scope

- **Fichier:** `lib/ho_mon_radeau/accounts/scope.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `for_user/1` - retourne un Scope avec l'utilisateur quand un User est passe
  - [ ] `for_user/1` - retourne nil quand nil est passe

---

### Module: HoMonRadeau.Events

- **Fichier:** `lib/ho_mon_radeau/events.ex`
- **Test existant:** `test/ho_mon_radeau/events_test.exs` (partiel)
- **Tests a ajouter:**

  #### Rafts (non testes)
  - [ ] `list_rafts/1` - retourne les radeaux avec le nombre de membres
  - [ ] `list_rafts/1` - trie par valide puis par nom
  - [ ] `list_rafts/1` - retourne une liste vide pour une edition sans radeaux
  - [ ] `list_current_edition_rafts/0` - retourne [] quand pas d'edition courante
  - [ ] `list_current_edition_rafts/0` - retourne les radeaux de l'edition courante
  - [ ] `get_raft!/1` - retourne le radeau avec crew, edition et links precharges
  - [ ] `get_raft!/1` - leve une erreur si le radeau n'existe pas
  - [ ] `get_raft_by_slug/2` - retourne le radeau par slug et edition
  - [ ] `get_raft_by_slug/2` - retourne nil si le slug n'existe pas
  - [ ] `preload_raft_details/1` - precharge edition, links et crew avec membres
  - [ ] `create_raft_with_crew/2` - cree un radeau, un equipage et ajoute le createur comme manager
  - [ ] `create_raft_with_crew/2` - retourne :no_current_edition quand pas d'edition
  - [ ] `create_raft_with_crew/3` - cree avec un edition_id specifique
  - [ ] `create_raft_with_crew/2` - echoue avec des attributs invalides (nom manquant)
  - [ ] `create_raft_with_crew/2` - echoue avec un nom duplique dans la meme edition
  - [ ] `update_raft/2` - met a jour la description du radeau
  - [ ] `change_raft/2` - retourne un changeset
  - [ ] `validate_raft/2` - marque un radeau comme valide avec la date et l'admin
  - [ ] `invalidate_raft/1` - revoque la validation
  - [ ] `list_admin_rafts/0` - retourne les radeaux avec le nombre de membres et le capitaine
  - [ ] `list_admin_rafts/1` - filtre par nom
  - [ ] `list_admin_rafts/1` - filtre par statut "validated" et "proposed"
  - [ ] `is_crew_manager?/2` - retourne true pour un manager
  - [ ] `is_crew_manager?/2` - retourne false pour un non-manager

  #### Crews (non testes)
  - [ ] `get_crew_by_raft/1` - retourne l'equipage avec les membres
  - [ ] `get_crew_by_raft/1` - retourne nil si pas d'equipage
  - [ ] `get_user_crew/1` - retourne l'equipage de l'utilisateur pour l'edition courante
  - [ ] `get_user_crew/1` - retourne nil si l'utilisateur n'est dans aucun equipage
  - [ ] `get_user_crew/1` - retourne nil quand pas d'edition courante
  - [ ] `user_has_crew?/1` - retourne true/false correctement

  #### Crew Members (partiellement testes)
  - [ ] `list_crew_members/1` - retourne les membres tries par manager, capitaine, date
  - [ ] `get_public_crew_members/1` - retourne seulement les membres avec un nickname
  - [ ] `count_secret_members/1` - compte les membres sans nickname ou photo privee
  - [ ] `count_crew_members/1` - compte le nombre total de membres
  - [ ] `add_crew_member/3` - ajoute un membre a un equipage
  - [ ] `add_crew_member/3` - echoue si deja membre (unique constraint)
  - [ ] `remove_crew_member/2` - retire un membre
  - [ ] `get_crew_member/2` - retourne le membre avec l'utilisateur precharge
  - [ ] `get_crew_member/2` - retourne nil si pas membre
  - [ ] `promote_to_manager/2` - promeut un membre en manager
  - [ ] `promote_to_manager/2` - retourne :not_found si membre inexistant
  - [ ] `demote_from_manager/2` - retrograde un manager
  - [ ] `demote_from_manager/2` - retourne :not_found si membre inexistant
  - [ ] `is_manager?/2` - retourne true/false correctement
  - [ ] `get_crew_managers/1` - retourne tous les managers d'un equipage
  - [ ] `update_member_roles/2` - met a jour les roles (deja teste mais manque mixed valid/invalid)

  #### Join Requests (non testes)
  - [ ] `create_join_request/3` - cree une demande si l'utilisateur n'est pas dans un equipage
  - [ ] `create_join_request/3` - retourne :already_in_crew si deja dans un equipage
  - [ ] `create_join_request/3` - echoue si demande pending deja existante (unique constraint)
  - [ ] `get_join_request!/1` - retourne la demande avec user et crew precharges
  - [ ] `list_pending_join_requests/1` - retourne les demandes pending triees par date
  - [ ] `list_user_join_requests/1` - retourne toutes les demandes d'un utilisateur
  - [ ] `accept_join_request/2` - ajoute le membre et annule les autres demandes pending
  - [ ] `accept_join_request/2` - retourne :user_not_validated si l'utilisateur n'est pas valide
  - [ ] `reject_join_request/2` - rejette la demande avec responded_at
  - [ ] `has_pending_join_request?/2` - retourne true quand une demande pending existe
  - [ ] `has_pending_join_request?/2` - retourne false quand aucune demande pending

  #### Raft Links (non testes)
  - [ ] `list_raft_links/1` - retourne tous les liens tries par position
  - [ ] `create_raft_link/1` - cree un lien avec des attributs valides
  - [ ] `create_raft_link/1` - echoue sans titre ou URL
  - [ ] `create_raft_link/1` - echoue avec une URL invalide
  - [ ] `update_raft_link/2` - met a jour un lien
  - [ ] `delete_raft_link/1` - supprime un lien
  - [ ] `list_public_raft_links/1` - retourne seulement les liens publics
  - [ ] `change_raft_link/2` - retourne un changeset

  #### Registration Forms (non testes)
  - [ ] `get_current_registration_form/2` - retourne la fiche la plus recente
  - [ ] `get_current_registration_form/2` - retourne nil si aucune fiche
  - [ ] `list_user_registration_forms/2` - retourne l'historique des fiches
  - [ ] `get_registration_form!/1` - retourne la fiche avec preloads
  - [ ] `required_form_type/2` - retourne :captain pour un capitaine
  - [ ] `required_form_type/2` - retourne :participant pour un non-capitaine
  - [ ] `required_form_type/2` - retourne nil si pas dans un equipage
  - [ ] `registration_form_status/2` - retourne :missing, :pending, :approved, :rejected
  - [ ] `approve_registration_form/2` - approuve la fiche
  - [ ] `reject_registration_form/3` - rejette avec une raison
  - [ ] `list_pending_registration_forms/1` - retourne les fiches en attente
  - [ ] `list_registration_forms/2` - filtre par statut
  - [ ] `list_registration_forms/2` - filtre par raft_id

---

### Module: HoMonRadeau.Events.Edition

- **Fichier:** `lib/ho_mon_radeau/events/edition.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - valide la presence de year
  - [ ] `changeset/2` - valide year entre 2000 et 3000
  - [ ] `changeset/2` - valide l'unicite de year
  - [ ] `changeset/2` - valide que end_date est apres start_date
  - [ ] `changeset/2` - valide le format URL pour participant_form_url
  - [ ] `changeset/2` - valide le format URL pour captain_form_url
  - [ ] `changeset/2` - accepte des dates nil (optionnelles)

---

### Module: HoMonRadeau.Events.Raft

- **Fichier:** `lib/ho_mon_radeau/events/raft.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert name et edition_id
  - [ ] `changeset/2` - valide la longueur du nom (2-100)
  - [ ] `changeset/2` - valide la longueur de description_short (max 150)
  - [ ] `changeset/2` - genere un slug a partir du nom
  - [ ] `changeset/2` - le slug est en minuscules sans caracteres speciaux
  - [ ] `changeset/2` - valide le format de forum_url
  - [ ] `changeset/2` - ne regenere pas le slug si le nom ne change pas
  - [ ] `validation_changeset/2` - cast validated, validated_at, validated_by_id
  - [ ] `update_changeset/2` - cast description, description_short, forum_url, picture_url
  - [ ] `update_changeset/2` - ne permet pas de changer le nom

---

### Module: HoMonRadeau.Events.Crew

- **Fichier:** `lib/ho_mon_radeau/events/crew.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert raft_id et edition_id
  - [ ] `changeset/2` - enforce unique constraint sur raft_id
  - [ ] `transverse_changeset/2` - requiert name et transverse_type
  - [ ] `transverse_changeset/2` - met is_transverse a true automatiquement
  - [ ] `transverse_changeset/2` - valide l'inclusion de transverse_type dans les types valides
  - [ ] `transverse_changeset/2` - valide la longueur du nom (2-100)
  - [ ] `transverse_types/0` - retourne la liste des types valides

---

### Module: HoMonRadeau.Events.CrewMember

- **Fichier:** `lib/ho_mon_radeau/events/crew_member.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert crew_id et user_id
  - [ ] `changeset/2` - valide l'inclusion de participation_status
  - [ ] `changeset/2` - valide les roles (rejette les roles invalides)
  - [ ] `changeset/2` - met joined_at automatiquement
  - [ ] `changeset/2` - enforce unique constraint sur [crew_id, user_id]
  - [ ] `update_changeset/2` - cast is_manager, is_captain, roles, participation_status
  - [ ] `promote_to_manager_changeset/1` - met is_manager a true
  - [ ] `demote_from_manager_changeset/1` - met is_manager a false
  - [ ] `set_captain_changeset/2` - met is_captain a la valeur donnee
  - [ ] `valid_roles/0` - retourne la combinaison des roles requis et optionnels
  - [ ] `required_roles/0` - retourne lead_construction, cooking, safe_contact
  - [ ] `optional_roles/0` - retourne logistics, music, decoration, other

---

### Module: HoMonRadeau.Events.CrewJoinRequest

- **Fichier:** `lib/ho_mon_radeau/events/crew_join_request.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert crew_id et user_id
  - [ ] `changeset/2` - message est optionnel
  - [ ] `changeset/2` - enforce unique constraint sur pending requests
  - [ ] `response_changeset/2` - met responded_at quand status est "accepted" ou "rejected"
  - [ ] `response_changeset/2` - ne met pas responded_at pour un autre statut
  - [ ] `statuses/0` - retourne pending, accepted, rejected, cancelled

---

### Module: HoMonRadeau.Events.CrewDeparture

- **Fichier:** `lib/ho_mon_radeau/events/crew_departure.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert user_id et crew_id
  - [ ] `changeset/2` - removed_by_id est optionnel
  - [ ] `changeset/2` - cuf_status_at_departure a "none" par defaut
  - [ ] `changeset/2` - was_captain et was_manager a false par defaut

---

### Module: HoMonRadeau.Events.RaftLink

- **Fichier:** `lib/ho_mon_radeau/events/raft_link.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert raft_id, title et url
  - [ ] `changeset/2` - valide la longueur du titre (max 200)
  - [ ] `changeset/2` - valide le format URL (http/https avec host)
  - [ ] `changeset/2` - rejette une URL sans scheme
  - [ ] `changeset/2` - position a 0 par defaut
  - [ ] `changeset/2` - is_public a true par defaut

---

### Module: HoMonRadeau.Events.RegistrationForm

- **Fichier:** `lib/ho_mon_radeau/events/registration_form.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert user_id, edition_id, form_type, file_key, file_name
  - [ ] `changeset/2` - valide form_type dans ["participant", "captain"]
  - [ ] `changeset/2` - rejette un fichier > 10 Mo
  - [ ] `changeset/2` - valide les content_types acceptes (pdf, jpeg, png, gif, webp)
  - [ ] `changeset/2` - rejette un content_type invalide (ex: text/plain)
  - [ ] `changeset/2` - met uploaded_at automatiquement
  - [ ] `approve_changeset/2` - met status a "approved" et reviewed_at
  - [ ] `approve_changeset/2` - efface rejection_reason
  - [ ] `reject_changeset/3` - met status a "rejected" avec le motif
  - [ ] `reject_changeset/3` - requiert rejection_reason
  - [ ] `form_types/0` - retourne ["participant", "captain"]
  - [ ] `statuses/0` - retourne ["pending", "approved", "rejected"]

---

### Module: HoMonRadeau.Events.RegistrationFormNotifier

- **Fichier:** `lib/ho_mon_radeau/events/registration_form_notifier.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] `deliver_form_rejected/2` - envoie un email de rejet a l'utilisateur avec le motif
  - [ ] `deliver_form_rejected_to_managers/4` - envoie un email aux managers avec le nom du radeau
  - [ ] `deliver_form_reminder/3` - envoie un rappel avec la deadline si elle existe
  - [ ] `deliver_form_reminder/3` - envoie un rappel avec "des que possible" sans deadline
  - [ ] `deliver_form_approved/1` - envoie un email de validation

---

### Module: HoMonRadeau.CUF

- **Fichier:** `lib/ho_mon_radeau/cuf.ex`
- **Test existant:** `test/ho_mon_radeau/cuf_test.exs`
- **Tests a ajouter:**
  - [ ] `get_unit_price/0` - retourne le prix unitaire des settings
  - [ ] `change_settings/2` - retourne un changeset pour les settings
  - [ ] `get_pending_declaration/1` - retourne la declaration pending la plus recente
  - [ ] `get_pending_declaration/1` - retourne nil si aucune pending
  - [ ] `get_crew_declarations/1` - retourne toutes les declarations d'un equipage
  - [ ] `list_all_declarations/0` - retourne toutes les declarations avec preloads
  - [ ] `list_all_declarations/1` - filtre par statut
  - [ ] `get_declaration!/1` - retourne la declaration avec crew et raft precharges

---

### Module: HoMonRadeau.CUF.CUFSettings

- **Fichier:** `lib/ho_mon_radeau/cuf/cuf_settings.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert unit_price
  - [ ] `changeset/2` - valide que unit_price > 0
  - [ ] `changeset/2` - cast total_limit, rib_iban, rib_bic

---

### Module: HoMonRadeau.CUF.Declaration

- **Fichier:** `lib/ho_mon_radeau/cuf/declaration.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/3` - requiert participant_count
  - [ ] `changeset/3` - valide participant_count > 0
  - [ ] `changeset/3` - calcule total_amount = participant_count * unit_price
  - [ ] `changeset/3` - stocke le unit_price dans la declaration
  - [ ] `validation_changeset/2` - met status a "validated" avec validated_at et validated_by_id

---

### Module: HoMonRadeau.Drums

- **Fichier:** `lib/ho_mon_radeau/drums.ex`
- **Test existant:** `test/ho_mon_radeau/drums_test.exs`
- **Tests a ajouter:**
  - [ ] `get_unit_price/0` - retourne le prix unitaire des settings
  - [ ] `change_settings/2` - retourne un changeset
  - [ ] `get_crew_requests/1` - retourne toutes les demandes d'un equipage
  - [ ] `list_all_requests/0` - retourne toutes les demandes avec preloads
  - [ ] `list_all_requests/1` - filtre par statut
  - [ ] `get_request!/1` - retourne la demande avec preloads
  - [ ] `change_drum_request/2` - retourne un changeset

---

### Module: HoMonRadeau.Drums.DrumRequest

- **Fichier:** `lib/ho_mon_radeau/drums/drum_request.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/3` - requiert quantity
  - [ ] `changeset/3` - valide quantity >= 0
  - [ ] `changeset/3` - calcule total_amount = quantity * unit_price
  - [ ] `changeset/3` - stocke le unit_price
  - [ ] `payment_changeset/2` - met status a "paid" avec paid_at et validated_by_id

---

### Module: HoMonRadeau.Drums.DrumSettings

- **Fichier:** `lib/ho_mon_radeau/drums/drum_settings.ex`
- **Test existant:** Aucun test direct
- **Tests a ajouter:**
  - [ ] `changeset/2` - requiert unit_price
  - [ ] `changeset/2` - valide que unit_price > 0
  - [ ] `changeset/2` - cast rib_iban et rib_bic

---

### Module: HoMonRadeau.Storage

- **Fichier:** `lib/ho_mon_radeau/storage.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] `upload/3` (local) - cree le fichier sur le disque
  - [ ] `upload/3` - retourne :storage_disabled quand desactive
  - [ ] `download/1` (local) - lit le contenu du fichier
  - [ ] `download/1` - retourne :storage_disabled quand desactive
  - [ ] `delete/1` (local) - supprime le fichier
  - [ ] `delete/1` (local) - retourne :ok si le fichier n'existe pas (enoent)
  - [ ] `delete/1` - retourne :storage_disabled quand desactive
  - [ ] `get_url/2` (local) - retourne un chemin relatif pour priv/static
  - [ ] `get_url/2` - retourne :storage_disabled quand desactive
  - [ ] `enabled?/0` - retourne true quand active, false sinon
  - [ ] `registration_form_key/3` - genere une cle avec edition_id, user_id et filename
  - [ ] `registration_form_key/3` - sanitize le nom de fichier (caracteres speciaux remplaces)
  - [ ] `registration_form_key/3` - tronque le nom a 100 caracteres

---

### Module: HoMonRadeauWeb.UserAuth (on_mount hooks)

- **Fichier:** `lib/ho_mon_radeau_web/user_auth.ex`
- **Test existant:** `test/ho_mon_radeau_web/user_auth_test.exs` (plugs seulement)
- **Tests a ajouter:**
  - [ ] `on_mount(:mount_current_scope)` - assigne current_scope avec l'utilisateur du token de session
  - [ ] `on_mount(:mount_current_scope)` - assigne current_scope nil sans token
  - [ ] `on_mount(:require_authenticated_user)` - continue si l'utilisateur est authentifie
  - [ ] `on_mount(:require_authenticated_user)` - redirige vers login si non authentifie
  - [ ] `on_mount(:require_validated_user)` - continue si l'utilisateur est valide
  - [ ] `on_mount(:require_validated_user)` - redirige si l'utilisateur n'est pas valide
  - [ ] `on_mount(:require_admin_user)` - continue si l'utilisateur est admin
  - [ ] `on_mount(:require_admin_user)` - redirige si l'utilisateur n'est pas admin
  - [ ] `require_validated_user/2` (plug) - laisse passer un utilisateur valide
  - [ ] `require_validated_user/2` (plug) - redirige un utilisateur non valide
  - [ ] `require_admin_user/2` (plug) - laisse passer un admin
  - [ ] `require_admin_user/2` (plug) - redirige un non-admin
  - [ ] `signed_in_path/1` - redirige vers /mon-radeau si l'utilisateur a un equipage
  - [ ] `signed_in_path/1` - redirige vers /radeaux si l'utilisateur n'a pas d'equipage

---

### Module: HoMonRadeauWeb.RaftLive.Index

- **Fichier:** `lib/ho_mon_radeau_web/live/raft_live/index.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche la liste des radeaux quand une edition existe
  - [ ] Affiche "Aucune edition en cours" quand pas d'edition
  - [ ] Affiche "Aucun radeau pour le moment" quand la liste est vide
  - [ ] Affiche le bouton "Creer un radeau" pour un utilisateur valide sans equipage
  - [ ] Cache le bouton "Creer" pour un utilisateur non valide
  - [ ] Cache le bouton "Creer" pour un utilisateur deja dans un equipage
  - [ ] Affiche le lien vers "mon radeau" pour un utilisateur avec equipage
  - [ ] L'evenement toggle_view bascule entre :grid et :list
  - [ ] Affiche le warning de validation pour un utilisateur non valide
  - [ ] Accessible sans connexion (page publique)

---

### Module: HoMonRadeauWeb.RaftLive.Show

- **Fichier:** `lib/ho_mon_radeau_web/live/raft_live/show.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche les details du radeau (nom, description, membres)
  - [ ] Redirige avec flash d'erreur si le slug n'existe pas
  - [ ] Redirige si pas d'edition courante
  - [ ] Affiche les liens publics du radeau
  - [ ] Affiche le formulaire "Demander a rejoindre" pour un utilisateur valide sans equipage
  - [ ] Affiche "Vous etes membre" pour un membre de l'equipage
  - [ ] Affiche "Votre demande est en attente" si une demande pending existe
  - [ ] L'evenement request_join cree une demande de jointure
  - [ ] L'evenement request_join affiche une erreur si deja dans un equipage
  - [ ] Affiche "Connectez-vous" pour un visiteur non connecte
  - [ ] Affiche le badge "Valide" pour un radeau valide

---

### Module: HoMonRadeauWeb.RaftLive.New

- **Fichier:** `lib/ho_mon_radeau_web/live/raft_live/new.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche le formulaire de creation de radeau
  - [ ] Redirige vers /mon-radeau si l'utilisateur a deja un equipage
  - [ ] L'evenement validate met a jour le formulaire avec les erreurs
  - [ ] L'evenement save cree un radeau et redirige vers /mon-radeau
  - [ ] L'evenement save affiche une erreur si pas d'edition courante
  - [ ] L'evenement save affiche les erreurs du changeset
  - [ ] Necessite un utilisateur valide (requiert validation)

---

### Module: HoMonRadeauWeb.RaftLive.MyCrew

- **Fichier:** `lib/ho_mon_radeau_web/live/raft_live/my_crew.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Redirige vers /radeaux si l'utilisateur n'a pas d'equipage
  - [ ] Affiche les informations du radeau et de l'equipage
  - [ ] Affiche les membres avec leurs roles
  - [ ] L'evenement edit_info active le mode edition (si manager)
  - [ ] L'evenement save_info met a jour les infos du radeau
  - [ ] L'evenement accept_request accepte une demande de jointure
  - [ ] L'evenement reject_request rejette une demande de jointure
  - [ ] L'evenement remove_member retire un membre
  - [ ] L'evenement set_captain definit un capitaine
  - [ ] L'evenement promote_manager promeut un membre
  - [ ] L'evenement demote_manager retrograde un manager
  - [ ] L'evenement update_roles met a jour les roles
  - [ ] L'evenement leave quitte l'equipage
  - [ ] Affiche les demandes de jointure pending pour les managers
  - [ ] Cache les actions de gestion pour les non-managers
  - [ ] Affiche le resume des roles
  - [ ] Gestion des liens du radeau (ajout, modification, suppression)
  - [ ] Gestion des bidons (demande, mise a jour)
  - [ ] Gestion CUF (declaration, selection des participants)

---

### Module: HoMonRadeauWeb.RegistrationFormLive.Index

- **Fichier:** `lib/ho_mon_radeau_web/live/registration_form_live/index.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Redirige si pas d'edition courante
  - [ ] Affiche le message "rejoindre un equipage" si l'utilisateur n'est dans aucun equipage
  - [ ] Affiche les instructions et le lien de telechargement du formulaire
  - [ ] Affiche le statut actuel (missing, pending, approved, rejected)
  - [ ] Affiche le motif de rejet si le formulaire a ete rejete
  - [ ] L'evenement save upload le fichier et cree un enregistrement
  - [ ] L'evenement cancel-upload annule l'upload en cours

---

### Module: HoMonRadeauWeb.Admin.UserLive.Index

- **Fichier:** `lib/ho_mon_radeau_web/live/admin/user_live/index.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche la liste des utilisateurs
  - [ ] Filtre les utilisateurs par statut (all, pending, validated)
  - [ ] L'evenement validate valide un utilisateur
  - [ ] L'evenement invalidate invalide un utilisateur
  - [ ] Recherche d'utilisateur par email ou nickname
  - [ ] Redirige les non-admins

---

### Module: HoMonRadeauWeb.Admin.UserLive.Show

- **Fichier:** `lib/ho_mon_radeau_web/live/admin/user_live/show.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche les details de l'utilisateur
  - [ ] Affiche l'equipage de l'utilisateur s'il en a un
  - [ ] Affiche le statut de la fiche d'inscription
  - [ ] Redirige les non-admins

---

### Module: HoMonRadeauWeb.Admin.RegistrationFormLive.Index

- **Fichier:** `lib/ho_mon_radeau_web/live/admin/registration_form_live/index.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche la liste des fiches d'inscription
  - [ ] Filtre par statut (pending, approved, rejected)
  - [ ] Affiche les statistiques par radeau
  - [ ] Redirige si pas d'edition courante
  - [ ] Redirige les non-admins

---

### Module: HoMonRadeauWeb.Admin.RegistrationFormLive.Show

- **Fichier:** `lib/ho_mon_radeau_web/live/admin/registration_form_live/show.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche les details de la fiche
  - [ ] L'evenement approve approuve la fiche et envoie un email
  - [ ] L'evenement reject rejette la fiche avec un motif et envoie un email
  - [ ] Affiche le lien de telechargement du fichier
  - [ ] Redirige les non-admins

---

### Module: HoMonRadeauWeb.Admin.DrumsLive.Index

- **Fichier:** `lib/ho_mon_radeau_web/live/admin/drums_live/index.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche la liste des demandes de bidons
  - [ ] Filtre par statut (pending, paid)
  - [ ] L'evenement validate_payment valide un paiement
  - [ ] L'evenement update_settings met a jour les parametres
  - [ ] Redirige les non-admins

---

### Module: HoMonRadeauWeb.Admin.CUFLive.Index

- **Fichier:** `lib/ho_mon_radeau_web/live/admin/cuf_live/index.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche la liste des declarations CUF
  - [ ] Affiche les statistiques globales
  - [ ] Filtre par statut (pending, validated)
  - [ ] L'evenement validate_declaration valide une declaration
  - [ ] L'evenement update_settings met a jour les parametres
  - [ ] Redirige les non-admins

---

### Module: HoMonRadeauWeb.Admin.DeparturesLive

- **Fichier:** `lib/ho_mon_radeau_web/live/admin/departures_live.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] Affiche la liste des departs
  - [ ] Filtre par statut CUF
  - [ ] Affiche le nombre de departs
  - [ ] Redirige les non-admins

---

### Module: HoMonRadeauWeb.PageController

- **Fichier:** `lib/ho_mon_radeau_web/controllers/page_controller.ex`
- **Test existant:** `test/ho_mon_radeau_web/controllers/page_controller_test.exs`
- **Tests a ajouter:**
  - [ ] Affiche les radeaux de l'edition courante sur la page d'accueil
  - [ ] Gere le cas sans edition courante

---

### Module: HoMonRadeauWeb.KaffyConfig

- **Fichier:** `lib/ho_mon_radeau_web/kaffy_config.ex`
- **Test existant:** Aucun
- **Tests a ajouter:**
  - [ ] `create_resources/1` - retourne la configuration avec les bons schemas

---

## Priorites de mise en oeuvre

### Priorite 1 - Impact eleve, effort faible (tests unitaires purs)
1. Tests de changesets pour tous les schemas (User, Edition, Raft, Crew, CrewMember, etc.)
2. Tests pour `Accounts.display_name/1`, `can_participate?/1`
3. Tests pour `Storage` (local adapter)
4. Tests pour `Accounts.Scope`

### Priorite 2 - Impact eleve, effort moyen (logique metier)
1. Tests pour Events: rafts, crews, crew members (CRUD)
2. Tests pour Events: join requests (workflow complet)
3. Tests pour Events: raft links
4. Tests pour Events: registration forms

### Priorite 3 - Impact moyen, effort moyen (LiveViews publiques)
1. Tests pour RaftLive.Index
2. Tests pour RaftLive.Show
3. Tests pour RaftLive.New
4. Tests pour RaftLive.MyCrew
5. Tests pour RegistrationFormLive.Index

### Priorite 4 - Impact moyen, effort eleve (LiveViews admin)
1. Tests pour Admin.UserLive.Index/Show
2. Tests pour Admin.RegistrationFormLive.Index/Show
3. Tests pour Admin.DrumsLive.Index
4. Tests pour Admin.CUFLive.Index
5. Tests pour Admin.DeparturesLive

### Priorite 5 - Impact faible (notifiers, config)
1. Tests pour UserNotifier
2. Tests pour RegistrationFormNotifier
3. Tests pour on_mount hooks
4. Tests pour KaffyConfig

---

## Fixtures manquantes

Pour implementer ces tests, il faudra creer des fixtures supplementaires dans `test/support/fixtures/` :

- **`events_fixtures.ex`** : edition_fixture, raft_fixture, crew_fixture, crew_member_fixture, join_request_fixture, raft_link_fixture, registration_form_fixture
- **`cuf_fixtures.ex`** : declaration_fixture, cuf_settings_fixture
- **`drums_fixtures.ex`** : drum_request_fixture, drum_settings_fixture
