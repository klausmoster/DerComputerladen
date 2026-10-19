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
