# Claude Code handoff brief — SFM-LCP scaffold

Open this file in the repo and point Claude Code at it at the start of the session.
It starts cold and knows none of the context below.

---

## 1. What the project is

An offline-first Android application that lets micro, small and medium enterprises
(MSMEs) in Lusaka record sales, expenses and stock, with transaction categorisation
and anomaly detection running **on the device**. The dissertation's research
contribution is a measurement: whether lightweight on-device models are accurate
and efficient enough on the 2–4 GB Android handsets these businesses actually own.
The app is the instrument; the measurement is the point.

Final supervision 10 Nov 2026. Next milestone is 13 Oct: Chapters 2 and 3 plus a
prototype implementing two functional requirements.

## 2. Hard constraints — these drive every design decision

| Constraint | Implication for the code |
|---|---|
| Works with no network, indefinitely | On-device database is the authoritative store. No feature may block on connectivity. Sync is opportunistic and additive |
| Target devices: 2–4 GB RAM Android, low-end SoCs | APK size, memory headroom and cold-start time are budgeted quantities, not afterthoughts. Release-mode profiling only |
| Users with limited literacy | Icon-led, linear flows; minimal text; no nested navigation. Design system lives in `theme.dart` |
| Financial data stays on the device | Inference is local. No raw transaction text leaves the handset |
| Single owner per device | No multi-writer conflict resolution needed. Append-only event log for ledger entries, last-write-wins for mutable metadata |

## 3. Working agreement — read this before writing any code

Shammah writes the business logic and all machine-learning code himself. This is an
academic integrity requirement, not a preference, and the university requires an AI
assistance log.

**Claude Code may:** scaffold directory structure and build configuration; write
widget skeletons and layout code; set up CI, linting, formatting and test
harnesses; write test fixtures and tooling scripts; review code and explain errors;
generate diagrams and docs from code that already exists.

**Claude Code must not:** write ledger logic, balance or categorisation rules, the
sync/conflict-resolution algorithm, or any ML training, evaluation or inference
code. For those, propose an interface and a test, and leave the body to Shammah.

**Never:** invent benchmark numbers, model accuracy figures or test results.
Measured values come from running the harness on real hardware, or they don't exist.

## 4. Two-phase scaffold — the boundary matters

Chapter 3 defines the ERD, data dictionary and functional requirements. Anything
derived from those should not be invented before they're written, or the chapter
and the code will contradict each other at exactly the point the examiner looks.

**Phase A — now, independent of Chapter 3:**

1. Repository layout (see §5), `.gitignore`, licence, README skeleton.
2. Flutter app shell: routing, `theme.dart` design system (colour, type scale, spacing, icon set), empty screens for the core flows.
3. Build and test infrastructure: `flutter analyze`, `flutter test`, formatting, a GitHub Actions workflow running all three on push.
4. The benchmark harness skeleton (§6) with its output contract fixed, even though no model exists yet.
5. `docs/` structure and the diagram-generation script (§6).
6. Update the existing `CLAUDE.md` rather than replacing it; fold in §2 and §3 above.

**Phase B — after Chapter 3's data model is written:**

7. Drift schema and migrations, generated from the ERD in Chapter 3.
8. Repository/DAO layer interfaces, with Shammah implementing the logic.
9. FR1 and FR2 features (§7).
10. Sync layer: outbox table, WorkManager job, append-only event log.

If Claude Code is asked for Phase B work before the ERD exists, it should say so
and propose the interface rather than guessing a schema.

## 5. Proposed repository layout

```
sfm-lcp/
  app/                  Flutter application
    lib/
      core/             theme.dart, constants, result types
      data/             Drift database, DAOs, repositories  (Phase B)
      domain/           entities, use cases                 (Shammah writes)
      features/         one folder per feature: sale/, expense/, inventory/, review/
      ml/               on-device scorer interface + Dart implementation (Shammah writes)
    test/
    integration_test/
  ml/                   Python: training, evaluation, export   (Shammah writes)
    data/               corpus (synthetic + seeded); never commit raw participant data
    notebooks/
    scripts/
  bench/                on-device benchmark harness + result CSVs
  docs/                 generated ERD, architecture diagrams, benchmark figures
  CLAUDE.md
  README.md
```

## 6. The "one flow" mechanism — this is the part worth getting right

The goal is that the dissertation's figures and tables are **generated from the
repository**, not drawn by hand and then re-drawn when the code changes.

- **ERD**: a script reads the Drift schema and emits Mermaid to `docs/erd.mmd`, rendered to `docs/erd.png` by mermaid-cli. Chapter 3 includes the rendered file.
- **Benchmarks**: the harness writes one CSV row per run — model, device, RAM, accuracy, inference latency (p50/p95), model size, APK delta, battery delta, timestamp, git SHA. A plotting script turns that CSV into the figures Chapter 4 includes. The CSV is committed; the figures are regenerated.
- **Test evidence**: `flutter test --reporter json` output is converted to the test-results table Chapter 4 needs.
- **Screenshots**: an integration test drives the app through each FR and saves screenshots to `docs/screens/` for the system guide.

Every one of these is a Chapter 4 deliverable that otherwise becomes manual work in
November. Fix the output contracts now, fill them later.

## 7. FR1 and FR2 for the 13 Oct prototype

Pick the two that de-risk the research, not the two that demo best:

- **FR1 — Record a transaction.** The user records a sale or expense (amount, free-text description, type) and it persists to the on-device database and appears in a list. Fully functional with the network off.
- **FR2 — Suggest a category.** On entry, the on-device model proposes a category; the user confirms or corrects it; the correction is stored as a labelled example. This is the one that proves the research claim is implementable.

FR2's model is Shammah's work. Claude Code scaffolds the confirm/correct widget and
the scorer interface it calls.

## 8. Definition of done for Phase A

- `flutter analyze` and `flutter test` pass locally and in CI on a clean clone.
- App builds in release mode and launches on a physical low-end device.
- `theme.dart` is the single source of colour, type and spacing; no hard-coded values in widgets.
- `docs/` contains a generated diagram, even if trivial, proving the pipeline runs.
- `bench/` runs end-to-end with a stub model and writes a valid CSV row.
- README states what the project is, how to build it, and how to run the benchmark.
- `CLAUDE.md` carries §2 and §3 of this brief.

## 9. Session opener to paste into Claude Code

> Read `claude_code_handoff.md` and `CLAUDE.md`, then propose a Phase A plan as a
> checklist before writing any code. Follow the working agreement in §3: scaffolding,
> tests and tooling only; leave ledger logic, sync algorithms and all ML code to me.
> Start with the repository layout and the Flutter shell, and stop at the Phase A/B
> boundary.
