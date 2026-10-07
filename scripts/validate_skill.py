#!/usr/bin/env python3
"""validate_skill.py — valida y empaqueta un Claude Skill (equivalente mínimo de
package_skill.py + quick_validate.py del skill-creator de Anthropic).

Uso:
  python3 scripts/validate_skill.py skill/arnes-implementador                 # solo validar
  python3 scripts/validate_skill.py skill/arnes-implementador --package dist   # validar + crear dist/<name>.skill
  python3 scripts/validate_skill.py skill/arnes-implementador --check dist/arnes-implementador.skill
                                    # validar + reempaquetar en memoria + comparar CONTENIDO con el .skill dado

Validaciones (mismas reglas que quick_validate.py):
  - SKILL.md existe y es el único SKILL.md bajo la carpeta
  - frontmatter YAML entre '---' que sea dict
  - solo claves permitidas: name, description, license, allowed-tools, metadata, compatibility
  - name: presente, kebab-case [a-z0-9-], sin '-' inicial/final ni '--', <=64 chars
  - description: presente, sin '<' ni '>', <=1024 chars
  - compatibility (opcional): string <=500 chars
Extras de este repo:
  - name == nombre de la carpeta (evita zips con ruta distinta al skill)
  - SKILL.md < 500 líneas
  - metadata.version (si existe) con formato semver X.Y.Z

El zip es determinista (entradas ordenadas, mtime fijo, permisos normalizados) para que
dos builds del mismo árbol produzcan bytes idénticos.
Solo depende de la stdlib + PyYAML (pip install pyyaml).
"""
from __future__ import annotations

import argparse
import fnmatch
import io
import re
import sys
import zipfile
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    print("ERROR: falta PyYAML (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

ALLOWED_PROPERTIES = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}
EXCLUDE_DIRS = {"__pycache__", "node_modules"}
EXCLUDE_GLOBS = {"*.pyc"}
EXCLUDE_FILES = {".DS_Store"}
ROOT_EXCLUDE_DIRS = {"evals"}
MAX_SKILL_MD_LINES = 500
FIXED_DATE = (1980, 1, 1, 0, 0, 0)  # mínimo que acepta ZIP; hace el build reproducible
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def should_exclude(rel: Path) -> bool:
    parts = rel.parts
    if any(p in EXCLUDE_DIRS for p in parts):
        return True
    if len(parts) > 1 and parts[1] in ROOT_EXCLUDE_DIRS:
        return True
    if rel.name in EXCLUDE_FILES:
        return True
    return any(fnmatch.fnmatch(rel.name, g) for g in EXCLUDE_GLOBS)


def validate(skill_path: Path) -> dict:
    if not skill_path.is_dir():
        fail(f"no es un directorio: {skill_path}")
    skill_md = skill_path / "SKILL.md"
    if not skill_md.is_file():
        fail(f"no existe {skill_md}")
    extras = [p for p in skill_path.rglob("SKILL.md") if p.resolve() != skill_md.resolve()]
    if extras:
        fail("hay más de un SKILL.md: " + ", ".join(str(p.relative_to(skill_path)) for p in extras))

    content = skill_md.read_text(encoding="utf-8")
    if not content.startswith("---"):
        fail("SKILL.md sin frontmatter YAML")
    m = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not m:
        fail("frontmatter mal formado")
    try:
        fm = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        fail(f"YAML inválido en frontmatter: {e}")
    if not isinstance(fm, dict):
        fail("el frontmatter debe ser un diccionario YAML")

    unexpected = set(fm) - ALLOWED_PROPERTIES
    if unexpected:
        fail(f"claves no permitidas en frontmatter: {sorted(unexpected)}; permitidas: {sorted(ALLOWED_PROPERTIES)}")
    if "name" not in fm:
        fail("falta 'name' en frontmatter")
    if "description" not in fm:
        fail("falta 'description' en frontmatter")

    name = fm["name"]
    if not isinstance(name, str):
        fail(f"name debe ser string, es {type(name).__name__}")
    name = name.strip()
    if not re.match(r"^[a-z0-9-]+$", name):
        fail(f"name '{name}' debe ser kebab-case (a-z, 0-9, '-')")
    if name.startswith("-") or name.endswith("-") or "--" in name:
        fail(f"name '{name}' no puede empezar/terminar con '-' ni contener '--'")
    if len(name) > 64:
        fail(f"name demasiado largo ({len(name)} > 64)")
    if name != skill_path.name:
        fail(f"name '{name}' no coincide con la carpeta '{skill_path.name}'")

    desc = fm["description"]
    if not isinstance(desc, str):
        fail(f"description debe ser string, es {type(desc).__name__}")
    desc = desc.strip()
    if not desc:
        fail("description vacía")
    if "<" in desc or ">" in desc:
        fail("description no puede contener '<' ni '>'")
    if len(desc) > 1024:
        fail(f"description demasiado larga ({len(desc)} > 1024)")

    compat = fm.get("compatibility", "")
    if compat:
        if not isinstance(compat, str):
            fail("compatibility debe ser string")
        if len(compat) > 500:
            fail(f"compatibility demasiado larga ({len(compat)} > 500)")

    n_lines = content.count("\n") + (0 if content.endswith("\n") else 1)
    if n_lines >= MAX_SKILL_MD_LINES:
        fail(f"SKILL.md tiene {n_lines} líneas; debe ser < {MAX_SKILL_MD_LINES}")

    version = None
    meta = fm.get("metadata")
    if isinstance(meta, dict) and "version" in meta:
        version = str(meta["version"])
        if not SEMVER_RE.match(version):
            fail(f"metadata.version '{version}' no es semver X.Y.Z")

    print(f"OK: skill '{name}' válido (description={len(desc)} chars, SKILL.md={n_lines} líneas"
          + (f", version={version}" if version else "") + ")")
    return {"name": name, "version": version}


def collect(skill_path: Path) -> list[tuple[str, Path]]:
    root = skill_path.parent
    entries = []
    for p in sorted(skill_path.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(root)
        if should_exclude(rel):
            continue
        entries.append((rel.as_posix(), p))
    return entries


def build_zip(skill_path: Path) -> bytes:
    """Zip determinista con la misma estructura que package_skill.py: <name>/..."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for arcname, p in collect(skill_path):
            zi = zipfile.ZipInfo(arcname, date_time=FIXED_DATE)
            zi.compress_type = zipfile.ZIP_DEFLATED
            mode = 0o755 if (p.stat().st_mode & 0o111) else 0o644
            zi.external_attr = (0o100000 | mode) << 16
            zf.writestr(zi, p.read_bytes())
    return buf.getvalue()


def zip_manifest(data: bytes) -> dict[str, bytes]:
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        return {i.filename: zf.read(i) for i in zf.infolist() if not i.is_dir()}


def check_against(skill_path: Path, dist_file: Path) -> None:
    if not dist_file.is_file():
        fail(f"no existe {dist_file}")
    want = zip_manifest(build_zip(skill_path))
    have = zip_manifest(dist_file.read_bytes())
    problems = []
    for k in sorted(set(want) | set(have)):
        if k not in have:
            problems.append(f"falta en dist: {k}")
        elif k not in want:
            problems.append(f"sobra en dist: {k}")
        elif want[k] != have[k]:
            problems.append(f"contenido distinto: {k}")
    if problems:
        print("\n".join(problems))
        fail(f"{dist_file} NO coincide con {skill_path} (reempaqueta: --package {dist_file.parent})")
    print(f"OK: {dist_file} coincide con el contenido de {skill_path} ({len(want)} archivos)")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("skill_dir")
    ap.add_argument("--package", metavar="OUT_DIR", help="escribe OUT_DIR/<name>.skill")
    ap.add_argument("--check", metavar="SKILL_FILE", help="compara contenido con un .skill existente")
    args = ap.parse_args()

    skill_path = Path(args.skill_dir).resolve()
    info = validate(skill_path)

    if args.package:
        out = Path(args.package).resolve()
        out.mkdir(parents=True, exist_ok=True)
        target = out / f"{info['name']}.skill"
        target.write_bytes(build_zip(skill_path))
        print(f"OK: empaquetado {target}")

    if args.check:
        check_against(skill_path, Path(args.check).resolve())


if __name__ == "__main__":
    main()
