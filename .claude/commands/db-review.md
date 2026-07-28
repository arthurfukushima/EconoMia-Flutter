---
description: Review what the price database has learned — canonical/alias coverage gaps, grouping failures, NCM and unit_basis errors. Read-only; proposes seed edits, never writes to Neon.
---

Review the Neon price database and propose improvements. `$ARGUMENTS` may narrow the
pass (a category, a product name, "coverage only"); with no arguments, do the full run.

`raw_prices` is an append-only record of every Menor Preço offer the app has ever
fetched — the only place the matching engine's real-world behaviour is visible.
The backend, its schema and its tooling all live under `backend/`; every npm command
below runs from there, not from the repo root.

`backend/tool/db/canonical-gaps.mjs` does the counting. **You do the judgment**: the part
that needs to know *bergamota* and *mexerica* are the same fruit, that
`BK MIX NUTELLA` is a lanchonete's milkshake and not groceries, and that a per-kilo
beef canonical matching an offer at R$ 1,06/kg means something is wrong upstream.

## Guardrails

- **Read-only against Neon.** `SELECT` and `WITH` only. Never `INSERT`, `UPDATE`,
  `DELETE`, `ALTER`, `CREATE`. The one exception is `npm run db:seed` — and only
  after the human has approved the diff.
- **Never invent an alias.** Every proposal quotes descriptions that exist in
  `raw_prices`, with a market count. No corpus evidence → it doesn't ship.
- **≥3 distinct markets** to propose a seed entry. Below that it is one store's
  typo — put it in a watchlist section instead.
- **Propose, don't apply.** Output a diff against `backend/db/seed.mjs`.
- Credentials come from `backend/.env.local` (gitignored). Never print a connection string.

## 1. Snapshot

```
cd backend && npm run db:review -- --json --limit=60
```

Five sections: `uncovered` (barcode-less descriptions in scope that
`lookupCanonical` fails), `overReach` (aliases firing on barcoded products — wrong
by construction), `ncmConflicts`, `basisCheck`, `deadCanonicals`. Note the coverage
percentage; if `backend/db/coverage-log.md` has a previous run, compare first — a drop is a
regression worth chasing before anything else.

## 2. Investigation passes

The script ranks by market reach. Ranking is not analysis. Work these, each
producing evidence-backed proposals:

**Synonyms and regionalisms.** Highest value. Scan `uncovered` for terms that are an
existing canonical under another name — *mexerica / tangerina / ponkan /
bergamota*, *aipim / mandioca / macaxeira*, *abóbora / jerimum / cabotiá*. Separate
products to SQL, one product to a shopper.

**Cultivars and cuts.** A canonical exists, its varieties don't: `Manga` without
*Palmer/Tommy/Espada*. Query the corpus for the canonical's head token and read what
qualifiers actually follow it — list the ones stores type, not the ones you can name.

**Receipt abbreviations.** Descriptions sharing one GTIN are known-synonymous — free
labelled data. Diff token sets within GTIN groups in scoped categories: that is
where `FGO`≡`FRANGO`, `CR`≡`CREME`, `LT`≡`LEITE` come from, grounded in real pairs.

**Prepared food.** Lanchonetes and bars issue NFC-e too. `ADICIONAL CEBOLA`,
`MILK SHAKE 3 LEITES`, `LANCHE PAO FRANCE KG` are not groceries and can never be a
valid price comparison. They belong in an exclusion rule, **not** in
`canonical_products`. Flag as a group; propose no canonicals for them.

**Wrong basis and impossible prices.** Cross-check `basisCheck` against the prices.
A `[KG]` canonical whose offers cluster under R$ 2,00 is priced per unit in reality.

**Over-reach.** Every line there is a live mis-match. Diagnose the mechanism, not the
symptom: `backend/api/precos.js`'s `candidatesFor` sets `want = canonical.tokens`, so a canonical hit
*replaces* the item's own tokens and discards every discriminating word. Propose the
guard (skip canonical resolution when a GTIN is present; processed-marker
blocklist), not just an alias tweak.

**NCM conflicts.** `classify()` prefers NCM as deterministic. It is deterministic per
row, not correct — the same description carries a different NCM at every store that
typed it (`MEXERICA KG` spans 11 codes). Check how many chapters one description
spans before blaming the keyword list.

## 3. Report

Lead with what changed and what it costs a user, then the proposals:

- **Findings** — count, mechanism, user-visible consequence. "313 packaged products
  hit a loose-goods alias" beats "alias matching could be improved".
- **Proposed seed entries** — a diff against `backend/db/seed.mjs`, grouped by category, each
  line carrying its evidence (`// 33 mkts: MEXERICA KG, MEXERICA PONKAN KG, HORTFG
  MEXERICA KG`).
- **Watchlist** — under the 3-market bar, kept for next run.
- **Code changes** — when the gap is a rule rather than data, say so and point at the
  file. A missing guard in `backend/api/lib/canonical.js` is not fixed by seeding more rows.

## 4. Apply

Only on approval: edit `backend/db/seed.mjs` (idempotent, `ON CONFLICT DO NOTHING`),
run `npm run db:seed`, re-run the report, and record the new coverage number in
`backend/db/coverage-log.md` with the date. The seed file stays the source of truth — the DB
is a derivative, never hand-edited.

## Free-form questions

For anything the fixed report doesn't cover ("which markets have the freshest
data?", "did grouping get worse this week?"), read `backend/tool/db/queries.md` — schema,
grouping-key semantics, and probes that already work. Same standard: state what you
measured, quote real rows, separate what the data shows from what you infer.
