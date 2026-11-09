#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

VENV_PY="$DIR/venv/bin/python3"

# Self-Healing Check: Verify if venv exists and can import PySide6 & requests
NEEDS_REBUILD=0

if [ ! -x "$VENV_PY" ]; then
    NEEDS_REBUILD=1
elif ! "$VENV_PY" -c "import requests, PySide6" >/dev/null 2>&1; then
    NEEDS_REBUILD=1
fi

if [ $NEEDS_REBUILD -eq 1 ]; then
    echo "=========================================================="
    echo "  System update detected! Auto-repairing CDDM environment..."
    echo "=========================================================="
    rm -rf "$DIR/venv"
    python3 -m venv "$DIR/venv"
    "$DIR/venv/bin/pip" install --upgrade pip >/dev/null 2>&1
    "$DIR/venv/bin/pip" install requests PySide6 certifi
    echo "✓ Repair complete. Launching CDDM..."
fi

exec "$VENV_PY" "$DIR/program/cddis_monitor.py" "$@"
