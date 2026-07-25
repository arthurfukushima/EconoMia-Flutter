# Gamification — Mia Points

**Mia Points** are EconoMia's **soft currency**: users earn them by contributing
data (and, later, by showing up and reporting), and spend them in the **Loja da
Mia** on coupons, products, and cosmetics. The point is to reward the behavior the
whole app depends on — scanning notes — and give Mia a way to say "obrigada".

## Shipped (v1)
- **Earn — note scan.** Scanning a *new* fiscal note awards `10 × unique products`
  in it. Unique = distinct `gtin`, falling back to the normalized description for
  weighed/PLU items (same key as [insights.aggregate](../src/lib/insights.js)).
- **Dedup — local, one award per note.** Awarding is hooked in the single new-note
  branch of `handleScanned` ([App.jsx](../src/App.jsx)); a re-scan finds the note in
  IndexedDB (`accessKey` keyPath) and never re-enters that branch, so the same note
  can't be farmed. *Local only for now* — server-side "claimed by any user" comes
  with accounts.
- **Balance.** A localStorage scalar `economia.miaPoints` ([src/lib/mia.js](../src/lib/mia.js)),
  not derived from notes — because the Store will *spend* points and future faucets
  will *add* them, a balance can't be recomputed from the notes ledger.
- **Display.** A points pill on the Home greeting row (`.home-points`), Baloo 2 /
  tabular-nums, Sage & Amber tokens.
- **Loja da Mia shortcut.** A disabled full-width tile on Home ("Em breve · troque
  seus pontos"). The Store itself is **not built**.

### Known ceiling
`clearReceipts()` then re-scanning would re-award — acceptable for a local MVP.
The real fix is server-side dedup once notes are claimed against an account.

## Shipped (v2) — Missões da Mia (quests)
Quests are the second faucet: **counters over named events**, all in
[src/lib/quests.js](../src/lib/quests.js) (`economia.quests` in localStorage, same
scalar-setting idiom as `lista.js`/`cep.js` — no IndexedDB store, contra the ledger
sketch in [10_Rewards_And_Engagement.md](10_Rewards_And_Engagement.md)).

**Events (6):** `note`, `product`, `mercado`, `list_add`, `list_check`, `location`.
Emitted by `track(event, n)` from the places the action already happens — the new-note
branch and barcode branch of `handleScanned` plus both location handlers
([App.jsx](../src/App.jsx)), `onScanned` ([MercadoView](../src/views/MercadoView.jsx),
counts as *both* `product` and `mercado`), and `add`/`toggle`
([ShoppingListView](../src/views/ShoppingListView.jsx) — only unchecked→checked counts,
so toggling can't farm).

**Three tracks**, all rendered inline on Home (`QuestBoard` in
[HomeView.jsx](../src/views/HomeView.jsx)) — no separate view:
| Track | Active | Rotation |
|---|---|---|
| **Diárias** | 3 of a 5-quest pool | completed slots replaced every 24h |
| **Semanais** | 3 of a 5-quest pool | completed slots replaced every 7d |
| **Primeiros passos** (FTUE) | 5 at a time, in catalog order | never rotate; a claimed one frees its slot for the next |

**Progress = `counts[event] − slot.base`**, where `base` is the counter value when the
slot opened — so a quest only counts actions taken *after* it appeared (no retroactive
credit). Completion is derived (`progress >= goal`); the slot stores only `hit`
("already toasted") and `claimed` ("already paid").

**Tap to claim.** Hitting the goal doesn't pay — the row turns into a "Resgatar +N"
button on Home, and `claim(id)` is the single payout path (`addPoints`). A quest
completed but never claimed when its window rolls is **still paid** (`autoAwarded` in
`refresh`): a missed tap must never burn a reward.

**Notification.** `track()` dispatches a `mia:quest` `CustomEvent` on `window` for each
newly completed quest; `QuestToast` in [App.jsx](../src/App.jsx) queues them into a
5s toast above the tab bar, so a completion in any view is announced without prop
threading.

**One reducer.** `refresh(state, now)` is pure and does everything (roll windows,
auto-claim, refill slots); `loadQuests`/`track`/`claim` are thin localStorage wrappers
around it. Tested in [test/quests.test.js](../test/quests.test.js).

### Known ceilings
- Rollover is evaluated **on read** — a session left open past the 24h mark refreshes on
  the next Home mount, not on a timer.
- The catalog is data: a new quest is one array entry (plus one `track()` call only if
  it needs a new signal).
- Same local-MVP trust ceiling as the balance: `economia.quests` is devtools-editable and
  the daily window is clock-spoofable. Server-side re-validation comes with accounts.

## Roadmap — earn (faucets)
Ordered by how cheaply the app can source the signal **today** (all derivable from
the local receipts/offers stores unless noted).
- **Fresh-note bonus** — extra points if scanned within ~24–48h of purchase
  (`header.purchasedAt` exists). Rewards timely data → fresher prices for everyone.
- **New-store bonus** — first note from a `cnpj` never scanned before (`listReceipts`).
- **Daily login streak** — locally, an "open app" streak via a `lastSeen` date +
  a streak multiplier. Becomes a true login streak once accounts exist.
- **Richer quest goals** — "a note > R$150", "produce from 2 stores", "a new store":
  these need a *predicate over receipts*, not a counter, so they'd extend the catalog
  with an optional check function rather than an `event`.
- **Achievements / badges** — one-time: 1st / 10th / 50th note, 100 unique
  products, first savings > R$50.
- **Battle Pass / Season** — a monthly XP track filled by the actions above, with
  tiered rewards; free + premium lanes later.
- **Reporting bonus** — flag a wrong/missing price. Needs moderation → later.
- **Referral / leaderboards / savings milestones** — need accounts or a server.

## Roadmap — spend (sinks: the Loja da Mia)
- **Coupons & products** — the headline rewards.
- **Cosmetics** — the cheap, high-value sink: Mia outfits/skins, **app themes**
  (recoloring the `--sa-*` tokens makes new themes nearly free), home backgrounds,
  Mia voice packs, seasonal decorations, avatar frames.
- **Utility unlocks** — streak freeze, mission reroll, 2× weekend boost.

## Economy notes
- **Every faucet needs a sink.** Until the Store ships, keep award rates modest and
  *honorable* — points issued now must be worth honoring later.
- **Anti-inflation control** is the `accessKey` dedup (one award per real note);
  server-side "claimed by any user" replaces it post-accounts.
- Mia's **voice** should carry the rewards (see [11_Branding_And_Mia.md](11_Branding_And_Mia.md)):
  "Boa! +150 pontos por essa nota." — objective, friendly, never childish.
