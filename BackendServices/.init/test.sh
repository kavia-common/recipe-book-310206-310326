#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-book-310206-310326/BackendServices"
cd "$WORKSPACE"
VENV_PYTEST="$WORKSPACE/.venv/bin/pytest"
[ -x "$VENV_PYTEST" ] || { echo 'pytest not available in venv; run deps-001' >&2; exit 2; }
# run pytest quietly
"$VENV_PYTEST" -q || { echo 'pytest failed' >&2; exit 3; }
