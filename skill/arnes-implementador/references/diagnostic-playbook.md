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
6. **Higiene/seguridad**: ¿`.env*` en `.gitignore`? ¿hay secretos commiteados? ¿`todo.md` desincronizado del
   código? (verifica el estado real en el código, no en los checkboxes — suelen mentir).

## D. Reconciliar backlog vs realidad
No confíes en los checkboxes de un `todo.md`. Haz grep en el código de las áreas críticas (auth, billing,
deploy, onboarding) y compara con lo que el backlog dice. Reporta las discrepancias: features "pendientes"
que en realidad ya existen, y "hechas" que no.

## E. Severidad
Clasifica cada hallazgo ALTA/MEDIA/BAJA por impacto en la fiabilidad y en el objetivo del usuario (ej. lanzar).
Lo que bloquea arrancar/verificar/desplegar es ALTA.
