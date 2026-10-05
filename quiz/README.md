# quiz/

**Proprietar:** Kevin.

- Aici stau QuizEngine (un `RefCounted`, unul pentru fiecare luptă), RomajiConverter și ecranele de pre-test și post-test.
- QuizEngine ia întrebările din `QuestionBank` (`autoload/question_bank.gd`), după un `pool_id`.
- API: `start(pool_id, rng_seed)`, `next_question()`, `submit(qid, answer, elapsed_ms)` și semnalul `answered`.
- Contract: [docs/contracts.md](../docs/contracts.md), secțiunea „QuestionBank and QuizEngine”. `FakeQuizEngine` (Ioana) are același API.
- Nu pune aici: conținutul lecțiilor (merge în `data/`), logica luptei (merge în `battle/`), text UI scris în cod.
- Fiecare funcție nouă primește teste GUT în `tests/unit/`.
