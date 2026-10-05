# 1. Instalare și configurare

> Timp: 30-45 minute, o singură dată. La final poți clona repo-ul și poți face push cu contul tău.

Lista de bifat la sfârșitul capitolului:

- [ ] Git instalat (`git --version` merge)
- [ ] Cont GitHub cu autentificare în doi pași (2FA)
- [ ] Adresa noreply găsită și setată în `user.email`
- [ ] `user.name`, `pull.rebase`, `fetch.prune` setate (și `core.autocrlf` pe Windows)
- [ ] Autentificare făcută (`gh auth status` arată contul tău)
- [ ] Invitația de colaborator la repo acceptată
- [ ] Repo-ul clonat

## 1.1 Instalează Git

### Windows

1. Descarcă instalatorul de pe [git-scm.com/install/windows](https://git-scm.com/install/windows) (sau, în PowerShell: `winget install --id Git.Git -e --source winget`).
2. Pornește instalatorul. Poți lăsa aproape tot pe implicit, dar verifică aceste ecrane:

| Ecranul din instalator | Ce alegi |
|---|---|
| Choosing the default editor used by Git | **Use Visual Studio Code as Git's default editor** (dacă ai VS Code) sau Notepad. Nu Vim. |
| Adjusting the name of the initial branch in new repositories | **Override the default branch name for new repositories** și scrii `main` |
| Adjusting your PATH environment | **Git from the command line and also from 3rd-party software** (recomandat) |
| Configuring the line ending conversions | **Checkout as-is, commit Unix-style line endings** |
| Choose the default behavior of `git pull` | **Merge** (implicit; în versiunile mai vechi se numește **Fast-forward or merge**). Nu alege **Rebase** sau **Fast-forward only**. |
| Choose a credential helper | **Git Credential Manager** (implicit) |

3. După instalare ai programul **Git Bash**. Comenzile din ghid merg în Git Bash și, aproape toate, și în PowerShell.

### macOS

Ai două variante:

- Cu [Homebrew](https://brew.sh/) (recomandat, primești o versiune nouă):

  ```bash
  brew install git gh
  ```

- Fără Homebrew: în Terminal scrii `git --version`. Dacă Git lipsește, macOS îți propune să instaleze „Command Line Tools”. Accepți.

### Linux (Ubuntu, Debian, Mint)

```bash
sudo apt update
sudo apt install git
```

Pentru GitHub CLI (`gh`) urmezi pașii oficiali: [install_linux.md](https://github.com/cli/cli/blob/trunk/docs/install_linux.md). Pe Fedora: `sudo dnf install git gh`.

### Verifică

```bash
git --version
```

Trebuie să vezi ceva de forma `git version 2.56.0` (numărul exact nu contează). Orice versiune de la 2.23 în sus are comenzile `git switch` și `git restore` pe care le folosim în ghid.

## 1.2 Cont GitHub

1. Dacă nu ai cont, îți faci unul pe [github.com/signup](https://github.com/signup).
2. Alege un **username** pe care nu te deranjează să-l vezi în proiect. Apare în `CODEOWNERS`, în review-uri și în istoric.
3. Activează **autentificarea în doi pași (2FA)**: Settings → Password and authentication → Two-factor authentication. Folosește o aplicație de autentificare pe telefon și salvează codurile de recuperare într-un loc sigur. GitHub o cere oricum celor care contribuie la cod.
4. Opțional: ca student poți cere gratuit [GitHub Student Developer Pack](https://education.github.com/pack). Nu e necesar pentru proiect.

## 1.3 Adresa ta noreply (important)

Repo-ul nostru e **public**. Orice commit conține adresa de e-mail a autorului și oricine o poate citi. De aceea folosim adresa **noreply** pe care ți-o dă GitHub. Commit-urile făcute cu ea apar tot pe contul tău și se numără în statistici.

Cum o găsești:

1. Pe GitHub: poza ta (dreapta sus) → **Settings** → **Emails** (sau direct [github.com/settings/emails](https://github.com/settings/emails)).
2. Bifează **Keep my email addresses private**.
3. Sub căsuță apare adresa ta noreply, de forma:

   ```text
   12345678+utilizator@users.noreply.github.com
   ```

   Numărul din față e ID-ul contului tău. Copiaz-o exact, cu tot cu număr.
4. Bifează și **Block command line pushes that expose my email**. Așa, dacă greșești configurarea, GitHub refuză push-ul în loc să-ți publice adresa.

## 1.4 Configurează Git

Rulezi o singură dată, în terminal. Înlocuiești textele dintre ghilimele cu ale tale.

```bash
git config --global user.name "Prenumele tău"
git config --global user.email "12345678+utilizator@users.noreply.github.com"
git config --global pull.rebase false
git config --global fetch.prune true
```

Ce înseamnă:

| Setare | De ce |
|---|---|
| `user.name` | Numele care apare la commit-uri. E public, deci ajunge prenumele. |
| `user.email` | Adresa noreply de la pasul 1.3. Leagă commit-ul de contul tău. |
| `pull.rebase false` | `git pull` face merge, nu rebase. Așa lucrăm în echipă. Fără setarea asta, Git poate refuza un pull cu mesajul „Need to specify how to reconcile divergent branches”. |
| `fetch.prune true` | Când un branch e șters pe GitHub, dispare și din lista ta. |

**Doar pe Windows**, în plus:

```bash
git config --global core.autocrlf input
```

Windows folosește alte capete de rând (CRLF) decât macOS și Linux (LF). Fără setarea asta, Git poate vedea fiecare fișier ca „modificat” deși nu ai schimbat nimic. Repo-ul are și un fișier `.gitattributes` care forțează LF, iar setarea de mai sus e a doua plasă de siguranță. Documentația Godot recomandă același lucru.

**Editorul pentru mesaje** (opțional, dar te scutește de Vim). Alegi **una** dintre comenzile de mai jos, nu pe amândouă.

Dacă ai VS Code:

```bash
git config --global core.editor "code --wait"
```

Fără VS Code, pe macOS și Linux:

```bash
git config --global core.editor "nano"
```

Pe macOS, comanda `code` apare după ce în VS Code deschizi paleta (Cmd+Shift+P) și alegi **Shell Command: Install 'code' command in PATH**.

Verifici tot ce ai setat:

```bash
git config --global --list
```

## 1.5 Autentificarea

Parola contului GitHub **nu** mai merge la `git push`. Ai nevoie de una dintre variantele de mai jos. Recomandăm varianta A pe toate sistemele.

### Varianta A: GitHub CLI (`gh`)

Instalare: pe Windows `winget install --id GitHub.cli`, pe macOS `brew install gh`, pe Linux pașii din 1.1. Pagina oficială: [cli.github.com](https://cli.github.com/).

Apoi:

```bash
gh auth login
```

Răspunzi la întrebări așa:

| Întrebarea | Răspunsul |
|---|---|
| Where do you use GitHub? (sau: What account do you want to log into?) | **GitHub.com** |
| What is your preferred protocol for Git operations on this host? | **HTTPS** |
| Authenticate Git with your GitHub credentials? | **Yes** |
| How would you like to authenticate GitHub CLI? | **Login with a web browser** |

Terminalul scrie `First copy your one-time code:` și un cod de forma `ABCD-1234`. Apeși Enter, se deschide browserul, scrii codul, apeși **Continue**, apoi **Authorize github**.

Verifici:

```bash
gh auth status
```

Trebuie să vezi `Logged in to github.com account <username-ul tău>` și `Git operations protocol: https`.

### Varianta B: Git Credential Manager

- **Windows**: e deja instalat cu Git (ecranul „Choose a credential helper”). La primul `git push` se deschide fereastra **Connect to GitHub**. Apeși **Sign in with your browser**, te loghezi și gata.
- **macOS**: `brew install --cask git-credential-manager`, apoi la primul push se deschide browserul.
- **Linux**: cere configurare în plus. Folosește varianta A.

## 1.6 Acceptă invitația la repo

Kevin te adaugă ca colaborator (collaborator) la repo-ul proiectului, https://github.com/kevingameit-tech/kotoba-no-takara. O găsești în e-mail și în notificările de pe github.com. **Acceptă invitația**. Fără ea, la push primești eroarea `403` sau `Permission denied`.

## 1.7 Clonează repo-ul

1. Deschide pagina repo-ului pe GitHub (linkul e în README-ul principal și în grupul echipei).
2. Apasă butonul verde **Code** → tab-ul **Local** → **HTTPS** → butonul de copiere (cele două pătrățele).
3. În terminal, mergi în folderul unde ții proiectele și scrie:

```bash
git clone <adresa-copiata>
cd kotoba-no-takara
```

`<adresa-copiata>` e ce ai copiat la pasul 2. Arată ca `https://github.com/kevingameit-tech/kotoba-no-takara.git`.

4. Instalează GUT (addon-ul de teste). Nu e în repo, îl aduce un script:

```bash
bash tools/install_gut.sh
```

Pe Windows, în PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File tools/install_gut.ps1
```

5. Deschide proiectul în **Godot 4.7.2** (versiunea standard, nu .NET, de pe [godotengine.org/download/archive/4.7.2-stable](https://godotengine.org/download/archive/4.7.2-stable/)): Project Manager → **Import** → alegi fișierul `project.godot` din folderul clonat. Prima deschidere durează puțin. Jos apare panoul **GUT**. O singură dată, în setările panoului, adaugi `res://tests/unit` la **Test Directories** și bifezi **Include Subdirs**. Apoi apeși **Run All**: toate testele trebuie să fie verzi.

   Dacă ai deschis proiectul **înainte** de pasul 4, Godot scrie în panoul **Output** că nu găsește addon-ul (`Addon 'res://addons/gut/plugin.cfg' failed to load`) și îl scoate din lista de plugin-uri active. Nu e grav: închizi Godot, rulezi scriptul, apoi `git status`. Dacă `project.godot` apare modificat, îl aduci înapoi cu `git restore project.godot`. Apoi redeschizi proiectul. Dacă panoul GUT tot lipsește: **Project → Project Settings → Plugins** și bifezi GUT.

Important: toți folosim **exact** Godot 4.7.2. O altă versiune rescrie fișierele `.tscn` și `project.godot` și produce conflicte inutile.

6. Verifici că totul e curat:

```bash
git status
```

Răspunsul corect: `On branch main`, `Your branch is up to date with 'origin/main'`, `nothing to commit, working tree clean`. Dacă apar fișiere modificate doar pentru că ai deschis proiectul, citește [capitolul 8](08-git-in-godot.md).

## 1.8 Opțional: GitHub Desktop

[GitHub Desktop](https://github.com/apps/desktop) (Windows și macOS) e o aplicație cu butoane pentru commit, push și pull. E bună ca să vezi vizual ce ai schimbat. Ghidul folosește terminalul, pentru că:

- erorile se înțeleg și se caută mai ușor,
- la laborator lucrăm toți la fel,
- multe comenzi din capitolul 9 nu au buton în Desktop.

Dacă totuși îl folosești: regulile rămân aceleași (branch nou pentru fiecare sarcină, nimic direct pe `main`). Desktop ia numele și e-mailul din configurarea Git de la pasul 1.4. Verifică în setările aplicației, la **Git**, că apare adresa noreply (Windows: **File → Options → Git**; macOS: **GitHub Desktop → Settings → Git**).

## 1.9 Editor recomandat

[VS Code](https://code.visualstudio.com/) pentru `.md`, `.json` și `.gd` în afara Godot. Are un ecran bun pentru conflicte (capitolul 5) și arată ce s-a schimbat în fiecare fișier.

---

Înapoi: [0. Introducere](00-introducere.md) · Următorul: [2. Conceptele de bază](02-concepte.md)
