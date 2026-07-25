# Rewards & Engagement (Points)

**Status:** Post-MVP, **Phase 2** (see `07_Product_Roadmap.md`). Not in the current MVP — the shipping app (scan → savings → local history) is unchanged by this doc.

## Intent
An engagement/retention layer on top of the core savings loop. Players earn **points** for three actions that each reinforce the loop: returning daily, feeding the app receipts (data), and acting on its recommendations. Point values and what points redeem for are **deliberately undecided** (see below).

## Earn mechanics

### Nota Fiscal upload
Points per **unique item** on an uploaded receipt.
- Unique = distinct **GTIN**; for SEM-GTIN items (produce, bulk, bakery), fall back to the item description.
- **De-duped by access key** — re-scanning the same receipt never re-earns. The idempotency key is `accessKey + gtin` (or `accessKey + description`), so each item on each receipt pays exactly once.

### Recommended-purchase reward
Points when a **later** receipt contains a product a **prior** savings report flagged as cheaper online (i.e. the app recommended buying it elsewhere and the player did).
- The set of "recommended GTINs" is **derived on read from existing stored receipt reports** — reuse `src/lib/savings.js` output over the `receipts` store; no new tracking store required.
  - `ponytail: derived scan over receipts; add a dedicated recommendations store only if that read gets slow.`
- On a new receipt, any item whose GTIN is in that set earns once. Idempotency key `accessKey + gtin`.

### Daily open
Points once per **calendar day** the app is opened (streak-friendly). Idempotency key is the local date `YYYY-MM-DD`, so a second open the same day earns nothing.

## Points value & redemption
**TBD — deliberately deferred.** Per-action point values are unset. Redemption candidates are **coupons or products**, routed through the business-model partners in `06_Business_Model.md` (cashback/affiliate/sponsored). None of this blocks documenting or prototyping the earn side.

## Storage & trust — local now, accounts later
Points are tracked **on-device** first (new local IndexedDB store), so the earn mechanics can be built and felt without a backend.

**Known ceiling (why this can't back real rewards yet):** local points are trivially editable in devtools, `daily open` is clock-spoofable, and uploads can be farmed from other people's receipts. So the local phase has **no real redemption** — points are an engagement score only.

**The unlock is accounts + a backend** that re-validates every earn server-side. That's the dependency for real coupon/product redemption, anti-fraud, and cross-device balances — and it's why this feature is post-MVP: today the app is deliberately login-less, single-device, and has no backend DB (`02_MVP.md` decisions). Accounts+backend are **not built now**; they're the documented gate before redemption goes live.

## Data model sketch (local, additive)
Adds one on-device store alongside the existing `receipts` (`src/lib/db.js`). Nothing in the MVP data model (`02_MVP.md`) changes.

- `points_ledger` — append-only:
  - `id` (PK), `type` (`receipt_item` | `recommended_purchase` | `daily_open`), `points`, `ref`, `created_at`.
  - **Balance = sum of the ledger.** A ledger (not a single mutable balance) makes earns idempotent and auditable: `ref` holds the idempotency key (`accessKey+gtin` for item/recommended earns, `YYYY-MM-DD` for daily). Before inserting, check no row with the same `type + ref` exists.

**Implementation note (for later, not part of this doc's task):** `db.js` is currently DB version 1 with a single `receipts` object store. Adding `points_ledger` needs a **1 → 2** version bump handled in `onupgradeneeded`.

## Open questions
- Point values per action (upload item / recommended purchase / daily open).
- Redemption mechanism: coupons vs. products vs. both.
- Anti-abuse while points are local-only (before accounts exist).
- When to introduce accounts + backend (the redemption gate).
- Recommended-purchase edge cases: partial GTIN coverage, price staleness at time of purchase.

## Metrics (ties to `06_Business_Model.md`)
- Daily active users — driven by `daily open`.
- Receipts imported — driven by the `upload` reward.
- Recommendation conversion — measured by `recommended-purchase` earns.
