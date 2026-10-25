# CLAUDE.md — SFM-LCP

Offline-first Android app for Lusaka MSMEs: record sales, expenses and stock, with transaction
categorisation and anomaly detection running on the device. The research contribution is a
measurement: whether lightweight on-device models are accurate and efficient enough on 2–4 GB
Android handsets. The app is the instrument; the measurement is the point.

Source of truth for requirements and data model: the dissertation's Chapter 3
(`Chapter3_Overleaf/` in the documentation folder; schema in `db/schema.sql`). Do not invent
schema, requirements or categories that Chapter 3 does not define.

## Hard constraints

| Constraint | Implication for the code |
|---|---|
| Works with no network, indefinitely | On-device database is the authoritative store. No feature may block on connectivity. Sync is opportunistic and additive |
| Target devices: 2–4 GB RAM Android, low-end SoCs | APK size, memory headroom and cold-start time are budgeted quantities. Release-mode profiling only |
| Users with limited literacy | Icon-led, linear flows; minimal text; no nested navigation. Design system lives in `theme.dart` |
| Financial data stays on the device | Inference is local. No raw transaction text leaves the handset |
| Single owner per device | No multi-writer conflict resolution. Append-only event log for ledger entries, last-write-wins for mutable metadata |

## Working agreement

The university requires an AI assistance log, and Shammah must be able to explain every part of
the system at examination.

**Revised 25 Oct 2026 (Shammah's decision):** Claude Code writes the app's logic as well as its
UI: ledger, totals, stock, onboarding, the sync client and the Supabase backend. Shammah reviews
every phase to understand how it works and what needs revision. To make that review possible:

- Each phase is delivered on its own branch in small, single-purpose commits.
- Each phase comes with a review guide in `docs/review/` explaining how the code works, which
  rules from Chapter 3 it enforces, and what to check.
- Tests define "done" and act as executable documentation; every rule has a named test.
- Every AI-written phase goes into Shammah's AI assistance log.

**Still Shammah's unless he says otherwise before Phase 6:** ML training, evaluation and the
on-device categoriser and anomaly detector. Claude Code builds the tooling around them (corpus
validator, parity harness, benchmark harness) and the interfaces they plug into.

**Never:** invent benchmark numbers, model accuracy figures or test results. Measured values come
from running the harness on real hardware, or they don't exist.

**`prototype/`:** the throwaway 13 Oct 2026 demonstration build (branch `prototype/fr1-3`). Nothing
from it is copied into the real app.

The plan and decisions for the current phases are in `docs/plans/next-phase-plan.md`.

## Repository layout

```
mobile/     Flutter application (real app)
backend/    Supabase project: SQL migrations, sync function, dashboard (FR9, FR10)
ml/         Python training, evaluation, export (Shammah writes)
docs/plans/ phase plans; docs/review/ review guides for AI-written phases
docs/       design notes, generated diagrams, handoff briefs
prototype/  throwaway FR1–FR3 demo (branch prototype/fr1-3)
```

Never commit raw participant data. `ml/data/raw/` is git-ignored.
