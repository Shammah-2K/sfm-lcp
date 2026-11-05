"""Screenshots of the dashboard with INJECTED SAMPLE DATA, for the dissertation.

The page is served unchanged from dashboard/, but in the browser only:
  * config.js is replaced by a dummy (no project URL, no key is ever loaded);
  * the supabase-js library is replaced by a stand-in client that serves the
    sample rows below and signs nobody in;
  * every other network request is blocked.
So nothing reaches Supabase and no real participant data can appear. The sample
codes (LSK01-LSK20) and amounts follow the demo seed's style (seeded, so every
run gives the same images).

    pip install playwright && python -m playwright install chromium
    python dashboard/tools/capture_sample.py OUT_DIR

Writes OUT_DIR/s16_dashboard.png (overview) and s16b_dashboard_participant.png
(LSK01: totals, daily chart, categories, stock and the start of the ledger).
"""

from __future__ import annotations

import json
import random
import subprocess
import sys
import time
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

from playwright.sync_api import sync_playwright

DASHBOARD = Path(__file__).resolve().parent.parent
PORT = 8765
LUSAKA = timezone(timedelta(hours=2))
TODAY = datetime(2026, 11, 10, 14, 0, tzinfo=LUSAKA)
NAMES = {
    "sales_goods": ("Sales of goods", "income"), "sales_service": ("Service income", "income"),
    "other_income": ("Other income", "income"), "stock": ("Stock purchase", "expense"),
    "transport": ("Transport", "expense"), "airtime": ("Airtime & data", "expense"),
    "rent_levy": ("Rent & market fees", "expense"), "utilities": ("Electricity & water", "expense"),
    "wages": ("Wages", "expense"), "food": ("Meals", "expense"),
    "other_expense": ("Other expense", "expense"),
}
CATALOGUE = [  # name, price, reorder level, stock now
    ("Tomatoes (heap)", 1000, 10, 34), ("Kapenta 500g", 6000, 3, 0),
    ("Cooking oil 2L", 9500, 5, 2), ("Mealie meal 25kg", 26000, 2, 5),
    ("Sugar 2kg", 5500, 4, 11), ("Bread", 2500, 6, 14), ("Soap", 1500, 5, 19),
]


def ms(t: datetime) -> int:
    return int(t.timestamp() * 1000)


def ledger_for(code: str, days: int, scale: float, rng: random.Random, cancel_day: int | None):
    """A market stall's entries over `days` days, like lib/demo/demo_seed.dart."""
    rows = []

    def add(t, kind, ngwee, cat, desc, method="cash", flag=False, reviewed=False):
        rows.append({"id": str(uuid.UUID(int=rng.getrandbits(128))), "occurred_at": ms(t),
                     "entry_type": kind, "amount_ngwee": ngwee, "final_category": cat,
                     "description": desc, "payment_method": method, "reverses_id": None,
                     "anomaly_flag": flag,
                     "anomaly_reviewed_at": t.isoformat() if reviewed else None})
        return rows[-1]

    for d in range(days - 1, -1, -1):
        base = (TODAY - timedelta(days=d)).replace(hour=0, minute=0)
        at = lambda h, m=0: base + timedelta(hours=h, minutes=m)  # noqa: E731
        if d == 0:
            add(at(11, 30), "expense", 2500, "transport", "minibus to Soweto market")
            add(at(11, 50), "expense", 500, "rent_levy", "daily market fee at Soweto market")
            add(at(12, 35), "sale", 7500, "sales_goods", "3 × Bread")
            add(at(13, 45), "expense", 25000, "transport", "taxi with stock", flag=True)
            continue
        add(at(6, 40), "expense", (20 + rng.randint(0, 10)) * 100, "transport",
            "minibus to Soweto market")
        add(at(7, 5), "expense", 500, "rent_levy", "daily market fee at Soweto market")
        for i in range(4 + rng.randint(0, 3)):
            method = "mobile_money" if rng.randint(0, 3) == 0 else "cash"
            ngwee = int((20 + rng.randint(0, 159)) * 100 * scale)
            name = rng.choice(CATALOGUE)[0]
            add(at(8 + i * 10 // 6, rng.randint(0, 49)), "sale", ngwee, "sales_goods",
                f"{1 + rng.randint(0, 2)} × {name}" if rng.random() < 0.5 else "", method)
        add(at(12, 30), "expense", (20 + rng.randint(0, 15)) * 100, "food", "lunch")
        if d % 3 == 0:
            add(at(13), "expense", 2000, "airtime", "MTN airtime", "mobile_money")
        if d % 4 == 0:
            add(at(15), "expense", int(rng.randint(180, 420) * 100 * scale), "stock",
                "stock from the wholesaler")
        if d % 7 == 0:
            add(at(17), "expense", 30000, "wages", "paid the helper")
        if d == 15:
            add(at(16), "expense", 15000, "utilities", "ZESCO units", "mobile_money")
        if d == cancel_day:
            wrong = add(at(14), "expense", 3000, "transport", "bus fare to town")
            rev = add(at(14, 5), "expense", -3000, "transport", "bus fare to town")
            rev["reverses_id"] = wrong["id"]
    rows.sort(key=lambda r: r["occurred_at"], reverse=True)
    return rows


def sample():
    rng = random.Random(42)
    people, by_biz = [], {}
    plans = {"LSK01": (21, 1.0, 9, "market_stall"), "LSK02": (16, 0.8, None, "market_stall"),
             "LSK03": (9, 1.3, 4, "shop")}
    for n in range(1, 21):
        code = f"LSK{n:02d}"
        p = {"participant_code": code, "claimed_at": None, "withdrawn_at": None,
             "business_id": None, "business_type": None, "entries": 0, "cancelled": 0,
             "in_ngwee": 0, "out_ngwee": 0, "flagged": 0, "last_received_at": None}
        if code in plans:
            days, scale, cancel, btype = plans[code]
            ledger = ledger_for(code, days, scale, rng, cancel)
            biz = str(uuid.UUID(int=rng.getrandbits(128)))
            for e in ledger:
                e["business_id"] = biz
            start = (TODAY - timedelta(days=days - 1)).replace(hour=6, minute=20)
            p.update(claimed_at=start.isoformat(), business_id=biz, business_type=btype,
                     entries=sum(1 for e in ledger if not e["reverses_id"]),
                     cancelled=sum(1 for e in ledger if e["reverses_id"]),
                     in_ngwee=sum(e["amount_ngwee"] for e in ledger if e["entry_type"] == "sale"),
                     out_ngwee=sum(e["amount_ngwee"] for e in ledger if e["entry_type"] == "expense"),
                     flagged=sum(1 for e in ledger if e["anomaly_flag"]),
                     last_received_at=(TODAY - timedelta(minutes=8 + 40 * n)).isoformat())
            by_biz[biz] = dashboard_views(ledger, biz)
        elif code == "LSK04":
            p.update(claimed_at=(TODAY - timedelta(hours=3)).isoformat(), business_type="service")
        people.append(p)
    return {"people": people, "biz": by_biz}


def dashboard_views(ledger, biz):
    daily, cats = {}, {}
    for e in ledger:
        dt = datetime.fromtimestamp(e["occurred_at"] / 1000, LUSAKA).date().isoformat()
        d = daily.setdefault(dt, {"business_id": biz, "day": dt, "in_ngwee": 0, "out_ngwee": 0,
                                  "entries": 0})
        d["in_ngwee" if e["entry_type"] == "sale" else "out_ngwee"] += e["amount_ngwee"]
        if not e["reverses_id"]:
            d["entries"] += 1
        name, kind = NAMES[e["final_category"]]
        c = cats.setdefault(name, {"business_id": biz, "name": name, "kind": kind, "entries": 0,
                                   "amount_ngwee": 0})
        c["amount_ngwee"] += e["amount_ngwee"]
        if not e["reverses_id"]:
            c["entries"] += 1
    stock = [{"business_id": biz, "name": n, "unit_price_ngwee": p, "reorder_level": r,
              "stock_qty": q, "is_active": True} for n, p, r, q in CATALOGUE]
    return {"dash_daily": sorted(daily.values(), key=lambda d: d["day"]),
            "dash_category": [c for c in cats.values() if c["entries"]],
            "dash_stock": stock, "ledger_entry": ledger}


# A stand-in for supabase-js: the calls index.html makes, answered from window.__SAMPLE.
STUB_CLIENT = r"""
(() => {
  const S = window.__SAMPLE;
  const session = { user: { email: 'researcher (sample data)' } };
  function query(table) {
    const filters = []; let order = null; let limit = null;
    const q = {
      select() { return q; },
      eq(col, val) { filters.push([col, val]); return q; },
      order(col, opts) { order = [col, !opts || opts.ascending !== false]; return q; },
      limit(n) { limit = n; return q; },
      then(resolve, reject) {
        let rows;
        if (table === 'dash_participant') rows = S.people.slice();
        else {
          const biz = (filters.find(([c]) => c === 'business_id') || [])[1];
          rows = ((S.biz[biz] || {})[table] || []).slice();
        }
        rows = rows.filter((r) => filters.every(([c, v]) => r[c] === v));
        if (order) rows.sort((a, b) => (a[order[0]] > b[order[0]] ? 1 : -1) * (order[1] ? 1 : -1));
        if (limit) rows = rows.slice(0, limit);
        return Promise.resolve({ data: rows, error: null }).then(resolve, reject);
      },
    };
    return q;
  }
  window.supabase = { createClient: () => ({
    from: query,
    rpc: async () => ({ data: true, error: null }),
    auth: {
      getSession: async () => ({ data: { session } }),
      onAuthStateChange(cb) { setTimeout(() => cb('INITIAL_SESSION', session), 0); },
      signOut: async () => ({}), signInWithPassword: async () => ({}),
    },
  }) };
})();
"""


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else DASHBOARD.parent / "docs" / "screens"
    out.mkdir(parents=True, exist_ok=True)
    data = sample()
    server = subprocess.Popen([sys.executable, "-m", "http.server", str(PORT), "--bind",
                               "127.0.0.1", "--directory", str(DASHBOARD)],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        time.sleep(1.5)
        with sync_playwright() as pw:
            browser = pw.chromium.launch()
            page = browser.new_page(viewport={"width": 1440, "height": 900},
                                    device_scale_factor=2, color_scheme="light")
            page.add_init_script("window.__SAMPLE = " + json.dumps(data) + ";")

            def route(r):
                url = r.request.url
                if url.endswith("/config.js"):
                    return r.fulfill(content_type="text/javascript", body=(
                        "window.SFM_CONFIG = { url: 'https://sample.invalid', "
                        "key: 'sample-data-only' };"))
                if "supabase-js" in url:
                    return r.fulfill(content_type="text/javascript", body=STUB_CLIENT)
                if url.startswith(f"http://127.0.0.1:{PORT}/"):
                    return r.continue_()
                return r.abort()  # nothing else leaves the page
            page.route("**/*", route)

            page.goto(f"http://127.0.0.1:{PORT}/index.html")
            page.wait_for_selector("text=Participants")
            page.wait_for_timeout(300)
            page.screenshot(path=str(out / "s16_dashboard.png"), full_page=True)

            page.goto(f"http://127.0.0.1:{PORT}/index.html#p=LSK01")
            page.wait_for_selector("text=Money in and out by day")
            page.wait_for_timeout(300)
            # Down to the first dozen ledger rows; the full ledger is very long.
            bottom = page.evaluate("""() => {
              const rows = [...document.querySelectorAll('table')].at(-1).querySelectorAll('tbody tr');
              const r = rows[Math.min(11, rows.length - 1)].getBoundingClientRect();
              return Math.ceil(r.bottom + window.scrollY + 24);
            }""")
            page.screenshot(path=str(out / "s16b_dashboard_participant.png"), full_page=True,
                            clip={"x": 0, "y": 0, "width": 1440, "height": bottom})
            browser.close()
    finally:
        server.terminate()
    print("written:", out / "s16_dashboard.png", out / "s16b_dashboard_participant.png")


if __name__ == "__main__":
    main()
