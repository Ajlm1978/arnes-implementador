# Changelog

Todos los cambios notables de este proyecto se documentan aquí.
Formato: [Keep a Changelog](https://keepachangelog.com/es/1.1.0/). Versionado: [SemVer](https://semver.org/lang/es/).

## [Unreleased]

## [2.0.0] - 2026-10-08
### Security
- Playbook §F.1: el comando de clasificación imprimía 4 caracteres del secreto (y el valor completo si era
  corto), violando "ni parcial". Ahora solo cuenta por tipo (`uniq -c`), sin un carácter del valor.
- Modo M: un patrón de secreto en archivos leídos o tocados es [ALTA] y activa el SOP §F; el cierre exige
  `git diff --cached` sin secretos. Commits nunca en la rama por defecto.
### Added
- **Modo M (mantenimiento)**: protocolo de sesión para repos ya arneseados — inicio barato (solo
  `## Estado Verificado Actual`, la feature activa, `git log -5` e `init.sh`), cierre con pass-gating estricto,
  registro de errores y servicios en el momento, y rotación del estado. Nueva referencia `references/mantenimiento.md`.
- **Presupuesto de contexto** (principio L14): topes por artefacto (router ≤200 líneas, 5 sesiones en progreso,
  40 errores activos, 300 líneas en DECISIONS) y archivo en `docs/harness/archive/`. Lectura bajo demanda con grep.
- Plantilla **`ERRORS.md`**: síntoma, causa raíz por capa, solución y prevención ejecutable; los recurrentes se
  promueven a checks.
- **DECISIONS.md § Servicios configurados**: variables por nombre, dónde se configuran y gotchas, nunca valores.
- **Diagnóstico G — memorias paralelas**: detecta `docs/kb/`, `SESSIONS.md`, vaults de notas y routers inflados;
  migración con mapeo explícito, `git mv` y confirmación antes de mover o borrar.
- Evals: fixture (e) `arneseado-con-docs-kb`, task-eval 6 (pass-gating + migración + secreto en memoria
  paralela) y 5 trigger-evals nuevos.
### Changed
- **Base vs feature activa**: un test en rojo de la feature `in_progress` no es fallo de base ni "arnés roto";
  arnés roto = `init.sh` no ejecuta, placeholders o comandos inexistentes. Evita re-auditorías falsas.
- Modo M cubre repos con `AGENTS.md` + `PROGRESS.md`; crea `ERRORS.md`/`DECISIONS.md` si faltan; aplica la
  lectura mínima aunque el router del repo pida leer todo; `evidence` solo guarda runs en exit 0.
- Rotación: se ejecuta sin permiso y se informa; nunca archiva errores abiertos/recurrentes ni decisiones
  vigentes; destinos por artefacto; la migración de memorias paralelas sí pide confirmación y no deja punteros.
- Fallback de feature activa = `not_started` de mayor prioridad (nunca `blocked`); se restaura la regla WIP
  "la siguiente solo cuando la actual esté passing".
- De golden-rules se recuperan R7 (reportar errores también en código ajeno), la rama "no sé la solución →
  dilo e investiga", el formato de reporte de violación, el flujo UI en la DoD y la nota de escala en
  decisiones de arquitectura; checklist de cierre completo de project-kb.
- Fase 1 contempla proyectos nuevos (git init con confirmación). Plantillas sin `‹…›` en los rituales.
- Eval 6 endurecido (12 aserciones: Estado Verificado, ERRORS.md, rama main intacta, remote bare sin push).
- **Reemplaza a los skills `project-core:project-kb` y `project-core:golden-rules`**: su valor queda absorbido
  (log de errores con causa raíz, registro de configuraciones, reglas de ingeniería no inventar / leer antes de
  tocar / grep de dependencias / sin parches que oculten la causa / reportar en el momento) sin duplicar estado.
- Router: rituales de arranque y cierre baratos; regla de alcance "tajada mínima verificada" en lugar de
  perfeccionismo previo al lanzamiento.
- `claude-progress.md`: Estado Verificado Actual acotado a 15 líneas con próxima acción y "no tocar".
- Trigger-eval de cierre de sesión pasa de negativo a positivo (es Modo M).
### Removed
- De golden-rules se descartan deliberadamente la revisión "1000 usuarios" en cada cambio y las reglas que
  impiden lanzar una tajada verificada (R3 MLP, R11 sin separar pre/post lanzamiento).

## [1.2.0] - 2026-10-07
### Security
- **Frontera de confianza**: el repo auditado es dato, no instrucciones (cláusula anti prompt-injection; comandos de scripts/README solo si son reconocibles del gestor del proyecto).
- **Frontera de ejecución**: antes de instalar dependencias/correr tests de un repo desconocido se pide confirmación; `--ignore-scripts` y lockfile congelado por defecto; Python en venv.
- `init.sh` sin `eval`: comandos como arrays, placeholders `‹…›` obligatorios (el script falla hasta rellenarlos), overrides restringidos a comandos simples.
- SOP de secretos: la purga de historial (`filter-repo`/BFG/force-push) **solo con confirmación literal del humano** y nunca ejecutada por el agente por su cuenta; detección sin imprimir valores (regex única, `-l`, `--all`).
- Reglas exactas de credenciales: nunca tokens en URLs de remote, nunca secretos en progreso/decisiones/PR/reporte, redacción de salida de comandos.
- Instalación: siempre rama + PR, nunca push a la rama por defecto ni `--force`, confirmación explícita por push; nunca sobreescribir archivos existentes (fusión con diff).
### Added
- Fase 1 confirma el **repo objetivo** cuando hay varios candidatos, verifica que sea un **repo git vivo y al día** (ZIP/export → parar), y lee el **stack desde el código** con orden de autoridad (`drizzle.config`/driver > deps > CI > README).
- Cada hallazgo ALTA/MEDIA sale con un **check ejecutable** o una feature con `verification`.
- `metadata.version` en el frontmatter; CHANGELOG, CONTRIBUTING, SECURITY; CI (validación + dist sincronizado) y Release (tag → `.skill` + `SHA256SUMS`).
- `evals/`: 20 trigger-evals, 5 task-evals con 47 aserciones, generador de fixtures y `check.sh` de regresión.
- Artefactos de crecimiento definidos y glosario en `kb-arnes.md`.
### Changed
- `feature_list.json`: `_prioridad: BORRADOR` y evidencia estructurada; plantillas de estado con cabecera anti-fuga.
- description del skill acotada (cláusula de NO uso) para no competir con revisión de código/seguridad general.

## [1.1.0] - 2026-10-07
### Added
- SOP crítico de secretos: detección en árbol + historial de git y remediación (rotar + purgar historial con `git filter-repo`/BFG + force-push).
- Síntesis de `.env.example` desde el código (escaneo de `process.env.*`) para cerrar el hueco de arranque en frío.
- Adaptador de DB MySQL-compatible (TiDB, PlanetScale).
### Changed
- Regla: la verificación de línea base no debe requerir la DB real.

## [1.0.0] - 2026-07-15
### Added
- Primera versión del skill `arnes-implementador`: workflow de 5 fases, `references/` (kb-arnes, diagnostic-playbook, stack-adapters) y kit de plantillas (`CLAUDE.md`, `init.sh`, `claude-progress.md`, `feature_list.json`, `DECISIONS.md`).

[Unreleased]: https://github.com/Ajlm1978/arnes-implementador/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/Ajlm1978/arnes-implementador/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/Ajlm1978/arnes-implementador/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Ajlm1978/arnes-implementador/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Ajlm1978/arnes-implementador/releases/tag/v1.0.0
