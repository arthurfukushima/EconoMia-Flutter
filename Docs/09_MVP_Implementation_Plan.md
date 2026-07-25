# MVP Implementation Plan

## Context
The MVP is a Paraná-only, QR-only, single-device shopping-savings PWA whose goal is **engagement** — get shoppers to scan receipts and act on savings. The one loop: *scan an NFC-e receipt → see what you bought and paid → see the cheapest nearby store for each item → total savings → local history.*

**Decision (validated on a real 23-item receipt):** the savings comparison is **local — "cheapest nearby store" via Menor Preço do Nota Paraná — not online retailers.** Measured coverage: **local 100% of the basket vs online 39%**, from data we already fetch. Online comparison is deferred (see Deferred).

Two facts that shape the build:
1. The receipt (SEFAZ-PR consulta via the signed QR) gives description + internal code (`cProd`) + **the price paid** — but **no GTIN** (the XML with `cEAN` is certificate-gated).
2. Menor Preço's public API is built from those NFC-e XMLs, so it has both the **GTIN** (recover it by same-store description match) and **live prices across 60k+ PR stores** (find the cheapest nearby).

**Stack:** Vite + React PWA, Vercel serverless proxies, no auth, no server DB (IndexedDB history).

## The pipeline (validated, real data)
```
scan QR  ─▶ /api/nfce   ─▶ items: {description, cProd, qty, unit, paidUnitCents}     (SEFAZ-PR consulta)
per item ─▶ /api/precos ─▶ {gtin?, basis, cheapest:{priceCents,store,km}, nStores}   (Menor Preço)
         ─▶ savings = Σ positive (paidUnitCents − cheapestUnitCents)   [after guardrails]
```
One Menor Preço `termo=<description>` search per item does double duty: recover the GTIN (same-store exact-desc match) **and** find the cheapest nearby offer for that product. Client caches everything in IndexedDB.

## Matching & guardrails (the core correctness work)
Coverage is easy (100%); **trustworthy savings is the hard part.** Two tiers plus two guards:
- **Packaged → GTIN-keyed (high confidence).** Recover the GTIN via same-store match, then take the cheapest nearby offer carrying that exact GTIN.
- **Produce / SEM-GTIN → description + unit-basis (approximate, flagged).** No barcode exists; match by description tokens, but **only compare like units** — a per-**UN** papaya must not be compared to a per-**KG** papaya. (This false match is what inflated the raw number.)
- **Outlier trimming.** Crowd-sourced NFC-e prices carry bad entries (a R$25,90 item "found" at R$8,90 on the *same* GTIN). Drop offers far below the median before taking the min.
- **Confidence flag** per line (`gtin` = solid, `desc` = approximate) so the UI can label produce honestly.

Measured effect on the sample receipt: raw savings **R$56 → defensible ~R$21** after guardrails — still ~2× the online path at ~2.6× the coverage.

## Dependencies (minimal)
`react`, `react-dom`, `vite`, `@vitejs/plugin-react`, `vite-plugin-pwa`, `html5-qrcode`, `idb`, `node-html-parser` (consulta parse only), `vitest`. Menor Preço is JSON — plain `fetch`. **No online-retailer / VTEX dependency in the MVP.**

## Repo layout
```
economia/
  api/
    nfce.js       # QR p= → SEFAZ-PR consulta → items (paid prices)          [EXISTS]
    precos.js     # {store, item} → Menor Preço → gtin + cheapest nearby     [NEW, replaces preco-online]
  src/
    App.jsx
    views/  ScanView.jsx  ReceiptView.jsx  HistoryView.jsx
    lib/
      nfce.js     # parse QR; call /api/nfce
      precos.js   # orchestrate store-resolve + per-item cheapest (cached)   [NEW]
      savings.js  # computeSavings + guardrails (unit-basis, outliers)       [REWRITE]
      money.js    # parseBRL (consulta) + reaisToCents (Menor Preço) + formatBRL
      db.js       # idb: receipts + price cache
    # data/catalog.json — DELETED (no seeded catalog)
  test/  nfce.parse / precos.match / savings.guardrails / money
  fixtures/  sample-consulta.html + menorpreco-sample.json
```

## Build steps
0. **(done) Validate** — the 23-item real receipt already proved 100% local coverage; keep the Menor Preço response as `menorpreco-sample.json` for tests.
1. **Scaffold / PWA / Vercel** (exists) — confirm it installs on a phone.
2. **`/api/nfce`** (exists) — consulta → items with `paidUnitCents` + store header (name, address, city). (`gtin` is null from here.)
3. **Store resolution** — match the receipt's store to a Menor Preço establishment by **name + address** (Menor Preço has no CNPJ); cache its `codigo` + city coords. Resolve **once per receipt**.
4. **`/api/precos`** — per item: `termo=<desc>` search near the store → (a) same-store exact-desc → **GTIN**; (b) cheapest nearby offer for that product (GTIN tier / desc+unit tier) → `{gtin, basis, cheapest:{priceCents,store,km}, nStores}`. Unit-test matching + guardrails against `menorpreco-sample.json`.
5. **Savings + report** — `savings.js` applies unit-basis + outlier guards; `ReceiptView` shows per item: paid, cheapest-nearby (price · store · distance), savings; total *"você poderia economizar R$X comprando por perto"*; produce lines flagged approximate.
6. **History** — IndexedDB list, reopen saved report.
7. **PWA polish + tests.**

## Key notes
- **Two money formats.** Consulta = `R$ 1.234,56` → `parseBRL`. Menor Preço `valor` = `"3.19"` (dot-decimal reais) → `reaisToCents`. Don't cross them.
- **Same-store filter is load-bearing** for GTIN recovery — the identical product is written many ways across stores; only within one store is `description → gtin` unique.
- **`termo` does not accept a raw barcode** (returns 0) — cross-store prices come from the description search, filtered by the recovered GTIN.

## Risks / mitigations
1. **Savings correctness (the #1 risk now).** Unit-basis mismatches + price outliers make numbers lie. Mitigate with the guardrails above; flag produce as approximate; never show a comparison you can't justify. A wrong "you overpaid R$17" destroys trust.
2. **Store resolution** — receipt CNPJ ↔ Menor Preço name/address (no CNPJ). Resolve once, exact-address preferred, cache.
3. **Single external dependency** — Menor Preço is undocumented / no SLA. Cache aggressively; isolate behind `/api/precos`; review ToS before commercial scale.
4. **SEFAZ-PR consulta** — CAPTCHA/HTML drift; client-cache by access key; certificate-gated XML is the ceiling, out of MVP.

## Verification
- Scan a real PR receipt → every item gets a cheapest-nearby price (~100% coverage) → the savings figure is defensible (no UN-vs-KG false positives, no outliers) → produce flagged → persists in history and survives reload.
- Tests green: consulta parse; Menor Preço same-store match; savings guardrails (feed a UN-vs-KG case **and** an outlier, assert both are rejected); money (both formats).

## Deferred — documented for later
- **Online-retailer comparison** (the old MVP spine): recover the GTIN → query a retailer's VTEX API (`?fq=alternateIds_Ean:<gtin>`). Verified working (Super Nova Era, Super Muffato) but only ~39% basket coverage — add as a *bonus row* once local is solid and if affiliate revenue becomes a priority.
- Rewards / engagement layer (see 10_Rewards_And_Engagement.md), accounts + backend, OCR / manual entry, native apps, and Phase-2/3 features (pantry, alerts, AI advisor, forecasting).
