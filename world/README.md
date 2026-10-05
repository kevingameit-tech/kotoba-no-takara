# world/

**Proprietar:** David.

- Aici stau hărțile (orașul Tokyo, altarul), Player, NPC-urile, DialogueBox și EnemyMarker.
- O luptă pornește doar prin `SceneRouter.start_battle(encounter_id)`. Id-ul vine din `data/encounters.json`.
- Un dialog pornește cu `DialogueBox.play(id)`. Replicile vin din `data/dialogue/`, nu se scriu în scenă.
- Contracte: [docs/contracts.md](../docs/contracts.md), secțiunile „Input Map”, „Battle hand-off” și „Dialogue”.
- Nu pune aici: logica luptei (merge în `battle/`), text UI scris direct în cod (folosește cheile din `i18n/`), imagini (merg în `assets/`).
- Fiecare scenă `.tscn` are un singur proprietar. Nu face merge de mână la un `.tscn`.
