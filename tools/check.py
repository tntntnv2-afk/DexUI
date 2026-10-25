"""Checks before committing: every Lua file compiles, and every DefineAsset path exists.

  python tools/check.py

Compiling needs luau-compile on PATH (it's skipped with a note when it isn't there).
"""
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSET_RE = re.compile(r'DefineAsset\(\s*"([^"]+)"\s*,\s*\{[^}]*?Path\s*=\s*"([^"]+)"')


def main():
    problems = []
    lua_files = [p for p in ROOT.rglob("*.lua") if ".git" not in p.parts]
    compiler = shutil.which("luau-compile")
    for path in lua_files:
        if compiler:
            result = subprocess.run([compiler, str(path)], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            if result.returncode != 0:
                problems.append(f"{path.relative_to(ROOT)}: {result.stderr.decode('utf-8', 'replace').strip()}")
    for path in ROOT.joinpath("src").rglob("*.lua"):
        for name, rel in ASSET_RE.findall(path.read_text(encoding="utf-8")):
            if not (ROOT / rel).is_file():
                problems.append(f"{path.relative_to(ROOT)}: asset {name} points at {rel}, which isn't in the repo")
    if not compiler:
        print("(luau-compile not found: Lua files not compile-checked)")
    for problem in problems:
        print(problem)
    print("check ok" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
