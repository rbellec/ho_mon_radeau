# HoMonRadeaaaUUUUUHOAUUUUOOOOOOO !

Application d'auto-gestion d'événements.

## Development Conventions

### Language Standards
- **Code & Comments:** English only
- **Documentation:** French (in `docs/` directory)
- **Commit messages:** English

### Code Style
- Follow Elixir standard conventions (mix format)
- Use Credo for static analysis
- Module naming: `HoMonRadeau.*`
- Application name: `ho_mon_radeau`

### Project Structure
```
ho_mon_radeau/
├── lib/
│   ├── ho_mon_radeau/          # Business logic
│   └── ho_mon_radeau_web/      # Web interface (Phoenix)
├── docs/
│   └── features/               # Feature documentation (French)
├── config/
├── priv/
└── test/
```

### Development Workflow
1. All services run via Docker Compose (`docker compose`, not `docker-compose`)
2. Database accessible locally (port forward optional, see docker-compose.yml)
3. Use mailcatcher for email testing in development
4. LiveView for minimal frontend interactions

### Stack
- **Language:** Elixir (latest stable)
- **Framework:** Phoenix (latest stable)
- **Database:** PostgreSQL 16
- **Auth:** phx.gen.auth (email/password with verification)
- **Frontend:** Phoenix LiveView (minimal JS)
- **Deployment:** VPS (Ionos) via Docker Compose + Traefik

### Personal Notes
- Keep personal TODOs in `todo_personnel.md` (git-ignored)

## Getting Started

```bash
# Start all services
docker compose up

# Access application
http://localhost:4000

# Access mailcatcher
http://localhost:1080
```

## Useful Commands

```bash
# Full precommit (format + credo + tests)
docker compose run --rm -e MIX_ENV=test app mix precommit

# Tests only
docker compose run --rm -e MIX_ENV=test app mix test

# Single test file
docker compose run --rm -e MIX_ENV=test app mix test test/path/to_test.exs

# Migrations
docker compose run --rm app mix ecto.migrate
```

## Deployment

Deploy via VPS:
1. `git push`
2. SSH to VPS, run `./deploy.sh`

Never edit files directly on the VPS (except `.env.prod`).

## Configuration

Environment variables are managed through:
- `.env` (local development, git-ignored)
- `.env.prod` on the VPS (production)

## Gotchas
- Always run mix commands via `docker compose run`, never directly
- Never use `cd` in bash commands — the working directory is already the project root
- Use `docker compose`, not `docker-compose`
