# Modo M — Mantenimiento de sesión en un repo ya arneseado

El arnés instalado solo rinde si cada sesión lo usa barato y lo deja al día. Este documento define el
protocolo de sesión, el presupuesto de contexto y la migración desde sistemas de memoria paralelos.

## 1. Presupuesto de contexto (por qué y cuánto)

Todo lo que se lee al arrancar se paga en CADA sesión; lo que se consulta bajo demanda se paga solo cuando
sirve. Regla: **el arranque lee punteros y estado; el detalle se busca con grep cuando la tarea lo pide.**

| Artefacto | Qué se lee al arrancar | Tope | Al superar el tope |
|---|---|---|---|
| `CLAUDE.md` / `AGENTS.md` | Completo (lo carga el harness) | 200 líneas | Mover detalle a docs temáticos; el router solo enlaza |
| `claude-progress.md` | Solo `## Estado Verificado Actual` (≤15 líneas) | 5 sesiones en el archivo | Mover las antiguas a `docs/harness/archive/progress-AAAA-MM.md` |
| `feature_list.json` | Solo la feature `in_progress` (o la de mayor prioridad) | — | Features `passing` de más de 30 días → `docs/harness/archive/features-AAAA-MM.json` |
| `ERRORS.md` | Nada. Grep por síntoma, archivo o servicio antes de tocar un área | 40 entradas activas | Archivar las resueltas hace más de 90 días sin recurrencia |
| `DECISIONS.md` | Nada. Grep por tema/servicio | 300 líneas | Archivar por trimestre; dejar en el activo solo decisiones vigentes |
| Archivos de `docs/harness/archive/` | Nunca | — | Solo se abren si un grep del activo apunta ahí |

Comandos de lectura mínima (adaptar si no hay `jq`; si el archivo es pequeño, leerlo entero está bien):
```bash
sed -n '/^## Estado Verificado Actual/,/^## /p' claude-progress.md
jq '.features[] | select(.status=="in_progress")' feature_list.json
# si no hay ninguna in_progress: la pendiente de mayor prioridad
jq '[.features[] | select(.status!="passing")] | sort_by(.priority) | .[0]' feature_list.json
grep -n -i -A6 '‹síntoma|archivo|servicio›' ERRORS.md DECISIONS.md
```

Anti-patrones que inflan el contexto: pegar salida cruda de comandos en progreso; repetir en el router lo que
ya está en DECISIONS; un "diario" que crece sin rotación; dos o más archivos que guardan el mismo estado.

## 2. Inicio de sesión (barato, en orden)
1. `pwd` y `git status -sb` (rama correcta, árbol limpio o cambios conocidos).
2. Estado Verificado Actual de `claude-progress.md` (solo esa sección).
3. Feature activa de `feature_list.json` (solo esa).
4. `git log --oneline -5`.
5. `./init.sh`. Si la base falla → arreglarla antes de cualquier feature (capa entorno ≠ código).
6. Antes de tocar un área: grep de `ERRORS.md` y `DECISIONS.md` por ese archivo/servicio. Si hay un error
   previo con esa causa raíz, aplicar su prevención; si hay una decisión vigente, respetarla o proponer cambiarla.

## 3. Durante la sesión
- WIP=1. Si aparece otra cosa, se anota como feature nueva (`not_started`), no se hace "de paso".
- Error que tomó más de 5 minutos o cuya causa no era obvia → entrada en `ERRORS.md` en el momento, no al final.
- Servicio externo configurado o cambiado (API, DB, auth, webhooks, deploy) → entrada en
  `DECISIONS.md` § Servicios configurados: nombre de variables, dónde se configura, gotchas. **Nunca valores.**
- Decisión no trivial (librería, patrón, trade-off) → entrada en `DECISIONS.md` en la misma sesión.

## 4. Cierre de sesión (pass-gating estricto)
1. Correr la verificación de la feature y la base. **Una feature pasa a `passing` solo si su `verification`
   se ejecutó en ESTA sesión y salió 0**; `evidence` = cmd, exit_code, fecha, commit. Si el usuario pide
   "márcala como passing" sin verificación ejecutada → ejecutarla primero; si no se puede, dejarla como está
   y decir por qué. No hay excepciones por prisa.
2. Actualizar `## Estado Verificado Actual` (≤15 líneas: verificación, feature activa, bloqueador, próxima acción).
3. Añadir la entrada de sesión (formato abajo) y rotar si hay más de 5.
4. Checklist de clean state: build/tipos pasan · tests pasan · sin debug ni temporales · sin secretos en el diff.
5. Commit en la rama de trabajo. Push solo con confirmación explícita (misma regla que la instalación).

Entrada de sesión (máx. ~10 líneas):
```markdown
### Sesión N — AAAA-MM-DD
- Objetivo: … · Feature: F0X (estado final)
- Verificación ejecutada: `cmd` → resumen ("vitest 42/42; tsc 0 errores")
- Cambios: … · Decisiones: ver DECISIONS.md (fecha) · Errores: ERR-NNN
- Próxima acción: … · No tocar: …
```

## 5. Formato de `ERRORS.md`
```markdown
## ERR-NNN — título corto · AAAA-MM-DD · estado: resuelto|abierto|recurrente
- Síntoma: lo que se veía (mensaje clave, no volcado)
- Causa raíz: por qué ocurrió de verdad (capa: tarea|contexto|entorno|verificación|estado)
- Solución: qué se cambió (archivo:línea)
- Prevención: check ejecutable o feature que lo detecta; si no admite check, decirlo
```
Nunca registrar un síntoma sin causa raíz: si no se conoce, estado `abierto` y la hipótesis en curso.
Un error que vuelve a ocurrir se marca `recurrente` y su prevención se promueve a check en `init.sh` o CI.

## 6. Reglas de ingeniería del router (absorbidas de golden-rules)
Se instalan como restricciones del router; son pocas a propósito:
1. No inventar URLs, emails, credenciales, IDs ni datos: si no está en el repo o lo dijo el usuario, preguntar.
2. Leer el archivo antes de modificarlo; si tocas A, buscar con grep lo que depende de A.
3. Sin parches que oculten la causa: si el problema es de configuración externa, se dice qué configurar;
   no se quita funcionalidad para esquivarlo.
4. Errores detectados se reportan en el momento con propuesta de arreglo, no al final.
5. Antes de marcar como pendiente algo "por hacer", grep del código y de `DECISIONS.md`: puede existir ya.
6. Alcance: se entrega la tajada mínima **verificada** de la feature activa; mejoras y pulido van como
   features nuevas. "Perfecto antes de lanzar" no es un criterio de done.

Lo que se descarta deliberadamente: revisar "1000 usuarios" en cada cambio (va como check en decisiones de
arquitectura, no en cada edición) y cualquier regla que impida lanzar una tajada verificada.

## 7. Migración desde memorias paralelas
Un repo con más de un sistema de memoria paga cada dato varias veces y acaba con fuentes que se contradicen.
El arnés queda como **única fuente de verdad**. Mapeo:

| Origen | Destino en el arnés | Cómo |
|---|---|---|
| `docs/kb/PROJECT.md` (project-kb) | Router: resumen + stack (verificados contra el código) | Fusionar; lo que contradiga al código es hallazgo |
| `docs/kb/ARCHITECTURE.md` | `DECISIONS.md` | Una entrada por decisión, con fecha original si consta |
| `docs/kb/CONFIGURATIONS.md` | `DECISIONS.md` § Servicios configurados | Copiar sin valores; si aparece un valor secreto → SOP §F del playbook |
| `docs/kb/ERROR_LOG.md` | `ERRORS.md` | Renumerar ERR-NNN; conservar causa raíz y prevención |
| `docs/kb/SESSIONS.md` | `claude-progress.md` | Últimas 5 sesiones resumidas; el resto a `docs/harness/archive/` |
| Notas de un vault (Obsidian u otro) dentro del repo | Docs temáticos enlazados desde el router | Solo si describen el proyecto; lo personal fuera del repo |

Procedimiento: proponer el mapeo con diff → confirmación del usuario → mover con `git mv` cuando sea posible
(conserva historial) → dejar en el origen un README de una línea que apunte al destino durante una versión →
registrar la migración en `DECISIONS.md`. Nunca borrar el origen sin confirmación.
