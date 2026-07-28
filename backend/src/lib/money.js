// Brazilian currency <-> integer cents. No floats leak into savings math.

// "R$ 1.234,56" -> 123456
export function parseBRL(str) {
  if (str == null) return 0;
  const cleaned = String(str)
    .replace(/[^\d,.-]/g, '') // strip "R$", NBSP, letters
    .replace(/\./g, '')       // thousands separator
    .replace(',', '.');       // decimal comma -> dot
  const value = parseFloat(cleaned);
  return Number.isNaN(value) ? 0 : Math.round(value * 100);
}

// "3.19" or 3.19 (dot-decimal reais, as Menor Preço/VTEX return) -> 319 cents.
// Distinct from parseBRL, which expects Brazilian "R$ 1.234,56" (comma decimal).
export function reaisToCents(v) {
  const n = typeof v === 'number' ? v : parseFloat(String(v).replace(',', '.'));
  return Number.isNaN(n) ? 0 : Math.round(n * 100);
}

// 123456 -> "R$ 1.234,56"  (manual grouping, no ICU dependency)
export function formatBRL(cents) {
  const n = Math.round(cents || 0);
  const sign = n < 0 ? '-' : '';
  const abs = Math.abs(n);
  const reais = String(Math.floor(abs / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  const cent = String(abs % 100).padStart(2, '0');
  return `${sign}R$ ${reais},${cent}`;
}
