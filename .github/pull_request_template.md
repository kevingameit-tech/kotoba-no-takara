<!--
Titlul PR-ului: Conventional Commits, de exemplu `feat(battle): add damage formula`.
Regulile: CONTRIBUTING.md. Lista completă: docs/DEFINITION_OF_DONE.md.
-->

## Ce face

Closes #

## De ce (2 rânduri)



## Cum testezi

1. 
2. 
3. 

## Captură

<!-- Trage aici o captură sau un GIF. Pentru logică fără ecran: rezultatul din panoul GUT. Fără persoane în imagine. -->

## Definition of Done

- [ ] Issue legat (`Closes #N` mai sus)
- [ ] 1 aprobare de la cineva care a rulat codul
- [ ] CI verde (`validate-data` și `gut-tests`)
- [ ] Teste GUT pentru logica nouă sau schimbată
- [ ] Fără erori în build-ul web (desktop + 1 telefon), dacă schimbarea se vede sau se aude
- [ ] Fără text UI scris direct în cod: chei `MENU_` / `BATTLE_` / `WORLD_` / `UI_` cu RO și EN, sau câmpuri `{ro, en}` din `data/`
- [ ] Asset-urile noi sunt în `CREDITS.md`
- [ ] Pot explica fiecare rând din acest PR
- [ ] Respectă `docs/contracts.md` (schimbare de contract după înghețare: 2 aprobări)
- [ ] Fără build-uri, log-uri, date de testeri, chei sau date personale
- [ ] `project.godot` nu e în diff (sau PR-ul e dedicat lui)
- [ ] Commit-uri cu adresa noreply de la GitHub; fișierele `.uid` noi sunt incluse

<!-- Bifează și ce se aplică din docs/DEFINITION_OF_DONE.md, secțiunea 2 (UI, date, telemetrie). -->

## AI (opțional)

<!-- O propoziție: „am folosit AI pentru ...”, ca reviewer-ul să știe ce să întrebe. -->
