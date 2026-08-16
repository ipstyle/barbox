#!/bin/bash
# Baut BarBox.app aus dem Swift Package (ohne Xcode-Projekt).
# Bundle wird ausserhalb von iCloud zusammengesetzt und signiert —
# iCloud stempelt sonst während des Signierens Metadaten hinein (detritus-Fehler).
#
#   ./build.sh          Vollversion  → build/BarBox.app
#   ./build.sh --mas    Store-Variante (App-Sandbox, ohne Systemwerkzeuge)
#                       → build/BarBox-MAS.app
set -euo pipefail
cd "$(dirname "$0")"

MAS=0
if [ "${1:-}" = "--mas" ]; then MAS=1; fi

# Wächter: doppelte Schlüssel im Localization-Dictionary stürzen zur Laufzeit ab
# (Lektion aus 1.7/1.8) — der Compiler warnt nur, wir brechen ab.
DUPES=$(awk -F'": ' '/^ *"/ {print $1}' Sources/AFToolbox/Core/Localization.swift | sort | uniq -d)
if [ -n "$DUPES" ]; then
    echo "✗ Doppelte Schlüssel in Localization.swift:" >&2
    echo "$DUPES" >&2
    exit 1
fi

if [ ! -f Resources/AppIcon.icns ]; then
    echo "→ Erzeuge App-Icon…"
    swift scripts/make_icon.swift Resources
fi

if [ "$MAS" = 1 ]; then
    APP="build/BarBox-MAS.app"
    echo "→ swift build -c release (Store-Variante, MAS_BUILD)…"
    swift build -c release -Xswiftc -DMAS_BUILD --scratch-path .build-mas
    BINARY=.build-mas/release/AFToolbox
else
    APP="build/BarBox.app"
    echo "→ swift build -c release…"
    swift build -c release
    BINARY=.build/release/AFToolbox
fi

echo "→ Bundle zusammensetzen (in /tmp, ausserhalb iCloud)…"
STAGE=$(mktemp -d /tmp/barbox-build.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT
APP_STAGE="$STAGE/BarBox.app"
mkdir -p "$APP_STAGE/Contents/MacOS" "$APP_STAGE/Contents/Resources"
cp "$BINARY" "$APP_STAGE/Contents/MacOS/AFToolbox"
cp Resources/Info.plist "$APP_STAGE/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_STAGE/Contents/Resources/AppIcon.icns"
cp Resources/PrivacyInfo.xcprivacy "$APP_STAGE/Contents/Resources/PrivacyInfo.xcprivacy"

VERSION=$(tr -d '[:space:]' < VERSION)
BUILDNUM=$(date +%Y%m%d%H%M)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_STAGE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILDNUM" "$APP_STAGE/Contents/Info.plist"
echo "→ Version $VERSION (Build $BUILDNUM)"

xattr -cr "$APP_STAGE"

if [ "$MAS" = 1 ]; then
    # Store-Provisioning-Profil einbetten, falls vorhanden (aus dem Developer-Portal)
    if [ -f AppStore/MacAppStore.provisionprofile ]; then
        cp AppStore/MacAppStore.provisionprofile "$APP_STAGE/Contents/embedded.provisionprofile"
        echo "→ Provisioning-Profil eingebettet"
    fi
    # Sandbox-Signatur: Distribution-Zertifikat falls gesetzt, sonst Ad-hoc (lokaler Test)
    IDENTITY="${CODESIGN_IDENTITY:--}"
    echo "→ Sandbox-Signatur mit «$IDENTITY»…"
    codesign --force --sign "$IDENTITY" \
        --entitlements Resources/Toolbox-MAS.entitlements "$APP_STAGE"
else
    # Stabile Identität verwenden, falls vorhanden (verhindert TCC-Verlust bei Updates);
    # sonst Ad-hoc. Eigene Identität anlegbar via Schlüsselbundverwaltung →
    # Zertifikatsassistent → «Zertifikat erstellen…», Typ «Codesignierung», Name «BarBox Dev».
    IDENTITY="${CODESIGN_IDENTITY:-}"
    if [ -z "$IDENTITY" ] && security find-identity -v -p codesigning 2>/dev/null | grep -q "BarBox Dev"; then
        IDENTITY="BarBox Dev"
    elif [ -z "$IDENTITY" ] && security find-identity -v -p codesigning 2>/dev/null | grep -q "AF-Toolbox Dev"; then
        IDENTITY="AF-Toolbox Dev"   # Übergangsweise: alte Dev-Identität weiterverwenden
    fi
    if [ -n "$IDENTITY" ]; then
        echo "→ Signatur mit «$IDENTITY»…"
        codesign --force --sign "$IDENTITY" "$APP_STAGE"
    else
        echo "→ Ad-hoc-Signatur…"
        codesign --force --sign - "$APP_STAGE"
    fi
fi

rm -rf "$APP"
mkdir -p build
ditto "$APP_STAGE" "$APP"

echo "✓ Fertig: $APP"
