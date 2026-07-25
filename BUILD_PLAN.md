# EconoMia — Flutter Production Build: PLAN

## Context

EconoMia is a Brazilian (Paraná) grocery-savings app: scan the QR on an NFC-e cupom fiscal, see where each item is cheaper at nearby markets, track savings, build shopping lists, earn Mia Points. It exists today as a throwaway React/Vite PWA at `D:\Projects\EconoMia` with a validated end-to-end loop and three deployed Vercel serverless functions.

This plan rebuilds the **client** as a production Flutter app. The React code is reference only — nothing is ported. The `api/*` functions stay deployed and are consumed over HTTP by a new typed Dart client. Nothing about NFC-e parsing or price scraping is re-implemented in Dart.

**Confirmed scope:** Android + iOS only (Android 8 / iOS 13) · full feature parity, phased · pt-BR strings inline, no ARB · **light theme only** for this build · base URL `https://econo-mia.vercel.app`.

---

## 1. Architecture

Feature-first, three thin layers. Nine screens sharing three data sources and a set of pure projections over them — that shape drives everything below.

```
lib/
  main.dart                 ProviderScope + runApp
  app.dart                  MaterialApp.router, themes, router

  theme/
    tokens.dart             Sage & Amber values (ThemeExtension); dark set recorded, unwired
    theme.dart              tokens → ThemeData (light)
    fonts.dart              TextTheme (Fredoka / Baloo 2 / Nunito)

  core/
    api_client.dart         base URL, GET+decode, typed ApiException
    pooled.dart             bounded-concurrency map (Menor Preço rate-limits)
    money.dart              parseBRL · reaisToCents · formatBRL  (integer cents everywhere)
    text.dart               norm · distinctiveStoreTokens
    categoria.dart          classify() — NCM chapter, then keyword

  data/
    models/                 freezed + json_serializable
      receipt.dart  offer.dart  precos.dart  app_location.dart
      list_item.dart  quest_state.dart  nutrition.dart
    economia_api.dart       /api/nfce · /api/precos · /api/cep
    off_api.dart            Open Food Facts (client-direct, as in the MVP)
    receipt_repository.dart sembast: receipts + offers
    prefs.dart              shared_preferences scalars

  domain/                   pure functions, no classes, no I/O — directly unit-testable
    savings.dart            computeSavings · savedPct · storeOptions · basketForStore · compareHere
    insights.dart           aggregate()
    tendencias.dart         cheapDayByCategory · trendsByWeekday
    quests.dart             CATALOG + refresh/track/claim reducer
    mia.dart                notePoints (10 × unique products)
    lista_parse.dart        parseItem · parseInput

  features/<name>/          screen + private widgets + a Riverpod controller
    home  scan  receipt  produto  mercado  lista  history  resumo  tendencias

  widgets/                  shared UI: CatChip · OfferSpan · StorePicker
                            AppBanner · MiaHero · QuestToast · LocationBar
```

**Why this and not something heavier:**

- **`domain/` is free functions, not services.** Every one of these is already a pure transform in the MVP (`computeSavings(items)`, `aggregate(receipts)`). Wrapping them in classes to inject them buys nothing — there is no second implementation and no I/O to fake. They are tested by calling them.
- **No repository interfaces.** One data source per concern, one implementation each. An `abstract class ReceiptRepository` with a single `SembastReceiptRepository` is exactly the speculative layer to skip.
- **`core/` holds only what two or more features share.** `norm()` is used by savings matching, tendências chain grouping, and the store picker filter — that's why it's shared, not because "utils" is a folder people make.
- **`features/` owns its own widgets.** Only pieces used by 2+ screens graduate to `widgets/` (`OfferSpan` appears in four screens, `StorePicker` in two).

---

## 2. State management: **Riverpod**

The app's state is overwhelmingly *derived*. Receipts, location, and points/quests are the only three sources of truth; Resumo is `aggregate(receipts)`, Home's hero is that same aggregate, Tendências is `trendsByWeekday(offers)`, and every savings figure is `computeSavings(receipt.items)`. Riverpod expresses each of those as a one-line derived provider that recomputes and repaints automatically the moment a scan writes a receipt — including on screens the user isn't currently looking at. The Bloc equivalent is a Bloc per screen plus hand-wired stream subscriptions to keep them consistent, which is machinery to solve a problem Riverpod doesn't have. Two secondary fits seal it: the async pricing calls map exactly onto `AsyncValue`'s loading/data/error, which *is* the three-state banner UI already on every screen, and Riverpod is also the DI container, so no `get_it`.

Hand-written providers — `Notifier`, `AsyncNotifier`, `.family`, `.autoDispose`. **No `riverpod_generator`**: `build_runner` is already in the project for models, but provider codegen buys typed families we can write by hand in one line each, at the cost of a second generated file per feature.

---

## 3. Packages

| Package | Concrete reason |
|---|---|
| `flutter_riverpod` | State + DI, per §2 |
| `go_router` | `StatefulShellRoute.indexedStack` gives per-tab state preservation — Lista's in-progress edits and Resumo's scroll must survive a tab switch (the MVP kept all views mounted in one component). Also deep-links `/notas/:accessKey` from History |
| `http` | Three GET endpoints returning JSON. No interceptors, no retry policy, no multipart → `dio` is unearned |
| `freezed` + `freezed_annotation` | ~10 models with 6–12 fields. Deletes ~250 lines of hand-written `copyWith`/`==`/`hashCode`. `copyWith` is load-bearing: enrichment stamps `precos` onto items and `enrichedAt` onto receipts |
| `json_serializable` + `json_annotation` | Parsing the three API contracts. Hand-written `fromJson` for `Precos`/`Offer`/`Option` nesting is pure error surface |
| `build_runner` | Required by the two above |
| `sembast` | Receipts and offers are two keyed document collections read whole (`listReceipts()` sorts all; tendências medians scan all offers). No joins, no filters, no relations → a document store, not SQL. Pure Dart, single file, no codegen, no native build step. Drift/Isar would be SQL and schema ceremony for `put`/`getAll` |
| `shared_preferences` | The six scalar keys (location, list, points, quests, currentStore, listStore) |
| `mobile_scanner` | The only maintained MLKit/AVFoundation wrapper. Handles both scan modes with a `formats:` filter (QR for nota, EAN-8/13 for produto) and owns its camera permission |
| `geolocator` | GPS fix + location permission. Reverse geocoding goes to `/api/cep?lat&lng`, so no geocoding package |
| `intl` | `R$ 1.234,56` and `DD/MM/YYYY` — pt-BR number/date formatting |
| `url_launcher` | The "mapa" link on every offer opens Google Maps |

**Deliberately not added:** `dio`, `get_it`, `google_fonts` (fonts are bundled as assets — no runtime fetch, no first-paint flash), `permission_handler` (the two packages that need permissions own them), any charting library (Resumo is eight horizontal bars — a `Container` with a `widthFactor`), `flutter_localizations`/ARB, `connectivity_plus`, `flutter_hooks`.

---

## 4. Theming

**Ship Sage & Amber only.** The MVP runs two palettes simultaneously — "Chubby Cat" (thick 2.5–4px ink outlines, hard `0 3px 0` sticker shadows) on seven views, "Sage & Amber" (1.5px translucent strokes, soft lifts) on Home + nav. The docs name migrating the rest as the one open design debt; a rebuild makes that free.

`theme/tokens.dart` holds a `SaTokens extends ThemeExtension<SaTokens>` with the roles Material's `ColorScheme` has no slot for — `paper2`, `paper3`, `forest`, `forestDeep`, `mint`, `amberPress`, `stroke`, `stroke2`, `lift`, `liftSm`. Material roles (`primary` = amber, `surface` = paper, `onSurface` = ink) come from a `ColorScheme` built from the same constants, so a plain `Card` or `TextButton` is already on-brand.

**Light** — verbatim from [styles.css:65-73](D:/Projects/EconoMia/src/styles.css#L65-L73):
```
paper #F5EEDD · paper2 #EBE0C6 · paper3 #E1D5B8
forest #14312A · forestDeep #0F241C · ink #14312A · muted #8A8064
amber #E4872B · amberPress #C96E1E · green #1E7A52 · mint #54C98C
stroke rgba(20,49,42,.15) · stroke2 rgba(20,49,42,.28)
lift 0 8 22 rgba(20,49,42,.09) · liftSm 0 3 12 rgba(20,49,42,.06)
```

**Dark — not built in this pass.** `MaterialApp` ships `theme:` only; no `darkTheme`, no `themeMode`. The MVP has no dark mode either, so there is nothing to port and no screen to check it against.

What *is* done now is the cheap part that makes adding it later a wiring job rather than a refactor: every colour a widget uses comes from `Theme.of(context).extension<SaTokens>()` or the `ColorScheme` — **zero hardcoded `Color(0x…)` in `features/`**. A derived dark set is recorded in `tokens.dart` as a commented `SaTokens.dark` const so the values aren't re-invented later:

```
paper #0F241C · paper2 #16342B · paper3 #1E4438 · forest #0A1A14
ink #F5EEDD · muted #9AA79E · amber #E4872B · amberPress #EC9740 (lighter on press)
green → mint #54C98C (savings text; #1E7A52 dies on a dark surface)
stroke rgba(245,238,221,.14) · stroke2 rgba(245,238,221,.26) · lift 0 8 22 rgba(0,0,0,.40)
```
Contrast on `#0F241C`: amber ≈6.4:1, mint ≈9:1, muted ≈6.5:1 — all pass AA, so the palette is sound whenever you want it. Turning dark on = uncomment, add `darkTheme:`, walk the screens.

**Type** — Fredoka (headings/labels), Baloo 2 (numbers, always `FontFeature.tabularFigures()`), Nunito (body), bundled as `.ttf` assets. Radii are consts (`r12 r16 r18 r22 rPill`) — the MVP has no formal spacing scale and inventing one is fiction; ad-hoc `EdgeInsets` matching the MVP's 8/12/14/16/18 rhythm.

**Motion** — the three MVP curves as consts (`easeOut cubic-bezier(.16,1,.3,1)`, `easeBack (.34,1.56,.64,1)`, `easeSquish (.22,1,.36,1)`), plus the staggered list rise-in. Honors `MediaQuery.disableAnimations`.

---

## 5. Navigation

`StatefulShellRoute.indexedStack` with **four** branches under a persistent bottom bar; the fifth slot is the center FAB, which is an action, not a route.

| Slot | Route | Notes |
|---|---|---|
| Início | `/` | branch 0 |
| Lista | `/lista` | branch 1 |
| **Escanear** | — | 64px amber-gradient FAB, `-34px` overlap. Opens the `ScanChooser` bottom sheet |
| Ofertas | `/ofertas` | branch 2. **Enabled** — Tendências is complete but dead in the MVP (tab + tile both `disabled`) |
| Resumo | `/resumo` | branch 3 |

Pushed **above** the shell (bar hidden, back button — matching the MVP's `← voltar` links):
`/notas` (History) · `/notas/:accessKey` (Receipt) · `/mercado` · `/produto/:gtin` · `/scan?mode=nota|produto` (fullscreen).

`/notas` and `/mercado` are deliberately tab-less, reached from Home's Atalhos tiles — this is what keeps the bar at five, per `Docs/13_Home_Screen.md`.

**Scan flow:** FAB → `showModalBottomSheet` ("O que vamos escanear?" · 🧾 Nota fiscal / 🏷️ Produto) → `/scan?mode=…`. Routing after a decode stays **content-based**, not mode-based, exactly as the MVP does — a 44-digit key goes to Receipt and an 8–14 digit barcode goes to Produto regardless of which mode was chosen, so a mis-tap still lands correctly.

---

## 6. Backend contract (client-side only)

Three deployed functions, consumed as-is. **`api/*` is not touched.**

- `GET /api/cep?cep=NNNNNNNN` → `{cep, lat, lng, city, state}` · `GET /api/cep?lat&lng` → `{lat, lng, city, state, cep}`
- `GET /api/nfce?p=<full signed QR payload>` → `{accessKey, header{cnpj,storeName,city,address,purchasedAt,totalCents}, items[{description,gtin,qty,unit,unitPriceCents,lineTotalCents}]}`
- `GET /api/precos?{q|gtin}&local=lat,lng&raio&mode&store&city&unit` → three shapes (`{stores}` · gtin path · description path with `options`)

Errors are uniformly `{error: "<snake_case>"}` (+ optional `detail`/`status`) → one `ApiException(code)` mapped to the MVP's pt-BR strings ([App.jsx `mapError`](D:/Projects/EconoMia/src/App.jsx)).

**Contract details that must survive the port:**

1. **`p` must be the whole signed payload**, not the bare 44-digit key — a bare key passes client validation but SEFAZ returns a summary with no items.
2. **`cheapest` has no `cod`.** [api/precos.js:134](D:/Projects/EconoMia/api/precos.js#L134) omits it while `stores[]` includes it, so `Offer.cod` is nullable. Consequence: `compareHere`'s `here.cod === cheapest.cod` check is unreachable in the MVP — but it is *redundant*, not broken (if `here` is the cheapest store its price equals `cheapest.priceCents`, so the `savingsCents <= 0` branch already returns `here-cheapest`). Port without the dead comparison.
3. **`cod` is passed through untouched from upstream.** Normalize to `String` at the parse boundary — the MVP compares it as a string in pickers and by identity elsewhere.
4. **Rate limits are real.** Menor Preço 429s drove pooling: concurrency **6** for receipt enrichment, **3** for list pricing and store seeding. Keep both.
5. **`raio`** server-defaults to 25 but clients always send 50 (or 2 when the GPS fix is precise). Send it explicitly.
6. **Two money formats:** SEFAZ gives `"R$ 1.234,56"` (`parseBRL`), Menor Preço gives `"3.19"` (`reaisToCents`). Never cross them. Everything downstream is integer cents.
7. Send `User-Agent: Mozilla/5.0 (EconoMia)` where the MVP does.

**Base URL:** `https://econo-mia.vercel.app` (confirmed). There is no `vercel.json` and no hardcoded URL in the MVP — every call there is a same-origin relative path — so the constant lives in `core/api_client.dart`. Native HTTP has no CORS, so the functions carrying no CORS headers is a non-issue on Android/iOS.

---

## 7. Persistence

| Store | Backing | Contents |
|---|---|---|
| `receipts` | sembast, key = `accessKey` | Full enriched receipt + `createdAt`. Read whole, sorted `createdAt` desc |
| `offers` | sembast, key = `"$cod\|${gtin ?? category}\|$datahora\|$priceCents"` | Price observations mined during enrichment; the synthetic key dedups re-scans. Read whole by Tendências |
| scalars | `shared_preferences` | `economia.location` · `economia.shoppingList` · `economia.miaPoints` · `economia.quests` · `economia.currentStore` · `economia.listStore` |

**Offline-first, matching the MVP exactly:** saved receipts open and render from disk with no network (skip pricing when `enrichedAt` is set); a failed `/api/precos` yields `precos == null` → that item is "uncompared" and the rest of the report still renders; shopping-list prices are cached **12h** per item and re-priced on staleness, CEP change, or explicit refresh — **and a failed refresh must never wipe good cached prices** (keep the old `precos` *and* the old `pricedAt` so the item stays stale and retries). No offline write queue — scanning offline fails at `/api/nfce`, as it does today.

---

## 8. Build phases

Sixteen small phases. Each one ends in something you can run and judge on a device, and each is independently stoppable — nothing later is required to make an earlier phase coherent.

### Progress tracking

**`PROGRESS.md` at the repo root** is the single status surface — a tracked file, so it renders in VSCode's preview and every status change shows up in `git log`.

```markdown
# EconoMia — Build Progress

**5 / 16 phases**  ▓▓▓▓▓░░░░░░░░░░░  31%

| # | Phase | Status | Notes |
|---|-------|--------|-------|
| 0 | Skeleton | ✅ done | |
| 1 | Data spine | ✅ done | |
| 2 | Location | ✅ done | |
| 3 | Scan → parsed nota | ✅ done | validated on a real Muffato nota |
| 4 | Pricing + savings | ✅ done | |
| 5 | Receipt, second pass | 🟨 in progress | store picker done, basket mode WIP |
| 6 | Minhas Notas | ⬜ todo | |
…
_Updated 2026-07-25_
```

Statuses are `⬜ todo` · `🟨 in progress` · `✅ done` · `⏸️ blocked` (with the reason in Notes).

**The update rule, so it can't rot:** created in Phase 0 along with a short `CLAUDE.md` that states it, so it survives a new session or a context reset —

> Flip the phase to `🟨` **before** writing its first line of code, and to `✅` only once its stated deliverable actually runs and `flutter test` passes. Recompute the count and the bar. `PROGRESS.md` goes in the same commit as the phase's code — never a commit of its own.

### Foundation

**Phase 0 — Skeleton.** `flutter create` (android, ios), pubspec, bundled fonts, `tokens.dart` + `theme.dart`, go_router shell with 4 branches + FAB + ScanChooser sheet, placeholder screens, `Splash`, **`PROGRESS.md` + `CLAUDE.md`**.
→ *A navigable app that already looks like Sage & Amber, and a status file that tracks the other fifteen phases.*

**Phase 1 — Data spine.** Models (freezed), `EconomiaApi` against `https://econo-mia.vercel.app`, `pooled.dart`, `money.dart` / `text.dart` / `categoria.dart`, sembast repository, prefs. No UI.
→ *`flutter test` proves every model round-trips the recorded API shapes.*

### The core loop — the MVP thesis, split into five

**Phase 2 — Location.** `LocationBar` (unset form + set state), CEP lookup and GPS via `/api/cep`, raio picker `[1,5,10,15,25,50]`, `economia.location` persisted, the six geo/CEP pt-BR error strings.
→ *Set your location by CEP or GPS; it survives a restart.* Nothing else needs it yet, and everything after does.

**Phase 3 — Scan → parsed nota.** `mobile_scanner` in nota mode, the manual-paste fallback, `parseQrPayload`, `/api/nfce`, ReceiptView's **unpriced** variant (header + flat item list + total), saved to sembast.
→ *Scan a real Paraná nota; items and total match the paper receipt.* This is the riskiest integration in the app and it lands alone, unmixed with pricing.

**Phase 4 — Pricing + savings.** Pooled `/api/precos` enrichment (concurrency 6), offers mined into the `offers` store, `savings.dart`, ReceiptView's **cheapest-nearby** mode with per-line offers, "aprox." flags, and the total.
→ *The savings number, defensible: no UN-vs-KG false positives, no outliers.*

**Phase 5 — Receipt, second pass.** Store picker + **single-store basket** mode (green/red deltas, "não vendidos nesta loja"), categories transparency panel, dismissible day tip.

**Phase 6 — Minhas Notas.** History list with saved/priced state, tap to re-open, re-price when the CEP changed, clear-history confirm.
→ *The full loop closes: scan → savings → history → reopen.*

### Home — split in two

**Phase 7 — Home hero.** `insights.dart aggregate()`, greeting row, Mia savings hero in **both** states (real figure + annual projection / onboarding nudge). Framing rule enforced: opportunity, never "already saved".

**Phase 8 — Home shortcuts.** Atalhos 2×2 tile grid with live meta lines wired to real counts, Dica da Mia (trend state + learning-nudge fallback), disabled "Loja da Mia" row.

### Remaining features

**Phase 9 — Produto.** Barcode mode, `lookupProduct`, price range + offer count, nearby-stores list, `RawData` inspector.

**Phase 10 — Mercado.** `StorePicker` (bottom sheet: search + debounced remote `mode=stores`), "you are in" persistence, `compareHere`'s four statuses, trip summary, re-arming embedded scanner.

**Phase 11 — Nutrição.** `off_api.dart` + `NutritionPanel` — Nutri-Score and NOVA badges, ingredients, per-100g nutrient table, the "not in Open Food Facts" state. Slots into Produto (always visible) and Mercado (inside a collapsible). Its own phase because it is a wholly separate data source, independent of the pricing spine — if it's ever cut, nothing else moves.

**Phase 12 — Lista de Compras.** `lista_parse.dart` free-text parser, 12h price cache with the never-wipe-on-failure rule, product-option switching, store basket, market ranking.

**Phase 13 — Gamification.** `mia.dart` (10 pts × unique products, key `gtin ?? norm(description)`), `quests.dart` reducer (18-quest catalog, 3 tracks, slots 3/3/5, `progress = counts[event] − slot.base`, tap-to-claim, auto-award on window roll), points pill, QuestBoard on Home, QuestToast.
→ Placed here because its six events — `note`, `product`, `mercado`, `list_add`, `list_check`, `location` — are emitted from Phases 2, 3, 9, 10 and 12. Built earlier, most of the catalog would be untrackable.

**Phase 14 — Resumo.** Aggregate hero, the <3-notes gate with its CTA, category bar chart, pantry champions, store summary, best-alternative tip.

**Phase 15 — Tendências.** `tendencias.dart` gating (`minPerDay: 4, marginPct: 8`), today card, Seg→Dom week list with today highlighted, per-category lookup, thin-data empty state. Enables the Ofertas tab.

**Phase 16 — Polish.** Motion curves + staggered list entrances, reduced-motion, empty/error-state audit against the honesty rule (*no notes → onboarding copy, never a hollow "R$ 0,00"*), semantics labels on every emoji chip, app icon + native splash.

---

## 9. Verification

**Unit tests** (`flutter test`) — targeted at what `Docs/09` calls the #1 risk, "a wrong 'you overpaid R$17' destroys trust":
- `savings_test.dart` — guardrails: a per-**UN** vs per-**KG** case and an outlier case must both be rejected; `computeSavings` sums only positive per-unit deltas × qty; a matched-but-dearer item is neither compared nor uncompared; `basketForStore` totals go negative correctly.
- `money_test.dart` — both formats, and that they are never crossed: `parseBRL("R\$ 1.234,56") == 123456`, `reaisToCents("3.19") == 319`.
- `quests_test.dart` — port of `test/quests.test.js`: no retroactive credit (`base`), deterministic rotation, and a completed-but-unclaimed quest whose window rolls is still paid.
- `insights_test.dart` / `tendencias_test.dart` — annual projection only fires at `pricedNotesCount >= 2` with a real date span; a weekday qualifies only at ≥4 samples per side and ≥8% margin.
- `models_test.dart` — the three API contracts round-trip, including `cheapest` arriving without `cod`.

Fixtures: copy `D:\Projects\EconoMia\fixtures\sample-receipts.json` (a real enriched Muffato/Londrina receipt) into `test/fixtures/`.

**Manual end-to-end**, per `Docs/09`'s acceptance criteria — on a device, with a real Paraná NFC-e:
1. Set CEP → scan the nota QR → items and total match the paper receipt.
2. Cheapest-nearby coverage is near-total; no UN-vs-KG false positives; produce lines are flagged "aprox."; the savings figure is defensible.
3. Receipt persists to History and survives a cold restart.
4. Switch the store picker → basket totals recompute.
5. Scan a barcode in Mercado mode → the four `compareHere` statuses render.

Phases 2–6 are each verifiable on-device in isolation; the checks above accumulate as those phases land rather than waiting for the end.
