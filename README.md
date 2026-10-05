# Kotoba no Takara

言葉の宝 · „comoara cuvintelor” · "the treasure of words"

**RO** Un mic JRPG care se joacă în browser, pe calculator și pe telefon, și te învață japoneză de la zero.\
Kenji-sensei te ghidează prin Japonia, iar yokai păzesc trei comori: îi învingi răspunzând corect.

**EN** A small JRPG you play in the browser, on desktop or phone, that teaches you Japanese from zero.\
Kenji-sensei guides you through Japan, where yokai guard three treasures: you beat them by answering correctly.

## Cum joci / How to play

**Joacă în browser: link-ul public apare de la v0.1.**\
*Play in your browser: the public link arrives with v0.1.*

| Acțiune / Action | Tastatură / Keyboard | Telefon / Phone |
|---|---|---|
| Mergi / Move | săgeți sau WASD / arrows or WASD | joystick |
| Vorbești, alegi / Talk, choose | Z, Enter, Space | A |
| Înapoi / Back | X, Esc | B |
| Meniu / Menu | Tab, M | ☰ |

Pe telefon, ține ecranul orizontal. / On a phone, hold the screen in landscape.

Jocul nu stochează date personale. Detalii: [PRIVACY.md](PRIVACY.md).\
*The game does not store personal data. Details: [PRIVACY.md](PRIVACY.md).*

---

## Pentru echipă și profesori

Proiect de echipă pentru un curs universitar (4 studenți, 2026-27). Motor: Godot 4.7.2.

> Numele jocului, comorile, rezoluția și fonturile sunt **propuneri**. Le votăm la laboratorul din 12 oct.

### Echipa și rolurile

| Membru | Rol | Ce deține |
|---|---|---|
| Kevin | Lider și coordonare, review, tot conținutul japonez, QuizEngine, date și telemetrie (catalog, analiză) | `quiz/`, `data/`, `tools/`, `autoload/question_bank.gd`, `docs/contracts.md` |
| David | Lumea jocului: hărți, Player, NPC, dialog, SceneRouter; mentor Godot | `world/`, `assets/`, `CREDITS.md`, `autoload/scene_router.gd`, Input Map |
| Ioana | Lupta (BattleModel, BattleScene), testele GUT, tot CI-ul | `battle/`, `.github/workflows/`, `CONTRIBUTING.md`, Definition of Done |
| Mariana | UI, Theme, fonturi, limbă RO/EN, export web, TouchControls, salvare, clientul de telemetrie, accesibilitate | `ui/`, `i18n/`, `fonts/`, `autoload/settings.gd`, `autoload/save_manager.gd`, `autoload/telemetry.gd`, `export_presets.cfg` |

Kevin face review și nu scrie codul colegilor. Utilizatorii GitHub și temele de cercetare: [docs/TEAM.md](docs/TEAM.md).

### Cum începi (o singură dată)

1. **Instalează Git** de pe [git-scm.com](https://git-scm.com/downloads). Pe Windows rulează și:
   ```bash
   git config --global core.autocrlf input
   ```
2. **Fă-ți cont pe GitHub** ([github.com/signup](https://github.com/signup)). În Settings > Emails bifează „Keep my email addresses private” și copiază adresa de forma `ID+utilizator@users.noreply.github.com`. Apoi:
   ```bash
   git config --global user.name "Prenumele tău"
   git config --global user.email "ID+utilizator@users.noreply.github.com"
   ```
   Repo-ul e public: cu adresa noreply, adresa ta reală nu apare în istoric, iar commit-urile tot se leagă de contul tău.
3. **Instalează Godot 4.7.2, varianta standard** (nu .NET), de pe [godotengine.org](https://godotengine.org/download/archive/4.7.2-stable/). Toți folosim exact aceeași versiune.
4. **Acceptă invitația și clonează repo-ul.** Kevin te adaugă ca colaborator (collaborator) la repo-ul de mai jos; invitația vine pe e-mail și în notificările GitHub:
   ```bash
   git clone https://github.com/kevingameit-tech/kotoba-no-takara.git
   cd kotoba-no-takara
   ```
5. **Instalează GUT 9.7.1** (framework-ul de teste). Scriptul îl pune în `addons/gut/`, care nu intră în Git:
   ```bash
   bash tools/install_gut.sh
   ```
   Pe Windows (PowerShell): `powershell -ExecutionPolicy Bypass -File tools/install_gut.ps1`
6. **Deschide proiectul:** în Godot apasă Import și alege `project.godot`. Prima deschidere durează puțin. Jos apare panoul GUT. O singură dată, la setările panoului, adaugi `res://tests/unit` la Test Directories și bifezi Include Subdirs. Apoi apeși Run All: toate testele trebuie să fie verzi. Dacă panoul lipsește: Project > Project Settings > Plugins și bifează GUT.

### Munca de zi cu zi (5 pași)

1. Alege un issue de pe board (GitHub Projects) și asignează-l ție.
2. Pornește din `main` actualizat și fă un branch:
   ```bash
   git switch main
   git pull
   git switch -c feat/battle-damage
   ```
3. Lucrează în pași mici. Un commit face un singur lucru:
   ```bash
   git commit -m "feat(battle): add damage formula"
   ```
4. Rulează testele (panoul GUT) și `python3 tools/validate_data.py` dacă ai atins `data/`. Apoi `git push -u origin feat/battle-damage` și deschide un Pull Request: completezi șablonul și scrii `Closes #N`.
5. Un coleg rulează codul și aprobă, CI-ul e verde, apoi faci merge (merge commit). PR-urile săptămânii intră până duminică la 22:00.

Regulile complete sunt în [CONTRIBUTING.md](CONTRIBUTING.md). Dacă Git e nou pentru tine, începe cu ghidul pas cu pas: [docs/ghid-git/README.md](docs/ghid-git/README.md).

### Etape

| Data | Ce trebuie să fie gata |
|---|---|
| 12 oct | Propunerea și votul la laborator; fiecare face un PR de exercițiu în `docs/TEAM.md` |
| 19 oct | Contractele înghețate, CI verde, primul build pe GitHub Pages, Input Map |
| 26 oct | Walking skeleton pe iPhone și Android; salvarea și telemetria înghețate |
| 2 nov | Totul integrat (conținutul cap. 1 gata pe 30 oct), feature freeze |
| 9 nov | **v0.1 public**: capitolul 1 jucabil până la Tengu; încep playtesturile |
| 7 dec | **v0.2 public**: corecturi din playtest, capitolul 2 (Kyoto); go/no-go pentru capitolul 3 |
| 21 dec | **v1.0-rc** live, ca datele să se adune în vacanță |
| 11 ian 2027 | **v1.0** (tag), analiza datelor, slide-uri, video de rezervă |
| 18 ian 2027 | Repetiția prezentării: fiecare răspunde fără notițe despre codul lui |

Fără laborator pe 30 nov. Vacanța: 24 dec până la 10 ian, fără muncă obligatorie.

### Comenzi utile

| Ce faci | Comanda |
|---|---|
| Instalezi GUT | `bash tools/install_gut.sh` |
| Verifici datele JSON | `python3 tools/validate_data.py` |
| Imporți proiectul în terminal (o dată, ca în CI) | `godot --headless --import` |
| Rulezi testele în terminal (ca în CI) | `godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit` |

`godot` este programul Godot 4.7.2. Pe macOS îl găsești la `/Applications/Godot.app/Contents/MacOS/Godot`.

### Documente

| Document | Pentru ce |
|---|---|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branch-uri, commit-uri, Pull Request, review, ciclul săptămânal |
| [docs/README.md](docs/README.md) | Indexul tuturor documentelor |
| [docs/ghid-git/README.md](docs/ghid-git/README.md) | Manual de Git și GitHub, de la zero |
| [docs/contracts.md](docs/contracts.md) | Contractele dintre module (API, date, Input Map, foldere) |
| [docs/DEFINITION_OF_DONE.md](docs/DEFINITION_OF_DONE.md) | Când e o sarcină „gata” |
| [docs/TEAM.md](docs/TEAM.md) | Echipa, utilizatori GitHub, teme de cercetare |
| [docs/LICENSES.md](docs/LICENSES.md) | Licențe și reutilizare după curs |
| [PRIVACY.md](PRIVACY.md) | Ce date colectează jocul și ce nu |
| [CREDITS.md](CREDITS.md) | Autorii asset-urilor externe |
| [data/README.md](data/README.md) | Formatul datelor JSON |

### Licență

Cod: MIT ([LICENSE](LICENSE)). Lecțiile din `data/` și audio înregistrat: CC BY-NC-SA 4.0. Fonturi: OFL. Asset-uri externe: CC0. Detalii în [docs/LICENSES.md](docs/LICENSES.md).
