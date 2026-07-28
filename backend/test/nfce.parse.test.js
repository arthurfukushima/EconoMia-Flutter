import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { parseConsulta, decodeHtml } from '../api/nfce.js';

// A REAL SEFAZ-PR consulta page (Muffato / Londrina, 2026-07-11), captured in Step 0.
const html = readFileSync(new URL('./sample-consulta.html', import.meta.url), 'utf8');
const { header, items } = parseConsulta(html);

describe('parseConsulta items', () => {
  it('parses every line item', () => {
    expect(items).toHaveLength(23);
    expect(items[0]).toMatchObject({
      description: 'MOTI MARUYA COL 280G',
      qty: 1,
      unit: 'Un',
      unitPriceCents: 2498,
      lineTotalCents: 2498,
    });
  });

  it('parses fractional weight items (produce)', () => {
    const manga = items.find((i) => i.description.startsWith('MANGA'));
    expect(manga).toMatchObject({ unit: 'Kg', qty: 0.61, lineTotalCents: 670 });
  });

  // Step-0 finding: the QR consulta page exposes only internal cProd codes,
  // never GTIN/EAN — so GTIN matching gets nothing from this source.
  it('exposes NO gtins (only internal product codes)', () => {
    expect(items.every((i) => i.gtin === null)).toBe(true);
  });
});

// Some retailers (e.g. Santarém/Londrina) DO print real EAN-13 in the Código
// field for packaged goods, while weighed items keep a zero-padded PLU code.
describe('gtin extraction distinguishes real EAN from padded PLU', () => {
  const mini = `<table id="tabResult">
    <tr><td><span class="txtTit2">CR LEITE TIROL 200G</span><span class="RCod">(Código: 7896256600780)</span>
      <span class="Rqtd"><strong>Qtde.:</strong>2</span><span class="RUN"><strong>UN: </strong>Un</span>
      <span class="RvlUnit"><strong>Vl. Unit.:</strong> 2,79</span></td>
      <td class="txtTit3"><span class="valor">5,58</span></td></tr>
    <tr><td><span class="txtTit2">BOV COXAO MOLE KG</span><span class="RCod">(Código: 0000000010047)</span>
      <span class="Rqtd"><strong>Qtde.:</strong>0,616</span><span class="RUN"><strong>UN: </strong>Kg</span>
      <span class="RvlUnit"><strong>Vl. Unit.:</strong> 48,99</span></td>
      <td class="txtTit3"><span class="valor">30,18</span></td></tr>
  </table>`;
  const parsed = parseConsulta(mini);

  it('keeps a real EAN-13, rejects a zero-padded internal code', () => {
    expect(parsed.items[0].gtin).toBe('7896256600780');
    expect(parsed.items[1].gtin).toBe(null);
  });
});

// Production regression: dfews serves ISO-8859-1 with no charset in the HTTP
// header. Feeding those raw bytes to fetch().text() (UTF-8) scrambles accents.
describe('decodeHtml honors the declared charset', () => {
  const src = '<meta content="text/html; charset=ISO-8859-1"><span class="txtTit2">PÃO FRANCÊS AÇÚCAR MAMÃO</span>';
  it('decodes ISO-8859-1 body (no HTTP charset) without mojibake', () => {
    expect(decodeHtml(Buffer.from(src, 'latin1'), 'text/html')).toContain('PÃO FRANCÊS AÇÚCAR MAMÃO');
  });
  it('still respects a UTF-8 HTTP charset when the server sends one', () => {
    expect(decodeHtml(Buffer.from(src, 'utf8'), 'text/html; charset=UTF-8')).toContain('PÃO FRANCÊS AÇÚCAR MAMÃO');
  });
});

describe('parseConsulta header', () => {
  it('extracts cnpj, amount due (not item count), and date', () => {
    expect(header.cnpj).toBe('76.430.438/0029-72');
    expect(header.totalCents).toBe(26651); // "Valor a pagar R$: 266,51"
    expect(header.purchasedAt).toBe('11/07/2026 11:15:22');
  });

  it('extracts store name and city (needed to resolve the Menor Preço store)', () => {
    expect(header.storeName).toBe('IRMAOS MUFFATO E CIA LTDA');
    expect(header.city).toBe('Londrina');
  });
});
