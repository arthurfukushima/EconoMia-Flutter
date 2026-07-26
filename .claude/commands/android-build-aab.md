Build a signed Android App Bundle and upload it to Google Play Store (internal track by default).

## Prerequisites (first-time setup only)
- Fastlane installed: `gem install fastlane`
- A Google Play service-account JSON key saved at `android/play-service-account.json`
  (Create one in Google Play Console → Setup → API access → Service accounts)
- The app must already have at least one manual release in Play Console before the API can upload
- **Real release signing config.** `android/app/build.gradle.kts` currently signs release
  builds with the debug key (`signingConfig = signingConfigs.getByName("debug")`) — a
  placeholder that lets `flutter run --release` work locally but cannot be uploaded to
  Play Console. Before running this skill for real, wire up a release keystore
  (`android/key.properties` + a `signingConfigs.release` block) and swap the release
  build type over to it. If that isn't done yet, stop and tell the user rather than
  uploading a debug-signed AAB.

## Steps

1. Bump the build number in pubspec.yaml (keeps the version name, increments only the build number):
```bash
python3 - <<'EOF'
import re, sys
with open("pubspec.yaml", "r") as f:
    content = f.read()
m = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)', content, re.MULTILINE)
if not m:
    print("Could not parse version"); sys.exit(1)
version_name, build = m.group(1), int(m.group(2))
old = f"{version_name}+{build}"
new = f"{version_name}+{build + 1}"
content = content.replace(f"version: {old}", f"version: {new}", 1)
with open("pubspec.yaml", "w") as f:
    f.write(content)
print(f"Bumped: {old}  →  {new}")
EOF
```

2. Stamp build_info.dart with the current version and UTC timestamp:
```bash
BUILD_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //') && BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ") && printf "// AUTO-GENERATED — do not edit manually.\n// Updated by the build script before each release build.\n// ignore_for_file: constant_identifier_names\n\nconst String kBuildVersion = '$BUILD_VERSION';\nconst String kBuildTime = '$BUILD_TIME';\n" > lib/core/build_info.dart && echo "Stamped: v$BUILD_VERSION @ $BUILD_TIME"
```

3. Build the Android App Bundle (AAB) in release mode:
```bash
flutter build appbundle --release
```

4. Upload the AAB to Google Play internal track via fastlane supply:
```bash
fastlane supply \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --track internal \
  --package_name br.com.economia \
  --json_key android/play-service-account.json \
  --skip_upload_apk true \
  --skip_upload_metadata true \
  --skip_upload_images true \
  --skip_upload_screenshots true
```

Run all four steps sequentially and report the output including the new build number.
After a successful upload, remind the user to promote the release to alpha/beta/production in the Google Play Console if needed.
