# 3. Primul flux complet, pas cu pas

> Timp: 30 minute de citit, apoi îl repeți la fiecare sarcină. Ține fișa de comenzi deschisă.

Exemplul din tot capitolul: Ioana are issue-ul **#12 „Bara de HP în luptă”**. Tu faci exact aceiași pași, doar cu numărul tău de issue și numele tău de branch.

Înainte să începi: issue-ul e asignat ție și l-ai mutat pe board în **In progress** (capitolul 6).

**Unde scrii comenzile**: în terminal, în folderul proiectului (cel făcut de `git clone`, capitolul 1.7).

- macOS și Linux: deschizi Terminal și scrii `cd` urmat de calea folderului, de exemplu `cd ~/proiecte/kotoba-no-takara`.
- Windows: în Explorer, click dreapta pe folderul `kotoba-no-takara` → **Open Git Bash here** (pe Windows 11, întâi **Show more options**).

Verifici că ești unde trebuie cu `git status`. Dacă răspunsul începe cu `On branch`, e bine. Dacă vezi `fatal: not a git repository`, nu ești în folderul proiectului.

## Pasul 1. Adu `main` la zi

```bash
git switch main
git pull
```

Pornești mereu din cel mai nou `main`. Altfel lucrezi pe o versiune veche și apar conflicte mai târziu.

Dacă `git switch main` refuză cu mesajul `Your local changes ... would be overwritten`, ai schimbări nesalvate în commit. Vezi [capitolul 9](09-greseli-frecvente.md), cazul 2.

## Pasul 2. Fă un branch nou

```bash
git switch -c feat/battle-hp-bar
```

`-c` înseamnă „create”: creează branch-ul și te mută pe el.

**Cum alegi numele**: `<tip>/<zonă>-<subiect>`, totul cu litere mici, cuvinte în engleză legate cu cratimă.

| Tip | Când | Exemplu |
|---|---|---|
| `feat` | funcționalitate nouă | `feat/battle-hp-bar`, `feat/world-npc-dialog` |
| `fix` | reparație | `fix/ui-romanian-letters` |
| `test` | doar teste | `test/quiz-engine-seed` |
| `docs` | documentație | `docs/team-mariana` |

Zonele (aceleași ca în [CONTRIBUTING.md](../../CONTRIBUTING.md)): `world`, `battle`, `ui`, `i18n`, `quiz`, `data`, `save`, `telemetry`, `ci`, `tools`, `docs`, `team`.

Verifici unde ești:

```bash
git branch --show-current
```

## Pasul 3. Lucrează

Deschizi Godot, faci scena, scriptul și testul GUT. Salvezi (Ctrl+S / Cmd+S). Rulezi jocul (butonul **Run Project** din dreapta sus) și testele (panoul **GUT** de jos → **Run All**). Dacă ai atins `data/`, rulezi și `python3 tools/validate_data.py` (capitolul 7).

Sfat: un branch trăiește **1-3 zile**. Dacă sarcina e mai mare, împarte issue-ul în două.

## Pasul 4. Vezi ce ai schimbat

```bash
git status
```

Exemplu de răspuns:

```text
On branch feat/battle-hp-bar
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   battle/battle.tscn

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	battle/hp_bar.gd
	battle/hp_bar.gd.uid
	battle/hp_bar.tscn
	tests/unit/test_hp_bar.gd
	tests/unit/test_hp_bar.gd.uid

no changes added to commit (use "git add" and/or "git commit -a")
```

Cum îl citești:

- **modified**: fișiere care existau și le-ai schimbat.
- **Untracked files**: fișiere noi, pe care Git nu le urmărește încă.

Vezi exact rândurile schimbate:

```bash
git diff                # ce ai schimbat și nu e încă în staging
git diff --stat         # doar lista de fișiere și câte rânduri
```

Ieși din `git diff` cu tasta `q`.

**Uită-te atent la listă.** Godot modifică uneori fișiere pe care nu le-ai atins (de exemplu o scenă pe care doar ai deschis-o). Acelea nu intră în commit. Vezi [capitolul 8](08-git-in-godot.md), secțiunea 8.3.

## Pasul 5. Alege ce intră în commit (`git add`)

Adaugi fișierele pe nume:

```bash
git add battle/hp_bar.gd battle/hp_bar.gd.uid battle/hp_bar.tscn battle/battle.tscn
git add tests/unit/test_hp_bar.gd tests/unit/test_hp_bar.gd.uid
```

Sau un folder întreg, dacă tot ce e în el e al tău:

```bash
git add battle/
```

`git add .` (tot) e permis doar după ce ai citit `git status` și știi că fiecare fișier din listă trebuie să intre.

Verifici:

```bash
git status
```

Acum fișierele apar sub **Changes to be committed**. Dacă ai adăugat ceva din greșeală:

```bash
git restore --staged battle/battle.tscn
```

Fișierul iese din staging, dar schimbările tale rămân pe disc.

## Pasul 6. Commit

```bash
git commit -m "feat(battle): show player HP bar"
```

### Cum scrii mesajul: Conventional Commits

Forma: `<tip>(<zonă>): <ce face, în engleză>`

| Tip | Folosești când | Exemplu |
|---|---|---|
| `feat` | adaugi ceva nou | `feat(battle): show player HP bar` |
| `fix` | repari un bug | `fix(ui): show ș and ț with Pixelify Sans` |
| `test` | adaugi sau repari teste | `test(quiz): cover empty pool` |
| `docs` | documentație | `docs(team): add GitHub username for Mariana` |
| `refactor` | rescrii fără să schimbi comportamentul | `refactor(world): split grid movement into GridUtils` |
| `chore` | întreținere: config, scripturi | `chore: ignore build folder` |
| `ci` | GitHub Actions | `ci: cache Godot download` |

Reguli:

- În **engleză**, ca restul codului.
- Verb la imperativ, literă mică, fără punct la final: `add`, `fix`, `show`, nu `Added` sau `fixes`.
- Maximum aproximativ 70 de caractere.
- **Un commit = o schimbare logică.** „HP model” și „HP bar UI” sunt două commit-uri, nu unul.

Dacă vrei să explici mai mult, pui un al doilea `-m` (devine corpul mesajului):

```bash
git commit -m "fix(battle): clamp HP at zero" -m "Damage larger than current HP made the bar negative."
```

**Ați lucrat în pereche?** Cine a scris codul face commit-ul și îl trece pe coleg la final, cu adresa lui noreply (i-o ceri lui):

```bash
git commit -m "feat(battle): add flee option" -m "Co-authored-by: Prenume <ID+utilizator@users.noreply.github.com>"
```

## Pasul 7. Repetă

Lucrezi mai departe și repeți pașii 3-6. E normal să ai 3-8 commit-uri mici într-un PR. Ținta: un PR sub 300 de rânduri schimbate (fără fișierele generate de Godot).

## Pasul 8. Trimite branch-ul pe GitHub (`git push`)

Prima dată:

```bash
git push -u origin feat/battle-hp-bar
```

`-u` leagă branch-ul tău local de cel de pe GitHub. De acum înainte, pe acest branch, ajunge:

```bash
git push
```

La primul push, Git poate cere autentificarea (capitolul 1.5; parola contului nu merge). Dacă push-ul e refuzat, caută mesajul în capitolul 9 (cazurile 1, 5, 10 și 11).

Răspunsul conține un link util:

```text
remote: Create a pull request for 'feat/battle-hp-bar' on GitHub by visiting:
remote:      https://github.com/kevingameit-tech/kotoba-no-takara/pull/new/feat/battle-hp-bar
```

## Pasul 9. Deschide pull request-ul

1. Deschide linkul de mai sus, sau intră pe pagina repo-ului. Apare o bandă galbenă cu butonul **Compare & pull request**.
2. Verifică sus: **base: `main`** ← **compare: `feat/battle-hp-bar`**.
3. **Titlul**: la fel ca un commit, de exemplu `feat(battle): show player HP bar`.
4. **Descrierea** vine completată cu șablonul nostru (`.github/pull_request_template.md`). Completezi fiecare parte:

| Partea din șablon | Ce scrii | Exemplu |
|---|---|---|
| **Ce face** | completezi numărul după `Closes #` și, dacă vrei, o propoziție despre ce face PR-ul | `Closes #12` |
| **De ce (2 rânduri)** | ce problemă rezolvă și de ce ai ales soluția | „Jucătorul nu știa câtă viață mai are. Bara ascultă semnalul hp_changed, ca să nu citească BattleModel în fiecare cadru.” |
| **Cum testezi** | pași concreți pentru reviewer | „1. Rulează battle/battle.tscn. 2. Răspunde greșit de 2 ori. 3. Bara scade cu 20%.” |
| **Captură** | o imagine sau un GIF; pentru logică fără ecran, rezultatul din panoul GUT | tragi fișierul direct în căsuța de text |
| **Definition of Done** | bifezi ce e gata: scrii `x` între paranteze (`- [x]`) sau, după ce creezi PR-ul, dai click pe căsuță | lista e explicată în capitolul 4.8 |
| **AI (opțional)** | o propoziție, dacă ai folosit AI | „am folosit AI pentru formula de daune” |

5. **Reviewers** (coloana din dreapta): GitHub pune automat proprietarul fișierelor atinse, după `.github/CODEOWNERS` (doar după ce Kevin trece acolo username-urile voastre). Dacă ai schimbat doar fișierele tale, GitHub nu are pe cine să pună, pentru că nu poți fi reviewer la propriul PR. Așa că verifici mereu: alegi cel puțin un coleg care chiar va rula codul.
6. **Assignees**: tu.
7. Apasă **Create pull request**.

Nu e gata, dar vrei părere? Apasă săgeata de lângă buton, alege **Create draft pull request** și apasă butonul. Când e gata, apeși **Ready for review**. Atenție: la un PR draft, GitHub nu cere automat review de la proprietari.

## Pasul 10. Așteaptă CI și review

Pe pagina PR-ului, jos, vezi verificările:

- cerc galben: rulează,
- bifă verde: a trecut,
- X roșu: a picat. Vezi [capitolul 7](07-ci.md).

Reviewer-ul fie aprobă, fie cere schimbări (capitolul 4). Dacă cere schimbări:

```bash
# tot pe feat/battle-hp-bar
git add battle/hp_bar.gd
git commit -m "fix(battle): update bar on hp_changed only"
git push
```

PR-ul se actualizează singur cu commit-ul nou. Nu deschizi PR nou. Răspunzi la fiecare comentariu (tab-ul **Conversation**), apeși **Resolve conversation** sub fiecare comentariu rezolvat, apoi ceri din nou review: în coloana din dreapta, la **Reviewers**, iconița cu săgeți rotunde de lângă numele reviewer-ului (**Re-request review**).

Între timp au intrat alte PR-uri în `main` și GitHub arată un conflict? Vezi [capitolul 5](05-sincronizare-si-conflicte.md).

## Pasul 11. Merge

Când ai **o aprobare** și **toate verificările verzi**, butonul de jos devine verde:

1. Apeși **Merge pull request**. La noi singura variantă activă e **Create a merge commit**.
2. Apeși **Confirm merge**.
3. Apeși **Delete branch** (branch-ul de pe GitHub nu mai e necesar).

Dacă butonul e gri, GitHub scrie dedesubt ce lipsește: aprobarea, CI verde sau rezolvarea unui conflict (capitolul 5).

Butonul îl apasă **autorul PR-ului**. Termenul: tot ce vrei să arăți la demo-ul de luni trebuie să fie îmbinat până **duminică la 22:00**.

Datorită lui `Closes #12`, issue-ul #12 se închide singur, iar cardul trece în **Done** pe board.

## Pasul 12. Fă curat local

```bash
git switch main
git pull
git branch -d feat/battle-hp-bar
```

`git branch -d` șterge branch-ul local doar dacă e deja în `main`. Dacă primești `error: the branch ... is not fully merged`, înseamnă că ai commit-uri care nu au ajuns în `main`. Nu folosi `-D` până nu înțelegi de ce.

Gata. Iei următorul issue și reiei de la pasul 1.

## Rezumat pe o singură privire

```bash
git switch main
git pull
git switch -c feat/<zona>-<subiect>
# ... lucrezi ...
git status
git add <fisiere>
git commit -m "feat(<zona>): <ce face>"
git push -u origin feat/<zona>-<subiect>
# PR pe GitHub: Closes #N, De ce, Cum testezi, captură
# review + CI verde -> Create a merge commit -> Delete branch
git switch main
git pull
git branch -d feat/<zona>-<subiect>
```

---

Înapoi: [2. Concepte](02-concepte.md) · Următorul: [4. Review](04-review.md)
