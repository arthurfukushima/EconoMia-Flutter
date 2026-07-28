import { describe, it, expect } from 'vitest';
import { parseBRL, formatBRL } from '../src/lib/money.js';

describe('parseBRL', () => {
  it('parses R$ with thousands + decimal comma', () => {
    expect(parseBRL('R$ 1.234,56')).toBe(123456);
    expect(parseBRL('3,50')).toBe(350);
    expect(parseBRL('R$ 0,99')).toBe(99);
    expect(parseBRL('&nbsp;&nbsp;5,00')).toBe(500);
  });
  it('returns 0 for junk', () => {
    expect(parseBRL(null)).toBe(0);
    expect(parseBRL('—')).toBe(0);
  });
});

describe('formatBRL', () => {
  it('formats cents', () => {
    expect(formatBRL(123456)).toBe('R$ 1.234,56');
    expect(formatBRL(99)).toBe('R$ 0,99');
    expect(formatBRL(500)).toBe('R$ 5,00');
    expect(formatBRL(-500)).toBe('-R$ 5,00');
  });
});

describe('round-trip', () => {
  it('parseBRL(formatBRL(c)) === c', () => {
    for (const c of [0, 99, 350, 123456, 100000, 1000000]) {
      expect(parseBRL(formatBRL(c))).toBe(c);
    }
  });
});
