#!/bin/bash
# Quits and removes the app, its labels file and its log.
set -euo pipefail

NAME="Claude Code - Auto Approver"
FOLDER="ClaudeCodeAutoApprover"

pkill -x AutoApprover 2>/dev/null || true
rm -rf "/Applications/$NAME.app" "$HOME/Applications/$NAME.app" \
       "$HOME/Library/Application Support/$FOLDER" "$HOME/Library/Logs/$FOLDER.log"

echo "✅ Removed. To drop its Accessibility entry too:"
echo "    tccutil reset Accessibility com.marcocesarato.ClaudeCodeAutoApprover"
