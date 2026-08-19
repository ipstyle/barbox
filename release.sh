#!/bin/bash
# Baut die App und legt den Build versioniert unter Releases/<version>/ ab.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh

VERSION=$(tr -d '[:space:]' < VERSION)
# Ablageort überschreibbar, damit das Archiv auch ausserhalb des Repos liegen
# kann (hier: ../01_Admin/Release-Archiv). Ohne RELEASE_DIR bleibt alles wie bisher.
DEST="${RELEASE_DIR:-Releases}/$VERSION"
mkdir -p "$DEST"
rm -rf "$DEST/AF-Toolbox.app" "$DEST/Toolbox.app" "$DEST/BarBox.app"
ditto "build/BarBox.app" "$DEST/BarBox.app"

echo "✓ Release $VERSION: $DEST/BarBox.app"
