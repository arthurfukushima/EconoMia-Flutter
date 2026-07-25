# Open Questions

- Which retailers first?
- QR or OCR first?
- Best product matching strategy?
- Shipping handling?
- How to rank recommendations?
- Annual savings methodology?
- International expansion?

## Resolved for MVP (see 02_MVP.md / 09_MVP_Implementation_Plan.md)
- **Goal:** engagement — validate that shoppers scan receipts and act on savings.
- **Market first:** Brazil — Paraná (PR).
- **QR or OCR:** QR only (NFC-e).
- **Comparison:** local — cheapest nearby store via Menor Preço do Nota Paraná. Online-retailer comparison deferred (validated, ~39% coverage vs ~100% local).
- **Product identity:** GTIN recovered via Menor Preço same-store description match (packaged); produce matched by description + unit-basis.
- **Ranking:** per-receipt savings (`paid − cheapest nearby`, positive only, after unit-basis + outlier guardrails).
- **Login:** none — single-device, anonymous, local history.

## Still open (do not block MVP)
- Which online retailer(s) for the deferred online comparison, and when to add it.
- Annual-savings methodology beyond the naive `× 52`.
- Radius / "nearby" definition, and how to weight distance vs. price.
- Trustworthy produce comparisons at scale (unit-basis edge cases, variety mismatches).
- International expansion beyond Brazil.
- Reward point values per action (see 10_Rewards_And_Engagement.md).
- Reward redemption mechanism (coupons vs. products).
- Anti-abuse for local-only points (before accounts exist).
- When to introduce accounts + backend (the redemption gate). A concrete proposal for this
  gate — WhatsApp note sharing, which forces accounts + server storage + a webhook — is
  specced in `12_WhatsApp_Note_Ingestion.md` (proposed, not yet built).
