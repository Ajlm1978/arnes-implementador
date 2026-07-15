# CLAUDE.md — ‹NOMBRE DEL PROYECTO›

> Router 50-200 líneas. Lo importante arriba. El skill rellena cada «‹...›» con datos REALES del repo.

## Resumen del proyecto
‹1-2 frases: qué es, para quién.›

## Stack (real, leído del repo)
- Lenguaje/framework: ‹...› · DB/servicios: ‹...› · Gestor de paquetes: ‹...› · Versiones fijadas en: ‹lockfile›

## Quick Start
- Instalar + verificar base: `./init.sh`
- Arrancar: `‹START_CMD real›`
- Verificación completa: `‹VERIFY_CMD real›`

## Restricciones duras (no negociables — máx ~15)
1. NUNCA commitear `.env*`, claves ni secretos.
2. Sin dependencias nuevas sin registrarlas en DECISIONS.md.
3. No romper la base: si `./init.sh` falla, arréglalo antes de cualquier feature.
4. ‹restricciones específicas del proyecto›

## Reglas de trabajo (harness)
- WIP=1: una feature en in_progress; la siguiente solo cuando la actual esté `passing`.
- Definition of Done: verificación EJECUTADA + evidencia en feature_list.json. "Se ve bien" NO es done.
- Pass-gating: no marques `passing` sin correr la verificación en esta sesión.
- Maker ≠ checker: al verificar, actúa como evaluador escéptico, no como autor.

## Arranque de sesión (en orden)
1. `pwd` 2. leer claude-progress.md 3. leer feature_list.json 4. `git log --oneline -5` 5. `./init.sh`
6. si la base falla → arreglarla primero 7. tomar la feature de mayor prioridad y trabajar SOLO en ella

## Cierre de sesión (5 dimensiones)
- [ ] build/tipos pasan · [ ] tests pasan · [ ] claude-progress.md actualizado
- [ ] feature_list.json refleja estado real (sin passing falsos) · [ ] sin debug/temporales · [ ] commit seguro

## Docs temáticos
- DECISIONS.md — decisiones + hallazgos. ‹README, ARCHITECTURE, todo.md según existan›
