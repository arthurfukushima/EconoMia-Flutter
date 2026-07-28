// Applies db/schema.sql to Neon. Run: node db/migrate.mjs
import { neon } from '@neondatabase/serverless';
import { readFileSync } from 'fs';

const env = readFileSync(new URL('../.env.local', import.meta.url), 'utf8');
const url = env.match(/^DATABASE_URL=(.*)$/m)[1].trim().replace(/^"|"$/g, '');
const sql = neon(url);

const schema = readFileSync(new URL('./schema.sql', import.meta.url), 'utf8');
const statements = schema
  .split(';')
  .map((s) => s.trim())
  .filter(Boolean);

for (const stmt of statements) {
  await sql.query(stmt);
  console.log('OK:', stmt.split('\n')[0].slice(0, 60));
}
console.log(`Applied ${statements.length} statements.`);
