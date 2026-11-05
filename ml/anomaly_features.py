"""Features for the anomaly detector, computed exactly as the phone does.

For a new entry, the history is the same business's earlier entries of the same
type and category in the last HISTORY_DAYS days (the ledger passes 60 days).
With fewer than MIN_HISTORY of them the detector has no opinion.

  log_ratio  ln(amount) - median(ln history)       how many times bigger or smaller
                                                    than usual, on a log scale
  robust_z   log_ratio / (1.4826 * MAD + 0.05)      the same, in units of this
                                                    trader's usual spread

The Dart port is mobile/lib/domain/isolation_forest_detector.dart; the parity
fixture written by train_detector.py checks the two agree.
"""

from __future__ import annotations

import math

MIN_HISTORY = 5
HISTORY_DAYS = 60
MAD_SCALE = 1.4826
SPREAD_FLOOR = 0.05
FEATURES = ["log_ratio", "robust_z"]


def median(values: list[float]) -> float:
    s = sorted(values)
    n = len(s)
    mid = n // 2
    return s[mid] if n % 2 else (s[mid - 1] + s[mid]) / 2.0


def features(amount_ngwee: int, history_ngwee: list[int]) -> list[float] | None:
    if len(history_ngwee) < MIN_HISTORY:
        return None
    logs = [math.log(h) for h in history_ngwee]
    centre = median(logs)
    mad = median([abs(v - centre) for v in logs])
    log_ratio = math.log(amount_ngwee) - centre
    return [log_ratio, log_ratio / (MAD_SCALE * mad + SPREAD_FLOOR)]
