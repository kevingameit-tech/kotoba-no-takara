#!/usr/bin/env node
// Tests for tools/log_backend/Code.gs. Run: node tools/log_backend/test_log_backend.js
//
// Code.gs runs in a sandbox with small fakes of the Apps Script services it uses
// (SpreadsheetApp, PropertiesService, LockService, ContentService, Logger). The last test
// exports the stored rows as CSV, like File > Download > CSV in Google Sheets, and gives them
// to tools/analyze_logs.py: every row that the backend stores must be read without a skip.
// Node 20 or newer, standard library only.

"use strict";

const assert = require("node:assert/strict");
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { test } = require("node:test");
const vm = require("node:vm");

const HERE = __dirname;
const REPO = path.resolve(HERE, "..", "..");
const CODE = fs.readFileSync(path.join(HERE, "Code.gs"), "utf8");
// The columns of docs/contracts.md, section 13, written out on purpose.
const COLUMNS = ["received_at", "v", "build", "sid", "t_ms", "platform", "lang", "event", "data"];
const NOW = new Date("2026-11-09T12:00:00.000Z");
const SID = "9f2c41d0e7ab5c3812fe06a9d4b7c1e5";

// ---------------------------------------------------------------- fakes

// Like Google Sheets, a cell that is not formatted as plain text turns "0.10" or "1000" into a number.
const LOOKS_NUMERIC = /^[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$/i;

class FakeSheet {
  constructor(maxRows = 1000) {
    this.rows = []; // row 1 first
    this.maxRows = maxRows;
    this.frozenRows = 0;
    this.textRanges = []; // [first row, number of rows, format] of every setNumberFormat()
    this.textRows = new Set();
    this.grownBy = [];
  }

  getLastRow() {
    return this.rows.length;
  }

  getMaxRows() {
    return this.maxRows;
  }

  insertRowsAfter(after, howMany) {
    assert.equal(after, this.maxRows, "rows are added at the end of the sheet");
    this.maxRows += howMany;
    this.grownBy.push(howMany);
  }

  setFrozenRows(count) {
    this.frozenRows = count;
  }

  getRange(row, column, numRows, numColumns) {
    if (row < 1 || column < 1 || row + numRows - 1 > this.maxRows) {
      throw new Error("The coordinates of the range are outside the dimensions of the sheet.");
    }
    const sheet = this;
    return {
      setNumberFormat(format) {
        sheet.textRanges.push([row, numRows, format]);
        for (let r = row; r < row + numRows; r += 1) {
          if (format === "@") sheet.textRows.add(r);
        }
        return this;
      },
      setValues(values) {
        assert.equal(values.length, numRows);
        values.forEach((cells, i) => {
          assert.equal(cells.length, numColumns);
          const isText = sheet.textRows.has(row + i);
          sheet.rows[row - 1 + i] = Array.from(cells, (cell) =>
            !isText && typeof cell === "string" && LOOKS_NUMERIC.test(cell) ? Number(cell) : cell);
        });
        return this;
      },
      getValues() {
        return sheet.rows.slice(row - 1, row - 1 + numRows).map((r) => r.slice(column - 1, column - 1 + numColumns));
      },
    };
  }
}

/** A Date whose "now" is fixed, so the tests give the same result on every day. */
function fixedClock(now) {
  return class FixedDate extends Date {
    constructor(...args) {
      if (args.length === 0) super(now.getTime());
      else super(...args);
    }

    static now() {
      return now.getTime();
    }
  };
}

/** Loads Code.gs into a fresh sandbox. With setupDone, the sheet "events" has its header. */
function load({ setupDone = true, lockFree = true, broken = false, sheet = new FakeSheet(), now = NOW } = {}) {
  const bookId = "book-1";
  const props = new Map(setupDone ? [["BOOK_ID", bookId]] : []);
  const sheets = new Map();
  if (setupDone) {
    sheet.rows.push(COLUMNS.slice());
    sheets.set("events", sheet);
  }
  const book = {
    getId: () => bookId,
    getSheetByName: (name) => sheets.get(name) || null,
    insertSheet: (name) => {
      const created = new FakeSheet();
      sheets.set(name, created);
      return created;
    },
  };
  const calls = { flushed: 0, released: 0, logged: [], errors: [] };
  const gs = vm.createContext({
    Date: fixedClock(now),
    SpreadsheetApp: {
      getActiveSpreadsheet: () => book,
      openById: (id) => {
        if (broken) throw new Error("Service Spreadsheets failed");
        assert.equal(id, bookId);
        return book;
      },
      flush: () => {
        calls.flushed += 1;
      },
    },
    PropertiesService: {
      getScriptProperties: () => ({
        getProperty: (key) => (props.has(key) ? props.get(key) : null),
        setProperty: (key, value) => {
          props.set(key, value);
        },
      }),
    },
    LockService: {
      getScriptLock: () => ({
        tryLock: () => lockFree,
        releaseLock: () => {
          calls.released += 1;
        },
      }),
    },
    ContentService: {
      MimeType: { JSON: "application/json" },
      createTextOutput: (text) => ({
        text,
        mimeType: "",
        setMimeType(mimeType) {
          this.mimeType = mimeType;
          return this;
        },
      }),
    },
    Logger: { log: (...args) => calls.logged.push(args) },
    console: { error: (...args) => calls.errors.push(args) },
  });
  vm.runInContext(CODE, gs, { filename: "Code.gs" });
  return { gs, sheets, props, calls, sheet: sheets.get("events") };
}

/** Objects made inside the sandbox have other prototypes: compare them as JSON. */
function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

function constant(gs, name) {
  return vm.runInContext(name, gs);
}

function send(gs, batch, now = NOW) {
  const body = typeof batch === "string" ? batch : JSON.stringify(batch);
  return plain(gs.handleBatch_(body, now));
}

// ---------------------------------------------------------------- sample events

function ev(event, data, top = {}) {
  return { v: 1, build: "0.1.0", sid: SID, t_ms: 1000, platform: "web_ios", lang: "ro", event, data, ...top };
}

const SAMPLES = {
  session_start: ev("session_start", {}),
  chapter_enter: ev("chapter_enter", { chapter: 1 }),
  answer: ev("answer", {
    encounter_id: "c1_kappa_1", qid: "q_0003", item_id: "h_ki", mode: "choice",
    correct: false, elapsed_ms: 3120, chosen: "sa",
  }),
  battle_end: ev("battle_end", { encounter_id: "c1_kappa_1", outcome: "win", correct: 4, wrong: 1 }),
  pretest: ev("pretest", { form: "A", score: 4, n_items: 10 }),
  posttest: ev("posttest", { form: "B", score: 8, n_items: 10, pre_form: "A", pre_score: 4 }),
  quit: ev("quit", { scene: "tokyo_town" }),
};

function withData(name, change) {
  return { ...SAMPLES[name], data: { ...SAMPLES[name].data, ...change } };
}

function without(object, key) {
  const copy = { ...object };
  delete copy[key];
  return copy;
}

// ---------------------------------------------------------------- setup, doGet, doPost

test("setup creates the sheet events with the header and remembers the spreadsheet", () => {
  const { gs, sheets, props } = load({ setupDone: false });
  gs.setup();
  const sheet = sheets.get("events");
  assert.deepEqual(sheet.rows, [COLUMNS]);
  assert.equal(sheet.frozenRows, 1);
  assert.equal(props.get("BOOK_ID"), "book-1");
});

test("setup keeps a sheet that has the right header and refuses one with another header", () => {
  const ok = load();
  ok.sheet.rows.push(["2026-11-09T12:00:00.000Z", "1", "0.1.0", SID, "5", "web_ios", "ro", "session_start", "{}"]);
  ok.gs.setup();
  assert.equal(ok.sheet.rows.length, 2);

  const other = load();
  other.sheet.rows[0] = ["name", "email"];
  assert.throws(() => other.gs.setup(), /alt antet/);
});

test("doPost answers with JSON, doGet shows that the backend runs", () => {
  const { gs, sheet } = load();
  const out = gs.doPost({ postData: { contents: JSON.stringify([SAMPLES.session_start]), type: "text/plain" } });
  assert.equal(out.mimeType, "application/json");
  assert.deepEqual(JSON.parse(out.text), { ok: true, stored: 1, rejected: {} });
  assert.equal(sheet.rows.length, 2);

  assert.deepEqual(JSON.parse(gs.doPost({}).text), { ok: false, error: "empty" });

  assert.deepEqual(JSON.parse(gs.doGet().text), { ok: true, service: "kotoba-no-takara-log", v: 1, open: true });

  const late = load({ now: new Date("2027-03-01T00:00:00Z") });
  assert.equal(JSON.parse(late.gs.doGet().text).open, false);
  const out2 = late.gs.doPost({ postData: { contents: JSON.stringify([SAMPLES.quit]) } });
  assert.deepEqual(JSON.parse(out2.text), { ok: false, error: "closed" });
});

test("doPost answers error server, and logs the cause, when Sheets fails", () => {
  const { gs, calls } = load({ broken: true });
  const out = gs.doPost({ postData: { contents: JSON.stringify([SAMPLES.quit]) } });
  assert.deepEqual(JSON.parse(out.text), { ok: false, error: "server" });
  assert.equal(calls.errors.length, 1);
});

// ---------------------------------------------------------------- what is stored

test("one event of each type becomes one row of text, in the column order of section 13", () => {
  const { gs, sheet, calls } = load();
  assert.deepEqual(plain(constant(gs, "COLUMNS")), COLUMNS);
  const result = send(gs, Object.values(SAMPLES));
  assert.deepEqual(result, { ok: true, stored: 7, rejected: {} });
  assert.equal(sheet.rows.length, 8);
  assert.deepEqual(sheet.rows[3], [
    "2026-11-09T12:00:00.000Z", "1", "0.1.0", SID, "1000", "web_ios", "ro", "answer",
    '{"encounter_id":"c1_kappa_1","qid":"q_0003","item_id":"h_ki","mode":"choice","correct":false,"elapsed_ms":3120,"chosen":"sa"}',
  ]);
  assert.deepEqual(sheet.rows[6][8], '{"form":"B","score":8,"n_items":10,"pre_form":"A","pre_score":4}');
  assert.ok(sheet.rows.flat().every((cell) => typeof cell === "string"), "every cell is text");
  assert.deepEqual(sheet.textRanges, [[2, 7, "@"]], "the new rows are formatted as plain text");
  assert.equal(calls.released, 1, "the lock is released");
  assert.equal(calls.flushed, 1);
});

test("unknown fields, and the free text in them, never reach the sheet", () => {
  const { gs, sheet } = load();
  const sneaky = {
    ...withData("answer", { name: "Ana Popescu", typed: "ki desu" }),
    note: "Ana Popescu, clasa a 7-a",
    email: "ana@example.com",
  };
  assert.deepEqual(send(gs, [sneaky]), { ok: true, stored: 1, rejected: {} });
  const cells = sheet.rows.slice(1).flat().join("|");
  for (const secret of ["Ana", "desu", "example.com", "clasa"]) {
    assert.ok(!cells.includes(secret), `${secret} must not be stored`);
  }
  assert.deepEqual(Object.keys(JSON.parse(sheet.rows[1][8])), Object.keys(SAMPLES.answer.data));
});

test("allowed edge values are stored", () => {
  const good = [
    ["type mode keeps chosen empty", withData("answer", { mode: "type", chosen: "", correct: true })],
    ["post-test without a pre-test", withData("posttest", { pre_form: "", pre_score: -1 })],
    ["quit before any scene", withData("quit", { scene: "" })],
    ["session_start without data", without(SAMPLES.session_start, "data")],
    ["empty build", { ...SAMPLES.quit, build: "" }],
    ["build with a suffix", { ...SAMPLES.quit, build: "0.1.0-rc.1+web" }],
    ["every platform", { ...SAMPLES.quit, platform: "desktop" }],
    ["English", { ...SAMPLES.quit, lang: "en" }],
    ["t_ms at the limit", { ...SAMPLES.quit, t_ms: 2147483647 }],
    ["a score of 0", withData("pretest", { score: 0 })],
    ["a full score", withData("posttest", { score: 10, pre_score: 10 })],
    ["an item id of 48 characters", withData("answer", { item_id: "w_" + "a".repeat(46) })],
    ["the reading of a word", withData("answer", { chosen: "toukyou" })],
    ["a qid with 5 digits", withData("answer", { qid: "q_10000" })],
    ["an encounter of chapter 3", withData("battle_end", { encounter_id: "c3_boss_oni" })],
    ["a scene with digits", withData("quit", { scene: "misiune_1" })],
    ["a lost battle", withData("battle_end", { outcome: "flee", correct: 0, wrong: 0 })],
  ];
  const { gs } = load();
  for (const [label, raw] of good) {
    assert.ok(plain(gs.checkEvent_(raw)).event, label);
  }
  // A whole float such as 3120.0 is the number 3120 after JSON.parse, as in the analysis.
  const text = JSON.stringify([SAMPLES.answer]).replace('"elapsed_ms":3120', '"elapsed_ms":3120.0');
  assert.ok(text.includes("3120.0"));
  assert.equal(send(gs, text).stored, 1);
});

test("each wrong event is dropped with the reason used by tools/analyze_logs.py", () => {
  const bad = [
    ["not an object", 5, "json"],
    ["v 2", { ...SAMPLES.answer, v: 2 }, "version"],
    ["v as text", { ...SAMPLES.answer, v: "1" }, "version"],
    ["unknown event", ev("level_up", {}), "event"],
    ["event name from Object.prototype", ev("constructor", {}), "event"],
    ["missing sid", without(SAMPLES.answer, "sid"), "field"],
    ["t_ms as text", { ...SAMPLES.answer, t_ms: "1000" }, "field"],
    ["t_ms with decimals", { ...SAMPLES.answer, t_ms: 10.5 }, "field"],
    ["data is a list", { ...SAMPLES.answer, data: [] }, "field"],
    ["data is null", { ...SAMPLES.answer, data: null }, "field"],
    ["correct as 1", withData("answer", { correct: 1 }), "field"],
    ["chapter as text", withData("chapter_enter", { chapter: "1" }), "field"],
    ["missing elapsed_ms", { ...SAMPLES.answer, data: without(SAMPLES.answer.data, "elapsed_ms") }, "field"],
    ["sid that is not 32 hex characters", { ...SAMPLES.answer, sid: "player-ana" }, "value"],
    ["sid in capitals", { ...SAMPLES.answer, sid: SID.toUpperCase() }, "value"],
    ["unknown platform", { ...SAMPLES.answer, platform: "ios" }, "value"],
    ["unknown language", { ...SAMPLES.answer, lang: "ja" }, "value"],
    ["build with a space", { ...SAMPLES.answer, build: "0.1 beta" }, "value"],
    ["negative t_ms", { ...SAMPLES.answer, t_ms: -1 }, "value"],
    ["t_ms above 2^31 - 1", { ...SAMPLES.answer, t_ms: 2147483648 }, "value"],
    ["qid with a space", withData("answer", { qid: "q 1" }), "value"],
    ["item_id that would be a formula", withData("answer", { item_id: '=HYPERLINK("http://x")' }), "value"],
    ["item_id that starts with a minus", withData("answer", { item_id: "-1" }), "value"],
    ["empty item_id", withData("answer", { item_id: "" }), "value"],
    ["chosen with a name", withData("answer", { chosen: "Ana Popescu" }), "value"],
    ["chosen with a diacritic", withData("answer", { chosen: "ș" }), "value"],
    ["item id of 49 characters", withData("answer", { item_id: "w_" + "a".repeat(47) }), "value"],
    ["typed text in type mode", withData("answer", { mode: "type", chosen: "sa" }), "value"],
    ["chosen in capitals", withData("answer", { chosen: "AnaPopescu" }), "value"],
    ["chosen as a phone number", withData("answer", { chosen: "0722123456" }), "value"],
    ["item_id as a phone number", withData("answer", { item_id: "0722123456" }), "value"],
    ["qid not made by QuizEngine", withData("answer", { qid: "evil.example.com" }), "value"],
    ["encounter_id without a chapter", withData("answer", { encounter_id: "kappa_1" }), "value"],
    ["scene with dots", withData("quit", { scene: "ana.popescu.2008" }), "value"],
    ["scene with a folder", withData("quit", { scene: "res://world/tokyo_town.tscn" }), "value"],
    ["scene in capitals", withData("quit", { scene: "TokyoTown" }), "value"],
    ["formula in chosen", withData("answer", { chosen: "=1+1" }), "value"],
    ["formula in qid", withData("answer", { qid: "=1+1" }), "value"],
    ["formula in encounter_id", withData("battle_end", { encounter_id: "=1+1" }), "value"],
    ["formula in scene", withData("quit", { scene: "=1+1" }), "value"],
    ["formula in build", { ...SAMPLES.quit, build: "=1+1" }, "value"],
    ["build that starts with +", { ...SAMPLES.quit, build: "+1" }, "value"],
    ["build that starts with @", { ...SAMPLES.quit, build: "@x" }, "value"],
    ["unknown mode", withData("answer", { mode: "voice" }), "value"],
    ["negative elapsed_ms", withData("answer", { elapsed_ms: -5 }), "value"],
    ["chapter 0", withData("chapter_enter", { chapter: 0 }), "value"],
    ["unknown outcome", withData("battle_end", { outcome: "draw" }), "value"],
    ["negative wrong", withData("battle_end", { wrong: -1 }), "value"],
    ["score above n_items", withData("pretest", { score: 11 }), "value"],
    ["form C", withData("pretest", { form: "C" }), "value"],
    ["n_items 0", withData("pretest", { score: 0, n_items: 0 }), "value"],
    ["pre_score above n_items", withData("posttest", { pre_score: 11 }), "value"],
    ["pre_score -2", withData("posttest", { pre_score: -2 }), "value"],
    ["pre_form C", withData("posttest", { pre_form: "C" }), "value"],
    ["scene with a slash", withData("quit", { scene: "../x" }), "value"],
  ];
  const { gs, sheet } = load();
  const counts = {};
  for (const [label, raw, reason] of bad) {
    assert.deepEqual(plain(gs.checkEvent_(raw)), { reason }, label);
    counts[reason] = (counts[reason] || 0) + 1;
  }
  // In one batch the good events are kept and the bad ones are counted by reason.
  const batch = [SAMPLES.session_start, ...bad.map((b) => b[1]), SAMPLES.quit];
  assert.deepEqual(send(gs, batch), { ok: true, stored: 2, rejected: counts });
  assert.deepEqual(sheet.rows.slice(1).map((r) => r[7]), ["session_start", "quit"]);
});

test("a body that is not a list of events is refused as a whole", () => {
  const { gs, sheet } = load();
  const maxEvents = constant(gs, "MAX_EVENTS");
  const maxChars = constant(gs, "MAX_BODY_CHARS");
  const cases = [
    ["", "empty"],
    ["hello", "json"],
    ['{"v": 1}', "not_array"],
    ["[]", "empty"],
    [JSON.stringify(Array(maxEvents + 1).fill(SAMPLES.quit)), "too_many"],
    ["[" + " ".repeat(maxChars) + "]", "too_large"],
  ];
  for (const [body, error] of cases) {
    assert.deepEqual(send(gs, body), { ok: false, error }, error);
  }
  assert.equal(send(gs, Array(maxEvents).fill(SAMPLES.quit)).stored, maxEvents);
  assert.equal(sheet.rows.length, 1 + maxEvents);
});

test("nothing is written before setup, while another POST writes, when full or after the last day", () => {
  assert.deepEqual(send(load({ setupDone: false }).gs, [SAMPLES.quit]), { ok: false, error: "setup", rejected: {} });
  assert.deepEqual(send(load({ lockFree: false }).gs, [SAMPLES.quit]), { ok: false, error: "busy", rejected: {} });

  const full = load();
  const maxRows = constant(full.gs, "MAX_ROWS");
  full.sheet.maxRows = maxRows + 1;
  full.sheet.rows.length = maxRows; // the header and maxRows - 1 events
  assert.equal(send(full.gs, [SAMPLES.quit]).stored, 1, "the last free row is used");
  assert.deepEqual(send(full.gs, [SAMPLES.quit]), { ok: false, error: "full", rejected: {} });

  const { gs } = load();
  assert.equal(send(gs, [SAMPLES.quit], new Date("2027-02-28T23:00:00Z")).stored, 1);
  assert.deepEqual(send(gs, [SAMPLES.quit], new Date("2027-03-01T00:00:00Z")), { ok: false, error: "closed" });
});

test("the sheet grows when it has no empty row left", () => {
  const { gs, sheet } = load({ sheet: new FakeSheet(3) });
  assert.equal(send(gs, Array(5).fill(SAMPLES.quit)).stored, 5);
  assert.deepEqual(sheet.grownBy, [1000]);
  assert.equal(sheet.rows.length, 6);
});

// ---------------------------------------------------------------- backend and analysis agree

function mulberry32(seed) {
  let a = seed;
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const EDGE_VALUES = [
  0, -1, 1, 4, 10, 11, 99, 100, 101, 2147483647, 2147483648, 3120, 1.5, -0.5, "", "a", "A", "B", "C",
  "x y", "=1+1", "+1", "@x", "-x", "q_0003", "h_ki", "sa", "ș", "0.1.0", "web_ios", "ro", "en", "ja",
  "choice", "type", "win", "draw", true, false, null, [], {}, SID, SID.toUpperCase(), "z".repeat(48),
  "z".repeat(49), "AnaPopescu", "0722123456", "ana.popescu", "tokyo_town", "c1_kappa_1", "q_10000",
  "toukyou", "\t1", " sa",
];

/** Valid events plus copies with one or two fields changed, removed or added. */
function fuzzEvents(random, count) {
  const pick = (list) => list[Math.floor(random() * list.length)];
  const names = Object.keys(SAMPLES);
  const events = [];
  for (let i = 0; i < count; i += 1) {
    const raw = JSON.parse(JSON.stringify(SAMPLES[pick(names)]));
    const changes = Math.floor(random() * 3);
    for (let c = 0; c < changes; c += 1) {
      // An earlier change may have turned data into a text or a number: change raw then.
      const dataIsObject = typeof raw.data === "object" && raw.data !== null;
      const target = random() < 0.5 && dataIsObject ? raw.data : raw;
      const key = random() < 0.15 ? "extra_" + c : pick(Object.keys(target));
      if (random() < 0.15) delete target[key];
      else target[key] = JSON.parse(JSON.stringify(pick(EDGE_VALUES)));
    }
    events.push(raw);
  }
  return events;
}

/** Complete sessions with real kana, so the analysis has real numbers to compute. */
function sessions(random, count) {
  const items = [["h_a", "a"], ["h_i", "i"], ["h_u", "u"], ["h_ka", "ka"], ["h_ki", "ki"], ["h_sa", "sa"]];
  const events = [];
  for (let s = 0; s < count; s += 1) {
    const sid = Array.from({ length: 32 }, () => "0123456789abcdef"[Math.floor(random() * 16)]).join("");
    let t = 0;
    const next = (event, data) => {
      t += 1000 + Math.floor(random() * 4000);
      events.push({ ...ev(event, data), sid, t_ms: t, platform: s % 2 ? "web_android" : "web_desktop" });
    };
    const pre = Math.floor(random() * 6);
    const form = s % 2 ? "A" : "B";
    next("session_start", {});
    next("pretest", { form, score: pre, n_items: 10 });
    next("chapter_enter", { chapter: 1 });
    for (let q = 0; q < 12; q += 1) {
      const [item, reading] = items[q % items.length];
      const correct = random() < 0.7;
      const chosen = correct ? reading : items[(q + 1) % items.length][1];
      next("answer", {
        encounter_id: "c1_kappa_1", qid: "q_" + String(q).padStart(4, "0"), item_id: item, mode: "choice",
        correct, elapsed_ms: 800 + Math.floor(random() * 7000), chosen,
      });
    }
    next("battle_end", { encounter_id: "c1_kappa_1", outcome: "win", correct: 8, wrong: 4 });
    next("posttest", {
      form: form === "A" ? "B" : "A", score: Math.min(10, pre + Math.floor(random() * 5)), n_items: 10,
      pre_form: form, pre_score: pre,
    });
    next("quit", { scene: "tokyo_town" });
  }
  return events;
}

function csvCell(text) {
  return /[",\r\n]/.test(text) ? '"' + text.replace(/"/g, '""') + '"' : text;
}

test("every row the backend stores is read by tools/analyze_logs.py without a skip", () => {
  const random = mulberry32(51);
  const { gs, sheet } = load();
  const events = [...sessions(random, 6), ...fuzzEvents(random, 600)];
  let stored = 0;
  let rejected = 0;
  for (let i = 0; i < events.length; i += 100) {
    const result = send(gs, events.slice(i, i + 100));
    assert.equal(result.ok, true, JSON.stringify(result));
    stored += result.stored;
    rejected += Object.values(result.rejected).reduce((a, b) => a + b, 0);
  }
  assert.equal(stored + rejected, events.length);
  assert.ok(stored >= 250 && rejected >= 150, `a useful mix: ${stored} stored, ${rejected} rejected`);
  assert.equal(sheet.rows.length, 1 + stored);
  for (const cell of sheet.rows.slice(1).flat()) {
    assert.equal(typeof cell, "string");
    assert.match(cell, /^[\x20-\x7e]*$/, "printable ASCII only");
    assert.doesNotMatch(cell, /^[=+\-@]/, "no cell can start a formula");
  }

  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "log_backend_"));
  try {
    const csvPath = path.join(dir, "events.csv");
    const jsonPath = path.join(dir, "summary.json");
    fs.writeFileSync(csvPath, sheet.rows.map((r) => r.map(csvCell).join(",")).join("\r\n") + "\r\n");
    execFileSync("python3", [path.join(REPO, "tools", "analyze_logs.py"), csvPath, "--json", jsonPath], {
      stdio: "pipe",
    });
    const summary = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
    assert.deepEqual(summary.skipped, {}, "the analysis skipped rows that the backend stored");
    assert.equal(summary.events, stored);
    assert.ok(summary.funnel.posttest >= 6, "the six complete sessions reach the post-test");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});
