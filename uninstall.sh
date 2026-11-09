#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================================="
echo "          CDDM Live v1.1 — Clean Uninstaller             "
echo "=========================================================="

# 1. Remove Linux desktop autostart entry
AUTOSTART_FILE="$HOME/.config/autostart/cddis_monitor.desktop"
if [ -f "$AUTOSTART_FILE" ]; then
    rm -f "$AUTOSTART_FILE"
    echo "✓ Removed system login autostart entry."
fi

# 2. Remove desktop shortcut entries
for dfile in "$HOME/.local/share/applications/cddm.desktop" "$HOME/.local/share/applications/cddm_live.desktop"; do
    if [ -f "$dfile" ]; then
        rm -f "$dfile"
        echo "✓ Removed application launcher shortcut: $(basename "$dfile")"
    fi
done

# Remove copied icon from system icon theme
SYSTEM_ICON="$HOME/.local/share/icons/hicolor/256x256/apps/cddis_icon.png"
if [ -f "$SYSTEM_ICON" ]; then
    rm -f "$SYSTEM_ICON"
    echo "✓ Removed application icon from system theme cache."
fi

# Refresh desktop and icon database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# 3. Clean virtual environment
if [ -d "venv" ]; then
    echo "--> Removing local virtual environment (venv)..."
    rm -rf venv
    echo "✓ Virtual environment removed."
fi

# 4. Clean local cache and temporary runtime logs
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
rm -rf logs data 2>/dev/null || true
echo "✓ Removed application runtime caches and temporary logs."

echo ""
read -p "Do you also want to remove saved NASA Earthdata credentials from ~/.netrc? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$HOME/.netrc" ]; then
        sed -i '/urs.earthdata.nasa.gov/d' "$HOME/.netrc" 2>/dev/null || true
        echo "✓ Removed Earthdata credentials from ~/.netrc."
    fi
fi

echo "=========================================================="
echo "✓ CDDM Live uninstalled cleanly from this system."
echo "=========================================================="
