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
1. All services run via Docker Compose
2. Database accessible locally (port forward optional, see docker-compose.yml)
3. Use mailcatcher for email testing in development
4. LiveView for minimal frontend interactions

### Stack
- **Language:** Elixir (latest stable)
- **Framework:** Phoenix (latest stable)
- **Database:** PostgreSQL 16
- **Auth:** phx.gen.auth (email/password with verification)
- **Frontend:** Phoenix LiveView (minimal JS)
- **Deployment:** Fly.io

### Personal Notes
- Keep personal TODOs in `todo_personnel.md` (git-ignored)

## Getting Started

```bash
# Start all services
docker-compose up

# Access application
http://localhost:4000

# Access mailcatcher
http://localhost:1080
```

## Deployment

Deploy to Fly.io:
```bash
fly deploy
```

## Configuration

Environment variables are managed through:
- `.env` (local development, git-ignored)
- Fly.io secrets (production)
