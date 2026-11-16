#!/bin/bash
# HitzeV store release helper.
#
#   scripts/release.sh ios-upload       archive + upload to App Store Connect (TestFlight)
#   scripts/release.sh ios-submit       submit the uploaded build for review, auto-release after approval
#   scripts/release.sh android-upload   test, build and upload the bundle to the internal Play track
#   scripts/release.sh android-promote  promote the internal release to production (100 %)
#
# Secrets never live in the repo:
#   ~/.appstoreconnect/hitzev.env   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (App Store Connect API key)
#   Android/keystore.properties     upload keystore (gitignored)
#   Android/play-publisher-credentials.json   Play service account (gitignored)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="1.3.0"
NOTES_DIR="$ROOT/release/$VERSION"
OUT="$ROOT/build-release/$VERSION"
IOS_PROJECT="$ROOT/iOS/Hitze-V/Hitze-V.xcodeproj"
IOS_SCHEME="Hitze-V"
IOS_BUNDLE_ID="org.entner.HitzeV.Hitze-V"
TEAM_ID="RG7FE682S2"
ASC_LOCALES="${ASC_LOCALES:-de-DE}"   # store localizations that exist; only de-DE today
PLAY_LOCALES="${PLAY_LOCALES:-de-DE}" # Play listing languages; only de-DE today

export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

load_asc() {
    local env_file="$HOME/.appstoreconnect/hitzev.env"
    [[ -f "$env_file" ]] || { echo "Missing $env_file (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH)" >&2; exit 1; }
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
    : "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}" "${ASC_KEY_PATH:?}"
    AUTH=(-allowProvisioningUpdates
          -authenticationKeyPath "$ASC_KEY_PATH"
          -authenticationKeyID "$ASC_KEY_ID"
          -authenticationKeyIssuerID "$ASC_ISSUER_ID")
}

notes_for() { # <store locale>
    case "$1" in
        de-*) cat "$NOTES_DIR/notes-de.txt" ;;
        *)    cat "$NOTES_DIR/notes-en.txt" ;;
    esac
}

ios_upload() {
    load_asc
    local build_number
    build_number="$(date +%Y%m%d%H%M)"
    mkdir -p "$OUT"
    echo "$build_number" > "$OUT/ios-build-number"

    cat > "$OUT/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>upload</string>
    <key>teamID</key><string>$TEAM_ID</string>
    <key>signingStyle</key><string>automatic</string>
    <key>manageAppVersionAndBuildNumber</key><false/>
    <key>uploadSymbols</key><true/>
    <key>testFlightInternalTestingOnly</key><false/>
</dict>
</plist>
EOF

    echo "-> Archiving $VERSION ($build_number)..."
    xcodebuild -project "$IOS_PROJECT" -scheme "$IOS_SCHEME" -configuration Release \
        -destination 'generic/platform=iOS' -archivePath "$OUT/HitzeV.xcarchive" \
        MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$build_number" \
        "${AUTH[@]}" archive | tail -5

    echo "-> Uploading to App Store Connect..."
    xcodebuild -exportArchive -archivePath "$OUT/HitzeV.xcarchive" \
        -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT/export" \
        "${AUTH[@]}" | tail -5
    echo "Uploaded iOS $VERSION ($build_number). It shows up in TestFlight after processing."
}

ios_submit() {
    load_asc
    local build_number meta key_json
    build_number="$(cat "$OUT/ios-build-number")"
    meta="$OUT/asc-metadata"
    rm -rf "$meta"
    for locale in $ASC_LOCALES; do
        mkdir -p "$meta/$locale"
        notes_for "$locale" > "$meta/$locale/release_notes.txt"
    done
    key_json="$(mktemp)"
    chmod 600 "$key_json"
    trap 'rm -f "$key_json"' RETURN
    python3 - "$key_json" <<'PY'
import json, os, sys
json.dump({"key_id": os.environ["ASC_KEY_ID"], "issuer_id": os.environ["ASC_ISSUER_ID"],
           "key_filepath": os.environ["ASC_KEY_PATH"], "in_house": False}, open(sys.argv[1], "w"))
PY

    echo "-> Submitting iOS $VERSION ($build_number) for review (automatic release)..."
    fastlane deliver \
        --api_key_path "$key_json" \
        --app_identifier "$IOS_BUNDLE_ID" \
        --app_version "$VERSION" \
        --build_number "$build_number" \
        --metadata_path "$meta" \
        --skip_binary_upload true \
        --skip_screenshots true \
        --skip_app_version_update false \
        --submit_for_review true \
        --automatic_release true \
        --reject_if_possible false \
        --force true \
        --run_precheck_before_submit false \
        --submission_information '{"add_id_info_uses_idfa": false}'
}

write_play_notes() {
    local dir="$ROOT/Android/app/src/main/play/release-notes"
    rm -rf "$dir"
    for locale in $PLAY_LOCALES; do
        mkdir -p "$dir/$locale"
        notes_for "$locale" > "$dir/$locale/default.txt"
    done
}

android_upload() {
    write_play_notes
    cd "$ROOT/Android"
    echo "-> Running unit tests and lint..."
    ./gradlew :app:testDebugUnitTest :app:testReleaseUnitTest :app:lintRelease
    echo "-> Building and uploading to the internal track..."
    ./gradlew :app:publishReleaseBundle --track internal --release-status completed
}

android_promote() {
    write_play_notes
    cd "$ROOT/Android"
    echo "-> Promoting internal -> production (100 %)..."
    ./gradlew :app:promoteReleaseArtifact --from-track internal --promote-track production \
        --release-status completed
}

case "${1:-}" in
    ios-upload)      ios_upload ;;
    ios-submit)      ios_submit ;;
    android-upload)  android_upload ;;
    android-promote) android_promote ;;
    *) sed -n '2,8p' "$0"; exit 64 ;;
esac
