# EconoMia — Build Progress

**14 / 17 phases**  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░  82%

Status: ⬜ todo · 🟨 in progress · ✅ done · ⏸️ blocked

> Running a phase? The procedure is in [CLAUDE.md](CLAUDE.md#executing-a-phase).
> The **Model** column below is not decoration — it is step 1 of that procedure.

## Foundation

| # | Phase | Status | Model | Notes |
|---|-------|--------|-------|-------|
| 0 | Skeleton | ✅ done | — | Shell, theme, splash, screenshot harness |
| 1 | Data spine | ✅ done | **Opus** | Models round-trip responses recorded live off the deployed API |

## The core loop

| # | Phase | Status | Model | Notes |
|---|-------|--------|-------|-------|
| 2 | Location | ✅ done | Sonnet | `LocationBar` (unset form + set summary), CEP/GPS via `/api/cep`, raio picker, persists across restarts |
| 3 | Scan → parsed nota | ✅ done | Sonnet | `mobile_scanner` (QR for nota, EAN for produto) + manual-paste fallback; content-based routing so a mis-scanned barcode still lands on Produto |
| 4 | Pricing + savings | ✅ done | **Opus** | Pooled `/api/precos` (6), `computeSavings` + the paid-price outlier guard, cheapest-nearby report; R$ 24,92 on the sample nota |
| 5 | Receipt, second pass | ✅ done | Sonnet | Store picker (sheet) + single-store basket with green/red deltas and "não vendidos nesta loja"; collapsible categories panel; dismissible weekday day-tip (`tendencias.dart`) |
| 6 | Minhas Notas | ✅ done | Sonnet | List sorted newest first, each row's honest pricing state; tap reopens `ReceiptScreen`, which already re-prices on a CEP change — nothing new needed there; clear-history behind a confirm dialog |

## Home

| # | Phase | Status | Model | Notes |
|---|-------|--------|-------|-------|
| 7 | Home hero | ✅ done | Sonnet | `insights.dart aggregate()` (savings + annual projection, ≥2 priced notes needed); hero's real and onboarding states, framed as opportunity never "already saved" |
| 8 | Home shortcuts | ✅ done | Sonnet | Atalhos 2×2 grid (Ofertas/Notas wired to real counts; Lista wired in Phase 12, Mercado static until its phase lands) + disabled "Loja da Mia" row; Dica da Mia reads `tendencias.dart` for today's weekday, `−X%` badge, learning-nudge fallback |

## Remaining features

| # | Phase | Status | Model | Notes |
|---|-------|--------|-------|-------|
| 9 | Produto | ✅ done | Sonnet | `/produto/:gtin` off the GTIN path of `/api/precos`; price range + cheapest + nearby-store list, "escanear outro", collapsible `RawData` JSON inspector; `CatChip` generalised off `ReceiptItem` to description+ncm, `_Card` promoted to shared `CardList` (now used by Receipt and Produto) |
| 10 | Mercado | ✅ done | Sonnet | Store picker seeded from staple terms + live name-search, remembers the chosen market (`economia.currentStore`); embedded EAN scanner re-arms after each check; `compareHere`'s four statuses (no-offers/not-carried/here-cheapest/cheaper-elsewhere) and the trip summary. No shot in `test/screenshots.dart` — the embedded camera calls `MobileScannerController.start()` on every mount and throws under the test binding's unregistered platform channel, same limit as Phase 3's `ScanScreen`; verified via `mercado_test.dart` + `flutter analyze` instead |
| 11 | Nutrição | ✅ done | Sonnet | `off_api.dart` (client-direct, own tiny error contract, never throws) + shared `NutritionBody`/`NutritionPanel`; always-visible section on Produto (independent of the price lookup, per the reference), collapsible on Mercado's result cards; Nutri-Score/NOVA badges keep their official colours outside `SaColors` on purpose |
| 12 | Lista de Compras | ✅ done | **Opus** | `lista_parse.dart` (quantity prefixes; g/ml → `un`, never a per-KG search) + `domain/lista.dart` (`isStale`, `activeOption`, `marketRanking`, `basketAt`); 12h cache where a failed fetch is skipped entirely, so old prices **and** old `pricedAt` survive and the item stays due — `lista_test.dart` pins that from both the state and the disk. Product-option switching, store basket, coverage-first market ranking. `mergeStores` graduated to `domain/stores.dart` and Mercado's picker to `widgets/store_picker.dart` (now shared, per §1) |
| 13 | Gamification | ⬜ todo | **Opus** | Mia Points + Missões (needs events from 2, 3, 9, 10, 12) |
| 14 | Resumo | ✅ done | Sonnet | `aggregate()` extended (byCategory, topItems, byStore, bestAlt) and shared with Home's hero rather than duplicated; <3-notes gate; category spend bars, campeões da despensa, favourite market, best-alternative-store tip (reusing `basket.dart`'s `storeOptions`) |
| 15 | Tendências | ⬜ todo | Sonnet | Best weekday per category |
| 16 | Polish | ⬜ todo | Sonnet | Motion, empty-state audit, semantics, icon + splash |

---

## Why those models

**Opus on 1, 4, 12, 13** — all four are subtle rules where a plausible-looking
wrong answer ships silently and is expensive to find later:

- **1** — the API contract sets up everything downstream. `cheapest` arriving
  without `cod`, `cod`'s passthrough type, and the two money formats that must
  never cross are exactly the details a fast pass smooths over.
- **4** — the savings guardrails. `Docs/09_MVP_Implementation_Plan.md` calls this
  the project's #1 risk: *"A wrong 'you overpaid R$17' destroys trust."*
  UN-vs-KG rejection, outlier trimming, and "matched but dearer is neither
  compared nor uncompared" are three separate ways to be quietly wrong.
- **12** — the 12h cache invalidation, specifically that a failed refresh must
  preserve the old prices **and** the old timestamp.
- **13** — the quest reducer: no retroactive credit, deterministic rotation, and
  paying out a completed-but-unclaimed quest whose window already rolled.

**Sonnet on the rest** — assembly against a spec already pinned down by the plan
and the reference implementation. Sonnet is strong at that and materially
faster, which compounds over ten phases.

**Not Haiku for any build phase.** Fine for chores — regenerating screenshots,
updating this file, reading a doc — but every phase involves judgment calls
against pt-BR copy and a design system.

## Suggested session grouping

Not one session per phase (re-loading the same context 17 times), not one for
everything (by Phase 8 the early exploration crowds out the code being edited).
Group where the context genuinely carries over:

| Session | Phases | Why together |
|---------|--------|--------------|
| A | 1 | Data spine, self-contained, no UI |
| B | 2 · 3 · 4 · 5 | One pipeline: location → scan → price → report. Same models, same screen |
| C | 6 · 7 · 8 | History and Home both read `aggregate()` over the same receipts |
| D | 9 · 10 · 11 | All three are the barcode path and share `StorePicker` |
| E | 12 · 13 | Gamification needs Lista's events; building them adjacent is easier |
| F | 14 · 15 | Both are read-only projections over stored data |
| G | 16 | Polish, wants fresh eyes on finished screens |

Starting a session costs little here because `CLAUDE.md`, this file and
`BUILD_PLAN.md` carry the context. A good opening line:

> Build Phase N.

`CLAUDE.md` loads automatically and points at the rest, so that is genuinely
enough — no need to list what to read.

Note that a session spanning several phases will cross a model boundary
(session B runs Sonnet for 2–3, Opus for 4, Sonnet for 5). `/model` switches
mid-session — no new session needed.

---

---

## Backend-integration port (out of band, 2026-07-26)

Not a numbered phase — this pulled the React repo's `feature/backend-integration`
work across, plus the client features that shipped with it.

| Piece | Notes |
|---|---|
| `/api/precos` two-step protocol | GET → `{needsFetch}` → **device** fetches Menor Preço → POST back. The backend never fetches it: a serverless egress IP is fed fabricated decoy data (garbled names, non-PR states), which it rejects as `produtos_implausible`. `precos_protocol_test.dart` pins the whole dance |
| CORS + deploy | Added `Access-Control-Allow-Origin`/`OPTIONS` to all five functions in the backend repo; prod was also failing to build on a stale Vercel cache. Redeployed to `econo-mia-hugo.vercel.app` — the bare `econo-mia.vercel.app` is a **different, inaccessible account** |
| `AppConfig` | Hosts/timeouts/pacing from `assets/config/app_config.json` + a gitignored `.local.json` override, so each dev points at their own backend. No hardcoded URLs left under `lib/` |
| Buscar por nome | `/api/suggest` autocomplete, search history, option switcher; jumps to Produto on a definite GTIN match |
| Catálogo | `/api/catalog` — a market's whole cached assortment, its own market picker, category chips, sort, rank line, cheapness badge, add-to-list |
| Multi-list | Named lists with a one-way migration off the flat `economia.shoppingList` key; per-list items and store pick. `listas_test.dart` pins the migration, CRUD and the self-heals |
| Parser | Bullets/numbering/NBSP stripped off pasted lines; names capitalised |
| `StoreRow` | Two-line store card for "N mercados" lists — `OfferSpan` wrapped to three lines there |

**Still unported, deliberately:** Tendências (Phase 15) and Mia Points/Missões
(Phase 13) exist in the reference but are their own planned phases with their
own specs — not backend-integration work.

---

## Lista parser rebuild (out of band, 2026-07-26)

Post-Phase-12 hardening, not a reopening of it. The old parser read three
regexes off the front of a line and collapsed *package size* into *quantity* —
so `500g Mortadela` meant **500 units** (a live bug, asserted by a passing
test), `Refrigerante 2l` searched for a 350ml can, and a pasted `1,5kg Carne`
split into two items.

| Layer | Piece | Notes |
|---|---|---|
| L1 | `domain/lista_parse.dart` | Rewritten. Pulls out `qty · unit · **size** · name · note` and emits a **confidence**, not a verdict. Prefix/suffix/embedded measures, containers, dozens, fractions, spelled numbers, money values, brand-digit guard |
| L2 | `core/staples.dart` + `assets/data/staples.json` | ~200 pt-BR terms and what they are *sold as*. This is what decides `Arroz 5kg` (one bag) from `Tomate 2kg` (two kilos) — the same sentence, opposite meanings, undecidable from syntax |
| — | `core/measure.dart` | `500g` and `0,5kg` are one thing. Canonical `kg`/`L`/`un`, plus reading sizes and pack counts back out of a store's product name |
| L3 | `domain/lista_reconcile.dart` | Settles what the grammar couldn't, against real product names from `/api/precos`. `OVO BRANCO GRANDE 12UN` is what proves the 12 in `12 Ovos` was a carton. Every rule needs evidence, none fire twice, none overrule the user |
| L4 | `lista_screen.dart` | Size on the quantity row, a one-tap correction sheet on any low-confidence line, the note, and undo for a whole paste |

**The rule the whole thing is built on:** ambiguity degrades toward `qty 1`.
Never resolve an ambiguity in the direction that multiplies — a line that comes
back priceless is honest, a line that comes back 12× too dear is the failure
that ends trust.

`lista_parse_test.dart` is the spec: a ~60-line corpus, run against the real
shipped lexicon, including the whole 22-line sample list asserted as one table.

_Updated 2026-07-26 (Lista parser rebuild) · Spec: [BUILD_PLAN.md](BUILD_PLAN.md) · Procedure: [CLAUDE.md](CLAUDE.md#executing-a-phase)_

<!-- Still left for later from Phase 1, deliberately: the Missões model
     (phase 13 defines its own shape) and `intl` (no date is formatted yet).
     Lista's model and its pricing orchestration landed with phase 12. -->

