# fonts/

**Proprietar:** Mariana.

- Aici stau fonturile jocului. Lângă fiecare font stă licența lui (`OFL.txt`).
- Pixelify Sans pentru română și engleză (`PixelifySans-VariableFont_wght.ttf`, licență `OFL_PixelifySans.txt`), DotGothic16 pentru kana și kanji.
- Configurat în `res://ui/theme.tres`: Pixelify Sans este fontul de bază, iar DotGothic16 (`dotgothic16_kana.ttf`) este fallback.
- DotGothic16 nu are ă, ș, ț, deci textul românesc rămâne pe Pixelify Sans.
- Dacă folosim un subset de font, îl refacem când apar caractere noi în `data/` sau `i18n/`.
- Contract: [docs/contracts.md](../docs/contracts.md), secțiunea „Fonts”.
- Nu pune aici: fonturi fără licență liberă clară. Fiecare font are un rând în `CREDITS.md`.
- `dotgothic16_kana.ttf`: subset din DotGothic16 (kana, ○ × →, punctuația japoneză și caracterele din `data/` și `i18n/ui.csv`), 142 KB în loc de 2 MB. Licența: `OFL_DotGothic16.txt`. Build-ul web nu are fonturi de sistem, deci fără el kana apar ca pătrățele. Refacere: `pyftsubset DotGothic16-Regular.ttf --unicodes="U+0020-007E,U+00D7,U+2190-2193,U+25CB,U+25EF,U+3000-303F,U+3040-309F,U+30A0-30FF,U+FF01-FF5E" --text="<caracterele noi>" --output-file=fonts/dotgothic16_kana.ttf`.
