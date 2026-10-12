"""Generate the synthetic transaction-description corpus for the SFM-LCP prototype.

THIS CORPUS IS FOR THE THROWAWAY PROTOTYPE ONLY. It must not be used in the dissertation
evaluation: it is template-generated, so a model scored on it measures how well it learned
the templates, not how well it handles real MSME descriptions.

Output: data/corpus.csv with columns text, category, kind, template_id, provenance.
Deterministic: seed 42, fixed iteration order, LF line endings, so reruns are byte-identical.

    python make_corpus.py
"""

import csv
import random
from pathlib import Path

SEED = 42
SAMPLES_PER_TEMPLATE = 120
TYPO_RATE = 0.30
CASE_RATE = 0.10
PROVENANCE = "template-v1"

OUT = Path(__file__).parent / "data" / "corpus.csv"

ITEMS = [
    "tomatoes", "onions", "kapenta", "mealie meal", "cooking oil", "sugar", "salt", "bread",
    "eggs", "chickens", "rape", "cabbage", "soap", "chitenge", "salaula bale", "charcoal",
    "soft drinks", "biscuits", "kalembula", "groundnuts",
]
PLACES = [
    "Soweto market", "Comesa market", "Kamwala", "City market", "Chilenje", "Matero",
    "Kalingalinga", "the wholesaler", "Shoprite", "Choppies",
]
WORKERS = ["shop assistant", "helper", "cleaner", "guard", "casual worker"]
MONTHS = [
    "January", "February", "March", "April", "May", "June", "July", "August", "September",
    "October", "November", "December",
]
UNITS = ["bags", "boxes", "crates", "kg", "dozen", "packets"]

KIND = {
    "sales_goods": "income", "sales_service": "income", "other_income": "income",
    "stock": "expense", "transport": "expense", "airtime": "expense", "rent_levy": "expense",
    "utilities": "expense", "wages": "expense", "food": "expense", "other_expense": "expense",
}

TEMPLATES = {
    "stock": [
        "bought {qty} {item}", "{item} for stock", "restock {item}", "{item} from {place}",
        "order of {item}", "{qty} {item} wholesale",
    ],
    "transport": [
        "bus fare to {place}", "minibus to {place}", "taxi from {place}", "transport for goods",
        "fuel for delivery", "carrier fee at {place}",
    ],
    "airtime": [
        "MTN airtime", "Airtel talktime", "Zamtel bundle", "data bundle",
        "airtime for business phone", "internet bundle for {month}",
    ],
    "rent_levy": [
        "stall rent", "shop rent for {month}", "market levy", "council levy",
        "daily market fee at {place}", "storage fee",
    ],
    "utilities": [
        "ZESCO units", "electricity tokens", "water bill", "LWSC bill",
        "prepaid units for {month}", "solar battery charging",
    ],
    "wages": [
        "paid {worker}", "{worker} wages", "salary for {worker}", "{worker} pay for {month}",
        "weekly pay {worker}",
    ],
    "food": [
        "lunch", "breakfast at {place}", "tea and buns", "nshima and relish", "drinking water",
        "meal at the market",
    ],
    "other_expense": [
        "phone repair", "mobile money fee", "plastic bags", "receipt book", "padlock for stall",
        "bank charges",
    ],
    "sales_goods": [
        "sold {qty} {item}", "{item} sale", "customer bought {item}", "sales of {item} today",
        "{qty} {item} sold at {place}",
    ],
    "sales_service": [
        "hair braiding", "phone charging service", "tailoring job", "shoe repair",
        "printing and photocopy", "barber cut",
    ],
    "other_income": [
        "refund from supplier", "commission received", "gift from family",
        "interest from chilimba", "rent from tenant",
    ],
}


def quantity(rng: random.Random) -> str:
    return f"{rng.randint(1, 50)} {rng.choice(UNITS)} of"


def fill(template: str, rng: random.Random) -> str:
    return template.format(
        item=rng.choice(ITEMS),
        place=rng.choice(PLACES),
        worker=rng.choice(WORKERS),
        month=rng.choice(MONTHS),
        qty=quantity(rng),
    )


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


def generate() -> list[dict[str, str]]:
    rng = random.Random(SEED)
    rows = []
    for category, templates in TEMPLATES.items():
        for number, template in enumerate(templates, start=1):
            template_id = f"{category}_{number:02d}"
            seen = set()
            for _ in range(SAMPLES_PER_TEMPLATE):
                text = fill(template, rng)
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
                    "kind": KIND[category],
                    "template_id": template_id,
                    "provenance": PROVENANCE,
                })
    return rows


def main() -> None:
    rows = generate()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["text", "category", "kind", "template_id", "provenance"],
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)
    templates = sum(len(t) for t in TEMPLATES.values())
    print(f"wrote {len(rows)} rows from {templates} templates to {OUT}")


if __name__ == "__main__":
    main()
