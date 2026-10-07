# Política de seguridad

## Qué cubre
`arnes-implementador` es un Claude Skill (Markdown + plantillas). No ejecuta código por sí mismo, pero sus
instrucciones guían a un agente que sí ejecuta comandos en tu repo. Consideramos problema de seguridad:
- Instrucciones o plantillas que puedan llevar al agente a exponer secretos, ejecutar comandos destructivos
  sin confirmación, instalar/ejecutar código de un repo no confiable sin aviso, o reescribir historial git
  fuera del SOP documentado.
- Un `.skill` publicado cuyo contenido no coincide con `skill/` en el tag correspondiente.
- Inyección de instrucciones a través de archivos del repo auditado que el skill no neutralice.

## Cómo reportar
No abras un issue público. Usa **"Report a vulnerability"** en la pestaña Security del repositorio
(GitHub Private Vulnerability Reporting). Incluye versión (`metadata.version` o tag), entorno (Claude Code /
Cowork), pasos para reproducir e impacto. Respuesta inicial en 7 días; corrección como nueva versión con
nota en `CHANGELOG.md`.

## Verificar lo que instalas
Cada Release adjunta `SHA256SUMS`: `sha256sum -c SHA256SUMS` antes de instalar. Solo se da soporte a la
última versión publicada.
