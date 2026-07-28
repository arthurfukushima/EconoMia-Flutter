// Shared Neon connection-string resolution — server-only (api/ isn't bundled by Vite).
import { readFileSync } from 'fs';

export function databaseUrl() {
  if (process.env.DATABASE_URL) return process.env.DATABASE_URL;
  if (process.env.VITEST) return null; // tests stay hermetic — no live DB, no network
  try {
    const env = readFileSync(new URL('../../.env.local', import.meta.url), 'utf8');
    return env.match(/^DATABASE_URL=(.*)$/m)?.[1]?.trim().replace(/^"|"$/g, '') ?? null;
  } catch {
    return null;
  }
}
