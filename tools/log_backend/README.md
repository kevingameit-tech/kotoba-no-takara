# tools/log_backend/

**Proprietar:** Kevin · Issue #51 · **Contract:** [docs/contracts.md, secțiunea 13](../../docs/contracts.md#13-telemetry-event-catalog-placeholder)

Backend-ul de log: un Google Apps Script publicat ca web app, care adaugă evenimentele jocului într-un Google Sheet privat.

**Stadiu: propunere.** Devine definitiv după decizia 7 (Apps Script sau Supabase) și cu înghețarea catalogului pe 26 oct.

| Fișier | Ce e |
|---|---|
| `Code.gs` | tot backend-ul: `setup()`, `doGet()`, `doPost()` și verificările |
| `appsscript.json` | setările proiectului Apps Script (fusul orar, permisiunea pentru Sheets, web app) |
| `test_log_backend.js` | testele, rulate cu Node și în CI |

## Ce face

- Primește un POST cu un **array JSON de evenimente**, trimis ca text (`text/plain`), după secțiunea 13.
- Verifică fiecare eveniment cu regulile din `tools/analyze_logs.py`, plus câteva mai stricte (tabelul de mai jos). Un eveniment bun devine un rând în foaia `events`. Unul greșit e numărat și aruncat, iar restul lotului se păstrează.
- Prin URL se pot **doar adăuga** rânduri. Nimeni nu poate citi, schimba sau șterge date prin el.

## Ce păstrează și ce nu

Un rând pe eveniment, cu toate celulele ca text: `received_at, v, build, sid, t_ms, platform, lang, event, data`. În `data` (text JSON) intră doar câmpurile din catalog.

**Nu păstrează:** adresa IP (Apps Script nu o dă scriptului), câmpurile necunoscute (sunt aruncate) și textul liber. Fiecare text are o regulă strictă, după câmp (tabelul de mai jos): id-uri cu litere mici, citiri romaji sau valori fixe, deci nu încap propoziții, spații sau diacritice. În modul „type”, `chosen` trebuie să fie gol, deci ce scrie jucătorul nu ajunge niciodată în foaie.

| Câmp | Ce acceptă |
|---|---|
| `v` | numărul 1 |
| `sid` | exact 32 de caractere `0-9a-f` (16 octeți aleatori, în hex) |
| `platform` | `web_desktop`, `web_android`, `web_ios`, `desktop` |
| `lang` | `ro`, `en` |
| `build` | gol, sau litere, cifre și `_ . + -`, maximum 32 de caractere |
| `item_id` | litere mici, cifre și `_`, începe cu o literă (`h_ki`), maximum 48 de caractere |
| `qid` | `q_` și cifre, cum le face QuizEngine (`q_0003`) |
| `encounter_id` | `c`, capitolul, `_`, apoi litere mici, cifre și `_` (`c1_kappa_1`) |
| `chosen` | o citire romaji, doar litere mici (`sa`), maximum 24; în modul „type” e mereu goală |
| `scene` | numele fișierului scenei, fără folder și extensie (`tokyo_town`), sau gol |
| numerele | doar întregi: `t_ms` și `elapsed_ms` de la 0 la 2147483647, `chapter` de la 1 la 99, `correct` și `wrong` din `battle_end` de la 0 la 999, `n_items` de la 1 la 100, scorurile de la 0 la `n_items` (`pre_score` poate fi și -1) |
| `mode`, `outcome`, `form`, `pre_form` | doar valorile din catalog |

Orice text începe cu o literă sau o cifră, deci nicio celulă nu poate deveni formulă (`=`, `+`, `-`, `@`).

## Răspunsul

- Lotul a fost citit: `{"ok": true, "stored": 7, "rejected": {"value": 1}}`. Motivele sunt cele din `tools/analyze_logs.py`: `json`, `version`, `event`, `field`, `value`.
- Tot lotul e refuzat, cu `{"ok": false, "error": "..."}`:

| `error` | Când |
|---|---|
| `empty`, `json`, `not_array` | corpul e gol, nu e JSON sau nu e un array |
| `too_many`, `too_large` | peste 200 de evenimente sau peste 60.000 de caractere |
| `setup` | nu s-a rulat `setup()` |
| `busy` | alt POST a ținut foaia ocupată peste 10 secunde |
| `full` | foaia are deja 200.000 de evenimente |
| `closed` | după 28 februarie 2027 ([PRIVACY.md](../../PRIVACY.md)) |
| `server` | Google Sheets a dat o eroare (o vezi în Apps Script, la Executions) |

## Ce cere de la client (`autoload/telemetry.gd`, Mariana, #50)

1. POST la URL-ul care se termină cu `/exec`, cu **un singur header: `Content-Type: text/plain`**. Cu alt header (de exemplu `application/json`) browserul trimite întâi o cerere OPTIONS, la care Apps Script nu răspunde, și evenimentele nu mai pleacă.
2. Corpul este array-ul JSON, cu maximum 200 de evenimente.
3. Nu aștepta răspunsul și nu repeta cererea. Google trimite răspunsul printr-o redirecționare, dar rândurile sunt deja scrise când ajunge POST-ul.
4. Pentru ultimul lot, când pagina se ascunde sau se închide: în browser, `fetch(url, {method: "POST", body: text, keepalive: true, credentials: "omit"})` prin `JavaScriptBridge`. `keepalive` termină trimiterea și după ce pagina s-a închis (maximum 64 KiB), iar `credentials: "omit"` nu trimite cookie-urile Google ale jucătorului.

## Pornirea (o singură dată, cam 15 minute, Kevin)

După decizia 7.

1. Într-un cont Google al proiectului, creează un Google Sheet nou, de exemplu „Kotoba no Takara log”. **Nu-l partaja public**: e tabelul privat al echipei din PRIVACY.md.
2. În foaie: **Extensions → Apps Script** (Extensii → Apps Script).
3. În editor, înlocuiește tot conținutul din `Code.gs` cu fișierul `tools/log_backend/Code.gs` și salvează.
   - Opțional: în **Project Settings**, bifează „Show "appsscript.json" manifest file in editor”.
   - Apoi înlocuiește `appsscript.json` cu fișierul de aici.
4. Lângă **Run**, alege funcția `setup` și apasă **Run**.
   - Google cere permisiunea pentru Sheets: **Review permissions**, alegi contul, apoi **Allow**.
   - Dacă apare „Google hasn't verified this app”: **Advanced**, apoi **Go to … (unsafe)**. E normal pentru un script propriu.
   - În foaie apare tabul `events`, cu antetul.
5. **Deploy → New deployment**. La „Select type” (rotița), alege **Web app**.
   - **Execute as: Me**
   - **Who has access: Anyone**
   - Apasă **Deploy** și copiază **Web app URL** (se termină cu `/exec`).
6. Verifică:
   - Deschide URL-ul în browser. Trebuie să vezi `{"ok":true,"service":"kotoba-no-takara-log",...}`.
   - Trimite un eveniment de test cu build-ul `test`, pe care raportul cu `--build 0.1` îl lasă deoparte. În comanda de mai jos pui URL-ul tău în locul lui `URL_EXEC`. Răspunsul trebuie să fie `{"ok":true,"stored":1,"rejected":{}}`, iar în foaie apare un rând nou:

```bash
curl -L -H "Content-Type: text/plain" --data '[{"v":1,"build":"test","sid":"00000000000000000000000000000000","t_ms":0,"platform":"desktop","lang":"ro","event":"session_start","data":{}}]' "URL_EXEC"
```

7. Dă URL-ul Marianei pentru #50. Nu e secret, pentru că ajunge oricum în build-ul public, dar nu-l publica în alte locuri.

## Când schimbi codul

Ce salvezi în editor nu ajunge singur la URL. Mergi la **Deploy → Manage deployments**, alegi deployment-ul activ și apeși creionul (**Edit**). La **Version** alegi **New version**, apoi **Deploy**. URL-ul rămâne același.

## Exportul și analiza

1. În foaia `events`: **File → Download → Comma-separated values (.csv)**.
2. Fișierul rămâne pe calculatorul tău, **în afara repo-ului**.
3. Rulează analiza:

```bash
python3 tools/analyze_logs.py events.csv --build 0.1
```

## Ștergerea datelor (PRIVACY.md)

Până la **1 martie 2027**:

1. Șterge Google Sheet-ul, apoi golește coșul (Trash).
2. Arhivează deployment-ul: **Deploy → Manage deployments → Archive deployment**.

Din 1 martie 2027 codul refuză oricum orice POST (`closed`).

## Limite

- Cel mult 200 de evenimente și 60.000 de caractere pe POST, 200.000 de evenimente în total.
- Limitele Google: cel mult 30 de execuții în același timp pentru contul care a publicat și 6 minute pe execuție ([Quotas](https://developers.google.com/apps-script/guides/services/quotas)).
- URL-ul e public, pentru că ajunge în build-ul web. Cine îl află poate trimite evenimente false în formatul corect și cu build-ul nostru, deci `--build` nu le separă. Poate și să umple foaia (`full`) sau să o țină ocupată (`busy`).
- De aceea, după fiecare zi de playtest, Kevin se uită la foaie: câte rânduri au venit și la ce ore (`received_at`). Rândurile suspecte, de exemplu sute de sesiuni în câteva secunde, le șterge din foaie înainte de export. Dacă cineva atacă foaia, arhivează deployment-ul și face unul nou, cu URL nou, pentru build-ul următor.

## Testele

```bash
node tools/log_backend/test_log_backend.js
```

Testele rulează `Code.gs` cu servicii Google false (Node 20 sau mai nou, fără pachete). Verifică:

- ce se păstrează, ce se aruncă și cu ce motiv;
- limitele;
- că `tools/analyze_logs.py` citește fiecare rând păstrat, fără să sară vreunul, și că nicio celulă nu poate deveni formulă (pe 6 sesiuni complete și 600 de evenimente stricate la întâmplare).

CI le rulează în jobul `validate-data`.

## Surse

- [Web Apps](https://developers.google.com/apps-script/guides/web): `doPost(e)` și `e.postData.contents`.
- [Content Service](https://developers.google.com/apps-script/guides/content): răspunsul trece printr-o redirecționare la `script.googleusercontent.com`.
- [Container-bound scripts](https://developers.google.com/apps-script/guides/bound): `getActiveSpreadsheet()` nu merge într-un web app. De aceea `setup()` ține minte id-ul foii.
- [Deployments](https://developers.google.com/apps-script/concepts/deployments): versiuni noi cu același URL și arhivarea.
- [Manifest: webapp](https://developers.google.com/apps-script/manifest/web-app-api-executable): `ANYONE_ANONYMOUS` și `USER_DEPLOYING`.
- [RequestInit (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/RequestInit): `keepalive` (maximum 64 KiB) și `credentials: "omit"`.
- Godot trimite header-ele din `HTTPRequest` direct la `fetch()` din browser: `platform/web/http_client_web.cpp` și `platform/web/js/libs/library_godot_fetch.js` din [codul Godot](https://github.com/godotengine/godot).
