#!/bin/bash
# Baut AF-Toolbox.app aus dem Swift Package (ohne Xcode-Projekt).
# Bundle wird ausserhalb von iCloud zusammengesetzt und signiert —
# iCloud stempelt sonst während des Signierens Metadaten hinein (detritus-Fehler).
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Toolbox.app"

if [ ! -f Resources/AppIcon.icns ]; then
    echo "→ Erzeuge App-Icon…"
    swift scripts/make_icon.swift Resources
fi

echo "→ swift build -c release…"
swift build -c release

echo "→ Bundle zusammensetzen (in /tmp, ausserhalb iCloud)…"
STAGE=$(mktemp -d /tmp/aftoolbox-build.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
APP_STAGE="$STAGE/Toolbox.app"
mkdir -p "$APP_STAGE/Contents/MacOS" "$APP_STAGE/Contents/Resources"
cp .build/release/AFToolbox "$APP_STAGE/Contents/MacOS/AFToolbox"
cp Resources/Info.plist "$APP_STAGE/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_STAGE/Contents/Resources/AppIcon.icns"

VERSION=$(tr -d '[:space:]' < VERSION)
BUILDNUM=$(date +%Y%m%d%H%M)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_STAGE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILDNUM" "$APP_STAGE/Contents/Info.plist"
echo "→ Version $VERSION (Build $BUILDNUM)"

xattr -cr "$APP_STAGE"

# Stabile Identität verwenden, falls vorhanden (verhindert TCC-Verlust bei Updates);
# sonst Ad-hoc. Eigene Identität anlegbar via Schlüsselbundverwaltung →
# Zertifikatsassistent → «Zertifikat erstellen…», Typ «Codesignierung», Name «AF-Toolbox Dev».
IDENTITY="${CODESIGN_IDENTITY:-}"
if [ -z "$IDENTITY" ] && security find-identity -v -p codesigning 2>/dev/null | grep -q "AF-Toolbox Dev"; then
    IDENTITY="AF-Toolbox Dev"
fi
if [ -n "$IDENTITY" ]; then
    echo "→ Signatur mit «$IDENTITY»…"
    codesign --force --sign "$IDENTITY" "$APP_STAGE"
else
    echo "→ Ad-hoc-Signatur…"
    codesign --force --sign - "$APP_STAGE"
fi

rm -rf "$APP"
mkdir -p build
ditto "$APP_STAGE" "$APP"

echo "✓ Fertig: $APP"
