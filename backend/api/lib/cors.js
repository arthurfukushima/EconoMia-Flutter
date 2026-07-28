// Flutter Web runs on a different origin than this backend, so every response
// needs these headers or the browser blocks reading it even when the request
// already succeeded server-side (a POST with a JSON body also triggers a
// preflight OPTIONS the browser sends before the real request). `*` is fine —
// every endpoint here is public, read-only-by-design, no cookies/auth.
export function applyCors(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return true; // handled; caller returns immediately
  }
  return false;
}
