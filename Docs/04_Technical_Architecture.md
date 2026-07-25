# Technical Architecture

Two horizons live here: the **shipped MVP** (validated, live) and the **target
platform** (Hugo's proposal). The MVP is a thin, local slice of the target.

## Shipped MVP (reality)
React + Vite **PWA**, Vercel serverless proxies, **no auth, no server DB**
(IndexedDB history). Pipeline:
```
scan NFC-e QR ─▶ /api/nfce (SEFAZ-PR) ─▶ items+paid
             ─▶ /api/precos (Menor Preço) ─▶ gtin + cheapest nearby ─▶ savings
```
Full detail in [09_MVP_Implementation_Plan.md](09_MVP_Implementation_Plan.md).
Stack note: Hugo's proposal specced **Flutter + Riverpod + GoRouter**; the app
actually shipped as a **React PWA** (Android/iOS via install; desktop for free).
Native Flutter builds remain a post-MVP option, not a committed decision.

## Target platform (north star)
Four layers, from Hugo's proposal:

### 1. Source layer → `RawPrice`
Every source emits one `RawPrice`, regardless of origin:
`{ source, market, description, price, quantity, unit, date, confidence, location }`.
Sources: QR/NFC-e · community · flyers (OCR+AI) · market spreadsheets · partner
APIs · crawlers · own team. **MVP implements only the QR/NFC-e source.**

### 2. Normalization layer → canonical products
Groups equivalents, fixes descriptions, standardizes units, identifies brands,
mints **Canonical Products**. `ARROZ NIKOH 5KG → {category: Arroz Japonês, brand:
Nikkoh, weight: 5kg}`. Uses an LLM for normalization + embeddings for similarity.
**MVP does a thin version:** same-store description→GTIN recovery + unit-basis
matching (no LLM/embeddings, no persisted canonical catalog).

### 3. Intelligence layer
Best market · best cross-store combination · equivalents · price history ·
alerts · Mia's suggestions · estimated savings. **MVP ships:** cheapest-nearby +
per-store basket comparison + savings. The rest is Phase 2/3
([07_Product_Roadmap.md](07_Product_Roadmap.md)).

### 4. Client
The PWA today (Flutter multi-platform in Hugo's proposal).

## Trust & confidence scoring
Each price carries a score, influenced by **source · age · confirmations ·
divergence · reputation** — e.g. "R$ 18,90 · 98% · confirmed today by 7 users."
**MVP approximation:** outlier-trimming of crowd-sourced Menor Preço prices + a
per-line confidence flag (`gtin` = solid, `desc` = approximate). The full
multi-factor score is a target-platform feature (needs accounts + a backend).

## Target data model (server, relational)
When accounts + backend arrive (the redemption/scale gate, see
[10_Rewards_And_Engagement.md](10_Rewards_And_Engagement.md)):
`Products` · `CanonicalProducts` · `Aliases` · `Brands` · `Categories` ·
`Markets` · `Prices` · `PriceHistory` · `ShoppingLists` · `ShoppingListItems` ·
`Sources` · `Users`.
Target infra: PostgreSQL · Redis · Firebase Auth · Cloud Storage · OCR/AI
workers. **None of this ships in the MVP** — MVP is IndexedDB-only
(`receipts`, `receipt_items`, `price_cache`; see [02_MVP.md](02_MVP.md)).

## Challenges
- Product normalization & duplicate products
- Catalog / canonical matching
- Unit standardization & like-unit comparison
- Price freshness & trust scoring
- Availability, and (for the deferred online path) shipping calculation
