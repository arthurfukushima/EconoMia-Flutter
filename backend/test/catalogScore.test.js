import { describe, it, expect } from 'vitest';
import { cheapnessScore } from '../src/lib/catalogScore.js';

describe('cheapnessScore', () => {
  it('flags the region minimum as ótimo at 0%', () => {
    expect(cheapnessScore(500, 500, 900, 4)).toEqual({ bucket: 'otimo', pct: 0 });
  });
  it('flags a mid-pack price as ok', () => {
    expect(cheapnessScore(620, 500, 900, 4)).toEqual({ bucket: 'ok', pct: 30 });
  });
  it('flags a price well above the pack as caro', () => {
    expect(cheapnessScore(700, 500, 900, 4)).toEqual({ bucket: 'caro', pct: 50 });
  });
  it('flags the region maximum as caro at 100%', () => {
    expect(cheapnessScore(900, 500, 900, 4)).toEqual({ bucket: 'caro', pct: 100 });
  });
  it('is unico when fewer than 2 stores carry the product', () => {
    expect(cheapnessScore(500, 500, 500, 1)).toEqual({ bucket: 'unico', pct: null });
  });
  it('is unico when every store observed the same price (no spread to score against)', () => {
    expect(cheapnessScore(500, 500, 500, 3)).toEqual({ bucket: 'unico', pct: null });
  });
});
