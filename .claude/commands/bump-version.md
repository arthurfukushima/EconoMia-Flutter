Bump the app version in pubspec.yaml and prepare it for a new release.

The version format is `major.minor.patch+commitCount` (e.g. `1.0.17+86`).
- `major.minor.patch` is the user-facing version shown in the store listing
- `+commitCount` is the build number (versionCode on Android, CFBundleVersion on iOS) — derived from `git rev-list --count HEAD` so it always increases and is never reused

## Usage
Call with one argument: `patch` (default), `minor`, or `major`
- `patch` — bug fixes / new build: 1.0.17 → 1.0.18
- `minor` — new features: 1.0.17 → 1.1.0
- `major` — breaking changes: 1.0.17 → 2.0.0

The `+N` build number is always recalculated from commit count regardless of bump type.

## Steps

1. Get current version and commit count:
```bash
grep "^version:" pubspec.yaml
git rev-list --count HEAD
```

2. Compute the new version, then update pubspec.yaml in-place:
```bash
python3 - <<'EOF'
import re, sys, subprocess

bump = "$ARGUMENTS" if "$ARGUMENTS" else "patch"
if bump not in ("major", "minor", "patch"):
    print(f"Unknown bump type '{bump}'. Use: major, minor, patch"); sys.exit(1)

commit_count = int(subprocess.check_output(["git", "rev-list", "--count", "HEAD"]).strip())

with open("pubspec.yaml", "r") as f:
    content = f.read()

# Match version with or without existing +N suffix
m = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)(?:\+\d+)?\s*$', content, re.MULTILINE)
if not m:
    print("Could not parse version in pubspec.yaml"); sys.exit(1)

major, minor, patch = int(m.group(1)), int(m.group(2)), int(m.group(3))
old = m.group(0).strip()

if bump == "major":   major += 1; minor = 0; patch = 0
elif bump == "minor": minor += 1; patch = 0
else:                 patch += 1

new = f"version: {major}.{minor}.{patch}+{commit_count}"
content = re.sub(r'^version:\s*\S+\s*$', new, content, flags=re.MULTILINE)

with open("pubspec.yaml", "w") as f:
    f.write(content)

print(f"Bumped: {old}  →  {new}")
EOF
```

3. Confirm the updated version:
```bash
grep "^version:" pubspec.yaml
```

Report the old and new version clearly. Remind the user to run `/android-build-play-store` (or `/android-build-aab` / `/android-build-app-distribution`) next to build and upload the new version. No iOS release skill exists yet.
