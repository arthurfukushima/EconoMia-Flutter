import { describe, it, expect } from 'vitest';
import { cacheKeyFor, localBucket } from '../api/lib/pricecache.js';

describe('cacheKeyFor', () => {
  it('prefers the gtin when present', () => {
    expect(cacheKeyFor('7896278143531', 'ALCATRA BOV')).toBe('7896278143531');
  });
  it('falls back to the normalized term', () => {
    expect(cacheKeyFor(null, 'Alcatra Bovina')).toBe('ALCATRA BOVINA');
  });
});

describe('localBucket', () => {
  it('rounds to ~1km so near-identical coords share a cache entry', () => {
    expect(localBucket('-23.2911,-51.1731')).toBe('-23.29,-51.17');
    expect(localBucket('-23.2934,-51.1719')).toBe('-23.29,-51.17');
  });
  it('differs once coords are genuinely far apart', () => {
    expect(localBucket('-23.29,-51.17')).not.toBe(localBucket('-25.43,-49.27'));
  });
});
