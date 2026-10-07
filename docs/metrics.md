# Metricile (fixate înainte de v0.1)

Proprietar: Kevin · Issue #51 · Versiunea v0, 7 oct 2026, propunere până la înghețarea catalogului (26 oct).

Le fixăm **înainte** să vedem datele, ca să nu alegem după aceea doar ce iese frumos. Tot ce e aici calculează `tools/analyze_logs.py`.

## De unde vin datele

- **Evenimentele din joc**, după catalogul din [contracts.md, secțiunea 13](contracts.md#13-telemetry-event-catalog-placeholder): doar id-uri, numere și valori fixe. Fără nume, fără text scris de jucător, fără id permanent.
- **Chestionarul de după joc** (Google Form): grupa de vârstă și cele 10 întrebări SUS. Fără e-mail, fără login, fără text liber.
- Datele brute **nu intră niciodată în repo**. În `docs/data/` punem doar fișierul cu numere agregate scris de `tools/analyze_logs.py --json`. Fișierele brute se șterg până la 1 martie 2027 ([PRIVACY.md](../PRIVACY.md)).

## Metricile

| # | Metrica | Cum o calculăm | Din ce eveniment | Ce aflăm |
|---|---|---|---|---|
| 1 | Abandon | sesiunile care au pornit (`session_start`) și nu au ajuns la `posttest`; ultima scenă din `quit` | toate | unde se opresc jucătorii |
| 2 | Acuratețe pe kana | răspunsuri corecte împărțit la toate răspunsurile, pentru fiecare `item_id`; în lista „cele mai grele” intră doar kana cu cel puțin 5 răspunsuri | `answer` | ce kana trebuie explicate mai bine |
| 3 | Curba de învățare | acuratețea la întâlnirea 1, 2, 3, 4 și „5 sau mai târziu” cu aceeași kana, în aceeași sesiune | `answer`, în ordinea lui `t_ms` | dacă jucătorii învață în timp ce joacă |
| 4 | Confuzii | cele mai dese 10 perechi (kana cerută, citirea aleasă) la răspunsurile greșite la alegere | `answer.chosen` | ce perechi se confundă (de exemplu ぬ și め) |
| 5 | Timp pe întrebare | mediana și quartilele lui `elapsed_ms`; un răspuns de peste 60 s nu intră aici (jucătorul era plecat), dar intră la acuratețe | `answer` | dacă o întrebare e prea grea sau prea lentă |
| 6 | Pre-test și post-test | pentru fiecare `posttest` care are pre-test: câștigul = scorul după minus scorul înainte. Raportăm media, mediana, câți au crescut, au rămas la fel sau au scăzut, testul semnului și câștigul normalizat | `posttest` (are și `pre_form`, `pre_score`) | cât au învățat, fără id de jucător |
| 7 | Formele A și B | media scorului la pre-test pentru forma A și pentru forma B | `pretest` | dacă cele două forme sunt la fel de grele |
| 8 | SUS | scorul SUS de la 0 la 100 pentru fiecare chestionar complet, apoi media | chestionarul | cât de ușor de folosit e jocul (68 = media obișnuită) |

Câștigul normalizat: (după minus înainte) împărțit la (10 minus înainte), adică ce parte din ce mai era de învățat a fost învățată. Cine avea deja 10 la pre-test nu intră în această medie.

## Reguli fixe

- **Minimum 5 jucători într-un grup.** Scorurile (pre-test, post-test, SUS) unui grup cu mai puțin de 5 jucători nu se raportează, ca nimeni să nu poată fi recunoscut.
- **60 de secunde.** Un răspuns de peste 60 s nu intră la timp.
- **Sesiune, nu jucător.** `sid` trăiește doar în memorie: dacă cineva reîncarcă pagina, începe o sesiune nouă. Abandonul se numără pe sesiuni.
- **Fără grup de control.** Pre-testul și post-testul arată dacă scorul crește, nu că jocul e singura cauză (chiar și pre-testul e deja o repetiție).
- **Curba de învățare nu e un experiment.** Kana greșite revin mai des (cutiile Leitner), deci la întâlnirile 2 și 3 sunt mai multe kana grele.
- **Un singur build.** Pentru raport filtrăm cu `--build`, de exemplu doar v0.1.
- **Testul semnului** spune cât de probabil ar fi un raport atât de inegal între „au crescut” și „au scăzut” dacă jocul nu ar schimba nimic. Sub 0,05 spunem „diferență clară”, niciodată „dovedit”.
- Un răspuns marcat greșit, deși citirea aleasă e cea corectă, nu intră la confuzii: scriptul îl arată separat, pentru că înseamnă o greșeală în codul care scrie evenimentul.

## Chestionarul (Google Form)

Setări: nu colectează adrese de e-mail, nu cere login, nu limitează la un singur răspuns (limitarea cere login), nu are întrebări cu text liber.

**Vârsta** (o singură alegere): sub 16 ani · 16 sau 17 ani · 18 până la 24 de ani · 25 până la 39 de ani · 40 de ani sau mai mult.

**Cele 10 întrebări SUS**, fiecare pe o scală de la 1 (deloc de acord) la 5 (total de acord). Titlul fiecărei întrebări începe cu numărul ei, de la „1.” la „10.”, după care o găsește scriptul.

1. Cred că mi-ar plăcea să joc des acest joc.
2. Jocul mi s-a părut complicat fără rost.
3. Jocul a fost ușor de folosit.
4. Cred că aș avea nevoie de ajutorul cuiva ca să pot juca.
5. Părțile jocului (harta, lupta, meniurile) se potrivesc bine între ele.
6. Multe lucruri din joc nu se potriveau între ele.
7. Cred că majoritatea oamenilor ar învăța repede să joace.
8. Mi s-a părut greoi să joc.
9. Am avut încredere în mine când am jucat.
10. A trebuit să învăț multe lucruri înainte să pot juca.

Scorul unui chestionar: la întrebările impare (1, 3, 5, 7, 9) luăm răspunsul minus 1, la cele pare (2, 4, 6, 8, 10) luăm 5 minus răspunsul, adunăm și înmulțim cu 2,5. Formularea e simplificată de noi după Brooke (1996) și nu e o traducere validată, deci comparăm mai ales versiunile jocului între ele.

## Cum rulezi

```bash
python3 tools/analyze_logs.py export.csv --build 0.1
python3 tools/analyze_logs.py export.csv --build 0.1 --form chestionar.csv --json docs/data/rezumat_v0.1.json
python3 tools/test_analyze_logs.py
```

`export.csv` este exportul din backend ([tools/log_backend/](../tools/log_backend/README.md)), cu coloanele `v, build, sid, t_ms, platform, lang, event, data` (`data` ca text JSON). Merge și un fișier `.jsonl`, cu un eveniment pe rând. Exporturile brute rămân pe calculatorul lui Kevin, în afara repo-ului.

## Ce arătăm la prezentarea finală

1. Scorul înainte și după (media, cu numărul de perechi).
2. Cele mai grele 5 kana și primele 5 confuzii.
3. Pâlnia de abandon: au pornit, pre-test, prima luptă, post-test.
4. Media SUS.

## Surse

- Brooke, J. (1996). SUS: A “quick and dirty” usability scale. În P. W. Jordan et al. (ed.), *Usability Evaluation in Industry*, 189-194. Taylor & Francis.
- Sauro, J. *Measuring Usability with the System Usability Scale (SUS)*. MeasuringU. <https://measuringu.com/sus/> (media 68).
- Hake, R. R. (1998). Interactive-engagement versus traditional methods. *American Journal of Physics*, 66(1), 64-74. (câștigul normalizat)
