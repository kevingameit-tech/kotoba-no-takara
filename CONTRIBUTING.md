# Cum contribui

> **v0**, scris de Kevin pe 5 oct 2026. Proprietar: **Ioana**. Ea îl revizuiește și îl îngheață până pe 19 oct.
> O regulă nouă se discută luni la laborator și intră apoi printr-un PR.

Dacă Git și GitHub sunt noi pentru tine, citește întâi ghidul pas cu pas: [docs/ghid-git/README.md](docs/ghid-git/README.md). Aici sunt doar regulile.

## Cuprins

1. [Înainte de primul commit](#1-înainte-de-primul-commit)
2. [Branch-uri](#2-branch-uri)
3. [Commit-uri](#3-commit-uri)
4. [Pull Request](#4-pull-request)
5. [Review](#5-review)
6. [Ciclul săptămânal](#6-ciclul-săptămânal)
7. [Scene (.tscn) și project.godot](#7-scene-tscn-și-projectgodot)
8. [Ce nu intră niciodată în repo](#8-ce-nu-intră-niciodată-în-repo)
9. [AI, tutoriale și cod copiat](#9-ai-tutoriale-și-cod-copiat)
10. [Cod și teste](#10-cod-și-teste)

## 1. Înainte de primul commit

- **Godot 4.7.2 standard** (nu .NET). Nu deschide proiectul cu altă versiune: Godot rescrie fișierele și apar conflicte.
- **Commit cu adresa noreply de la GitHub.** Repo-ul e public, deci adresa din commit o vede oricine. Verifică:
  ```bash
  git config user.email
  ```
  Trebuie să vezi ceva de forma `ID+utilizator@users.noreply.github.com`. Adresa noreply se leagă tot de contul tău, deci commit-urile apar în Insights > Contributors.
- **Pe Windows:** `git config --global core.autocrlf input` (fișierele rămân cu capăt de rând LF).
- **GUT** se instalează cu `bash tools/install_gut.sh` (Windows: `powershell -ExecutionPolicy Bypass -File tools/install_gut.ps1`). Nu îl adăuga în Git.

## 2. Branch-uri

Nu lucrezi niciodată direct pe `main`. `main` e protejat: intră doar prin Pull Request.

Formatul numelui: `<tip>/<zonă>-<subiect>`

| Parte | Valori |
|---|---|
| tip | `feat` (funcție nouă), `fix` (reparație), `test` (doar teste), `docs` (doar documentație) |
| zonă | `world`, `battle`, `ui`, `i18n`, `quiz`, `data`, `save`, `telemetry`, `ci`, `tools`, `docs`, `team` |
| subiect | 1 până la 3 cuvinte în engleză, litere mici, despărțite prin cratimă |

Exemple:

```text
feat/battle-damage
fix/ui-romanian-letters
test/quiz-distractors
docs/team-mariana
```

Reguli:

- Pornești mereu din `main` actualizat: `git switch main`, `git pull`, apoi `git switch -c feat/...`.
- Un branch trăiește 1 până la 3 zile. Dacă durează mai mult, sarcina e prea mare: împarte issue-ul.
- După merge, branch-ul se șterge (butonul „Delete branch” din PR).

## 3. Commit-uri

Folosim [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). Mesajul e în engleză, ca și codul.

Formatul: `<tip>(<zonă>): <ce face, la imperativ>`

| Tip | Când |
|---|---|
| `feat` | funcție nouă |
| `fix` | reparație |
| `test` | teste noi sau schimbate |
| `docs` | documentație |
| `refactor` | aceeași funcție, cod mai curat |
| `chore` | date, configurări, unelte |
| `ci` | GitHub Actions |

Exemple bune:

```text
feat(world): add grid movement for Player
fix(ui): show ș and ț with Pixelify Sans
test(quiz): cover distractors for row k
docs(contracts): add Settings API
refactor(battle): move damage into BattleModel
chore(data): add hiragana row s
ci: run validate_data.py on every pull request
```

Exemple proaste: `update`, `fix stuff`, `final version 2`, `wip`.

**Commit-uri mici.** Un commit face o singură schimbare logică. Dacă nu o poți descrie într-un rând, e prea mare. Fă commit des și `git push` cel puțin o dată pe zi în care lucrezi.

**Lucru în pereche.** Cine scrie codul face commit-ul și îl adaugă pe colegul cu care a lucrat la final:

```text
feat(battle): add flee option

Co-authored-by: Prenume <ID+utilizator@users.noreply.github.com>
```

## 4. Pull Request

1. **Titlul** respectă tot Conventional Commits, de exemplu `feat(battle): add damage formula`.
2. **Descrierea** urmează șablonul (apare singur):
   - `Closes #N`: issue-ul se închide automat la merge;
   - **De ce**: 2 rânduri;
   - **Cum testezi**: pași pe care un coleg îi poate repeta;
   - **o captură** de ecran sau un GIF pentru orice se vede; pentru logică pură, rezultatul GUT.
3. **1 aprobare** de la cineva care **a rulat** codul pe calculatorul lui, nu doar a citit diff-ul. Când `.github/CODEOWNERS` e activ, GitHub îl cere automat ca reviewer pe proprietarul folderului. Aprobarea poate veni de la orice coleg care a rulat codul.
4. **CI verde**: joburile `validate-data` și `gut-tests` trebuie să treacă.
5. **Merge commit** („Create a merge commit”). Fără squash și fără rebase merge: fiecare commit al tău rămâne în istoric și în statistici.
6. Nimeni nu face merge fără aprobare, nici Kevin: regulile de pe `main` nu au excepții pentru admin.
7. **PR mic**: ideal sub 300 de rânduri schimbate (fără fișiere generate de Godot). Pentru o părere devreme, deschide un **Draft PR**.
8. Un PR care schimbă un contract din [docs/contracts.md](docs/contracts.md) după data de înghețare are nevoie de **2 aprobări**, dintre care una de la cealaltă parte a contractului.
9. **Conflict cu main?** Aduci `main` în branch-ul tău, rezolvi, rulezi din nou testele:
   ```bash
   git switch feat/battle-damage
   git fetch origin
   git merge origin/main
   ```
   Pentru fișiere `.tscn` și `.tres` vezi [secțiunea 7](#7-scene-tscn-și-projectgodot).

## 5. Review

Reviewer-ul descarcă branch-ul și îl rulează:

```bash
git fetch origin
git switch feat/battle-damage
```

Checklist pentru reviewer:

- [ ] Am rulat codul (editor sau build web), nu doar am citit diff-ul.
- [ ] Face ce cere issue-ul; pașii din „Cum testezi” merg.
- [ ] Logica nouă are teste GUT; CI e verde.
- [ ] Schimbă doar fișierele autorului sau proprietarul lor a aprobat.
- [ ] Respectă [docs/contracts.md](docs/contracts.md) (nume, semnături, chei).
- [ ] Fără text UI scris direct în cod: doar chei (`MENU_`, `BATTLE_`, `WORLD_`, `UI_`) sau câmpuri `{ro, en}` din JSON.
- [ ] GDScript tipizat, nume clare, după style guide.
- [ ] Fără `print()` uitate, fără cod comentat, fără fișiere în plus (build-uri, log-uri).
- [ ] Asset nou: rând în [CREDITS.md](CREDITS.md).
- [ ] Am pus cel puțin o întrebare „de ce?” și autorul a explicat.

Cum dăm review:

- Comentăm codul, nu persoana. Propunem ceva concret: „aici ar merge `clampi()`”, nu „e greșit”.
- Răspundem la un review cerut în 24 de ore, maxim 48.
- **Kevin face review, dar nu repară codul colegilor.** Scrie comentariul, iar autorul face schimbarea. La fel pentru toți: nu împingem commit-uri în branch-ul altcuiva fără să întrebăm.
- „Request changes” înseamnă „mai e de lucru”, nu „ai greșit”. După corectură, reviewer-ul verifică din nou și aprobă.

## 6. Ciclul săptămânal

| Când | Ce |
|---|---|
| **Duminică, 22:00** | PR-urile săptămânii sunt merge-uite. Ce nu e gata trece la săptămâna următoare. |
| **Luni, la laborator** | 15 min demo pe telefon, 10 min retro, 20 min planificare, apoi lucru în perechi |
| **Joi** | check-in de 3 rânduri în chat-ul echipei: gata / urmează / blocat |
| **O dată pe săptămână** | 1 oră de Q&A Godot cu David |

Exemplu de check-in:

```text
Gata: BattleModel calculează daunele (#14)
Urmează: teste pentru WIN, LOSE și FLEE
Blocat: aștept encounters.json (#9)
```

Board-ul e în GitHub Projects, cu o iterație pentru fiecare săptămână de laborator. Fără laborator pe 30 nov. Vacanța: 24 dec până la 10 ian, fără muncă obligatorie.

## 7. Scene (.tscn) și project.godot

- **Un proprietar pe scenă** (vezi `.github/CODEOWNERS`). Vrei o schimbare în scena altcuiva? Deschide un issue sau cere-i proprietarului. Ca să folosești scena lui, o pui ca instanță (nod copil) în scena ta.
- **Nu face niciodată merge de mână la un `.tscn` sau `.tres`.** La conflict păstrezi o singură parte și refaci schimbarea în editor. În timpul `git merge origin/main`, `--ours` este versiunea ta și `--theirs` este versiunea din `main`:
  ```bash
  git checkout --theirs world/maps/tokyo_town.tscn
  git add world/maps/tokyo_town.tscn
  ```
  Apoi deschizi scena în Godot, refaci schimbarea ta, salvezi și faci commit.
- **`project.godot` doar în PR-uri mici, dedicate** (de exemplu `chore(project): add Input Map actions`). Anunți în chat înainte. Godot schimbă uneori singur `project.godot`: înainte de commit, verifică `git diff project.godot`. Dacă nu ai vrut schimbarea, o anulezi cu `git restore project.godot`.
- **Fișierele `.uid` intră în Git** împreună cu scriptul sau scena lor. Muți și redenumești fișiere doar din Godot (panoul FileSystem), ca `.uid` să le urmeze.
- **Nume de fișiere în `snake_case`.** Build-ul web face diferența între litere mari și mici.

## 8. Ce nu intră niciodată în repo

- Build-uri (`build/`, `*.pck`, `*.wasm`, arhive exportate). Build-ul web îl face CI-ul.
- Log-uri, exporturi din formulare sau tabele, date brute de la testeri. În repo intră doar cifre agregate, în `docs/data/`.
- `addons/gut/` (se instalează cu scriptul) și `.godot/` (cache local).
- Parole, chei API, token-uri, fișiere `.env`.
- Date personale: nume de testeri, e-mailuri, numere de telefon, poze sau video cu oameni.
- Fișiere mari (peste 5 MB) fără discuție în echipă.

Ai pus ceva din greșeală? Spune-i imediat lui Kevin. Nu încerca să rescrii singur istoria (`git push --force` este blocat pe `main`).

## 9. AI, tutoriale și cod copiat

- Poți folosi AI și tutoriale. **Regula: trebuie să poți explica fiecare rând pe care îl pui într-un PR.** La prezentare fiecare răspunde despre codul lui, fără notițe. Cine nu își explică codul pică.
- Nu lipi cod pe care nu îl înțelegi. Rescrie-l cu tipuri și cu numele noastre din [docs/contracts.md](docs/contracts.md).
- Doar material pentru Godot 4.3 sau mai nou. Semne că un tutorial e vechi: `TileMap` (noi folosim `TileMapLayer`), `KinematicBody2D`, `yield` (acum `await`), `export var` fără `@`.
- Cod luat din altă parte: verifici licența, scrii sursa într-un comentariu în fișier și adaugi un rând în [docs/LICENSES.md](docs/LICENSES.md).
- Recomandat: o propoziție în PR, „am folosit AI pentru ...”, ca reviewer-ul să știe ce să întrebe.

## 10. Cod și teste

- **GDScript tipizat:** `var hp: int = 10`, `func take_damage(amount: int) -> void:`.
- Urmăm [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): `snake_case` pentru variabile și funcții, `PascalCase` pentru clase și noduri, `UPPER_SNAKE_CASE` pentru constante.
- Niciun autoload nu se numește `Logger`: Godot are deja o clasă cu acest nume. Lista autoload-urilor e în [docs/contracts.md](docs/contracts.md#4-autoloads).
- Identificatorii și comentariile din cod sunt în engleză. Textul pentru jucător vine doar din chei (`tr("MENU_NEW_GAME")`) sau din câmpurile `{ro, en}` din `data/`.
- **Teste:** fiecare își testează propria logică. Fișierele sunt `tests/unit/test_<ce_testezi>.gd` și extind `GutTest`. Rulezi testele local înainte de push.
- Datele JSON le verifici cu `python3 tools/validate_data.py`.
- Textul în română se scrie cu ș și ț cu virgulă dedesubt (U+0218 până la U+021B: Ș ș Ț ț), niciodată cu sedilă (U+015E, U+015F, U+0162, U+0163).

Mulțumim! Întrebările merg în chat-ul echipei sau la laborator.
