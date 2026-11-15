# Checklist de Testare a Sistemului de Luptă pe Mobil (iPhone și Android) — v0.1

> **Autor & Responsabil:** Ioana Radu (`battle/`, QA & CI)  
> **Versiune proiect:** v0.1.0  
> **Referință:** [Issue #55](https://github.com/kevingameit-tech/kotoba-no-takara/issues/55), [docs/DEFINITION_OF_DONE.md](../DEFINITION_OF_DONE.md), [docs/contracts.md](../contracts.md) (Secțiunile 1, 2, 8, 9, 10).

---

## 1. Scopul Documentului

Acest checklist formalizează procesul de verificare calitativă și ergonomie a scenei de luptă (`BattleScene`) pe dispozitive mobile (**iPhone** cu Safari și **Android** cu Chrome) în cadrul exportului web (HTML5 / WebGL Compatibility) înainte de lansarea versiunii **v0.1**.

Obiectivul principal este garantarea faptului că modulul de luptă:
1. Este complet jucabil și confortabil la atingere (touch) pe ecrane de telefon.
2. Respectă constrângerile stricte de accesibilitate (butoane $\ge$ 48px, contrast, afișare explicită a răspunsurilor).
3. Păstrează stabilitatea fluxului de luptă și integrarea corectă cu `QuizEngine`, întâlnirile din `encounters.json` și mecanica de Faza 2 a boss-ului Tengu.

---

## 2. Dispozitive și Configurație de Test

| Parametru | Mediu iOS | Mediu Android | Mediu Referință (Desktop) |
|---|---|---|---|
| **Dispozitiv** | iPhone 13 / iPhone SE (3rd gen) | Google Pixel 7 / Samsung Galaxy A53 | PC Windows 11 / macOS |
| **Sistem de operare** | iOS 17.x / 18.x | Android 13 / 14 | Windows 11 (64-bit) |
| **Browser** | Mobile Safari (WebKit) | Google Chrome Mobile (Blink) | Chrome / Firefox |
| **Rezoluție de bază** | 640x360 (`canvas_items`, aspect `expand`) | 640x360 (`canvas_items`, aspect `expand`) | 640x360 scalat |
| **Orientare** | Landscape (orizontal) | Landscape (orizontal) | Fereastră desktop |
| **Renderer Godot** | Compatibility (WebGL 2.0 / WebGL 1 fallback) | Compatibility (WebGL 2.0) | Compatibility |
| **Model Threading** | Single-threaded (Thread Support off) | Single-threaded (Thread Support off) | Single-threaded |

---

## 3. Checklist Detaliat de Verificare

### A. Ergonomie & Comenzi Tactile (Touch & Accessibility)
- [x] **Dimensiune minimă accesibilă (48 CSS px):** Toate butoanele de opțiuni de răspuns (romaji) au `custom_minimum_size` de cel puțin $110 \times 48\text{ px}$, conform *Definition of Done* secțiunea 2.
- [x] **Butoane de acțiune secundare:** Butonul „Următoarea întrebare →” și butonul „Fugi din luptă” au înălțimea de cel puțin $48\text{ px}$ și lățime generoasă pentru atingere facilă.
- [x] **Spațiere prevenire apăsare eronată (*fat finger*):** Spațierea între opțiunile de răspuns este de $12\text{ px}$ în `HBoxContainer`, permițând selecția precisă fără atingeri accidentale.
- [x] **Răspuns tactil imediat:** La atingerea ecranului (tap), butonul răspunde instantaneu, fără delay-ul nativ de 300ms din browserele mobile.
- [x] **Fără scroll sau zoom nedorit:** Viewport-ul rămâne fix în landscape; gesturile de pinch-to-zoom sau double-tap nu deplasează elementele interfeței.

### B. Randare Vizuală, Fonturi și Lizibilitate
- [x] **Întrebare Kana lizibilă:** Caracterul japonez hiragana/katakana este afișat mare (font size 72px) din fontul dedicat `DotGothic16`, fiind perfect lizibil chiar și pe ecrane de telefon de 4.7 inch.
- [x] **Diacritice românești corecte:** Toate mesajele de feedback și textele din explicații folosesc diacritice cu virgulă dedesubt (ă, â, î, ș, ț — conform U+0218 la U+021B), fără caractere lipsă sau tofu (`□`).
- [x] **Feedback non-cromatic:** Rezultatul răspunsului este semnalizat explicit atât prin text și simbol clar (`○  Corect: [răspuns]` sau `×  Ai ales: [alegere]  |  Răspuns corect: [așteptat]`), cât și prin culoare, respectând regulile de accesibilitate pentru persoanele cu daltonism.
- [x] **Bare de viață vizibile:** Barele de HP pentru inamic și jucător (`ProgressBar`) au o grosime confortabilă ($16\text{ px}$) și contrastează net pe fundalul `#14213d`.

### C. Fluxul de Luptă și Tranziția de Boss (Gameplay Loop)
- [x] **Inițializare inamic obișnuit (`c1_kappa_1`):** Inamicul are 50 HP, jucătorul are 100 HP, iar QuizEngine pornește cu pool-ul de întrebări `c1_rows_a_k`.
- [x] **Inițializare Boss Tengu (`c1_boss_tengu`):** Boss-ul are 120 HP, atac sporit (15) și afișează eticheta `[BOSS]` în antet.
- [x] **Mecanica răspuns corect:** Se adaugă +1 la răspunsuri corecte, inamicul primește 25 daune, apare butonul de trecere la următoarea întrebare.
- [x] **Mecanica răspuns greșit:** Se adaugă +1 la răspunsuri greșite, jucătorul primește daune conform atacului inamicului, se afișează explicația fonetică/gramaticală.
- [x] **Tranziția în Faza 2 la Tengu:** Când viața boss-ului scade la sau sub pragul de 50% ($\le 60\text{ HP}$ din 120):
  - QuizEngine comută automat pe pool-ul greu `c1_boss_tengu_phase2`.
  - Se emite semnalul `phase_changed(2)`.
  - Se afișează vizual mesajul `⚡ FAZA 2!` și eticheta `[FAZA 2]`.
  - Loviturile ulterioare nu redeclanșează evenimentul de tranziție.
- [x] **Condiții de final de luptă:**
  - **Victorie (`win`):** Când viața inamicului ajunge la 0 HP, semnalul `battle_finished` emite `{encounter_id, outcome: "win", correct, wrong}`.
  - **Înfrângere (`lose`):** Când viața jucătorului ajunge la 0 HP, semnalul emite `{outcome: "lose"}`.
  - **Fugi (`flee`):** Butonul de fugă emite `{outcome: "flee"}` fără blocaje.

### D. Performanță și Stabilitate Web
- [x] **Framerate constant:** 60 FPS stabil pe parcursul întregii lupte, fără căderi de cadre la generarea dinamică a butoanelor.
- [x] **Consolă Web curată:** Fără erori JavaScript / WebAssembly sau avertismente de memorie în Web Inspector / Chrome DevTools.
- [x] **Orientare ecran:** Dacă telefonul este rotit accidental în mod portret, overlay-ul de rotire specificat de Mariana acoperă ecranul, iar la revenirea în landscape lupta continuă de unde a rămas.

---

## 4. Matricea de Rezultate Playtest (v0.1)

| Categorie Verificare | iPhone Safari | Android Chrome | Desktop Web | Rezultat |
|---|:---:|:---:|:---:|:---:|
| Ținte touch $\ge 48\text{ px}$ | PASS | PASS | PASS | **Conform** |
| Randare Kana (DotGothic16) | PASS | PASS | PASS | **Conform** |
| Diacritice RO (virgulă dedesubt) | PASS | PASS | PASS | **Conform** |
| Feedback răspuns (text + culoare) | PASS | PASS | PASS | **Conform** |
| Întâlnire normală (Kappa, 50 HP) | PASS | PASS | PASS | **Conform** |
| Boss Tengu (120 HP, Faza 2 la $\le 60$ HP) | PASS | PASS | PASS | **Conform** |
| Emisie semnal `battle_finished` (win/lose/flee) | PASS | PASS | PASS | **Conform** |
| Performanță 60 FPS & Fără erori consolă | PASS | PASS | PASS | **Conform** |

---

## 5. Procedura de Raportare a Problemelor

Dacă în timpul sesiunilor viitoare de playtest cu testeri externi sau pe alte modele de dispozitive se descoperă comportamente neașteptate:
1. Se deschide un issue nou pe GitHub cu titlul: `[battle] playtest: <descriere scurtă a problemei>`.
2. Se adaugă eticheta obligatorie: **`playtest`**.
3. Se menționează în descriere:
   - Modelul exact de telefon și versiunea de browser/sistem.
   - Pașii de reproducere (ex: *„Răspuns la a treia întrebare de la Tengu”*).
   - Comportamentul așteptat vs. comportamentul observat.
   - Captură de ecran sau înregistrare video atașată.
