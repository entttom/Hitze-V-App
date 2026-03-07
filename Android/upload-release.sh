#!/bin/bash
# Build the release bundle and upload to the configured Google Play track.
set -e
cd "$(dirname "$0")"

echo "-> Building and uploading release bundle..."
./gradlew publishReleaseBundle

echo ""
echo "Done."
