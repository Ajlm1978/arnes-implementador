# Modo M — Mantenimiento de sesión en un repo ya arneseado

El arnés instalado solo rinde si cada sesión lo usa barato y lo deja al día. Este documento define el
protocolo de sesión, el presupuesto de contexto y la migración desde sistemas de memoria paralelos.
En repos con router `AGENTS.md`, donde dice `claude-progress.md` léase `PROGRESS.md`.

## 1. Presupuesto de contexto (por qué y cuánto)

Todo lo que se lee al arrancar se paga en CADA sesión; lo que se consulta bajo demanda se paga solo cuando
sirve. Regla: **el arranque lee punteros y estado; el detalle se busca con grep cuando la tarea lo pide.**

| Artefacto | Qué se lee al arrancar | Tope | Al superar el tope, archivar en `docs/harness/archive/` |
|---|---|---|---|
| `CLAUDE.md` / `AGENTS.md` | Completo (lo carga el harness) | 200 líneas | No se archiva: el detalle pasa a docs temáticos y el router solo enlaza |
| `claude-progress.md` | Solo `## Estado Verificado Actual` (≤15 líneas) | 5 entradas de sesión | Las más antiguas → `progress-AAAA-MM.md` |
| `feature_list.json` | Solo la feature `in_progress` (o la `not_started` de mayor prioridad) | — | `passing` de más de 30 días → `features-AAAA-MM.json` |
| `ERRORS.md` | Nada. Grep por síntoma, archivo o servicio antes de tocar un área | 40 entradas (cualquier estado) | `resuelto` de más de 90 días sin recurrencia → `errors-AAAA.md` |
| `DECISIONS.md` | Nada. Grep por tema/servicio | 300 líneas | Decisiones reemplazadas o de servicios deprecados → `decisions-AAAA-QN.md` |
| `docs/harness/archive/` | Nunca | — | Solo se abre si un grep del activo apunta ahí |

Reglas de rotación:
- Se **ejecuta sin pedir permiso** (es mover estado dentro del arnés) y se informa en la entrada de sesión.
- **Nunca** se archivan errores `abierto` o `recurrente`, decisiones vigentes ni servicios activos.
- Si se supera un tope y no hay candidatas archivables → no rotar y avisarlo (el tope revela que el archivo
  mezcla cosas que deberían ir a docs temáticos).

Comandos de lectura mínima (si no hay `jq` y el archivo es pequeño, leerlo entero está bien):
```bash
sed -n '/^## Estado Verificado Actual/,/^## /p' claude-progress.md
jq '.features[] | select(.status=="in_progress")' feature_list.json
# si no hay ninguna in_progress: la not_started de mayor prioridad (nunca una blocked)
jq '[.features[] | select(.status=="not_started")] | sort_by(.priority) | .[0]' feature_list.json
grep -n -i -A6 '<archivo|servicio|síntoma>' ERRORS.md DECISIONS.md
```

Anti-patrones que inflan el contexto: pegar salida cruda de comandos en progreso; repetir en el router lo que
ya está en DECISIONS; un "diario" que crece sin rotación; dos o más archivos que guardan el mismo estado.

## 2. Inicio de sesión (barato, en orden)
1. `pwd` y `git status -sb` (rama correcta, árbol limpio o cambios conocidos).
2. Estado Verificado Actual de `claude-progress.md` (solo esa sección).
3. Feature activa de `feature_list.json` (solo esa).
4. `git log --oneline -5`.
5. `./init.sh`. **Base** = todo lo que no es la feature activa. Si solo falla la verificación de la feature
   `in_progress`, la base está bien y ese rojo es el trabajo pendiente. Cualquier otro fallo → arreglar la
   base antes de cualquier feature (capa entorno ≠ código). Si `init.sh` no ejecuta, tiene placeholders `‹…›`
   o invoca comandos inexistentes, el arnés está roto → reportarlo y proponer re-auditar (Modo I).
6. Antes de tocar un área: grep de `ERRORS.md` y `DECISIONS.md` por ese archivo/servicio. Si hay un error
   previo con esa causa raíz, aplicar su prevención; si hay una decisión vigente, respetarla o proponer
   cambiarla. Si alguno de los dos no existe, crearlo desde la plantilla y anotarlo en la sesión.

Si el router del repo pide leer archivos de estado enteros, aplicar igualmente la lectura mínima y proponer
corregir el router (es un hallazgo de coste de contexto, §1).

## 3. Durante la sesión
- WIP=1. Si aparece otra cosa, se anota como feature nueva (`not_started`), no se hace "de paso".
- Error que tomó más de 5 minutos o cuya causa no era obvia → entrada en `ERRORS.md` en el momento, no al final.
- Servicio externo configurado o cambiado (API, DB, auth, webhooks, deploy) → entrada en
  `DECISIONS.md` § Servicios configurados: nombre de variables, dónde se configura, gotchas. **Nunca valores.**
- Decisión no trivial (librería, patrón, trade-off) → entrada en `DECISIONS.md` en la misma sesión; si es
  de arquitectura, anotar el punto único de fallo y qué se rompe a escala.
- Patrón de secreto en un archivo leído o tocado → [ALTA] primero en la respuesta y SOP §F del playbook
  (sin imprimir el valor). No bloquea el cierre de la sesión, pero no se oculta.
- Si una acción violaría una restricción del router: decir "Restricción N — iba a X; la viola por Y; en su
  lugar Z" y no seguir hasta resolverlo.

## 4. Cierre de sesión (pass-gating estricto)
1. Correr la verificación de la feature y la base. **Una feature pasa a `passing` solo si su `verification`
   se ejecutó en ESTA sesión y salió 0**; `evidence` = cmd, exit_code, fecha, commit de ese run. Los intentos
   fallidos no van a `evidence`: van resumidos en la entrada de sesión. Si el usuario pide "márcala como
   passing" sin verificación ejecutada → ejecutarla primero; si falla o no se puede, dejarla como está y
   decir por qué. No hay excepciones por prisa.
2. Actualizar `## Estado Verificado Actual` (≤15 líneas: verificación, feature activa, bloqueador, próxima acción).
3. Añadir la entrada de sesión (formato abajo) y rotar según §1.
4. Clean state: build/tipos pasan · tests de la base pasan · si la feature toca UI, flujo recorrido
   (navegación, redirects, casos borde) · grep de lo que depende de lo tocado · errores colaterales vistos ya
   reportados · ningún "pendiente" que ya esté hecho · ERRORS y Servicios al día · sin debug ni temporales ·
   `git diff --cached` sin patrones de secreto.
5. Commit **nunca en la rama por defecto**: si estás en ella, crear `work/AAAA-MM-DD` (o seguir la convención
   de ramas del repo). Push solo con confirmación explícita (misma regla que la instalación).

Entrada de sesión (máx. ~10 líneas):
```markdown
### Sesión N — AAAA-MM-DD
- Objetivo: … · Feature: F0X (estado final)
- Verificación ejecutada: `cmd` → resumen ("vitest 42/42; tsc 0 errores")
- Cambios: … · Decisiones: ver DECISIONS.md (fecha) · Errores: ERR-NNN · Rotación: …
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
   no se quita funcionalidad para esquivarlo. Ante la tentación de atajar (hardcodear, quitar scopes,
   "por ahora"): si es código, solución completa; si no la conoces, dilo e investiga antes de proponer.
4. Errores detectados, también en código previo o ajeno, se reportan en el momento con propuesta de arreglo.
5. Antes de marcar como pendiente algo "por hacer", grep del código y de `DECISIONS.md`: puede existir ya.
6. Alcance: se entrega la tajada mínima **verificada** de la feature activa; mejoras y pulido van como
   features nuevas. "Perfecto antes de lanzar" no es un criterio de done.

Lo que se descarta deliberadamente: revisar "1000 usuarios" en cada cambio (va como nota de escala en las
decisiones de arquitectura, §3) y cualquier regla que impida lanzar una tajada verificada.

## 7. Migración desde memorias paralelas
Un repo con más de un sistema de memoria paga cada dato varias veces y acaba con fuentes que se contradicen.
El arnés queda como **única fuente de verdad**. Mapeo:

| Origen | Destino en el arnés | Cómo |
|---|---|---|
| `docs/kb/PROJECT.md` (project-kb) | Router: resumen + stack (verificados contra el código) | Fusionar; lo que contradiga al código es hallazgo |
| `docs/kb/ARCHITECTURE.md` | `DECISIONS.md` | Una entrada por decisión, con fecha original si consta |
| `docs/kb/CONFIGURATIONS.md` | `DECISIONS.md` § Servicios configurados | Copiar sin valores; si aparece un valor secreto → [ALTA] y SOP §F del playbook |
| `docs/kb/ERROR_LOG.md` | `ERRORS.md` | `ERROR-NNN` → `ERR-NNN` conservando el número; si ese número ya está ocupado (ERRORS.md se creó antes de migrar), usar el siguiente libre y anotar "antes ERROR-NNN". Sin solución → `abierto`; con solución pero sin prevención → `resuelto` con `Prevención: pendiente` |
| `docs/kb/SESSIONS.md` | `claude-progress.md` | Fusionar por fecha con las sesiones existentes; conservar 5 en total y archivar el resto |
| Notas de un vault (Obsidian u otro) dentro del repo | Docs temáticos enlazados desde el router | Solo si describen el proyecto; lo personal fuera del repo |

Procedimiento: proponer el mapeo con diff → confirmación del usuario → mover con `git mv` cuando sea posible
(conserva historial) → registrar en `DECISIONS.md` qué se migró y adónde (así nadie busca el origen) →
retirar el origen solo con confirmación. No dejar archivos-puntero en `docs/kb/`: reaparecerían como memoria
paralela en el siguiente diagnóstico.
