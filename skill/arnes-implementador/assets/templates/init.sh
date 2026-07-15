#!/usr/bin/env bash
# init.sh — Arranque + verificación de línea base del arnés. Adapta INSTALL/VERIFY/START al repo real.
# Si la verificación falla, DETENTE y arregla la base ANTES de cualquier feature.
set -euo pipefail
INSTALL_CMD="${INSTALL_CMD:-}"   # ej: pnpm install | npm ci | pip install -r requirements.txt
VERIFY_CMD="${VERIFY_CMD:-}"     # ej: pnpm check && pnpm test | pytest -q | go test ./...
START_CMD="${START_CMD:-}"       # ej: pnpm dev | uvicorn app:app --reload
cd "$(dirname "$0")"; echo "== $(pwd) =="
detect(){
  if [ -f package.json ]; then local pm=npm; [ -f pnpm-lock.yaml ]&&pm=pnpm; [ -f yarn.lock ]&&pm=yarn
    [ -z "$INSTALL_CMD" ]&&{ [ "$pm" = npm ]&&INSTALL_CMD="npm ci || npm install"||INSTALL_CMD="$pm install"; }
    [ -z "$VERIFY_CMD" ]&&{ grep -q '"check"' package.json&&VERIFY_CMD="$pm run check && $pm test"||VERIFY_CMD="npx tsc --noEmit; $pm test --if-present"; }
    [ -z "$START_CMD" ]&&START_CMD="$pm run dev"; return; fi
  if [ -f pyproject.toml ]||[ -f requirements.txt ]; then
    [ -z "$INSTALL_CMD" ]&&{ [ -f requirements.txt ]&&INSTALL_CMD="pip install -r requirements.txt"||INSTALL_CMD="pip install -e ."; }
    [ -z "$VERIFY_CMD" ]&&VERIFY_CMD="ruff check . || true; pytest -q"; [ -z "$START_CMD" ]&&START_CMD="python -m app"; return; fi
  if [ -f go.mod ]; then [ -z "$INSTALL_CMD" ]&&INSTALL_CMD="go mod download"; [ -z "$VERIFY_CMD" ]&&VERIFY_CMD="go vet ./... && go test ./..."; [ -z "$START_CMD" ]&&START_CMD="go run ."; return; fi
  if [ -f Cargo.toml ]; then [ -z "$INSTALL_CMD" ]&&INSTALL_CMD="cargo fetch"; [ -z "$VERIFY_CMD" ]&&VERIFY_CMD="cargo clippy -- -D warnings && cargo test"; [ -z "$START_CMD" ]&&START_CMD="cargo run"; return; fi
}
detect
[ -z "$VERIFY_CMD" ]&&{ echo "!! Define INSTALL_CMD/VERIFY_CMD/START_CMD arriba." >&2; exit 1; }
echo "install: $INSTALL_CMD"; echo "verify : $VERIFY_CMD"; echo "start  : $START_CMD"
echo "== install =="; eval "$INSTALL_CMD"
echo "== verify (línea base) =="; eval "$VERIFY_CMD"
echo "== OK. arranque: $START_CMD =="
[ "${RUN_START_COMMAND:-0}" = "1" ]&&eval "$START_CMD" || true
