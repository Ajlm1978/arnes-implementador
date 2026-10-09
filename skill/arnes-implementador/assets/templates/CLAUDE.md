# CLAUDE.md — ‹NOMBRE DEL PROYECTO›

> Router 50-200 líneas. Lo importante arriba. El skill rellena cada «‹...›» con datos REALES del repo.
> Este archivo se carga en cada sesión: aquí van punteros, no detalle. El detalle vive en los docs de abajo.

## Resumen del proyecto
‹1-2 frases: qué es, para quién.›

## Stack (real, leído del repo)
- Lenguaje/framework: ‹...› · DB/servicios: ‹...› · Gestor de paquetes: ‹...› · Versiones fijadas en: ‹lockfile›

## Quick Start
- Instalar + verificar base: `./init.sh`
- Arrancar: `‹START_CMD real›`
- Verificación completa: `‹VERIFY_CMD real›`

## Restricciones duras (no negociables — máx ~15)
1. NUNCA commitear `.env*`, claves ni secretos. Servicios se documentan por NOMBRE de variable, nunca valor.
2. No inventar URLs, emails, credenciales, IDs ni datos: si no está en el repo o no lo dijo el usuario, preguntar.
3. Leer un archivo antes de modificarlo; si tocas A, `grep` de lo que depende de A.
4. Sin parches que oculten la causa (hardcodear, quitar scopes, "por ahora"): si es configuración externa,
   decir qué configurar; si no conoces la solución completa, dilo e investiga.
5. Errores detectados, también en código previo o ajeno, se reportan en el momento con propuesta de arreglo.
6. Antes de dar algo por "pendiente", `grep` en el código y en DECISIONS.md: puede existir ya.
7. Sin dependencias nuevas sin registrarlas en DECISIONS.md.
8. No romper la base: si `./init.sh` falla por algo distinto de la feature activa, arréglalo antes de seguir.
9. ‹restricciones específicas del proyecto›

## Reglas de trabajo (harness)
- WIP=1: una feature en in_progress; la siguiente solo cuando la actual esté `passing`. Lo nuevo se anota
  como feature `not_started`, no se hace "de paso".
- Alcance: entrega la tajada mínima VERIFICADA de la feature activa; el pulido es otra feature.
- Definition of Done: verificación EJECUTADA + evidencia en feature_list.json. "Se ve bien" NO es done;
  si la feature toca UI, recorrer el flujo (navegación, redirects, casos borde).
- Pass-gating: no marques `passing` sin correr su `verification` en esta sesión, aunque te lo pidan.
- Maker ≠ checker: al verificar, actúa como evaluador escéptico, no como autor.

## Arranque de sesión (barato, en orden)
1. `pwd` · `git status -sb`
2. Solo la sección `## Estado Verificado Actual` de claude-progress.md
3. Solo la feature activa: `jq '.features[] | select(.status=="in_progress")' feature_list.json`; si no hay,
   la `not_started` de mayor prioridad
4. `git log --oneline -5` · 5. `./init.sh` → si falla algo distinto de la feature activa, arreglar la base primero
6. Antes de tocar un área: `grep -n -i "<archivo o servicio>" ERRORS.md DECISIONS.md`
No leer archivos de estado enteros ni `docs/harness/archive/`.

## Durante la sesión
- Error de más de 5 min o causa no obvia → ERRORS.md (síntoma, causa raíz, solución, prevención).
- Servicio externo configurado → DECISIONS.md § Servicios configurados. Decisión no trivial → DECISIONS.md.

## Cierre de sesión
- [ ] build/tipos y tests de la base pasan · [ ] feature_list.json sin passing falsos (evidence = run en exit 0)
- [ ] grep de lo que depende de lo tocado · [ ] ERRORS y Servicios al día · [ ] ningún "pendiente" ya hecho
- [ ] Estado Verificado Actual al día (≤15 líneas) + entrada de sesión (≤10 líneas)
- [ ] rotación: >5 sesiones, >40 errores, >300 líneas en DECISIONS o passing de >30 días → docs/harness/archive/
- [ ] sin debug/temporales · [ ] `git diff --cached` sin secretos
- [ ] commit fuera de la rama por defecto (`work/AAAA-MM-DD`); push solo con confirmación

## Docs temáticos (se consultan bajo demanda, no al arrancar)
- DECISIONS.md — decisiones, hallazgos y servicios configurados
- ERRORS.md — errores resueltos con causa raíz y prevención
- ‹README, docs temáticos según existan›
