Bump the version, build a signed Android App Bundle, and upload it to Google Play Store.

## Usage
Accepts an optional track argument: `internal` (default), `alpha`, `beta`, or `production`
- `/android-build-play-store` → uploads to internal testing (team only, no review)
- `/android-build-play-store alpha` → closed testing
- `/android-build-play-store beta` → open testing
- `/android-build-play-store production` → public release (requires Google review)

## Prerequisites (first-time setup only)
- Fastlane installed: `gem install fastlane`
- Service account key at `android/play-service-account.json` (Play Console → Setup → API access → Service accounts → Release Manager role)
- At least one release manually published in Play Console before the API can upload
- **Real release signing config.** `android/app/build.gradle.kts` currently signs release
  builds with the debug key (`signingConfig = signingConfigs.getByName("debug")`) — a
  placeholder that lets `flutter run --release` work locally but cannot be uploaded to
  Play Console. Wire up a release keystore (`android/key.properties` + a
  `signingConfigs.release` block) before running this for real, or stop and tell the
  user rather than uploading a debug-signed AAB.

## Steps

1. Bump the patch version and increment the build number in pubspec.yaml:
```bash
python3 - <<'EOF'
import re, sys
with open("pubspec.yaml", "r") as f:
    content = f.read()
m = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)', content, re.MULTILINE)
if not m:
    print("Could not parse version"); sys.exit(1)
major, minor, patch, build = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
old = f"{major}.{minor}.{patch}+{build}"
patch += 1
build += 1
new = f"{major}.{minor}.{patch}+{build}"
content = content.replace(f"version: {old}", f"version: {new}", 1)
with open("pubspec.yaml", "w") as f:
    f.write(content)
print(f"Bumped: {old}  →  {new}")
EOF
```

2. Stamp build_info.dart with the new version and UTC timestamp:
```bash
BUILD_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //') && BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ") && printf "// AUTO-GENERATED — do not edit manually.\n// Updated by the build script before each release build.\n// ignore_for_file: constant_identifier_names\n\nconst String kBuildVersion = '$BUILD_VERSION';\nconst String kBuildTime = '$BUILD_TIME';\n" > lib/core/build_info.dart && echo "Stamped: v$BUILD_VERSION @ $BUILD_TIME"
```

3. Build the Android App Bundle (AAB) in release mode:
```bash
flutter build appbundle --release
```

4. Upload to Google Play. Use the track from $ARGUMENTS (default: internal):
```bash
TRACK="${ARGUMENTS:-internal}"
fastlane supply \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --track "$TRACK" \
  --package_name br.com.economia \
  --json_key android/play-service-account.json \
  --skip_upload_apk true \
  --skip_upload_metadata true \
  --skip_upload_images true \
  --skip_upload_screenshots true
```

Run all four steps sequentially and report the output including the new version number and the track it was uploaded to.

After a successful upload:
- **internal/alpha/beta**: the build is available in Play Console immediately — testers can download it from their Play Store.
- **production**: the release goes into review. Once approved it rolls out to all users.
To promote a release to a higher track later: Play Console → EconoMia → Testing / Production → select the release → Promote.
