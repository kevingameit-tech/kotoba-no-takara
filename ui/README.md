# ui/

**Proprietar:** Mariana.

- Aici stau meniurile, ecranul de titlu, Theme-ul, componentele HUD și TouchControls.
- `theme.tres`: tema globală cu fontul Pixelify Sans și fallback DotGothic16.
- `touch_controls.tscn` (`touch_controls.gd`): controale pe ecran cu joystick virtual pe `move_*` (deadzone 0.35) și butoane A (`interact`), B (`cancel`), Menu (`menu`).
- `rotate_overlay.tscn` (`rotate_overlay.gd`): overlay afișat când dispozitivul este ținut în mod portret.
- `tap_to_start.tscn` (`tap_to_start.gd`): ecran inițial „Tap to start” pentru deblocarea contextului audio pe Web și mobil.
- Tot textul vizibil vine din chei de traducere (`MENU_`, `BATTLE_`, `WORLD_`, `UI_`) din `i18n/`.
- Butoanele de pe ecran trimit aceleași acțiuni ca tastatura: `move_*`, `interact`, `cancel`, `menu`.
- Contracte: [docs/contracts.md](../docs/contracts.md), secțiunile „Settings and UI text keys” și „Input Map”.
- Nu pune aici: text scris direct în cod, fonturi (merg în `fonts/`), logica jocului sau a luptei.
