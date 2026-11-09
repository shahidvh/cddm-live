#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=========================================================="
echo "          Installing CDDM Live Environment                "
echo "=========================================================="

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

"$DIR/venv/bin/pip" install --upgrade pip

if [ -f "$DIR/requirements.txt" ]; then
    "$DIR/venv/bin/pip" install -r "$DIR/requirements.txt"
else
    "$DIR/venv/bin/pip" install requests PySide6 certifi
fi

echo "=========================================================="
echo "✓ Installation complete! Run './run_cddm.sh' to start CDDM"
echo "=========================================================="
