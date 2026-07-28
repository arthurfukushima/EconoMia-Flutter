// Resolve a Brazilian CEP to coordinates for the "nearby" search center.
// AwesomeAPI has the richest data but rate-limits Vercel's shared serverless IP
// (429), so Nominatim (OSM) is the fallback for coords. City-level precision is
// plenty for a radius search; the returned city is cosmetic (not used for pricing).
// ponytail: Nominatim asks 1 req/s — fine at MVP volume (one call per CEP,
// client-cached). Move to a keyed geocoder (or an AwesomeAPI token) at scale.
import { applyCors } from './lib/cors.js';

async function fromAwesome(cep) {
  const r = await fetch(`https://cep.awesomeapi.com.br/json/${cep}`, { headers: { 'User-Agent': 'EconoMia' } });
  if (!r.ok) return null;
  const d = await r.json();
  if (!d.lat || !d.lng) return null;
  return { cep, lat: Number(d.lat), lng: Number(d.lng), city: d.city || null, state: d.state || null };
}

async function fromNominatim(cep) {
  const masked = `${cep.slice(0, 5)}-${cep.slice(5)}`;
  const url = `https://nominatim.openstreetmap.org/search?postalcode=${masked}&country=Brazil&format=json&addressdetails=1&limit=1`;
  const r = await fetch(url, { headers: { 'User-Agent': 'EconoMia/1.0 (price-compare PWA)' } });
  if (!r.ok) return null;
  const hit = (await r.json())[0];
  if (!hit || !hit.lat || !hit.lon) return null;
  const a = hit.address || {};
  return { cep, lat: Number(hit.lat), lng: Number(hit.lon), city: a.city || a.town || a.village || a.municipality || null, state: a.state || null };
}

export default async function handler(req, res) {
  if (applyCors(req, res)) return;
  const cep = String((req.query && req.query.cep) || '').replace(/\D/g, '');
  if (cep.length !== 8) return res.status(400).json({ error: 'invalid_cep' });
  try {
    const loc = (await fromAwesome(cep).catch(() => null)) || (await fromNominatim(cep).catch(() => null));
    if (!loc) return res.status(404).json({ error: 'cep_no_coords' });
    return res.status(200).json(loc);
  } catch (e) {
    return res.status(502).json({ error: 'cep_failed', detail: String(e && e.message) });
  }
}
