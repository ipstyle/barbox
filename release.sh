#!/bin/bash
# Baut die App und legt den Build versioniert unter Releases/<version>/ ab.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh

VERSION=$(tr -d '[:space:]' < VERSION)
DEST="Releases/$VERSION"
mkdir -p "$DEST"
rm -rf "$DEST/AF-Toolbox.app" "$DEST/Toolbox.app"
ditto "build/Toolbox.app" "$DEST/Toolbox.app"

echo "✓ Release $VERSION: $DEST/Toolbox.app"
