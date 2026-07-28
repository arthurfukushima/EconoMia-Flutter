import { parse } from 'node-html-parser';
import { parseBRL } from '../src/lib/money.js';
import { applyCors } from './lib/cors.js';

const SEFAZ_BASE = 'https://www.fazenda.pr.gov.br/nfce/qrcode';

// Vercel serverless entry: fetch the SEFAZ-PR consulta for a signed `p` payload,
// parse the item table, return JSON. Stateless — client caches by access key.
export default async function handler(req, res) {
  if (applyCors(req, res)) return;
  const p = (req.query && req.query.p) || (req.body && req.body.p) || '';
  const accessKey = String(p).split('|')[0].replace(/\D/g, '');

  // Validate at the trust boundary.
  if (accessKey.length !== 44) {
    return res.status(400).json({ error: 'invalid_access_key' });
  }

  try {
    const url = `${SEFAZ_BASE}?p=${encodeURIComponent(p)}`;
    const resp = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 (EconoMia)' } });
    if (!resp.ok) {
      return res.status(502).json({ error: 'portal_unavailable', status: resp.status });
    }
    const html = decodeHtml(Buffer.from(await resp.arrayBuffer()), resp.headers.get('content-type'));
    const parsed = parseConsulta(html);
    if (!parsed.items.length) {
      return res.status(502).json({ error: 'no_items_parsed' });
    }
    return res.status(200).json({ accessKey, ...parsed });
  } catch (e) {
    return res.status(502).json({ error: 'portal_fetch_failed', detail: String(e && e.message) });
  }
}

// SEFAZ-PR's DANFE page (dfews) is served as ISO-8859-1 with NO charset in the
// HTTP header, but fetch().text() always assumes UTF-8 — so accented descriptions
// (PÃO, AÇÚCAR) come back as mojibake. Decode like a browser: HTTP charset wins,
// else the HTML <meta> charset, else UTF-8. Bad label -> UTF-8 (never throw).
export function decodeHtml(buf, contentType) {
  const fromHeader = /charset=([\w-]+)/i.exec(contentType || '')?.[1];
  const fromMeta = /charset=["']?([\w-]+)/i.exec(buf.toString('latin1').slice(0, 2048))?.[1];
  const label = (fromHeader || fromMeta || 'utf-8').toLowerCase();
  try {
    return new TextDecoder(label).decode(buf);
  } catch {
    return new TextDecoder('utf-8').decode(buf);
  }
}

// --- pure parser (unit-tested against fixtures/sample-consulta.html) ---
// ponytail: selectors target the STANDARD NFC-e consulta layout (#tabResult /
// span.txtTit / .RCod / .Rqtd / .RUN / .RvlUnit / .valor). Step 0 gate: verify
// against a real Paraná page and adjust selectors before trusting in production.
export function parseConsulta(html) {
  const root = parse(html);
  let rows = root.querySelectorAll('#tabResult tr');
  if (!rows.length) rows = root.querySelectorAll('tr');
  const items = rows.map(parseItemRow).filter(Boolean);
  return { header: parseHeader(root), items };
}

function textOf(el) {
  return el ? el.text.replace(/\s+/g, ' ').trim() : '';
}

function parseItemRow(row) {
  const description = textOf(row.querySelector('.txtTit2'));
  if (!description) return null; // header / spacer rows

  const gtin = extractGtin(textOf(row.querySelector('.RCod')));
  const qty = parseQty(textOf(row.querySelector('.Rqtd')));
  const unit = afterColon(textOf(row.querySelector('.RUN'))) || null;
  const unitPriceCents = parseBRL(afterColon(textOf(row.querySelector('.RvlUnit'))));
  const lineTotalCents = parseBRL(textOf(row.querySelector('.valor')));

  return { description, gtin, qty, unit, unitPriceCents, lineTotalCents };
}

function afterColon(text) {
  const i = text.lastIndexOf(':');
  return (i === -1 ? text : text.slice(i + 1)).trim();
}

// The "(Código: …)" field is the product code; treat it as a GTIN only when it
// looks like a real barcode (EAN-8/UPC-12/EAN-13/GTIN-14). "SEM GTIN" -> null.
function extractGtin(text) {
  if (!text || /SEM\s*GTIN/i.test(text)) return null;
  const digits = (text.match(/\d+/g) || []).join('');
  if (![8, 12, 13, 14].includes(digits.length)) return null;
  // Weighed/PLU items use zero-padded internal codes (e.g. 0000000010047).
  // A real GTIN keeps >= 8 significant digits after stripping leading zeros.
  if (digits.replace(/^0+/, '').length < 8) return null;
  return digits;
}

function parseQty(text) {
  const n = parseFloat(afterColon(text).replace(/\./g, '').replace(',', '.'));
  return Number.isNaN(n) ? 1 : n;
}

function parseHeader(root) {
  const text = root.text;
  const cnpj = text.match(/\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}/);
  const date = text.match(/\d{2}\/\d{2}\/\d{4}\s+\d{2}:\d{2}:\d{2}/);
  // Store name is the ".txtTopo" header; the address is the ".text" div with commas
  // (the CNPJ ".text" div has none). City = second-to-last field ("..., <city>, <UF>").
  const storeName = textOf(root.querySelector('.txtTopo')) || null;
  const address = root.querySelectorAll('.text').map(textOf).find((t) => t.includes(',') && !/CNPJ/i.test(t)) || null;
  let city = null;
  if (address) {
    const parts = address.split(',').map((s) => s.trim()).filter(Boolean);
    if (parts.length >= 2) city = parts[parts.length - 2];
  }
  return {
    cnpj: cnpj ? cnpj[0] : null,
    storeName,
    city,
    address,
    purchasedAt: date ? date[0] : null,
    totalCents: extractTotal(text),
  };
}

// The totals block has several `.totalNumb` spans (item count, subtotal,
// discount, amount due). Target "Valor a pagar" by its label; never the first span.
function extractTotal(text) {
  const pay = text.match(/Valor\s+a\s+pagar[^\d]*([\d.]+,\d{2})/i);
  if (pay) return parseBRL(pay[1]);
  const tot = text.match(/Valor\s+total[^\d]*([\d.]+,\d{2})/i);
  return tot ? parseBRL(tot[1]) : 0;
}
