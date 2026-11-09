#!/usr/bin/env bash

# Use active system proxy only if explicitly defined; otherwise run direct
export HTTP_PROXY="${HTTP_PROXY:-$http_proxy}"
export HTTPS_PROXY="${HTTPS_PROXY:-$https_proxy}"

echo "=========================================================="
echo "    CDDM Live — Network Diagnostic & Handshake Engine     "
echo "=========================================================="

if [ -n "$HTTPS_PROXY" ]; then
    echo "Active Proxy: $HTTPS_PROXY"
else
    echo "Active Connection: Direct (No proxy configured)"
fi
echo ""

# [1/4] Virtual Environment & Core Libraries
echo "[1/4] Checking Python Virtual Environment & Core Libraries..."
PYTHON_BIN="./venv/bin/python3"
if [ ! -f "$PYTHON_BIN" ]; then
    echo "  ❌ Virtual environment not found at $PYTHON_BIN."
    echo "     Please run ./install.sh first."
    exit 1
fi
echo "  ✓ Virtual environment found."

$PYTHON_BIN -c "import PySide6, requests, netrc" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✓ PySide6, requests, and netrc libraries loaded successfully."
else
    echo "  ❌ Missing dependencies in virtual environment."
    exit 1
fi

# [2/4] Direct / Proxy Reachability Test to CDDIS
echo ""
echo "[2/4] Testing Connectivity to NASA CDDIS Archive..."
if [ -n "$HTTPS_PROXY" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --proxy "$HTTPS_PROXY" --connect-timeout 10 https://cddis.nasa.gov || echo "ERR")
else
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 https://cddis.nasa.gov || echo "ERR")
fi

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  ✓ Successfully reached NASA CDDIS server (HTTP $HTTP_CODE)."
else
    echo "  ❌ Connection failed (curl status: $HTTP_CODE)."
    echo "     Check your internet connection, DNS, or firewall settings."
fi

# [3/4] Earthdata Credentials & Authorization
echo ""
echo "[3/4] Checking Earthdata Credentials (~/.netrc)..."
$PYTHON_BIN - << 'PYEOF'
import netrc, sys

try:
    auth = netrc.netrc().authenticators("urs.earthdata.nasa.gov")
    if auth and auth[0] and auth[2]:
        print(f"  ✓ Found credentials for user: {auth[0]}")
    else:
        print("  ⚠️ 'urs.earthdata.nasa.gov' entry in ~/.netrc is incomplete.")
        sys.exit(1)
except FileNotFoundError:
    print("  ℹ️ No ~/.netrc file found yet. (Credentials will be requested at login).")
except Exception as e:
    print(f"  ❌ Error reading ~/.netrc: {e}")
    sys.exit(1)
PYEOF

# [4/4] Authenticated CDDIS Session Handshake
echo ""
echo "[4/4] Testing CDDIS API Handshake..."
$PYTHON_BIN - << 'PYEOF'
import sys, requests, netrc
from requests.auth import HTTPBasicAuth

try:
    auth = netrc.netrc().authenticators("urs.earthdata.nasa.gov")
except Exception:
    auth = None

if not auth or not auth[0] or not auth[2]:
    print("  ℹ️ Skipping authenticated test (no credentials stored in ~/.netrc).")
    sys.exit(0)

user, pwd = auth[0], auth[2]

class DiagSession(requests.Session):
    def __init__(self):
        super().__init__()
        self.auth_creds = (user, pwd)
        self.auth = HTTPBasicAuth(user, pwd)
        self.trust_env = True

    def rebuild_auth(self, prepared_request, response):
        if "urs.earthdata.nasa.gov" in prepared_request.url and self.auth_creds:
            prepared_request.prepare_auth(HTTPBasicAuth(*self.auth_creds))
            return
        super().rebuild_auth(prepared_request, response)

s = DiagSession()
test_url = "https://cddis.nasa.gov/archive/gnss/data/daily/"

try:
    r = s.get(test_url, timeout=20)
    if r.status_code == 200:
        print(f"  ✓ Authenticated handshake verified (HTTP 200).")
    elif r.status_code == 401:
        print("  ❌ Authentication rejected (HTTP 401). Check password or account status.")
    else:
        print(f"  ❌ Received HTTP {r.status_code} from CDDIS archive.")
except Exception as e:
    print(f"  ❌ Session error: {type(e).__name__}: {e}")
PYEOF

echo ""
echo "=========================================================="
echo "Diagnostic Run Completed."
echo "=========================================================="
