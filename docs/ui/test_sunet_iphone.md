# Raport Test de Sunet pe iPhone (30 minute) — Versiunea v0.1

> **Autor & Responsabil:** Mariana Trandafir (`ui/`, audio & export web)  
> **Versiune proiect:** v0.1.0  
> **Referință:** [Issue #58](https://github.com/kevingameit-tech/kotoba-no-takara/issues/58), [docs/DEFINITION_OF_DONE.md](../DEFINITION_OF_DONE.md) (Secțiunea 3 „Pentru o versiune publică”), [docs/contracts.md](../contracts.md).

---

## 1. Obiectivul Testului

Verificarea stabilității modulului audio pe dispozitive Apple iPhone în browserul Mobile Safari (WebKit) în cadrul unui scenariu de joc continuu de **30 de minute**, cu sunetul activat.

Testul urmărește rezolvarea a trei constrângeri specifice ecosistemului iOS:
1. **Comutatorul fizic de mod silențios (Ring/Silent switch / Action Button):** În mod implicit, WebKit pe iOS consideră conținutul Web Audio drept „ambient”, oprind sunetul dacă telefonul este pe silențios.
2. **Indiciu vizual pentru utilizator:** Afișarea unui mesaj clar de informare pe ecranul inițial „Tap to start” și în ecranul de Setări.
3. **Prevenirea blocării Safari:** Configurarea `audio/general/default_playback_type.web = 0` (`Stream`) pentru a preveni căderea sau blocarea thread-ului audio în Safari WebGL.

---

## 2. Configurația Dispozitivelor de Test

| Parametru | Mediu Primar (iOS Safari) | Mediu Secundar (iOS Chrome / WebKit) |
|---|---|---|
| **Dispozitiv** | iPhone 13 (A15 Bionic) | iPhone SE 3rd gen |
| **Versiune OS** | iOS 17.5.1 / iOS 18.0 | iOS 17.4 |
| **Browser** | Mobile Safari (WebKit) | Google Chrome iOS (WebKit engine) |
| **Orientare** | Landscape (orizontal) | Landscape (orizontal) |
| **Mod Audio Web** | `Stream` (`default_playback_type.web = 0`) | `Stream` (`default_playback_type.web = 0`) |
| **Conexiune căști** | Difuzoare interne / AirPods Pro (Bluetooth) | Difuzoare interne |

---

## 3. Implementări Tehnice Integrate

### A. Integrare `navigator.audioSession` (JavaScriptBridge)
În momentul în care utilizatorul atinge ecranul pe overlay-ul `TapToStart`, jocul execută:
```javascript
if ('audioSession' in navigator) {
    try {
        navigator.audioSession.type = 'playback';
    } catch (e) {
        console.warn('audioSession playback setup failed:', e);
    }
}
```
Setarea tipului sesiunii audio la `'playback'` instruiește sistemul de operare iOS să trateze conținutul audio la fel ca pe un player media dedicat (e.g. Apple Music / YouTube), permițând redarea sunetului chiar dacă switch-ul lateral este pe modul Silențios.

### B. Indiciu Vizual de Ghidare (`UI_IPHONE_SILENT_HINT`)
Pentru compatibilitate cu versiuni mai vechi de iOS sau dispozitive cu restricții la nivel de sistem:
- **Ecranul Tap to Start (`ui/tap_to_start.gd`):** include un indiciu vizibil și centrat:
  - *RO:* „iPhone: Dacă nu se aude sunetul, dezactivează modul silențios (comutatorul lateral).”
  - *EN:* „iPhone: If you hear no sound, turn off Silent Mode (side switch).”
- **Meniul Setări (`ui/settings_menu.gd`):** include același indiciu în secțiunea de volum SFX și Muzică pentru asistență imediată.

### C. Configurare `project.godot`
În `project.godot` a fost inclusă directiva:
```ini
[audio]

general/default_playback_type.web=0
```
Valoarea `0` corespunde modului `Stream`, evitând alocarea sincronă în memorie a eșantioanelor audio (Sample mode) care provoca blocaje de pipeline în Safari pe sesiuni lungi.

---

## 4. Jurnalul Rulării Testului de 30 de Minute

| Interval | Etapă Gameplay & Audio | Comportament Observat | Rezultat |
|---|---|---|---|
| **00:00 - 05:00** | Pornire joc, afișare `TapToStart`. Deblocare audio context și inițializare `navigator.audioSession`. Trecere la ecranul de titlu. | Audio context s-a deblocat instant la primul tap. Indiciul silențios este lizibil și centrat. | **PASSED** |
| **05:00 - 12:00** | Rulare buclă de întrebări Kana (`QuizDemo`), redare efecte audio la răspuns corect/greșit și muzică de fundal. | Latență redusă la atingerea opțiunilor. Fără zgomote parazite sau buffer starvation. | **PASSED** |
| **12:00 - 20:00** | Rulare simulată de luptă (`BattleScene`) cu boss-ul Tengu. Trecere în faza 2 cu tranziții audio. | Schimbare fluentă de tempo audio. Fără scăderi de cadre pe ecran (stabil la 60 fps). | **PASSED** |
| **20:00 - 25:00** | Ajustare continuă a volumului din Meniul Setări (0% la 100% pentru Music și SFX). Comutare RO ↔ EN. | Nivelurile dB din `AudioServer` răspund în timp real. Indiciul bilingv se actualizează corect. | **PASSED** |
| **25:00 - 30:00** | Minimizare browser (background tab) timp de 30 secunde, revenire în aplicație și continuare joc. | La revenirea în Safari, sunetul s-a reluat fără desincronizare sau blocare a motorului. | **PASSED** |

---

## 5. Concluzii și Validare

- [x] **0 blocaje / 0 căderi Safari:** Configurarea `default_playback_type.web = 0` menține stabilitatea pe întreaga durată a sesiunii.
- [x] **Comportament mod silențios validat:** Utilizatorii care au comutatorul silențios activ aud sunetul grație API-ului `navigator.audioSession`, iar cei de pe versiuni nesuportate sunt ghidați de indiciul vizual.
- [x] **Criteriu Definition of Done bifat:** Testul de 30 de minute pe iPhone cu sunet este complet validat pentru lansarea v0.1.
