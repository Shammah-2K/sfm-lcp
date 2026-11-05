"""Generate the synthetic transaction-description corpus for the categoriser (FR3).

Reads templates/categoriser_templates.yaml and writes data/processed/corpus.csv with
columns text, category, kind, template_id, provenance.

Template-generated only, no LLM-generated rows: every row is a template filled from
word lists, with seeded noise (typos, case, an amount typed in). The templates and word
lists were drafted with AI assistance and are reviewed by the researcher; until the
YAML says `reviewed: true`, the provenance of every row ends in `-draft`.

Deterministic: seed 42, fixed iteration order, LF line endings, so reruns are
byte-identical (tests/test_make_corpus.py checks this).

Claim limits (Chapter 3, Dataset Construction): this corpus is valid for efficiency
measurement and as training scaffolding. Accuracy measured on it describes how well a
model generalises to unseen *templates*, not to real trader descriptions.

    python make_corpus.py
"""

from __future__ import annotations

import csv
import random
import re
from pathlib import Path

import yaml

HERE = Path(__file__).parent
TEMPLATES = HERE / "templates" / "categoriser_templates.yaml"
OUT = HERE / "data" / "processed" / "corpus.csv"
# The codebook as the server stores it; server_contract_test.dart checks it equals the app's.
CODEBOOK_SQL = HERE.parent / "backend" / "supabase" / "migrations" / "20261027000000_sync.sql"

SEED = 42
SAMPLES_PER_TEMPLATE = 120
TYPO_RATE = 0.30
CASE_RATE = 0.10
AMOUNT_RATE = 0.10
FIELDS = ["text", "category", "kind", "template_id", "provenance"]

_SLOT = re.compile(r"\{(\w+)\}")


def codebook() -> dict[str, str]:
    """Category code -> kind (income/expense), read from the server migration."""
    sql = CODEBOOK_SQL.read_text(encoding="utf-8")
    rows = re.findall(r"\('(\w+)',\s*'[^']+',\s*'(income|expense)'", sql)
    if not rows:
        raise SystemExit(f"no categories found in {CODEBOOK_SQL}")
    return dict(rows)


def load_templates(path: Path = TEMPLATES) -> dict:
    spec = yaml.safe_load(path.read_text(encoding="utf-8"))
    kinds = codebook()
    categories = spec["categories"]
    if set(categories) != set(kinds):
        raise SystemExit(
            f"template categories {sorted(categories)} differ from the codebook {sorted(kinds)}"
        )
    for category, templates in categories.items():
        for template in templates:
            for slot in _SLOT.findall(template):
                if slot not in spec["slots"]:
                    raise SystemExit(f"{category}: unknown slot {{{slot}}} in {template!r}")
    return spec


def fill(template: str, slots: dict[str, list[str]], rng: random.Random) -> str:
    """Each {slot} occurrence gets its own random value."""
    return _SLOT.sub(lambda m: str(rng.choice(slots[m.group(1)])), template)


def typo(text: str, rng: random.Random) -> str:
    """One drop, adjacent swap or duplication, never touching the first character."""
    if len(text) < 3:
        return text
    kind = rng.choice(("drop", "swap", "duplicate"))
    if kind == "drop":
        i = rng.randrange(1, len(text))
        return text[:i] + text[i + 1:]
    if kind == "swap":
        i = rng.randrange(1, len(text) - 1)
        return text[:i] + text[i + 1] + text[i] + text[i + 2:]
    i = rng.randrange(1, len(text))
    return text[:i] + text[i] + text[i:]


def randomise_case(text: str, rng: random.Random) -> str:
    style = rng.choice(("upper", "title", "mixed"))
    if style == "upper":
        return text.upper()
    if style == "title":
        return text.title()
    return "".join(c.upper() if rng.random() < 0.5 else c.lower() for c in text)


def with_amount(text: str, amounts: list[str], rng: random.Random) -> str:
    """Traders sometimes type the amount into the description too."""
    amount = rng.choice(amounts)
    return f"{text} {amount}" if rng.random() < 0.5 else f"{amount} {text}"


def generate(spec: dict | None = None) -> list[dict[str, str]]:
    spec = spec or load_templates()
    kinds = codebook()
    provenance = spec["version"] + ("" if spec.get("reviewed") else "-draft")
    slots = spec["slots"]
    rng = random.Random(SEED)
    rows = []
    for category in sorted(spec["categories"]):
        for number, template in enumerate(spec["categories"][category], start=1):
            template_id = f"{category}_{number:02d}"
            seen = set()
            for _ in range(SAMPLES_PER_TEMPLATE):
                text = fill(template, slots, rng)
                if rng.random() < AMOUNT_RATE:
                    text = with_amount(text, slots["amount"], rng)
                if rng.random() < TYPO_RATE:
                    text = typo(text, rng)
                if rng.random() < CASE_RATE:
                    text = randomise_case(text, rng)
                if text in seen:
                    continue
                seen.add(text)
                rows.append({
                    "text": text,
                    "category": category,
                    "kind": kinds[category],
                    "template_id": template_id,
                    "provenance": provenance,
                })
    return rows


def write(rows: list[dict[str, str]], out: Path = OUT) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    spec = load_templates()
    rows = generate(spec)
    write(rows)
    templates = sum(len(t) for t in spec["categories"].values())
    print(f"wrote {len(rows)} rows from {templates} templates "
          f"({rows[0]['provenance']}) to {OUT.relative_to(HERE)}")
    if not spec.get("reviewed"):
        print("NOTE: templates not yet reviewed by the researcher; rows are marked -draft")


if __name__ == "__main__":
    main()
