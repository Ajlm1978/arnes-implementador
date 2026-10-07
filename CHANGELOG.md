# Changelog

Todos los cambios notables de este proyecto se documentan aquí.
Formato: [Keep a Changelog](https://keepachangelog.com/es/1.1.0/). Versionado: [SemVer](https://semver.org/lang/es/).

## [Unreleased]

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

[Unreleased]: https://github.com/Ajlm1978/arnes-implementador/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/Ajlm1978/arnes-implementador/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Ajlm1978/arnes-implementador/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Ajlm1978/arnes-implementador/releases/tag/v1.0.0
