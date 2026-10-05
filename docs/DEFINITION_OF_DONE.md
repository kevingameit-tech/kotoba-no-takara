# Definition of Done

> **v0**, scris de Kevin pe 5 oct 2026. Proprietar: **Ioana**. Se îngheață pe 19 oct.

O sarcină e **gata** doar când toate punctele care i se aplică sunt bifate. Aceeași listă apare în șablonul de Pull Request ([.github/pull_request_template.md](../.github/pull_request_template.md)), deci o bifezi acolo.

## 1. Pentru orice Pull Request

- [ ] **Issue legat:** descrierea conține `Closes #N`.
- [ ] **1 aprobare** de la cineva care **a rulat** codul, nu doar a citit diff-ul.
- [ ] **CI verde:** joburile `validate-data` și `gut-tests` au trecut.
- [ ] **Teste GUT** pentru logica nouă sau schimbată, în `tests/unit/`.
- [ ] **Fără erori în build-ul web**, verificat pe desktop și pe cel puțin un telefon (pentru orice schimbare care se vede sau se aude).
- [ ] **Fără text UI scris direct în cod:** doar chei (`MENU_`, `BATTLE_`, `WORLD_`, `UI_`) în `i18n/ui.csv`, cu RO și EN, sau câmpuri `{ro, en}` din `data/`.
- [ ] **Asset-urile noi sunt trecute în credite** ([CREDITS.md](../CREDITS.md)); fiecare font are `OFL.txt`.
- [ ] **Autorul explică fiecare rând**, inclusiv codul scris cu ajutorul AI.
- [ ] Respectă [contracts.md](contracts.md). O schimbare de contract după înghețare are 2 aprobări.
- [ ] Nimic interzis în repo: build-uri, log-uri, date de testeri, chei, date personale.
- [ ] Commit-urile folosesc adresa noreply de la GitHub; fișierele `.uid` noi sunt incluse.

## 2. În plus, după tipul schimbării

### Ecrane și UI

- [ ] Textul se citește și la mărimea mare din Setări.
- [ ] Corect și greșit nu se arată doar prin culoare: apare și un text sau un simbol, plus răspunsul corect.
- [ ] Fără cronometru pentru răspuns și fără efecte care clipesc repede.
- [ ] Țintele de atingere au cel puțin 48 CSS px.
- [ ] ă â î ș ț Ă Â Î Ș Ț și kana se văd corect.
- [ ] Schimbarea RO ↔ EN actualizează tot textul, fără repornire.

### Date (`data/`)

- [ ] `python3 tools/validate_data.py` trece fără erori.
- [ ] Id-urile sunt string-uri; un id folosit deja nu se schimbă fără anunț în echipă.
- [ ] Textele RO și EN sunt verificate; ș și ț au virgulă, nu sedilă.

### Scene și setări de proiect

- [ ] Ai schimbat doar scenele tale (vezi `.github/CODEOWNERS`); niciun `.tscn` îmbinat de mână.
- [ ] `project.godot` apare în diff doar dacă PR-ul e dedicat acestei schimbări.

### Telemetrie

- [ ] Evenimentul există în catalogul din [contracts.md](contracts.md#13-telemetry-event-catalog-placeholder).
- [ ] Trimite doar id-uri, cifre și valori fixe; fără text liber.
- [ ] Când statisticile sunt oprite în Setări, nu se trimite nimic.

## 3. Pentru o versiune publică (v0.1, v0.2, v1.0)

- [ ] Jucabil cap-coadă pe desktop, iPhone (Safari) și Android (Chrome).
- [ ] Nota de confidențialitate RO/EN apare pe ecranul de titlu și pe pagina publică.
- [ ] Versiunea de pe ecranul de titlu vine din `application/config/version` și se potrivește cu tag-ul Git (`0.1.0` pentru tag-ul `v0.1`).
- [ ] Test de 30 de minute pe iPhone, cu sunet.
- [ ] Lista de accesibilitate de mai sus e bifată pentru toate ecranele.
- [ ] Pagina publică și creditele din joc nu numesc universitatea sau cursul.
- [ ] Tag-ul `vX.Y` și o notă scurtă cu ce s-a schimbat.
