#!/usr/bin/env bash
# init.sh — Arranque + verificación de línea base del arnés.
# Comandos EXPLÍCITOS como arrays (sin eval). Rellena los ‹…› con los comandos REALES del repo
# (léelos de los scripts del manifiesto). El script falla mientras queden placeholders.
# Si VERIFY falla: DETENTE y arregla la base antes de cualquier feature.
set -euo pipefail
cd "$(dirname "$0")"; echo "== $(pwd) =="

# 1 = no ejecutar postinstall/scripts de dependencias (repo no verificado). Pon 0 solo si confías en el repo.
IGNORE_SCRIPTS="${IGNORE_SCRIPTS:-1}"
ign=(); [ "$IGNORE_SCRIPTS" = 1 ] && ign=(--ignore-scripts)

# ── Rellenar (ejemplos: pnpm install --frozen-lockfile | npm ci | pip install -r requirements.txt) ──
INSTALL=(‹INSTALL real›)
VERIFY=(‹VERIFY real, ej: pnpm check›)        # tipos/lint
TESTS=(‹TESTS real, ej: pnpm test:unit›)      # tests deterministas (offline)
START=(‹START real, ej: pnpm dev›)

# Override por env: UN comando simple (sin ; && | $( ) `)
override(){ local v="${!1:-}"; [ -z "$v" ] && return 0
  case "$v" in *';'*|*'&'*|*'|'*|*'$('*|*'`'*|*'>'*|*'<'*) echo "!! $1 contiene operadores de shell; edita los arrays en init.sh" >&2; exit 2;; esac
  read -r -a "$2" <<< "$v"; }
override INSTALL_CMD INSTALL; override VERIFY_CMD VERIFY; override TESTS_CMD TESTS; override START_CMD START

case "${INSTALL[*]} ${VERIFY[*]} ${TESTS[*]} ${START[*]}" in *‹*) echo "!! init.sh tiene placeholders ‹…› sin rellenar" >&2; exit 2;; esac

# Node: añade --ignore-scripts al install si aplica
case "${INSTALL[0]:-}" in npm|pnpm|yarn) INSTALL+=("${ign[@]}");; esac
# Python: venv nuevo, nunca global
if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  [ -d .venv ] || python3 -m venv .venv
  # shellcheck disable=SC1091
  . .venv/bin/activate
fi

echo "install: ${INSTALL[*]}"; echo "verify : ${VERIFY[*]}"; echo "tests  : ${TESTS[*]}"; echo "start  : ${START[*]}"
echo "== install =="; "${INSTALL[@]}"
echo "== verify (tipos/lint) =="; "${VERIFY[@]}"
echo "== tests (deterministas) =="; "${TESTS[@]}"
echo "== OK línea base verde — $(date -u +%FT%TZ) — $(git rev-parse --short HEAD 2>/dev/null || echo no-git) =="
if [ "${RUN_START_COMMAND:-0}" = 1 ]; then "${START[@]}"; fi
