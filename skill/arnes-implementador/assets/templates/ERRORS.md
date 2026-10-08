# Registro de Errores — ‹PROYECTO›
> Este archivo se commitea. NUNCA pegues aquí valores de secretos/tokens (ni parciales), salida cruda de
> comandos sin redactar, connection strings, rutas absolutas de tu máquina ni SHAs de commits que contuvieron
> secretos. Evidencia = resumen ("tsc: 0 errores; vitest: 42/42"), no volcado.

> Cuándo: error que tomó más de 5 min o cuya causa no era obvia, registrado en el momento.
> Cómo se usa: antes de tocar un área, `grep -n -i '‹archivo|servicio|síntoma›' ERRORS.md`. No se lee entero.
> Nunca un síntoma sin causa raíz: si no se conoce, estado `abierto` + hipótesis en curso.
> Recurrente → su prevención se promueve a check en `init.sh` o CI.
> Más de 40 entradas activas → archivar las resueltas hace más de 90 días en `docs/harness/archive/`.

## ERR-001 — ‹título corto› · ‹fecha› · estado: resuelto|abierto|recurrente
- Síntoma: ‹lo que se veía (mensaje clave, no volcado)›
- Causa raíz: ‹por qué ocurrió de verdad› (capa: tarea|contexto|entorno|verificación|estado)
- Solución: ‹qué se cambió (archivo:línea)›
- Prevención: ‹check ejecutable o feature que lo detecta; si no admite check, decirlo›
