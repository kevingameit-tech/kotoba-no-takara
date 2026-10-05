# 8. Git în Godot: ce comiți și ce nu

> Timp: 20 minute. Aici sunt capcanele specifice Godot. Majoritatea problemelor din echipele care încep cu Godot vin de aici.

## 8.1 Pe scurt

| Fișier sau folder | În Git? | De ce |
|---|---|---|
| `*.gd` (scripturi) | Da | Codul nostru. |
| `*.gd.uid` și alte `*.uid` | **Da** | Din Godot 4.4, fiecare script are un id stabil în fișierul `.uid` de lângă el. Fără el, referințele colegilor se strică. |
| `*.tscn` (scene), `*.tres` (resurse) | Da | Proprietar unul singur pe fiecare (capitolul 5). |
| `*.import` (lângă imagini, sunete, fonturi, CSV) | **Da** | Setările de import și id-ul fișierului. |
| `project.godot` | Da, dar | Doar în PR-uri mici, dedicate. |
| `export_presets.cfg` | Da | Preset-ul web comun (proprietar: Mariana). Fără secrete. |
| `data/*.json`, `i18n/ui.csv` | Da | Conținutul jocului și textele UI. |
| `assets/` (`.png`, `.ogg`), `fonts/` | Da | Mici, cu rând în `CREDITS.md`. |
| `.godot/` | **Nu** | Cache-ul local al editorului. Se reface singur. |
| `addons/gut/` | **Nu** | Îl instalează `tools/install_gut.sh`. |
| `*.translation` | **Nu** | Generate de Godot din `i18n/ui.csv`. |
| `build/`, `export/`, `*.pck`, `*.zip`, `*.exe` | **Nu** | Build-uri. Build-ul web îl face CI-ul. |
| Log-uri, date brute de la testeri | **Nu, niciodată** | Date personale și volum mare. Doar cifre agregate în `docs/data/`. |
| `.DS_Store`, `Thumbs.db`, `.vscode/`, `.idea/` | Nu | Fișiere ale sistemului sau ale editorului tău. |

Lista exactă a ce ignorăm e în [`.gitignore`](../../.gitignore). Dacă `git status` îți arată ceva din coloana „Nu”, nu-l adăuga. Spune-i lui Kevin, ca să completăm `.gitignore`.

## 8.2 Fișierele speciale, explicate

### `.godot/`

Godot ține aici cache-ul: importuri, lista de clase, starea editorului. Se reface singur la prima deschidere. Dacă ajunge în Git, fiecare coleg ar avea conflicte la fiecare deschidere a editorului.

### `*.uid`

Din Godot 4.4, lângă fiecare script apare un fișier mic, de exemplu `player.gd.uid`, cu un id de forma `uid://b8k3...`. Scenele trimit la script prin acest id, nu doar prin cale. De aceea:

- **comiți mereu `.uid` împreună cu scriptul lui** (în același commit),
- dacă muți un script, `.uid` trebuie să meargă după el (vezi 8.4).

Semn că ai uitat un `.uid`: la colegi apar fișiere `.uid` noi în `git status` după ce îți rulează branch-ul.

### `*.import`

Pentru fiecare imagine, sunet, font sau CSV, Godot creează un fișier `.import` cu setările de import (de exemplu filtrul pentru pixel art). Îl comiți. Rezultatul importului stă în `.godot/` și nu se comite.

### `addons/gut/`

GUT (framework-ul de teste) **nu** e în repo, ca să nu intre mii de rânduri de cod străin în statisticile noastre. Îl instalează scriptul:

```bash
bash tools/install_gut.sh
```

Pe Windows: `powershell -ExecutionPolicy Bypass -File tools/install_gut.ps1`.

Rulezi scriptul o dată după clonare. `project.godot` are plugin-ul GUT activat, deci dacă deschizi proiectul fără el, Godot se plânge că nu găsește `addons/gut/plugin.cfg`. Nu folosi niciodată `git add -f` pe `addons/`.

### `export_presets.cfg`

Ține preset-ul de export web (single-threaded, Compatibility). Îl comitem ca toți și CI-ul să folosească același preset. E sigur de comis: din Godot 4.1, parolele și cheile de export stau în `.godot/export_credentials.cfg`, care e ignorat.

Înainte de commit, uită-te totuși în diff:

```bash
git diff export_presets.cfg
```

Nu trebuie să apară căi personale (de exemplu `C:/Users/...` sau `/Users/...`), parole sau chei.

### `project.godot`

Setările întregului proiect: rezoluție, Input Map, autoload-uri, plugin-uri. Îl ating toți, deci e un loc ideal pentru conflicte. Regulile:

- se schimbă **doar în PR-uri mici, dedicate** (de exemplu `chore(project): add Input Map actions`),
- anunți în chat-ul echipei înainte,
- Input Map și rezoluția: David; fiecare rând de autoload: proprietarul lui.

## 8.3 Fișiere modificate de Godot fără să vrei

Godot rescrie uneori fișiere doar pentru că le-ai deschis: o scenă primește un id intern nou sau o proprietate în plus, `project.godot` primește o setare nouă, un `.tscn` al altcuiva apare ca „modified”.

**Regula: în commit intră doar ce ai vrut tu să schimbi.**

Înainte de fiecare commit:

```bash
git status
git diff --stat
```

Pentru fiecare fișier pe care nu l-ai schimbat intenționat:

```bash
git diff world/maps/tokyo_town.tscn      # te uiți ce s-a schimbat
git restore world/maps/tokyo_town.tscn   # anulezi schimbarea
```

Dacă același fișier „se modifică singur” la fiecare deschidere, spune-i proprietarului. De obicei înseamnă că versiunea din `main` a fost salvată cu altă versiune de Godot sau că lipsește un `.uid`.

Cel mai sigur mod de a evita asta: **toți pe exact Godot 4.7.2**.

## 8.4 Muți și redenumești doar din Godot

Muți sau redenumești fișiere **doar din panoul FileSystem al Godot** (click dreapta → **Rename...** sau **Move/Duplicate To...**, ori tragi fișierul în alt folder din același panou). Godot actualizează referințele din scene și mută și fișierul `.uid`.

Dacă muți un fișier din Finder, Explorer sau terminal, Godot nu află și scenele care îl foloseau se strică. Dacă ai făcut-o deja: mută și fișierul `.uid` (și `.import`) lângă el, apoi deschide Godot și verifică scenele.

După o mutare, `git status` arată fișierul vechi ca șters și pe cel nou ca adăugat. E normal. Le adaugi pe amândouă:

```bash
git add -A world/
```

(`-A` înseamnă „tot”: fișiere noi, schimbate și șterse din folderul respectiv.)

## 8.5 Majuscule și nume de fișiere

- Toate fișierele și folderele: **`snake_case`**, cu litere mici: `tokyo_town.tscn`, `battle_model.gd`.
- Windows și macOS nu fac diferența între `Player.gd` și `player.gd`. Build-ul web și CI-ul (Linux) **fac**. O cale scrisă cu altă literă mare merge la tine și pică pe telefon sau în CI.

**Redenumire doar a literelor mari** (de exemplu `Player.gd` → `player.gd`): pe Windows și macOS Git nu vede schimbarea. O faci în doi pași, din panoul FileSystem, cu `git add` între ei:

1. În Godot: `Player.gd` → `player_tmp.gd`. Apoi `git add -A world/player/`.
2. În Godot: `player_tmp.gd` → `player.gd`. Apoi din nou `git add -A world/player/`.
3. `git status` trebuie să arate `renamed: world/player/Player.gd -> world/player/player.gd` (și la fel pentru `.uid`).

Fără `git add` după primul pas, Git nu vede nimic la final.

## 8.6 Asset-uri binare (imagini, sunete, fonturi)

- Nu folosim Git LFS. Ținem fișierele mici: pixel art PNG, sunete scurte OGG.
- **Peste 5 MB**: discuți întâi în echipă (regula din CONTRIBUTING). GitHub refuză orice fișier peste 100 MB.
- Fișierele binare **nu se pot îmbina**. La conflict păstrezi o parte (capitolul 5). De aceea `assets/` are un singur proprietar: David.
- Fiecare asset nou are un rând în `CREDITS.md` (sursă, autor, licență). E în Definition of Done.
- Un fișier șters din repo rămâne în istoric pentru totdeauna. Nu pune „de probă” fișiere mari.

## 8.7 Lista de verificare înainte de commit

- [ ] `git status`: în listă sunt doar fișierele mele.
- [ ] Fișierele `.uid` și `.import` noi sunt incluse.
- [ ] Nicio scenă a altcuiva, niciun `project.godot` (dacă PR-ul nu e dedicat lui).
- [ ] Nimic din `.godot/`, `addons/`, `build/`.
- [ ] Am rulat jocul și testele GUT.
- [ ] Dacă am atins `data/`: `python3 tools/validate_data.py` trece.

---

Înapoi: [7. CI](07-ci.md) · Următorul: [9. Greșeli frecvente](09-greseli-frecvente.md)
