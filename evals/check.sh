#!/usr/bin/env bash
# evals/check.sh — regresión mínima del repo del skill. Sin red. Sale ≠0 ante cualquier fallo.
# Uso: bash evals/check.sh   (desde la raíz del repo o desde cualquier sitio)
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO/skill/arnes-implementador"
DIST="$REPO/dist/arnes-implementador.skill"
FAIL=0
ok()   { echo "  [ok]   $*"; }
fail() { echo "  [FAIL] $*"; FAIL=1; }

echo "== 1. Frontmatter de SKILL.md =="
python3 -I - "$SKILL_DIR/SKILL.md" <<'PY' || FAIL=1
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---\n", t, re.S)
if not m:
    print("  [FAIL] no hay frontmatter YAML delimitado por ---"); sys.exit(1)
fm = m.group(1)
name = re.search(r"^name:\s*(.+?)\s*$", fm, re.M)
if not name or name.group(1) != "arnes-implementador":
    print("  [FAIL] name ausente o distinto de 'arnes-implementador'"); sys.exit(1)
print("  [ok]   name = arnes-implementador")
dm = re.search(r"^description:\s*(.*)$", fm, re.M)
if not dm:
    print("  [FAIL] description ausente"); sys.exit(1)
first = dm.group(1).strip()
if first in (">-", ">", "|", "|-"):
    rest = fm[dm.end():]
    lines = []
    for l in rest.splitlines():
        if l.startswith("  "): lines.append(l.strip())
        elif l.strip() == "": continue
        else: break
    desc = " ".join(lines)
else:
    desc = first.strip('"').strip("'")
n = len(desc)
if n == 0:
    print("  [FAIL] description vacía"); sys.exit(1)
if n > 1024:
    print(f"  [FAIL] description tiene {n} chars (> 1024)"); sys.exit(1)
print(f"  [ok]   description = {n} chars (<= 1024)")
if n > 1000:
    print(f"  [warn] description a {1024-n} chars del límite")
extra = [k for k in re.findall(r"^([A-Za-z_-]+):", fm, re.M) if k not in ("name","description","license","allowed-tools","metadata")]
if extra:
    print(f"  [warn] claves de frontmatter no estándar: {extra}")
PY

echo "== 2. Tamaño de SKILL.md =="
LINES=$(wc -l < "$SKILL_DIR/SKILL.md")
if [ "$LINES" -lt 500 ]; then ok "SKILL.md tiene $LINES líneas (< 500)"; else fail "SKILL.md tiene $LINES líneas (>= 500)"; fi

echo "== 3. Referencias citadas en SKILL.md existen =="
for ref in $(grep -oE '`(references|assets)/[A-Za-z0-9_./-]+`' "$SKILL_DIR/SKILL.md" | tr -d '`' | sort -u); do
  if [ -e "$SKILL_DIR/$ref" ]; then ok "$ref"; else fail "SKILL.md cita $ref pero no existe"; fi
done

echo "== 4. dist/.skill sincronizado con skill/ =="
if [ ! -f "$DIST" ]; then fail "no existe $DIST"; else
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  unzip -oq "$DIST" -d "$TMP"
  if [ ! -d "$TMP/arnes-implementador" ]; then fail "el .skill no contiene la carpeta raíz arnes-implementador/"; else
    if diff -r --exclude='.DS_Store' "$TMP/arnes-implementador" "$SKILL_DIR" > "$TMP/diff.txt"; then
      ok "dist/arnes-implementador.skill == skill/arnes-implementador/"
    else
      fail "dist desincronizado con source:"; sed 's/^/         /' "$TMP/diff.txt" | head -40
      echo "         -> regenera: (cd skill && zip -r ../dist/arnes-implementador.skill arnes-implementador -x '*.DS_Store')"
    fi
  fi
fi

echo "== 5. Fixtures de evals se generan =="
FX_ROOT="$(mktemp -d)/arnes-fixtures"
if bash "$REPO/evals/fixtures/make-fixtures.sh" "$FX_ROOT" > /dev/null; then
  for d in node-pnpm-env-tests python-pytest-noreadme secret-in-history drizzle-mysql-readme-postgres arneseado-con-docs-kb; do
    [ -d "$FX_ROOT/$d/.git" ] && ok "$d ($(git -C "$FX_ROOT/$d" rev-list --count HEAD) commits)" || fail "$d no se generó como repo git"
  done
  # Propiedades que las aserciones de evals.json dan por sentadas:
  C="$FX_ROOT/secret-in-history"
  git -C "$C" grep -q 'sk_live_' HEAD -- . 2>/dev/null && fail "(c) el secreto NO debe estar en HEAD" || ok "(c) secreto ausente en HEAD"
  [ -n "$(git -C "$C" log --oneline -S 'whsec_')" ] && ok "(c) secreto presente en historial" || fail "(c) secreto debería estar en historial"
  grep -q 'dialect: "mysql"' "$FX_ROOT/drizzle-mysql-readme-postgres/drizzle.config.ts" && grep -qi 'postgres' "$FX_ROOT/drizzle-mysql-readme-postgres/README.md" \
    && ok "(d) contradicción mysql/postgres presente" || fail "(d) contradicción mysql/postgres ausente"
  [ ! -f "$FX_ROOT/python-pytest-noreadme/README.md" ] && ok "(b) sin README" || fail "(b) README no debería existir"
  [ ! -f "$FX_ROOT/node-pnpm-env-tests/.env.example" ] && ok "(a) sin .env.example" || fail "(a) .env.example no debería existir"
  E="$FX_ROOT/arneseado-con-docs-kb"
  [ -f "$E/claude-progress.md" ] && [ -f "$E/feature_list.json" ] && [ -d "$E/docs/kb" ] \
    && ok "(e) arnés + docs/kb paralelos presentes" || fail "(e) faltan artefactos del arnés o docs/kb"
  [ "$(grep -c '^### Sesión' "$E/claude-progress.md")" -gt 5 ] && ok "(e) más de 5 sesiones (rotación pendiente)" || fail "(e) debería tener más de 5 sesiones"
  grep -q 'whsec_' "$E/docs/kb/CONFIGURATIONS.md" && ok "(e) valor de secreto en CONFIGURATIONS.md" || fail "(e) falta el secreto falso en CONFIGURATIONS.md"
  if command -v node >/dev/null 2>&1; then
    (cd "$E" && node --test --test-name-pattern=F01 >/dev/null 2>&1) && ok "(e) F01 pasa" || fail "(e) F01 debería pasar"
    (cd "$E" && node --test --test-name-pattern=F02 >/dev/null 2>&1) && fail "(e) F02 debería fallar" || ok "(e) F02 falla (pass-gating debe impedir marcarla)"
  else
    echo "  [skip] (e) node no disponible: no se comprueba F01/F02"
  fi
  rm -rf "$(dirname "$FX_ROOT")"
else
  fail "make-fixtures.sh falló"
fi

echo "== 6. evals.json válido =="
if [ -f "$REPO/evals/evals.json" ]; then
  python3 -I - "$REPO/evals/evals.json" <<'PY' || FAIL=1
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
assert d["skill_name"] == "arnes-implementador", "skill_name incorrecto"
ids = [e["id"] for e in d["evals"]]
assert len(ids) == len(set(ids)), "ids duplicados"
for e in d["evals"]:
    for k in ("id", "prompt", "expected_output", "files", "assertions"):
        assert k in e, "eval %s sin campo %s" % (e.get("id"), k)
    assert e["assertions"], "eval %s sin assertions" % e["id"]
print("  [ok]   evals.json: %d evals, %d assertions" % (len(ids), sum(len(e["assertions"]) for e in d["evals"])))
PY
else
  echo "  [skip] evals/evals.json no existe todavía"
fi

echo "== 7. Sin secretos reales en el repo del skill =="
if git -C "$REPO" grep -nE '(sk_live|whsec|github_pat|ghp)_[A-Za-z0-9]{8,}|AKIA[0-9A-Z]{16}' -- . ':!evals/fixtures/*' ':!evals/evals.json' ':!references/*' >/dev/null 2>&1; then
  fail "patrón de secreto fuera de fixtures/references"; else ok "ningún patrón de secreto fuera de fixtures"; fi

echo
[ "$FAIL" -eq 0 ] && echo "CHECK: PASS" || { echo "CHECK: FAIL"; exit 1; }
