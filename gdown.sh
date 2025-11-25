#!/bin/sh
# Minimal, safer installer for pip + gdown on funky Python environments (Batocera, SM8550, etc.)

set -e

PYTHON=python3

echo "==> Checking for python3..."
if ! command -v "$PYTHON" >/dev/null 2>&1; then
    echo "Error: python3 not found in PATH." >&2
    exit 1
fi

echo "==> Ensuring pip exists (python3 -m ensurepip)..."
# Don't die if ensurepip no-ops or complains
if ! "$PYTHON" -m ensurepip --upgrade 2>/dev/null; then
    echo "   (ensurepip failed or is already set up; continuing)"
fi

# Figure out user base and bin dir *before* installing
USER_BASE=$("$PYTHON" -m site --user-base 2>/dev/null || echo "$HOME/.local")
BIN_DIR="$USER_BASE/bin"
mkdir -p "$BIN_DIR"

echo "==> Installing / upgrading gdown with no bytecode compilation..."
# Global env and explicit flag to avoid the pyc assertion
export PIP_NO_COMPILE=1
"$PYTHON" -m pip install --user --upgrade --no-compile --no-cache-dir gdown

echo "   gdown install step finished."

echo "==> Adding $BIN_DIR to PATH for this session..."
case ":$PATH:" in
    *":$BIN_DIR:"*) echo "   (already in PATH)";;
    *) export PATH="$PATH:$BIN_DIR";;
esac

# Persist PATH in startup files
add_path_line='export PATH="$PATH:'"$BIN_DIR"'"'

update_rc_file() {
    rc="$1"
    [ -e "$rc" ] || touch "$rc"
    if ! grep -F "$BIN_DIR" "$rc" >/dev/null 2>&1; then
        echo "$add_path_line" >> "$rc"
        echo "   Added PATH update to $rc"
    else
        echo "   PATH already present in $rc"
    fi
}

echo "==> Making PATH persistent..."
update_rc_file "$HOME/.profile"
update_rc_file "$HOME/.bashrc"

# Optional: wrapper in /storage/bin if that dir exists (Batocera/Rocknix-style)
if [ -d /storage/bin ]; then
    WRAP=/storage/bin/gdown
    if [ ! -x "$WRAP" ]; then
        echo "==> Creating wrapper script at $WRAP"
        cat >"$WRAP" <<EOF
#!/bin/sh
exec "$BIN_DIR/gdown" "\$@"
EOF
        chmod +x "$WRAP"
    else
        echo "   Wrapper /storage/bin/gdown already exists"
    fi
fi

echo "==> Test:"
if command -v gdown >/dev/null 2>&1; then
    gdown --version || true
elif [ -x "$BIN_DIR/gdown" ]; then
    "$BIN_DIR/gdown" --version || true
else
    echo "gdown installed, but not on PATH. You can still run:"
    echo "  \"$BIN_DIR/gdown\" URL_OR_ID"
fi

echo
echo "Example usage:"
echo "  gdown \"https://drive.google.com/file/d/FILE_ID/view?usp=sharing\""
