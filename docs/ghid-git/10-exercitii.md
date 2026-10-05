# 10. Exerciții

> Timp total: aproximativ 1 oră și jumătate. Exercițiul 1 îl termini **până la laboratorul din 12 octombrie**. Exercițiile 2 și 3 le facem la laborator, în perechi.

Kevin deschide pentru fiecare exercițiu un issue asignat ție. În PR scrii `Closes #N` cu numărul acelui issue.

## Exercițiul 1: primul tău PR (TEAM.md)

**Scop**: treci o dată prin tot drumul (branch, commit, push, PR, review, merge) și verifici că GitHub îți leagă commit-urile de cont. Pașii sunt aceiași ca în [docs/TEAM.md](../TEAM.md).

**Timp**: 20-30 de minute.

1. Ai terminat [capitolul 1](01-instalare.md): Git configurat cu adresa noreply, repo clonat.
2. Aduci `main` la zi și faci branch-ul:

   ```bash
   git switch main
   git pull
   git switch -c docs/team-mariana
   ```

   (Cu prenumele tău, cu litere mici: `docs/team-david`, `docs/team-ioana`.)
3. Deschizi `docs/TEAM.md` în VS Code. În rândul tău, înlocuiești „de completat prin PR-ul de exercițiu” cu `@utilizatorul-tău`. Dacă vrei, scrii și două teme candidate pentru cercetare.
4. Verifici, faci commit și push:

   ```bash
   git status
   git diff
   git add docs/TEAM.md
   git commit -m "docs(team): add GitHub username for Mariana"
   git push -u origin docs/team-mariana
   ```

5. Deschizi PR-ul pe GitHub (capitolul 3, pasul 9). În șablon: `Closes #N`, la „De ce” un rând simplu („Exercițiul 1: primul PR.”), la „Cum testezi” scrii „Deschide docs/TEAM.md și verifică rândul meu.”
6. Ceri review de la un coleg (**Reviewers**, în dreapta PR-ului). Pentru exercițiul ăsta ajunge ca el să deschidă fișierul în **Files changed**, să lase un comentariu și să aprobe ([capitolul 4](04-review.md), pașii 4 și 5). Review-ul complet îl exersăm în exercițiul 3.
7. Apeși **Merge pull request** → **Create a merge commit** → **Confirm merge** → **Delete branch**.
8. Faci curat local:

   ```bash
   git switch main
   git pull
   git branch -d docs/team-mariana
   ```

### Aproape sigur vei avea un conflict

Toți patru schimbați același tabel, pe rânduri lipite. Al doilea PR îmbinat va avea probabil conflict. E normal și e un exercițiu bun.

Rezolvarea locală (capitolul 5):

```bash
git switch main
git pull
git switch docs/team-mariana
git merge main --no-edit
```

În `docs/TEAM.md` vei vedea ceva de forma:

```text
<<<<<<< HEAD
| Ioana | ... | de completat prin PR-ul de exercițiu | ... |
| Mariana | ... | @utilizator-mariana | ... |
=======
| Ioana | ... | @utilizator-ioana | ... |
| Mariana | ... | de completat prin PR-ul de exercițiu | ... |
>>>>>>> main
```

**Atenție**: aici **nu** apeși „Accept Both Changes”. Ai obține 4 rânduri în loc de 2. Păstrezi **rândul nou al colegului** (din partea `main`) și **rândul tău nou** (din partea `HEAD`):

```text
| Ioana | ... | @utilizator-ioana | ... |
| Mariana | ... | @utilizator-mariana | ... |
```

Apoi:

```bash
git diff --check
git add docs/TEAM.md
git commit --no-edit
git push
```

**Variantă din browser**: pe pagina PR-ului, butonul **Resolve conflicts** deschide un editor pe GitHub. Faci aceeași editare, apeși **Mark as resolved**, apoi **Commit merge**. După aceea, local, rulezi `git pull` pe branch-ul tău. Încearcă o dată și varianta asta, ca s-o știi.

## Exercițiul 2: un conflict construit intenționat (în perechi)

**Scop**: produci un conflict cu un coleg, într-un fișier care nu strică nimic, și îl rezolvi calm. Fișierul: [`docs/ghid-git/sandbox.txt`](sandbox.txt).

**Timp**: 30-40 de minute.

Perechile sunt cele de la laborator. **Perechea 1** lucrează pe rândurile de sub „== Perechea 1 ==”, **perechea 2** pe cele de sub „== Perechea 2 ==”. Așa, perechile nu se încurcă între ele. În fiecare pereche, unul e **A** și celălalt **B**.

### Partea 1: A și B schimbă același rând

1. Amândoi:

   ```bash
   git switch main
   git pull
   ```

2. A: `git switch -c docs/docs-sandbox-<prenume-a>`. B: `git switch -c docs/docs-sandbox-<prenume-b>`. (Forma e `<tip>/<zonă>-<subiect>`, cu zona `docs`.)
3. Amândoi schimbați **același rând**, „Cuvântul zilei”, fiecare cu alt cuvânt japonez. De exemplu A scrie `neko (pisică)`, B scrie `inu (câine)`.
4. Amândoi:

   ```bash
   git add docs/ghid-git/sandbox.txt
   git commit -m "docs: set word of the day in sandbox"
   git push -u origin docs/docs-sandbox-<prenumele-tau>
   ```

5. Amândoi deschideți PR. B face review la PR-ul lui A și îl aprobă. A îl îmbină.

### Partea 2: B rezolvă conflictul

6. GitHub arată acum la PR-ul lui B: „This branch has conflicts that must be resolved”. B rezolvă local:

   ```bash
   git switch main
   git pull
   git switch docs/docs-sandbox-<prenume-b>
   git merge main --no-edit
   git status
   ```

7. B deschide `sandbox.txt`, găsește semnele de conflict și decide împreună cu A ce rămâne. De exemplu `Cuvântul zilei: neko (pisică) și inu (câine)`. Șterge cele trei rânduri cu semne.
8. B verifică și termină:

   ```bash
   git diff --check
   git add docs/ghid-git/sandbox.txt
   git commit --no-edit
   git push
   ```

9. A face review la PR-ul lui B și îl aprobă. B îl îmbină.
10. Amândoi faceți curat:

    ```bash
    git switch main
    git pull
    git branch -d docs/docs-sandbox-<prenumele-tau>
    ```

### Partea 3: inversați rolurile, cu regula pentru `.tscn`

Repetați pașii 1-10 pe rândul „Culoarea preferată”, cu branch-uri noi (`docs/docs-color-<prenume>`) și cu rolurile inversate: acum B îmbină primul, A rezolvă. De data asta A rezolvă **ca și cum ar fi un `.tscn`**: nu editează semnele, ci păstrează varianta din `main` și își reface schimbarea de mână.

Pasul 6 rămâne la fel: A aduce `main` în branch-ul lui (`docs/docs-color-<prenume-a>`) și vede conflictul. În locul pașilor 7 și 8, A rulează:

```bash
git restore --theirs docs/ghid-git/sandbox.txt
git add docs/ghid-git/sandbox.txt
git commit --no-edit
```

Acum A deschide `sandbox.txt` și își adaugă din nou culoarea, lângă cea a colegului. Salvează, apoi:

```bash
git add docs/ghid-git/sandbox.txt
git commit -m "docs: re-add my color in sandbox after merge"
git push
```

Asta e exact procedura din capitolul 5.5 pentru scene.

## Exercițiul 3: review la PR-ul unui coleg

**Scop**: faci un review adevărat, nu doar un clic pe „Approve”.

**Timp**: 20 de minute.

Alegi un PR încă deschis al unui coleg, de exemplu PR-ul lui din partea 3 a exercițiului 2, înainte să fie îmbinat. Urmezi [capitolul 4](04-review.md):

1. Citești descrierea. Are `Closes #N`, „De ce”, „Cum testezi”?
2. Rulezi branch-ul la tine (numele branch-ului îl vezi sus în PR; aici, de exemplu, `docs/docs-color-david`):

   ```bash
   git fetch
   git switch docs/docs-color-david
   ```

   Verifici fișierul, apoi te întorci:

   ```bash
   git switch main
   ```

3. În **Files changed** lași:
   - o **Întrebare** („Întrebare: de ce ai ales culoarea asta?”),
   - o **Sugestie** cu butonul **Add a suggestion** (de exemplu o virgulă sau o literă cu diacritice).
4. **Review changes** (sau **Submit review**) → **Approve** → **Submit review**.
5. Autorul răspunde la întrebare și apasă **Commit suggestion**. Pentru că acest commit s-a făcut pe GitHub, autorul rulează apoi local `git pull` pe branch-ul lui (altfel următorul `git push` e refuzat, vezi capitolul 9, cazul 5).

## Lista finală: ești gata?

Bifează doar ce ai verificat cu ochii tăi:

- [ ] `git log -5 --format="%h %an <%ae>"`: la commit-urile tale apare adresa ta noreply.
- [ ] În lista de commit-uri de pe GitHub (**Code** → **Commits**), lângă commit-ul tău apare poza și username-ul tău, nu o iconiță gri.
- [ ] În **Insights → Contributors** apari cu cel puțin un commit. (Graficul numără doar commit-urile din `main`, fără commit-urile de merge, și se poate actualiza cu întârziere.)
- [ ] Ai deschis cel puțin un PR care a fost îmbinat.
- [ ] Ai rezolvat cel puțin un conflict (exercițiul 1 sau 2).
- [ ] Ai făcut cel puțin un review cu un comentariu și o aprobare.
- [ ] Ai șters branch-urile terminate: `git branch` arată doar `main` (și ce lucrezi acum).
- [ ] Știi unde e [fișa de comenzi](fisa-de-comenzi.md) și [capitolul 9](09-greseli-frecvente.md).

Dacă nu apari în Contributors sau commit-ul are iconiță gri, adresa din commit nu e legată de contul tău. Verifici `git config --global user.email` (capitolul 1.3) și scrii în chat-ul echipei.

---

Înapoi: [9. Greșeli frecvente](09-greseli-frecvente.md) · Cuprins: [README](README.md)
