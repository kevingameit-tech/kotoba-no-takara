# 9. Greșeli frecvente și cum le repari

> Nu se citește de la cap la coadă. Îl deschizi când ceva nu merge. Fiecare caz are: ce vezi, ce faci, comenzile exacte.

**Înainte de orice reparație:**

```bash
git status
git log --oneline --graph -10
```

Prima comandă îți spune pe ce branch ești și ce fișiere sunt schimbate. A doua îți arată ultimele 10 commit-uri. Citește-le cu atenție. Jumătate din probleme se lămuresc aici.

**Regula de siguranță:** nu folosi `git push --force`, `git reset --hard` sau `git clean -f` dacă nu ești sigur ce fac. Dacă ești în dubiu, oprește-te și scrie în chat-ul echipei cu rezultatul celor două comenzi de mai sus.

## Cuprins

| # | Problema |
|---|---|
| 1 | Am făcut commit pe `main` din greșeală |
| 2 | Am lucrat pe branch-ul greșit |
| 3 | Vreau să anulez sau să corectez ultimul commit |
| 4 | Vreau să arunc schimbările locale |
| 5 | Am uitat să fac pull |
| 6 | Conflict și panică |
| 7 | „detached HEAD” |
| 8 | Am urcat o parolă sau o cheie |
| 9 | Fișier prea mare sau ceva ce nu trebuia (`.godot/`, `build/`) |
| 10 | Push refuzat din cauza adresei de e-mail |
| 11 | Eroare de autentificare la push |
| 12 | M-am blocat într-un editor ciudat (Vim) |

## 1. Am făcut commit pe `main` din greșeală

**Ce vezi**: ai lucrat direct pe `main`, ai făcut commit, iar `git push` e refuzat:

```text
remote: error: GH006: Protected branch update failed for refs/heads/main.
```

(sau `GH013: Repository rule violations found for refs/heads/main`). E normal: `main` e protejat. Munca ta nu e pierdută.

**Ce faci**: muți commit-urile pe un branch nou și aduci `main` înapoi la varianta de pe GitHub.

```bash
git switch -c feat/battle-hp-bar        # branch nou, cu toate commit-urile tale
git branch -f main origin/main          # main local redevine ca pe GitHub
git push -u origin feat/battle-hp-bar
```

`git switch -c` ia cu el și schimbările încă nesalvate în commit, deci nu pierzi nimic. `git branch -f main origin/main` mută doar eticheta `main` înapoi, la ultima variantă de pe GitHub; commit-urile tale rămân pe branch-ul nou. În locul lui `feat/battle-hp-bar` pui numele potrivit sarcinii tale.

## 2. Am lucrat pe branch-ul greșit

### a) Încă nu am făcut commit

Schimbările nesalvate „călătoresc” cu tine când schimbi branch-ul.

Dacă branch-ul corect **nu există încă**:

```bash
git switch -c feat/world-npc-dialog
```

Dacă branch-ul corect **există deja**:

```bash
git switch feat/world-npc-dialog
```

Dacă Git refuză cu `Your local changes to the following files would be overwritten by checkout`, pui schimbările deoparte, schimbi branch-ul și le aduci înapoi:

```bash
git stash push -m "npc dialog in lucru"
git switch feat/world-npc-dialog
git stash pop
```

Dacă `git stash pop` produce conflict (`CONFLICT (content)`): deschizi fișierul, rezolvi semnele ca la 5.4 (pașii 3-5), apoi `git add <fișier>`. Aici **nu** faci `git commit --no-edit`, pentru că nu e un merge: lucrezi mai departe și faci commit când e gata. Git păstrează stash-ul („The stash entry is kept in case you need it again”), îl vezi cu `git stash list`. După ce ai verificat că totul e bine, îl ștergi cu `git stash drop`.

### b) Am făcut deja commit (dar nu push)

Copiezi commit-ul pe branch-ul corect, apoi îl scoți de pe cel greșit:

```bash
git log --oneline -3                    # copiezi id-ul commit-ului, de ex. a1b2c3d
git switch feat/world-npc-dialog        # branch-ul corect
git cherry-pick a1b2c3d                 # commit-ul apare și aici
git switch feat/battle-hp-bar           # branch-ul greșit
git reset --hard HEAD~1                 # scoți ultimul commit de aici
```

`HEAD~1` înseamnă „un commit în urmă”. Atenție: `git reset --hard` șterge și schimbările nesalvate de pe acel branch. Verifică întâi cu `git status`.

Dacă ai făcut deja push pe branch-ul greșit, nu folosi `reset`. Scrie în chat și rezolvăm împreună (de obicei cu `git revert`, vezi cazul 3).

## 3. Vreau să anulez sau să corectez ultimul commit

### a) Commit-ul **nu** e pe GitHub încă

Anulezi commit-ul, dar **păstrezi schimbările** (rămân pregătite pentru un commit nou):

```bash
git reset --soft HEAD~1
git status          # fișierele apar la "Changes to be committed"
```

Ai greșit doar mesajul:

```bash
git commit --amend -m "feat(battle): show player HP bar"
```

Ai uitat un fișier în commit:

```bash
git add battle/hp_bar.gd.uid
git commit --amend --no-edit
```

### b) Commit-ul e deja pe GitHub

Nu rescrii istoria. Faci un commit nou care face exact opusul:

```bash
git revert a1b2c3d      # id-ul commit-ului de anulat
git push
```

Se deschide editorul cu mesajul `Revert "..."`. Îl salvezi așa cum e (sau folosești `git revert --no-edit a1b2c3d`).

Dacă vrei doar să repari ceva mic într-un commit urcat, e mai simplu: faci un commit nou cu reparația (`fix(...)`) și push.

## 4. Vreau să arunc schimbările locale

Un singur fișier, revine la ultima variantă din commit:

```bash
git restore battle/battle.tscn
```

Toate fișierele modificate (atenție, nu se poate anula):

```bash
git restore .
```

Ai pus un fișier în staging din greșeală și vrei doar să-l scoți de acolo (schimbările rămân pe disc):

```bash
git restore --staged battle/battle.tscn
```

Fișiere **noi** (untracked) pe care vrei să le ștergi: întâi te uiți ce s-ar șterge, apoi ștergi:

```bash
git clean -n        # doar arată lista
git clean -f        # șterge fișierele din listă
```

`git clean` nu atinge fișierele ignorate (`.godot/`, `addons/gut/`).

## 5. Am uitat să fac pull

### a) `git push` refuzat pe branch-ul tău

```text
 ! [rejected]        feat/battle-hp-bar -> feat/battle-hp-bar (fetch first)
hint: Updates were rejected because the remote contains work that you do not
hint: have locally.
```

Pe GitHub există commit-uri pe branch-ul tău pe care nu le ai local. Se întâmplă des la noi când ai apăsat **Commit suggestion** sau **Update branch** pe pagina PR-ului.

```bash
git pull --no-edit
git push
```

`--no-edit` păstrează mesajul automat al merge-ului, fără să deschidă editorul.

### b) Ai lucrat pornind de la un `main` vechi

PR-ul arată conflicte sau CI pică din cauza codului nou al colegilor. Aduci `main` în branch (rutina din capitolul 5):

```bash
git switch main
git pull
git switch feat/battle-hp-bar
git merge main --no-edit
git push
```

### c) `git pull` cere să alegi „merge” sau „rebase”

```text
fatal: Need to specify how to reconcile divergent branches.
```

Nu ai setat `pull.rebase` (capitolul 1). O dată:

```bash
git config --global pull.rebase false
git pull
```

## 6. Conflict și panică

Oprești merge-ul și revii exact la starea de dinainte:

```bash
git merge --abort
```

Apoi recitește [capitolul 5](05-sincronizare-si-conflicte.md) cu calm. Pentru `.tscn`: nu edita semnele de conflict, păstrezi o parte (`git restore --theirs <fișier>`) și refaci schimbarea în editor.

Dacă ai terminat deja merge-ul cu un rezultat greșit și **nu** ai făcut push:

```bash
git reset --hard ORIG_HEAD
```

`ORIG_HEAD` e starea de dinainte de ultimul merge. Dacă ai făcut deja push, scrie în chat.

## 7. „detached HEAD”

**Ce vezi**:

```text
You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, ...
```

Ai sărit pe un commit anume (de exemplu cu `git checkout a1b2c3d`), nu pe un branch. Poți să te uiți, dar commit-urile făcute aici nu aparțin niciunui branch.

Nu ai făcut nimic acolo? Te întorci:

```bash
git switch main
```

Ai făcut commit-uri acolo și vrei să le păstrezi? Le pui pe un branch nou **înainte** să pleci:

```bash
git switch -c fix/battle-rescue-work
```

Ai plecat deja și ai pierdut commit-urile? Git îți afișează id-ul lor când pleci, iar `git reflog` îți arată tot ce ai făcut recent. Găsești id-ul și:

```bash
git branch fix/battle-rescue-work a1b2c3d
```

## 8. Am urcat o parolă sau o cheie

Repo-ul e public. Un secret urcat pe GitHub trebuie considerat **deja furat**, chiar dacă l-ai șters după un minut.

În ordinea asta:

1. **Spune-i imediat lui Kevin.**
2. **Anulează secretul** la sursă: generezi o cheie nouă și o dezactivezi pe cea veche. Ștergerea din Git nu e de ajuns.
3. Scoate secretul din cod și pune-l într-un fișier ignorat de Git. Commit nou, push.
4. Curățarea istoricului (dacă e nevoie) o face Kevin. Nu încerca `git push --force` (oricum e blocat pe `main`).

Dacă GitHub **refuză** push-ul pentru că a recunoscut un secret (`Push cannot contain secrets`), e o veste bună: nu a ajuns online. Dacă secretul e în ultimul commit:

```bash
git reset --soft HEAD~1
```

Scoți secretul din fișier și salvezi. Apoi:

```bash
git add <fisier>
git commit -m "feat(...): ..."
git push
```

Nu apăsa linkul de „allow the secret” din mesaj.

## 9. Fișier prea mare sau ceva ce nu trebuia (`.godot/`, `build/`)

### a) Push refuzat pentru fișier mare

```text
remote: error: File assets/music/theme.wav is 120.00 MB; this exceeds GitHub's file size limit of 100.00 MB
```

Dacă fișierul a intrat în **ultimul** commit:

```bash
git rm --cached assets/music/theme.wav
git commit --amend --no-edit
git push
```

`--cached` îl scoate din Git, dar îl lasă pe disc. Apoi îl transformi în ceva mic (pentru muzică: OGG). Dacă fișierul e într-un commit mai vechi, scrie în chat: trebuie rescris istoricul branch-ului și o facem împreună.

### b) Am comis `.godot/`, `build/` sau `addons/gut/`

Le scoți din Git (rămân pe disc) și faci commit:

```bash
git rm -r --cached .godot
git commit -m "chore: stop tracking .godot"
git push
```

Verifică și că folderul e în `.gitignore`. Dacă nu e, spune-i lui Kevin.

## 10. Push refuzat din cauza adresei de e-mail

```text
remote: error: GH007: Your push would publish a private email address.
```

Commit-ul are adresa ta reală, iar GitHub te protejează (setarea din capitolul 1.3). Repari configurarea și refaci autorul ultimului commit:

```bash
git config --global user.email "12345678+utilizator@users.noreply.github.com"
git commit --amend --reset-author --no-edit
git push
```

Dacă sunt mai multe commit-uri cu adresa greșită, scrie în chat. Le refacem împreună.

Verifici cu ce adresă e făcut ultimul commit:

```bash
git log -1 --format="%an <%ae>"
```

## 11. Eroare de autentificare la push

```text
remote: Permission to kevingameit-tech/kotoba-no-takara.git denied to utilizator.
fatal: unable to access '...': The requested URL returned error: 403
```

sau `Authentication failed`.

1. Ai acceptat invitația de colaborator la repo? (capitolul 1.6)
2. Verifici cu ce cont ești logat:

   ```bash
   gh auth status
   ```

3. Dacă nu ești logat sau e alt cont:

   ```bash
   gh auth login
   ```

Parola contului GitHub nu merge la `git push`. Folosește `gh auth login` sau Git Credential Manager (capitolul 1.5).

## 12. M-am blocat într-un editor ciudat (Vim)

Ai rulat `git commit` fără `-m` sau un merge fără `--no-edit`, și terminalul arată un ecran plin de `~`.

- Ca să păstrezi mesajul și să termini commit-ul: apasă `Esc`, scrie `:wq`, apasă `Enter`. La un merge, mesajul propus („Merge branch 'main' into ...”) e bun așa cum e.
- Ca să renunți la commit: `Esc`, `:cq`, `Enter`. Git anulează commit-ul. (La un merge, conflictele rezolvate rămân; termini cu `git commit --no-edit` sau renunți cu `git merge --abort`.)

Ca să nu se mai întâmple, setează alt editor (capitolul 1.4):

```bash
git config --global core.editor "code --wait"
```

---

Înapoi: [8. Git în Godot](08-git-in-godot.md) · Următorul: [10. Exerciții](10-exercitii.md)
