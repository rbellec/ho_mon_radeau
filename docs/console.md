# Console et manipulation des données

## Ouvrir une console

```bash
# Développement (iex -S mix)
./console.sh

# Production (remote console sur l'app en cours)
./console.sh prod
```

## Commandes release (production, sans Mix)

Ces commandes s'exécutent via `eval`, sans ouvrir de console interactive :

```bash
COMPOSE="docker compose -f docker-compose.prod.yml --env-file .env.prod"
```

### Créer / promouvoir un admin

```bash
$COMPOSE exec app /app/bin/ho_mon_radeau eval \
  'HoMonRadeau.Release.create_admin("admin@example.com")'
```

Si l'email n'existe pas : crée le compte (confirmé, validé, admin) avec un mot de passe aléatoire.
Si l'email existe : promeut l'utilisateur admin + validé.

### Forcer un mot de passe

```bash
$COMPOSE exec app /app/bin/ho_mon_radeau eval \
  'HoMonRadeau.Release.reset_password("user@example.com", "nouveau_mot_de_passe")'
```

### Lancer les migrations

```bash
$COMPOSE run --rm app /app/bin/migrate
```

## Console IEx — manipulations utilisateurs

### Importer les modules nécessaires

```elixir
alias HoMonRadeau.{Accounts, Repo}
alias HoMonRadeau.Accounts.User
```

### Trouver un utilisateur

```elixir
# Par email
user = Accounts.get_user_by_email("email@example.com")

# Par ID
user = Accounts.get_user!(1)

# Lister tous les utilisateurs
Repo.all(User)
```

### Valider un utilisateur (validation équipe d'accueil)

```elixir
user = Accounts.get_user_by_email("email@example.com")
Accounts.validate_user(user)
```

### Invalider un utilisateur

```elixir
user = Accounts.get_user_by_email("email@example.com")
Accounts.invalidate_user(user)
```

### Passer un utilisateur admin

```elixir
user = Accounts.get_user_by_email("email@example.com")
user
|> Ecto.Changeset.change(is_admin: true)
|> Repo.update()
```

### Retirer les droits admin

```elixir
user = Accounts.get_user_by_email("email@example.com")
user
|> Ecto.Changeset.change(is_admin: false)
|> Repo.update()
```

### Confirmer manuellement un email (si besoin)

```elixir
user = Accounts.get_user_by_email("email@example.com")
user
|> User.confirm_changeset()
|> Repo.update()
```

## Console IEx — manipulations radeaux et équipages

### Importer les modules

```elixir
alias HoMonRadeau.{Events, Repo}
```

### Lister les radeaux

```elixir
Events.list_current_edition_rafts()
```

### Voir l'équipage d'un radeau

```elixir
raft = Events.get_raft!(1) |> Events.preload_raft_details()
raft.crew.crew_members
```

## Quitter la console

```elixir
# Ctrl+C deux fois, ou :
System.halt()
```
