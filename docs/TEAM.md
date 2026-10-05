# Echipa

| Membru | Rol | Utilizator GitHub | Tema de cercetare (10%) |
|---|---|---|---|
| Kevin | Lider și coordonare, review, tot conținutul japonez, QuizEngine, date, telemetrie (catalog și analiză) | de completat prin PR-ul de exercițiu | de ales până la 19 oct (propunere: retrieval practice și spaced repetition în jocurile educative) |
| David | Lumea jocului: hărți, Player, NPC, dialog, SceneRouter; asset-uri și credite; mentor Godot (1 h de Q&A pe săptămână) | de completat prin PR-ul de exercițiu | de ales până la 19 oct |
| Ioana | Lupta (BattleModel, BattleScene), testele GUT, tot CI-ul, CONTRIBUTING și Definition of Done | de completat prin PR-ul de exercițiu | de ales până la 19 oct |
| Mariana | UI, Theme, fonturi, limbă RO/EN, export web, TouchControls, salvare, clientul de telemetrie, accesibilitate | de completat prin PR-ul de exercițiu | de ales până la 19 oct |

Folderele fiecăruia: [contracts.md, secțiunea 3](contracts.md#3-folders-and-ownership). Kevin face review și nu scrie și nu repară codul colegilor.

## Exercițiul: primul tău Pull Request (până pe 12 oct)

Scopul: să treci o dată prin tot drumul (branch, commit, push, PR, review, merge) și să verifici că GitHub îți leagă commit-urile de cont.

1. Acceptă invitația de colaborator la repo și clonează repo-ul (vezi [README](../README.md#cum-începi-o-singură-dată)).
2. Fă un branch: `git switch -c docs/team-<prenume>` (de exemplu `docs/team-ioana`).
3. În tabelul de mai sus, în rândul tău, înlocuiește „de completat prin PR-ul de exercițiu” cu `@utilizatorul-tău`. Dacă vrei, scrie și două teme candidate pentru cercetare.
4. Commit și push:
   ```bash
   git add docs/TEAM.md
   git commit -m "docs(team): add GitHub username for <prenume>"
   git push -u origin docs/team-<prenume>
   ```
5. Deschide Pull Request-ul, scrie `Closes #N` (issue-ul tău de exercițiu) și cere review de la un coleg.
6. După merge, deschide Insights > Contributors. Dacă nu apari acolo, adresa de e-mail din commit nu e legată de contul tău: vezi [CONTRIBUTING.md](../CONTRIBUTING.md#1-înainte-de-primul-commit).

Toți patru schimbați același tabel, deci al doilea sau al treilea PR va avea probabil un **conflict**. E normal și e un exercițiu bun: păstrezi ambele rânduri, faci commit și ceri din nou review. Pașii sunt în [docs/ghid-git/](ghid-git/README.md).
