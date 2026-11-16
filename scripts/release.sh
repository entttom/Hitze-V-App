#!/bin/bash
# HitzeV store release helper.
#
#   scripts/release.sh ios-upload       archive + export with Xcode, upload to TestFlight (group "Fam")
#   scripts/release.sh ios-submit       create 1.3.0 in App Store Connect, attach the build, submit for review,
#                                       release automatically after approval
#   scripts/release.sh android-upload   test, build and upload the bundle to the internal Play track
#   scripts/release.sh android-promote  promote the internal release to production (100 %)
#
# Credentials never live in the repo:
#   iOS signing    the Apple account signed in to Xcode (-allowProvisioningUpdates, cloud signing)
#   App Store      the default profile of the `asc` CLI (asc auth doctor)
#   Android        Android/keystore.properties + Android/play-publisher-credentials.json (gitignored)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="1.3.0"
PREVIOUS_VERSION="1.2.4"
IOS_BUILD_NUMBER="${IOS_BUILD_NUMBER:-3}"
NOTES_DIR="$ROOT/release/$VERSION"
OUT="$ROOT/build-release/$VERSION"
IOS_PROJECT="$ROOT/iOS/Hitze-V/Hitze-V.xcodeproj"
IOS_SCHEME="Hitze-V"
ASC_APP_ID="6760189444"
TESTFLIGHT_GROUP="461cfab9-dd66-4ab2-9756-1003007a9070"   # internal group "Fam"
TEAM_ID="RG7FE682S2"
STORE_NAME="HitzeV"
ASC_LOCALE="de-DE"                    # only App Store localization
PLAY_LOCALES="${PLAY_LOCALES:-de-DE}" # Play listing languages; only de-DE today

export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

notes_for() { # <store locale>
    case "$1" in
        de-*) cat "$NOTES_DIR/notes-de.txt" ;;
        *)    cat "$NOTES_DIR/notes-en.txt" ;;
    esac
}

json_get() { # <python expression on d> < json
    python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"
}

ios_upload() {
    mkdir -p "$OUT"
    cat > "$OUT/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>app-store-connect</string>
<key>destination</key><string>export</string>
<key>teamID</key><string>$TEAM_ID</string>
<key>signingStyle</key><string>automatic</string>
<key>manageAppVersionAndBuildNumber</key><false/>
<key>uploadSymbols</key><true/>
</dict></plist>
EOF
    echo "-> Archiving $VERSION ($IOS_BUILD_NUMBER)..."
    rm -rf "$OUT/HitzeV.xcarchive" "$OUT/export"
    xcodebuild -project "$IOS_PROJECT" -scheme "$IOS_SCHEME" -configuration Release \
        -destination 'generic/platform=iOS' -archivePath "$OUT/HitzeV.xcarchive" \
        MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$IOS_BUILD_NUMBER" \
        -allowProvisioningUpdates archive > "$OUT/archive.log" 2>&1 \
        || { grep -E 'error:' "$OUT/archive.log" | sort -u; exit 1; }

    echo "-> Exporting App Store IPA..."
    xcodebuild -exportArchive -archivePath "$OUT/HitzeV.xcarchive" \
        -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT/export" \
        -allowProvisioningUpdates > "$OUT/export.log" 2>&1 \
        || { grep -E 'error:' "$OUT/export.log" | sort -u; exit 1; }

    echo "-> Uploading to TestFlight..."
    asc publish testflight --app "$ASC_APP_ID" --ipa "$OUT/export/Hitze-V.ipa" \
        --group "$TESTFLIGHT_GROUP" --test-notes "$(notes_for de-DE)" --locale de-DE \
        --wait --timeout 60m --output json > "$OUT/ios-publish.json"
    echo "Uploaded iOS $VERSION ($IOS_BUILD_NUMBER) to TestFlight."
}

ios_build_id() {
    asc builds list --app "$ASC_APP_ID" --version "$VERSION" --build-number "$IOS_BUILD_NUMBER" --output json \
        | json_get 'd["data"][0]["id"]'
}

ios_submit() {
    local build_id version_id
    build_id="$(ios_build_id)"
    echo "-> Build $VERSION ($IOS_BUILD_NUMBER): $build_id"

    echo "-> Creating/staging App Store version $VERSION (metadata copied from $PREVIOUS_VERSION)..."
    asc release stage --app "$ASC_APP_ID" --version "$VERSION" --build-id "$build_id" \
        --copy-metadata-from "$PREVIOUS_VERSION" --exclude-fields whatsNew \
        --checkpoint-file "$OUT/asc-stage.checkpoint" --confirm --output json > "$OUT/asc-stage.json"

    version_id="$(asc versions list --app "$ASC_APP_ID" --version "$VERSION" --platform IOS --output json \
        | json_get 'd["data"][0]["id"]')"

    echo "-> What's new, store name, release after approval..."
    asc localizations update --version "$version_id" --locale "$ASC_LOCALE" \
        --whats-new "$(notes_for "$ASC_LOCALE")" --output json > /dev/null
    asc localizations update --app "$ASC_APP_ID" --type app-info --locale "$ASC_LOCALE" \
        --name "$STORE_NAME" --output json > /dev/null
    asc versions update --version-id "$version_id" --release-type AFTER_APPROVAL --output json > /dev/null

    echo "-> Readiness check..."
    asc validate --app "$ASC_APP_ID" --version "$VERSION" --output table

    echo "-> Submitting for review..."
    asc review submit --app "$ASC_APP_ID" --version "$VERSION" --build-id "$build_id" \
        --confirm --output json > "$OUT/asc-submit.json"
    asc status --app "$ASC_APP_ID" --output table
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

android_rename_listing() {
    # Store title "Hitze-V" -> "HitzeV". Downloads the live listing, changes only the title and
    # publishes the texts back (no graphics), then removes the downloaded files again.
    local play="$ROOT/Android/app/src/main/play"
    cd "$ROOT/Android"
    rm -rf "$play"
    ./gradlew -q :app:bootstrapListing --listings
    find "$play/listings" -mindepth 2 -maxdepth 2 -type d -name graphics -exec rm -rf {} +
    for title in "$play"/listings/*/title.txt; do
        sed -i '' 's/^Hitze-V$/'"$STORE_NAME"'/' "$title"
        echo "   $(basename "$(dirname "$title")"): $(cat "$title")"
    done
    ./gradlew -q :app:publishListing
    rm -rf "$play"
}

android_promote() {
    android_rename_listing
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
    *) sed -n '2,9p' "$0"; exit 64 ;;
esac
