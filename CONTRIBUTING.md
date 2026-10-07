# Contribuir a arnes-implementador

Aportes bienvenidos: adaptadores de stack (`skill/arnes-implementador/references/stack-adapters.md`),
mejoras al playbook de diagnóstico, casos de fallo reales de campo, correcciones de texto.

## Antes de abrir un PR
1. Para cambios grandes, abre un issue y acuerda el enfoque.
2. Edita solo `skill/arnes-implementador/`. **No edites `dist/` a mano.**
3. Valida y reempaqueta (Linux/macOS/WSL — Windows pierde el bit ejecutable de `init.sh`):
   ```bash
   pip install pyyaml
   python3 scripts/validate_skill.py skill/arnes-implementador --package dist
   bash evals/check.sh
   ```
4. Si el cambio es visible para el usuario, añade una línea en `CHANGELOG.md` bajo `[Unreleased]`.
5. CI debe pasar: frontmatter válido, `SKILL.md` < 500 líneas, `bash -n` de plantillas, JSON válido,
   `dist/` idéntico en contenido a `skill/`, `metadata.version` == última entrada del CHANGELOG.

## Reglas del skill
- Español primero; TL;DR en inglés en el README.
- `description` ≤ 1024 caracteres, sin `<` ni `>`. Claves de frontmatter permitidas: `name`,
  `description`, `license`, `allowed-tools`, `metadata`, `compatibility`.
- Nunca introduzcas instrucciones que lleven al agente a declarar "listo" sin verificación, a ejecutar
  código de un repo desconocido sin confirmación, o a reescribir historia git sin confirmación humana.
- Cada mejora que venga de un fallo real de campo: documenta el caso en el CHANGELOG (es cómo el skill aprende).

## Releases (mantenedores)
1. Sube `metadata.version` en `SKILL.md`; mueve `[Unreleased]` a `## [X.Y.Z] - AAAA-MM-DD`.
2. Reempaqueta `dist/`, PR, merge.
3. `git tag vX.Y.Z && git push origin vX.Y.Z` → `release.yml` publica el `.skill` y `SHA256SUMS`.
