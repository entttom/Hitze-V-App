#!/bin/bash
# Test, lint, build the release bundle and upload it to the configured Google Play track.
set -euo pipefail
cd "$(dirname "$0")"

echo "-> Running unit tests and lint..."
./gradlew :app:testDebugUnitTest :app:testReleaseUnitTest :app:lintRelease

echo "-> Building and uploading release bundle..."
./gradlew :app:publishReleaseBundle

echo ""
echo "Done."
