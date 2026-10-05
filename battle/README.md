# battle/

**Proprietar:** Ioana.

- Aici stau BattleModel (logica luptei, fără noduri), Battler, BattleScene și inamicii în `battle/data/enemies/*.tres`.
- Întrebările vin doar de la `QuizEngine` (din `quiz/`). Lupta decide doar cât HP se pierde.
- Pool-ul de întrebări al unei lupte stă în `data/encounters.json`, nu în `.tres`.
- Contracte: [docs/contracts.md](../docs/contracts.md), secțiunile „QuestionBank and QuizEngine”, „Battle hand-off” și „Battle data”.
- Nu pune aici: întrebări sau text japonez (merg în `data/`), text UI scris în cod, scrieri într-un `.tres` încărcat (copiază statisticile într-un `Battler`).
- Testele pentru BattleModel merg în `tests/unit/` și folosesc `FakeQuizEngine`.
