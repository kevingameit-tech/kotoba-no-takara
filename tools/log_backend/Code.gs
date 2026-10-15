// Kotoba no Takara: the log backend (docs/contracts.md, section 13). Owner: Kevin, issue #51.
//
// A Google Apps Script web app that appends the game's events to a private Google Sheet.
// The game POSTs a JSON array of events as a text/plain body. Every valid event becomes one
// row of the sheet "events", with the columns of section 13. The URL can only add rows:
// nothing can be read, changed or deleted through it.
//
// Only ids, numbers and fixed values are stored. Unknown fields are dropped and every string must
// match the pattern of its field (lowercase ids, romaji letters or fixed values), so sentences,
// spaces and diacritics cannot be stored. In "type" mode `chosen` must be empty, so what a player
// types never reaches the sheet. Apps Script does not give the script the sender's IP address,
// so it is never stored (PRIVACY.md).
//
// Setup, deployment and updates: tools/log_backend/README.md.
// Tests: node tools/log_backend/test_log_backend.js (CI runs them too).

const SCHEMA_VERSION = 1;
const SHEET_NAME = "events";
const COLUMNS = ["received_at", "v", "build", "sid", "t_ms", "platform", "lang", "event", "data"];
const BOOK_ID_KEY = "BOOK_ID"; // script property written by setup()
const MAX_BODY_CHARS = 60000; // browsers cap a keepalive request at 64 KiB
const MAX_EVENTS = 200; // per POST
const MAX_ROWS = 200000; // data rows: 1.8 million cells, far below the 10 million of a spreadsheet
const GROW_ROWS = 1000; // rows added at once when the sheet has no empty row left
const LOCK_WAIT_MS = 10000;
const LAST_DAY = "2027-02-28"; // PRIVACY.md: the raw data is deleted by 1 March 2027
const MAX_INT = 2147483647;

// Every text starts with a letter or a digit, so no cell can start a formula ("=", "+", "-", "@").
const SNAKE_ID = /^[a-z][a-z0-9_]{0,47}$/; // item ids such as "h_ki" (data/README.md)
const QID = /^q_[0-9]{1,8}$/; // made by QuizEngine as "q_%04d"
const ENCOUNTER_ID = /^c[1-9]_[a-z0-9_]{1,45}$/; // "c1_kappa_1"
const READING = /^([a-z]{1,24})?$/; // one of the romaji choices; "" in "type" mode
const SCENE = /^([a-z][a-z0-9_]{0,47})?$/; // scene file name without folder or extension
const BUILD = /^([A-Za-z0-9][A-Za-z0-9_.+-]{0,31})?$/; // application/config/version, "" if not set
const SID = /^[0-9a-f]{32}$/; // Crypto.generate_random_bytes(16).hex_encode()
const FORMS = ["A", "B"];

// ---------------------------------------------------------------- field checks
// Each check returns "" for a good value, "field" for a missing value or a wrong type and
// "value" for a value that is not allowed: the reasons of SKIP_REASONS in tools/analyze_logs.py.

function isInt_(value) {
  return typeof value === "number" && Number.isInteger(value);
}

function intIn_(min, max) {
  return function (value) {
    if (!isInt_(value)) return "field";
    return value < min || value > max ? "value" : "";
  };
}

function text_(pattern) {
  return function (value) {
    if (typeof value !== "string") return "field";
    return pattern.test(value) ? "" : "value";
  };
}

function oneOf_(values) {
  return function (value) {
    if (typeof value !== "string") return "field";
    return values.indexOf(value) >= 0 ? "" : "value";
  };
}

function bool_() {
  return function (value) {
    return typeof value === "boolean" ? "" : "field";
  };
}

// Fields that Telemetry adds to every event, besides v and event.
const TOP_FIELDS = {
  build: text_(BUILD),
  sid: text_(SID),
  t_ms: intIn_(0, MAX_INT),
  platform: oneOf_(["web_desktop", "web_android", "web_ios", "desktop"]),
  lang: oneOf_(["ro", "en"]),
};

// The data fields of each event in catalog v1, in the order they are stored.
const EVENT_FIELDS = {
  session_start: {},
  chapter_enter: { chapter: intIn_(1, 99) },
  answer: {
    encounter_id: text_(ENCOUNTER_ID),
    qid: text_(QID),
    item_id: text_(SNAKE_ID),
    mode: oneOf_(["choice", "type"]),
    correct: bool_(),
    elapsed_ms: intIn_(0, MAX_INT),
    chosen: text_(READING),
  },
  battle_end: {
    encounter_id: text_(ENCOUNTER_ID),
    outcome: oneOf_(["win", "lose", "flee"]),
    correct: intIn_(0, 999),
    wrong: intIn_(0, 999),
  },
  pretest: { form: oneOf_(FORMS), score: intIn_(0, 100), n_items: intIn_(1, 100) },
  posttest: {
    form: oneOf_(FORMS),
    score: intIn_(0, 100),
    n_items: intIn_(1, 100),
    pre_form: oneOf_(FORMS.concat([""])), // "" and -1 when the pre-test is unknown
    pre_score: intIn_(-1, 100),
  },
  quit: { scene: text_(SCENE) },
};

// Rules that compare two fields, as in _values_ok() of tools/analyze_logs.py, plus one rule of
// the contract: in "type" mode `chosen` stays "", because typed text is never logged.
function crossCheck_(name, data) {
  if (name === "answer" && data.mode === "type" && data.chosen !== "") return "value";
  if ((name === "pretest" || name === "posttest") && data.score > data.n_items) return "value";
  if (name === "posttest" && data.pre_score > data.n_items) return "value";
  return "";
}

function isPlainObject_(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// ---------------------------------------------------------------- one batch

/**
 * Checks one event. Returns {event} with only the catalog fields, or {reason}.
 * The order of the checks is the same as in normalize() of tools/analyze_logs.py.
 */
function checkEvent_(raw) {
  if (!isPlainObject_(raw)) return { reason: "json" };
  if (raw.v !== SCHEMA_VERSION) return { reason: "version" };
  const name = raw.event;
  if (typeof name !== "string" || !Object.prototype.hasOwnProperty.call(EVENT_FIELDS, name)) {
    return { reason: "event" };
  }
  const event = { v: SCHEMA_VERSION, event: name };
  for (const key of Object.keys(TOP_FIELDS)) {
    const reason = TOP_FIELDS[key](raw[key]);
    if (reason) return { reason: reason };
    event[key] = raw[key];
  }
  const data = raw.data === undefined ? {} : raw.data;
  if (!isPlainObject_(data)) return { reason: "field" };
  const fields = EVENT_FIELDS[name];
  const clean = {};
  for (const key of Object.keys(fields)) {
    const reason = fields[key](data[key]);
    if (reason) return { reason: reason };
    clean[key] = data[key];
  }
  const reason = crossCheck_(name, clean);
  if (reason) return { reason: reason };
  event.data = clean;
  return { event: event };
}

/** Reads the POST body. Returns {events} or {error}. */
function parseBatch_(body) {
  if (typeof body !== "string" || body.length === 0) return { error: "empty" };
  if (body.length > MAX_BODY_CHARS) return { error: "too_large" };
  let parsed;
  try {
    parsed = JSON.parse(body);
  } catch (err) {
    return { error: "json" };
  }
  if (!Array.isArray(parsed)) return { error: "not_array" };
  if (parsed.length === 0) return { error: "empty" };
  if (parsed.length > MAX_EVENTS) return { error: "too_many" };
  return { events: parsed };
}

/** One sheet row, every cell as text, in the order of COLUMNS. */
function toRow_(event, receivedAt) {
  return [
    receivedAt.toISOString(),
    String(event.v),
    event.build,
    event.sid,
    String(event.t_ms),
    event.platform,
    event.lang,
    event.event,
    JSON.stringify(event.data),
  ];
}

function closingTime_() {
  return new Date(LAST_DAY + "T23:59:59.999Z").getTime();
}

/**
 * Stores the valid events of one batch and drops the others.
 * Returns {ok: true, stored, rejected: {reason: count}} or {ok: false, error}.
 */
function handleBatch_(body, now) {
  if (now.getTime() > closingTime_()) return { ok: false, error: "closed" };
  const batch = parseBatch_(body);
  if (batch.error) return { ok: false, error: batch.error };
  const rows = [];
  const rejected = {};
  for (const raw of batch.events) {
    const result = checkEvent_(raw);
    if (result.reason) {
      rejected[result.reason] = (rejected[result.reason] || 0) + 1;
    } else {
      rows.push(toRow_(result.event, now));
    }
  }
  if (rows.length > 0) {
    const error = appendRows_(rows);
    if (error) return { ok: false, error: error, rejected: rejected };
  }
  return { ok: true, stored: rows.length, rejected: rejected };
}

// ---------------------------------------------------------------- the sheet

function eventsSheet_() {
  const id = PropertiesService.getScriptProperties().getProperty(BOOK_ID_KEY);
  return id ? SpreadsheetApp.openById(id).getSheetByName(SHEET_NAME) : null;
}

/**
 * Appends the rows while holding the script lock, so two POSTs never write the same rows.
 * Returns an error key, or "" when the rows were written.
 */
function appendRows_(rows) {
  const sheet = eventsSheet_();
  if (!sheet) return "setup";
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(LOCK_WAIT_MS)) return "busy";
  try {
    const first = sheet.getLastRow() + 1;
    const last = first + rows.length - 1;
    if (last - 1 > MAX_ROWS) return "full"; // row 1 is the header
    const maxRows = sheet.getMaxRows();
    if (last > maxRows) sheet.insertRowsAfter(maxRows, Math.max(last - maxRows, GROW_ROWS));
    const range = sheet.getRange(first, 1, rows.length, COLUMNS.length);
    range.setNumberFormat("@"); // plain text: "0.10" stays "0.10" and no cell turns into a number
    range.setValues(rows);
    SpreadsheetApp.flush();
    return "";
  } finally {
    lock.releaseLock();
  }
}

function json_(value) {
  return ContentService.createTextOutput(JSON.stringify(value)).setMimeType(ContentService.MimeType.JSON);
}

// ---------------------------------------------------------------- entry points

/**
 * Run once from the editor: choose "setup" next to Run, then Run. Google asks for permission
 * to use Sheets. Creates the sheet "events" with the header row and remembers this spreadsheet,
 * because a web app cannot use getActiveSpreadsheet().
 */
function setup() {
  const book = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = book.getSheetByName(SHEET_NAME) || book.insertSheet(SHEET_NAME);
  if (sheet.getLastRow() === 0) {
    sheet.getRange(1, 1, 1, COLUMNS.length).setValues([COLUMNS]);
  } else {
    const header = sheet.getRange(1, 1, 1, COLUMNS.length).getValues()[0].join(",");
    if (header !== COLUMNS.join(",")) {
      throw new Error("Foaia „" + SHEET_NAME + "” are alt antet: " + header + ". Folosește o foaie goală.");
    }
  }
  sheet.setFrozenRows(1);
  PropertiesService.getScriptProperties().setProperty(BOOK_ID_KEY, book.getId());
  Logger.log("Gata: foaia „%s” primește evenimentele. Pasul următor: Deploy > New deployment.", SHEET_NAME);
}

/** Health check: opening the /exec URL in a browser shows that the backend runs. */
function doGet() {
  return json_({ ok: true, service: "kotoba-no-takara-log", v: SCHEMA_VERSION, open: Date.now() <= closingTime_() });
}

/** Receives one batch of events from the game (docs/contracts.md, section 13). */
function doPost(e) {
  try {
    const body = e && e.postData ? e.postData.contents : "";
    return json_(handleBatch_(body, new Date()));
  } catch (err) {
    console.error(err);
    return json_({ ok: false, error: "server" });
  }
}
