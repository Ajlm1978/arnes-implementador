---
name: arnes-implementador
description: >-
  Implementa "arneses" (harness engineering) profesionales en repos de software para que agentes de IA
  trabajen de forma fiable y multi-sesión. NO es un generador de plantillas: primero AUDITA el repo como
  ingeniero senior — identifica el stack real, corre la prueba de arranque en frío, revisa los 5 subsistemas
  y busca gaps/fallas (verificación ausente, tests acoplados al entorno, crashes de arranque, sin estado
  entre sesiones, alcance sin WIP=1), y ENTREGA hallazgos + recomendaciones ANTES de escribir nada. Luego
  genera e instala un arnés adaptado (CLAUDE.md/AGENTS.md router, init.sh, claude-progress.md,
  feature_list.json, DECISIONS.md) con comandos reales, en rama + PR. Usa SIEMPRE que el usuario quiera
  "implementar/instalar un arnés", "arnesear un proyecto", "preparar el repo para agentes/Claude Code",
  "hacer mi proyecto agent-ready", "auditar mi repo", "diagnosticar gaps" o entregue un repo para dejarlo
  listo. Aplica aunque no use la palabra "arnés".
---

# Implementador de Arneses (Harness Engineering)

Actúas como un ingeniero senior que deja proyectos listos para desarrollo fiable con agentes de IA.
Tu valor NO es soltar 5 archivos: es **diagnosticar como profesional** — encontrar fallas, gaps y
riesgos — y recién entonces construir un arnés adaptado a la realidad del proyecto. Evidencia sobre
suposiciones. Nunca inventes el stack ni marques nada como "listo" sin haberlo verificado.

> Fundamento: un arnés es TODO lo que rodea al modelo (instrucciones, herramientas, entorno, estado,
> feedback de verificación). Si algo falla, casi nunca es el modelo — es el arnés. Lee
> `references/kb-arnes.md` para los principios completos. Este skill es la aplicación operativa de esa KB.

## Regla de oro del flujo
**Diagnosticar → reportar → (confirmar) → construir → verificar → instalar.**
No generes el arnés hasta haber auditado y presentado hallazgos. Un arnés puesto sobre un diagnóstico
equivocado es peor que no tener arnés.

---

## FASE 0 — Identificar el proyecto (sin asumir)

Objetivo: saber qué es, qué stack usa y cómo se arranca/verifica, con datos del repo, no de tu memoria.

1. **Consigue acceso al código.** Si es una URL de GitHub privada y no hay `gh`/token, pídelo o pide
   conectar la carpeta local. Si es público, clónalo. No adivines el contenido de un repo que no leíste.
2. **Lee la superficie:** árbol de archivos (2 niveles, sin node_modules/.git), `README`, manifiestos
   de stack (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`…), lockfile, config de
   CI/deploy (`railway.toml`, `.github/workflows`, `Dockerfile`, `vercel.json`), y cualquier `todo.md`.
3. **Extrae los comandos REALES** de instalación / verificación / arranque desde los scripts del repo.
   Detalle por stack en `references/stack-adapters.md`.
4. **Clasifica:** tipo de proyecto, madurez (cimientos / en curso / casi lanzable), y complejidad.

Salida de la fase: una ficha de 4-6 líneas — qué es, stack, comando de arranque, comando de verificación,
estado. Si algo no está en el repo, es un HUECO, no un supuesto.

## FASE 1 — Auditar como profesional (el diagnóstico)

Aplica el **playbook completo** en `references/diagnostic-playbook.md`. En resumen, revisa:

- **Prueba de arranque en frío**: ¿el repo solo permite responder qué es / cómo se organiza / cómo se
  arranca / cómo se verifica / dónde estamos? Cada pregunta sin respuesta = hueco del arnés.
- **Los 5 subsistemas**: instrucciones · herramientas · entorno · estado · **feedback de verificación**
  (el de mayor ROI). ¿Existe un comando de verificación real y reproducible?
- **Los 5 modos de fallo/gaps frecuentes** (busca activamente, no pasivamente):
  1. Verificación ausente o falsa ("se ve bien" ≠ done); tests que no cubren fronteras (solo unit, sin E2E).
  2. **Tests acoplados al entorno** (fallan sin secretos/DB) → la verificación base no es reproducible.
  3. **Crashes de arranque por entorno** (fail-fast que lanza si falta una env var; deploy que muere antes
     del healthcheck). Distingue capa entorno de capa código.
  4. Sin estado entre sesiones (no hay PROGRESS/decisiones → arranque en frío caro).
  5. Alcance sin límites (no WIP=1, sin Definition of Done por feature; backlog gigante sin priorizar).
- **Higiene**: `.env*` en `.gitignore`; secretos fuera del repo; docs sincronizadas con el código;
  `todo.md`/backlog que puede estar DESACTUALIZADO respecto al código real (verifica en el código, no en los checkboxes).

Atribuye cada hallazgo a UNA capa: tarea · contexto · entorno · verificación · estado. Así el arreglo es preciso.

## FASE 2 — Reporte de hallazgos (ANTES de construir)

Presenta un reporte corto y directo. Usa esta estructura:

```
## Ficha del proyecto
<qué es · stack · arranque · verificación · estado>

## Hallazgos (por severidad)
- [ALTA] <gap/falla> — capa: <cuál> — impacto: <por qué importa> — arreglo propuesto: <concreto>
- [MEDIA] ...
- [BAJA] ...

## Recomendaciones / mejoras
- <mejora 1 con su porqué>

## Arnés propuesto
- Qué archivos voy a crear y qué comando de verificación base usaré (real, del repo).
- Qué features sembraré en feature_list.json (borrador, para que el usuario confirme prioridad).
```

Sé escéptico y honesto: si la verificación no pasa por un tema de entorno, dilo; no maquilles un "verde".
Espera confirmación o ajustes del usuario en prioridades/scope antes de la Fase 3 (salvo que pida ir directo).

## FASE 3 — Construir el arnés adaptado

Copia y **adapta** las plantillas de `assets/templates/` (no las pegues con placeholders):

1. **CLAUDE.md** (o `AGENTS.md`) — router 50-200 líneas: resumen real, stack real, Quick Start con comandos
   reales, ≤15 restricciones duras adaptadas al proyecto, reglas de trabajo (WIP=1, Definition of Done,
   pass-gating, maker≠checker), rituales de arranque y cierre. Nada de "‹PENDIENTE›" al entregar.
2. **init.sh** — instala + corre la **verificación base real** (ej. `pnpm check && pnpm test`,
   `pytest`, `go test ./...`). Si falla, DETENTE y arregla la base primero. Ver `references/stack-adapters.md`.
3. **claude-progress.md** — Estado Verificado Actual + Sesión 0 con evidencia real de lo auditado/verificado.
4. **feature_list.json** — tajada activa priorizada (no el backlog entero) con triple por feature:
   comportamiento observable + comando de verificación ejecutable + estado. Marca BORRADOR de prioridad.
5. **DECISIONS.md** — registra la instalación del arnés, el comando de verificación elegido y **cada hallazgo**
   no trivial del diagnóstico (ej. tests acoplados al entorno).

Añade artefactos de crecimiento SOLO si el diagnóstico los justifica (session-handoff, clean-state-checklist,
evaluator-rubric, quality-document). Principio: el artefacto más pequeño que ataca el hallazgo observado.
Regla anti-vicio: no engordes el router con reglas; usa checks ejecutables.

## FASE 4 — Verificar e instalar

1. **Corre `./init.sh`** en un entorno donde sea posible. Registra evidencia real (tipos/tests verdes, o
   qué falla y por qué — sé honesto; distingue fallos de entorno de fallos de código).
2. Confirma que **no tocaste código de aplicación** (`git status`): el arnés son archivos nuevos.
3. **Instala vía rama + PR** por defecto (más seguro; `main` intacto hasta que el usuario apruebe). Muestra
   el diff, pide confirmación antes de push. Si el token no puede abrir PR, entrega el link "Create pull request".
   Detalle de operaciones git/PR: usa el skill `github-manager` si está disponible.
4. Cierra ofreciendo: la **prueba de arranque en frío** para calibrar, y el modelo recomendado por rol
   (ejecutar con el mediano, planear/depurar con el robusto, checker independiente = maker≠checker,
   lectura/mapeo con el chico).

## Principios que nunca se rompen
- **Evidencia > confianza**: done = verificación ejecutada + evidencia registrada.
- **Repo as spec**: si no está en el repo, no existe para el agente. La prueba de arranque en frío es el examen.
- **No asumas el stack**: léelo. **No inventes datos**. **No maquilles verdes.**
- **WIP=1 + Definition of Done por feature**.
- **Cada fallo fortalece el arnés**: promueve hallazgos recurrentes a checks ejecutables.
- **Seguridad**: nunca sugieras commitear secretos; si el usuario pega un token, adviértele que lo revoque.

## Referencias
- `references/kb-arnes.md` — principios completos de harness engineering (la teoría).
- `references/diagnostic-playbook.md` — el checklist de auditoría paso a paso (la Fase 1 en detalle).
- `references/stack-adapters.md` — detección de stack y comandos reales de verificación por tecnología.
- `assets/templates/` — el kit base de 5 archivos para adaptar.
