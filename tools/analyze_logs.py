#!/usr/bin/env python3
"""Summarise the playtest logs with the metrics fixed in docs/metrics.md.

Usage:
    python3 tools/analyze_logs.py events.csv
    python3 tools/analyze_logs.py events.jsonl --build 0.1 --json docs/data/rezumat_v0.1.json
    python3 tools/analyze_logs.py events.csv --form chestionar.csv

Input: the raw events exported from the log backend (docs/contracts.md, section 13),
either as JSON Lines (one event object per line) or as CSV with the columns
v, build, sid, t_ms, platform, lang, event, data, where `data` holds the event's data
object as JSON text. Other columns, such as the time the backend received the row,
are ignored. --form reads the CSV export of the feedback form (age group and the
10 SUS questions, numbered "1." to "10." in the question titles).

Raw logs never go into the repo. Only the file written with --json may go to
docs/data/: it holds aggregated numbers only, never a session id, and the scores of
groups with fewer than MIN_GROUP players are left out.

Python 3 standard library only. Messages are in Romanian because the whole team reads them.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterator

SCHEMA_VERSION = 1
MAX_ANSWER_MS = 60_000  # slower answers count for accuracy but not for time (the player was away)
MIN_GROUP = 5  # smallest group of players whose scores we report
MIN_ITEM_ANSWERS = 5  # an item needs this many answers to appear in the "hardest" list
TOP_CONFUSIONS = 10
MAX_EXPOSURE = 5  # the learning curve puts the 5th and later meetings with a kana together
FORMS = ("A", "B")
MODES = ("choice", "type")
OUTCOMES = ("win", "lose", "flee")
KANA_FILES = ("hiragana.json", "katakana.json")
REPO_DATA = Path(__file__).resolve().parent.parent / "data"

# Fields that Telemetry adds to every event (docs/contracts.md, section 13).
TOP_FIELDS: dict[str, type] = {
    "v": int,
    "build": str,
    "sid": str,
    "t_ms": int,
    "platform": str,
    "lang": str,
}
# The data fields of each event in catalog v1. Unknown extra fields are dropped.
EVENT_FIELDS: dict[str, dict[str, type]] = {
    "session_start": {},
    "chapter_enter": {"chapter": int},
    "answer": {"encounter_id": str, "qid": str, "item_id": str, "mode": str,
               "correct": bool, "elapsed_ms": int, "chosen": str},
    "battle_end": {"encounter_id": str, "outcome": str, "correct": int, "wrong": int},
    "pretest": {"form": str, "score": int, "n_items": int},
    "posttest": {"form": str, "score": int, "n_items": int, "pre_form": str, "pre_score": int},
    "quit": {"scene": str},
}
SKIP_REASONS = {
    "json": "rând care nu e JSON valid",
    "version": "versiune necunoscută (v diferit de 1)",
    "event": "eveniment necunoscut",
    "field": "câmp lipsă sau de tip greșit",
    "value": "valoare în afara celor permise",
}
POST_SKIP_REASONS = {
    "no_pretest": "fără pre-test",
    "same_form": "aceeași formă înainte și după",
}

INT_TEXT = re.compile(r"^-?\d+(?:\.0+)?$")
SUS_TITLE = re.compile(r"^\s*(\d{1,2})\.\s")
SUS_ANSWER = re.compile(r"^\s*([1-5])(?!\d)")
AGE_TITLES = ("vârsta", "varsta")


# ---------------------------------------------------------------- reading

def _as_type(value: Any, expected: type) -> tuple[bool, Any]:
    """Checks a JSON value; a whole float such as 3120.0 counts as the int 3120."""
    if expected is bool:
        return isinstance(value, bool), value
    if expected is int:
        if isinstance(value, bool):
            return False, value
        if isinstance(value, int):
            return True, value
        if isinstance(value, float) and value.is_integer():
            return True, int(value)
        return False, value
    return isinstance(value, expected), value


def _values_ok(name: str, data: dict[str, Any]) -> bool:
    if name == "answer":
        return data["mode"] in MODES and data["item_id"] != ""
    if name == "battle_end":
        return data["outcome"] in OUTCOMES and data["correct"] >= 0 and data["wrong"] >= 0
    if name == "chapter_enter":
        return data["chapter"] >= 1
    if name in ("pretest", "posttest"):
        if data["form"] not in FORMS or data["n_items"] <= 0:
            return False
        if not 0 <= data["score"] <= data["n_items"]:
            return False
    if name == "posttest":
        return data["pre_form"] in (*FORMS, "") and -1 <= data["pre_score"] <= data["n_items"]
    return True


def normalize(raw: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    """Returns (event, None) for a valid event, or (None, reason) with a key of SKIP_REASONS."""
    ok, version = _as_type(raw.get("v"), int)
    if not ok or version != SCHEMA_VERSION:
        return None, "version"
    name = raw.get("event")
    if name not in EVENT_FIELDS:
        return None, "event"
    event: dict[str, Any] = {"event": name}
    for key, expected in TOP_FIELDS.items():
        ok, value = _as_type(raw.get(key), expected)
        if not ok:
            return None, "field"
        event[key] = value
    if not event["sid"]:
        return None, "field"
    data = raw.get("data", {})
    if not isinstance(data, dict):
        return None, "field"
    clean: dict[str, Any] = {}
    for key, expected in EVENT_FIELDS[name].items():
        ok, value = _as_type(data.get(key), expected)
        if not ok:
            return None, "field"
        clean[key] = value
    if not _values_ok(name, clean):
        return None, "value"
    event["data"] = clean
    return event, None


def _from_csv_row(row: dict[str, Any]) -> dict[str, Any] | None:
    raw: dict[str, Any] = {"event": (row.get("event") or "").strip()}
    for key, expected in TOP_FIELDS.items():
        text = (row.get(key) or "").strip()
        raw[key] = int(float(text)) if expected is int and INT_TEXT.match(text) else text
    text = (row.get("data") or "").strip()
    try:
        raw["data"] = json.loads(text) if text else {}
    except json.JSONDecodeError:
        return None
    return raw


def _iter_raw(path: Path, skipped: Counter[str]) -> Iterator[dict[str, Any]]:
    # utf-8-sig: a CSV exported from Google Sheets may start with a byte order mark.
    with path.open(encoding="utf-8-sig", newline="") as fh:
        if path.suffix.lower() == ".csv":
            for row in csv.DictReader(fh):
                raw = _from_csv_row(row)
                if raw is None:
                    skipped["json"] += 1
                else:
                    yield raw
            return
        for line in fh:
            if not line.strip():
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                skipped["json"] += 1
                continue
            if isinstance(obj, dict):
                yield obj
            else:
                skipped["json"] += 1


def read_events(path: Path) -> tuple[list[dict[str, Any]], Counter[str]]:
    """Valid events sorted by session and time, plus how many rows were skipped and why."""
    skipped: Counter[str] = Counter()
    events = []
    for raw in _iter_raw(path, skipped):
        event, reason = normalize(raw)
        if reason:
            skipped[reason] += 1
        else:
            events.append(event)
    events.sort(key=lambda e: (e["sid"], e["t_ms"]))
    return events, skipped


def load_kana(data_dir: Path) -> dict[str, dict[str, str]]:
    """Item id -> {kana, romaji, script}, read from the kana files in data/."""
    items: dict[str, dict[str, str]] = {}
    for name in KANA_FILES:
        path = data_dir / name
        if not path.is_file():
            continue
        for item in json.loads(path.read_text(encoding="utf-8")).get("items", []):
            items[item["id"]] = {"kana": item["kana"], "romaji": item["romaji"], "script": item["script"]}
    return items


# ---------------------------------------------------------------- metrics

def _answers(events: list[dict[str, Any]]) -> Iterator[dict[str, Any]]:
    return (e for e in events if e["event"] == "answer")


def _mean(values: list[float]) -> float:
    return round(statistics.fmean(values), 2)


def funnel(events: list[dict[str, Any]]) -> dict[str, Any]:
    """How many sessions reach each step, and the last scene of those that never finish."""
    kinds: dict[str, set[str]] = defaultdict(set)
    last_scene: dict[str, str] = {}
    for e in events:
        kinds[e["sid"]].add(e["event"])
        if e["event"] == "quit":
            last_scene[e["sid"]] = e["data"]["scene"]
    steps = {"started": "session_start", "pretest": "pretest", "battle": "answer", "posttest": "posttest"}
    result: dict[str, Any] = {"sessions": len(kinds)}
    for key, name in steps.items():
        result[key] = sum(1 for seen in kinds.values() if name in seen)
    stopped = Counter(scene for sid, scene in last_scene.items() if "posttest" not in kinds[sid])
    result["stopped_at"] = dict(stopped.most_common())
    return result


def item_accuracy(events: list[dict[str, Any]]) -> dict[str, dict[str, int]]:
    acc: dict[str, dict[str, int]] = defaultdict(lambda: {"n": 0, "correct": 0})
    for e in _answers(events):
        row = acc[e["data"]["item_id"]]
        row["n"] += 1
        row["correct"] += int(e["data"]["correct"])
    return dict(sorted(acc.items()))


def learning_curve(events: list[dict[str, Any]]) -> list[dict[str, int]]:
    """Accuracy at the 1st, 2nd, ... meeting with the same kana in the same session."""
    met: Counter[tuple[str, str]] = Counter()
    curve: dict[int, dict[str, int]] = defaultdict(lambda: {"n": 0, "correct": 0})
    for e in _answers(events):  # sorted by session and time
        key = (e["sid"], e["data"]["item_id"])
        met[key] += 1
        step = curve[min(met[key], MAX_EXPOSURE)]
        step["n"] += 1
        step["correct"] += int(e["data"]["correct"])
    return [{"exposure": k, **curve[k]} for k in sorted(curve)]


def _wrong_choices(events: list[dict[str, Any]]) -> Iterator[dict[str, Any]]:
    for e in _answers(events):
        d = e["data"]
        if not d["correct"] and d["mode"] == "choice" and d["chosen"]:
            yield d


def _is_own_reading(d: dict[str, Any], kana: dict[str, dict[str, str]]) -> bool:
    return kana.get(d["item_id"], {}).get("romaji") == d["chosen"]


def confusions(events: list[dict[str, Any]], kana: dict[str, dict[str, str]]) -> list[dict[str, Any]]:
    """The most frequent (expected item, chosen reading) pairs among wrong multiple-choice answers."""
    pairs = Counter((d["item_id"], d["chosen"]) for d in _wrong_choices(events) if not _is_own_reading(d, kana))
    return [{"item_id": i, "chosen": c, "count": n} for (i, c), n in pairs.most_common(TOP_CONFUSIONS)]


def inconsistent_answers(events: list[dict[str, Any]], kana: dict[str, dict[str, str]]) -> int:
    """Answers logged as wrong although the chosen reading is the right one: a bug in whoever logs them."""
    return sum(1 for d in _wrong_choices(events) if _is_own_reading(d, kana))


def _time_summary(values: list[int]) -> dict[str, Any]:
    if not values:
        return {"n": 0}
    out: dict[str, Any] = {"n": len(values), "median": statistics.median(values)}
    if len(values) >= 2:
        q1, _, q3 = statistics.quantiles(values, n=4, method="inclusive")
        out["q1"], out["q3"] = q1, q3
    return out


def answer_times(events: list[dict[str, Any]]) -> dict[str, Any]:
    kept: list[int] = []
    per_item: dict[str, list[int]] = defaultdict(list)
    excluded = 0
    for e in _answers(events):
        ms = e["data"]["elapsed_ms"]
        if 0 < ms <= MAX_ANSWER_MS:
            kept.append(ms)
            per_item[e["data"]["item_id"]].append(ms)
        else:
            excluded += 1
    return {
        "overall": _time_summary(kept),
        "excluded": excluded,
        "items": {item: _time_summary(v) for item, v in sorted(per_item.items())},
    }


def sign_test(improved: int, worse: int) -> float | None:
    """Two-sided exact sign test: how likely is a split at least this uneven if nothing changed?"""
    n = improved + worse
    if n == 0:
        return None
    tail = sum(math.comb(n, i) for i in range(min(improved, worse) + 1)) / 2 ** n
    return round(min(1.0, 2 * tail), 4)


def _scores_summary(scores: list[float]) -> dict[str, Any]:
    if len(scores) < MIN_GROUP:
        return {"n": len(scores), "reported": False}
    return {"n": len(scores), "reported": True, "mean": _mean(scores), "median": statistics.median(scores)}


def _pairs_summary(pairs: list[tuple[str, int, int, int]]) -> dict[str, Any]:
    if len(pairs) < MIN_GROUP:
        return {"n": len(pairs), "reported": False}
    pre = [p[1] for p in pairs]
    post = [p[2] for p in pairs]
    gains = [b - a for a, b in zip(pre, post)]
    improved = sum(g > 0 for g in gains)
    worse = sum(g < 0 for g in gains)
    normalized = [(b - a) / (n - a) for _, a, b, n in pairs if a < n]
    return {
        "n": len(pairs),
        "reported": True,
        "pre_mean": _mean(pre),
        "post_mean": _mean(post),
        "gain_mean": _mean(gains),
        "gain_median": statistics.median(gains),
        "improved": improved,
        "same": len(gains) - improved - worse,
        "worse": worse,
        "sign_test_p": sign_test(improved, worse),
        "normalized_gain_mean": _mean(normalized) if normalized else None,
        "normalized_gain_n": len(normalized),
    }


def pre_post(events: list[dict[str, Any]]) -> dict[str, Any]:
    """Before/after scores of the same player, taken from the posttest event (no player id needed)."""
    pairs: list[tuple[str, int, int, int]] = []
    skipped: Counter[str] = Counter()
    pre_scores: dict[str, list[float]] = {form: [] for form in FORMS}
    for e in events:
        d = e["data"]
        if e["event"] == "pretest":
            pre_scores[d["form"]].append(d["score"])
        if e["event"] != "posttest":
            continue
        if d["pre_form"] == "" or d["pre_score"] < 0:
            skipped["no_pretest"] += 1
        elif d["pre_form"] == d["form"]:
            skipped["same_form"] += 1
        else:
            pairs.append((d["pre_form"], d["pre_score"], d["score"], d["n_items"]))
    return {
        "n_pairs": len(pairs),
        "skipped": dict(skipped),
        "all": _pairs_summary(pairs),
        "a_then_b": _pairs_summary([p for p in pairs if p[0] == "A"]),
        "b_then_a": _pairs_summary([p for p in pairs if p[0] == "B"]),
        "pretest_by_form": {form: _scores_summary(scores) for form, scores in pre_scores.items()},
    }


def summarize(events: list[dict[str, Any]], skipped: Counter[str], kana: dict[str, dict[str, str]],
              build: str = "") -> dict[str, Any]:
    """Every metric of docs/metrics.md, as aggregated numbers only."""
    answers = list(_answers(events))
    return {
        "schema": 1,
        "build_filter": build,
        "events": len(events),
        "skipped": dict(skipped),
        "funnel": funnel(events),
        "accuracy": {
            "n": len(answers),
            "correct": sum(int(e["data"]["correct"]) for e in answers),
            "items": item_accuracy(events),
        },
        "learning_curve": learning_curve(events),
        "confusions": confusions(events, kana),
        "inconsistent_answers": inconsistent_answers(events, kana),
        "time_ms": answer_times(events),
        "pre_post": pre_post(events),
    }


# ---------------------------------------------------------------- feedback form (SUS)

def sus_score(answers: list[int]) -> float:
    """SUS, 0 to 100: odd questions are positive (answer - 1), even ones negative (5 - answer)."""
    total = sum(a - 1 if i % 2 == 0 else 5 - a for i, a in enumerate(answers))
    return total * 2.5


def read_form(path: Path) -> tuple[list[dict[str, Any]], int]:
    """Complete answers as {age, answers}, plus how many rows were incomplete."""
    with path.open(encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        columns: dict[int, str] = {}
        age_column = None
        for title in reader.fieldnames or []:
            match = SUS_TITLE.match(title)
            if match and 1 <= int(match.group(1)) <= 10:
                columns[int(match.group(1))] = title
            elif title.strip().casefold().startswith(AGE_TITLES):
                age_column = title
        if sorted(columns) != list(range(1, 11)):
            raise ValueError("nu găsesc cele 10 întrebări SUS (titluri care încep cu „1.” până la „10.”)")
        rows: list[dict[str, Any]] = []
        incomplete = 0
        for row in reader:
            answers = []
            for number in range(1, 11):
                match = SUS_ANSWER.match(row.get(columns[number]) or "")
                if not match:
                    break
                answers.append(int(match.group(1)))
            if len(answers) < 10:
                incomplete += 1
                continue
            age = (row.get(age_column) or "").strip() if age_column else ""
            rows.append({"age": age, "answers": answers})
    return rows, incomplete


def sus_summary(rows: list[dict[str, Any]], incomplete: int) -> dict[str, Any]:
    scores = [sus_score(r["answers"]) for r in rows]
    by_age: dict[str, list[float]] = defaultdict(list)
    for r, score in zip(rows, scores):
        by_age[r["age"] or "fără răspuns"].append(score)
    return {
        "complete": len(rows),
        "incomplete": incomplete,
        "all": _scores_summary(scores),
        "by_age": {age: _scores_summary(s) for age, s in sorted(by_age.items())},
    }


# ---------------------------------------------------------------- report

def _num(value: float, digits: int = 1) -> str:
    """Romanian decimal comma: 3.25 -> '3,3' (digits=1)."""
    return f"{value:.{digits}f}".replace(".", ",")


def _signed(value: float) -> str:
    """+2 for a whole number, +1,5 otherwise."""
    return f"{int(value):+d}" if float(value).is_integer() else f"{value:+.1f}".replace(".", ",")


def _pct(part: int, whole: int) -> str:
    return f"{round(100 * part / whole)}%" if whole else "-"


def _kana_label(item_id: str, kana: dict[str, dict[str, str]]) -> str:
    item = kana.get(item_id)
    return f"{item['kana']} ({item['romaji']})" if item else item_id


def _chosen_label(item_id: str, chosen: str, kana: dict[str, dict[str, str]]) -> str:
    script = kana.get(item_id, {}).get("script")
    for item in kana.values():
        if item["script"] == script and item["romaji"] == chosen:
            return f"{item['kana']} ({chosen})"
    return chosen


def _pairs_text(s: dict[str, Any]) -> str:
    if not s["reported"]:
        return f"prea puține perechi (n={s['n']}, minimum {MIN_GROUP}), nu raportăm"
    p = s["sign_test_p"]
    p_text = "-" if p is None else _num(p, 4)
    norm = s["normalized_gain_mean"]
    norm_text = "-" if norm is None else _num(norm, 2)
    return (f"n={s['n']} · înainte {_num(s['pre_mean'])} · după {_num(s['post_mean'])} · "
            f"câștig mediu {_signed(s['gain_mean'])} (mediana {_signed(s['gain_median'])}) · "
            f"au crescut {s['improved']}, la fel {s['same']}, au scăzut {s['worse']} · "
            f"testul semnului p = {p_text} · câștig normalizat {norm_text}")


def report_lines(summary: dict[str, Any], kana: dict[str, dict[str, str]]) -> list[str]:
    lines = []
    skipped = summary["skipped"]
    detail = ", ".join(f"{n} {SKIP_REASONS.get(k, k)}" for k, n in skipped.items())
    lines.append(f"Evenimente valide: {summary['events']} · ignorate: {sum(skipped.values())}"
                 + (f" ({detail})" if detail else ""))
    if summary["build_filter"]:
        lines.append(f"Doar build-urile care încep cu „{summary['build_filter']}”.")

    f = summary["funnel"]
    base = f["started"] or f["sessions"]
    lines += ["", "1. Sesiuni și abandon",
              f"   Sesiuni: {f['sessions']} · au pornit: {f['started']} · pre-test: {f['pretest']} · "
              f"cel puțin o luptă: {f['battle']} · post-test: {f['posttest']}",
              f"   Abandon (fără post-test): {base - f['posttest']} din {base} ({_pct(base - f['posttest'], base)})"]
    if f["stopped_at"]:
        lines.append("   Unde s-au oprit: " + ", ".join(f"{s} {n}" for s, n in f["stopped_at"].items()))

    acc = summary["accuracy"]
    lines += ["", "2. Acuratețe",
              f"   Total: {acc['n']} răspunsuri, {_pct(acc['correct'], acc['n'])} corecte"]
    hard = [(i, r) for i, r in acc["items"].items() if r["n"] >= MIN_ITEM_ANSWERS]
    hard.sort(key=lambda x: (x[1]["correct"] / x[1]["n"], x[0]))
    if hard:
        lines.append(f"   Cele mai grele (cel puțin {MIN_ITEM_ANSWERS} răspunsuri): " + ", ".join(
            f"{_kana_label(i, kana)} {_pct(r['correct'], r['n'])} (n={r['n']})" for i, r in hard[:5]))

    lines += ["", "3. Curba de învățare (aceeași kana, în aceeași sesiune)"]
    for s in summary["learning_curve"]:
        later = " sau mai târziu" if s["exposure"] == MAX_EXPOSURE else ""
        lines.append(f"   întâlnirea {s['exposure']}{later}: {_pct(s['correct'], s['n'])} corecte (n={s['n']})")

    lines += ["", "4. Confuzii (răspunsuri greșite la alegere)"]
    lines += [f"   {_kana_label(c['item_id'], kana)} → {_chosen_label(c['item_id'], c['chosen'], kana)}: {c['count']}"
              for c in summary["confusions"]] or ["   nicio confuzie"]
    if summary["inconsistent_answers"]:
        lines.append(f"   ATENȚIE: {summary['inconsistent_answers']} răspunsuri marcate greșit, deși citirea aleasă "
                     "e cea corectă. Verifică cine scrie evenimentul answer.")

    t = summary["time_ms"]
    o = t["overall"]
    lines += ["", f"5. Timp pe întrebare (fără răspunsurile de peste {MAX_ANSWER_MS // 1000} s: {t['excluded']})"]
    if o["n"]:
        quart = f" (Q1 {_num(o['q1'] / 1000)} s, Q3 {_num(o['q3'] / 1000)} s)" if "q1" in o else ""
        lines.append(f"   Mediana: {_num(o['median'] / 1000)} s{quart}, n={o['n']}")

    pp = summary["pre_post"]
    skipped_pp = ", ".join(f"{n} {POST_SKIP_REASONS.get(k, k)}" for k, n in pp["skipped"].items())
    lines += ["", "6. Pre-test și post-test",
              f"   Perechi: {pp['n_pairs']}" + (f" · ignorate: {skipped_pp}" if skipped_pp else ""),
              f"   Toți: {_pairs_text(pp['all'])}",
              f"   A apoi B: {_pairs_text(pp['a_then_b'])}",
              f"   B apoi A: {_pairs_text(pp['b_then_a'])}"]
    forms = []
    for form, s in pp["pretest_by_form"].items():
        forms.append(f"{form} {_num(s['mean'])} (n={s['n']})" if s["reported"] else f"{form} n={s['n']}, prea puține")
    lines.append("   Scorul la pre-test pe forme (cele două forme trebuie să fie la fel de grele): " + " · ".join(forms))

    if "sus" in summary:
        sus = summary["sus"]
        lines += ["", "7. SUS (chestionar)", f"   Răspunsuri complete: {sus['complete']} · incomplete: {sus['incomplete']}"]
        a = sus["all"]
        lines.append(f"   Media: {_num(a['mean'])} din 100 (68 = media obișnuită), mediana {_num(a['median'])}"
                     if a["reported"] else f"   Prea puține răspunsuri (n={a['n']}, minimum {MIN_GROUP}), nu raportăm")
        for age, s in sus["by_age"].items():
            if s["reported"]:
                lines.append(f"   {age}: {_num(s['mean'])} (n={s['n']})")
    return lines


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Rezumă log-urile din playtest, cu metricile din docs/metrics.md.")
    parser.add_argument("events", type=Path, help="exportul evenimentelor: .csv sau .jsonl")
    parser.add_argument("--form", type=Path, help="exportul CSV al chestionarului (vârsta și SUS)")
    parser.add_argument("--build", default="", help="doar build-urile care încep cu acest text, de exemplu 0.1")
    parser.add_argument("--json", type=Path, dest="json_out", help="scrie aici doar numerele agregate (pentru docs/data/)")
    parser.add_argument("--data-dir", type=Path, default=REPO_DATA, help="folderul cu kana (implicit data/ din repo)")
    args = parser.parse_args(argv)

    if not args.events.is_file():
        print(f"EROARE: nu găsesc fișierul {args.events}")
        return 1
    events, skipped = read_events(args.events)
    if args.build:
        events = [e for e in events if e["build"].startswith(args.build)]
    if not events:
        print("EROARE: niciun eveniment valid. Verifică exportul și filtrul --build.")
        return 1
    kana = load_kana(args.data_dir)
    summary = summarize(events, skipped, kana, args.build)
    if args.form:
        if not args.form.is_file():
            print(f"EROARE: nu găsesc fișierul {args.form}")
            return 1
        try:
            rows, incomplete = read_form(args.form)
        except ValueError as err:
            print(f"EROARE în chestionar: {err}")
            return 1
        summary["sus"] = sus_summary(rows, incomplete)

    for line in report_lines(summary, kana):
        print(line)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"\nAm scris numerele agregate în {args.json_out}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
