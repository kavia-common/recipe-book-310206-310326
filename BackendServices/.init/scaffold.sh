#!/usr/bin/env bash
set -euo pipefail
# Minimal deterministic scaffolding for FastAPI app
WORKSPACE="/home/kavia/workspace/code-generation/recipe-book-310206-310326/BackendServices"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
mkdir -p app/routes app/services app/models tests data logs
# main app
cat > "$WORKSPACE/app/main.py" <<'PY'
from fastapi import FastAPI
from app.routes import health, recommendations
app = FastAPI()
app.include_router(health.router)
app.include_router(recommendations.router)
PY
# health route
cat > "$WORKSPACE/app/routes/health.py" <<'PY'
from fastapi import APIRouter
router = APIRouter(prefix="/health")
@router.get("/")
def status():
    return {"status":"ok"}
PY
# recommendations route
cat > "$WORKSPACE/app/routes/recommendations.py" <<'PY'
from fastapi import APIRouter
from app.services.recommendations import get_recommendations
router = APIRouter(prefix="/recommendations")
@router.get("/")
def list_recs():
    return {"items": get_recommendations()}
PY
# service
cat > "$WORKSPACE/app/services/recommendations.py" <<'PY'
_data = [{"id":1,"text":"Try the tomato soup"}]
def get_recommendations():
    return _data
PY
# models package placeholder
cat > "$WORKSPACE/app/models/__init__.py" <<'PY'
# models placeholder
PY
# requirements pinned to FastAPI compatible with Pydantic 1.x and test deps
cat > "$WORKSPACE/requirements.txt" <<'TXT'
fastapi==0.95.2
pydantic==1.10.12
uvicorn
requests==2.31.0
pytest==7.4.0
httpx==0.24.1
# optional: psycopg2-binary (install separately if using Postgres)
TXT
# gitignore
cat > "$WORKSPACE/.gitignore" <<'TXT'
__pycache__/
.venv/
data/*.sqlite
.env.backendservices
logs/
TXT
# deterministic start script preferring workspace .venv
cat > "$WORKSPACE/start.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-book-310206-310326/BackendServices"
cd "$WORKSPACE"
[ -f "$WORKSPACE/.env.backendservices" ] && . "$WORKSPACE/.env.backendservices"
VENV_PY="$WORKSPACE/.venv/bin/python"
if [ -x "$VENV_PY" ]; then
  exec "$VENV_PY" -m uvicorn ${APP_MODULE:-app.main:app} --host 0.0.0.0 --port 8000
else
  exec python3 -m uvicorn ${APP_MODULE:-app.main:app} --host 0.0.0.0 --port 8000
fi
SH
chmod 0755 "$WORKSPACE/start.sh"
# basic test
cat > "$WORKSPACE/tests/test_health.py" <<'PY'
from fastapi.testclient import TestClient
from app.main import app

def test_health_ok():
    client = TestClient(app)
    r = client.get('/health/')
    assert r.status_code == 200
    assert r.json() == {"status":"ok"}
PY
# ensure sqlite DB exists
SQLITE_FILE="$WORKSPACE/data/dev.sqlite"
if [ ! -f "$SQLITE_FILE" ]; then
  python3 - <<PY
import sqlite3, os
os.makedirs(os.path.dirname('$SQLITE_FILE'), exist_ok=True)
conn=sqlite3.connect('$SQLITE_FILE')
conn.execute('PRAGMA user_version=1')
conn.commit(); conn.close()
PY
fi
# permissions: dirs 755, files 644, scripts executable
find "$WORKSPACE" -type d -exec chmod 755 {} +
find "$WORKSPACE" -type f -exec chmod 644 {} +
chmod 0755 "$WORKSPACE/start.sh" || true

# Print summary for logs (minimal)
echo "scaffold: created project at $WORKSPACE"
