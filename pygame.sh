#!/bin/sh
# pdeps.sh — robust Python deps installer for RGSX

set -e

REQ_DIR="/storage/roms/ports/RGSX"
REQ_FILE="$REQ_DIR/requirements.txt"

# 1) Pick a Python interpreter
pick_python() {
  for cand in python3.13 python3 python /usr/bin/python3.13 /usr/bin/python3 /usr/bin/python; do
    if command -v "$cand" >/dev/null 2>&1; then
      echo "$cand"
      return 0
    fi
  done
  echo "ERROR: No Python interpreter found." >&2
  exit 1
}

PY="$(pick_python)"

# 2) Ensure a requirements.txt exists
if [ ! -f "$REQ_FILE" ]; then
  mkdir -p "$REQ_DIR"
  cat >"$REQ_FILE" <<'EOF'
pygame==2.6.1
requests
# add more modules your game needs below
EOF
  echo "Created default requirements.txt at $REQ_FILE"
fi

# 3) Make user site predictable and on sys.path
export PYTHONUSERBASE=/storage/.local
export PYTHONPATH="$PYTHONUSERBASE/lib/python3.13/site-packages:$PYTHONPATH"
export PATH="$HOME/.local/bin:$PATH"

# 4) Make sure pip exists (use ensurepip if needed)
have_pip() {
  "$PY" -m pip --version >/dev/null 2>&1
}

if ! have_pip; then
  echo "Bootstrapping pip with ensurepip..."
  if ! "$PY" -m ensurepip --upgrade >/dev/null 2>&1; then
    echo "WARNING: ensurepip not available for $PY. Trying to continue if pip appears later..." >&2
  fi
fi

# Re-check pip
if ! have_pip; then
  echo "ERROR: pip is still unavailable under '$PY'."
  echo "If this is a minimal firmware without ensurepip, use a Python that includes pip, or create a venv:"
  echo "  $PY -m venv /storage/pyenv && . /storage/pyenv/bin/activate && pip install -U pip"
  exit 2
fi

# 5) Install/upgrade core tooling (avoid pyc compile to prevent AssertionError)
echo "Upgrading pip/setuptools/wheel..."
PIP_BREAK_SYSTEM_PACKAGES=1 \
"$PY" -m pip install --user --no-compile -U pip setuptools wheel

# 6) Install project deps (no pyc compile avoids read-only bytecode issues)
echo "Installing Python dependencies from $REQ_FILE..."
PIP_BREAK_SYSTEM_PACKAGES=1 \
"$PY" -m pip install --user --no-compile -r "$REQ_FILE"

echo "All set. Test import:"
"$PY" - <<'PYCODE'
import sys
print("Python:", sys.version.split()[0])
for m in ("pygame","requests"):
    try:
        mod = __import__(m)
        print(f"  {m}: OK ({getattr(mod,'__version__','?')})")
    except Exception as e:
        print(f"  {m}: FAIL ({e})")
PYCODE


