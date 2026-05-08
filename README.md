# SFM-LCP — SME Financial Management Platform

> A mobile-first, offline-capable bookkeeping and Point-of-Sale platform for Zambian market traders, with on-device machine learning for expense categorization and cash-flow anomaly detection.

![Status](https://img.shields.io/badge/status-Phase%200%20%E2%80%94%20Foundations-orange)
![Platform](https://img.shields.io/badge/platform-Android-green)
![Stack](https://img.shields.io/badge/stack-Flutter%20%7C%20Node%20%7C%20Postgres%20%7C%20Python-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## About

SFM-LCP is the final-year project of Shammah King Kausa, BSc Computer Science student at **ZCAS University, Lusaka, Zambia** (Academic Year 2026).

The project addresses the financial-management gap in Zambia's informal economy. Small and Medium Enterprises and market traders account for approximately 70% of national employment, yet most operate without systematic financial records. They rely on memory and informal bookkeeping, which leads to poor business decisions, inability to access credit, and weak tax compliance. Mobile money penetration above 60% of adults provides a familiar payment rail that can be extended into a full bookkeeping experience. SFM-LCP packages bookkeeping, basic Point-of-Sale, MTN Mobile Money receipt integration, and two on-device machine-learning features into a single offline-capable Android application designed for low-end devices and intermittent connectivity.

## Status

**Phase 0 — Foundations** (Weeks 1–2 of a 24-week timeline). The project is in the setup phase: development environment, repository, MTN MoMo sandbox application, and literature-review tooling.

| Phase | Weeks | State |
| --- | --- | --- |
| 0. Foundations | 1–2 | In progress |
| 1. Literature Review | 3–5 | Not started |
| 2. Design & Architecture | 6–7 | Not started |
| 3. Backend + Dataset Collection | 8–12 | Not started |
| 4. Frontend + ML Workstream | 13–17 | Not started |
| 5. User Testing | 18–19 | Not started |
| 6. Dissertation Writing | 20–23 | Not started |
| 7. Polish & Defense | 24 | Not started |

## Core Features (MVP)

- Phone-based signup and login with OTP
- Sales and expense recording with offline-first storage
- Daily, weekly, and monthly summary views
- Basic inventory counter
- MTN Mobile Money Collections integration for digital receipts
- Bilingual UI (English and Nyanja, labels)
- Offline-first architecture with cloud sync
- **Smart expense categorization** — on-device classifier (TF-IDF + Logistic Regression baseline, fastText comparison)
- **Cash-flow anomaly detection** — on-device statistical detector (z-score baseline, Isolation Forest comparison)

## Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile | Flutter, Dart |
| Backend | Node.js, Express, TypeScript |
| Database (server) | PostgreSQL |
| Database (device) | SQLite via Drift |
| Authentication | Firebase Auth (phone OTP) |
| Mobile money | MTN MoMo Open API (Collections, sandbox) |
| Hosting | Railway |
| ML training | Python 3.11+, scikit-learn, fastText, pandas, numpy |
| ML deployment | On-device inference reimplemented in Dart |
| Version control & CI | GitHub, GitHub Actions |

## Repository Structure

sfm-lcp/
├── README.md
├── .gitignore
├── mobile/      # Flutter application
├── backend/     # Node.js + Express + TypeScript API
├── ml/          # Python ML training scripts and notebooks
└── docs/        # Project phase documents and design notes

Folders will be populated as the corresponding phases are reached.

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio with an Android SDK and emulator
- Node.js LTS (version 20 or 22)
- Python 3.11 or higher
- Git

Verify your environment:

```bash
flutter doctor
node --version
python --version
```

### Local setup

Cloning and running instructions will be added as each subproject is initialised. For now the repository contains scaffolding only.

## Documentation

Project phase documents, design decisions, and dissertation drafts are in [`docs/`](./docs). Each phase produces a Markdown backup that records what was done, the considerations involved, and the tradeoffs accepted.

## Author

**Shammah King Kausa**
BSc Computer Science, ZCAS University
Lusaka, Zambia
shammahk1usa@gmail.com · https://github.com/Shammah-2K · www.linkedin.com/in/shammah-kausa-0a81042b2

## Acknowledgements

Supervised at ZCAS University, Department of Computer Science. Built with reference to the Eighth National Development Plan and Zambia's National Financial Inclusion Strategy 2023–2027.

## License

MIT — see [LICENSE](./LICENSE) when added.