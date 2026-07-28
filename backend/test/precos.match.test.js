import { describe, it, expect } from 'vitest';
import { analyzeItem, recoverGtin, distinctiveStoreTokens, g14, candidatesFor } from '../api/precos.js';
import { productSignature } from '../src/lib/match.js';

const STORE = distinctiveStoreTokens('IRMAOS MUFFATO E CIA LTDA'); // -> ['MUFFATO']
const CITY = 'LONDRINA';
const est = (nm_fan, cod, extra = {}) => ({ nm_emp: extra.nm_emp || nm_fan, nm_fan, mun: extra.mun || 'LONDRINA', codigo: cod });

describe('store token extraction', () => {
  it('reduces razão social to the distinctive name', () => {
    expect(STORE).toEqual(['MUFFATO']);
  });
});

describe('recoverGtin — same-store, exact description', () => {
  const produtos = [
    { desc: 'RODO PRAT CSA UN', gtin: '7896278143531', valor: '25.90', estabelecimento: est('SUPER MUFFATO', 'm1', { nm_emp: 'IRMAOS MUFFATO E CIA LTDA' }) },
  ];
  it('recovers the GTIN when the same store has the exact description', () => {
    expect(recoverGtin('RODO PRAT CSA UN', produtos, STORE, CITY)).toBe(g14('7896278143531'));
  });
  it('returns null when only a different store matches the description', () => {
    const other = [{ ...produtos[0], estabelecimento: est('MERCADO X', 'x1', { nm_emp: 'MERCADO X LTDA' }) }];
    expect(recoverGtin('RODO PRAT CSA UN', other, STORE, CITY)).toBeNull();
  });
});

describe('guardrail: outlier trimming on GTIN offers', () => {
  const g = '7896278143531';
  const produtos = [
    { desc: 'RODO PRAT CSA UN', gtin: g, valor: '25.90', estabelecimento: est('SUPER MUFFATO', 'm1', { nm_emp: 'IRMAOS MUFFATO E CIA LTDA' }) },
    { desc: 'RODO PRATICO', gtin: g, valor: '24.90', estabelecimento: est('MERCADO X', 'x1') },
    { desc: 'RODO', gtin: g, valor: '26.50', estabelecimento: est('MERCADO Y', 'y1') },
    { desc: 'RODO PRAT', gtin: g, valor: '8.90', estabelecimento: est('MERCADO Z', 'z1') }, // bad data
    { desc: 'RODO PRAT CSA', gtin: g, valor: '25.90', estabelecimento: est('MERCADO W', 'w1') },
  ];
  it('drops the sub-median outlier and returns the real cheapest', async () => {
    const r = await analyzeItem({ description: 'RODO PRAT CSA UN', unit: 'Un' }, produtos, STORE, CITY);
    expect(r.basis).toBe('gtin');
    expect(r.cheapest.priceCents).toBe(2490); // 890 rejected, not 890
    expect(r.nStores).toBe(4);
  });

  it('forwards a per-store list (best price per store) to the client', async () => {
    const r = await analyzeItem({ description: 'RODO PRAT CSA UN', unit: 'Un' }, produtos, STORE, CITY);
    expect(Array.isArray(r.stores)).toBe(true);
    expect(r.stores).toHaveLength(4);                        // outlier store dropped
    expect(r.stores.every((s) => s.cod && s.priceCents > 0)).toBe(true);
    expect(new Set(r.stores.map((s) => s.cod)).size).toBe(4); // one entry per store
  });
});

describe('NCM surfacing (deterministic category signal)', () => {
  it('returns the NCM most matched offers agree on', async () => {
    const produtos = [
      { desc: 'ALCATRA BOV KG', gtin: '', valor: '39.90', ncm: '02013000', estabelecimento: est('MERCADO A', 'a') },
      { desc: 'ALCATRA BOV KG', gtin: '', valor: '41.90', ncm: '02013000', estabelecimento: est('MERCADO B', 'b') },
      { desc: 'ALCATRA BOV KG', gtin: '', valor: '38.90', ncm: '99999999', estabelecimento: est('MERCADO C', 'c') }, // mislabeled, outvoted
    ];
    const r = await analyzeItem({ description: 'ALCATRA BOV KG', unit: 'Kg' }, produtos, STORE, CITY);
    expect(r.ncm).toBe('02013000');
  });
  it('is null when offers carry no NCM', async () => {
    const produtos = [{ desc: 'ALCATRA BOV KG', gtin: '', valor: '39.90', estabelecimento: est('MERCADO A', 'a') }];
    expect((await analyzeItem({ description: 'ALCATRA BOV KG', unit: 'Kg' }, produtos, STORE, CITY)).ncm).toBeNull();
  });
});

describe('lenient basis: a freeform term with no unit matches per-KG and per-UN', () => {
  const produtos = [
    { desc: 'TOMATE KG', gtin: '', valor: '2.50', estabelecimento: est('MERCADO A', 'a') },        // cheapest, per-kilo
    { desc: 'TOMATE ITALIANO UN', gtin: '', valor: '5.99', estabelecimento: est('MERCADO B', 'b') },
    { desc: 'TOMATE LONGA VIDA KG', gtin: '', valor: '4.49', estabelecimento: est('MERCADO C', 'c') },
  ];
  it('includes KG offers when the item carries no unit (would be excluded before)', async () => {
    const r = await analyzeItem({ description: 'TOMATE', unit: '' }, produtos, STORE, CITY);
    expect(r.basis).toBe('desc');
    expect(r.cheapest.priceCents).toBe(250); // the per-KG offer, not the 599 per-UN one
    expect(r.nStores).toBe(3);
  });
});

describe('options: a vague term groups into pickable distinct products', () => {
  const produtos = [
    { desc: 'CARNE MOIDA BOVINA KG', gtin: '', valor: '19.90', estabelecimento: est('MERCADO A', 'a') },
    { desc: 'CARNE MOIDA BOVINA KG', gtin: '', valor: '21.90', estabelecimento: est('MERCADO B', 'b') },
    { desc: 'CARNE MOIDA BOVINA KG', gtin: '', valor: '18.90', estabelecimento: est('MERCADO C', 'c') },
    { desc: 'CARNE SECA KG', gtin: '', valor: '45.00', estabelecimento: est('MERCADO D', 'd') },
  ];
  it('returns distinct products, most-common first, each with its own cheapest/stores', async () => {
    const r = await analyzeItem({ description: 'CARNE', unit: '' }, produtos, STORE, CITY);
    expect(r.options).toHaveLength(2);
    expect(r.options[0].name).toBe('CARNE MOIDA BOVINA KG'); // 3 offers → most common
    expect(r.options[0].cheapest.priceCents).toBe(1890);
    expect(r.options[0].nStores).toBe(3);
    expect(r.options[1].name).toBe('CARNE SECA KG');
    expect(r.options[1].cheapest.priceCents).toBe(4500);
  });
  it('omits options when a single product matched (nothing to pick)', async () => {
    const one = produtos.filter((p) => p.desc === 'CARNE SECA KG');
    expect((await analyzeItem({ description: 'CARNE SECA', unit: '' }, one, STORE, CITY)).options).toEqual([]);
  });
});

describe('guardrail: canonical match must not cross species (real bug found in prod testing)', () => {
  // Real Menor Preço data surfaced this: "Coxão Mole" is a cut name reused for both
  // beef and pork. The canonical alias tokens are just ['COXAO','MOLE'] (species-
  // agnostic), so without the species guard a pork offer wins the "cheapest" beef slot.
  const produtos = [
    { desc: 'COXAO MOLE KG', gtin: '', valor: '52.90', ncm: '02013000', estabelecimento: est('CASA DE CARNES', 'a') },
    { desc: 'COXAO MOLE BDJ KG', gtin: '', valor: '51.90', ncm: '02013000', estabelecimento: est('BAZA', 'b') },
    { desc: 'COXAO MOLE SUINO KG', gtin: '', valor: '32.97', ncm: '02031900', estabelecimento: est('SUPER MUFFATO', 'c') }, // pork — cheaper, must be excluded
  ];
  const canonical = { name: 'Coxão Mole', unit_basis: 'KG', tokens: ['COXAO', 'MOLE'] };

  it('excludes the pork offer when the item names a species (beef)', () => {
    const item = { description: 'COXAO MOLE BOI KG', unit: 'Kg' };
    const cands = candidatesFor(item, produtos, null, canonical);
    expect(cands).toHaveLength(2);
    expect(cands.every((p) => p.desc !== 'COXAO MOLE SUINO KG')).toBe(true);
  });

  it('leaves all offers in when the item names no species (genuinely ambiguous)', () => {
    const item = { description: 'COXAO MOLE KG', unit: 'Kg' };
    const cands = candidatesFor(item, produtos, null, canonical);
    expect(cands).toHaveLength(3); // can't disambiguate what we aren't told
  });
});

describe('guardrail: produce UN vs KG unit-basis', () => {
  const produtos = [
    { desc: 'MAMAO PAPAYA UN', gtin: '', valor: '3.99', estabelecimento: est('MERCADO A', 'a') },
    { desc: 'MAMAO PAPAYA KG', gtin: '', valor: '1.99', estabelecimento: est('MERCADO B', 'b') }, // per-kilo, must be excluded
    { desc: 'MAMAO PAPAYA UN', gtin: '', valor: '2.99', estabelecimento: est('MERCADO C', 'c') },
    { desc: 'MAMAO FORMOSA UN', gtin: '', valor: '2.50', estabelecimento: est('MERCADO D', 'd') }, // different variety
  ];
  it('never compares a per-unit item against a per-kilo price', async () => {
    const r = await analyzeItem({ description: 'MAMAO PAPAYA UN', unit: 'Un' }, produtos, STORE, CITY);
    expect(r.basis).toBe('desc');
    expect(r.cheapest.priceCents).toBe(299); // not 199 (KG) and not 250 (Formosa)
  });
});

describe('regression: plural query lands on the singular offer ("3 Leites")', () => {
  const produtos = [
    { desc: 'LEITE INTEGRAL ITALAC 1L', gtin: '', valor: '4.99', ncm: '04012010', estabelecimento: est('MERCADO A', 'a') },
    { desc: 'DOCE LEITE ROSS 60G', gtin: '', valor: '0.99', ncm: '17049020', estabelecimento: est('MERCADO B', 'b') },
  ];
  it('matches the plural "Leites" against the singular offer (used to return zero candidates)', () => {
    const cands = candidatesFor({ description: 'Leites', unit: '' }, produtos, null, null);
    expect(cands).toHaveLength(1);
    expect(cands[0].desc).toBe('LEITE INTEGRAL ITALAC 1L');
  });
  it('prices the item once matched', async () => {
    const r = await analyzeItem({ description: 'Leites', unit: '' }, produtos, STORE, CITY);
    expect(r.cheapest.priceCents).toBe(499);
  });
});

describe('regression: size/product-class guards on a packaged query ("Coca Cola 2L")', () => {
  const produtos = [
    { desc: 'REFRIG COCA COLA 2L', gtin: '', valor: '6.89', ncm: '22021000', estabelecimento: est('MERCADO A', 'a') },
    { desc: 'VASILHAME COCA COLA RETORNAVEL 1L 2L', gtin: '', valor: '4.00', ncm: '22021000', estabelecimento: est('MERCADO B', 'b') }, // empty bottle, not the drink
    { desc: 'COCA COLA 350ML', gtin: '', valor: '3.49', ncm: '22021000', estabelecimento: est('MERCADO C', 'c') }, // wrong size
    { desc: 'COCA COLA ZERO 2L', gtin: '', valor: '6.99', ncm: '22021000', estabelecimento: est('MERCADO D', 'd') },
    { desc: 'COCA COLA ZERO 2L', gtin: '', valor: '6.99', ncm: '22021000', estabelecimento: est('MERCADO E', 'e') },
    { desc: 'COCA-COLA ZERO 2 LITROS', gtin: '', valor: '7.00', ncm: '22021000', estabelecimento: est('MERCADO F', 'f') }, // same product, different store text
  ];
  const item = { description: 'Coca Cola 2L', unit: '' };

  it('excludes the empty returnable bottle and the wrong-size can', () => {
    const cands = candidatesFor(item, produtos, null, null);
    expect(cands).toHaveLength(4); // REFRIG + 3x ZERO — vasilhame and 350ml dropped
    expect(cands.some((p) => p.desc.includes('VASILHAME'))).toBe(false);
    expect(cands.some((p) => p.desc === 'COCA COLA 350ML')).toBe(false);
  });

  it('ranks the literal product first and collapses the three Zero offers into one variant option', async () => {
    const r = await analyzeItem(item, produtos, STORE, CITY);
    expect(r.cheapest.priceCents).toBe(689); // the plain product, not a Zero offer or the vasilhame
    expect(r.options).toHaveLength(2);
    expect(r.options[0].tier).toBe(1);
    expect(r.options[0].name).toBe('REFRIG COCA COLA 2L');
    expect(r.options[1].tier).toBe(2);
    expect(r.options[1].nStores).toBe(3); // 3 differently-formatted "Zero" offers, one option
  });
});

describe('regression: NCM-category disagreement separates a product from its derivative ("Leite" vs "Doce de Leite")', () => {
  it('excludes the candy when NCM chapters disagree', async () => {
    const produtos = [
      { desc: 'LEITE INTEGRAL ITALAC 1L', gtin: '', valor: '4.99', ncm: '04012010', estabelecimento: est('MERCADO A', 'a') },
      { desc: 'DOCE LEITE ROSS 60G', gtin: '', valor: '0.99', ncm: '17049020', estabelecimento: est('MERCADO B', 'b') },
    ];
    const r = await analyzeItem({ description: 'Leite', unit: '' }, produtos, STORE, CITY);
    expect(r.cheapest.priceCents).toBe(499); // not the 99-cent candy
  });
  it('still excludes it with no NCM on either offer (keyword fallback: "DOCE" is its own category)', async () => {
    const produtos = [
      { desc: 'LEITE INTEGRAL ITALAC 1L', gtin: '', valor: '4.99', estabelecimento: est('MERCADO A', 'a') },
      { desc: 'DOCE LEITE ROSS 60G', gtin: '', valor: '0.99', estabelecimento: est('MERCADO B', 'b') },
    ];
    const r = await analyzeItem({ description: 'Leite', unit: '' }, produtos, STORE, CITY);
    expect(r.cheapest.priceCents).toBe(499);
  });
});

describe('productSignature dedupe key used by buildOptions', () => {
  it('groups differently-formatted store text for the same product/size', () => {
    expect(productSignature('COCA COLA ZERO 2L')).toBe(productSignature('COCA-COLA ZERO 2 LITROS'));
  });
});
