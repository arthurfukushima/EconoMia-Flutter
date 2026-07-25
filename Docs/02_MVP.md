# MVP

## User Story
As a shopper, I want to scan the QR on my store receipt and discover where to buy each product cheaper nearby next time.

## Goal
Prove **engagement** — that shoppers will scan receipts and act on savings. Revenue (affiliate / sponsored / rewards) is deferred; this MVP validates the behavior loop.

## Decisions
- **Market:** Brazil — **Paraná (PR)**. Fiscal receipts are **NFC-e**; the printed QR links to SEFAZ-PR's public *consulta* page with fully itemized data.
- **Capture:** **QR scan only** (no OCR, no per-retailer parser, no manual entry).
- **Comparison:** **local — cheapest nearby store**, powered by **Menor Preço do Nota Paraná** (live, statewide NFC-e prices). No seeded catalog; **online-retailer comparison is deferred** (validated, but only ~39% basket coverage vs ~100% local).
- **Platform:** target is Android & iOS; the MVP ships as a **mobile-first web app / PWA**. Native apps are post-MVP.
- **No login:** single-device, anonymous; history persists locally in the browser.

## MVP Thesis — the one loop that must work
Scan the QR on a Paraná receipt → see what you bought and paid → see the **cheapest nearby store** for each item → total savings → saved to history.

## Scope
1. **Receipt capture (NFC-e QR)** — scan the QR; read the SEFAZ-PR access key/URL.
2. **Product extraction** — fetch the SEFAZ-PR consulta and parse items (description, qty, unit, **price paid**, line total, store name/address/CNPJ, date). The receipt has **no GTIN** — only an internal store code.
3. **Product identity** — recover the GTIN for packaged goods via a **Menor Preço same-store description match**; produce/SEM-GTIN matched by description.
4. **Cheapest-nearby lookup** — for each item, find the lowest current price at a nearby store via Menor Preço (GTIN-keyed for packaged; description + unit-basis for produce).
5. **Savings report** — per receipt, items cheaper at a nearby store, sorted by savings; total savings; each line shows the store + distance; produce comparisons flagged approximate.
6. **Purchase history** — past receipts (on-device), each openable to its saved report.

## Out of Scope
- Photo/OCR capture, manual item entry — QR only.
- **Online-retailer comparison** — deferred; local (nearby stores) only for the MVP.
- Anywhere outside Paraná — Menor Preço is PR-only.
- User accounts / login / cross-device sync.
- Native Android/iOS builds, app-store presence.
- Pantry, loyalty/rewards (see 10_Rewards_And_Engagement.md), price prediction/forecasting, family accounts, sale alerts, AI advisor, affiliate/monetization.

## Feature Detail (Paraná specifics)

### Receipt capture
- NFC-e QR = SEFAZ-PR URL (`fazenda.pr.gov.br/nfce/qrcode?p=<chave>|…`). Parse the **44-digit `chNFe`**; fetch the consulta via the signed `p` (the plain-key public consulta returns only a summary — no items).
- QR decode in-browser via one JS lib (`html5-qrcode`, works on Android + iOS).

### Product identity & pricing (Menor Preço)
- The receipt carries only the store's internal code (`cProd`), not the barcode. Recover the **GTIN** from Menor Preço by matching the item's description **within the same store** (descriptions vary per store, so same-store makes it 1:1).
- **Cheapest nearby** = lowest price for that product across stores within a radius: by **GTIN** for packaged goods; by **description + matching unit** for produce.
- **Guardrails (core):** compare only like units (per-UN vs per-KG) and trim price outliers from the crowd-sourced data, or the savings figure lies. Produce comparisons are flagged approximate.

### Savings
- Savings per item = `paid − cheapest nearby` (only when positive, after guardrails).
- Receipt savings = sum over items. Optional naive annual projection (`× 52`) — defer unless trivial.

## Data Model (sketch)
On-device (IndexedDB), no server DB, no catalog:
- `receipts` (access_key PK, store, city, purchased_at, total, created_at)
- `receipt_items` (access_key, description, cProd, gtin nullable, qty, unit, paid_unit_cents, line_total)
- `price_cache` (item key → cheapest {price, store, km}, fetched_at TTL)

## Suggested Lazy Stack
- **PWA / mobile web**, camera via `html5-qrcode`.
- **No backend DB, no auth.** History + caches in IndexedDB.
- **Serverless proxies only:** `/api/nfce` (SEFAZ-PR consulta) and `/api/precos` (Menor Preço) — both dodge browser CORS. One external dependency for pricing (Menor Preço).
- Build detail in [09_MVP_Implementation_Plan.md](09_MVP_Implementation_Plan.md).

## Risks
1. **Savings correctness** (the #1 risk) — unit-basis mismatches + crowd-sourced price outliers make numbers lie. *Mitigation:* like-unit comparison + outlier trimming; flag produce as approximate; never show an unjustifiable comparison.
2. **Store resolution** — Menor Preço has no CNPJ; match the receipt's store by name+address. *Mitigation:* resolve once per receipt, cache the `codigo`.
3. **Single external dependency** — Menor Preço is undocumented / no SLA. *Mitigation:* cache; isolate behind `/api/precos`; review ToS before scale.
4. **SEFAZ-PR consulta** — CAPTCHA/HTML drift; cache by access key; XML ceiling needs a certificate (out of MVP).

## Verification / Acceptance
With a **real Paraná NFC-e receipt**:
1. Scan → items + prices paid match the paper receipt; total matches.
2. Every item gets a cheapest-nearby price (~100% coverage on real baskets).
3. The savings figure is defensible — no per-UN-vs-per-KG false positives, no outliers; produce flagged approximate.
4. Receipt + report persist in history and survive reload.

Checks to leave behind: parse a saved consulta HTML → items; compute savings from a Menor Preço fixture, including a UN-vs-KG case and an outlier that the guardrails must reject.
