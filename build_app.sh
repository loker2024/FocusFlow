#!/usr/bin/env bash
set -euo pipefail

# Backward-compatible entry point. The canonical app/DMG packaging logic lives
# in Scripts/package_dmg.sh so Info.plist, icon, signing, and output paths stay
# consistent.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$ROOT_DIR/Scripts/package_dmg.sh"
