#!/usr/bin/env python3
"""Unit tests for tools/analyze_logs.py (standard library unittest, no pytest).

Run:
    python3 tools/test_analyze_logs.py

All events here are made up for the tests. Real playtest logs never enter the repo.
"""

from __future__ import annotations

import contextlib
import csv
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))

import analyze_logs as al  # noqa: E402  (imported after the path change on purpose)

CSV_COLUMNS = ["received_at", "v", "build", "sid", "t_ms", "platform", "lang", "event", "data"]


def ev(sid: str, t_ms: int, event: str, build: str = "0.1.0", **data: Any) -> dict[str, Any]:
    return {"v": 1, "build": build, "sid": sid, "t_ms": t_ms, "platform": "web_desktop",
            "lang": "ro", "event": event, "data": data}


def answer(sid: str, t_ms: int, item: str, correct: bool, ms: int = 3000, chosen: str = "",
           mode: str = "choice") -> dict[str, Any]:
    return ev(sid, t_ms, "answer", encounter_id="c1_kappa_1", qid=f"q_{t_ms:04d}", item_id=item,
              mode=mode, correct=correct, elapsed_ms=ms, chosen=chosen)


def posttest(sid: str, form: str, score: int, pre_form: str, pre_score: int) -> dict[str, Any]:
    return ev(sid, 900, "posttest", form=form, score=score, n_items=10, pre_form=pre_form, pre_score=pre_score)


def sample_events() -> list[dict[str, Any]]:
    """s1 finishes chapter 1, s2 stops in the town, s3 stops in a battle."""
    return [
        ev("s1", 0, "session_start"),
        ev("s1", 10, "pretest", form="A", score=4, n_items=10),
        answer("s1", 20, "h_ki", False, ms=2000, chosen="sa"),
        answer("s1", 30, "h_ki", True, ms=3000),
        answer("s1", 40, "h_nu", False, ms=4000, chosen="me"),
        answer("s1", 50, "h_ki", True, ms=5000),
        posttest("s1", "B", 7, "A", 4),
        ev("s2", 0, "session_start"),
        answer("s2", 10, "h_nu", True, ms=70_000),
        ev("s2", 20, "quit", scene="tokyo_town"),
        ev("s3", 0, "session_start"),
        ev("s3", 10, "pretest", form="B", score=6, n_items=10),
        ev("s3", 20, "quit", scene="battle_scene"),
    ]


def write_jsonl(path: Path, rows: list[Any]) -> Path:
    path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8")
    return path


def write_csv(path: Path, events: list[dict[str, Any]]) -> Path:
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(CSV_COLUMNS)
        for e in events:
            writer.writerow(["2026-11-09T18:00:00Z", e["v"], e["build"], e["sid"], e["t_ms"], e["platform"],
                             e["lang"], e["event"], json.dumps(e["data"], ensure_ascii=False)])
    return path


KANA_ITEMS = [
    {"id": "h_ki", "script": "hira", "kana": "き", "romaji": "ki"},
    {"id": "h_sa", "script": "hira", "kana": "さ", "romaji": "sa"},
    {"id": "h_nu", "script": "hira", "kana": "ぬ", "romaji": "nu"},
    {"id": "h_me", "script": "hira", "kana": "め", "romaji": "me"},
    {"id": "k_ki", "script": "kata", "kana": "キ", "romaji": "ki"},
    {"id": "k_sa", "script": "kata", "kana": "サ", "romaji": "sa"},
]
KANA = {i["id"]: {"kana": i["kana"], "romaji": i["romaji"], "script": i["script"]} for i in KANA_ITEMS}


def write_kana(folder: Path) -> Path:
    for name, script in (("hiragana.json", "hira"), ("katakana.json", "kata")):
        items = [i for i in KANA_ITEMS if i["script"] == script]
        (folder / name).write_text(json.dumps({"schema_version": 1, "items": items}), encoding="utf-8")
    return folder


class TempDirTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()


class ReadEventsTest(TempDirTest):
    def test_jsonl_and_csv_give_the_same_events(self) -> None:
        from_jsonl, skipped_jsonl = al.read_events(write_jsonl(self.dir / "e.jsonl", sample_events()))
        from_csv, skipped_csv = al.read_events(write_csv(self.dir / "e.csv", sample_events()))
        self.assertEqual(len(from_jsonl), len(sample_events()))
        self.assertEqual(from_jsonl, from_csv)
        self.assertFalse(skipped_jsonl)
        self.assertFalse(skipped_csv)

    def test_bad_rows_are_counted_and_skipped(self) -> None:
        wrong_version = ev("s1", 1, "session_start")
        wrong_version["v"] = 2
        no_sid = ev("", 2, "session_start")
        path = self.dir / "bad.jsonl"
        lines = [
            json.dumps(ev("s1", 0, "session_start")),
            "acesta nu e JSON",
            json.dumps([1, 2]),
            json.dumps(wrong_version),
            json.dumps(ev("s1", 3, "jump")),
            json.dumps(no_sid),
            json.dumps(answer("s1", 4, "h_ki", True) | {"data": {"item_id": "h_ki", "correct": "da"}}),
            json.dumps(ev("s1", 5, "pretest", form="C", score=3, n_items=10)),
        ]
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        events, skipped = al.read_events(path)
        self.assertEqual(len(events), 1)
        self.assertEqual(skipped, {"json": 2, "version": 1, "event": 1, "field": 2, "value": 1})

    def test_unknown_data_fields_are_dropped(self) -> None:
        row = answer("s1", 0, "h_ki", True)
        row["data"]["nume"] = "Ana"
        events, _ = al.read_events(write_jsonl(self.dir / "e.jsonl", [row]))
        self.assertNotIn("nume", events[0]["data"])

    def test_whole_floats_count_as_ints(self) -> None:
        whole = answer("s1", 0, "h_ki", True)
        whole["data"]["elapsed_ms"] = 3120.0
        half = answer("s1", 1, "h_ki", True)
        half["data"]["elapsed_ms"] = 3120.5
        events, skipped = al.read_events(write_jsonl(self.dir / "e.jsonl", [whole, half]))
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["data"]["elapsed_ms"], 3120)
        self.assertIsInstance(events[0]["data"]["elapsed_ms"], int)
        self.assertEqual(skipped, {"field": 1})

    def test_events_are_sorted_by_session_and_time(self) -> None:
        rows = [ev("s2", 5, "session_start"), ev("s1", 9, "quit", scene="x"), ev("s1", 1, "session_start")]
        events, _ = al.read_events(write_jsonl(self.dir / "e.jsonl", rows))
        self.assertEqual([(e["sid"], e["t_ms"]) for e in events], [("s1", 1), ("s1", 9), ("s2", 5)])


class MetricsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.events = sorted(
            (al.normalize(e)[0] for e in sample_events()), key=lambda e: (e["sid"], e["t_ms"]))

    def test_funnel_counts_each_step(self) -> None:
        f = al.funnel(self.events)
        self.assertEqual((f["sessions"], f["started"], f["pretest"], f["battle"], f["posttest"]), (3, 3, 2, 2, 1))
        self.assertEqual(f["stopped_at"], {"tokyo_town": 1, "battle_scene": 1})

    def test_item_accuracy(self) -> None:
        acc = al.item_accuracy(self.events)
        self.assertEqual(acc["h_ki"], {"n": 3, "correct": 2})
        self.assertEqual(acc["h_nu"], {"n": 2, "correct": 1})

    def test_learning_curve_counts_meetings_per_session(self) -> None:
        curve = al.learning_curve(self.events)
        self.assertEqual(curve, [
            {"exposure": 1, "n": 3, "correct": 1},
            {"exposure": 2, "n": 1, "correct": 1},
            {"exposure": 3, "n": 1, "correct": 1},
        ])

    def test_learning_curve_groups_late_meetings(self) -> None:
        events = [al.normalize(answer("s1", t, "h_ki", True))[0] for t in range(7)]
        self.assertEqual(al.learning_curve(events)[-1], {"exposure": al.MAX_EXPOSURE, "n": 3, "correct": 3})

    def test_confusions_only_wrong_choice_answers(self) -> None:
        extra = [answer("s9", 1, "h_ki", False, chosen=""), answer("s9", 2, "h_ki", False, mode="type")]
        events = self.events + [al.normalize(e)[0] for e in extra]
        self.assertEqual(al.confusions(events, KANA), [
            {"item_id": "h_ki", "chosen": "sa", "count": 1},
            {"item_id": "h_nu", "chosen": "me", "count": 1},
        ])

    def test_wrong_answer_with_the_right_reading_is_flagged(self) -> None:
        events = self.events + [al.normalize(answer("s9", 1, "h_ki", False, chosen="ki"))[0]]
        self.assertEqual(al.inconsistent_answers(events, KANA), 1)
        self.assertNotIn("ki", [c["chosen"] for c in al.confusions(events, KANA)])
        self.assertEqual(al.inconsistent_answers(self.events, KANA), 0)

    def test_answer_times_leave_out_long_pauses(self) -> None:
        times = al.answer_times(self.events)
        self.assertEqual(times["excluded"], 1)
        self.assertEqual(times["overall"], {"n": 4, "median": 3500.0, "q1": 2750.0, "q3": 4250.0})
        self.assertEqual(times["items"]["h_nu"], {"n": 1, "median": 4000})

    def test_sign_test(self) -> None:
        self.assertEqual(al.sign_test(5, 0), 0.0625)
        self.assertEqual(al.sign_test(4, 1), 0.375)
        self.assertEqual(al.sign_test(8, 1), 0.0391)
        self.assertEqual(al.sign_test(3, 3), 1.0)
        self.assertIsNone(al.sign_test(0, 0))


class PrePostTest(unittest.TestCase):
    def events(self, pairs: list[tuple[str, int, int]]) -> list[dict[str, Any]]:
        rows = []
        for i, (pre_form, pre, post) in enumerate(pairs):
            post_form = "B" if pre_form == "A" else "A"
            rows.append(posttest(f"p{i}", post_form, post, pre_form, pre))
        rows.append(posttest("x1", "A", 5, "", -1))
        rows.append(posttest("x2", "A", 5, "A", 3))
        return [al.normalize(r)[0] for r in rows]

    def test_pairs_summary(self) -> None:
        pairs = [("A", 2, 6), ("A", 4, 7), ("A", 5, 5), ("A", 3, 8), ("A", 6, 9), ("B", 10, 9)]
        result = al.pre_post(self.events(pairs))
        self.assertEqual(result["n_pairs"], 6)
        self.assertEqual(result["skipped"], {"no_pretest": 1, "same_form": 1})
        s = result["all"]
        self.assertTrue(s["reported"])
        self.assertEqual((s["pre_mean"], s["post_mean"], s["gain_mean"], s["gain_median"]), (5.0, 7.33, 2.33, 3.0))
        self.assertEqual((s["improved"], s["same"], s["worse"]), (4, 1, 1))
        self.assertEqual(s["sign_test_p"], 0.375)
        # (10 -> 9) has no room to grow, so it is left out of the normalized gain.
        self.assertEqual((s["normalized_gain_mean"], s["normalized_gain_n"]), (0.49, 5))
        self.assertTrue(result["a_then_b"]["reported"])
        self.assertEqual(result["b_then_a"], {"n": 1, "reported": False})

    def test_small_groups_are_not_reported(self) -> None:
        result = al.pre_post(self.events([("A", 2, 6), ("A", 4, 7), ("B", 5, 5), ("B", 3, 8)]))
        self.assertEqual(result["all"], {"n": 4, "reported": False})

    def test_pretest_scores_by_form(self) -> None:
        rows = [ev(f"a{i}", 1, "pretest", form="A", score=i, n_items=10) for i in range(1, 6)]
        rows += [ev(f"b{i}", 1, "pretest", form="B", score=i, n_items=10) for i in range(2)]
        by_form = al.pre_post([al.normalize(r)[0] for r in rows])["pretest_by_form"]
        self.assertEqual(by_form["A"], {"n": 5, "reported": True, "mean": 3.0, "median": 3})
        self.assertEqual(by_form["B"], {"n": 2, "reported": False})


class SusTest(TempDirTest):
    TITLES = [f"{i}. Întrebarea {i}" for i in range(1, 11)]

    def write_form(self, rows: list[tuple[str, list[str]]], titles: list[str] | None = None) -> Path:
        path = self.dir / "chestionar.csv"
        with path.open("w", encoding="utf-8-sig", newline="") as fh:
            writer = csv.writer(fh)
            writer.writerow(["Marcaj de timp", "Vârsta"] + (titles or self.TITLES))
            for age, answers in rows:
                writer.writerow(["2026/11/09 18:00:00", age] + answers)
        return path

    def test_sus_score(self) -> None:
        self.assertEqual(al.sus_score([3] * 10), 50.0)
        self.assertEqual(al.sus_score([5, 1] * 5), 100.0)
        self.assertEqual(al.sus_score([1, 5] * 5), 0.0)
        self.assertEqual(al.sus_score([4, 2] * 5), 75.0)

    def test_read_form_and_summary(self) -> None:
        good = [("18 până la 24 de ani", ["4", "2"] * 5)] * 5 + [("sub 16 ani", ["3"] * 10)]
        incomplete = [("18 până la 24 de ani", ["4"] * 9 + [""])]
        rows, n_incomplete = al.read_form(self.write_form(good + incomplete))
        self.assertEqual((len(rows), n_incomplete), (6, 1))
        sus = al.sus_summary(rows, n_incomplete)
        self.assertEqual(sus["all"]["n"], 6)
        self.assertEqual(sus["by_age"]["18 până la 24 de ani"], {"n": 5, "reported": True, "mean": 75.0, "median": 75.0})
        self.assertEqual(sus["by_age"]["sub 16 ani"], {"n": 1, "reported": False})

    def test_form_without_the_10_questions_is_an_error(self) -> None:
        path = self.write_form([("sub 16 ani", ["3"] * 9)], titles=self.TITLES[:9])
        with self.assertRaises(ValueError):
            al.read_form(path)


class MainTest(TempDirTest):
    def run_main(self, args: list[str]) -> tuple[int, str]:
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = al.main(args + ["--data-dir", str(write_kana(self.dir))])
        return code, out.getvalue()

    def test_report_and_aggregated_json(self) -> None:
        events = write_jsonl(self.dir / "e.jsonl", sample_events())
        out_json = self.dir / "docs" / "data" / "rezumat.json"
        code, text = self.run_main([str(events), "--json", str(out_json)])
        self.assertEqual(code, 0)
        self.assertIn("Evenimente valide: 13", text)
        self.assertIn("き (ki) → さ (sa): 1", text)
        self.assertIn("Mediana: 3,5 s (Q1 2,8 s, Q3 4,2 s), n=4", text)
        summary = json.loads(out_json.read_text(encoding="utf-8"))
        self.assertEqual(summary["schema"], 1)
        self.assertEqual(summary["accuracy"]["n"], 5)

    def test_json_never_holds_a_session_id(self) -> None:
        events = [ev(f"secret{i}", 1, "pretest", form="A", score=5, n_items=10) for i in range(6)]
        events += sample_events()
        out_json = self.dir / "rezumat.json"
        code, _ = self.run_main([str(write_jsonl(self.dir / "e.jsonl", events)), "--json", str(out_json)])
        self.assertEqual(code, 0)
        text = out_json.read_text(encoding="utf-8")
        self.assertNotIn("secret", text)
        self.assertNotIn('"sid"', text)
        self.assertNotIn('"s1"', text)

    def test_report_warns_about_inconsistent_answers(self) -> None:
        events = sample_events() + [answer("s9", 1, "h_ki", False, chosen="ki")]
        code, text = self.run_main([str(write_jsonl(self.dir / "e.jsonl", events))])
        self.assertEqual(code, 0)
        self.assertIn("ATENȚIE: 1 răspunsuri marcate greșit", text)
        self.assertIn("întâlnirea 1: ", text)

    def test_build_filter(self) -> None:
        events = [ev("s1", 0, "session_start", build="0.1.0"), ev("s2", 0, "session_start", build="0.2.0")]
        out_json = self.dir / "rezumat.json"
        code, text = self.run_main([str(write_jsonl(self.dir / "e.jsonl", events)), "--build", "0.2",
                                    "--json", str(out_json)])
        self.assertEqual(code, 0)
        self.assertIn("încep cu „0.2”", text)
        self.assertEqual(json.loads(out_json.read_text(encoding="utf-8"))["funnel"]["sessions"], 1)

    def test_form_adds_sus(self) -> None:
        form = self.dir / "chestionar.csv"
        with form.open("w", encoding="utf-8", newline="") as fh:
            writer = csv.writer(fh)
            writer.writerow(["Vârsta"] + SusTest.TITLES)
            for _ in range(5):
                writer.writerow(["25 până la 39 de ani"] + ["4", "2"] * 5)
        code, text = self.run_main([str(write_jsonl(self.dir / "e.jsonl", sample_events())), "--form", str(form)])
        self.assertEqual(code, 0)
        self.assertIn("Media: 75,0 din 100", text)

    def test_missing_file_and_no_valid_events(self) -> None:
        code, text = self.run_main([str(self.dir / "nu_exista.csv")])
        self.assertEqual(code, 1)
        self.assertIn("nu găsesc fișierul", text)
        empty = self.dir / "gol.jsonl"
        empty.write_text("nimic\n", encoding="utf-8")
        code, text = self.run_main([str(empty)])
        self.assertEqual(code, 1)
        self.assertIn("niciun eveniment valid", text)


if __name__ == "__main__":
    unittest.main(verbosity=1)
