#!/usr/bin/env bash
set -e

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SRC="$APP_DIR/program/cddis_icon.png"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

echo "=== Installing CDDM Live on this system ==="

# 1. Verify Python 3
if ! command -v python3 &>/dev/null; then
    echo "[-] Error: python3 is not installed. Please install it with: sudo apt install python3 python3-venv"
    exit 1
fi

# 2. Setup Virtual Environment
if [ ! -d "$APP_DIR/venv" ]; then
    echo "[+] Creating virtual environment in ./venv..."
    python3 -m venv "$APP_DIR/venv"
fi

echo "[+] Installing required Python packages..."
"$APP_DIR/venv/bin/python3" -m pip install --upgrade pip --quiet
"$APP_DIR/venv/bin/python3" -m pip install -r "$APP_DIR/requirements.txt" --quiet

# 3. Install Icon to system spec directory
mkdir -p "$ICON_DIR"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$ICON_DIR/cddis_icon.png"
    echo "[+] Installed application icon to $ICON_DIR"
fi

# 4. Generate user-specific .desktop entry
mkdir -p "$DESKTOP_DIR"
cat << DESKTOP_CONTENT > "$DESKTOP_DIR/cddm.desktop"
[Desktop Entry]
Version=1.1
Type=Application
Name=CDDM Live v1.1
GenericName=GNSS CDDIS Monitor
Comment=NASA CDDIS GNSS Station Upload Availability Monitor
Exec=$APP_DIR/run_cddm.sh
Icon=$ICON_DIR/cddis_icon.png
Terminal=false
Categories=Science;Geology;Engineering;
StartupNotify=true
StartupWMClass=cddm
DESKTOP_CONTENT

chmod +x "$DESKTOP_DIR/cddm.desktop"
chmod +x "$APP_DIR/run_cddm.sh"

# 5. Refresh system desktop database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "==========================================="
echo "✓ Installation completed successfully!"
echo "You can now run CDDM from your Applications menu or with ./run_cddm.sh"
echo "==========================================="
