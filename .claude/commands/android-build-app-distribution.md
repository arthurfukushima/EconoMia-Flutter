Build and upload the Android APK to Firebase App Distribution.

## Prerequisites (first-time setup only)
Firebase is not yet wired into this app — per CLAUDE.md, Firebase's only sanctioned
role here is Crashlytics / App Distribution / Play publishing helpers, and none of
that is installed yet (no `firebase_core` or Firebase config in `pubspec.yaml`, no
`google-services.json`, no `firebase` CLI project set up). Before this skill can run:
1. `firebase login` and `firebase apps:create android br.com.economia` (or reuse an
   existing Firebase project registered to that package name) to get an app ID.
2. Add `google-services.json` to `android/app/`.
3. Confirm the app ID below matches what `firebase apps:list` reports — do not reuse
   an app ID from a different project.

If any of this isn't done, stop and tell the user rather than uploading against a
guessed app ID.

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

3. Build the Android APK in release mode:
```bash
flutter build apk --release
```

4. Upload to Firebase App Distribution:
```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_APP_ID> \
  --groups Devs
```
`<FIREBASE_APP_ID>` is the `1:...:android:...` ID from `firebase apps:list` for
**this** project's Firebase app (`br.com.economia`) — never reuse an ID from
another app. Fill it in once the prerequisite step above is done, then this
placeholder can be replaced with the literal value for future runs.

Run all four steps sequentially and report the output including the new build number.
