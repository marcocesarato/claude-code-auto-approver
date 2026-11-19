#!/bin/bash
# Builds the app, installs it in /Applications (or ~/Applications when that is not
# writable) and starts it.
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="Claude Code - Auto Approver"
BUNDLE_ID="com.marcocesarato.ClaudeCodeAutoApprover"

command -v swift >/dev/null || { echo "❌ Swift not found. Install the Command Line Tools: xcode-select --install"; exit 1; }
scripts/build-app.sh

APPS="/Applications"
[ -w "$APPS" ] || { APPS="$HOME/Applications"; mkdir -p "$APPS"; }
DEST="$APPS/$NAME.app"

pkill -x AutoApprover 2>/dev/null || true
rm -rf "$DEST"
cp -R "build/$NAME.app" "$DEST"
open "$DEST"

cat << EOF
✅ Installed in $DEST and started.

Grant it Accessibility when macOS asks: System Settings → Privacy & Security → Accessibility.
A rebuilt app is a new signature, so after an update reset the old grant first:
    tccutil reset Accessibility $BUNDLE_ID
EOF
