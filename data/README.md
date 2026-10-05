# data/

**Proprietar:** Kevin.
**Contract:** [docs/contracts.md](../docs/contracts.md), secțiunile „Content data (JSON)”, „Battle data” și „Dialogue”.

Aici stă tot conținutul lecțiilor, în JSON. Codul nu conține lecții sau text japonez: le citește de aici, prin `QuestionBank`.

Datele provin din aplicația JapanLogic a lui Kevin (lista de hiragana și katakana, cu romaji). Kevin este autorul aplicației și a permis folosirea datelor aici.

## Reguli generale

- Fișierele sunt UTF-8 fără BOM, cu indentare de 2 spații.
- Fiecare fișier este un obiect JSON cu `"schema_version": 1`.
- Id-urile sunt text (string), în `snake_case`, cu prefix: `h_` pentru hiragana, `k_` pentru katakana, `c1_`, `c2_`, `c3_` pentru pool-urile, luptele și dialogurile din capitolele 1, 2 și 3. Niciodată numere.
- Un id folosit deja nu se mai schimbă: îl folosesc scenele, salvarea și telemetria.
- Japoneza stă în cheia `ja` (nu `jp`). Textul pentru jucător are mereu forma `{ "ro": "...", "en": "..." }`.
- În română scriem ș și ț cu virgulă dedesubt, nu cu sedilă, și nu folosim linii lungi (em dash, en dash). Validatorul verifică asta.
- În Godot, numerele din JSON vin ca `float`. Pentru `chapter` folosește `int()`.

## hiragana.json și katakana.json

Forma: `{ "schema_version": 1, "items": [ ... ] }`. Fiecare fișier are cele 46 de kana de bază.

| Câmp | Tip | Ce înseamnă |
|---|---|---|
| `id` | string | `h_` + romaji (`h_ka`) sau `k_` + romaji (`k_ka`) |
| `script` | string | `hira` sau `kata` |
| `kana` | string | un singur caracter |
| `romaji` | string | Hepburn, litere mici: `shi`, `chi`, `tsu`, `fu`, `wo`, `n` |
| `alt_romaji` | listă de string | alte scrieri acceptate la tastare: `si`, `ti`, `tu`, `hu`, `o` (pentru を), `nn` (pentru ん) |
| `row` | string | rândul din tabel: `a`, `k`, `s`, `t`, `n`, `h`, `m`, `y`, `r`, `w`; ん are `n_final` |
| `chapter` | int | 1 pentru hiragana, 2 pentru katakana |
| `confusable_ids` | listă de id-uri | kana care seamănă la vedere și pe care începătorii le confundă des (de exemplu あ și お, ぬ și め, シ și ツ, ソ și ン). Perechile sunt simetrice. |
| `mnemonic` | `{ro, en}` | truc de memorare. Deocamdată e gol, îl completează Kevin. |

## pools.json

Forma: `{ "schema_version": 1, "pools": { "<pool_id>": { "items": [id, ...] } } }`.

- Câte un pool pentru fiecare rând de hiragana: `c1_row_a`, `c1_row_k`, `c1_row_s`, `c1_row_t`, `c1_row_n`, `c1_row_h`, `c1_row_m`, `c1_row_y`, `c1_row_r`, `c1_row_w`.
- ん (`h_n`, rândul `n_final`) este în `c1_row_w`, împreună cu わ și を, ca în manuale. Un pool cu o singură literă nu ar avea variante de răspuns.
- `c1_boss_tengu` are toate cele 46 de hiragana. `c2_katakana_all` are toate cele 46 de katakana.
- Scenele și luptele trimit doar un `pool_id`, niciodată o listă de id-uri.

## encounters.json

Forma: `{ "schema_version": 1, "encounters": { "<encounter_id>": { ... } } }`.

| Câmp | Tip | Ce înseamnă |
|---|---|---|
| `chapter` | int | numărul capitolului |
| `pool_id` | string | o cheie din `pools.json` |
| `is_boss` | bool | `true` doar pentru boss |
| `enemy` | string | calea `res://` spre fișierul `.tres` al inamicului (îl face Ioana) |
| `phase2_pool_id` | string, opțional (propunere) | pool-ul pentru faza 2 a boss-ului |

Prima variantă pentru capitolul 1:

| Luptă | Pool |
|---|---|
| `c1_kappa_1` | `c1_row_a` |
| `c1_kappa_2` | `c1_row_k` |
| `c1_kodama_1` | `c1_row_s` |
| `c1_tanuki_1` | `c1_row_t` |
| `c1_boss_tengu` (boss) | `c1_boss_tengu` |

Toate căile `enemy` arată deocamdată spre `res://battle/data/enemies/placeholder.tres`. Ioana le înlocuiește cu inamicii reali. Ce rânduri primește fiecare luptă se decide până la 10/30, odată cu conținutul capitolului 1.

## dialogue/ch1.json

Forma: `{ "schema_version": 1, "dialogues": { "<dialog_id>": [ replici ] } }`. Id-ul unui dialog arată așa: `c<capitol>_<loc>_<vorbitor>`, de exemplu `c1_intro_kenji`.

| Câmp | Tip | Ce înseamnă |
|---|---|---|
| `speaker` | string | id-ul vorbitorului (`kenji`). Numele afișat vine din `i18n/` (`WORLD_SPEAKER_KENJI`). |
| `text` | `{ro, en}` | obligatoriu, nu poate fi gol |
| `ja` | string | replica în japoneză, poate fi `""` |
| `romaji` | string | citirea lui `ja`, ca în JapanLogic: `ou` în loc de `ō` (`Toukyou`) |
| `set_flag` | string | steagul pus în `GameState.flags` când apare replica. `""` înseamnă niciunul. |

## Cum adaugi conținut

1. Faci un branch, de exemplu `feat/data-ch1-dialog`.
2. Editezi JSON-ul. Păstrezi ordinea câmpurilor și indentarea de 2 spații.
3. Rulezi `python3 tools/validate_data.py`. Trebuie să vezi „0 erori”.
4. Dacă ai schimbat ceva ce citesc alții (un câmp nou, un pool nou, un id nou de luptă), actualizezi și `docs/contracts.md`. După înghețare, schimbarea are nevoie de 2 aprobări.
5. Deschizi PR-ul. CI rulează validatorul în jobul `validate-data`.

- Un câmp nou: îl adaugi și în `tools/validate_data.py`, cu un test în `tools/test_validate_data.py`, și în tabelul de aici. Dacă se schimbă forma unui fișier, crește `schema_version`.
- Un fișier nou (de exemplu `vocab.json`): validatorul îl citește, dar dă un avertisment până îi scrii regulile.
- Testele validatorului: `python3 tools/test_validate_data.py`.

## Licență

Conținutul din `data/` (lecții, dialoguri, liste de kana, trucuri de memorare) și audio-ul înregistrat pentru lecții sunt sub licența **CC BY-NC-SA 4.0** (Atribuire, Necomercial, Distribuire în condiții identice). Codul jocului este sub licența MIT (vezi `LICENSE`). Detalii: [docs/LICENSES.md](../docs/LICENSES.md).

Datele provin din aplicația JapanLogic a lui Kevin.
