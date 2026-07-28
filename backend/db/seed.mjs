// Hand-curated first-pass canonical products: meat + produce only (see schema.sql).
// Idempotent — safe to re-run (ON CONFLICT DO NOTHING on the unique keys).
// Run: node db/seed.mjs
import { neon } from '@neondatabase/serverless';
import { readFileSync } from 'fs';
import { norm } from '../src/lib/text.js';

const env = readFileSync(new URL('../.env.local', import.meta.url), 'utf8');
const url = env.match(/^DATABASE_URL=(.*)$/m)[1].trim().replace(/^"|"$/g, '');
const sql = neon(url);

// category matches src/lib/categoria.js; unit_basis is the typical NFC-e basis for
// the whole product (first-pass — expect edge cases, e.g. morango sold by UN caixinha).
const PRODUCTS = [
  // carnes
  { category: 'carnes', name: 'Alcatra', unit_basis: 'KG', aliases: ['ALCATRA', 'ALCATRA BOV'] },
  { category: 'carnes', name: 'Patinho', unit_basis: 'KG', aliases: ['PATINHO', 'PATINHO BOV'] },
  { category: 'carnes', name: 'Acém', unit_basis: 'KG', aliases: ['ACEM', 'ACEM BOV'] },
  { category: 'carnes', name: 'Coxão Mole', unit_basis: 'KG', aliases: ['COXAO MOLE', 'COXAO'] },
  { category: 'carnes', name: 'Músculo', unit_basis: 'KG', aliases: ['MUSCULO', 'MUSCULO BOV'] },
  { category: 'carnes', name: 'Lagarto', unit_basis: 'KG', aliases: ['LAGARTO'] },
  { category: 'carnes', name: 'Filé Mignon', unit_basis: 'KG', aliases: ['FILE MIGNON', 'FILEZINHO'] },
  { category: 'carnes', name: 'Contrafilé', unit_basis: 'KG', aliases: ['CONTRAFILE', 'CONTRA FILE'] },
  { category: 'carnes', name: 'Costela Bovina', unit_basis: 'KG', aliases: ['COSTELA', 'COSTELA BOV'] },
  { category: 'carnes', name: 'Picanha', unit_basis: 'KG', aliases: ['PICANHA'] },
  { category: 'carnes', name: 'Maminha', unit_basis: 'KG', aliases: ['MAMINHA'] },
  { category: 'carnes', name: 'Fraldinha', unit_basis: 'KG', aliases: ['FRALDINHA'] },
  { category: 'carnes', name: 'Cupim', unit_basis: 'KG', aliases: ['CUPIM'] },
  { category: 'carnes', name: 'Pernil Suíno', unit_basis: 'KG', aliases: ['PERNIL'] },
  { category: 'carnes', name: 'Lombo Suíno', unit_basis: 'KG', aliases: ['LOMBO'] },
  { category: 'carnes', name: 'Panceta Suína', unit_basis: 'KG', aliases: ['PANCETA'] },
  { category: 'carnes', name: 'Carré Suíno', unit_basis: 'KG', aliases: ['CARRE'] },
  { category: 'carnes', name: 'Carne Moída', unit_basis: 'KG', aliases: ['MOIDA', 'MOIDO', 'CARNE MOIDA'] },
  { category: 'carnes', name: 'Peito de Frango', unit_basis: 'KG', aliases: ['PEITO DE FRANGO', 'PEITO FRANGO'] },
  { category: 'carnes', name: 'Coxa de Frango', unit_basis: 'KG', aliases: ['COXA FRANGO', 'COXA'] },
  { category: 'carnes', name: 'Sobrecoxa de Frango', unit_basis: 'KG', aliases: ['SOBRECOXA'] },
  { category: 'carnes', name: 'Asa de Frango', unit_basis: 'KG', aliases: ['ASA', 'ASINHA'] },
  { category: 'carnes', name: 'Frango Inteiro', unit_basis: 'KG', aliases: ['FRANGO'] },
  { category: 'carnes', name: 'Linguiça', unit_basis: 'KG', aliases: ['LINGUICA'] },
  { category: 'carnes', name: 'Salsicha', unit_basis: 'KG', aliases: ['SALSICHA'] },
  { category: 'carnes', name: 'Bacon', unit_basis: 'KG', aliases: ['BACON'] },
  { category: 'carnes', name: 'Presunto', unit_basis: 'KG', aliases: ['PRESUNTO'] },
  { category: 'carnes', name: 'Mortadela', unit_basis: 'KG', aliases: ['MORTADELA'] },
  { category: 'carnes', name: 'Salame', unit_basis: 'KG', aliases: ['SALAME'] },
  { category: 'carnes', name: 'Hambúrguer', unit_basis: 'UN', aliases: ['HAMBURGUER', 'HAMBURGER'] },
  { category: 'carnes', name: 'Almôndega', unit_basis: 'KG', aliases: ['ALMONDEGA'] },
  { category: 'carnes', name: 'Tilápia', unit_basis: 'KG', aliases: ['TILAPIA'] },
  { category: 'carnes', name: 'Salmão', unit_basis: 'KG', aliases: ['SALMAO'] },
  { category: 'carnes', name: 'Sardinha', unit_basis: 'KG', aliases: ['SARDINHA'] },
  { category: 'carnes', name: 'Merluza', unit_basis: 'KG', aliases: ['MERLUZA'] },
  { category: 'carnes', name: 'Camarão', unit_basis: 'KG', aliases: ['CAMARAO'] },
  { category: 'carnes', name: 'Atum', unit_basis: 'KG', aliases: ['ATUM'] },

  // frutas
  { category: 'frutas', name: 'Banana', unit_basis: 'KG', aliases: ['BANANA', 'BANANA NANICA', 'BANANA PRATA'] },
  { category: 'frutas', name: 'Maçã', unit_basis: 'KG', aliases: ['MACA'] },
  { category: 'frutas', name: 'Laranja', unit_basis: 'KG', aliases: ['LARANJA'] },
  { category: 'frutas', name: 'Mamão', unit_basis: 'KG', aliases: ['MAMAO'] },
  { category: 'frutas', name: 'Abacaxi', unit_basis: 'UN', aliases: ['ABACAXI'] },
  { category: 'frutas', name: 'Melancia', unit_basis: 'KG', aliases: ['MELANCIA'] },
  { category: 'frutas', name: 'Melão', unit_basis: 'KG', aliases: ['MELAO'] },
  { category: 'frutas', name: 'Uva', unit_basis: 'KG', aliases: ['UVA'] },
  { category: 'frutas', name: 'Manga', unit_basis: 'KG', aliases: ['MANGA'] },
  { category: 'frutas', name: 'Limão', unit_basis: 'KG', aliases: ['LIMAO'] },
  { category: 'frutas', name: 'Morango', unit_basis: 'KG', aliases: ['MORANGO'] },
  { category: 'frutas', name: 'Abacate', unit_basis: 'KG', aliases: ['ABACATE'] },
  { category: 'frutas', name: 'Pera', unit_basis: 'KG', aliases: ['PERA'] },

  // verduras
  { category: 'verduras', name: 'Tomate', unit_basis: 'KG', aliases: ['TOMATE'] },
  { category: 'verduras', name: 'Alface', unit_basis: 'UN', aliases: ['ALFACE'] },
  { category: 'verduras', name: 'Cebola', unit_basis: 'KG', aliases: ['CEBOLA'] },
  { category: 'verduras', name: 'Batata', unit_basis: 'KG', aliases: ['BATATA'] },
  { category: 'verduras', name: 'Cenoura', unit_basis: 'KG', aliases: ['CENOURA'] },
  { category: 'verduras', name: 'Alho', unit_basis: 'KG', aliases: ['ALHO'] },
  { category: 'verduras', name: 'Pimentão', unit_basis: 'KG', aliases: ['PIMENTAO'] },
  { category: 'verduras', name: 'Pepino', unit_basis: 'KG', aliases: ['PEPINO'] },
  { category: 'verduras', name: 'Abobrinha', unit_basis: 'KG', aliases: ['ABOBRINHA'] },
  { category: 'verduras', name: 'Abóbora', unit_basis: 'KG', aliases: ['ABOBORA'] },
  { category: 'verduras', name: 'Brócolis', unit_basis: 'UN', aliases: ['BROCOLIS', 'BROCOLI'] },
  { category: 'verduras', name: 'Couve', unit_basis: 'UN', aliases: ['COUVE'] },
  { category: 'verduras', name: 'Repolho', unit_basis: 'UN', aliases: ['REPOLHO'] },
  { category: 'verduras', name: 'Mandioca', unit_basis: 'KG', aliases: ['MANDIOCA', 'AIPIM', 'MACAXEIRA'] },
  { category: 'verduras', name: 'Beterraba', unit_basis: 'KG', aliases: ['BETERRABA'] },
  { category: 'verduras', name: 'Chuchu', unit_basis: 'KG', aliases: ['CHUCHU'] },
  { category: 'verduras', name: 'Vagem', unit_basis: 'KG', aliases: ['VAGEM'] },
  { category: 'verduras', name: 'Quiabo', unit_basis: 'KG', aliases: ['QUIABO'] },
  { category: 'verduras', name: 'Berinjela', unit_basis: 'KG', aliases: ['BERINJELA'] },
  { category: 'verduras', name: 'Milho', unit_basis: 'UN', aliases: ['MILHO'] },

  // padaria — bakery-counter items, commonly sold loose/by weight, no GTIN
  { category: 'padaria', name: 'Pão Francês', unit_basis: 'KG', aliases: ['PAO FRANCES', 'FRANCESINHA', 'PAO FCA'] },
  { category: 'padaria', name: 'Pão de Queijo', unit_basis: 'KG', aliases: ['PAO DE QUEIJO', 'PAO QUEIJO'] },
  { category: 'padaria', name: 'Rosca', unit_basis: 'UN', aliases: ['ROSCA'] },
  { category: 'padaria', name: 'Broa', unit_basis: 'UN', aliases: ['BROA'] },
  { category: 'padaria', name: 'Cuca', unit_basis: 'UN', aliases: ['CUCA'] },
  { category: 'padaria', name: 'Sonho', unit_basis: 'UN', aliases: ['SONHO'] },
  { category: 'padaria', name: 'Pão Sovado', unit_basis: 'UN', aliases: ['SOVADO', 'PAO SOVADO'] },

  // laticinios — deli-counter cheese, commonly sold loose/by weight, no GTIN
  { category: 'laticinios', name: 'Queijo Prato', unit_basis: 'KG', aliases: ['QUEIJO PRATO'] },
  { category: 'laticinios', name: 'Queijo Mussarela', unit_basis: 'KG', aliases: ['MUSSARELA', 'MUCARELA', 'QUEIJO MUSSARELA'] },
  { category: 'laticinios', name: 'Queijo Minas', unit_basis: 'KG', aliases: ['QUEIJO MINAS'] },
  { category: 'laticinios', name: 'Queijo Provolone', unit_basis: 'KG', aliases: ['PROVOLONE'] },
];

let products = 0, aliases = 0;
for (const p of PRODUCTS) {
  const [row] = await sql`
    INSERT INTO canonical_products (category, name, unit_basis)
    VALUES (${p.category}, ${p.name}, ${p.unit_basis})
    ON CONFLICT (category, name) DO UPDATE SET unit_basis = EXCLUDED.unit_basis
    RETURNING id
  `;
  products++;
  for (const alias of p.aliases) {
    await sql`
      INSERT INTO aliases (canonical_product_id, raw_description)
      VALUES (${row.id}, ${norm(alias)})
      ON CONFLICT (raw_description) DO NOTHING
    `;
    aliases++;
  }
}
console.log(`Seeded ${products} canonical products, ${aliases} alias rows attempted.`);
