# KB — Harness Engineering (principios)

## Definición
Un LLM aislado solo recibe texto y devuelve texto: no ve el repo, no ejecuta comandos, no recuerda sesiones.
El **arnés es TODO lo que está fuera de los pesos del modelo**: instrucciones, herramientas, entorno, gestión
de estado y feedback de verificación. Corolario #1: **cuando algo falla, revisa el arnés antes de cambiar de
modelo.** Un buen AGENTS.md puede rendir más que subir de modelo.

## Los 5 subsistemas (analogía de la cocina)
1. **Instrucciones** (recetario): AGENTS.md/CLAUDE.md — resumen, stack+versiones, comandos, restricciones duras.
2. **Herramientas** (cuchillos): shell, archivos, tests con mínimo privilegio.
3. **Entorno** (estufa): reproducible — lockfiles, versiones fijadas, devcontainers.
4. **Estado** (estación de prep): PROGRESS.md, feature list, commits — persistencia entre sesiones.
5. **Feedback** (control de calidad): comandos de verificación explícitos. **Mayor ROI — configúralo primero.**

Medido: añadir subsistemas por etapas subió el éxito de 20% → 60% (instrucciones) → 80% (verificación) → 80-100% (estado).

## Las 5 capas diagnósticas de fallo
Todo fallo se atribuye a UNA capa: **especificación de tarea · provisión de contexto · entorno de ejecución ·
feedback de verificación · gestión de estado.** Bucle: ejecutar → observar → atribuir capa → corregir esa capa → re-ejecutar.

## Principios destilados
- **L1 Verificación**: brecha entre confianza del agente y corrección real = modo de fallo #1. Definition of Done
  explícita y verificable por máquina para CADA tarea.
- **L3 Repo as spec**: lo que no está en el repo NO EXISTE para el agente. Prueba de arranque en frío (5 preguntas).
  Documentación desincronizada es PEOR que no tener.
- **L4 Divide instrucciones**: archivo raíz = ROUTER 50-200 líneas (lost-in-the-middle: lo del medio se ignora).
  Progressive disclosure a docs temáticos. Ante un error NO añadas otra regla al router.
- **L5 Continuidad**: el agente es un ingeniero brillante con amnesia; dale un diario (PROGRESS + DECISIONS).
  La "ansiedad de contexto" varía por modelo → el arnés es específico por modelo, no talla única.
- **L6 Inicialización como fase separada**: sesión 1 solo cimientos (nada de features). Entorno ejecutable +
  test de ejemplo pasando + contrato de bootstrap + desglose de tareas + commit baseline.
- **L7 WIP=1**: una feature activa; la siguiente solo tras verificación end-to-end. Prohibido "refactorizar de paso".
  Líneas de código correlacionan NEGATIVAMENTE con features completadas.
- **L8 Feature lists como primitiva**: cada feature = (comportamiento observable, comando de verificación, estado).
  **Pass-gating**: solo pasa a `passing` si la verificación se ejecutó con éxito; el harness controla el estado, no el agente.
- **L9 Victoria prematura**: los modelos son sobre-confiados; **separa maker de checker** (evaluador independiente).
  Validación en 3 capas: sintaxis/estático → runtime (tests + arranque real) → E2E.
- **L10 Solo E2E es verificación real**: los unit tests son ciegos a defectos de frontera entre componentes.
  Reglas arquitectónicas → checks ejecutables, no prosa.
- **L12 Clean state al cerrar**: build pasa · tests pasan · progreso registrado · sin artefactos obsoletos ·
  ruta de arranque estándar. La entropía es el default; "limpiar después" = nunca limpiar.
- **L13 Loop engineering**: da una METODOLOGÍA (objetivo + verificación + parada), no una tarea suelta.

## Síntesis operativa
1. Repo as spec. 2. Evidencia > confianza. 3. Maker ≠ checker. 4. WIP=1 + Definition of Done.
5. Router, no enciclopedia. 6. Impón invariantes (checks ejecutables), no microgestiones. 7. Estado en disco.
8. El arnés es específico por modelo y caduca. 9. Cada fallo fortalece el arnés. 10. De prompts a loops.
