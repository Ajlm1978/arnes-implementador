# Adaptadores de stack — detección y comandos reales de verificación

## Orden de autoridad para el stack (de mayor a menor)
1. **Config de herramientas y código**: `drizzle.config.*` (`dialect`), `prisma/schema.prisma` (`provider`),
   `knexfile`, `alembic.ini`/`settings.py` (`ENGINE`), `docker-compose.yml` (imagen de DB), esquema de
   `DATABASE_URL` en `.env.example` (`mysql://` vs `postgres://`).
2. **Dependencias**: lockfile/manifiesto — `mysql2`/`pg`/`@supabase/supabase-js`/`psycopg`/`pymysql`. Un
   driver presente y otro ausente es evidencia fuerte.
3. **CI/deploy**: workflows, `Dockerfile`, `railway.toml`, `vercel.json`.
4. **README/docs**: solo intención. Si contradice a 1-3, gana el código y el conflicto es un hallazgo
   (docs desincronizadas). Caso real: README decía "Postgres/Supabase", `drizzle.config` decía `mysql`.
Escribe en el router la fuente de cada dato: `DB: MySQL (drizzle.config.ts → dialect: "mysql"; dep: mysql2)`.

Objetivo: derivar INSTALL / VERIFY / START reales del repo, no de suposiciones. Lee siempre los scripts del
manifiesto antes de decidir. La verificación base debe cubrir, cuando exista: tipos + tests (y lint si hay).

## Node / TypeScript
- Manifiesto: `package.json`. Gestor: `npm` (package-lock), `pnpm` (pnpm-lock.yaml), `yarn` (yarn.lock).
- Respeta la versión fijada en `packageManager`/`engines`. Usa `corepack` si el gestor está pinneado.
- INSTALL: `pnpm install` (o `npm ci`). VERIFY: combina lo que exista →
  `tsc --noEmit` (o `pnpm check`) `&&` `vitest run`/`jest` (o `pnpm test`); añade `eslint .` si hay lint.
  Ojo: un script `check` puede ser SOLO tipos — para Definition of Done agrega los tests explícitamente.
- START: `pnpm dev`. Deploy: revisa `railway.toml`/`vercel.json`/`Dockerfile` y su `healthcheckPath`.

## Python
- Manifiesto: `pyproject.toml`/`requirements.txt`/`setup.py`. INSTALL: `pip install -r requirements.txt` o
  `poetry install`/`uv sync`. VERIFY: `ruff check .` (o flake8) `&&` `mypy .` (si hay) `&&` `pytest -q`.
  START: el entrypoint real (uvicorn/flask/django runserver).

## Go
- `go.mod`. INSTALL: `go mod download`. VERIFY: `go vet ./... && go test ./...` (+ `golangci-lint run` si hay). START: `go run .`.

## Rust
- `Cargo.toml`. INSTALL: `cargo fetch`. VERIFY: `cargo clippy -- -D warnings && cargo test`. START: `cargo run`.

## Bases de datos y verificación (transversal)
- La verificación base NO debe requerir la DB real corriendo. Tests que abren conexión a Postgres/MySQL/TiDB
  son **integration** → sepáralos de `test:unit`. Usa mocks/in-memory para el gate del arnés.
- **MySQL-compatible (TiDB, PlanetScale, MySQL)**: ORMs como Drizzle/Prisma funcionan; migraciones vía la CLI
  del ORM. TiDB es distribuido y wire-compatible con MySQL — trátalo como MySQL para comandos, pero no asumas
  features MySQL exclusivas. La cadena de conexión va en env var (`DATABASE_URL`), documentada en `.env.example`.
- **Postgres (Supabase/Neon/RDS)**: igual — conexión por env var; pooling (Supavisor/pgbouncer) afecta el
  string. Nunca hardcodees credenciales.

## Otros / monorepos
- Java/Kotlin: `mvn -q verify` / `./gradlew build`. .NET: `dotnet test`.
- Monorepo (turbo/nx/pnpm workspaces): usa el runner del monorepo (`turbo run check test`) o filtra por paquete.
- Si nada se detecta: pregunta al usuario los comandos reales; no inventes.

## init.sh (patrón de la plantilla)
Sin `eval`: los comandos son arrays de bash. Los placeholders `‹…›` hacen fallar el script hasta rellenarlos
con los comandos reales del repo (no autodetección a ciegas). `IGNORE_SCRIPTS=1` por defecto y lockfile
congelado (`npm ci`, `pnpm install --frozen-lockfile`) para no ejecutar postinstall ni reescribir el lock en
la primera pasada; Python en venv nuevo. Overrides por env (`INSTALL_CMD`, `VERIFY_CMD`, `START_CMD`) solo
como comando simple, sin operadores de shell. Si VERIFY falla, el script sale ≠0 y la base se arregla antes
de cualquier feature. En Windows ejecútalo con Git Bash o WSL; si el equipo es solo PowerShell, genera un
`init.ps1` equivalente.
