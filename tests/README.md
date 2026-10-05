# tests/

**Proprietar:** cine scrie codul testat. Ioana păstrează modelul de test.

- Testele GUT stau în `tests/unit/`, cu numele `test_<subiect>.gd`, și încep cu `extends GutTest`.
- Prima dată instalezi GUT: `bash tools/install_gut.sh` (macOS, Linux) sau `powershell -ExecutionPolicy Bypass -File tools/install_gut.ps1` (Windows).
- În editor: deschizi panoul GUT, la setări (Test Directories) adaugi `res://tests/unit`, bifezi Include Subdirs și apeși Run All.
- În terminal: `godot --headless --import`, apoi `godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit`.
- CI rulează aceleași comenzi în jobul `gut-tests`, la fiecare PR. Contract: [docs/contracts.md](../docs/contracts.md), secțiunea „Folders and ownership”.
- Nu pune aici: teste care au nevoie de internet, teste care depind de ordinea lor, date reale ale jucătorilor.
