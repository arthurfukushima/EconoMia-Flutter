# Home Screen — "A casa da Mia"

Analysis of the shipped Home Screen ([src/views/HomeView.jsx](../src/views/HomeView.jsx))
and the app shell around it ([src/App.jsx](../src/App.jsx)). This is the hub the
app opens to — the first surface where **Mia speaks** and the entry point to every
other view.

## Role
The default view (`view = 'home'`). It's a **hub, not a feature**: it summarizes
what Mia knows, points at the flagship action (scan), and routes to the other
views. It holds no data of its own — every figure is pulled from the same local
sources the other views trust, so nothing on it is a claim the app can't back.

## Layout (top → bottom)
Inside the "paper sticker sheet" (`.app`), below the topbar + `LocationBar`:

1. **Greeting** — time-of-day (`Bom dia / Boa tarde / Boa noite 👋`).
2. **Mia savings hero** (`.home-hero`) — forest-green card, Mia avatar (the logo).
   - *Has savings:* `🐱 Mia · dá pra economizar` → "Comprando no lugar mais
     barato, você guarda" → the figure (`Baloo 2`, large) → "São os preços
     melhores que achei nas suas notas." + optional annual projection ("No seu
     ritmo, dá **R$ X** por ano."). Framed as **opportunity, not achieved**: the
     number is paid − cheapest nearby (money still on the table), never a claim
     that Mia already banked it.
   - *Onboarding (no savings yet):* "Escaneie sua primeira nota e eu começo a
     caçar economia pra você."
3. **Atalhos** — 2×2 tile grid (`.home-grid` / `.qtile`), each with a live meta line:
   | Tile | Route | Meta (has data → empty) |
   |------|-------|--------------------------|
   | 🛒 Lista de Compras | `lista` | *N* itens → "Monte sua lista" |
   | 🏪 No mercado | `mercado` | "Compare preços perto" |
   | 🔥 Ofertas do dia | `tendencias` | **N** ofertas hoje → "Melhores dias por categoria" |
   | 🧾 Minhas Notas | `history` | *N* notas · R$ gasto → "Seu histórico aqui" |
4. **Dica da Mia** (`.home-dica`) — one data-driven tip.
   - *Has a trend:* "Hoje é dia de [categoria]" → "[categoria] costuma sair mais
     barato hoje no **[loja]**" → `−X%` badge.
   - *Fallback:* "Ainda aprendendo os preços daqui" + a nudge to scan more notes.

## Data sourcing (all local, all honest)
Loaded once on mount, no network of its own:
- `listReceipts()` → `aggregate(...)` → accumulated saved, annual projection,
  notes count, total spent ([lib/insights.js](../src/lib/insights.js)).
- `getList()` → shopping-list item count ([lib/lista.js](../src/lib/lista.js)).
- `listOffers()` → `trendsByWeekday(cheapDayByCategory(...))` for today's weekday
  → today's offer count + top trend ([lib/tendencias.js](../src/lib/tendencias.js)).

**The honesty rule:** every block has a real state and an empty state. No notes →
onboarding copy, never a hollow "R$ 0,00". No gated trend → a learning nudge,
never a fabricated promo. Mia only claims what the on-device data proves.

## App shell & navigation
The shell lives in [App.jsx](../src/App.jsx): `topbar` (wordmark) · `LocationBar`
(CEP + radius) · `main` (the switched view) · `BottomNav` (fixed).

**BottomNav — five slots, center FAB:** Início (this hub) · Lista · **Escanear**
(raised amber FAB, the flagship) · Ofertas (`tendencias`) · Resumo (`dashboard`).
"No mercado" and "Minhas Notas" deliberately have **no** tab slot — they live as
home tiles, keeping the bar at five. The FAB is the **only** scan entry point —
it opens the **scan chooser** (`ScanChooser`, a bottom sheet) that asks intent
first — 🧾 **Nota fiscal** (QR → histórico) vs 🏷️ **Produto** (código de barras →
preço perto) — then opens `ScanView` in that `mode`. Scanning nota and produto
are distinct moments (bookkeeping vs in-the-moment price check), so intent comes
before the camera. Routing in `handleScanned` stays content-based, so a mis-tap
still lands correctly.

## Visual language — "Sage & Amber"
The home + bottom nav are the first surfaces on the refined **Sage & Amber**
direction (`--sa-*` tokens in [styles.css](../src/styles.css)): forest green
`#14312A`, amber `#E4872B`, warm papers, mint/green for positive figures. The
tokens are **scoped** — older views still render on the original "Chubby Cat"
tokens (`--pine-*`, `--orange-*`, `--kraft-*`), so both systems coexist until the
rest of the app migrates. Type: Fredoka (headings/labels), Baloo 2 (the savings
number), Nunito (body). Rounded sticker cards, soft lifts, an amber-gradient CTA
on a forest hero. See [11_Branding_And_Mia.md](11_Branding_And_Mia.md).

## Status & pending
- **Shipped:** the hub, both states of every block, bottom nav, Sage & Amber on
  home + nav. Mia's **voice** ships here first (hero + Dica copy).
- **Pending:** migrating the remaining views to the Sage & Amber tokens.
