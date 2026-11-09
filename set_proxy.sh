#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/proxy.conf"

echo "=========================================================="
echo "          CDDM Live — Network Proxy Configuration         "
echo "=========================================================="
echo "Select your network environment:"
echo "  1) Direct Internet (Home, Mobile Hotspot, Open Wi-Fi)"
echo "  2) Custom Institutional Proxy (Specify IP & Port)"
echo "  3) Default Lab Proxy (http://192.168.101.19:3128)"
echo "  4) View current proxy configuration"
echo "=========================================================="
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        echo "DIRECT" > "$CONFIG_FILE"
        echo "✓ Configured for Direct Internet connection (No proxy)."
        ;;
    2)
        read -p "Enter Proxy URL (e.g., http://proxy.univ.edu:3128): " user_proxy
        if [ -n "$user_proxy" ]; then
            if [[ ! "$user_proxy" =~ ^https?:// ]]; then
                user_proxy="http://$user_proxy"
            fi
            echo "$user_proxy" > "$CONFIG_FILE"
            echo "✓ Proxy saved: $user_proxy"
        else
            echo "[-] No URL entered. Aborted."
        fi
        ;;
    3)
        echo "http://192.168.101.19:3128" > "$CONFIG_FILE"
        echo "✓ Configured for default Lab Proxy (http://192.168.101.19:3128)."
        ;;
    4)
        if [ -f "$CONFIG_FILE" ]; then
            echo "Current configuration: $(cat "$CONFIG_FILE")"
        else
            echo "Current configuration: Default Lab Proxy (http://192.168.101.19:3128)"
        fi
        ;;
    *)
        echo "Invalid selection."
        ;;
esac
echo "=========================================================="
