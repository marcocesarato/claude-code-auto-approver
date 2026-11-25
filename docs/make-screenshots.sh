#!/bin/bash
# Takes the README's screenshots of the window, one per page, in light and dark, from the app's
# demo mode: made-up chats and approvals, and nothing started, pressed or written. It builds the
# app and leaves the installed one alone. Usage: docs/make-screenshots.sh
set -euo pipefail
cd "$(dirname "$0")/.."

(cd macos && scripts/build-app.sh >/dev/null)
BIN="macos/build/Claude Code - Auto Approver.app/Contents/MacOS/AutoApprover"

# The demo's window, found by its process: the one taller than a menu bar item.
window_of() {
    swift - "$1" <<'SWIFT'
import CoreGraphics
let pid = Int32(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
for w in list where w[kCGWindowOwnerPID as String] as? Int32 == pid && w[kCGWindowLayer as String] as? Int == 0 {
    if let b = w[kCGWindowBounds as String] as? [String: Any], (b["Height"] as? Double ?? 0) > 300 {
        print(w[kCGWindowNumber as String]!)
        break
    }
}
SWIFT
}

for theme in light dark; do
    for page in status paused activity chats; do
        "$BIN" --demo "$page" $([ "$theme" = dark ] && echo --dark) >/dev/null 2>&1 &
        pid=$!
        sleep 3
        id=$(window_of "$pid")
        screencapture -x -l "$id" "docs/window-$page-$theme.png"
        # Half a Retina window is sharp at the width the README shows it, at a third of the bytes.
        sips -Z 1280 "docs/window-$page-$theme.png" >/dev/null
        kill "$pid"
        wait "$pid" 2>/dev/null || true
        echo "docs/window-$page-$theme.png"
    done
done
