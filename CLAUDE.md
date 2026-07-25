# EconoMia — working notes

Brazilian (Paraná) grocery-savings app. Scan the QR on an NFC-e cupom fiscal,
see where each item is cheaper nearby, track savings, build lists, earn Mia
Points. UI language is **pt-BR**. Android + iOS (Android 8 / iOS 13).

`Docs/` is the product source of truth — vision, features, branding, gamification,
home screen spec. Read the relevant one before building a feature.

## Executing a phase

`PROGRESS.md` tracks the 17 build phases and `.claude/phases.json` holds the
model mapping. When asked to build, run, execute or continue a phase — by number
or by name — follow this order:

1. **Check the model.** Look up the phase in `.claude/phases.json` to get its
   recommended model. If the session is not on that model, output the exact
   command the user should run:
   ```
   /model opus
   ```
   (or `sonnet`, whatever is needed). Then output "Ready to build Phase N once you switch."
   
   **Enforce:** Do not silently build an Opus phase on Sonnet. But after the
   user runs `/model`, just build — no need to wait for them to ask again or
   repeat the request.
   If already on the recommended model, proceed immediately to step 2.
   
   If not: the user runs the command, and I build automatically on the next
   message (no need for them to repeat the request).

2. **Read the phase spec** in [`BUILD_PLAN.md`](BUILD_PLAN.md) §8, plus any
   `Docs/` file it names. The plan states each phase's deliverable — that is the
   definition of done, not "some code exists". §1–7 hold the architecture, the
   backend contract and the persistence model; re-read the relevant one rather
   than re-deriving it.
3. **Flip the phase to 🟨** in `PROGRESS.md` before writing its first line of
   code.
4. **Build it,** honouring the ground rules below.
5. **Verify:** `flutter analyze` and `flutter test` clean, plus the phase's own
   check. For anything with UI, add a shot to `test/screenshots.dart` and
   actually look at it — there is no device on this machine.
6. **Flip to ✅**, add a one-line note, recompute the header count, the progress
   bar and the date footer.
7. **Commit `PROGRESS.md` with that phase's code**, never as a commit of its
   own. Only commit if the user has asked for commits.

If a phase turns out to be blocked, mark it ⏸️ with the reason in Notes, finish
everything in the phase that is not blocked, and say plainly what was left out.

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
