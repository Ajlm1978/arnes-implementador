# Playbook de diagnóstico (Fase 1 en detalle)

Ejecuta esto como un auditor senior. Busca gaps ACTIVAMENTE. Cada hallazgo se atribuye a una capa y lleva
un arreglo concreto. No pases a construir sin haber corrido este checklist.

## A. Prueba de arranque en frío (el examen del arnés)
Simula una sesión nueva sin contexto. ¿El repo SOLO permite responder?
1. ¿Qué es este proyecto? (README/CLAUDE.md)
2. ¿Cómo se organiza el código? (estructura/ARCHITECTURE)
3. ¿Cómo se arranca? (script de arranque)
4. ¿Cómo se verifica que funciona? (comando de verificación)
5. ¿Dónde estamos — qué falta y cuál es el próximo paso? (feature_list + progress)
Cada pregunta sin respuesta clara = HUECO. Anótalo.

## B. Auditoría de los 5 subsistemas
- **Instrucciones**: ¿existe AGENTS.md/CLAUDE.md? ¿es router corto o enciclopedia? ¿restricciones duras claras?
- **Herramientas**: ¿el agente tendría shell/tests/archivos? ¿algo requiere acceso no documentado?
- **Entorno**: ¿lockfile? ¿versiones fijadas (node/python/pkg manager)? ¿devcontainer/Dockerfile? ¿reproducible?
- **Estado**: ¿hay PROGRESS/DECISIONS/feature list? ¿o el conocimiento vive solo en la cabeza del dueño?
- **Feedback (máx ROI)**: ¿hay UN comando de verificación real? ¿es reproducible sin secretos? ¿corre en CI?

## C. Cacería de gaps/fallas frecuentes (revisa cada uno)
1. **Verificación ausente/falsa**: no hay `check`/`test`, o "done" se declara por inspección visual.
   → Arreglo: definir comando de verificación (lint+typecheck+tests); Definition of Done por feature.
2. **Tests acoplados al entorno**: suites que fallan sin secretos/DB/red → la base no es reproducible offline.
   → Arreglo: separar `test:unit` (determinista, gate del arnés) de `test:integration` (requiere .env).
   Detéctalo corriendo la suite en un entorno limpio y viendo QUÉ falla y por qué (env var/DB, no lógica).
3. **Crash de arranque por entorno**: fail-fast que lanza si falta una env var; el proceso muere antes del
   healthcheck; el build pasa pero el deploy no arranca. → Atribuir a capa ENTORNO. Arreglo: setear las env
   requeridas (documentarlas en `.env.example`) y/o degradar el fail-fast del healthcheck. Distingue SIEMPRE
   capa entorno de capa código: si el build pasa y solo el healthcheck falla, sospecha env, no código.
4. **Sin estado entre sesiones**: reconstruir contexto cuesta >3 min. → Arreglo: PROGRESS + DECISIONS + rituales.
5. **Alcance sin límites**: no WIP=1, sin priorización, backlog gigante. → Arreglo: feature_list priorizado,
   una sola feature activa, la siguiente solo tras verificación.
6. **Higiene/seguridad (ALTA)**: escanea el árbol Y el historial de git en busca de secretos. ¿`.env*` en
   `.gitignore`? ¿`.env.example` existe y documenta TODAS las env vars? ¿`todo.md` desincronizado del código?
   Si hay secretos commiteados o env vars sin documentar → aplica el SOP de la sección F (obligatorio, antes de instalar el arnés).

## D. Reconciliar backlog vs realidad
No confíes en los checkboxes de un `todo.md`. Haz grep en el código de las áreas críticas (auth, billing,
deploy, onboarding) y compara con lo que el backlog dice. Reporta las discrepancias: features "pendientes"
que en realidad ya existen, y "hechas" que no.

## E. Severidad
Clasifica cada hallazgo ALTA/MEDIA/BAJA por impacto en la fiabilidad y en el objetivo del usuario (ej. lanzar).
Lo que bloquea arrancar/verificar/desplegar es ALTA.


## F. SOP crítico — secretos en el repo y `.env.example`

Aprendido en campo (proyecto real con PAT + Stripe webhook secret commiteados): detectar el secreto no
basta; **borrarlo en un commit nuevo NO lo elimina** — sigue vivo en el historial de git y cualquiera que
clone lo recupera. Este SOP es severidad ALTA y va ANTES de instalar el arnés.

### F.1 Detectar (sin imprimir valores)
Los comandos deben devolver RUTAS y COMMITS, nunca el secreto. Usa una sola regex (varios `-S` en
`git log` solo conservan el último) y `--all` para cubrir ramas:
```
PAT='(sk_live_|sk_test_|whsec_|github_pat_|ghp_|AKIA[0-9A-Z]{16}|xoxb-|BEGIN [A-Z ]*PRIVATE KEY|mysql://[^:]+:[^@]+@|postgres(ql)?://[^:]+:[^@]+@)'
git grep -lIE "$PAT" -- . ':!*.example'                # árbol: solo rutas
git log --all --oneline -G"$PAT"                       # historial: solo commits
git grep -hoIE '(sk_live|sk_test|whsec|github_pat|ghp)_[A-Za-z0-9]{4}' | sort -u   # tipo + 4 chars, para clasificar
```
Segunda pasada opcional (ruidosa): `git grep -lIiE 'api[_-]?key|secret|token|password' -- . ':!*.example'`.
Si hay `gitleaks`: `gitleaks detect --no-banner --redact`. No uses `-p` ni `cat` sobre los hallazgos.

### F.2 Remediar (obligatorio, en orden)
1. **ROTAR** el secreto en su proveedor. Asume que está comprometido, punto.
2. **PURGAR del historial — SOLO el humano decide.** Reescribir historia es destructivo e irreversible para
   colaboradores. Tú NUNCA ejecutas `git filter-repo`, BFG, `git push --force`/`--force-with-lease`,
   `reflog expire` ni `gc --prune` por tu cuenta. Flujo: (a) confirma que el paso 1 (rotar) está hecho y
   verificado por el humano; (b) presenta el plan: ramas (`git branch -r`), colaboradores recientes
   (`git shortlog -sn --since=90.days`), PRs abiertos y el `expr.txt` exacto; (c) pide la frase literal
   "CONFIRMO reescribir la historia de <repo>" — un "ok"/"sí"/"dale" no basta; (d) clon fresco
   (`git clone --mirror`) y el original como respaldo; (e) `--force-with-lease` rama por rama; (f) avisa
   que todos re-clonan y que forks/PRs cerrados/cachés conservan el secreto: la rotación es la única
   mitigación real. Sin confirmación → queda como ALTA ABIERTA en el reporte y en DECISIONS.md.
3. **Mover a env var** y documentarlo en `.env.example` con un placeholder, nunca el valor real.
4. **Confirmar `.gitignore`** cubre `.env`, `.env.*` (excepto `.env.example`).
No marques esto resuelto sin haber hecho los 4 pasos. Rotar sin purgar, o purgar sin rotar, deja el hueco abierto.

### F.3 Generar `.env.example` desde el código
Si faltan env vars documentadas (arranque en frío/deploy imposible por fail-fast), sintetiza el archivo
escaneando el código:
```
grep -rhoE 'process\.env\.[A-Z0-9_]+' --include='*.ts' --include='*.js' . | sed 's/process.env.//' | sort -u
# Python: grep -rhoE 'os\.environ\[?["'"'"'][A-Z0-9_]+' ...
```
Crea `.env.example` con TODAS las claves encontradas y placeholders (`KEY=` o `KEY=your-value-here`).
Marca cuáles son obligatorias (las que un fail-fast exige al arrancar). Esto documenta el contrato de entorno
y previene el crash "build pasa pero el proceso muere antes del healthcheck".

## G. Memorias paralelas y coste de contexto
Un repo con varios sistemas de memoria paga cada dato varias veces por sesión y acaba con fuentes que se
contradicen. Detecta (solo listar, no leer contenidos enteros):
```
ls -d docs/kb docs/memory .obsidian 2>/dev/null
git ls-files | grep -iE '(^|/)(SESSIONS|ARCHITECTURE|CONFIGURATIONS|ERROR_LOG|PROJECT)\.md$'
wc -l CLAUDE.md AGENTS.md claude-progress.md DECISIONS.md 2>/dev/null
grep -c '^### Sesión' claude-progress.md 2>/dev/null
```
- Dos o más archivos guardando estado, decisiones o errores → [MEDIA] duplicación; migrar con
  `references/mantenimiento.md` §7.
- Router de más de 200 líneas, progreso con más de 5 sesiones o DECISIONS de más de 300 líneas → [BAJA]
  coste de contexto; aplicar topes y rotación (§1).
- `.obsidian/` versionado con configuración personal (workspace, plugins) → [BAJA]; añadir a `.gitignore`.
- Contradicción entre una memoria y el código → gana el código y es hallazgo, igual que con el README.
