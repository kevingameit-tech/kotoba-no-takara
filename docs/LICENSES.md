# Licențe

Pe scurt: codul e MIT, lecțiile și vocea înregistrată sunt CC BY-NC-SA 4.0, fonturile sunt OFL, grafica externă e CC0. Toți patru putem refolosi proiectul după curs.

Cine face un Pull Request acceptă regulile din acest fișier pentru ce adaugă.

## 1. Ce licență are fiecare parte

| Ce | Unde | Licență | Textul licenței |
|---|---|---|---|
| Codul nostru (GDScript, Python, shell, CI), documentația și configurările | tot repo-ul, cu excepțiile de mai jos | MIT | [LICENSE](../LICENSE) |
| Conținutul lecțiilor (JSON) | `data/` | CC BY-NC-SA 4.0 | [creativecommons.org/licenses/by-nc-sa/4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) |
| Audio înregistrat de echipă (voce) | `assets/audio/` (când apare) | CC BY-NC-SA 4.0 | idem |
| Fonturi | `fonts/` | SIL Open Font License 1.1 | `OFL.txt` lângă fiecare font |
| Grafică, sunete și muzică externe | `assets/` | CC0 1.0 (de exemplu Ninja Adventure) | rând în [CREDITS.md](../CREDITS.md) |

**CC BY-NC-SA 4.0** înseamnă: oricine poate copia și adapta lecțiile, dacă numește autorii (BY), nu le folosește comercial (NC) și publică adaptarea sub aceeași licență (SA). Atribuirea: „Kotoba no Takara team (Kevin, Mariana, David, Ioana), CC BY-NC-SA 4.0”.

Conținutul japonez din `data/` e scris de Kevin. O parte vine din aplicația lui de învățare, JapanLogic (de exemplu lista de kana cu romaji). Kevin e autorul ei, aduce datele aici sub licența de mai sus și își păstrează dreptul de a le folosi în continuare oriunde, inclusiv în JapanLogic.

## 2. Cod și unelte de la alții

| Componentă | Licență | Cum ajunge în proiect | Ce facem |
|---|---|---|---|
| Godot Engine 4.7.2 | MIT | fiecare îl instalează; motorul intră în build-ul web | textul de licență Godot apare în ecranul de credite (vezi [Complying with licenses](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)) |
| GUT 9.7.1 | MIT | `tools/install_gut.sh` îl pune în `addons/gut/`; **nu e în Git** | exclus din exportul web; menționat în credite |
| WanaKana | MIT | doar dacă Kevin portează convertorul romaji (16 nov) | notița MIT în antetul fișierului portat + un rând aici |
| Ninja Adventure | CC0 1.0 | `assets/` | rând în CREDITS.md (nu e obligatoriu, dar îl trecem) |
| Pixelify Sans, DotGothic16 (propunere) | OFL 1.1 | `fonts/` | `OFL.txt` lângă fiecare font + rând în CREDITS.md |

**De ce GUT nu e în repo:** statisticile de cod (Insights) trebuie să arate doar codul echipei. Scriptul descarcă mereu aceeași versiune (tag-ul v9.7.1), deci toți și CI-ul au exact același GUT.

**Cod luat de altundeva:** înainte să-l pui în proiect, verifici licența. Acceptăm doar MIT, BSD, Apache 2.0, CC0 sau OFL (pentru fonturi). Scrii sursa și licența într-un comentariu în fișier și adaugi un rând în tabelul de mai sus.

## 3. Reutilizare după curs

Ne-am înțeles așa:

1. **Fiecare membru poate refolosi tot proiectul după curs:** cod, conținut, asset-uri create de echipă. De exemplu în portofoliu, în CV, într-o versiune proprie a jocului.
2. **Codul** e MIT, deci oricine îl poate folosi, cu condiția să păstreze notița de copyright.
3. **Kevin poate folosi conținutul (`data/`, audio) în lecțiile lui de japoneză, inclusiv în cele plătite.** Restul lumii îl primește sub CC BY-NC-SA 4.0.
4. **Contribuțiile altor membri la `data/` sau la audio:** prin Pull Request, autorul le dă celorlalți trei membri o permisiune permanentă și gratuită de a le refolosi, inclusiv comercial. Această permisiune se adaugă licenței CC BY-NC-SA 4.0 și nu o înlocuiește pentru alte persoane.
5. Asset-urile, fonturile și uneltele de la alții rămân sub licențele lor (secțiunea 2).

Nu suntem juriști. Dacă apare o situație neclară, citim textul licenței și discutăm în echipă înainte să publicăm ceva.
