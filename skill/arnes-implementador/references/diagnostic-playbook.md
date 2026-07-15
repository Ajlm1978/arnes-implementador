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

### F.1 Detectar
Escanea árbol + historial:
```
git grep -iE 'api[_-]?key|secret|token|password|BEGIN [A-Z ]*PRIVATE KEY' -- . ':!*.example'
git log -p -S 'whsec_' -S 'sk_live' -S 'github_pat_' 2>/dev/null | head
```
Patrones típicos: `sk_live_`/`sk_test_` (Stripe), `whsec_` (Stripe webhook), `github_pat_`/`ghp_` (GitHub),
`AKIA` (AWS), `xoxb-` (Slack), connection strings con contraseña, bloques `PRIVATE KEY`.
Si hay `gitleaks`/`trufflehog`, úsalos: `gitleaks detect --no-banner`.

### F.2 Remediar (obligatorio, en orden)
1. **ROTAR** el secreto en su proveedor. Asume que está comprometido, punto.
2. **PURGAR del historial** (no solo del HEAD): `git filter-repo --replace-text expr.txt` (o BFG
   `--replace-text`). Luego `git push --force` (coordina con el equipo; reescribe la historia).
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
