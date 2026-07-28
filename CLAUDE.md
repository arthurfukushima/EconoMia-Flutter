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
- **A package size is not a quantity.** On the shopping list, `qty`/`unit` is
  *how much to buy* and is the only number that multiplies a price; `size` is
  *how big one package is* and only steers which candidate product the line is
  priced as. Collapsing them is what made `500g Mortadela` mean 500 units.
  Sizes are canonical `kg`/`L`/`un` via `core/measure.dart` — never compared as
  strings, since the same bottle is tagged `2L`, `2000ML` and `2.0 L`.
- **Ambiguity degrades toward `qty 1`.** Never resolve an unclear line in the
  direction that multiplies. `lista_parse.dart` reports a confidence instead of
  guessing, `lista_reconcile.dart` only acts on evidence in a real price
  response, and the row offers the alternative readings. Priceless is honest;
  12× too dear is not.
- **`domain/` is pure functions** — no I/O, no classes, no injection. That is
  what makes the savings maths directly testable, and savings correctness is the
  project's #1 risk: a wrong "you overpaid R$17" destroys trust.
- **Add a dependency in the phase that needs it**, not up front.
- **Honesty rule** (from `Docs/13_Home_Screen.md`): every block has a real state
  *and* an empty state. No notes → onboarding copy, never a hollow "R$ 0,00". No
  gated trend → a learning nudge, never a fabricated promo. Savings are framed as
  opportunity ("dá pra economizar"), never as already banked.

## Configuration

**No hosts, endpoints or request-pacing numbers hardcoded in feature code.**
They live in `assets/config/app_config.json`, are typed by
[`lib/core/app_config.dart`](lib/core/app_config.dart), and reach the app
through `appConfigProvider`.

- `assets/config/app_config.json` — committed defaults, what a fresh clone runs on.
- `assets/config/app_config.local.json` — **gitignored** per-machine override,
  merged over the base one section at a time (name only what differs). Copy
  `app_config.local.example.json` to start.
- Every field also has a compile-time default in `AppConfig.fallback`, so tests
  and a config-less build still work. `appConfigProvider` defaults to it rather
  than throwing.

Adding a knob: add the field + its default to the right section class, name it
in `app_config.json`, read it via `ref.watch(appConfigProvider)`. A malformed
JSON file throws at launch on purpose — a typo must not look like a server
outage an hour later.

`assets/data/staples.json` follows the same shape (typed by
[`lib/core/staples.dart`](lib/core/staples.dart), reached via `staplesProvider`,
compile-time `Staples.fallback`), but it is **data, not configuration**: what a
pt-BR grocery term is sold as. Correcting a wrong sale unit there is a one-line
edit, not a code change — which is the point.

## Backend

**The backend lives in this repo, under `backend/`** — in JS, deployed to Vercel.
`backend/api/*.js` are the five handlers (`/api/cep`, `/api/nfce`, `/api/precos`,
`/api/suggest`, `/api/catalog`), `backend/api/lib/*.js` is their server-only half
(Neon connection, caches, persistence), `backend/src/lib/*.js` is logic shared
between handlers, `backend/db/` holds the schema and seed. Nothing outside
`backend/` is JS, and nothing inside it is Dart. Base URL is still `api.baseUrl`
in config, **not** a constant (each dev deploys their own project;
`econo-mia-hugo.vercel.app` and `econo-mia.vercel.app` are different accounts).
Errors come back as `{error: "<snake_case>"}`.

The Vercel project's **Root Directory is `backend`** — that is what makes
`backend/api/precos.js` serve `/api/precos` and keeps the Flutter half out of the
build entirely. Leave "Include files outside root directory" off. `npm` lives
there too: run every `npm run …` from `backend/`, and `backend/.env.local`
(gitignored) is where `DATABASE_URL` goes locally.

Two halves, one repo, and the line between them matters: **NFC-e parsing, price
scraping and offer matching stay in JS under `backend/`** — never re-implemented
in Dart. `lib/` consumes the endpoints and owns nothing of their logic. A few
pure functions are deliberately mirrored on both sides (`norm()` in
`backend/src/lib/text.js` and `lib/core/text.dart`, the category keywords, the
money parsers); when one changes, the other has to, or client and server stop
agreeing on what two strings being "the same" means.

`/api/precos` is **two-step**: a GET serves a cached result or answers
`{needsFetch: true}`; on a miss the *device* fetches Menor Preço directly
(`menorPreco.baseUrl`) and POSTs the raw `produtos` back for matching. The
backend never fetches it — a serverless egress IP gets fed fabricated decoy
data (garbled names, non-PR states), which it rejects as
`produtos_implausible`. `EconomiaApi._priceQuery` owns the whole dance.

Menor Preço rate-limits: the request pools are `pricing.receiptConcurrency` (6)
and `pricing.listConcurrency` (3) in config — tune there, not in the code.

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

cd backend && npm run test:api                          # backend (vitest)
cd backend && npm run db:migrate                        # apply db/schema.sql
cd backend && npm run db:seed                           # canonical products + aliases
cd backend && npm run db:review -- --json               # canonical coverage report
```

The two test runners never meet: `flutter test` collects `*_test.dart` under
`test/` and never descends into `backend/`; vitest is pointed at
`backend/test/**/*.test.js` and never leaves it. Both must be clean.

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
                  money.dart (parseBRL/reaisToCents/formatBRL), text.dart, categoria.dart,
                  measure.dart (canonical kg/L/un sizes + pack counts),
                  staples.dart (pt-BR lexicon ← assets/data/staples.json)
  data/
    models/       freezed + json_serializable; receipt.dart is the core domain model
    economia_api.dart    the three backend endpoints (cep/nfce/precos)
    off_api.dart          Open Food Facts, called directly (own error contract)
    receipt_repository.dart   sembast persistence
    prefs.dart            shared_preferences scalars
  domain/         pure functions, no I/O (savings.dart, insights.dart, tendencias.dart,
                  quests.dart, mia.dart, lista_parse.dart, lista_reconcile.dart)
                  — this is where correctness lives
  features/       one folder per screen: <name>_screen.dart, <name>_controller.dart
  widgets/        shared UI (bottom_nav, scan_chooser, phase_placeholder, wordmark)

backend/          the whole server side; Vercel's Root Directory points here
  api/            serverless functions, one file per endpoint —
                  cep.js nfce.js precos.js suggest.js catalog.js
    lib/          server-only: db.js (Neon), canonical.js (alias lookup),
                  rawprices.js (append every offer), pricecache.js (1/day per query),
                  catalog.js (the DISTINCT ON regroup), cors.js
  src/lib/        shared between handlers — text.js (norm), categoria.js (classify),
                  match.js (productSignature, guards, scoring), money.js, catalogScore.js
  db/             schema.sql, migrate.mjs, seed.mjs (canonical products + aliases)
  tool/db/        canonical-gaps.mjs — read-only coverage report (`/db-review`);
                  queries.md — probe library
  test/           *.test.js, run by vitest; `flutter test` never descends here
  public/         stub index + reports/ — static write-ups (DB coverage, design
                  notes) served at /reports/*.html, no auth, no build step

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

`~/Projects/HMLabs/EconoMia` (a clone of `github.com/arthurfukushima/EconoMia`,
`D:\Projects\EconoMia` on Windows) is the React/Vite MVP this app grew out of. It
is **reference only** — read it for behaviour, layout and copy; never port its
code or structure. The `api/`, `src/lib/` and `db/` it also contains are the
*former* home of this repo's backend; they were migrated here on 2026-07-27 and
that copy is now stale. Note it is still linked to the same Vercel project
(`econo-mia-hugo`), so whichever of the two deploys last wins — the deploy must
be repointed at this repo.
