# Contracts between modules (v0)

> **Status: v0.3 draft.** Written by Kevin on 2026-10-05, updated on 2026-10-07, presented at the lab on 2026-10-12.
> Items marked **PROPOSAL** are decided by the team vote on 2026-10-12 or by the owners before the freeze date.

**Why this file exists.** Four people build four parts of one game at the same time. A contract fixes the names, signatures and data shapes that two parts use to talk to each other, so each person can work (and test with fakes) without waiting for the others.

**How to change a contract.**

- Before its freeze date: a normal pull request, with the agreement of the other side of the contract (a comment in the pull request or a message in the team group).
- After its freeze date: a pull request with the **written agreement of the other side** in the pull request (a comment such as "agreed" or "de acord"), the `contract` label, and a line in the [changelog](#14-changelog). Since 2026-10-07 GitHub needs no approval, only the automatic checks. Code on both sides and the fakes (for example `FakeQuizEngine`) change in the same pull request.

## Contents

| # | Contract | Between | Owner | Freeze |
|---|---|---|---|---|
| 1 | [Engine, renderer, resolution](#1-engine-renderer-resolution) | all | David (project.godot) | resolution voted 2026-10-12, in project.godot by 2026-10-19 |
| 2 | [Fonts](#2-fonts-proposal) | Mariana to all | Mariana | Theme v1 2026-10-22, fonts v1 2026-10-26 |
| 3 | [Folders and ownership](#3-folders-and-ownership) | all | Kevin | 2026-10-12 |
| 4 | [Autoloads](#4-autoloads) | all | Kevin | 2026-10-19 |
| 5 | [Input Map](#5-input-map) | David to all | David | 2026-10-19 |
| 6 | [Settings and UI text keys](#6-settings-and-ui-text-keys) | Mariana to all | Mariana | 2026-10-19 |
| 7 | [Content data (JSON)](#7-content-data-json) | Kevin to all | Kevin | ids and pools 2026-10-19 |
| 8 | [QuestionBank and QuizEngine](#8-questionbank-and-quizengine) | Kevin and Ioana | Kevin | 2026-10-19 |
| 9 | [Battle hand-off](#9-battle-hand-off) | David and Ioana | David, Ioana | 2026-10-19 |
| 10 | [Battle data](#10-battle-data) | Kevin and Ioana | Kevin (JSON), Ioana (.tres) | 2026-10-19 |
| 11 | [Dialogue](#11-dialogue) | Kevin and David | Kevin (JSON), David (DialogueBox) | 2026-10-19 |
| 12 | [Save schema](#12-save-schema-placeholder) | all four | Mariana | 2026-10-26 |
| 13 | [Telemetry event catalog](#13-telemetry-event-catalog-placeholder) | Kevin to Mariana | Kevin | 2026-10-26 |

## 1. Engine, renderer, resolution

| Item | Value |
|---|---|
| Engine | Godot **4.7.2-stable, standard build** (not .NET) for everyone. No upgrade after v0.1. Fallback if the GUT spike fails on 2026-10-09: Godot 4.6.3 + GUT 9.6.1 for the whole team. |
| Test framework | GUT **9.7.1**, installed by `tools/install_gut.sh` / `tools/install_gut.ps1` into `addons/gut/` (gitignored, never committed). |
| Renderer | `rendering/renderer/rendering_method="gl_compatibility"` (the web export supports only Compatibility). |
| Web export | Single-threaded (Thread Support off). Preset in `export_presets.cfg` (Mariana, 2026-10-15). Exclude `addons/gut/*` and `tests/*` from the export. |
| Project name | `application/config/name="Kotoba no Takara"`. Must not change after v0.1: web saves live in IndexedDB under this name. |
| Version | `application/config/version` = `"0.1.0"`, `"0.2.0"`, `"1.0.0"`. Shown on the title screen and sent with every telemetry event. Matches the Git tag (`"0.1.0"` for tag `v0.1`). |
| Text server data | `internationalization/locale/include_text_server_data=true` (Japanese line breaking in the web build). |

**Resolution: PROPOSAL A**, confirmed after the phone test (2026-10-09 to 2026-10-12):

| Setting | Value | project.godot key |
|---|---|---|
| Base size | 640x360 | `display/window/size/viewport_width=640`, `display/window/size/viewport_height=360` |
| Stretch mode | canvas_items | `display/window/stretch/mode="canvas_items"` |
| Aspect | expand | `display/window/stretch/aspect="expand"` |
| Default texture filter | Nearest | `rendering/textures/canvas_textures/default_texture_filter=0` |
| Snap 2D transforms to pixel | on | `rendering/2d/snap/snap_2d_transforms_to_pixel=true` |

With A, the world camera uses `Camera2D.zoom = Vector2(2, 2)` (16 px tiles look like 32 px) and the UI draws at full 640x360. Phones are used in landscape; Mariana's "rotate your phone" overlay covers portrait.
Other options on the ballot: **B** 384x216 canvas_items; **C** 384x216 viewport with integer scaling.

## 2. Fonts (PROPOSAL)

- **Pixelify Sans** (OFL 1.1) is the primary font for Latin and Romanian text.
- **DotGothic16** (OFL 1.1) is the fallback for kana and kanji. It has no ă, ș, ț (nor Ă, Ș, Ț), so it is never the primary font for Romanian text.
- Optional: a subset of **Noto Sans JP** (OFL 1.1) for large quiz kana. Kevin approves the kana shapes.
- Files live in `fonts/`, each with its own `OFL.txt`. Scenes get fonts only through Mariana's Theme (path fixed on 2026-10-22); no font is set directly on a node.
- Pixel fonts use integer sizes, checked on a real phone.
- Romanian uses comma-below letters U+0218 to U+021B (Ș ș Ț ț), never the cedilla forms U+015E, U+015F, U+0162, U+0163. A GUT glyph test (Mariana, 2026-10-22) checks ă â î ș ț Ă Â Î Ș Ț and kana.
- If fonts are subset, the subset is rebuilt whenever `data/` or `i18n/` gets new characters.

## 3. Folders and ownership

One owner per folder and per scene. Others change it only through an issue or with the owner's agreement. `.github/CODEOWNERS` lists the same owners with every rule commented out: since 2026-10-07 a PR needs no approval, so GitHub does not request reviews automatically.

| Path | Owner | Content |
|---|---|---|
| `world/` | David | maps, Player, NPC, DialogueBox, EnemyMarker |
| `battle/` | Ioana | BattleModel, Battler, BattleScene, `battle/data/enemies/*.tres` |
| `ui/` | Mariana | menus, Theme, TouchControls, HUD components, title screen |
| `i18n/` | Mariana | `ui.csv` |
| `fonts/` | Mariana | font files + `OFL.txt` |
| `quiz/` | Kevin | QuizEngine, RomajiConverter, pre-test and post-test screens |
| `data/` | Kevin | JSON content (section 7) |
| `autoload/` | one file per owner | section 4 |
| `assets/` | David | sprites, tiles, sounds, music (CC0); every file gets a row in `CREDITS.md` |
| `tests/unit/` | the owner of the code under test | `test_<topic>.gd`, extends `GutTest`; Ioana keeps the template |
| `tools/` | Kevin; `tools/install_gut.*` Ioana | Python and shell tools; has a `.gdignore`, so Godot does not import it |
| `docs/` | Kevin (`contracts.md`, `ghid-git/`), Ioana (`DEFINITION_OF_DONE.md`) | documentation |
| `CONTRIBUTING.md`, `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/` | Ioana | contribution rules, PR and issue templates |
| `tests/fakes/`, `.gutconfig.json` | Ioana | `FakeQuizEngine` and other fakes, GUT settings used by CI |
| `README.md`, `LICENSE`, `.github/CODEOWNERS` | Kevin | front page, code licence, owner list (rules off) |
| `PRIVACY.md` | Kevin and Mariana | privacy note (RO/EN) |
| `.github/workflows/` | Ioana | CI: jobs `validate-data` and `gut-tests` |
| `project.godot` | small dedicated PRs only; Input Map and resolution: David; each autoload line: its owner | project settings |
| `export_presets.cfg` | Mariana | web export preset |
| `addons/` | nobody | GUT is installed by script, not committed |

File and folder names are `snake_case` (the exported .pck is case-sensitive). Class names and scene root nodes are `PascalCase`.

## 4. Autoloads

Order in Project Settings > Globals (top to bottom):

| # | Name | Script | Owner | Purpose | Freeze |
|---|---|---|---|---|---|
| 1 | `Settings` | `autoload/settings.gd` | Mariana | language, volumes, text size, telemetry opt-out | 2026-10-19 |
| 2 | `GameState` | `autoload/game_state.gd` | Mariana (PROPOSAL) | runtime state that gets saved (section 12) | 2026-10-26 |
| 3 | `QuestionBank` | `autoload/question_bank.gd` | Kevin | loads and serves `data/*.json` | 2026-10-19 |
| 4 | `SaveManager` | `autoload/save_manager.gd` | Mariana | `user://save.json` | 2026-10-26 |
| 5 | `Telemetry` | `autoload/telemetry.gd` | Mariana (client), Kevin (catalog) | sends events (section 13) | 2026-10-26 |
| 6 | `SceneRouter` | `autoload/scene_router.gd` | David | map and chapter changes, battle overlay | 2026-10-19 |

Rules:

- **Never name an autoload `Logger`**: Godot has a built-in class with that name.
- An autoload script does not declare a `class_name` equal to its autoload name.
- Autoloads never reach into scenes by node path. They talk through the signals and methods in this file.
- `QuizEngine` is **not** an autoload: it is a `RefCounted`, one instance per battle (section 8).

## 5. Input Map

Already in `project.godot` (keyboard part). Owner: David.

| Action | Keyboard (physical keys) | Touch (Mariana's TouchControls) |
|---|---|---|
| `move_up` | Up, W | joystick up |
| `move_down` | Down, S | joystick down |
| `move_left` | Left, A | joystick left |
| `move_right` | Right, D | joystick right |
| `interact` | Z, Enter, Space | A button |
| `cancel` | X, Escape | B button |
| `menu` | Tab, M | menu button |

Rules:

- Gameplay reads input by **polling**: `Input.is_action_pressed()` / `Input.is_action_just_pressed()`. Not in `_unhandled_input()`: the touch buttons use `Input.action_press()`, which creates no `InputEvent`.
- The built-in `VirtualJoystick` starts on the `ui_*` actions with deadzone 0: set it to the `move_*` actions and a deadzone of 0.3 to 0.5.
- A tap can also arrive as an emulated mouse click. Each control handles one kind only, so a tap never counts twice.
- No movement during dialogue, screen fades or battles. After a battle, held movement keys are ignored until released.
- Gameplay does not use the `ui_*` actions. UI Controls keep their built-in `ui_*` focus navigation.

## 6. Settings and UI text keys

```gdscript
# autoload/settings.gd (Mariana)
signal language_changed(code: String)

var lang: String = "ro"  # "ro" | "en"

func set_language(code: String) -> void:
	# Sets TranslationServer locale, stores the choice, emits language_changed(code).
	pass
```

PROPOSAL, frozen with the Settings screen on 2026-11-02:

```gdscript
var music_volume: float = 1.0       # 0.0 to 1.0
var sfx_volume: float = 1.0         # 0.0 to 1.0
var text_size: int = 0              # 0 normal, 1 large
var telemetry_enabled: bool = true  # opt-out toggle; false means nothing is sent
```

Settings persist in `user://settings.cfg` (ConfigFile).

**UI text keys** (all text written by the team for menus, buttons, labels, prompts):

- File: `i18n/ui.csv`, UTF-8, columns `keys,en,ro`. Godot imports it into `.translation` files (gitignored).
- Keys are `UPPER_SNAKE_CASE` with one prefix:

| Prefix | Used for | Example |
|---|---|---|
| `MENU_` | title, pause, settings screens | `MENU_NEW_GAME` |
| `BATTLE_` | battle UI, enemy names | `BATTLE_FLEE`, `BATTLE_ENEMY_TENGU` |
| `WORLD_` | map prompts, signs, speaker names | `WORLD_PRESS_INTERACT`, `WORLD_SPEAKER_KENJI` |
| `UI_` | shared buttons, notices | `UI_OK`, `UI_PRIVACY_NOTICE` |

- A Control's `text` holds the key and is translated automatically. Code uses `tr("KEY")` and re-applies the text when `language_changed` fires.
- **Lesson content is not in `ui.csv`.** Questions, dialogue lines, mnemonics and explanations stay in `data/*.json` as `{"ro": "...", "en": "..."}` and are picked with `Settings.lang`.
- Any other CSV file stays outside `res://` or in a folder with `.gdignore` (Godot imports every CSV as a translation).

## 7. Content data (JSON)

Owner: Kevin. The full field list per file is in [data/README.md](../data/README.md); this section fixes what other modules read.

General rules:

- Every file is UTF-8 and a top-level object with `"schema_version": 1`. The loader fails loudly on another version.
- **Ids are strings**, `snake_case`, with a prefix: `h_` hiragana, `k_` katakana, `c1_` / `c2_` / `c3_` chapter pools, encounters and dialogues. Never numbers.
- Godot loads every JSON number as `float`: cast with `int()`. JSON arrays are untyped: copy them with `Array[String].assign()`.
- Japanese text uses the key `ja` (never `jp`). Text for players uses `{ "ro": ..., "en": ... }`.
- Load with `JSON.new()` and `parse()` so the error line can be reported (`JSON.parse_string()` only returns `null`).
- `python3 tools/validate_data.py` runs in CI (job `validate-data`) and must pass.

Files in v0:

| File | Top-level key | Shape |
|---|---|---|
| `data/hiragana.json` | `items` | array of kana items (46) |
| `data/katakana.json` | `items` | array of kana items (46) |
| `data/pools.json` | `pools` | `{ pool_id: { "items": [item_id, ...] } }` |
| `data/encounters.json` | `encounters` | section 10 |
| `data/dialogue/ch1.json` | `dialogues` | section 11 |

Kana item:

```json
{
  "id": "h_chi",
  "script": "hira",
  "kana": "ち",
  "romaji": "chi",
  "alt_romaji": ["ti"],
  "row": "t",
  "chapter": 1,
  "confusable_ids": ["h_sa"],
  "mnemonic": { "ro": "...", "en": "..." }
}
```

`script` is `"hira"` or `"kata"`. `row` is one of `a k s t n h m y r w`, or `n_final` for ん / ン. `romaji` is Hepburn; `alt_romaji` lists other accepted spellings for typing mode. Audio fields are added later (Could) with a `schema_version` bump.

Pool ids frozen on 2026-10-19 for chapter 1: `c1_row_a`, `c1_row_k`, `c1_row_s`, `c1_row_t`, `c1_row_n`, `c1_row_h`, `c1_row_m`, `c1_row_y`, `c1_row_r`, `c1_row_w` (one row each, for practice and NPC lessons), `c1_rows_a_k`, `c1_rows_s_t`, `c1_rows_n_h_m`, `c1_rows_y_r_w` (the 4 regular enemies: each asks the new rows since the previous enemy, so battles cover all 46 hiragana before the boss) `c1_boss_tengu` and `c1_boss_tengu_phase2` (the 17 hiragana with `confusable_ids`, for the Tengu's phase 2). Chapter 2 pool ids are fixed on 2026-11-16 (`c2_katakana_all` in `pools.json` is a draft until then). Scenes and encounters pass only pool ids, never item lists.

**Real data for stubs (use it now).** Fakes and first scenes read these ids, which already exist in `data/`:

| What | Id | Content |
|---|---|---|
| Pools | `c1_row_a`, `c1_row_k` | 10 hiragana: あいうえお, かきくけこ |
| Encounter | `c1_kappa_1` | pool `c1_rows_a_k` (the same 10 hiragana), enemy `placeholder.tres` |
| Boss encounter | `c1_boss_tengu` | pool `c1_boss_tengu` (all 46 hiragana) |
| Dialogue | `c1_intro_kenji` | 6 lines by Kenji-sensei, the last one sets the flag `c1_intro_done` |

## 8. QuestionBank and QuizEngine

Between Kevin (provider) and Ioana (battle). Frozen **2026-10-19**.

### QuestionBank (autoload, read-only access to `data/`)

```gdscript
# autoload/question_bank.gd (Kevin)
func load_all() -> Error
func get_item(item_id: String) -> Dictionary                              # {} if unknown
func items_for(chapter: int, rows: Array[String]) -> Array[Dictionary]
func get_pool(pool_id: String) -> Array[String]                           # item ids; [] if unknown
func get_encounter(encounter_id: String) -> Dictionary                    # section 10; {} if unknown
func get_dialogue(dialogue_id: String) -> Array[Dictionary]               # section 11; [] if unknown
```

`get_encounter()` and `get_dialogue()` are **PROPOSALS** so that one loader reports all JSON errors. David and Ioana confirm them before the freeze.

### QuizEngine (one per battle)

```gdscript
# quiz/quiz_engine.gd (Kevin)
class_name QuizEngine
extends RefCounted

signal answered(qid: String, item_id: String, correct: bool, elapsed_ms: int)

func _init(bank: Object = null) -> void      # data source; null = the QuestionBank autoload
func start(pool_id: String, rng_seed: int = -1) -> void
func next_question() -> Dictionary
func submit(qid: String, answer: String, elapsed_ms: int) -> Dictionary
func get_state() -> Dictionary
func set_state(state: Dictionary) -> void
```

The parameter is named `rng_seed`, not `seed`, because `seed()` is a built-in GDScript function.

`next_question()` returns:

```gdscript
{
	"qid": "q_0001",                         # unique within this engine instance
	"item_id": "h_ka",
	"mode": "choice",                        # "choice" (v0.1) | "type" (Should) | "listen_choice" (Could)
	"prompt_text": "か",
	"prompt_audio": "",                      # res:// path or ""
	"choices": ["ka", "ki", "ta", "na"],     # Array[String]; 4 in "choice" mode, [] in "type" mode
}
```

`submit()` returns:

```gdscript
{
	"correct": true,
	"expected": "ka",                        # always shown to the player, not only a colour
	"explain": { "ro": "...", "en": "..." },
}
```

Rules:

- `QuizEngine.new()` uses the `QuestionBank` autoload. Tests pass any object with `get_pool()`, `get_item()` and `items_for()` (`QuizEngine.new(fake_bank)`), so they do not depend on `data/`.
- `rng_seed = -1` means random. Any other value makes the order and the distractors deterministic (used by tests).
- After `start()`, `next_question()` never returns an empty dictionary: when the pool runs out, it reshuffles, and the same item never comes twice in a row. The only exception is a pool that `start()` could not find: then `start()` and `next_question()` call `push_error()` and `next_question()` returns `{}`.
- `submit()` emits `answered` exactly once per `qid`. An unknown or already answered `qid` returns `{}` and calls `push_error()` (tests use `assert_push_error`).
- Distractors come only from rows the player has already met and never equal the expected answer. "Met" means every row, in the teaching order `a k s t n h m y r w n_final`, up to the last row used by the pool. Confusable kana (`confusable_ids`) come first, then the others; no reading appears twice.
- `explain` is the item's `mnemonic` from `data/`. Both strings stay `""` until Kevin writes the mnemonic; the battle then shows only `expected`, with a `BATTLE_` text from `ui.csv`.
- `"choice"` answers are compared exactly. `"type"` answers are normalised inside the engine (trim, lower case, romaji to kana).
- The engine has no nodes, no UI and no timers. The battle UI measures `elapsed_ms`. **The battle decides damage**, the engine only says correct or wrong.
- The engine does not call `Telemetry`; the battle forwards `answered` (section 13).
- `get_state()` returns `{ item_id: { "box": int, "seen": int, "wrong": int } }` for the save file (Leitner boxes 1 to 3 are Should). `set_state()` accepts the same shape, casts the numbers with `int()` (a JSON save gives floats) and keeps `box` between 1 and 3.
- Every `submit()` adds 1 to `seen`. A correct answer moves the item one box up (at most 3); a wrong one adds 1 to `wrong` and sends the item back to box 1.
- v0.1 asks only `"choice"` questions. `"type"` comes after `RomajiConverter` (decision 10, 2026-11-16).

### FakeQuizEngine (Ioana)

`tests/fakes/fake_quiz_engine.gd` extends `QuizEngine`, overrides the same methods and returns scripted questions. BattleModel receives its engine from outside (constructor or `setup()`), so tests pass the fake. Any signature change in `QuizEngine` updates the fake in the same pull request.

## 9. Battle hand-off

Between David (world) and Ioana (battle). Frozen **2026-10-19**.

```gdscript
# autoload/scene_router.gd (David)
signal map_changed(map_path: String)
signal battle_ended(result: Dictionary)

func goto_map(map_path: String, spawn_id: String) -> void
func goto_chapter(chapter: int) -> void
func start_battle(encounter_id: String) -> void
```

```gdscript
# battle/battle.tscn, root script (Ioana)
signal battle_finished(result: Dictionary)

func setup(encounter: Dictionary) -> void
```

Flow:

1. An `EnemyMarker` on the map (`@export var encounter_id: String`) calls `SceneRouter.start_battle(encounter_id)`.
2. `SceneRouter` gets the encounter with `QuestionBank.get_encounter(encounter_id)`, sets the world to `PROCESS_MODE_DISABLED`, instances `battle.tscn` on a `CanvasLayer` above the world (overlay, no scene change), calls `add_child()` and then `setup(encounter)`. The encounter dictionary includes its own `"id"`.
3. The battle emits `battle_finished(result)` exactly once.
4. `SceneRouter` frees the overlay, re-enables the world and emits `battle_ended(result)`. On `"win"` it appends `encounter_id` to `GameState.defeated`.

```gdscript
# result
{
	"encounter_id": "c1_kappa_1",
	"outcome": "win",                        # "win" | "lose" | "flee"
	"correct": 5,
	"wrong": 2,
}
```

- `"lose"`: the player returns to the same map cell and the enemy stays. A "retry" inside the battle (Ioana's choice) emits nothing until the final outcome.
- The battle scene also runs alone (F6) with a default encounter when `setup()` is never called.
- `TouchControls` and the overlay stay outside the disabled world, so they keep working.
- Maps and chapters change with `goto_map()` / `goto_chapter()` (scene change with a fade). Battles never change the scene.

## 10. Battle data

Between Kevin (`data/encounters.json`) and Ioana (enemy `.tres`). Frozen **2026-10-19**.

```json
{
  "schema_version": 1,
  "encounters": {
    "c1_boss_tengu": {
      "chapter": 1,
      "pool_id": "c1_boss_tengu",
      "phase2_pool_id": "c1_boss_tengu_phase2",
      "is_boss": true,
      "enemy": "res://battle/data/enemies/placeholder.tres"
    }
  }
}
```

| Field | Type | Meaning |
|---|---|---|
| key | String | encounter id, used by `EnemyMarker.encounter_id` and in `GameState.defeated` |
| `chapter` | int (float in JSON) | chapter number |
| `pool_id` | String | a key of `data/pools.json` |
| `is_boss` | bool | boss rules (phase 2, higher HP) |
| `enemy` | String | `res://` path of an `EnemyData` or `BossData` `.tres` |
| `phase2_pool_id` | String, optional (PROPOSAL) | harder pool for boss phase 2 (Should) |

```gdscript
# battle/data/enemy_data.gd (Ioana)
class_name EnemyData
extends Resource

@export var id: String = ""
@export var name_key: String = ""            # ui.csv key, e.g. BATTLE_ENEMY_TENGU
@export var max_hp: int = 10
@export var attack: int = 1
@export var defense: int = 0
@export var sprite: Texture2D
```

```gdscript
# battle/data/boss_data.gd (Ioana)
class_name BossData
extends EnemyData

@export var phase2_hp_ratio: float = 0.5     # phase 2 starts at or below this share of max_hp
```

- The question pool lives only in `encounters.json`, not in the `.tres`.
- Never write to a loaded `.tres`: Godot shares one instance. Copy the stats into a runtime `Battler` (`RefCounted`) and test that `EnemyData` stays unchanged.

## 11. Dialogue

Between Kevin (`data/dialogue/*.json`) and David (`DialogueBox`). Frozen **2026-10-19**.

```json
{
  "schema_version": 1,
  "dialogues": {
    "c1_intro_kenji": [
      {
        "speaker": "kenji",
        "text": { "ro": "Bine ai venit în Tokyo!", "en": "Welcome to Tokyo!" },
        "ja": "ようこそ、とうきょうへ！",
        "romaji": "Youkoso, Toukyou e!",
        "set_flag": ""
      }
    ]
  }
}
```

| Field | Type | Meaning |
|---|---|---|
| key | String | dialogue id, `c<chapter>_<place>_<speaker>` |
| `speaker` | String | speaker id; display name from `ui.csv` key `WORLD_SPEAKER_<ID>` |
| `text` | `{ro, en}` | required, shown in `Settings.lang` |
| `ja` | String | Japanese line, may be `""` |
| `romaji` | String | reading of `ja`, may be `""` |
| `set_flag` | String | when the line is shown, `GameState.flags[set_flag] = true`; `""` means none |

Chapter 1 dialogues (PROPOSAL for David, frozen with this section on 2026-10-19). The lines are in `data/dialogue/ch1.json`. Where each dialogue starts (an NPC, a trigger area, or SceneRouter after a battle) is David's choice; the order, the ids and the flags are the contract.

| # | Dialogue id | Plays | Sets flag | Then |
|---|---|---|---|---|
| 1 | `c1_intro_kenji` | at the start of chapter 1 | `c1_intro_done` | |
| 2 | `c1_lesson1_kenji` | lesson: rows a and k | `c1_lesson1_done` | battle `c1_kappa_1` |
| 3 | `c1_lesson2_kenji` | after `c1_kappa_1`; rows s and t | `c1_lesson2_done` | battle `c1_kodama_1` |
| 4 | `c1_lesson3_kenji` | after `c1_kodama_1`; rows n, h and m | `c1_lesson3_done` | battle `c1_tanuki_1` |
| 5 | `c1_lesson4_kenji` | after `c1_tanuki_1`; rows y, r, w and ん | `c1_lesson4_done` | battle `c1_kappa_2` |
| 6 | `c1_shrine_kenji` | after `c1_kappa_2`, at the shrine | none | |
| 7 | `c1_tengu_before` | in the shrine, before the boss | none | battle `c1_boss_tengu` |
| 8 | `c1_tengu_after` | after the player beats the Tengu | `c1_treasure_hiragana` | |
| 9 | `c1_end_kenji` | at the end of chapter 1 | `c1_done` | post-test (section 13), then chapter 2 |

- A flag is set when its line is shown, so a save made after a dialogue keeps it. SceneRouter can use the flags to decide what comes next, for example the battle `c1_kodama_1` only after `c1_lesson2_done`.
- Speakers in chapter 1: `kenji` and `tengu`, shown with the `ui.csv` keys `WORLD_SPEAKER_KENJI` and `WORLD_SPEAKER_TENGU`.
- The town NPC dialogues (`c1_town_*`) come later in one pull request, after David's map.

```gdscript
# world/dialogue/dialogue_box.gd (David)
signal dialogue_finished(dialogue_id: String)

func play(dialogue_id: String) -> void
```

- `DialogueBox` gets the lines from `QuestionBank.get_dialogue()` and redraws the current line on `Settings.language_changed`.
- The player cannot move while a dialogue is open.

## 12. Save schema (placeholder)

Owner: Mariana. Frozen **2026-10-26**. Saving is Should for v0.1.

`GameState` (PROPOSAL) holds everything that is saved:

| Field | Type | Written by |
|---|---|---|
| `map` | String (`res://` path) | David |
| `cell` | Vector2i, stored as `[x, y]` | David |
| `facing` | Vector2i, stored as `[x, y]` | David |
| `chapter` | int | David |
| `defeated` | Array[String] of encounter ids | David (SceneRouter) |
| `flags` | Dictionary, String to bool | David (dialogue) |
| `hp`, `max_hp` | int | Ioana |
| `quiz` | Dictionary from `QuizEngine.get_state()` | Kevin |
| `pretest` | Dictionary `{ "form": "A", "score": 6 }`, `{}` before the pre-test | Kevin (pre-test screen) |
| `version` | int, save schema version | Mariana |
| `build` | String, game version | Mariana |

```json
{
  "version": 1,
  "build": "0.1.0",
  "world": { "map": "res://world/maps/tokyo_town.tscn", "cell": [12, 7], "facing": [0, 1], "chapter": 1, "defeated": ["c1_kappa_1"], "flags": { "c1_intro_done": true } },
  "battle": { "hp": 20, "max_hp": 20 },
  "quiz": { "h_ka": { "box": 2, "seen": 4, "wrong": 1 } }
}
```

```gdscript
# autoload/save_manager.gd (Mariana)
func save_game() -> Error
func load_game() -> Dictionary        # {} if there is no save or it is corrupted
func has_save() -> bool
func delete_save() -> void
```

- File: `user://save.json` (IndexedDB in the web build). Numbers come back as `float`: cast with `int()`.
- A corrupted file or an unknown `version` never crashes the game: the player gets a message and a new game.
- No personal data in the save file.

## 13. Telemetry event catalog (placeholder)

Catalog owner: **Kevin**. Client (`autoload/telemetry.gd`): **Mariana**. Frozen **2026-10-26**, together with the backend choice and the test URL for Mariana.

```gdscript
# autoload/telemetry.gd (Mariana)
func log_event(event: String, data: Dictionary = {}) -> void
```

Fields added by `Telemetry` to every event:

| Field | Value |
|---|---|
| `v` | event schema version, `1` |
| `build` | `application/config/version` |
| `sid` | `Crypto.new().generate_random_bytes(16).hex_encode()`, created at start, **kept only in memory** |
| `t_ms` | milliseconds since the session started |
| `platform` | `"web_desktop"` \| `"web_android"` \| `"web_ios"` \| `"desktop"` |
| `lang` | `Settings.lang` |

Wire format (PROPOSAL, frozen with the catalog): each event travels as one JSON object, the six fields above plus `event` (the name from the catalog) and `data` (its fields). A batch is a JSON array of such objects, sent as the `text/plain` body of one POST. The backend stores one row per event with the columns `received_at, v, build, sid, t_ms, platform, lang, event, data`, where `data` is kept as JSON text. The analysis reads exactly this export.

```json
{"v": 1, "build": "0.1.0", "sid": "9f2c41d0e7ab5c3812fe06a9d4b7c1e5", "t_ms": 51234, "platform": "web_ios", "lang": "ro",
 "event": "answer", "data": {"encounter_id": "c1_kappa_1", "qid": "q_0003", "item_id": "h_ki", "mode": "choice",
 "correct": false, "elapsed_ms": 3120, "chosen": "sa"}}
```

Catalog (v1, PROPOSAL until the freeze on 2026-10-26):

| Event | Emitted by | When | `data` fields |
|---|---|---|---|
| `session_start` | Telemetry (Mariana) | after "Tap to start" | none |
| `chapter_enter` | SceneRouter (David) | a chapter starts, also after loading a save | `chapter` (int) |
| `answer` | BattleScene (Ioana), on `QuizEngine.answered` | every answer in a battle | `encounter_id`, `qid`, `item_id`, `mode`, `correct` (bool), `elapsed_ms` (int), `chosen` |
| `battle_end` | SceneRouter (David), on `battle_finished` | end of every battle | `encounter_id`, `outcome` (`"win"` \| `"lose"` \| `"flee"`), `correct` (int), `wrong` (int) |
| `pretest` | pre-test screen (Kevin) | after the 10 pre-test items | `form` (`"A"` \| `"B"`), `score` (int, 0 to 10), `n_items` (10) |
| `posttest` | post-test screen (Kevin) | after the Tengu | `form`, `score`, `n_items`, `pre_form`, `pre_score` (from `GameState.pretest`; `""` and `-1` if unknown) |
| `quit` | Telemetry (Mariana) | page hidden or closed | `scene` (scene file name, for example `"tokyo_town"`) |

`chosen` is the reading the player picked, one of the four choices (for example `"sa"` when the expected answer was `"ki"`). It shows which kana get confused. In `"type"` mode it stays `""`: typed text is never logged.

Pre-test and post-test (decision 9):

- Two forms of 10 hiragana, one kana from each row (ん counts with the w row) and no kana in both forms. Form A is the pool `c1_test_a` (あ き し つ ぬ ひ め ゆ る わ), form B is the pool `c1_test_b` (お こ さ ち ね ほ む よ れ ん). Each form has 6 kana from the confusable pairs.
- The pre-test picks A or B at random; the post-test uses the other form, so nobody answers the same items twice.
- The test screens use their own `QuizEngine`, show no correct answers and no `explain`, and never save its state.
- The pre-test result goes into `GameState.pretest` (section 12). The `posttest` event repeats it, so one event holds both scores of one player: we compare before and after without any id that recognises the player.
- The pool ids `c1_test_a` and `c1_test_b` freeze with the other chapter 1 pool ids on 2026-10-19.

Rules:

- **Only ids, numbers and fixed values.** No free text, no names, no typed text (in `"type"` mode only `correct` is logged). No persistent id.
- `Settings.telemetry_enabled == false` means nothing is sent.
- Events are sent in small batches (for example at the end of a battle) and also when the page loses focus.
- Backend (PROPOSAL): Google Apps Script writing to a Google Sheet, POST with a `text/plain` body (no CORS preflight). Alternative: Supabase with an insert-only policy. The endpoint URL ends up in the public web build, so it must accept inserts only.
- Raw data never enters the repo. Only aggregated numbers go to `docs/data/`. Raw data is deleted by 2027-03-01 (see [PRIVACY.md](../PRIVACY.md)).

## 14. Changelog

| Version | Date | Change | Approved by |
|---|---|---|---|
| v0 | 2026-10-05 | First draft (Kevin) | to be presented on 2026-10-12 |
| v0.1 | 2026-10-06 | Real data for stubs and one pool per regular enemy (section 7). QuizEngine details: `_init(bank)`, distractors, `explain`, boxes, choice mode only in v0.1 (section 8) | to be reviewed by Ioana |
| v0.2 | 2026-10-07 | Section 12: `pretest` field. Section 13: event catalog v1 (`answer` gets `encounter_id` and `chosen` instead of `choice_index`; `posttest` repeats the pre-test with `pre_form` and `pre_score`; forms `c1_test_a` and `c1_test_b`; wire format). Sections 7 and 10: pool `c1_boss_tengu_phase2` for the Tengu's phase 2 | to be reviewed by Mariana (12, 13) and Ioana (7, 10) |
| v0.3 | 2026-10-07 | Section 11: order, ids and flags of the 9 dialogues of chapter 1 | to be agreed by David (11) |
