import { describe, it, expect } from 'vitest';
import { selectCheapest, g14 } from '../api/precos.js';

// Barcode-scan path: the GTIN is passed straight in (no description recovery).
const est = (nm_fan, cod) => ({ nm_emp: nm_fan, nm_fan, mun: 'LONDRINA', codigo: cod });
const item = { description: '', unit: '' };

describe('selectCheapest — scanned GTIN path', () => {
  const g = '7894900700015';
  const produtos = [
    { desc: 'REF COCA COLA 350ML', gtin: g, valor: '3.49', estabelecimento: est('MERCADO A', 'a') },
    { desc: 'COCA COLA LATA 350 ML', gtin: g, valor: '4.99', estabelecimento: est('MERCADO B', 'b') },
    { desc: 'REF COCA COLA 350ML', gtin: g, valor: '3.99', estabelecimento: est('MERCADO C', 'c') },
  ];

  it('returns the price range, modal name and cheapest for the matched barcode', () => {
    const r = selectCheapest(item, produtos, g14(g));
    expect(r.cheapest.priceCents).toBe(349);
    expect(r.range).toEqual({ minCents: 349, maxCents: 499 });
    expect(r.name).toBe('REF COCA COLA 350ML'); // modal desc (2 of 3 offers)
    expect(r.nStores).toBe(3);
  });

  // No true majority (1 offer each) used to fall to whichever description happened
  // to iterate first — arbitrary, and in practice often the terser/truncated one.
  // Same GTIN, different store text, tie broken toward the more specific description.
  it('breaks a description tie toward the longer, more specific text', () => {
    const g2 = '7896045506040';
    const tied = [
      { desc: 'CERVEJA HEINEKEN LON', gtin: g2, valor: '6.49', estabelecimento: est('ALMEIDA', 'a') },
      { desc: 'CERVEJA HEINEKEN LONG ZERO 330ML', gtin: g2, valor: '7.99', estabelecimento: est('NOSTRO', 'b') },
    ];
    const r = selectCheapest(item, tied, g14(g2));
    expect(r.name).toBe('CERVEJA HEINEKEN LONG ZERO 330ML');
  });

  // THE TRAP: a barcode with no offers makes Menor Preço return the baseline area
  // list (unrelated products), NOT empty. Filtering to g14(p.gtin)===gtin must yield
  // nothing rather than leak a wrong product's price.
  it('returns empty (not garbage) when nothing matches the barcode', () => {
    const garbage = [
      { desc: 'CHICLETE AVULSO', gtin: '', valor: '0.50', estabelecimento: est('X', 'x') },
      { desc: 'PARAFUSOS DIVERSOS', gtin: '7891111111111', valor: '2.00', estabelecimento: est('Y', 'y') },
    ];
    const r = selectCheapest(item, garbage, g14('7894900700015'));
    expect(r.cheapest).toBeNull();
    expect(r.stores).toEqual([]);
    expect(r.range).toBeNull();
    expect(r.nOffers).toBe(0);
  });
});
