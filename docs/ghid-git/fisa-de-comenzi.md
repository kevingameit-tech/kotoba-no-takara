# Fișa de comenzi

> O pagină de ținut deschisă lângă terminal. Explicațiile sunt în capitolele ghidului. `<...>` înseamnă „pui aici textul tău”, fără `<` și `>`.

## O singură dată

| Ce faci | Comanda |
|---|---|
| Numele tău | `git config --global user.name "Prenumele tău"` |
| Adresa noreply | `git config --global user.email "<ID+utilizator>@users.noreply.github.com"` |
| Pull face merge | `git config --global pull.rebase false` |
| Curăță branch-urile șterse | `git config --global fetch.prune true` |
| Doar pe Windows | `git config --global core.autocrlf input` |
| Editor (VS Code) | `git config --global core.editor "code --wait"` |
| Autentificare | `gh auth login` (verifici cu `gh auth status`) |
| Clonezi | `git clone <adresa-de-la-butonul-Code>` |
| Instalezi GUT | `bash tools/install_gut.sh` (Windows: `powershell -ExecutionPolicy Bypass -File tools/install_gut.ps1`) |

## Fluxul pentru fiecare sarcină

```bash
git switch main
git pull
git switch -c feat/<zona>-<subiect>
# lucrezi, salvezi, rulezi testele
git status
git add <fisiere>
git commit -m "feat(<zona>): <ce face>"
git push -u origin feat/<zona>-<subiect>     # prima dată; apoi doar: git push
# PR pe GitHub -> review + CI verde -> Create a merge commit -> Delete branch
git switch main
git pull
git branch -d feat/<zona>-<subiect>
```

## Văd ce se întâmplă

| Ce faci | Comanda |
|---|---|
| Pe ce branch sunt, ce am schimbat | `git status` |
| Rândurile schimbate (nesalvate în staging) | `git diff` |
| Rândurile din staging | `git diff --staged` |
| Doar lista de fișiere | `git diff --stat` |
| Istoricul, scurt, cu desen | `git log --oneline --graph -15` |
| Branch-ul curent | `git branch --show-current` |
| Toate branch-urile locale | `git branch` |
| Cu ce adresă e ultimul commit | `git log -1 --format="%an <%ae>"` |

## Sincronizare cu `main`

```bash
git switch main
git pull
git switch <branch-ul-tau>
git merge main --no-edit
git push
```

Ai apăsat **Commit suggestion** sau **Update branch** pe GitHub? Pe branch-ul tău rulezi `git pull --no-edit` înainte să lucrezi mai departe.

## Conflicte

| Ce faci | Comanda |
|---|---|
| Ce fișiere au conflict | `git status` |
| Au rămas semne de conflict? | `git diff --check` |
| Păstrez varianta din `main` (`.tscn`, imagini) | `git restore --theirs <fisier>` |
| Păstrez varianta mea | `git restore --ours <fisier>` |
| Am rezolvat fișierul | `git add <fisier>` |
| Termin merge-ul | `git commit --no-edit` |
| Renunț, revin la starea de dinainte | `git merge --abort` |

## Anulez

| Situația | Comanda |
|---|---|
| Arunc schimbările dintr-un fișier | `git restore <fisier>` |
| Scot un fișier din staging (rămâne pe disc) | `git restore --staged <fisier>` |
| Anulez ultimul commit, păstrez schimbările (doar înainte de push) | `git reset --soft HEAD~1` |
| Corectez mesajul ultimului commit (doar înainte de push) | `git commit --amend -m "<mesaj nou>"` |
| Adaug un fișier uitat în ultimul commit (doar înainte de push) | `git add <fisier>` apoi `git commit --amend --no-edit` |
| Anulez un commit deja urcat | `git revert <id-commit>` apoi `git push` |
| Pun deoparte lucrul nesalvat | `git stash push -m "<descriere>"` |
| Îl aduc înapoi | `git stash pop` |
| Șterg stash-ul după un conflict rezolvat la `stash pop` | `git stash drop` |
| Scot din Git un fișier care nu trebuia (rămâne pe disc) | `git rm --cached <fisier>` (folder: `git rm -r --cached <folder>`) |

## Verificările proiectului (ca în CI)

| Ce verifici | Comanda |
|---|---|
| Datele JSON | `python3 tools/validate_data.py` |
| Testele validatorului | `python3 tools/test_validate_data.py` |
| Importul proiectului (o dată pe clonă nouă) | `godot --headless --import` |
| Testele GUT | `godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit` |
| Testele GUT, din editor | panoul GUT → **Run All** |

## Nume

| Ce | Forma | Exemplu |
|---|---|---|
| Branch | `<tip>/<zonă>-<subiect>` | `feat/battle-hp-bar` |
| Commit și titlu de PR | `<tip>(<zonă>): <ce face>` | `fix(ui): show ș and ț with Pixelify Sans` |
| Tipuri | `feat`, `fix`, `test`, `docs`, `refactor`, `chore`, `ci` | |
| Zone | `world`, `battle`, `ui`, `i18n`, `quiz`, `data`, `save`, `telemetry`, `ci`, `tools`, `docs`, `team` | |
| Lucru în pereche | rând la finalul mesajului | `Co-authored-by: Prenume <ID+utilizator@users.noreply.github.com>` |

## PR: ce trebuie să conțină

`Closes #N` · De ce (2 rânduri) · Cum testezi · Captură · Definition of Done bifat · CI verde (fără aprobare; review opțional) · merge până duminică la 22:00

## Niciodată

- Commit sau push direct pe `main`.
- `git push --force` (oricum e blocat pe `main`).
- Merge de mână la `.tscn` sau `.tres`.
- `git add -f` pe ceva ignorat (`.godot/`, `addons/gut/`, `build/`).
- Parole, chei, date personale sau date de la testeri în repo.
- `git reset --hard` sau `git clean -f` fără să fi citit `git status` înainte.
