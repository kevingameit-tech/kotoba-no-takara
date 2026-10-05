# autoload/

**Proprietari:** câte un fișier pentru fiecare proprietar.

- Mariana: `settings.gd`, `game_state.gd` (propunere), `save_manager.gd`, `telemetry.gd`. Kevin: `question_bank.gd` și catalogul de evenimente. David: `scene_router.gd`.
- Proprietarul își creează fișierul când are nevoie de el. Linia din `project.godot` intră într-un PR mic, separat.
- Ordinea și regulile: [docs/contracts.md](../docs/contracts.md), secțiunea „Autoloads”.
- Nu numi niciun autoload `Logger`: Godot are deja o clasă cu acest nume.
- Un autoload nu caută noduri după cale. Vorbește doar prin semnalele și metodele din contracte.
- Nu pune aici: scene, cod folosit de o singură scenă, `QuizEngine` (nu este autoload).
