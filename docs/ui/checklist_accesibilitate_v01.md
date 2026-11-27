# Checklist de Accesibilitate și UI — Versiunea v0.1

> **Autor & Responsabil:** Mariana Trandafir (`ui/`, limbă RO/EN, temă & accesibilitate)  
> **Versiune proiect:** v0.1.0  
> **Referință:** [Issue #56](https://github.com/kevingameit-tech/kotoba-no-takara/issues/56), [docs/DEFINITION_OF_DONE.md](../DEFINITION_OF_DONE.md), [docs/contracts.md](../contracts.md) (Secțiunea 6 „Settings and UI text keys”).

---

## 1. Scopul Documentului

Acest document formalizează verificarea cerințelor de accesibilitate și a livrabilelor finale de UI pentru livrarea versiunii **v0.1** a jocului *Kotoba no Takara*, conform criteriilor de acceptanță din **Issue #56** și **Definition of Done** (Secțiunile 2 și 3).

---

## 2. Criterii de Acceptanță și Verificare (Issue #56)

### A. Notă de Confidențialitate RO/EN pe Ecranul de Titlu
- [x] **Subsol vizibil pe ecranul de titlu:** În partea inferioară a ecranului de titlu este afișată cheia `UI_PRIVACY_NOTICE`, informând explicit utilizatorul:
  - *RO:* „Nu stocăm date personale. Statisticile se pot opri din Setări. Ai sub 16 ani? Întreabă un părinte.”
  - *EN:* „No personal data is stored. Statistics can be disabled in Settings. Under 16? Ask a parent.”
- [x] **Buton dedicat „Confidențialitate” / „Privacy”:** Deschide un dialog modal (`AcceptDialog`) bilingv RO/EN complet, conform contractului stabilit în `PRIVACY.md`.
- [x] **Opțiune directă de dezactivare:** Dialogul și nota indică clar secțiunea `Setări` → `Statistici de joc` pentru oprire instantanee.

### B. Versiunea pe Ecranul de Titlu din `application/config/version`
- [x] **Valoare dinamică:** Eticheta `VersionLabel` de pe ecranul de titlu preia dinamic versiunea prin `ProjectSettings.get_setting("application/config/version", "0.1.0")`.
- [x] **Format standard:** Este afișată sub forma `v0.1.0`, sincronizată cu tag-ul Git `v0.1`.
- [x] **Configurare `project.godot`:** Parametrul `application/config/version="0.1.0"` este salvat în configurarea Godot.

### C. Lista de Accesibilitate Bifată
- [x] **Text mărit (Large text support):**
  - Sistemul `Settings` suportă parametrul `text_size` (`0` = Normal, `1` = Mare) și emite semnalul `text_size_changed`.
  - Meniurile (`TitleScreen`, `SettingsMenu`, `PauseMenu`) își ajustează fonturile dinamic:
    - Normal: Titlu 32-36px, Butoane 16px, Text secundar 12-14px.
    - Mare: Titlu 40-44px, Butoane 20px, Text secundar 15-18px.
  - Textul nu iese din ecran și rămâne perfect lizibil la rezoluția de bază 640x360 expandată.
- [x] **Corect / Greșit indicat nu doar prin culoare (Non-color-only feedback):**
  - În `QuizEngine`, `QuizDemo` și `BattleScene`, răspunsurile sunt marcate prin glife și simboluri geometrice distincte:
    - **Corect:** Simbolul cerc `○` / text explicit `Corect:` / verde.
    - **Greșit:** Simbolul cruce `×` / text explicit `Ai ales: ... | Răspuns corect: ...` / roșu.
  - Persoanele cu daltonism (protanopie, deuteranopie, acromatopsie) pot distinge instant rezultatul fără a depinde de codul de culori.
- [x] **Fără timer punitiv (No restrictive timer):**
  - Nu există cronometru restrictiv care să forțeze eșecul jucătorului dacă acesta are nevoie de timp suplimentar pentru a citi, procesa informația sau alege răspunsul.
  - Ritmul de învățare este relaxat și autodirijat.
- [x] **Ținte tactile $\ge 48$ CSS px (Touch targets $\ge 48\text{px}$):**
  - Toate butoanele interactive din joc respectă standardul internațional WCAG 2.1 / W3C pentru ținte tactile de cel puțin 48x48 CSS px:
    - Butoane TitleScreen (`btn_new_game`, `btn_continue`, `btn_settings`, `btn_privacy`): lățime 220px, înălțime $\ge 48\text{px}$.
    - Butoane PauseMenu (`btn_resume`, `btn_settings`, `btn_quit`): lățime 180px, înălțime $\ge 48\text{px}$.
    - Butoane SettingsMenu (selectoare limbă, dimensiune text, toggle telemetrie, buton înapoi): înălțime $\ge 48\text{px}$.
    - Butoane TouchControls (A, B, Menu): diametru/latură $56\text{ px}$.
    - Butoane opțiuni Quiz / Luptă: lățime $\ge 110\text{px}$, înălțime $\ge 48\text{px}$.

### D. Internaționalizare & Diacritice Românești
- [x] **Chei de traducere complete:** Toate textele vizibile provin exclusiv din `i18n/ui.csv` folosind prefixele permise (`MENU_`, `UI_`, `WORLD_`, `BATTLE_`).
- [x] **Diacritice corecte:** Toate textele în limba română folosesc caracterele corecte cu virgulă dedesubt (ș = U+0219, ț = U+021B, ă = U+0103, â = U+00E2, î = U+00EE), fără sedile greșite (U+015F / U+0163).
- [x] **Comutare instantă RO ↔ EN:** La schimbarea limbii din Setări, toate meniurile și ecranele active se actualizează imediat fără repornirea jocului.

---

## 3. Teste Automate de Validare (GUT)

Următoarele suite de teste din `tests/unit/` validează automat cerințele de accesibilitate și UI:
1. `tests/unit/test_title_screen.gd`: Validează componentele ecranului de titlu, versiunea dinamică `v0.1.0`, conținutul bilingv al notei de confidențialitate, comutarea limbii și scalarea fonturilor.
2. `tests/unit/test_accessibility.gd`: Validează constrângerile de minimum 48px pentru butoane, feedback-ul simbolic `○`/`×`, absența timerelor restrictive și conformitatea setării de versiune.
3. `tests/unit/test_pause_menu.gd`: Validează țintele tactile $\ge 48\text{px}$ și fluxul de navigare.
4. `tests/unit/test_settings_menu.gd`: Validează comutarea mărimii textului și opt-out-ul de telemetrie.
5. `tests/unit/test_ui_csv.gd`: Validează integritatea fișierului de traduceri, prefixele contractuale și lipsa sedilelor.
