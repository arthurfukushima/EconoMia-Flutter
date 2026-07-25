# EconoMia — working notes

Brazilian (Paraná) grocery-savings app. Scan the QR on an NFC-e cupom fiscal,
see where each item is cheaper nearby, track savings, build lists, earn Mia
Points. UI language is **pt-BR**. Android + iOS (Android 8 / iOS 13).

`Docs/` is the product source of truth — vision, features, branding, gamification,
home screen spec. Read the relevant one before building a feature.

## Phase status — update it as you go

`PROGRESS.md` tracks the 17 build phases and is the only status surface.

- Flip a phase to 🟨 **before** writing its first line of code.
- Flip it to ✅ only once its stated deliverable actually runs **and**
  `flutter analyze` and `flutter test` are clean.
- Recompute the count and the progress bar in the header, and the date footer.
- Commit `PROGRESS.md` **with that phase's code**, never as a commit of its own.

## Ground rules

- **No colour literals under `lib/features/`.** Everything comes from
  `Theme.of(context).sa` (`SaColors`) or the `ColorScheme`. This is what keeps a
  dark theme a wiring job instead of a refactor — the palette is already worked
  out in `SaColors.dark`, just unwired.
- **Money is always integer cents.** Two source formats that must never be
  crossed: SEFAZ gives `"R$ 1.234,56"` (`parseBRL`), Menor Preço gives `"3.19"`
  (`reaisToCents`).
- **`domain/` is pure functions** — no I/O, no classes, no injection. That is
  what makes the savings maths directly testable, and savings correctness is the
  project's #1 risk: a wrong "you overpaid R$17" destroys trust.
- **Add a dependency in the phase that needs it**, not up front.
- **Honesty rule** (from `Docs/13_Home_Screen.md`): every block has a real state
  *and* an empty state. No notes → onboarding copy, never a hollow "R$ 0,00". No
  gated trend → a learning nudge, never a fabricated promo. Savings are framed as
  opportunity ("dá pra economizar"), never as already banked.

## Backend

Three already-deployed Vercel functions at `https://econo-mia.vercel.app`:
`/api/cep`, `/api/nfce`, `/api/precos`. **This repo is a client — never
re-implement NFC-e parsing or price scraping in Dart.** Errors come back as
`{error: "<snake_case>"}`.

Menor Preço rate-limits: keep the request pools at concurrency 6 for receipt
enrichment and 3 for list pricing.

## Commands

```
flutter analyze
flutter test
flutter test test/screenshots.dart --update-goldens   # renders to test/shots/
```

There is no emulator or device on this machine, so `test/screenshots.dart` is
how UI gets eyeballed. It is not named `*_test.dart` on purpose — `flutter test`
skips it, so it never becomes a brittle pixel assertion.

## Reference implementation

`D:\Projects\EconoMia` is a React/Vite MVP of this app. It is **reference only**
— read it for behaviour, layout and copy; never port its code or structure.
