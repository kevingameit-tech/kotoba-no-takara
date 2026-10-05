#!/usr/bin/env python3
"""Validate the lesson data in data/ before Godot loads it.

Usage:
    python3 tools/validate_data.py               # checks the repo's data/ folder
    python3 tools/validate_data.py --data-dir X  # checks another folder (used by the tests)

Exit code 0 when there are no errors (warnings are allowed), 1 otherwise.
Python 3 standard library only, so it runs anywhere without pip.
Messages are in Romanian because the whole team reads them.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterator

SCHEMA_VERSION = 1

KANA_FILES = {
    "hiragana.json": {"script": "hira", "prefix": "h_", "first": 0x3041, "last": 0x3096},
    "katakana.json": {"script": "kata", "prefix": "k_", "first": 0x30A1, "last": 0x30FA},
}
POOLS_FILE = "pools.json"
ENCOUNTERS_FILE = "encounters.json"
DIALOGUE_DIR = "dialogue"

ROWS = {"a", "k", "s", "t", "n", "h", "m", "y", "r", "w", "n_final"}
SCRIPTS = {"hira", "kata"}

ID_RE = re.compile(r"^[a-z][a-z0-9_]*$")
ROMAJI_RE = re.compile(r"^[a-z]+$")
ALT_ROMAJI_RE = re.compile(r"^[a-z']+$")

# Romanian text: comma-below letters only, and no long dashes.
# Written as escapes so this file itself never contains the forbidden characters.
FORBIDDEN_RO = {
    "\u015f": "s cu sedilă, folosește ș",
    "\u0163": "t cu sedilă, folosește ț",
    "\u015e": "S cu sedilă, folosește Ș",
    "\u0162": "T cu sedilă, folosește Ț",
    "\u2014": "linie lungă, folosește virgula sau punctul",
    "\u2013": "linie medie, folosește virgula sau punctul",
}
# Two hyphens between spaces, used instead of a dash. Built so the source stays clean.
DOUBLE_HYPHEN = " " + "-" * 2 + " "

KANA_FIELDS = {
    "id": str,
    "script": str,
    "kana": str,
    "romaji": str,
    "alt_romaji": list,
    "row": str,
    "chapter": int,
    "confusable_ids": list,
    "mnemonic": dict,
}
ENCOUNTER_FIELDS = {"chapter": int, "pool_id": str, "is_boss": bool, "enemy": str}
ENCOUNTER_OPTIONAL = {"phase2_pool_id": str}  # PROPOSAL in docs/contracts.md section 10
LINE_FIELDS = {"speaker": str, "text": dict, "ja": str, "romaji": str, "set_flag": str}

TYPE_NAMES = {
    str: "text (string)",
    int: "număr întreg",
    bool: "true/false",
    list: "listă",
    dict: "obiect",
}


class DuplicateKeyError(ValueError):
    """Raised when a JSON object repeats a key (Godot would silently keep the last one)."""


class Report:
    """Collects errors and warnings with the file they come from."""

    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, where: str, message: str) -> None:
        self.errors.append(f"EROARE  {where}: {message}")

    def warn(self, where: str, message: str) -> None:
        self.warnings.append(f"ATENȚIE {where}: {message}")

    @property
    def ok(self) -> bool:
        return not self.errors


def _type_ok(value: Any, expected: type) -> bool:
    # bool is a subclass of int in Python, but true/false is not a valid chapter.
    if expected is int:
        return isinstance(value, int) and not isinstance(value, bool)
    return isinstance(value, expected)


def _reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateKeyError(key)
        result[key] = value
    return result


def load_json(path: Path, rel: str, report: Report) -> Any | None:
    """Read one JSON file. Returns None (and records an error) when it cannot be used."""
    try:
        raw = path.read_bytes()
    except OSError as exc:
        report.error(rel, f"nu pot citi fișierul ({exc.strerror}).")
        return None
    if raw.startswith(b"\xef\xbb\xbf"):
        report.warn(rel, "fișierul începe cu BOM. Salvează-l ca UTF-8 fără BOM.")
        raw = raw[3:]
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        report.error(rel, "fișierul nu este UTF-8. Salvează-l ca UTF-8.")
        return None
    try:
        return json.loads(text, object_pairs_hook=_reject_duplicate_keys)
    except DuplicateKeyError as exc:
        report.error(rel, f"cheia „{exc}” apare de două ori în același obiect.")
    except json.JSONDecodeError as exc:
        report.error(rel, f"JSON invalid la linia {exc.lineno}, coloana {exc.colno}: {exc.msg}.")
    return None


def check_schema(data: Any, rel: str, container_key: str, container_type: type, report: Report) -> Any | None:
    """Check the top level {schema_version: 1, <container_key>: ...} and return the container."""
    if not isinstance(data, dict):
        report.error(rel, "fișierul trebuie să fie un obiect JSON { ... }.")
        return None
    version = data.get("schema_version")
    if not _type_ok(version, int) or version != SCHEMA_VERSION:
        report.error(rel, f"„schema_version” trebuie să fie {SCHEMA_VERSION}, am găsit {version!r}.")
    container = data.get(container_key)
    if not isinstance(container, container_type):
        report.error(rel, f"lipsește „{container_key}” sau nu este {TYPE_NAMES[container_type]}.")
        return None
    return container


def check_fields(obj: Any, fields: dict[str, type], where: str, report: Report,
                 optional: dict[str, type] | None = None) -> bool:
    """Required fields with the right types. Unknown fields only produce a warning."""
    if not isinstance(obj, dict):
        report.error(where, "trebuie să fie un obiect { ... }.")
        return False
    optional = optional or {}
    ok = True
    for name, expected in fields.items():
        if name not in obj:
            report.error(where, f"lipsește câmpul „{name}”.")
            ok = False
        elif not _type_ok(obj[name], expected):
            report.error(where, f"câmpul „{name}” trebuie să fie {TYPE_NAMES[expected]}.")
            ok = False
    for name, expected in optional.items():
        if name in obj and not _type_ok(obj[name], expected):
            report.error(where, f"câmpul „{name}” trebuie să fie {TYPE_NAMES[expected]}.")
            ok = False
    for name in obj:
        if name not in fields and name not in optional:
            report.warn(where, f"câmp necunoscut „{name}” (greșeală de tipar?).")
    return ok


def check_id(value: str, where: str, report: Report) -> bool:
    if not ID_RE.match(value):
        report.error(where, f"id-ul „{value}” trebuie să aibă doar litere mici, cifre și _, și să înceapă cu o literă.")
        return False
    return True


def validate_kana_file(rel: str, data: Any, rules: dict[str, Any], report: Report,
                       items_by_id: dict[str, dict[str, Any]], item_file: dict[str, str]) -> None:
    items = check_schema(data, rel, "items", list, report)
    if items is None:
        return
    seen_kana: dict[str, str] = {}
    for index, item in enumerate(items):
        label = item.get("id") if isinstance(item, dict) and isinstance(item.get("id"), str) else "?"
        where = f"{rel} items[{index}] ({label})"
        if not check_fields(item, KANA_FIELDS, where, report):
            continue
        item_id = item["id"]
        if check_id(item_id, where, report) and not item_id.startswith(rules["prefix"]):
            report.error(where, f"id-ul trebuie să înceapă cu „{rules['prefix']}”.")
        if item_id in items_by_id:
            report.error(where, f"id-ul „{item_id}” există deja în {item_file[item_id]}.")
        else:
            items_by_id[item_id] = item
            item_file[item_id] = rel

        if item["script"] not in SCRIPTS:
            report.error(where, f"„script” trebuie să fie hira sau kata, nu „{item['script']}”.")
        elif item["script"] != rules["script"]:
            report.error(where, f"în acest fișier „script” trebuie să fie „{rules['script']}”.")

        kana = item["kana"]
        if len(kana) != 1:
            report.error(where, f"„kana” trebuie să fie un singur caracter, am găsit „{kana}”.")
        elif not rules["first"] <= ord(kana) <= rules["last"]:
            report.error(where, f"„{kana}” nu este {'hiragana' if rules['script'] == 'hira' else 'katakana'}.")
        elif kana in seen_kana:
            report.error(where, f"„{kana}” apare deja la {seen_kana[kana]}.")
        else:
            seen_kana[kana] = item_id

        if not ROMAJI_RE.match(item["romaji"]):
            report.error(where, f"„romaji” trebuie să aibă doar litere mici a-z, am găsit „{item['romaji']}”.")
        alt_seen: set[str] = set()
        for alt in item["alt_romaji"]:
            if not isinstance(alt, str) or not ALT_ROMAJI_RE.match(alt):
                report.error(where, f"„alt_romaji” conține o valoare greșită: {alt!r}.")
            elif alt == item["romaji"] or alt in alt_seen:
                report.warn(where, f"„alt_romaji” repetă „{alt}”.")
            else:
                alt_seen.add(alt)

        if item["row"] not in ROWS:
            report.error(where, f"rândul „{item['row']}” nu există. Valori bune: {', '.join(sorted(ROWS))}.")
        if item["chapter"] < 1:
            report.error(where, "„chapter” trebuie să fie 1 sau mai mare.")

        for cid in item["confusable_ids"]:
            if not isinstance(cid, str):
                report.error(where, f"„confusable_ids” trebuie să conțină doar id-uri text, am găsit {cid!r}.")
            elif cid == item_id:
                report.error(where, "un kana nu poate fi confundabil cu el însuși.")

        mnemonic = item["mnemonic"]
        for lang in ("ro", "en"):
            if not isinstance(mnemonic.get(lang), str):
                report.error(where, f"„mnemonic.{lang}” trebuie să existe și să fie text (poate fi gol).")


def validate_confusables(items_by_id: dict[str, dict[str, Any]], item_file: dict[str, str], report: Report) -> None:
    """Runs after all kana files are read, so ids from both scripts are known."""
    for item_id, item in items_by_id.items():
        where = f"{item_file[item_id]} ({item_id})"
        for cid in item["confusable_ids"]:
            if not isinstance(cid, str) or cid == item_id:
                continue
            other = items_by_id.get(cid)
            if other is None:
                report.error(where, f"„confusable_ids” trimite la „{cid}”, care nu există.")
            elif item_id not in other["confusable_ids"]:
                report.warn(where, f"„{cid}” nu are „{item_id}” în confusable_ids (perechea nu e simetrică).")


def validate_pools(rel: str, data: Any, items_by_id: dict[str, Any], report: Report) -> set[str]:
    pools = check_schema(data, rel, "pools", dict, report)
    if pools is None:
        return set()
    for pool_id, pool in pools.items():
        where = f"{rel} pools.{pool_id}"
        check_id(pool_id, where, report)
        if not check_fields(pool, {"items": list}, where, report):
            continue
        if not pool["items"]:
            report.error(where, "pool-ul este gol.")
        seen: set[str] = set()
        for ref in pool["items"]:
            if not isinstance(ref, str):
                report.error(where, f"„items” trebuie să conțină doar id-uri text, am găsit {ref!r}.")
                continue
            if ref in seen:
                report.error(where, f"„{ref}” apare de două ori.")
            elif ref not in items_by_id:
                report.error(where, f"„{ref}” nu există în hiragana.json sau katakana.json.")
            seen.add(ref)
    return set(pools)


def validate_encounters(rel: str, data: Any, pool_ids: set[str], report: Report) -> None:
    encounters = check_schema(data, rel, "encounters", dict, report)
    if encounters is None:
        return
    for enc_id, enc in encounters.items():
        where = f"{rel} encounters.{enc_id}"
        check_id(enc_id, where, report)
        if not check_fields(enc, ENCOUNTER_FIELDS, where, report, ENCOUNTER_OPTIONAL):
            continue
        if enc["chapter"] < 1:
            report.error(where, "„chapter” trebuie să fie 1 sau mai mare.")
        for key in ("pool_id", "phase2_pool_id"):
            if key in enc and enc[key] not in pool_ids:
                report.error(where, f"pool-ul „{enc[key]}” din „{key}” nu există în {POOLS_FILE}.")
        enemy = enc["enemy"]
        if not enemy.startswith("res://"):
            report.error(where, f"„enemy” trebuie să înceapă cu res://, am găsit „{enemy}”.")
        elif not enemy.endswith(".tres"):
            report.warn(where, f"„enemy” ar trebui să fie un fișier .tres, am găsit „{enemy}”.")


def validate_dialogue(rel: str, data: Any, report: Report, dialogue_file: dict[str, str]) -> None:
    dialogues = check_schema(data, rel, "dialogues", dict, report)
    if dialogues is None:
        return
    for dlg_id, lines in dialogues.items():
        where = f"{rel} dialogues.{dlg_id}"
        check_id(dlg_id, where, report)
        if dlg_id in dialogue_file:
            report.error(where, f"dialogul „{dlg_id}” există deja în {dialogue_file[dlg_id]}.")
        else:
            dialogue_file[dlg_id] = rel
        if not isinstance(lines, list) or not lines:
            report.error(where, "un dialog trebuie să fie o listă cu cel puțin o replică.")
            continue
        for index, line in enumerate(lines):
            line_where = f"{where}[{index}]"
            if not check_fields(line, LINE_FIELDS, line_where, report):
                continue
            if not line["speaker"].strip():
                report.error(line_where, "„speaker” este gol.")
            for lang in ("ro", "en"):
                value = line["text"].get(lang)
                if not isinstance(value, str) or not value.strip():
                    report.error(line_where, f"lipsește textul „text.{lang}” sau este gol.")
            if line["set_flag"] and not ID_RE.match(line["set_flag"]):
                report.error(line_where, f"„set_flag” are un nume greșit: „{line['set_flag']}”.")


def iter_ro_texts(node: Any, path: str = "") -> Iterator[tuple[str, str]]:
    """Yield (path, text) for every string stored under a key named "ro"."""
    if isinstance(node, dict):
        for key, value in node.items():
            child = f"{path}.{key}" if path else key
            if key == "ro" and isinstance(value, str):
                yield child, value
            else:
                yield from iter_ro_texts(value, child)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from iter_ro_texts(value, f"{path}[{index}]")


def check_romanian(rel: str, data: Any, report: Report) -> None:
    for path, text in iter_ro_texts(data):
        for char, name in FORBIDDEN_RO.items():
            if char in text:
                report.error(f"{rel} {path}", f"textul românesc conține „{char}” ({name}).")
        if DOUBLE_HYPHEN in text:
            report.error(f"{rel} {path}", "textul românesc conține două cratime în loc de o linie. Folosește virgula sau punctul.")


def validate(data_dir: Path) -> Report:
    """Validate every JSON file under data_dir and return the report."""
    report = Report()
    data_dir = Path(data_dir)
    if not data_dir.is_dir():
        report.error(str(data_dir), "folderul de date nu există.")
        return report

    folder = data_dir.name
    loaded: dict[str, tuple[str, Any]] = {}
    for path in sorted(data_dir.rglob("*.json")):
        rel = path.relative_to(data_dir.parent).as_posix()
        data = load_json(path, rel, report)
        if data is not None:
            loaded[path.relative_to(data_dir).as_posix()] = (rel, data)
            check_romanian(rel, data, report)

    items_by_id: dict[str, dict[str, Any]] = {}
    item_file: dict[str, str] = {}
    for name, rules in KANA_FILES.items():
        if not (data_dir / name).exists():
            report.error(f"{folder}/{name}", "fișierul lipsește.")
        elif name in loaded:
            rel, data = loaded[name]
            validate_kana_file(rel, data, rules, report, items_by_id, item_file)
    validate_confusables(items_by_id, item_file, report)

    pool_ids: set[str] = set()
    if not (data_dir / POOLS_FILE).exists():
        report.error(f"{folder}/{POOLS_FILE}", "fișierul lipsește.")
    elif POOLS_FILE in loaded:
        rel, data = loaded[POOLS_FILE]
        pool_ids = validate_pools(rel, data, items_by_id, report)

    if not (data_dir / ENCOUNTERS_FILE).exists():
        report.error(f"{folder}/{ENCOUNTERS_FILE}", "fișierul lipsește.")
    elif ENCOUNTERS_FILE in loaded:
        rel, data = loaded[ENCOUNTERS_FILE]
        validate_encounters(rel, data, pool_ids, report)

    dialogue_file: dict[str, str] = {}
    known = set(KANA_FILES) | {POOLS_FILE, ENCOUNTERS_FILE}
    for name in sorted(loaded):
        rel, data = loaded[name]
        if name.startswith(DIALOGUE_DIR + "/"):
            validate_dialogue(rel, data, report, dialogue_file)
        elif name not in known:
            report.warn(rel, "fișier fără reguli în validator. Verific doar că JSON-ul e corect.")
            if isinstance(data, dict) and data.get("schema_version") != SCHEMA_VERSION:
                report.error(rel, f"„schema_version” trebuie să fie {SCHEMA_VERSION}.")
    return report


def main(argv: list[str] | None = None) -> int:
    default_dir = Path(__file__).resolve().parent.parent / "data"
    parser = argparse.ArgumentParser(description="Verifică fișierele JSON din data/.")
    parser.add_argument("--data-dir", type=Path, default=default_dir, help="folderul cu date (implicit: data/)")
    args = parser.parse_args(argv)

    report = validate(args.data_dir)
    for line in report.errors + report.warnings:
        print(line)
    if report.ok:
        print(f"Gata: datele sunt corecte. 0 erori, {len(report.warnings)} avertismente.")
        return 0
    print(f"Datele au probleme: {len(report.errors)} erori, {len(report.warnings)} avertismente.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
