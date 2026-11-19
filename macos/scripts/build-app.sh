#!/bin/bash
# Builds build/Claude Code - Auto Approver.app: the release binary, Info.plist, icon and an
# ad-hoc signature. VERSION overrides the version in resources/Info.plist (CI sets it from the tag).
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="Claude Code - Auto Approver"
EXECUTABLE="AutoApprover"
APP="build/$NAME.app"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' resources/Info.plist)}"

# A universal binary needs Xcode's build system; with the Command Line Tools alone the
# build is for this Mac's architecture.
ARCHS=(--arch arm64 --arch x86_64)
# Its own scratch path: Xcode's build system in .build breaks `swift test`.
SCRATCH=(--scratch-path .build-app)
if ! swift build -c release "${SCRATCH[@]}" "${ARCHS[@]}" >/dev/null 2>&1; then
    echo "⚠️  Universal build unavailable, building for $(uname -m) only"
    ARCHS=()
    swift build -c release "${SCRATCH[@]}"
fi
BIN="$(swift build -c release "${SCRATCH[@]}" ${ARCHS[@]+"${ARCHS[@]}"} --show-bin-path)/$EXECUTABLE"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$EXECUTABLE"
cp resources/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION" -c "Set CFBundleVersion $VERSION" \
    "$APP/Contents/Info.plist"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
swiftc -O scripts/make-icon.swift -o "$WORK/make-icon" -framework Cocoa
mkdir "$WORK/AppIcon.iconset"
"$WORK/make-icon" "$WORK/AppIcon.iconset" >/dev/null
iconutil -c icns "$WORK/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc: privacy grants attach to the signature, so a rebuilt app needs Accessibility again.
codesign --force --deep --sign - "$APP"

echo "✅ $APP ($VERSION, $(lipo -archs "$APP/Contents/MacOS/$EXECUTABLE"))"
