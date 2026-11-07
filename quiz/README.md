# quiz/

**Proprietar:** Kevin.

- Aici stau QuizEngine (un `RefCounted`, unul pentru fiecare luptă), RomajiConverter și ecranele de pre-test și post-test.
- QuizEngine ia întrebările din `QuestionBank` (`autoload/question_bank.gd`), după un `pool_id`.
- API: `start(pool_id, rng_seed)`, `next_question()`, `submit(qid, answer, elapsed_ms)` și semnalul `answered`.
- `PrePostTest` (`pre_post_test.gd`): logica testului de la început și de la final. Alege forma A sau B, pune fiecare dintre cele 10 kana o singură dată, numără scorul fără să arate răspunsul corect și pregătește datele pentru `GameState.pretest` și evenimentele `pretest` / `posttest`. Ecranele se construiesc peste ea.
- `PrePostScreen` (`pre_post_screen.tscn`): ecranele pentru pre-test și post-test peste `PrePostTest` (#46): explicația, cele 10 întrebări fără răspunsuri corecte, mulțumirea, apoi semnalul `finished`. Textele sunt chei din `i18n/ui.csv`. Când există `GameState` și `Telemetry`, scrie `GameState.pretest` și trimite `pretest` / `posttest`.
- `QuizStyle` (`quiz_style.gd`): culorile și butoanele comune ale ecranelor din `quiz/`, până la Theme-ul Marianei (#37).
- `QuizDemo` (`quiz_demo.tscn`): o întrebare de luptă pe ecran, cu datele reale (rândurile a și k), pentru demo-ul prototipului. Se pornește singură: deschizi scena în Godot și apeși F6. Ecranul de luptă adevărat e în `battle/` (Ioana).
- Contract: [docs/contracts.md](../docs/contracts.md), secțiunea „QuestionBank and QuizEngine”. `FakeQuizEngine` (Ioana) are același API.
- Nu pune aici: conținutul lecțiilor (merge în `data/`), logica luptei (merge în `battle/`), text UI scris în cod.
- Fiecare funcție nouă primește teste GUT în `tests/unit/`.
