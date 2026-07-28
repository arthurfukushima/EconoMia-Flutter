---
description: Onboard a new dev — install deps, verify the stack runs
---

Onboard new machine for EconoMia. Do steps in order. Report status each step (OK / SKIP / NEEDS-HUMAN). Don't invent secrets — anything needing a credential, stop and ask user.

This is a **Flutter client only**. Per CLAUDE.md: NFC-e parsing and price
scraping already run behind deployed Vercel functions. The backend host is
**configuration, not a constant** — `api.baseUrl` in
`assets/config/app_config.json`, typed by `lib/core/app_config.dart`. There is
no local backend, database, or `.env` to wire up to run this app — skip any
step that would suggest otherwise.

## 1. Flutter SDK
Check `flutter --version`. Confirm it supports Android 8+ / iOS 13+ targets (see `.metadata` / `pubspec.yaml` for the pinned SDK constraint). Run `flutter doctor` and report any red flags (missing Android toolchain, missing Xcode, etc.) — don't try to fix toolchain installs yourself, just report.

## 2. Install deps
```
flutter pub get
```
Confirm it completes with no errors.

## 3. Verify: static analysis
```
flutter analyze
```
Should be clean.

## 4. Verify: tests
```
flutter test
```
Should all pass. No DB, no network, no credentials needed — `domain/` is pure functions and `data/` tests run against fixtures in `test/fixtures/`.

## 5. Verify: screenshots (UI eyeballing)
There is no device/emulator on this machine, so this is how UI gets checked:
```
flutter test test/screenshots.dart --update-goldens
```
Renders to `test/shots/` — look at a few to confirm nothing is visibly broken. Not run by `flutter test` (deliberately not named `*_test.dart`).

## 6. Verify: app boots
```
flutter run
```
Confirm it builds and reaches Home without crashing (either on a connected device/simulator, or `flutter build apk --debug` / `flutter build ios --debug --no-codesign` if none is attached). Don't leave it running in foreground unless the user asks to keep it up.

## 7. Stray untracked files — flag, don't touch
`.env.local`, `.neon`, and `.vercel/` currently sit untracked at repo root. Nothing in `lib/` reads them (confirmed: no `dotenv`/`DATABASE_URL`/`NEON` references in Dart code) — they look like leftovers from `vercel link` / `neon link` run against the separate backend project, not something this client needs. Flag their presence to the user; don't delete or fill them in as part of setup.

## 8. Release tooling (optional, only if user is about to ship a build)
Not needed for day-to-day dev. If the user is about to cut a release, point them at `/bump-version` first, then whichever of `/android-build-aab`, `/android-build-play-store`, or `/android-build-app-distribution` fits — each states its own prerequisites (signing config, Firebase project) and currently flags that release signing and Firebase are not yet wired up for this app.

## Summary
End with a short checklist: what's done, what needs the user (toolchain gaps from `flutter doctor`, anything device-related), and the stray-files flag from step 7.
