import { describe, it, expect } from 'vitest';
import {
  singular, parseSize, sizesOverlap, significantTokens, headToken,
  hasClassBlock, hasNewVariant, scoreOffer, productSignature,
} from '../src/lib/match.js';

describe('singular — pt-BR plural heuristic', () => {
  it('handles the plural shapes seen in shopping-list items', () => {
    expect(singular('LEITES')).toBe('LEITE');
    expect(singular('PAES')).toBe('PAO');
    expect(singular('LARANJAS')).toBe('LARANJA');
    expect(singular('MANTEIGAS')).toBe('MANTEIGA');
    expect(singular('OVOS')).toBe('OVO');
    expect(singular('PAPEIS')).toBe('PAPEL');
  });
  it('leaves short/non-plural tokens alone', () => {
    expect(singular('GAS')).toBe('GAS'); // len <= 3, never touched
    expect(singular('LEITE')).toBe('LEITE');
  });
});

describe('parseSize — size extraction and equivalence', () => {
  it('treats 2L and 2000ML as the same size', () => {
    expect(sizesOverlap(parseSize('Coca Cola 2L'), parseSize('Refrigerante 2000ml'))).toBe(true);
  });
  it('treats 1KG and 1000G as the same size', () => {
    expect(sizesOverlap(parseSize('Arroz 1kg'), parseSize('Arroz Tipo 1 1000g'))).toBe(true);
  });
  it('a multipack contributes the per-unit size, not the total', () => {
    const sizes = parseSize('Refrigerante Lata 6X350ML');
    expect(sizes).toEqual([{ unit: 'ML', value: 350 }]);
  });
  it('disagrees on an explicitly different size', () => {
    expect(sizesOverlap(parseSize('Coca Cola 2L'), parseSize('Coca Cola 350ML'))).toBe(false);
  });
  it('is not a constraint when one side names no size', () => {
    expect(sizesOverlap(parseSize('Coca Cola 2L'), parseSize('Coca Cola'))).toBe(true);
    expect(parseSize('Coca Cola')).toBeNull();
  });
});

describe('significantTokens — singularized, size/generic-stripped identity set', () => {
  it('strips merged size tokens and generic packaging words', () => {
    expect(significantTokens('Coca Cola 2L')).toEqual(['COCA', 'COLA']);
    expect(significantTokens('Arroz 1kg Pacote')).toEqual(['ARROZ', 'PACOTE']);
  });
  it('singularizes so a plural query lands on the same tokens as a singular offer', () => {
    expect(significantTokens('3 Leites')).toEqual(['LEITE']);
    expect(significantTokens('Leite Integral 1L')).toEqual(['LEITE', 'INTEGRAL']);
  });
});

describe('hasClassBlock — product-class noise', () => {
  it('flags an empty returnable bottle as a different product class', () => {
    expect(hasClassBlock('VASILHAME COCA COLA RETORNAVEL 1L 2L')).toBe(true);
  });
  it('does not flag the regular product', () => {
    expect(hasClassBlock('COCA COLA 2L')).toBe(false);
  });
});

describe('hasNewVariant — tiering', () => {
  it('flags a formulation the query did not ask for', () => {
    expect(hasNewVariant('Coca Cola 2L', 'Coca Cola Zero 2L')).toBe(true);
    expect(hasNewVariant('Leite', 'Leite Desnatado Tirol')).toBe(true);
  });
  it('does not flag the literal product, or a variant the query itself named', () => {
    expect(hasNewVariant('Coca Cola 2L', 'Coca Cola 2L')).toBe(false);
    expect(hasNewVariant('Coca Cola Zero 2L', 'Coca Cola Zero 2L')).toBe(false);
  });
});

describe('scoreOffer — soft ranking among survivors', () => {
  it('rewards head-noun and token agreement, penalizes unrelated extra tokens', () => {
    const exact = scoreOffer('Coca Cola 2L', 'Coca Cola 2L');
    const noisier = scoreOffer('Coca Cola 2L', 'Refrigerante Coca Cola Sabor Original 2L');
    expect(exact).toBeGreaterThan(noisier);
  });
});

describe('productSignature — dedupe key resilient to store-text formatting', () => {
  it('collapses differently-formatted text for the same product/size', () => {
    expect(productSignature('COCA COLA ZERO 2L')).toBe(productSignature('COCA-COLA ZERO 2 LITROS'));
  });
  it('keeps a real variant on a distinct signature from the base product', () => {
    expect(productSignature('COCA COLA 2L')).not.toBe(productSignature('COCA COLA ZERO 2L'));
  });
});
