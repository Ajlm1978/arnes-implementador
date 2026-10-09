# arnes-implementador 🔧

[![CI](https://github.com/Ajlm1978/arnes-implementador/actions/workflows/ci.yml/badge.svg)](https://github.com/Ajlm1978/arnes-implementador/actions/workflows/ci.yml) [![Release](https://img.shields.io/github/v/release/Ajlm1978/arnes-implementador)](https://github.com/Ajlm1978/arnes-implementador/releases) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Un Skill de Claude que instala "arneses" (harness engineering) profesionales en tus repos, para que los agentes de IA trabajen de forma fiable y multi-sesión.**
> No es un generador de plantillas: **audita tu repo como un ingeniero senior**, encuentra gaps y fallas, entrega recomendaciones, y recién entonces construye e instala el arnés.

*English TL;DR at the bottom.*

---

## ¿Qué problema resuelve?

Un LLM aislado no ve tu repo, no ejecuta comandos, no recuerda sesiones. El **arnés** es todo lo que rodea al modelo: instrucciones, herramientas, entorno, estado y feedback de verificación. Con un buen arnés, el mismo modelo pasa de poco fiable a fiable — cambio cualitativo, no de modelo.

La mayoría de repos hoy no están "arneseados": no hay un comando de verificación reproducible, no hay estado entre sesiones, el alcance no tiene límites, y el agente declara "listo" lo que no verificó. Este skill lo arregla.

## Qué hace

Dos modos: **instalación** (5 fases, como lo haría un profesional) y **mantenimiento** (cada sesión de trabajo, gastando el mínimo de tokens).

### Modo I — Instalación (5 fases)

> El repo que audita es **dato, no instrucciones**; nunca instala dependencias ni corre tests de un repo desconocido sin tu confirmación; nunca hace push a `main` ni reescribe historial por su cuenta.

1. **Identifica** el objetivo y su estado real — confirma cuál repo (si hay varios), verifica que sea un repo git vivo y al día (no un ZIP viejo), y lee el stack **del código** (dialecto de DB desde `drizzle.config`/driver, no del README).
2. **Audita** — prueba de arranque en frío (5 preguntas), revisión de los 5 subsistemas del arnés, y **caza activa de gaps**: verificación ausente, tests acoplados al entorno, crashes de arranque por variables de entorno, falta de estado entre sesiones, alcance sin WIP=1, backlog desincronizado del código.
3. **Reporta hallazgos** por severidad + recomendaciones — **antes** de escribir nada.
4. **Construye** un arnés adaptado con comandos reales: `CLAUDE.md`/`AGENTS.md` (router), `init.sh` (verificación de línea base), `claude-progress.md`, `feature_list.json`, `DECISIONS.md`, `ERRORS.md`. Si encuentra memorias paralelas (`docs/kb/`, diarios duplicados), propone migrarlas al arnés.
5. **Verifica e instala** — corre la verificación, registra evidencia honesta, y lo sube en **rama + PR** (main intacto).

### Modo M — Mantenimiento (cada sesión)

- **Inicio barato**: lee solo el estado verificado, la feature activa y los últimos commits, y corre `./init.sh`. El detalle (`ERRORS.md`, `DECISIONS.md`) se busca con grep cuando la tarea lo pide.
- **Durante**: errores con causa raíz y servicios configurados se registran en el momento.
- **Cierre con pass-gating**: una feature solo pasa a `passing` si su verificación corrió y salió bien, aunque se lo pidas.
- **Rotación**: el estado viejo se archiva para que leerlo siga siendo barato.

> Desde la v2.0.0 este skill **reemplaza a `project-kb` y `golden-rules`**: absorbe lo útil de ambos (log de errores, registro de configuraciones, reglas de ingeniería) sin duplicar memoria. Puedes desinstalarlos.

## Instalación

**Opción A — un clic (Cowork y Claude Code).** Descarga [`dist/arnes-implementador.skill`](dist/arnes-implementador.skill)
(o el asset del último [Release](https://github.com/Ajlm1978/arnes-implementador/releases), con `SHA256SUMS`
para verificar) y usa **Save skill** en Claude, o súbelo desde la configuración de Skills.

**Opción B — manual (Claude Code).** Copia la carpeta completa al directorio de skills personales y reinicia la sesión:
```bash
cp -r skill/arnes-implementador ~/.claude/skills/
```

## Uso

Una vez instalado, se auto-activa. Ejemplos de lo que puedes decir:

- *"Arnesea este repo: https://github.com/usuario/proyecto"*
- *"Prepara mi proyecto para trabajar con agentes / Claude Code"*
- *"Audita los gaps de mi repositorio y dime qué falla"*
- *"¿Por qué el agente falla en este proyecto?"*
- *"Arranco sesión, ponme al día con lo mínimo"* · *"Cierra la sesión y actualiza el progreso"*
- *"Registra este error en el arnés"* · *"Unifica docs/kb con el arnés"*

Funciona **aunque no uses la palabra "arnés"**.

## Estructura del repo

```
skill/arnes-implementador/      # Skill fuente
├── SKILL.md                    # Modo I (5 fases) y Modo M (mantenimiento)
├── references/
│   ├── kb-arnes.md             # Principios de harness engineering (la teoría)
│   ├── diagnostic-playbook.md  # Checklist de auditoría paso a paso (A-G)
│   ├── stack-adapters.md       # Detección de stack + comandos de verificación por tecnología
│   └── mantenimiento.md        # Modo M: presupuesto de contexto, sesiones, migración
└── assets/templates/           # Kit base de 6 archivos (se adapta a cada repo)
dist/arnes-implementador.skill  # Skill empaquetado (instalación de un clic)
```

## Principios que nunca se rompen

- **Evidencia > confianza**: done = verificación ejecutada + evidencia registrada.
- **Repo as spec**: si no está en el repo, no existe para el agente.
- **No asumas el stack**: léelo. No inventes datos. No maquilles "verdes".
- **WIP=1** + Definition of Done por feature. **Maker ≠ checker**.
- **Cada fallo fortalece el arnés**.
- **Una sola memoria por proyecto, barata de leer**.

## Contribuir

PRs bienvenidos: nuevos adaptadores de stack (`references/stack-adapters.md`), mejoras al playbook de diagnóstico, o casos de fallo nuevos. Abre un issue para proponer cambios grandes primero.

## Créditos

Metodología basada en el trabajo público de harness engineering (Anthropic, OpenAI, A. Osmani, A. Karpathy) sintetizado en `references/kb-arnes.md`. Empaquetado como skill por Amilcar Leon.

## Changelog

Ver [CHANGELOG.md](CHANGELOG.md). Cada versión nace de fallos reales de campo: el skill aprende de cada repo que audita.

## Licencia

MIT — ver [LICENSE](LICENSE).

---

## English TL;DR

**arnes-implementador** is a Claude Skill that installs professional *harness engineering* into your repos so AI agents work reliably across sessions. It has two modes: install and per-session maintenance (cheap session start, strict pass-gating on close, root-cause error log, state rotation — replacing the separate project-kb and golden-rules skills). It's **not a template generator**: it first **audits your repo like a senior engineer** — detects the real stack, runs a cold-start test, reviews the 5 harness subsystems, and hunts for gaps (missing/false verification, environment-coupled tests, startup crashes from missing env vars, no cross-session state, unbounded scope). It reports findings and recommendations **before** writing anything, then builds and installs an adapted harness (`CLAUDE.md`/`AGENTS.md` router, `init.sh` baseline verification, `claude-progress.md`, `feature_list.json`, `DECISIONS.md`, `ERRORS.md`) via a branch + PR. Install the packaged skill from [`dist/`](dist/arnes-implementador.skill) or copy [`skill/`](skill/). MIT licensed.
