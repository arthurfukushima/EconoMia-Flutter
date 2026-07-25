# WhatsApp Fiscal-Note Ingestion

> **Status: Proposed — not yet implemented (2026-07-23).** Design spec only.
> Related: `08_Open_Questions.md` ("When to introduce accounts + backend"),
> `04_Technical_Architecture.md`, `02_MVP.md`.

## Goal

Let a user **share a fiscal note over WhatsApp** — a link, a photo, or a PDF — have it
**processed and saved to their account**, and receive a **WhatsApp reply** confirming the
save (or a specific error). Notes ingested this way **appear in the existing "Minhas Notas"**
alongside scanned receipts.

## Why this is a real backend step

EconoMia today is a **100% client-side PWA** (Vite + React) with three stateless Vercel
proxies (`api/nfce.js`, `api/precos.js`, `api/cep.js`), **no auth, no accounts, no server DB,
no secrets, no webhooks**. Receipts live in the browser (IndexedDB `receipts` store, keyed by
`accessKey`). This feature introduces the project's first accounts, first persistent
server-side storage, and first inbound webhook + secrets — the post-MVP "accounts + backend"
gate the docs already anticipate.

The one reuse win that keeps it tractable: **every input path reduces to recovering the QR's
signed `p` payload, then calling the existing SEFAZ parser.** A link already contains `p`; a
photo/PDF just needs its QR decoded; only when no QR is recoverable do we fall back to OCR.

### Decisions (locked)
- **Provider:** Meta WhatsApp Cloud API (official; free at this volume; no per-message markup).
- **Data home:** sync into the existing app — notes surface in "Minhas Notas".
- **Input scope:** all formats — link, photo, PDF — plus a vision/OCR fallback.

### Known ceilings (accept up front)
- **Step-0 parser gate is still open** (`README`, `parseConsulta` in `api/nfce.js`):
  selectors are verified only against a synthetic fixture, never a real SEFAZ-PR page. All
  paths inherit this risk.
- **Bare access-key links can't be parsed** — the consulta needs the *signed* `p` (hash); a
  national/"Receita Federal" link with only the 44-digit key is CAPTCHA-walled. Those get a
  clear error reply, not a save.
- **Meta onboarding friction:** a Meta Business account, business verification (can take
  days), and a dedicated phone number are prerequisites — build can proceed against the Cloud
  API **test number** meanwhile.
- **`accountId` is a bearer capability, not real auth** (matches the app's current anonymous
  stance). Whoever holds the UUID can read that account's receipts. Upgrade path: real auth.

---

## Architecture

```
WhatsApp user ──(text/image/document)──▶ Meta Cloud API
                                              │ POST webhook (signed)
                                              ▼
                                     api/whatsapp.js
   ┌──────────────────────────────────────────┼───────────────────────────────┐
   │ 1. verify X-Hub-Signature-256 (raw body)  │                               │
   │ 2. route by message type → recover `p`    │                               │
   │      text  → parseQrPayload(text)         │                               │
   │      image → download → decodeQr(buf)     │──no QR──▶ ocr(buf) (Claude)   │
   │      pdf   → text-layer URL, else raster QR│──no QR──▶ ocr(...)            │
   │ 3. p ⇒ fetchAndParseReceipt(p)  (REUSE)   │                               │
   │ 4. resolve account by phone (link code)   │                               │
   │ 5. store receipt (Upstash) under account  │                               │
   │ 6. reply via Meta (24h window, free-form) │                               │
   └───────────────────────────────────────────────────────────────────────────┘
                                              │
PWA (HistoryView) ──GET /api/receipts?account&since──▶ merge into IndexedDB (saveReceipt)
PWA "Conectar WhatsApp" ──POST /api/link──▶ one-time code ──▶ wa.me/<biz>?text=EconoMia:<code>
```

### Identity & linking — deep-link code (no OTP, no template)
The PWA holds an anonymous `accountId` (`crypto.randomUUID()`, persisted in `localStorage` as
`economia.accountId`). "Conectar WhatsApp" calls `POST /api/link` → server mints a single-use,
TTL-bound `code` mapped to that `accountId`, and opens
`https://wa.me/<BUSINESS_NUMBER>?text=EconoMia:<code>`. The user hits send; the webhook sees
the code and binds `phone → accountId`. Thereafter every note that phone sends is stored under
that account. This avoids business-initiated messaging entirely — no approved template, no OTP
typing.

### Storage — Upstash Redis (KV) via `@upstash/redis`
KV covers every access pattern here with no schema/migrations. (Upgrade to Postgres only when
cross-user analytics/trends arrive.)
- `code:<code>` → `accountId` (SET EX 600; delete on bind — single-use)
- `phone:<e164>` → `accountId`
- `acct:<accountId>:receipts` → sorted set (score = savedAt, member = key)
- `receipt:<key>` → receipt JSON
- `ratelimit:<e164>` → per-phone counter

---

## Build order (each phase independently shippable + testable)

### Phase A — Plumbing + link input (vertical slice)
- **Refactor for reuse:** extract the fetch+parse core of `api/nfce.js` into
  `export async function fetchAndParseReceipt(p)` → `{ accessKey, header, items }` (throws
  typed errors: `invalid_access_key`, `portal_unavailable`, `no_items_parsed`). Existing
  `handler` becomes a thin wrapper (no behaviour change; tests stay green).
- **`api/whatsapp.js` (new):**
  - `GET`: Meta verify challenge — echo `hub.challenge` iff `hub.verify_token` matches
    `WHATSAPP_VERIFY_TOKEN`.
  - `POST`: read **raw body**, verify `X-Hub-Signature-256` (HMAC-SHA256 with
    `WHATSAPP_APP_SECRET`), parse `messages[]`. **text** → `parseQrPayload` (reuse
    `src/lib/nfce.js`; `api/` already imports from `src/lib/`) → `fetchAndParseReceipt(p)` →
    store → reply. Bare-key/national link → typed error reply.
- **`api/_lib/store.js` (new):** Upstash helpers (`bindPhone`, `accountByPhone`, `mintCode`/
  `consumeCode`, `putReceipt`, `listReceipts`).
- **`api/_lib/whatsapp-meta.js` (new):** `sendText(to, body)` (POST
  `graph.facebook.com/v21.0/<PHONE_NUMBER_ID>/messages`) and `downloadMedia(mediaId)` (fetch
  media URL then bytes with Bearer token; cap size, check content-type).
- **Reply copy (Mia voice):** success → `🐱 Nota salva! <storeName> — <N> itens, R$ <total>.
  Veja em <appUrl>.` Errors → specific ("Esse link só tem a chave, sem os dados assinados —
  não dá pra consultar", etc.).
- **Env/secrets (Vercel):** `WHATSAPP_VERIFY_TOKEN`, `WHATSAPP_APP_SECRET`, `WHATSAPP_TOKEN`,
  `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_BUSINESS_NUMBER`, `UPSTASH_REDIS_REST_URL`,
  `UPSTASH_REDIS_REST_TOKEN`. (First secrets in the project.)

### Phase B — Account linking + app sync
- **`api/link.js` (new):** `POST { accountId }` → `mintCode` → `{ code, waLink }`.
- **`api/receipts.js` (new):** `GET ?account=<id>&since=<ts>` → account's receipts newer than
  `since`. (`accountId` = bearer capability — documented ceiling.)
- **PWA:** in `src/App.jsx` ensure/persist `economia.accountId`; on load and on focus, pull
  `GET /api/receipts` and merge each into IndexedDB via existing `saveReceipt` (dedup by
  `accessKey` is automatic). Existing `listReceipts` / `src/views/HistoryView.jsx` then shows
  them with **zero render changes**. Add a "Conectar WhatsApp" control near the CEP/settings
  UI (`src/lib/cep.js`) that calls `/api/link` and opens `waLink`.
- Client-side enrichment (`enrichReceipt`) is unchanged — WhatsApp-ingested notes get prices
  the same way scanned ones do.

### Phase C — Photo (image message)
- **`api/_lib/qr.js` (new):** `decodeQrFromImage(buf)` using **`jimp` + `jsqr`** (both pure JS,
  serverless-safe) → QR string (SEFAZ URL) or `null`. Webhook image branch: `downloadMedia` →
  `decodeQrFromImage` → `parseQrPayload` → `fetchAndParseReceipt`. `null` → Phase E.

### Phase D — PDF (document message)
- Extend `api/_lib/qr.js`: **`pdf-parse`** (pure JS) to pull the SEFAZ `qrcode?p=…` URL from
  the PDF **text layer** first (cheapest — many DANFEs carry it as text). Only if that misses,
  render the page and run `jsqr` on the raster (`pdfjs-dist`; gate this behind need — raster
  may pull a native `canvas` dep). Miss → Phase E.

### Phase E — OCR fallback (Claude vision)
- **`api/_lib/ocr.js` (new):** send the image (or rasterized PDF page) to **Claude vision** →
  structured `{ storeName, purchasedAt, items:[{description, qty, unit, unitPriceCents,
  lineTotalCents}], totalCents, confidence }` matching the `parseConsulta` shape.
  - Default model **`claude-haiku-4-5`** for cost; escalate to Opus if accuracy insufficient.
    Consult the `claude-api` reference for current vision params / pricing before building.
  - No access key here → synthetic key `ocr-<sha1(store|purchasedAt|total)>`; tag record
    `source:'ocr'`, `confidence:<0..1>`. `receipts` keyPath is `accessKey`, so a synthetic
    value needs **no DB schema change**.
  - Reply notes lower confidence ("Li pela foto — confere os valores 🐱").
- Add `ANTHROPIC_API_KEY`.

---

## Files

**New:** `api/whatsapp.js`, `api/link.js`, `api/receipts.js`, `api/_lib/store.js`,
`api/_lib/whatsapp-meta.js`, `api/_lib/qr.js`, `api/_lib/ocr.js`.
**Modify:** `api/nfce.js` (extract `fetchAndParseReceipt`), `src/App.jsx` (accountId +
pull-sync + Conectar control), `src/views/HistoryView.jsx` (only if a "via WhatsApp" /
confidence badge is wanted — otherwise untouched).
**Reuse as-is:** `parseQrPayload` (`src/lib/nfce.js`), `parseConsulta`/`decodeHtml`
(`api/nfce.js`), `saveReceipt`/`listReceipts` (`src/lib/db.js`), `enrichReceipt`
(`src/lib/precos.js`).
**New deps (per phase):** `@upstash/redis` (A); `jimp` + `jsqr` (C); `pdf-parse`
(+ `pdfjs-dist` only if raster needed) (D); `@anthropic-ai/sdk` (E).

---

## Security (do not simplify away)
- Verify `X-Hub-Signature-256` against the **raw** request body on every webhook POST; reject
  mismatch. (Vercel Node function: read the raw stream — don't rely on a parsed `req.body`.)
- Verify `hub.verify_token` on the GET challenge.
- Cap downloaded-media size and check content-type before decoding (hostile/huge-file guard).
- Link `code`: single-use (delete on consume) + short TTL.
- Reuse the 44-digit access-key validation at the parse boundary.
- Per-phone rate limit on inbound (Upstash) — can follow the first cut; note the ceiling.
- Never log tokens, media bytes, or full phone numbers.

---

## Testing (end-to-end)
1. **Unit (`vitest`, extend existing suite):** `fetchAndParseReceipt` still parses
   `fixtures/sample-consulta.html` (refactor guard); `decodeQrFromImage` on a fixture
   receipt-photo PNG; PDF text-layer URL extraction on a fixture DANFE; OCR parse-shape on a
   canned Claude response; webhook signature verify (good/bad HMAC); link code
   bind→resolve round-trip.
2. **Webhook live:** point the Meta app's callback at a Vercel **preview** deployment (or
   ngrok); pass the GET verify challenge; from the linked phone send, in turn: a SEFAZ
   `qrcode?p=…` **link**, a **receipt photo**, a **DANFE PDF**, and a QR-less **blurry photo**
   (exercises OCR). Confirm the correct reply and that `receipt:<key>` lands in Upstash.
3. **App sync:** click "Conectar WhatsApp", send the code, confirm the four notes appear in
   "Minhas Notas" after pull-sync, and that opening one enriches prices like a scanned note.
4. **Error paths:** bare-access-key/national link → "só tem a chave" reply, nothing saved;
   message from an *unlinked* phone → reply prompting to connect first.
