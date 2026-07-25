# Branding & Mia

Source: consolidated from `Hugo/EconoMia-Proposta-Inicial.md`.

## Name
**EconoMia** — *economia* (savings) + **Mia** (the character). The wordmark ships
as `Econo` + accent-colored `Mia` (see `src/App.jsx`, `.wordmark-accent`).

## Positioning line
> "EconoMia turns prices scattered across the web into intelligence that helps
> people shop better." — the user doesn't open a price comparator, they open Mia.

## Mia — the character
**Status:** partly shipped (logo + wordmark + visuals). Mia's **speaking voice**
now ships on the **Home Screen** — the savings hero and "Dica da Mia" speak in her
tone ("Já te economizei…", "Ainda aprendendo os preços daqui") — see
[13_Home_Screen.md](13_Home_Screen.md). Her voice **elsewhere** (notifications,
loading, in other views) is still **not built**; this section is the spec for it.

A curious, clever cat. The voice of the app.

Personality: objective · friendly · helpful · observant · a hunter of good deals.
**Never childish. Always useful.**

Voice examples (PT-BR — the product's actual copy tone):
- "Encontrei uma economia de R$ 48 hoje."
- "Achei uma marca equivalente 18% mais barata."
- "Hoje vale mais a pena comprar no Muffato."
- "Vale esperar até sexta."

Where Mia should appear: onboarding · loading/splash · notifications · tips ·
home screen.

## Visual identity
Hugo's proposed palette **is the shipped "Chubby Cat" system** (`src/styles.css`,
sampled from `assets/EconoMia_Logo.png`) — the marketing names map to real tokens:

| Hugo's intent            | Shipped token(s)                          |
|--------------------------|-------------------------------------------|
| Green → trust & savings  | `--pine-700/-600/-500`, `--leaf-500`      |
| Cream → warmth/welcome   | `--paper`, `--paper-2`, `--kraft-300`     |
| Orange → opportunity     | `--orange-500/-600`, `--accent`           |

Style: minimalist · rounded corners (`--r-*`) · few colors · sticker-sheet cards
on a pine field · micro-animations (`--ease-back`, `--ease-squish`).
Type: Fredoka (wordmark/headings), Nunito (body).

**Refined "Sage & Amber" direction** (`--sa-*` tokens): forest green `#14312A`,
amber `#E4872B`, warm papers, mint/green for savings. Shipped on the **Home Screen
+ bottom nav** and scoped there — older views keep the Chubby Cat tokens above
until they migrate. See [13_Home_Screen.md](13_Home_Screen.md).

## Note on scope
Full character voice/personality is a **post-MVP** layer (Phase 2+, see
[07_Product_Roadmap.md](07_Product_Roadmap.md)); it changes copy/UX, not the core
scan → savings → history loop. The visual system already ships, and a first slice
of her voice landed early on the Home Screen ([13_Home_Screen.md](13_Home_Screen.md)).
