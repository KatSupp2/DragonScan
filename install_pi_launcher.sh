#!/usr/bin/env bash
# Lets the website's Open scanner button start the DragonScan App on this Raspberry Pi.
# No server runs and no network port opens. The browser hands dragonscan:// links to the desktop.
#
#   bash install_pi_launcher.sh            install, or update after moving the project
#   bash install_pi_launcher.sh --remove   remove it
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dragonscan"
MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
ENTRY="dragonscan-launch.desktop"
LAUNCHER="$STATE/open-scanner.sh"

refresh() {
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database "$APPS" >/dev/null 2>&1 || true
    fi
}

if [ "${1:-}" = "--remove" ]; then
    rm -f "$APPS/$ENTRY" "$LAUNCHER"
    if [ -f "$MIMEAPPS" ]; then
        sed -i '/^x-scheme-handler\/dragonscan=/d' "$MIMEAPPS"
    fi
    refresh
    echo "Removed. The website's Open scanner button no longer starts the app on this Pi."
    exit 0
fi

for tool in xdg-mime flock; do
    if ! command -v "$tool" >/dev/null; then
        echo "Missing $tool. Run: sudo apt install -y xdg-utils util-linux" >&2
        exit 1
    fi
done
if [ ! -f "$PROJECT/run_dragonscan.sh" ]; then
    echo "Keep this script in the DragonScan folder, next to run_dragonscan.sh." >&2
    exit 1
fi

mkdir -p "$APPS" "$STATE"

# The link's address is never used, so a web page cannot pass anything to the app.
# The lock stays held while the app runs, so a second click does nothing.
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
exec 9>$(printf '%q' "$STATE/lock")
flock -n 9 || exit 0
cd $(printf '%q' "$PROJECT")
exec bash run_dragonscan.sh >>$(printf '%q' "$STATE/scanner.log") 2>&1
EOF
chmod +x "$LAUNCHER"

cat > "$APPS/$ENTRY" <<EOF
[Desktop Entry]
Type=Application
Name=DragonScan App
Exec="$LAUNCHER" %u
Terminal=false
NoDisplay=true
MimeType=x-scheme-handler/dragonscan;
EOF

refresh
xdg-mime default "$ENTRY" x-scheme-handler/dragonscan

echo "Installed. Open the website in Firefox, go to Scanner app, and choose Open scanner."
echo "The first time, Firefox asks to open the link. Choose DragonScan App and allow it."
echo "If the app does not appear, check $STATE/scanner.log"
