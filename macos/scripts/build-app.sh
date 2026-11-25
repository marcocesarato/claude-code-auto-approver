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
# SwiftPM records the deployment target as the SDK the binary was built with, and macOS 26
# draws an app in Liquid Glass only when that SDK is 26 or later: record the real one.
SDK="$(xcrun --sdk macosx --show-sdk-version)"
xcrun vtool -set-build-version macos 13.0 "$SDK" -replace \
    -output "$APP/Contents/MacOS/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE" 2>/dev/null
cp resources/Info.plist "$APP/Contents/Info.plist"
cp resources/woodpecker.gif resources/press.json resources/woodland.gif resources/shake.json resources/branch.png resources/twig.png "$APP/Contents/Resources/"
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION" -c "Set CFBundleVersion $VERSION" \
    "$APP/Contents/Info.plist"

# The icon is an Icon Composer document. actool compiles it into Assets.car, which macOS 26
# renders in Liquid Glass, and AppIcon.icns for earlier systems. It ships with Xcode 26 or
# later, not with the Command Line Tools.
DEV="$(xcode-select -p)"
[[ -x "$DEV/usr/bin/actool" ]] || DEV=/Applications/Xcode.app/Contents/Developer
if [[ -x "$DEV/usr/bin/actool" ]]; then
    WORK="$(mktemp -d)"
    trap 'rm -rf "$WORK"' EXIT
    DEVELOPER_DIR="$DEV" xcrun actool resources/AppIcon.icon --compile "$APP/Contents/Resources" \
        --platform macosx --minimum-deployment-target 13.0 --app-icon AppIcon \
        --output-partial-info-plist "$WORK/icon.plist" >/dev/null
else
    echo "⚠️  Xcode not found, building without the app icon"
fi

# Ad-hoc: privacy grants attach to the signature, so a rebuilt app needs Accessibility again.
codesign --force --deep --sign - "$APP"

echo "✅ $APP ($VERSION, $(lipo -archs "$APP/Contents/MacOS/$EXECUTABLE"))"
