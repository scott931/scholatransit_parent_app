#!/bin/bash
# Run the Flutter app with the Mapbox token from local.properties.
# Add MAPBOX_ACCESS_TOKEN to android/local.properties, then run:
#   ./scripts/run_with_mapbox.sh --dart-define=API_BASE_URL=http://<host>:8001/
#
# Unlike the driver app, this app's Gradle does not read local.properties — the
# token reaches the SDK only through main.dart (_initializeMapbox ->
# MapboxOptions.setAccessToken), which needs the --dart-define this script builds.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_PROPS="$APP_DIR/android/local.properties"
DEFINES_FILE="$APP_DIR/dart_defines.json"

# Read MAPBOX_ACCESS_TOKEN from local.properties. Anchored so it cannot match
# MAPBOX_DOWNLOADS_TOKEN or a commented-out line.
MAPBOX_TOKEN=""
if [ -f "$LOCAL_PROPS" ]; then
  MAPBOX_TOKEN=$(grep "^MAPBOX_ACCESS_TOKEN=" "$LOCAL_PROPS" 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' \r')
fi

if [ -z "$MAPBOX_TOKEN" ]; then
  echo "⚠️  MAPBOX_ACCESS_TOKEN not found in $LOCAL_PROPS"
  echo "   Add: MAPBOX_ACCESS_TOKEN=pk.your_token_here"
  exit 1
fi

# main.dart rejects anything that is not a public token, then silently runs on
# with a blank map — fail loudly here instead.
case "$MAPBOX_TOKEN" in
  pk.*) ;;
  *)
    echo "⚠️  MAPBOX_ACCESS_TOKEN must be a public token (pk.*)."
    echo "   main.dart rejects other tokens and the map renders blank."
    exit 1
    ;;
esac

echo "{\"MAPBOX_ACCESS_TOKEN\": \"$MAPBOX_TOKEN\"}" > "$DEFINES_FILE"

GITIGNORE="$APP_DIR/.gitignore"
if [ -f "$GITIGNORE" ] && ! grep -q "dart_defines.json" "$GITIGNORE"; then
  echo "dart_defines.json" >> "$GITIGNORE"
fi

cd "$APP_DIR"
exec flutter run --dart-define-from-file="$DEFINES_FILE" "$@"
