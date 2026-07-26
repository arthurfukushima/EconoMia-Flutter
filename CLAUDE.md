# EconoMia — working notes

Brazilian (Paraná) grocery-savings app. Scan the QR on an NFC-e cupom fiscal,
see where each item is cheaper nearby, track savings, build lists, earn Mia
Points. UI language is **pt-BR**. Android + iOS (Android 8 / iOS 13).

`Docs/` is the product source of truth — vision, features, branding, gamification,
home screen spec. Read the relevant one before building a feature.

## Executing a phase

`PROGRESS.md` tracks the 17 build phases and `.claude/phases.json` holds the
model mapping. When asked to build, run, execute or continue a phase — by number
or by name — follow this order:

1. **Check the model.** Look up the phase in `.claude/phases.json` to get its
   recommended model. If the session is not on that model, output the exact
   command the user should run:
   ```
   /model opus
   ```
   (or `sonnet`, whatever is needed). Then output "Ready to build Phase N once you switch."
   
   **Enforce:** Do not silently build an Opus phase on Sonnet. But after the
   user runs `/model`, just build — no need to wait for them to ask again or
   repeat the request.
   If already on the recommended model, proceed immediately to step 2.
   
   If not: the user runs the command, and I build automatically on the next
   message (no need for them to repeat the request).

2. **Read the phase spec** in [`BUILD_PLAN.md`](BUILD_PLAN.md) §8, plus any
   `Docs/` file it names. The plan states each phase's deliverable — that is the
   definition of done, not "some code exists". §1–7 hold the architecture, the
   backend contract and the persistence model; re-read the relevant one rather
   than re-deriving it.
3. **Flip the phase to 🟨** in `PROGRESS.md` before writing its first line of
   code.
4. **Build it,** honouring the ground rules below.
5. **Verify:** `flutter analyze` and `flutter test` clean, plus the phase's own
   check. For anything with UI, add a shot to `test/screenshots.dart` and
   actually look at it — there is no device on this machine.
6. **Flip to ✅**, add a one-line note, recompute the header count, the progress
   bar and the date footer.
7. **Commit `PROGRESS.md` with that phase's code**, never as a commit of its
   own. Only commit if the user has asked for commits.

If a phase turns out to be blocked, mark it ⏸️ with the reason in Notes, finish
everything in the phase that is not blocked, and say plainly what was left out.

## Ground rules

- **No colour literals under `lib/features/`.** Everything comes from
  `Theme.of(context).sa` (`SaColors`) or the `ColorScheme`. This is what keeps a
  dark theme a wiring job instead of a refactor — the palette is already worked
  out in `SaColors.dark`, just unwired.
- **Money is always integer cents.** Two source formats that must never be
  crossed: SEFAZ gives `"R$ 1.234,56"` (`parseBRL`), Menor Preço gives `"3.19"`
  (`reaisToCents`).
- **`domain/` is pure functions** — no I/O, no classes, no injection. That is
  what makes the savings maths directly testable, and savings correctness is the
  project's #1 risk: a wrong "you overpaid R$17" destroys trust.
- **Add a dependency in the phase that needs it**, not up front.
- **Honesty rule** (from `Docs/13_Home_Screen.md`): every block has a real state
  *and* an empty state. No notes → onboarding copy, never a hollow "R$ 0,00". No
  gated trend → a learning nudge, never a fabricated promo. Savings are framed as
  opportunity ("dá pra economizar"), never as already banked.

## Backend

Three already-deployed Vercel functions at `https://econo-mia.vercel.app`:
`/api/cep`, `/api/nfce`, `/api/precos`. **This repo is a client — never
re-implement NFC-e parsing or price scraping in Dart.** Errors come back as
`{error: "<snake_case>"}`.

Menor Preço rate-limits: keep the request pools at concurrency 6 for receipt
enrichment and 3 for list pricing.

## Third-party services — keep the boundary

One service per job. Do not add a new integration that duplicates one already
in place.

- **Neon** — the only database. Postgres, billed directly (not the "Vercel
  Postgres" marketplace resale of the same Neon, which just adds a markup and
  a middleman layer for no benefit here).
- **Vercel** — the only API/compute layer (`/api/cep`, `/api/nfce`,
  `/api/precos`) and hosting.
- **Firebase** — mobile ops only: Crashlytics, App Distribution, Play Store
  publishing helpers. **Never** Firestore/Realtime DB, Firebase Auth, Cloud
  Functions, or Firebase Hosting — those would duplicate Neon/Vercel above.

If a task seems to need a new backend, auth, or storage service, that's a
signal to re-check whether Vercel/Neon already cover it before reaching for
something else.

## Commands

```
flutter analyze
flutter test
flutter test test/savings_test.dart                    # single file
flutter test --plain-name "computeSavings"              # single test by name
flutter test test/screenshots.dart --update-goldens     # renders to test/shots/
```

There is no emulator or device on this machine, so `test/screenshots.dart` is
how UI gets eyeballed. It is not named `*_test.dart` on purpose — `flutter test`
skips it, so it never becomes a brittle pixel assertion.

## Architecture map

```
lib/
  main.dart / app.dart / router.dart   ProviderScope, MaterialApp.router, theme,
                                        four-branch StatefulShellRoute.indexedStack
                                        (Home/Notas/Mercado hang off Home's tile,
                                        not their own tab — see router.dart comment)
  theme/          tokens.dart (SaColors ThemeExtension) → theme.dart (ThemeData);
                  fonts.dart (Fredoka/Baloo2/Nunito via FontVariation, not weight files)
  core/           api_client.dart, pooled.dart (bounded-concurrency pool),
                  money.dart (parseBRL/reaisToCents/formatBRL), text.dart, categoria.dart
  data/
    models/       freezed + json_serializable; receipt.dart is the core domain model
    economia_api.dart    the three backend endpoints (cep/nfce/precos)
    off_api.dart          Open Food Facts, called directly (own error contract)
    receipt_repository.dart   sembast persistence
    prefs.dart            shared_preferences scalars
  domain/         pure functions, no I/O (savings.dart, insights.dart, tendencias.dart,
                  quests.dart, mia.dart, lista_parse.dart) — this is where correctness lives
  features/       one folder per screen: <name>_screen.dart, <name>_controller.dart
  widgets/        shared UI (bottom_nav, scan_chooser, phase_placeholder, wordmark)

test/
  *_test.dart           run by `flutter test`
  screenshots.dart       NOT run by `flutter test`; invoke explicitly (see Commands)
  fixtures/              recorded API responses used by data/model tests
```

State flows one way: `features/` reads/writes via Riverpod providers → `data/`
(API + sembast) → `domain/` (pure transforms) back into UI state. Never call
`domain/` functions with I/O, and never put business logic in a `*_controller.dart`
that belongs in `domain/`.

## Reference implementation

`D:\Projects\EconoMia` is a React/Vite MVP of this app. It is **reference only**
— read it for behaviour, layout and copy; never port its code or structure.
