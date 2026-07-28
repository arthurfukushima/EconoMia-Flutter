import { describe, it, expect } from 'vitest';
import { classify, catInfo } from '../src/lib/categoria.js';

describe('classify (keyword, NCM-ready)', () => {
  it('buckets real receipt descriptions by their head noun', () => {
    expect(classify('BANANA NANICA KG')).toBe('frutas');
    expect(classify('ALCATRA BOV KG')).toBe('carnes');
    expect(classify('FILE DE PEITO FGO')).toBe('carnes');
    expect(classify('LEITE INTEG PIRACANJUBA 1L')).toBe('laticinios');
    expect(classify('PAO FRANCES KG')).toBe('padaria');
    expect(classify('REFRIG COCA COLA 2L')).toBe('bebidas');
    expect(classify('CHOCOLATE NESTLE 90G')).toBe('doces');
    expect(classify('DETERGENTE YPE NEUTRO 500ML')).toBe('limpeza');
  });

  it('splits fruit from veg and keeps sweet potato a vegetable', () => {
    expect(classify('TOMATES ITALIANO KG')).toBe('verduras'); // plural strip, veg
    expect(classify('BATATA DOCE KG')).toBe('verduras');      // head noun BATATA wins over DOCE
    expect(classify('MACARRAO GALO 500G')).toBe('outros');    // MACARRAO !== MACA
    expect(classify('PARAFUSO SEXTAVADO')).toBe('outros');
  });

  it('lets a fiscal NCM override the keyword guess (dormant until data carries it)', () => {
    expect(classify({ description: 'PRODUTO GENERICO', ncm: '02013000' })).toBe('carnes');
    expect(classify({ description: 'PRODUTO GENERICO', ncm: '0701' })).toBe('verduras'); // ch 07 → veg
    expect(classify({ description: 'PRODUTO GENERICO', ncm: '0803' })).toBe('frutas');   // ch 08 → fruit
    expect(classify({ description: 'PRODUTO GENERICO', ncm: '1806' })).toBe('doces');    // ch 18 → cocoa/choc
    expect(classify({ description: 'DETERGENTE YPE', ncm: '' })).toBe('limpeza'); // empty NCM → keyword
  });

  it('catInfo always resolves to an emoji + label', () => {
    expect(catInfo('carnes')).toMatchObject({ emoji: '🥩', label: 'Carnes' });
    expect(catInfo('naoexiste')).toMatchObject({ label: 'Outros' });
  });
});
