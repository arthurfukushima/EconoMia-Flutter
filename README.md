# EconoMia — Flutter App

A Brazilian grocery-savings app: scan the QR on an NFC-e cupom fiscal, see where each item is cheaper at nearby markets, track savings, build shopping lists, earn Mia Points.

- **Platforms:** Android 8+ / iOS 13+
- **Language:** pt-BR only
- **State management:** Riverpod
- **Navigation:** go_router (`StatefulShellRoute.indexedStack` for per-tab state)
- **Persistence:** sembast (IndexedDB equivalent) + shared_preferences
- **Backend:** deployed Vercel functions; the host is **configured, not hardcoded** — see [Configuration](#configuration)

## Configuration

Hosts, timeouts and request pacing come from JSON, so different people can point the same
checkout at different backends:

| File | Committed? | Role |
|---|---|---|
| `assets/config/app_config.json` | yes | defaults everyone gets (`econo-mia-hugo.vercel.app`) |
| `assets/config/app_config.local.json` | no (gitignored) | your machine's overrides |

To point your build at a different backend:

```bash
cp assets/config/app_config.local.example.json assets/config/app_config.local.json
# edit api.baseUrl, then rebuild — assets are bundled at build time
```

The local file is merged over the base one section at a time, so it only names what differs
— usually just `{"api": {"baseUrl": "…"}}`. Typed by [`lib/core/app_config.dart`](lib/core/app_config.dart)
and read through `appConfigProvider`; every field has a compile-time default, so a missing
file is fine. Also configurable: Menor Preço and Open Food Facts endpoints, the maps-link
template, request concurrency, and the store-discovery seed terms.

## Working structure

### Meta files (read these first when joining or starting a new session)

- **[CLAUDE.md](CLAUDE.md)** — working notes, ground rules, and the procedure for executing a phase
- **[PROGRESS.md](PROGRESS.md)** — the 17-phase build plan, status of each, and session groupings
- **[BUILD_PLAN.md](BUILD_PLAN.md)** — the approved architecture spec; read §1–7 for context and §8 for phase details

### Project structure

```
lib/
  main.dart                   ProviderScope + orientation lock
  app.dart                    MaterialApp.router, theme
  router.dart                 four-branch shell + full route tree

  theme/
    tokens.dart               Sage & Amber palette (ThemeExtension)
    theme.dart                tokens → ThemeData
    fonts.dart                Fredoka / Baloo 2 / Nunito via FontVariation

  core/
    app_config.dart           JSON-loaded hosts/timeouts/pacing (+ local override)
    api_client.dart           HTTP (GET/POST/external), error mapping
    pooled.dart               bounded-concurrency request pool
    money.dart                parseBRL / reaisToCents / formatBRL
    text.dart                 normalize / distinctiveStoreTokens
    categoria.dart            classify by NCM or keyword

  data/
    models/                   freezed + json_serializable
      receipt.dart            the core domain model
      offer.dart precos.dart  pricing response shapes
      [others]                app_location, list_item, quest_state, nutrition
    economia_api.dart         /api/cep · /api/nfce · /api/precos · /api/suggest
                              · /api/catalog, plus the device-side Menor Preço
                              fetch /api/precos asks for on a cache miss
    off_api.dart              Open Food Facts (direct client call)
    receipt_repository.dart   sembast receipts + offers
    prefs.dart                shared_preferences scalars

  domain/                     pure functions, no I/O
    savings.dart              computeSavings · savedPct · storeOptions
    insights.dart             aggregate receipts into dashboard figures
    tendencias.dart           cheapDayByCategory · trendsByWeekday
    quests.dart               quest reducer + catalog
    mia.dart                  notePoints formula
    lista_parse.dart          free-text list parser

  features/
    [screen_name]/            one folder per screen
      [screen_name]_screen.dart
      [screen_name]_controller.dart
      [local_widgets].dart

  widgets/                    shared UI pieces
    wordmark.dart             "EconoMia" logo
    bottom_nav.dart           five-slot tab bar + scan FAB
    scan_chooser.dart         modal asking nota vs produto
    [others]                  phase_placeholder (for unbuilt screens)

assets/
  fonts/                      Fredoka.ttf, Baloo2.ttf, Nunito.ttf (variable)
  img/                        mia_logo.png
  config/                     app_config.json + .local.example.json (see above)

test/
  shell_test.dart             shell navigation smoke tests (always run)
  screenshots.dart            renders screens to test/shots/ for eyeballing
                              (not run by `flutter test` — invoke explicitly)
```

### Reference implementation

`D:\Projects\EconoMia` — React/Vite MVP. Read it for **behaviour, layout, copy**; never port code. `Docs/` folder there is the product source of truth.

## Commands

```bash
flutter analyze                                        # static check
flutter test                                           # run shell_test.dart
flutter test test/screenshots.dart --update-goldens   # render UI to PNGs
```

There is no emulator or device on the build machine; use `test/screenshots.dart` to see UI. It is not named `*_test.dart` on purpose — `flutter test` skips it so it never becomes a brittle pixel assertion.

## Building a phase

Run `flutter analyze && flutter test` after each phase. Read **[CLAUDE.md § Executing a phase](CLAUDE.md#executing-a-phase)** for the full procedure — notably, check the recommended model first before starting.

Each phase is independently verifiable on-device (phases 2–6 especially); once an emulator or device is attached, capture a real receipt and test end-to-end.
