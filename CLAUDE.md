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

Shammah writes the business logic and all machine-learning code himself. This is an academic
integrity requirement, and the university requires an AI assistance log.

**Claude Code may:** scaffold directory structure and build configuration; write widget skeletons
and layout code; set up CI, linting, formatting and test harnesses; write test fixtures and tooling
scripts; review code and explain errors; generate diagrams and docs from code that already exists.

**Claude Code must not:** write ledger logic, balance or categorisation rules, the sync/conflict
resolution algorithm, or any ML training, evaluation or inference code. For those, propose an
interface and a test, and leave the body to Shammah.

**Never:** invent benchmark numbers, model accuracy figures or test results. Measured values come
from running the harness on real hardware, or they don't exist.

**Exception — `prototype/` only:** the throwaway 13 Oct 2026 demonstration build is fully
AI-written under `BUILD_PROTOTYPE.md`, on branch `prototype/fr1-3`. That exception does not extend
to any other folder, and nothing from `prototype/` is to be copied into the real app.

## Repository layout

```
mobile/     Flutter application (real app)
backend/    Node/TypeScript sync API (FR9; not started)
ml/         Python training, evaluation, export (Shammah writes)
docs/       design notes, generated diagrams, handoff briefs
prototype/  throwaway FR1–FR3 demo (branch prototype/fr1-3)
```

Never commit raw participant data. `ml/data/raw/` is git-ignored.
