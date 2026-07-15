# arnes-implementador 🔧

> **Un Skill de Claude que instala "arneses" (harness engineering) profesionales en tus repos, para que los agentes de IA trabajen de forma fiable y multi-sesión.**
> No es un generador de plantillas: **audita tu repo como un ingeniero senior**, encuentra gaps y fallas, entrega recomendaciones, y recién entonces construye e instala el arnés.

*English TL;DR at the bottom.*

---

## ¿Qué problema resuelve?

Un LLM aislado no ve tu repo, no ejecuta comandos, no recuerda sesiones. El **arnés** es todo lo que rodea al modelo: instrucciones, herramientas, entorno, estado y feedback de verificación. Con un buen arnés, el mismo modelo pasa de poco fiable a fiable — cambio cualitativo, no de modelo.

La mayoría de repos hoy no están "arneseados": no hay un comando de verificación reproducible, no hay estado entre sesiones, el alcance no tiene límites, y el agente declara "listo" lo que no verificó. Este skill lo arregla.

## Qué hace (5 fases, como lo haría un profesional)

1. **Identifica** el proyecto — clona/lee el repo, detecta el stack real y los comandos reales de instalación/verificación/arranque. Sin suposiciones.
2. **Audita** — prueba de arranque en frío (5 preguntas), revisión de los 5 subsistemas del arnés, y **caza activa de gaps**: verificación ausente, tests acoplados al entorno, crashes de arranque por variables de entorno, falta de estado entre sesiones, alcance sin WIP=1, backlog desincronizado del código.
3. **Reporta hallazgos** por severidad + recomendaciones — **antes** de escribir nada.
4. **Construye** un arnés adaptado con comandos reales: `CLAUDE.md`/`AGENTS.md` (router), `init.sh` (verificación de línea base), `claude-progress.md`, `feature_list.json`, `DECISIONS.md`.
5. **Verifica e instala** — corre la verificación, registra evidencia honesta, y lo sube en **rama + PR** (main intacto).

## Instalación

**Opción A — Skill de Claude (recomendada).** Descarga [`dist/arnes-implementador.skill`](dist/arnes-implementador.skill) y, en Claude (Cowork o Claude Code), instálalo con el botón **Save skill** o desde **Ajustes → Capacidades**.

**Opción B — Manual.** Copia la carpeta [`skill/arnes-implementador/`](skill/arnes-implementador/) a tu directorio de skills (`~/.claude/skills/` en Claude Code, o el que use tu entorno).

## Uso

Una vez instalado, se auto-activa. Ejemplos de lo que puedes decir:

- *"Arnesea este repo: https://github.com/usuario/proyecto"*
- *"Prepara mi proyecto para trabajar con agentes / Claude Code"*
- *"Audita los gaps de mi repositorio y dime qué falla"*
- *"¿Por qué el agente falla en este proyecto?"*

Funciona **aunque no uses la palabra "arnés"**.

## Estructura del repo

```
skill/arnes-implementador/      # Skill fuente
├── SKILL.md                    # El workflow de 5 fases
├── references/
│   ├── kb-arnes.md             # Principios de harness engineering (la teoría)
│   ├── diagnostic-playbook.md  # Checklist de auditoría paso a paso
│   └── stack-adapters.md       # Detección de stack + comandos de verificación por tecnología
└── assets/templates/           # Kit base de 5 archivos (se adapta a cada repo)
dist/arnes-implementador.skill  # Skill empaquetado (instalación de un clic)
```

## Principios que nunca se rompen

- **Evidencia > confianza**: done = verificación ejecutada + evidencia registrada.
- **Repo as spec**: si no está en el repo, no existe para el agente.
- **No asumas el stack**: léelo. No inventes datos. No maquilles "verdes".
- **WIP=1** + Definition of Done por feature. **Maker ≠ checker**.
- **Cada fallo fortalece el arnés**.

## Contribuir

PRs bienvenidos: nuevos adaptadores de stack (`references/stack-adapters.md`), mejoras al playbook de diagnóstico, o casos de fallo nuevos. Abre un issue para proponer cambios grandes primero.

## Créditos

Metodología basada en el trabajo público de harness engineering (Anthropic, OpenAI, A. Osmani, A. Karpathy) sintetizado en `references/kb-arnes.md`. Empaquetado como skill por Amilcar Leon.

## Licencia

MIT — ver [LICENSE](LICENSE).

---

## English TL;DR

**arnes-implementador** is a Claude Skill that installs professional *harness engineering* into your repos so AI agents work reliably across sessions. It's **not a template generator**: it first **audits your repo like a senior engineer** — detects the real stack, runs a cold-start test, reviews the 5 harness subsystems, and hunts for gaps (missing/false verification, environment-coupled tests, startup crashes from missing env vars, no cross-session state, unbounded scope). It reports findings and recommendations **before** writing anything, then builds and installs an adapted harness (`CLAUDE.md`/`AGENTS.md` router, `init.sh` baseline verification, `claude-progress.md`, `feature_list.json`, `DECISIONS.md`) via a branch + PR. Install the packaged skill from [`dist/`](dist/arnes-implementador.skill) or copy [`skill/`](skill/). MIT licensed.
