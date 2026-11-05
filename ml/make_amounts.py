"""Generate synthetic trader ledgers with injected anomalies, for the detector (FR4).

Writes data/processed/amounts.csv: one row per entry, with columns
  trader, business_type, occurred_at_ms, type, category, amount_ngwee,
  is_anomaly, anomaly_kind

Each trader has a usual amount per category (drawn around the category scale
below) and day-to-day variation around it. About 2% of entries are replaced by
a typing slip, the anomalies FR4 is meant to catch:
  x10    an extra zero          (K25 typed as K250)
  x100   two extra zeros        (K25 typed as K2,500)
  /10    a dropped zero         (K250 typed as K25)
  /100   a misplaced point      (K250.00 typed as K2.50)
Chapter 3: synthetic data is valid for injected-anomaly evaluation.

The scales and frequencies are ASSUMPTIONS drafted with AI assistance (2 Nov 2026)
for the researcher to check against what Lusaka traders spend and earn.

Deterministic: seed 42.  python make_amounts.py
"""

from __future__ import annotations

import csv
import math
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

from make_corpus import codebook

HERE = Path(__file__).parent
OUT = HERE / "data" / "processed" / "amounts.csv"

SEED = 42
TRADERS = 80
DAYS = 90
START = datetime(2026, 3, 1, tzinfo=timezone(timedelta(hours=2)))  # Lusaka
ANOMALY_RATE = 0.02
ANOMALY_KINDS = {"x10": 10.0, "x100": 100.0, "/10": 0.1, "/100": 0.01}
WITHIN_TRADER_SIGMA = 0.4   # day-to-day spread around a trader's usual amount (log scale)
BETWEEN_TRADER_SIGMA = 0.6  # how much traders differ from each other (log scale)

# ASSUMPTIONS to check: (median amount in kwacha, entries per day) by business type.
GOODS = {
    "sales_goods": (150, 3.0), "sales_service": (60, 0.05), "other_income": (200, 0.05),
    "stock": (600, 0.4), "transport": (25, 0.6), "airtime": (20, 0.3),
    "rent_levy": (30, 0.3), "utilities": (150, 0.05), "wages": (300, 0.1),
    "food": (25, 0.7), "other_expense": (40, 0.2),
}
SERVICE = {
    "sales_goods": (100, 0.2), "sales_service": (80, 2.5), "other_income": (200, 0.05),
    "stock": (250, 0.1), "transport": (25, 0.5), "airtime": (20, 0.4),
    "rent_levy": (40, 0.2), "utilities": (150, 0.08), "wages": (300, 0.1),
    "food": (25, 0.7), "other_expense": (40, 0.2),
}
PROFILES = {"market_stall": GOODS, "shop": GOODS, "service": SERVICE}
FIELDS = ["trader", "business_type", "occurred_at_ms", "type", "category", "amount_ngwee",
          "is_anomaly", "anomaly_kind"]


def poisson(rng: random.Random, lam: float) -> int:
    """Knuth's method; small lambdas only."""
    limit, k, p = math.exp(-lam), 0, 1.0
    while True:
        p *= rng.random()
        if p <= limit:
            return k
        k += 1


def round_ngwee(kwacha: float, category: str) -> int:
    """Sales to the nearest 50 ngwee, everything else to the kwacha."""
    step = 50 if category.startswith("sales") else 100
    return max(step, int(round(kwacha * 100 / step)) * step)


def generate() -> list[dict]:
    rng = random.Random(SEED)
    kinds = codebook()
    rows = []
    for t in range(TRADERS):
        trader = f"T{t + 1:03d}"
        business_type = rng.choice(list(PROFILES))
        profile = PROFILES[business_type]
        usual = {c: m * math.exp(rng.gauss(0, BETWEEN_TRADER_SIGMA)) for c, (m, _) in profile.items()}
        for day in range(DAYS):
            for category in sorted(profile):
                for _ in range(poisson(rng, profile[category][1])):
                    kwacha = usual[category] * math.exp(rng.gauss(0, WITHIN_TRADER_SIGMA))
                    amount = round_ngwee(kwacha, category)
                    kind = ""
                    if rng.random() < ANOMALY_RATE:
                        kind = rng.choice(sorted(ANOMALY_KINDS))
                        slipped = int(round(amount * ANOMALY_KINDS[kind]))
                        if slipped < 100:  # a dropped zero on a tiny amount: use x10 instead
                            kind, slipped = "x10", amount * 10
                        amount = slipped
                    at = START + timedelta(days=day, minutes=rng.randint(7 * 60, 19 * 60))
                    rows.append({
                        "trader": trader, "business_type": business_type,
                        "occurred_at_ms": int(at.timestamp() * 1000),
                        "type": "sale" if kinds[category] == "income" else "expense",
                        "category": category, "amount_ngwee": amount,
                        "is_anomaly": int(bool(kind)), "anomaly_kind": kind,
                    })
    rows.sort(key=lambda r: (r["trader"], r["occurred_at_ms"], r["category"]))
    return rows


def write(rows: list[dict], out: Path = OUT) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    rows = generate()
    write(rows)
    anomalies = sum(r["is_anomaly"] for r in rows)
    print(f"wrote {len(rows)} entries for {TRADERS} traders over {DAYS} days, "
          f"{anomalies} injected anomalies, to {OUT.relative_to(HERE)}")


if __name__ == "__main__":
    main()
