# Registro de Decisiones — ‹PROYECTO›
> Este archivo se commitea. NUNCA pegues aquí valores de secretos/tokens (ni parciales), salida cruda de
> comandos sin redactar, connection strings, rutas absolutas de tu máquina ni SHAs de commits que contuvieron
> secretos. Evidencia = resumen ("tsc: 0 errores; vitest: 42/42"), no volcado.

> Conserva el PORQUÉ. Una entrada por decisión no trivial, escrita en la misma sesión.
> Se consulta con grep, no se lee entero al arrancar. Más de 300 líneas → archivar por trimestre en
> `docs/harness/archive/decisions-AAAA-QN.md` dejando aquí solo lo vigente.
> Formato: fecha · decisión · razón · alternativa rechazada · restricción resultante ·
> (si es arquitectura: punto único de fallo y qué se rompe a escala).

## ‹fecha›: Instalación del arnés mínimo
- Decisión: adoptar el arnés (router + init.sh + progress + feature_list + este registro).
- Razón: fiabilidad multi-sesión; evidencia > confianza; repo como fuente única de verdad.
- Alternativa rechazada: prompting ad-hoc por sesión.
- Restricción: WIP=1 y pass-gating obligatorios.

## ‹fecha›: Hallazgos del diagnóstico
- ‹registrar cada gap/falla no trivial detectado en la auditoría y su arreglo›

## Servicios configurados
> Un bloque por servicio externo (API, DB, auth, webhooks, deploy). Variables por NOMBRE, nunca valores.
> Al instalar, BORRA el bloque de ejemplo si aún no hay servicios configurados.

### ‹Servicio› — configurado ‹fecha› · estado: activo|pendiente|deprecado
- Propósito: ‹qué hace en el proyecto›
- Variables: `‹NOMBRE_VARIABLE›` (en `.env.example`)
- Dónde se configura: ‹dashboard / consola›
- Gotchas: ‹límites, comportamientos no obvios›
