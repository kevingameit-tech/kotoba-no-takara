#!/usr/bin/env python3
"""Unit tests for tools/validate_data.py (standard library unittest, no pytest).

Run:
    python3 tools/test_validate_data.py
"""

from __future__ import annotations

import contextlib
import copy
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any, Callable

sys.path.insert(0, str(Path(__file__).resolve().parent))

import validate_data  # noqa: E402  (imported after the path change on purpose)

REPO_DATA = Path(__file__).resolve().parent.parent / "data"
ENEMY = "res://battle/data/enemies/placeholder.tres"


def kana_item(item_id: str, script: str, kana: str, romaji: str, row: str, chapter: int,
              confusable_ids: list[str] | None = None) -> dict[str, Any]:
    return {
        "id": item_id,
        "script": script,
        "kana": kana,
        "romaji": romaji,
        "alt_romaji": [],
        "row": row,
        "chapter": chapter,
        "confusable_ids": confusable_ids or [],
        "mnemonic": {"ro": "", "en": ""},
    }


def good_dataset() -> dict[str, Any]:
    """A small but complete data folder that must pass with 0 errors and 0 warnings."""
    return {
        "hiragana.json": {
            "schema_version": 1,
            "items": [
                kana_item("h_a", "hira", "あ", "a", "a", 1, ["h_o"]),
                kana_item("h_o", "hira", "お", "o", "a", 1, ["h_a"]),
                kana_item("h_shi", "hira", "し", "shi", "s", 1),
            ],
        },
        "katakana.json": {
            "schema_version": 1,
            "items": [
                kana_item("k_shi", "kata", "シ", "shi", "s", 2, ["k_tsu"]),
                kana_item("k_tsu", "kata", "ツ", "tsu", "t", 2, ["k_shi"]),
            ],
        },
        "pools.json": {
            "schema_version": 1,
            "pools": {
                "c1_row_a": {"items": ["h_a", "h_o"]},
                "c2_katakana_all": {"items": ["k_shi", "k_tsu"]},
            },
        },
        "encounters.json": {
            "schema_version": 1,
            "encounters": {
                "c1_kappa_1": {"chapter": 1, "pool_id": "c1_row_a", "is_boss": False, "enemy": ENEMY},
            },
        },
        "dialogue/ch1.json": {
            "schema_version": 1,
            "dialogues": {
                "c1_intro_kenji": [
                    {
                        "speaker": "kenji",
                        "text": {"ro": "Bine ai venit în Tokyo! Ești gata?", "en": "Welcome to Tokyo!"},
                        "ja": "ようこそ！",
                        "romaji": "Youkoso!",
                        "set_flag": "",
                    }
                ]
            },
        },
    }


class ValidatorTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.data_dir = Path(self._tmp.name) / "data"

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def write(self, files: dict[str, Any]) -> None:
        for name, content in files.items():
            path = self.data_dir / name
            path.parent.mkdir(parents=True, exist_ok=True)
            if isinstance(content, str):
                path.write_text(content, encoding="utf-8")
            else:
                path.write_text(json.dumps(content, ensure_ascii=False, indent=2), encoding="utf-8")

    def run_with(self, change: Callable[[dict[str, Any]], None] | None = None) -> validate_data.Report:
        files = copy.deepcopy(good_dataset())
        if change is not None:
            change(files)
        self.write(files)
        return validate_data.validate(self.data_dir)

    def assert_error(self, report: validate_data.Report, fragment: str) -> None:
        joined = "\n".join(report.errors)
        self.assertTrue(any(fragment in e for e in report.errors),
                        f"expected an error containing {fragment!r}, got:\n{joined}")

    def assert_warning(self, report: validate_data.Report, fragment: str) -> None:
        joined = "\n".join(report.warnings)
        self.assertTrue(any(fragment in w for w in report.warnings),
                        f"expected a warning containing {fragment!r}, got:\n{joined}")


class GoodDataTests(ValidatorTestCase):
    def test_repo_data_has_no_errors(self) -> None:
        report = validate_data.validate(REPO_DATA)
        self.assertEqual(report.errors, [])

    def test_repo_kana_files_have_46_items_each(self) -> None:
        for name in ("hiragana.json", "katakana.json"):
            data = json.loads((REPO_DATA / name).read_text(encoding="utf-8"))
            self.assertEqual(len(data["items"]), 46, name)

    def test_small_good_dataset_passes_cleanly(self) -> None:
        report = self.run_with()
        self.assertEqual(report.errors, [])
        self.assertEqual(report.warnings, [])

    def test_main_returns_0_for_good_data(self) -> None:
        self.write(good_dataset())
        with contextlib.redirect_stdout(io.StringIO()):
            code = validate_data.main(["--data-dir", str(self.data_dir)])
        self.assertEqual(code, 0)


class BrokenDataTests(ValidatorTestCase):
    def test_wrong_schema_version(self) -> None:
        report = self.run_with(lambda f: f["pools.json"].update(schema_version=2))
        self.assert_error(report, "schema_version")

    def test_duplicate_id(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][2]["id"] = "h_a"
        self.assert_error(self.run_with(change), "există deja")

    def test_id_must_be_a_string(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][2]["id"] = 7
        self.assert_error(self.run_with(change), "„id”")

    def test_missing_field(self) -> None:
        def change(f: dict[str, Any]) -> None:
            del f["hiragana.json"]["items"][0]["row"]
        self.assert_error(self.run_with(change), "lipsește câmpul „row”")

    def test_kana_must_be_one_character(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][2]["kana"] = "しし"
        self.assert_error(self.run_with(change), "un singur caracter")

    def test_katakana_in_hiragana_file(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][2]["kana"] = "シ"
        self.assert_error(self.run_with(change), "nu este hiragana")

    def test_romaji_must_be_lowercase_ascii(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][2]["romaji"] = "Shi"
        self.assert_error(self.run_with(change), "litere mici")

    def test_chapter_cannot_be_bool(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][2]["chapter"] = True
        self.assert_error(self.run_with(change), "„chapter”")

    def test_unknown_confusable_id_is_an_error(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][2]["confusable_ids"] = ["h_xx"]
        self.assert_error(self.run_with(change), "„h_xx”, care nu există")

    def test_one_sided_confusable_is_only_a_warning(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][1]["confusable_ids"] = []
        report = self.run_with(change)
        self.assertEqual(report.errors, [])
        self.assert_warning(report, "nu e simetrică")

    def test_pool_with_unknown_item(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["pools.json"]["pools"]["c1_row_a"]["items"].append("h_zz")
        self.assert_error(self.run_with(change), "„h_zz” nu există")

    def test_encounter_with_unknown_pool(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["encounters.json"]["encounters"]["c1_kappa_1"]["pool_id"] = "c1_row_zz"
        self.assert_error(self.run_with(change), "„c1_row_zz” din „pool_id” nu există")

    def test_optional_phase2_pool_must_exist(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["encounters.json"]["encounters"]["c1_kappa_1"]["phase2_pool_id"] = "c1_hard"
        self.assert_error(self.run_with(change), "„c1_hard” din „phase2_pool_id”")

    def test_optional_phase2_pool_is_accepted(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["encounters.json"]["encounters"]["c1_kappa_1"]["phase2_pool_id"] = "c1_row_a"
        report = self.run_with(change)
        self.assertEqual(report.errors, [])
        self.assertEqual(report.warnings, [])

    def test_enemy_path_must_start_with_res(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["encounters.json"]["encounters"]["c1_kappa_1"]["enemy"] = "battle/enemies/kappa.tres"
        self.assert_error(self.run_with(change), "res://")

    def test_dialogue_line_without_english(self) -> None:
        def change(f: dict[str, Any]) -> None:
            del f["dialogue/ch1.json"]["dialogues"]["c1_intro_kenji"][0]["text"]["en"]
        self.assert_error(self.run_with(change), "text.en")

    def test_romanian_cedilla_is_rejected(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["dialogue/ch1.json"]["dialogues"]["c1_intro_kenji"][0]["text"]["ro"] = "E\u015fti gata?"
        self.assert_error(self.run_with(change), "sedilă")

    def test_romanian_em_dash_is_rejected(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["hiragana.json"]["items"][0]["mnemonic"]["ro"] = "a \u2014 ca un arc"
        self.assert_error(self.run_with(change), "linie lungă")

    def test_romanian_double_hyphen_is_rejected(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["dialogue/ch1.json"]["dialogues"]["c1_intro_kenji"][0]["text"]["ro"] = "Bine" + " -" + "- " + "ai venit"
        self.assert_error(self.run_with(change), "două cratime")

    def test_invalid_json_reports_the_line(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["pools.json"] = '{\n  "schema_version": 1,\n  "pools": {,}\n}\n'
        self.assert_error(self.run_with(change), "linia 3")

    def test_duplicate_json_key(self) -> None:
        def change(f: dict[str, Any]) -> None:
            f["pools.json"] = '{"schema_version": 1, "schema_version": 1, "pools": {}}'
        self.assert_error(self.run_with(change), "de două ori")

    def test_missing_required_file(self) -> None:
        def change(f: dict[str, Any]) -> None:
            del f["katakana.json"]
        self.assert_error(self.run_with(change), "katakana.json: fișierul lipsește")

    def test_main_returns_1_for_broken_data(self) -> None:
        files = good_dataset()
        files["encounters.json"]["encounters"]["c1_kappa_1"]["is_boss"] = "no"
        self.write(files)
        with contextlib.redirect_stdout(io.StringIO()) as out:
            code = validate_data.main(["--data-dir", str(self.data_dir)])
        self.assertEqual(code, 1)
        self.assertIn("EROARE", out.getvalue())


if __name__ == "__main__":
    unittest.main(verbosity=2)
