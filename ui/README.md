# ui/

**Proprietar:** Mariana.

- Aici stau meniurile, ecranul de titlu, Theme-ul, componentele HUD și TouchControls.
- Tot textul vizibil vine din chei de traducere (`MENU_`, `BATTLE_`, `WORLD_`, `UI_`) din `i18n/`.
- Butoanele de pe ecran trimit aceleași acțiuni ca tastatura: `move_*`, `interact`, `cancel`, `menu`.
- Contracte: [docs/contracts.md](../docs/contracts.md), secțiunile „Settings and UI text keys” și „Input Map”.
- Nu pune aici: text scris direct în cod, fonturi (merg în `fonts/`), logica jocului sau a luptei.
