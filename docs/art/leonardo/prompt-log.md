# Prompt-Log Leonardo

Freigegebene Bilder aus Leonardo.ai, mit allem, was man zum Nachbauen braucht. Regeln und Stilblock stehen im [Computerladen Style-Guide](https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX), Abschnitt Leonardo-Workflow.

Gemeinsame Einstellungen, wenn nicht anders angegeben: Modell Lucid Origin, Prompt Enhance aus, Style None, Generation Mode Fast, größte Bildgröße. Der Seed gilt für den ganzen Durchgang; „Bild“ ist die Nummer der Datei in diesem Durchgang.

## S-C Stilanker C2

- Datei: `stilanker-c2.jpg`, 1920 × 1088
- Datum: 2026-10-19
- Durchgang: `1f1cbc3d-5cb5-6590-ae38-7f1e46308bed`, Bild 0, Seed 1622989587
- Format: 16:9, 2 Bilder, ohne Stil-Referenz
- Status: Stilanker, alle weiteren Bilder laufen mit ihm als Style Reference

> Interior of a small, cramped German computer shop in the early 1990s. The shopkeeper, a man in his late thirties with a moustache, a short-sleeved light blue shirt and a red tie, stands behind a wooden counter and leans forward with a friendly, slightly sly smile. On the counter a beige desktop PC with a CRT monitor, a dot-matrix printer with continuous form paper with pale green stripes, and a cash register with a green glowing display. Behind him, shelves full of colorful software boxes and floppy disks. Warm interior light from the upper left. Wide shot. Early 1990s VGA point-and-click adventure game screenshot: pixel art at 320x200 resolution scaled up, limited 256-color palette, clearly visible square pixels, hand-placed dithering in the shading, crisp dark outlines, no anti-aliasing. No text, no lettering, no logos, no user interface.

## F-01 Figurenblatt Ladenbesitzer

- Datei: `f-01-figurenblatt.jpg`, 1920 × 1088
- Datum: 2026-10-19
- Durchgang: `1f1cbc52-4bab-6e10-a964-41d50c7fc5a5`, Bild 1, Seed 136014704
- Format: 16:9, 2 Bilder, Style Reference C2 (High)
- Status: Basis fürs Figurenblatt. Nacharbeit nötig: Kritzel-Beschriftungen und die zwei grauhaarigen Köpfe entfernen, Seitenansicht fehlt.

> Character reference sheet of one shopkeeper on a plain light grey background: front view, side view and back view standing, plus three close-up faces with a friendly smile, a skeptical raised eyebrow and a shocked look. A man in his late thirties with dark hair, a moustache, a short-sleeved light blue shirt with a small name badge, a red striped tie and dark trousers. Same character and same scale in every view, evenly spaced. Early 1990s VGA point-and-click adventure game screenshot: pixel art at 320x180 resolution scaled up, limited 256-color palette, clearly visible square pixels, hand-placed dithering in the shading, crisp dark outlines, no anti-aliasing. No text, no lettering, no logos, no user interface.

## T-01 Titelbild

- Datei: `t-01-titelbild.jpg`, 1920 × 1088
- Datum: 2026-10-19
- Durchgang: `1f1cbc54-7717-6610-920b-dfc60aa0233f`, Bild 1, Seed 907617441
- Format: 16:9, 4 Bilder, Style Reference C2 (High)
- Status: freigegeben für den Titelscreen. Noch nicht aufs Bildraster 320 × 180 gebracht.

> A small German computer shop on a street corner at dusk in the early 1990s. Old plastered town house with a big shop window glowing warm yellow; inside, beige desktop PCs with chunky CRT monitors showing green and blue screens, stacks of software boxes and floppy disks. A blank illuminated sign box above the window, a blank poster in the window. Wet cobblestone street reflecting the window light, an old street lamp, a parked 1980s hatchback, a bicycle leaning against the wall. Deep blue evening sky with the last light at the horizon, rooftops and a church tower in the distance. Calm, empty sky in the upper left third for the game title, a calm darker area on the right for a menu. Early 1990s VGA point-and-click adventure game screenshot: pixel art at 320x180 resolution scaled up, limited 256-color palette, clearly visible square pixels, hand-placed dithering in the shading, crisp dark outlines, no anti-aliasing. No text, no lettering, no logos, no user interface.

## L-01 Logo: Ladenschild

- Dateien: `logo-ladenschild.png` (freigestellt, auf den Inhalt zugeschnitten, 850 × 164) und `logo-ladenschild-original.jpg` (1280 × 720)
- Datum: 2026-10-19
- Entwurf: Durchgang `1f1cbc74-6881-6590-98c1-70d6454fb2c8`, Bild 0, Seed 129437009 (Ideogram 4.5, Qualität Low, 16:9, ohne Referenz)
- Endfassung: Durchgang `1f1cbc7f-4036-6670-b94d-e8d1cb28d549`, Bild 1, Seed 1317451242 (Ideogram 4.5, Qualität Medium, Entwurf als Image Reference; Leonardo liefert dabei 1280 × 720)
- Freistellen: Leonardo „Remove Background“, Ausgabe Full, kein Schatten, transparent, Halbtransparenz aus; zugeschnitten mit `png_crop.py` (2 Pixel Rand)
- Status: freigegeben als Logo. Noch nicht aufs Oberflächenraster gebracht.

Prompt der Endfassung:

> Pixel art title logo of a 1990s PC game, designed as an illuminated shop sign, exactly like the reference image. The text reads exactly "DER COMPUTERLADEN": the small word "DER" with thin decorative lines to its left and right, above the large word "COMPUTERLADEN", all capital letters, correct German spelling. A long sign box with a beige plastic frame, the letters glowing warm yellow with orange shading on a dark red sign face, a small pixel-art beige computer monitor icon at the left end of the sign. The sign fills most of the image width. Early 1990s VGA game title screen look, 256 colors, crisp square pixels, hand-placed dithering, no anti-aliasing. Plain flat dark navy blue background, sign centered, nothing else in the image.

## C-01 Cover

- Datei: `c-01-cover.jpg`, 1200 × 1808
- Datum: 2026-10-19
- Durchgang: `1f1cbc55-0b34-6dc0-bc0d-70766ac1fefc`, Bild 0, Seed 1638136522
- Format: 2:3, 4 Bilder, Style Reference C2 (High)
- Status: freigegeben für das Cover. Noch nicht aufs Raster 300 × 450 gebracht.

> A cheerful shopkeeper in his late thirties with dark hair and a moustache, a short-sleeved light blue shirt with a small name badge and a red striped tie, standing proudly behind the counter of a cramped German computer shop in the early 1990s, arms spread wide to present his goods. On the counter a beige desktop PC with a CRT monitor and a dot-matrix printer printing continuous form paper with pale green stripes that curls over the counter edge toward the viewer. Shelves full of colorful software boxes and floppy disks behind him, a cash register with a green glowing display, a skeptical customer couple at the left edge, a cat asleep on top of a monitor. Warm interior light. Keep the top quarter calm and uncluttered for the title logo. Early 1990s VGA point-and-click adventure game screenshot: pixel art at 320x180 resolution scaled up, limited 256-color palette, clearly visible square pixels, hand-placed dithering in the shading, crisp dark outlines, no anti-aliasing. No text, no lettering, no logos, no user interface.

## G-01 Gerät: Organizer 1991 (Spike)

- Datei: `g-01-organizer.jpg`, 1440 × 1440
- Datum: 2026-10-27
- Durchgang: `1f1d1cda-de2f-6870-8a72-225eb21fdb42`, Bild 0, Seed 1515248944
- Format: 1:1 Large, 4 Bilder, Style Reference C2 (High, als Upload `stilanker-c2.jpg`), 78 Token
- Rasterfassung: Hintergrund per Füllung vom Rand freigestellt (OKLab-Abstand unter 0,06), auf 785 × 1010 ab 335/215 zugeschnitten, `rasterize.py --faktor 5`, `cleanup.py` → `src/assets/images/organizer_1991.png`, 157 × 202, 110 Farben. Das LCD-Grün fehlt in der Hauptpalette und wird beige; die Oberfläche malt das LCD darüber.
- Status: nur für den Spike „Taschengerät im Hauptmenü“, nicht freigegeben.

> An open pocket organizer from the early 1990s, a small clamshell palmtop computer, seen straight from the front and slightly from above, perfectly symmetrical, centered, opened flat like a book. Warm light grey plastic housing with rounded corners and a darker grey hinge bar across the middle. The upper lid holds one large, completely blank rectangular LCD screen, plain pale grey-green and empty, inside a thin dark bezel; the screen takes up most of the lid. The lower half holds a compact keyboard with rows of small dark grey rubber keys and a row of small function keys above them. Light from the upper left, a thin highlight along the upper left edges, a soft dark outline around the device. The device fills most of the image. Plain flat dark navy blue background, nothing else in the image. Early 1990s VGA point-and-click adventure game screenshot: pixel art at 320x180 resolution scaled up, limited 256-color palette, clearly visible square pixels, hand-placed dithering in the shading, crisp dark outlines, no anti-aliasing. No text, no lettering, no logos, no user interface.

## G-02 Gehäuse des Communicators: Organizer 1991

- Datei: `g-02-organizer.jpg`, 1440 × 1440
- Datum: 2026-10-27, von Claude über Claude in Chrome erzeugt (Klaus, 2026-10-27)
- Durchgang: `1f1d1eb5-03e3-6590-a9ba-41f57f8c353b`, Bild 2, Seed 211475330
- Format: Lucid Origin, 1:1 Large, 4 Bilder, Style None, Prompt Enhance aus, Fast, Style Reference C2 (High, als Upload `stilanker-c2.jpg`), 78 Token
- Auswahl: Bild 2 von Klaus gewählt; alle vier wirkten eher wie Laptops, Bild 2 hat ein LCD von genau 2 : 1 und ist gerade von vorn.
- Rasterfassung: Original mit `sips` auf 1481 × 1481 gebracht, damit das LCD 576 × 288 wird (192 × 96 bei Faktor 3); Ausschnitt 870 × 810 ab 311/337; Hintergrund per Füllung vom Rand freigestellt (OKLab-Abstand unter 0,06); `rasterize.py --faktor 3` → 290 × 270, LCD bei 50/42. Der Rand war zu breit für den Titel (Gehäuse rund 576 statt 432 Oberflächenpixel): Herausgenommen sind die Spalten 20–43 und 248–271 (blaue Seitenfelder) und die Zeilen 8–35 und 141–156 (Rand über und unter dem LCD), dann auf 216 × 132 ab 14/2 zugeschnitten (Klaus, 2026-10-27, nach Empfehlung). `cleanup.py` (110 → 103 Farben); von Hand eine schriftartige Reihe und ein Zeichen „LS“ am Unterteil mit der Farbe daneben übermalt. Nach der Phasenprüfung: die Blende unter dem LCD (Zeilen 108–111) gespiegelt aus der über dem LCD, Striche in der oberen Lichtkante, dunkle Punkte am Unterteil und helle Zeichen im blauen Schlitz entfernt; der warme Kunststoff in OKLab um 0,12 aufgehellt und etwas entsättigt auf hellere Farben der Hauptpalette (Klaus, 2026-10-27, nach Empfehlung). Ergebnis `src/assets/images/organizer_1991.png`, 216 × 132, LCD bei 12/12, 192 × 96; die Oberfläche malt das LCD in `lcd` darüber.
- Status: freigegeben von Klaus am 2026-10-27 (Abnahme von Phase 4, T026).

> An open pocket organizer from the early 1990s, a small clamshell palmtop computer, seen straight from the front, perfectly symmetrical, centered, opened flat like a book. Warm light grey plastic housing with rounded corners and a darker grey hinge bar across the middle. The upper lid holds one wide, completely blank rectangular LCD screen, exactly twice as wide as it is high, plain flat pale grey-green and empty, inside a thin dark bezel; the screen fills almost the whole width of the lid, with only a narrow plastic border around it and a plain smooth plastic strip above it, without dots, holes or a speaker grille. The lower half holds a compact keyboard with rows of small dark grey rubber keys and a row of small function keys above them. Light from the upper left, a thin highlight along the upper left edges, a soft dark outline around the device. The device fills most of the image. Plain flat dark navy blue background, nothing else in the image. No brand name, no logo on the device. Early 1990s VGA point-and-click adventure game screenshot: pixel art at 320x180 resolution scaled up, limited 256-color palette, clearly visible square pixels, hand-placed dithering in the shading, crisp dark outlines, no anti-aliasing. No text, no lettering, no logos, no user interface.

## T-02 Titelbild: der Laden links, rechts Platz für den Communicator

- Datei: `t-02-titelbild.jpg`, 1920 × 1088
- Datum: 2026-10-27, von Claude über Claude in Chrome erzeugt (Klaus, 2026-10-27)
- Durchgang: `1f1d1ecd-6b0e-6400-8227-2191d7b76803`, Bild 3, Seed 128072448
- Format: Lucid Origin, 16:9 Large, 4 Bilder, Style None, Prompt Enhance aus, Fast, Style Reference C2 (High), 79 Token
- Auswahl: Bild 3 von Klaus gewählt, nach einer Montage aller vier mit Logo und G-02. Der Laden steht links, rechts unten liegt alles unter dem Gerät.
- Rasterfassung: `rasterize.py --groesse 320x180` (Faktor 6, Ausschnitt ab 0/4), `cleanup.py` (212 → 182 Farben); von Hand die schriftartigen Kleckse auf dem Plakat links (x 0–9, y 84–105) und ein Zeichen im Schild über dem Fenster (x 93–102, y 50–55) übermalt; nach der Phasenprüfung das Rauschen auf dem Putz oben links (x 0–149, y 0–25) und dem Pflaster unten links (x 0–99, y 160–179) mit einem Mehrheitsfilter 3 × 3 geglättet. Ergebnis `src/assets/images/title_t02.png`, 320 × 180. `title_t01.png` bleibt im Repo.
- Status: freigegeben von Klaus am 2026-10-27 (Abnahme von Phase 4, T026).

> A small German computer shop on a street corner at dusk in the early 1990s, seen at an angle from the street so that the whole shop front stands in the left third of the image. Old plastered town house with a big shop window glowing warm yellow in the lower left; inside, beige desktop PCs with chunky CRT monitors showing green and blue screens, stacks of software boxes and floppy disks. A blank illuminated sign box above the window, a blank poster in the window. Wet cobblestone street in front reflecting the window light, an old street lamp beside the shop. Deep blue evening sky with the last light at the horizon, rooftops and a church tower in the distance. Calm, empty dark sky in the upper left corner for the game title. The right two thirds of the image below the top quarter stay calm and dark: a plain house wall in deep shadow and an empty dark street, no lights, no windows, no details there. Early 1990s VGA point-and-click adventure game screenshot: pixel art at 320x180 resolution scaled up, limited 256-color palette, clearly visible square pixels, hand-placed dithering in the shading, crisp dark outlines, no anti-aliasing. No text, no lettering, no logos, no user interface.
