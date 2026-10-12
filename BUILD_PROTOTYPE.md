# BUILD_PROTOTYPE.md — SFM-LCP throwaway prototype (FR1–FR3, offline)

You are Claude Code. Build the prototype described here, completely and working, in one session.
Work milestone by milestone (section 9), verify each one, and commit after each.

---

## 0. Authorisation and boundaries (read first)

- The repository owner (Shammah) has **explicitly authorised** you to write the *entire* prototype,
  including business logic and ML code. This overrides the "scaffolding and review only" rule in
  `CLAUDE.md` **for the `prototype/` folder only**. Outside `prototype/`, `CLAUDE.md` still applies.
- This is a **throwaway demonstration build**. The owner will rewrite the real app himself later.
  It must still be complete: it is shown to a supervisor on Tue 13 Oct 2026.
- Work on a new branch: `prototype/fr1-3`. Do not modify `CLAUDE.md`, and do not touch files outside `prototype/`.
- **No placeholders.** No `TODO`, `FIXME`, `UnimplementedError`, lorem ipsum, "your text here", empty
  handlers, or commented-out stubs. If something is in scope it works; if it is out of scope it does
  not appear at all (no disabled buttons for future features).
- **No generic template code.** Delete the Flutter counter app and its default widget test. No default
  README text. No unused packages or files.
- Do not ask the owner questions mid-build. Where this document is silent, make the simplest choice
  consistent with it and record it in `prototype/DECISIONS.md` (one line each).

## 1. What the prototype must demonstrate

An Android app that an MSME operator in Lusaka uses **fully offline** to:

| ID | Requirement | In prototype |
|---|---|---|
| FR1 | Record a sale: amount, optional description, cash or mobile money | Yes |
| FR2 | Record an expense with a short free-text description | Yes |
| FR3 | Suggest a category on the device; the user confirms or corrects it | Yes |
| FR8 | All of the above with no network | Yes (no network code exists at all) |
| FR11 | Identify the user by a participant code | Yes (local only) |

Out of scope, so do not build: sync/backend/HTTP, products/POS/stock, anomaly detection, reversals UI,
daily/weekly totals screen, dashboard, login server, iOS, localisation, onboarding tutorials.

## 2. Repository layout to create

```
prototype/
  README.md                 # how to run, specific to this prototype (section 10)
  DECISIONS.md              # one line per choice you made that this doc did not specify
  ml/
    requirements.txt        # scikit-learn, numpy (latest stable)
    make_corpus.py          # deterministic synthetic corpus (section 4)
    train.py                # trains, evaluates, exports model + parity cases (section 5)
    data/corpus.csv         # generated, committed
    out/                    # generated: categoriser_model.json, parity_cases.json, metrics.txt
  app/                      # Flutter project (package name: sfm_lcp_prototype)
    assets/models/categoriser_model.json
    lib/...
    test/...
```

## 3. Category codebook (fixed for the prototype)

Seed these into the `category` table on first database creation. `icon` is a Material icon name.

| code | name | kind | icon |
|---|---|---|---|
| sales_goods | Sales of goods | income | shopping_basket |
| sales_service | Service income | income | handyman |
| other_income | Other income | income | savings |
| stock | Stock purchase | expense | inventory_2 |
| transport | Transport | expense | directions_bus |
| airtime | Airtime & data | expense | phone_android |
| rent_levy | Rent & market fees | expense | storefront |
| utilities | Electricity & water | expense | bolt |
| wages | Wages | expense | groups |
| food | Meals | expense | restaurant |
| other_expense | Other expense | expense | more_horiz |

## 4. Synthetic corpus — `ml/make_corpus.py`

Template-generated only (no LLM-generated text), fixed random seed `42`, reproducible byte-for-byte.
English descriptions with local nouns (no code-switched sentences). Output `data/corpus.csv` with
columns: `text, category, kind, template_id, provenance` (`provenance` = `template-v1`).

Slot lists:
- items: tomatoes, onions, kapenta, mealie meal, cooking oil, sugar, salt, bread, eggs, chickens, rape,
  cabbage, soap, chitenge, salaula bale, charcoal, soft drinks, biscuits, kalembula, groundnuts
- places/suppliers: Soweto market, Comesa market, Kamwala, City market, Chilenje, Matero, Kalingalinga,
  the wholesaler, Shoprite, Choppies
- workers: shop assistant, helper, cleaner, guard, casual worker
- months: January … December; quantities: 1–50 with units (bags, boxes, crates, kg, dozen, packets)

Templates (at least these; each has a unique `template_id`):
- **stock**: "bought {qty} {item}", "{item} for stock", "restock {item}", "{item} from {place}", "order of {item}", "{qty} {item} wholesale"
- **transport**: "bus fare to {place}", "minibus to {place}", "taxi from {place}", "transport for goods", "fuel for delivery", "carrier fee at {place}"
- **airtime**: "MTN airtime", "Airtel talktime", "Zamtel bundle", "data bundle", "airtime for business phone", "internet bundle for {month}"
- **rent_levy**: "stall rent", "shop rent for {month}", "market levy", "council levy", "daily market fee at {place}", "storage fee"
- **utilities**: "ZESCO units", "electricity tokens", "water bill", "LWSC bill", "prepaid units for {month}", "solar battery charging"
- **wages**: "paid {worker}", "{worker} wages", "salary for {worker}", "{worker} pay for {month}", "weekly pay {worker}"
- **food**: "lunch", "breakfast at {place}", "tea and buns", "nshima and relish", "drinking water", "meal at the market"
- **other_expense**: "phone repair", "mobile money fee", "plastic bags", "receipt book", "padlock for stall", "bank charges"
- **sales_goods**: "sold {qty} {item}", "{item} sale", "customer bought {item}", "sales of {item} today", "{qty} {item} sold at {place}"
- **sales_service**: "hair braiding", "phone charging service", "tailoring job", "shoe repair", "printing and photocopy", "barber cut"
- **other_income**: "refund from supplier", "commission received", "gift from family", "interest from chilimba", "rent from tenant"

Generate ~120 samples per template. Apply a typo to 30% of samples (one of: drop a character, swap
two adjacent characters, duplicate a character — never in the first character). Randomise case for
10% of samples. Deduplicate exact duplicates within a template.

Add a header comment stating: this corpus is for the throwaway prototype only and must not be used in
the dissertation evaluation.

## 5. Training and export — `ml/train.py`

1. Load `data/corpus.csv`.
2. Split **by template**, not by row: `GroupShuffleSplit(test_size=0.2, random_state=42)` on
   `template_id`, re-drawing until every category has at least one test template (cap 200 tries; fail
   loudly if impossible). Explain in one comment why (leakage).
3. Pipeline: `TfidfVectorizer(analyzer="char_wb", ngram_range=(2, 4), lowercase=True,
   sublinear_tf=True, min_df=2, max_features=6000)` → `LogisticRegression(max_iter=2000, C=4.0)`
   (multinomial softmax, which is the default for lbfgs with >2 classes).
4. Print and write to `out/metrics.txt`: macro-F1 and per-class F1 on the held-out templates, plus the
   train/test template lists.
5. Refit on all data, then export `out/categoriser_model.json`:
   ```json
   {
     "model_version": "proto-lr-1",
     "analyzer": "char_wb", "ngram_min": 2, "ngram_max": 4,
     "lowercase": true, "sublinear_tf": true, "norm": "l2",
     "classes": ["airtime", "..."],
     "vocabulary": {"ai": 0, "...": 1},
     "idf": [1.23, "..."],
     "coef": [[0.1, "..."], "..."],
     "intercept": [0.2, "..."],
     "confidence_cutoff": 0.6
   }
   ```
6. Export `out/parity_cases.json`: 300 descriptions (mix of corpus rows, unseen typos, and 20
   hand-written edge cases: single word, all caps, punctuation, digits only, extra spaces, very long
   text; no empty strings) with the Python `predict_proba` vector for each.
7. Copy the model to `app/assets/models/` and the parity file to `app/test/fixtures/`.

## 6. Dart categoriser — must match Python exactly

`lib/ml/categoriser.dart`: pure Dart, no ML packages.

- Load the JSON asset once at startup.
- **Reproduce scikit-learn's `char_wb` analyzer exactly** (verified against scikit-learn 1.9.1 on
  2,009 strings, order included): lowercase; collapse every whitespace run to one space; split on
  spaces, skipping empty pieces; for each word `w`, let `p = ' ' + w + ' '`; then for n = min..max:
  if `p.length <= n`, emit `p` once and **stop** (do not try larger n for this word); otherwise
  emit every window `p.substring(i, i + n)` for i = 0..p.length − n. Reference Python:
  ```python
  def char_wb(text, lo=2, hi=4):
      text = re.sub(r"\s+", " ", text.lower()); out = []
      for w in text.split(" "):
          if not w: continue
          p = " " + w + " "
          for n in range(lo, hi + 1):
              if len(p) <= n: out.append(p); break
              out.extend(p[i:i + n] for i in range(len(p) - n + 1))
      return out
  ```
  Before writing Dart, add an assertion in `train.py` that this function equals
  `vectorizer.build_analyzer()` on every corpus row and parity case; stop if it ever differs.
- Term frequencies → if `sublinear_tf`, tf = 1 + ln(tf) → multiply by idf → L2-normalise → sparse dot
  with each class row of `coef` + `intercept` → softmax.
- `suggest(description, kind)` returns a `Suggestion { categoryCode, confidence, top3, modelVersion,
  preselect, elapsedMicros }`. Restrict to categories of the requested kind (income/expense) by
  dropping the other classes' scores **before** the softmax. `preselect = confidence >= cutoff`.
  Time the call with `Stopwatch`.
- If the description is empty after trimming, return no suggestion (null).

**Parity test (mandatory):** `test/categoriser_parity_test.dart` loads `test/fixtures/parity_cases.json`
and asserts that, for every case, Dart probabilities match Python within `1e-6`. (Compare over all
classes with no kind restriction; add a `suggestUnrestricted` method for this.) The build is not done
until this passes.

## 7. Database — Drift, using the dissertation schema verbatim

The schema is in section 12 of this document, copied from the dissertation's `schema.sql`. Use it **unchanged**.

- Put it in `lib/data/schema.drift` so Drift generates classes from the real SQL.
- If `drift_dev` rejects a specific statement (most likely a trigger with `RAISE` or a view), keep all
  tables in the `.drift` file and execute the rejected statements verbatim with `customStatement` in
  `onCreate`, in the same order as the schema. Record which ones in `DECISIONS.md`.
- `beforeOpen`: `PRAGMA foreign_keys = ON`.
- `onCreate`: create the schema, then seed the 11 categories from section 3.
- Packages: `drift`, `drift_flutter`, `uuid`, `intl`; dev: `drift_dev`, `build_runner`. Use current
  stable versions.

`lib/data/ledger_repository.dart`:
- `Future<LedgerEntry> recordSale({required int amountNgwee, String description = '', required PaymentMethod method, String? finalCategory, Suggestion? suggestion})`
  — the final category defaults to `sales_goods` when there is no description.
- `Future<LedgerEntry> recordExpense({required int amountNgwee, required String description, required PaymentMethod method, required String finalCategory, Suggestion? suggestion})`
- `Stream<List<EntryView>> watchRecent({int limit = 50})`, newest first.
- `Stream<int> watchPendingSyncCount()` (counts `sync_record` rows with status `pending`; the triggers fill it).
- UUID v4 ids; all timestamps in epoch milliseconds UTC; `occurred_at` = `created_at` = `updated_at` = now.
- Store `predicted_category`, `category_confidence` and `model_version` from the suggestion when one
  exists, otherwise null. Anomaly columns stay at their defaults.
- One database transaction per save.

`lib/data/session.dart`: the user is "logged in" when a `business` row exists. First launch shows the
participant-code screen, which inserts the business row.

## 8. User interface (low-literacy first)

`lib/theme.dart` is the single place for colours, sizes and text styles.
- Income green `#2E7D32`, expense red `#C62828`, neutral surfaces; Material 3.
- Minimum touch target 56 dp; body text ≥ 18 sp; amounts ≥ 32 sp bold.
- Icons + numbers first, few words. Every category shows its icon (section 3) next to its name.
- Currency format `K25.00` (ZMW). **Never use `double` for money**: parse the typed amount string
  directly into integer ngwee (`"25"` → 2500, `"25.5"` → 2550, `"25.50"` → 2550; reject >2 decimals,
  zero, negative, and > K1,000,000).

Screens:
1. **Participant code** (first launch only): large field, 4–12 letters/digits, auto-uppercased;
   "Start" button. Inserts the business row and navigates to Home.
2. **Home**: two large buttons side by side — green "Sale" (icon `add_card`) and red "Expense"
   (icon `payments`). Below them, the recent entries list (icon of the final category, description or
   category name, amount coloured by type, time `HH:mm`, small "cash"/"mobile money" icon). Top bar:
   the participant code, and a small "offline-ready" badge with the pending-sync count
   (`cloud_off` icon + number), which shows that saves are queued in the outbox.
3. **Record expense**:
   - Amount: big custom on-screen keypad (0–9, `.`, backspace); no system keyboard for amounts.
   - Description: text field (system keyboard), hint "What was it for?", max 120 characters.
   - Suggestion runs as the user types (debounce 250 ms):
     - If `preselect`: show the suggested category as a large selected chip with its icon.
     - Otherwise: show the top-3 categories as three large icon chips, none selected.
     - Always offer an "Other" chip that opens a grid of all expense categories.
     - Under the chips, in small grey text: `Suggested in 2.3 ms · 87%`.
   - Payment method: two large toggle buttons (cash `payments_outlined`, mobile money `phone_iphone`); cash is the default.
   - Save is enabled only when amount, description and category are valid. On save, show a full-width
     green confirmation ("Saved K25.00") for 1.5 s, then return Home.
4. **Record sale**: the same layout, but the description is optional and the suggestion uses income
   categories. With no description, the category defaults to Sales of goods (shown preselected).

Accessibility: semantic labels on icon-only buttons; text scales with system font size without overflow
at 1.3×.

## 9. Milestones (verify and commit after each)

| # | Milestone | Done when |
|---|---|---|
| M1 | Branch, `prototype/` layout, Flutter project created, counter app removed | `flutter analyze` clean |
| M2 | `make_corpus.py` + `train.py`; artefacts generated | `out/metrics.txt` exists; macro-F1 printed (report the number, no target) |
| M3 | Dart categoriser + parity test | `flutter test test/categoriser_parity_test.dart` passes |
| M4 | Drift schema, seeding, repository + DB tests | DB tests in section 11 pass |
| M5 | Theme + four screens wired to the repository | Manual run in emulator: record a sale and an expense end to end |
| M6 | Release build | `flutter build apk --release --split-per-abi` succeeds; report APK sizes and model JSON size |
| M7 | README + DECISIONS + final check | Section 13 checklist all true |

Commit message format: `prototype: <milestone summary>`.

## 10. `prototype/README.md` content (write it specifically, no boilerplate)

What the prototype shows (FR1–FR3 offline); how to regenerate the corpus and model (exact commands);
how to run the tests; how to build and install the release APK (`adb install`); the measured
macro-F1, parity result and APK size; a one-paragraph note that this is a throwaway build and the
corpus is prototype-only.

## 11. Tests required

- `categoriser_parity_test.dart`: section 6.
- `amount_parser_test.dart`: valid and invalid cases from section 8.
- `ledger_repository_test.dart` (in-memory `NativeDatabase.memory()`; install `libsqlite3-dev` in WSL
  if needed):
  - an expense saves with prediction fields and creates exactly one pending `sync_record`
  - an expense with a blank description is rejected by the database
  - a sale with no description saves as `sales_goods`
  - DELETE on `ledger_entry` throws (append-only trigger)
  - a sale with an expense category is rejected (category-kind trigger)
- One widget test: the expense screen's Save button stays disabled until amount, description and
  category are all valid.

## 12. Schema (use verbatim)

This is the dissertation's `schema.sql`, tested against SQLite (12 constraint tests pass). Save it
as `lib/data/schema.sql` for reference and build `schema.drift` from it. Do not change columns,
constraints, triggers or views. Tables not used by the prototype (`product`, `entry_item`,
`stock_adjustment`) are still created, so the prototype runs on the real schema.

```sql
-- =====================================================================
-- SFM-LCP on-device database (SQLite, implemented with Drift)
-- Logical/physical design for Chapter 3, Section 3.7.2
-- Conventions:
--   * Primary keys are UUID v4 strings generated on the phone, so records
--     created offline never collide with records from other devices and
--     retries are idempotent on the server (NFR4).
--   * Money is stored as INTEGER ngwee (1 ZMW = 100 ngwee). Floating point
--     cannot represent 0.10 exactly, so REAL would accumulate rounding error.
--   * Timestamps are INTEGER milliseconds since 1970-01-01 UTC.
--   * Ledger entries are append-only: a mistake is corrected by a reversal
--     entry, never by editing or deleting the original.
-- =====================================================================
PRAGMA foreign_keys = ON;

CREATE TABLE business (
  id               TEXT    PRIMARY KEY,
  participant_code TEXT    NOT NULL UNIQUE CHECK (length(participant_code) BETWEEN 4 AND 12),
  business_type    TEXT,
  created_at       INTEGER NOT NULL
);

CREATE TABLE category (
  code       TEXT    PRIMARY KEY,
  name       TEXT    NOT NULL,
  kind       TEXT    NOT NULL CHECK (kind IN ('income', 'expense')),
  icon       TEXT    NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE product (
  id               TEXT    PRIMARY KEY,
  business_id      TEXT    NOT NULL REFERENCES business(id),
  name             TEXT    NOT NULL CHECK (length(trim(name)) > 0),
  unit_price_ngwee INTEGER NOT NULL CHECK (unit_price_ngwee >= 0),
  reorder_level    INTEGER NOT NULL DEFAULT 0 CHECK (reorder_level >= 0),
  is_active        INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  UNIQUE (business_id, name)
);

CREATE TABLE ledger_entry (
  id                  TEXT    PRIMARY KEY,
  business_id         TEXT    NOT NULL REFERENCES business(id),
  entry_type          TEXT    NOT NULL CHECK (entry_type IN ('sale', 'expense')),
  amount_ngwee        INTEGER NOT NULL,
  description         TEXT    NOT NULL DEFAULT '' CHECK (length(description) <= 120),
  payment_method      TEXT    NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'mobile_money')),
  predicted_category  TEXT    REFERENCES category(code),
  category_confidence REAL    CHECK (category_confidence BETWEEN 0 AND 1),
  final_category      TEXT    NOT NULL REFERENCES category(code),
  model_version       TEXT,
  anomaly_score       REAL,
  anomaly_flag        INTEGER NOT NULL DEFAULT 0 CHECK (anomaly_flag IN (0, 1)),
  anomaly_reviewed_at INTEGER,
  reverses_id         TEXT    UNIQUE REFERENCES ledger_entry(id),
  occurred_at         INTEGER NOT NULL,
  created_at          INTEGER NOT NULL,
  updated_at          INTEGER NOT NULL,
  -- an expense must say what it was for (FR2); a sale may rely on its items
  CHECK (entry_type = 'sale' OR length(trim(description)) > 0),
  -- originals are positive; reversals are negative and point at the original
  CHECK ((reverses_id IS NULL AND amount_ngwee > 0) OR (reverses_id IS NOT NULL AND amount_ngwee < 0)),
  -- a prediction and its confidence are stored together or not at all
  CHECK ((predicted_category IS NULL) = (category_confidence IS NULL)),
  CHECK (anomaly_flag = 0 OR anomaly_score IS NOT NULL)
);

CREATE TABLE entry_item (
  id               TEXT    PRIMARY KEY,
  entry_id         TEXT    NOT NULL REFERENCES ledger_entry(id),
  product_id       TEXT    NOT NULL REFERENCES product(id),
  quantity         INTEGER NOT NULL CHECK (quantity <> 0),
  unit_price_ngwee INTEGER NOT NULL CHECK (unit_price_ngwee >= 0),
  UNIQUE (entry_id, product_id)
);

CREATE TABLE stock_adjustment (
  id             TEXT    PRIMARY KEY,
  product_id     TEXT    NOT NULL REFERENCES product(id),
  quantity_delta INTEGER NOT NULL CHECK (quantity_delta <> 0),
  reason         TEXT    NOT NULL CHECK (reason IN ('opening', 'count', 'damage', 'other')),
  created_at     INTEGER NOT NULL
);

CREATE TABLE sync_record (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_table    TEXT    NOT NULL CHECK (entity_table IN ('business', 'product', 'ledger_entry', 'entry_item', 'stock_adjustment')),
  entity_id       TEXT    NOT NULL,
  operation       TEXT    NOT NULL CHECK (operation IN ('insert', 'update')),
  status          TEXT    NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_flight', 'acked', 'failed')),
  attempts        INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  last_error      TEXT,
  created_at      INTEGER NOT NULL,
  last_attempt_at INTEGER,
  acked_at        INTEGER,
  CHECK ((status = 'acked') = (acked_at IS NOT NULL))
);

-- ---------------------------------------------------------------- indexes
CREATE INDEX ix_entry_business_time ON ledger_entry (business_id, occurred_at);
CREATE INDEX ix_entry_category      ON ledger_entry (final_category);
CREATE INDEX ix_item_entry          ON entry_item (entry_id);
CREATE INDEX ix_item_product        ON entry_item (product_id);
CREATE INDEX ix_adjust_product      ON stock_adjustment (product_id);
CREATE INDEX ix_sync_queue          ON sync_record (status, id);

-- ------------------------------------------------- append-only enforcement
CREATE TRIGGER trg_entry_no_delete BEFORE DELETE ON ledger_entry
BEGIN SELECT RAISE(ABORT, 'ledger entries are append-only: post a reversal'); END;

CREATE TRIGGER trg_entry_no_financial_update
BEFORE UPDATE OF business_id, entry_type, amount_ngwee, payment_method, reverses_id, occurred_at, created_at ON ledger_entry
BEGIN SELECT RAISE(ABORT, 'financial fields are immutable: post a reversal'); END;

CREATE TRIGGER trg_item_no_change BEFORE UPDATE ON entry_item
BEGIN SELECT RAISE(ABORT, 'entry items are immutable'); END;

CREATE TRIGGER trg_item_no_delete BEFORE DELETE ON entry_item
BEGIN SELECT RAISE(ABORT, 'entry items are immutable'); END;

CREATE TRIGGER trg_reversal_matches BEFORE INSERT ON ledger_entry
WHEN NEW.reverses_id IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'reversal must cancel the original exactly')
  WHERE NOT EXISTS (SELECT 1 FROM ledger_entry o
                    WHERE o.id = NEW.reverses_id AND o.reverses_id IS NULL
                      AND o.entry_type = NEW.entry_type
                      AND o.amount_ngwee = -NEW.amount_ngwee
                      AND o.business_id = NEW.business_id);
END;

-- ------------------------------- outbox: every change queued atomically
-- Triggers run inside the same SQLite transaction as the write, so a record
-- can never be saved without also being queued for sync (FR9, NFR4).
CREATE TRIGGER trg_q_business_ins AFTER INSERT ON business
BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES ('business', NEW.id, 'insert', NEW.created_at); END;
CREATE TRIGGER trg_q_product_ins AFTER INSERT ON product
BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES ('product', NEW.id, 'insert', NEW.created_at); END;
CREATE TRIGGER trg_q_product_upd AFTER UPDATE ON product
BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES ('product', NEW.id, 'update', NEW.updated_at); END;
CREATE TRIGGER trg_q_entry_ins AFTER INSERT ON ledger_entry
BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES ('ledger_entry', NEW.id, 'insert', NEW.created_at); END;
CREATE TRIGGER trg_q_entry_upd AFTER UPDATE ON ledger_entry
BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES ('ledger_entry', NEW.id, 'update', NEW.updated_at); END;
CREATE TRIGGER trg_q_item_ins AFTER INSERT ON entry_item
BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at)
      VALUES ('entry_item', NEW.id, 'insert', (SELECT created_at FROM ledger_entry WHERE id = NEW.entry_id)); END;
CREATE TRIGGER trg_q_adjust_ins AFTER INSERT ON stock_adjustment
BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES ('stock_adjustment', NEW.id, 'insert', NEW.created_at); END;

-- ------------------------------------------- derived data as views (3NF)
-- Stock is derived, not stored, so it can never disagree with the ledger.
-- Sale items reduce stock; items on an expense (stock purchase) increase it.
CREATE VIEW v_stock_level AS
SELECT p.id AS product_id, p.business_id, p.name, p.reorder_level,
       COALESCE((SELECT SUM(CASE e.entry_type WHEN 'expense' THEN i.quantity ELSE -i.quantity END)
                 FROM entry_item i JOIN ledger_entry e ON e.id = i.entry_id
                 WHERE i.product_id = p.id), 0)
     + COALESCE((SELECT SUM(a.quantity_delta) FROM stock_adjustment a WHERE a.product_id = p.id), 0)
       AS stock_qty
FROM product p WHERE p.is_active = 1;

CREATE VIEW v_low_stock AS
SELECT * FROM v_stock_level WHERE stock_qty <= reorder_level;

-- Daily totals for FR5 (Lusaka is UTC+2 all year, no daylight saving).
CREATE VIEW v_daily_summary AS
SELECT business_id,
       date(occurred_at / 1000, 'unixepoch', '+2 hours') AS day,
       SUM(CASE WHEN entry_type = 'sale'    THEN amount_ngwee ELSE 0 END) AS income_ngwee,
       SUM(CASE WHEN entry_type = 'expense' THEN amount_ngwee ELSE 0 END) AS expense_ngwee,
       SUM(CASE WHEN entry_type = 'sale' THEN amount_ngwee ELSE -amount_ngwee END) AS profit_ngwee
FROM ledger_entry
GROUP BY business_id, day;

-- The confirmed category must be of the right kind (no 'airtime' on a sale).
CREATE TRIGGER trg_category_kind BEFORE INSERT ON ledger_entry
BEGIN
  SELECT RAISE(ABORT, 'category kind does not match entry type')
  WHERE (SELECT kind FROM category WHERE code = NEW.final_category)
        <> CASE NEW.entry_type WHEN 'sale' THEN 'income' ELSE 'expense' END;
END;
```

## 13. Final checklist (all must be true)

- [ ] `grep -rniE "todo|fixme|unimplemented|lorem|placeholder" prototype/` returns nothing
- [ ] No counter-app or template remnants; no unused dependencies
- [ ] `flutter analyze` clean; all tests pass, including parity
- [ ] The release APK installs on a physical phone and works in airplane mode end to end
- [ ] A saved expense shows predicted and final category in the database (verify with a test or the debug query in the README)
- [ ] Money is never a `double` anywhere in the code path
- [ ] Nothing outside `prototype/` changed; `CLAUDE.md` untouched
- [ ] `DECISIONS.md` lists every choice not specified here
