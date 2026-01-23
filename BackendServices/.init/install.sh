#!/usr/bin/env bash
set -euo pipefail

# Dependencies step: create workspace-local venv, install pinned requirements, verify imports
WORKSPACE="/home/kavia/workspace/code-generation/recipe-book-310206-310326/BackendServices"
cd "$WORKSPACE"

# Basic environment checks
command -v python3 >/dev/null 2>&1 || { echo "python3 not found in PATH" >&2; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo "pip3 not found in PATH" >&2; exit 2; }
# ensure venv module available
python3 -c "import venv" >/dev/null 2>&1 || { echo "python3 venv module missing; install python3-venv" >&2; exit 3; }

# ensure requirements.txt exists
[ -f "$WORKSPACE/requirements.txt" ] || { echo "requirements.txt not found in workspace: $WORKSPACE/requirements.txt" >&2; exit 8; }

# create minimal secure .env if missing
if [ ! -f "$WORKSPACE/.env" ]; then
  umask 077 && printf "# workspace env\n" > "$WORKSPACE/.env" || { echo ".env creation failed" >&2; exit 9; }
fi

# create venv if missing
if [ ! -d "$WORKSPACE/.venv" ]; then
  python3 -m venv "$WORKSPACE/.venv" || { echo 'venv creation failed; ensure python3-venv installed' >&2; exit 4; }
fi

VENV_PY="$WORKSPACE/.venv/bin/python"
VENV_PIP="$WORKSPACE/.venv/bin/pip"
[ -x "$VENV_PY" ] || { echo 'venv missing or invalid' >&2; exit 4; }

# upgrade pip/setuptools/wheel deterministically
"$VENV_PY" -m pip install --no-cache-dir -q --prefer-binary --upgrade pip setuptools wheel || { echo 'pip upgrade failed' >&2; exit 5; }

# install pinned requirements deterministically
"$VENV_PIP" install --no-cache-dir -q --prefer-binary -r "$WORKSPACE/requirements.txt" || { echo 'pip install requirements failed' >&2; exit 6; }

# verify critical imports
"$VENV_PY" - <<'PY' || { echo 'dependency import check failed' >&2; exit 7; }
import sys
try:
    import fastapi, requests, pytest, httpx
except Exception as e:
    print('import-failure:', e, file=sys.stderr)
    sys.exit(1)
print('imports-ok')
PY

# All done
echo 'dependencies: OK'
