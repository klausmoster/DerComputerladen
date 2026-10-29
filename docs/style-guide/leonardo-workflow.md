# Leonardo-Workflow

Szenen, Figuren und das Cover entstehen mit Leonardo.ai. Claude schreibt Prompt, Modell und Format, erzeugt wird im Leonardo-Konto des Projekts. Freigegebene Bilder werden aufs Bildraster gebracht, nachbearbeitet und mit ihrem Prompt im Repo abgelegt.

## Modelle und Einstellungen

Stand Oktober 2026:

| Zweck | Modell | Warum |
|---|---|---|
| Szenen, Cover, Figuren | Lucid Origin | hat den Stilanker erzeugt, folgt dem Prompt genau, nimmt eine Stil-Referenz |
| Varianten einer freigegebenen Figur oder Szene | FLUX.1 Kontext | nimmt ein Bild als Vorlage und ändert nur, was der Text verlangt |

Einstellungen für Lucid Origin: Prompt Enhance aus, Style None, Generation Mode Fast, größte Bildgröße (16:9: 1920 × 1088, 2:3: 1200 × 1808). Jeder Durchgang erzeugt zwei bis vier Bilder. Gewählt wird das Bild, das dem Stilanker am nächsten kommt, nicht das spektakulärste.

## Stilblock

Steht unverändert am Ende jedes Prompts:

> Early 1990s VGA point-and-click adventure game screenshot: pixel art at 320x180 resolution scaled up, limited 256-color palette, clearly visible square pixels, hand-placed dithering in the shading, crisp dark outlines, no anti-aliasing. No text, no lettering, no logos, no user interface.

Lucid Origin hat kein Feld für einen Negativ-Prompt. Was nicht ins Bild soll, steht als „no …“ im Stilblock.

## Stimmigkeit

- **Stilanker:** C2 aus der Stilprobe vom 19.10.2026 läuft bei jeder Erzeugung als Style Reference mit.
- **Figuren:** Jede Figur bekommt zuerst ein Figurenblatt: von vorn, von der Seite, von hinten, dazu drei Mienen. Weitere Bilder der Figur entstehen mit dem Figurenblatt als zusätzlicher Referenz oder über FLUX.1 Kontext.
- Ab etwa 15 freigegebenen Bildern wird in Leonardo ein eigener Stil trainiert. Welche Basismodelle das Training anbietet, zeigt das Konto.
- Seed, Modell und Prompt jedes freigegebenen Bildes werden notiert.

## Formate

| Bild | Seitenverhältnis in Leonardo | Endgröße in Bildpixeln |
|---|---|---|
| Vollbild: Titel, Zwischenbild | 16:9 | 320 × 180 |
| Spielszene im Rahmen | 16:9, danach zugeschnitten | 312 × 144 |
| Porträt in der Leiste | 1:1 | 24 × 28 |
| Figur in einer Szene | aus dem Figurenblatt | etwa 60 hoch |
| Cover | 2:3 hochkant | 300 × 450, für Druck und Shop ganzzahlig hochskaliert |
| Gehäuse des Communicators | 1:1, freigestellt | LCD genau 160 × 80, das Gehäuse drumherum nach Bild; im Spiel ×2 |

## Nachbearbeitung

1. Hände, Gesichter, Geräte und Schriftreste prüfen; Fehler übermalen oder neu erzeugen.
2. Aufs Bildraster bringen: die Pixelgröße im Bild bestimmen und mit Nearest Neighbor auf die Endgröße verkleinern, sodass aus jedem gemalten Pixel genau ein Bildpixel wird. Sind die gemalten Pixel ungleich groß, wie bei T-01 und beim Logo gemessen, wird stattdessen per Flächenmittel auf die Endgröße verkleinert; Schritt 3 rechnet die Mischfarben auf die Palette zurück.
3. Auf die Hauptpalette rechnen, ohne zusätzliches Dithering.
4. Von Hand aufräumen, etwa in Aseprite: Konturen schließen, verirrte Einzelpixel und Farbreste entfernen.
5. Als indiziertes PNG in Endgröße speichern. Import in Godot: Filter Nearest, Mipmaps aus, verlustfrei.
6. Prompt, Modell, Seed und Datum im Prompt-Log des Repos eintragen.

## Hauptpalette

Alle Szenen teilen sich eine Palette aus 256 Farben. Sie entsteht aus dem Stilanker und den ersten freigegebenen Bildern (Titelbild T-01 und Cover C-01): 240 Farben per Median-Cut, dazu 15 Oberflächenfarben dieses Guides und eine Farbe für Transparenz. Danach wird sie eingefroren, und jede weitere Szene wird auf sie gerechnet. Die 16. Oberflächenfarbe `lcd` gehört nicht hinein: Sie kommt in keinem Bild vor, die Oberfläche malt sie über das Gehäuse des Communicators.

## Prompts

Jeder Prompt bekommt den Stilblock angehängt und läuft mit dem Stilanker als Style Reference.

### S-C Stilanker: der Ladenbesitzer hinter der Theke

Lucid Origin, 16:9. Aus diesem Durchgang stammt C2.

> Interior of a small, cramped German computer shop in the early 1990s. The shopkeeper, a man in his late thirties with a moustache, a short-sleeved light blue shirt and a red tie, stands behind a wooden counter and leans forward with a friendly, slightly sly smile. On the counter a beige desktop PC with a CRT monitor, a dot-matrix printer with continuous form paper with pale green stripes, and a cash register with a green glowing display. Behind him, shelves full of colorful software boxes and floppy disks. Warm interior light from the upper left. Wide shot.

### F-01 Figurenblatt: der Ladenbesitzer

Lucid Origin, 16:9.

> Character reference sheet of one shopkeeper on a plain light grey background: front view, side view and back view standing, plus three close-up faces with a friendly smile, a skeptical raised eyebrow and a shocked look. A man in his late thirties with dark hair, a moustache, a short-sleeved light blue shirt with a small name badge, a red striped tie and dark trousers. Same character and same scale in every view, evenly spaced.

### T-01 Titelbild: der Laden in der Abenddämmerung

Lucid Origin, 16:9.

> A small German computer shop on a street corner at dusk in the early 1990s. Old plastered town house with a big shop window glowing warm yellow; inside, beige desktop PCs with chunky CRT monitors showing green and blue screens, stacks of software boxes and floppy disks. A blank illuminated sign box above the window, a blank poster in the window. Wet cobblestone street reflecting the window light, an old street lamp, a parked 1980s hatchback, a bicycle leaning against the wall. Deep blue evening sky with the last light at the horizon, rooftops and a church tower in the distance. Calm, empty sky in the upper left third for the game title, a calm darker area on the right for a menu.

### G-01 Gerät: Organizer 1991 (Spike, nicht freigegeben)

Lucid Origin, 1:1. Aus dem Spike „Taschengerät im Hauptmenü“ vom 27.10.2026; das erste Bild war brauchbar. Für das Gerät im Spiel braucht das LCD ein Seitenverhältnis von 2 : 1 (Inhalt 320 × 160), dann gehört „a wide LCD screen, twice as wide as high“ in den Prompt.

> An open pocket organizer from the early 1990s, a small clamshell palmtop computer, seen straight from the front and slightly from above, perfectly symmetrical, centered, opened flat like a book. Warm light grey plastic housing with rounded corners and a darker grey hinge bar across the middle. The upper lid holds one large, completely blank rectangular LCD screen, plain pale grey-green and empty, inside a thin dark bezel; the screen takes up most of the lid. The lower half holds a compact keyboard with rows of small dark grey rubber keys and a row of small function keys above them. Light from the upper left, a thin highlight along the upper left edges, a soft dark outline around the device. The device fills most of the image. Plain flat dark navy blue background, nothing else in the image.

### G-02 Gehäuse des Communicators: Organizer 1991 (abgelöst durch G-03)

Lucid Origin, 1:1, Stilanker C2 als Style Reference (High). Für Feature 005, Nachfolger von G-01. Aus Durchgang `1f1d1eb5…` ist Bild 2 freigegeben (Seed 211475330); alle vier Bilder wirkten eher wie Laptops mit breitem Rand, beim Rastern wurden die blauen Seitenfelder und Teile des Rands über und unter dem LCD herausgenommen, unter dem Scharnier auch Zeilen zwischen Funktionstasten und Tastatur (Prompt-Log im Repo). Das LCD muss genau doppelt so breit wie hoch sein, denn die Anzeige ist 320 × 160 Oberflächenpixel; über dem LCD keine Punkte oder Lautsprecherlöcher, die bei G-01 als Sprenkel auffielen. Von vorn statt leicht von oben, damit das LCD ein Rechteck bleibt. Beim Rastern wird der Faktor so gewählt, dass das LCD 160 × 80 Bildpixel hat; seine Fläche übermalt die Oberfläche mit `lcd`.

> An open pocket organizer from the early 1990s, a small clamshell palmtop computer, seen straight from the front, perfectly symmetrical, centered, opened flat like a book. Warm light grey plastic housing with rounded corners and a darker grey hinge bar across the middle. The upper lid holds one wide, completely blank rectangular LCD screen, exactly twice as wide as it is high, plain flat pale grey-green and empty, inside a thin dark bezel; the screen fills almost the whole width of the lid, with only a narrow plastic border around it and a plain smooth plastic strip above it, without dots, holes or a speaker grille. The lower half holds a compact keyboard with rows of small dark grey rubber keys and a row of small function keys above them. Light from the upper left, a thin highlight along the upper left edges, a soft dark outline around the device. The device fills most of the image. Plain flat dark navy blue background, nothing else in the image. No brand name, no logo on the device.

### G-03 Gehäuse des Communicators: elektronisches Notizbuch nach dem Olivetti D2000

Lucid Origin, 1:1, Stilanker C2 als Style Reference (High). Für Feature 005, Abnahme Phase 5: Bei G-02 wirkte die Tastatur nach dem Zuschneiden seltsam (Klaus, 2026-10-27). Vorbild in Form und Tastatur ist der Olivetti D2000 von 1990: Klappgehäuse, Scharnier als dicke Walze, Schreibmaschinentastatur mit hellen Tasten, darüber eine Reihe mintgrüner Funktionstasten und eine rote Taste. Beschrieben wird nur in Worten, ohne Foto als Bildvorlage, damit kein Logo ins Bild kommt. Das Gehäuse bleibt hell wie die Geräte im Stilanker, nicht dunkelgrau wie das Vorbild. Das LCD ist genau 2 : 1, beim Rastern 160 × 80 Bildpixel. Aus Durchgang `1f1d2078…` ist Bild 2 freigegeben (Seed 1140053864); es löst G-02 ab. Beim Rastern wurde der breite dunkle Rahmen ums LCD schmaler gemacht, Zeilen zwischen Deckel, Scharnier und Tastatur herausgenommen und die Zeichen auf den Tasten übermalt (Prompt-Log im Repo).

> An open electronic notebook organizer from 1990, a small clamshell pocket computer, seen straight from the front, perfectly symmetrical, centered, opened flat. Warm light grey plastic housing with rounded corners. A thick round cylindrical hinge bar runs across the whole width between the lid and the base. The upper lid holds one wide, completely blank rectangular LCD screen, exactly twice as wide as it is high, plain flat pale grey-green and empty, inside a thin dark bezel; the screen fills almost the whole width of the lid, with only a narrow plastic border around it, without dots, holes or a speaker grille. The lower half holds a full typewriter keyboard set into a slightly darker grey panel: five even rows of small off-white rectangular plastic keys with crisp dark outlines, a long space bar in the bottom row and four arrow keys at the bottom right; directly below the hinge one row of eight small mint green function keys and one small red key at the right end. Light from the upper left, a thin highlight along the upper left edges, a soft dark outline around the device. The device fills most of the image. Plain flat dark navy blue background, nothing else in the image. No brand name, no logo, no lettering on the device or the keys.

### T-02 Titelbild: der Laden links, rechts Platz für den Communicator

Lucid Origin, 16:9, Stilanker C2 als Style Reference (High). Für Feature 005: Der Communicator steht rechts unten und verdeckt dort alles; der Laden rückt deshalb ins linke Drittel. Aus Durchgang `1f1d1ecd…` ist Bild 3 freigegeben (Seed 128072448).

> A small German computer shop on a street corner at dusk in the early 1990s, seen at an angle from the street so that the whole shop front stands in the left third of the image. Old plastered town house with a big shop window glowing warm yellow in the lower left; inside, beige desktop PCs with chunky CRT monitors showing green and blue screens, stacks of software boxes and floppy disks. A blank illuminated sign box above the window, a blank poster in the window. Wet cobblestone street in front reflecting the window light, an old street lamp beside the shop. Deep blue evening sky with the last light at the horizon, rooftops and a church tower in the distance. Calm, empty dark sky in the upper left corner for the game title. The right two thirds of the image below the top quarter stay calm and dark: a plain house wall in deep shadow and an empty dark street, no lights, no windows, no details there.

### C-01 Cover: der Ladenbesitzer

Lucid Origin, 2:3 hochkant.

> A cheerful shopkeeper in his late thirties with dark hair and a moustache, a short-sleeved light blue shirt with a small name badge and a red striped tie, standing proudly behind the counter of a cramped German computer shop in the early 1990s, arms spread wide to present his goods. On the counter a beige desktop PC with a CRT monitor and a dot-matrix printer printing continuous form paper with pale green stripes that curls over the counter edge toward the viewer. Shelves full of colorful software boxes and floppy disks behind him, a cash register with a green glowing display, a skeptical customer couple at the left edge, a cat asleep on top of a monitor. Warm interior light. Keep the top quarter calm and uncluttered for the title logo.
