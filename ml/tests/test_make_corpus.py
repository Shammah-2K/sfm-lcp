"""Checks for make_corpus.py.  Run: python -m pytest ml/tests"""

import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import make_corpus as mc  # noqa: E402


def test_reproducible_byte_for_byte(tmp_path):
    a, b = tmp_path / "a.csv", tmp_path / "b.csv"
    mc.write(mc.generate(), a)
    mc.write(mc.generate(), b)
    assert a.read_bytes() == b.read_bytes()


def test_every_codebook_category_has_rows_with_the_right_kind():
    rows = mc.generate()
    kinds = mc.codebook()
    assert {r["category"] for r in rows} == set(kinds)
    assert all(r["kind"] == kinds[r["category"]] for r in rows)


def test_no_slot_left_unfilled_and_no_empty_rows():
    rows = mc.generate()
    assert all(r["text"].strip() for r in rows)
    assert not any("{" in r["text"] or "}" in r["text"] for r in rows)


def test_no_exact_duplicates_within_a_template():
    rows = mc.generate()
    pairs = [(r["template_id"], r["text"]) for r in rows]
    assert len(pairs) == len(set(pairs))


def test_unreviewed_templates_are_marked_draft():
    spec = mc.load_templates()
    rows = mc.generate(spec)
    expected = spec["version"] + ("" if spec.get("reviewed") else "-draft")
    assert {r["provenance"] for r in rows} == {expected}


def test_each_slot_occurrence_is_filled_independently():
    rng = random.Random(1)
    seen = {mc.fill("{x} and {x}", {"x": ["a", "b", "c", "d"]}, rng) for _ in range(50)}
    assert any(s.split(" and ")[0] != s.split(" and ")[1] for s in seen)


def test_typo_never_changes_the_first_character():
    rng = random.Random(3)
    for _ in range(2000):
        out = mc.typo("transport", rng)
        assert out[0] == "t" and out != "" and abs(len(out) - 9) <= 1


def test_unknown_slot_is_rejected(tmp_path):
    bad = tmp_path / "t.yaml"
    spec = mc.load_templates()
    spec["categories"]["food"] = ["lunch with {nobody}"]
    import yaml
    bad.write_text(yaml.safe_dump(spec), encoding="utf-8")
    try:
        mc.load_templates(bad)
    except SystemExit as e:
        assert "unknown slot" in str(e)
    else:
        raise AssertionError("unknown slot accepted")
