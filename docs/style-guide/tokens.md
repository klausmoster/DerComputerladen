# Tokens

Alle Werte des Style-Guides mit Namen. Die Abschnitte nennen sie in `Code-Schrift`, etwa `papier` oder `raster-8`. Maschinenlesbar stehen dieselben Werte in [tokens.json](tokens.json); geändert wird beides zusammen.

## Farben

Thema: Spiel.

| Name | Wert | Verwendung |
|---|---|---|
| `tusche` | `#1d1916` | Konturen, harte Schatten und Text auf `papier`, `endlos-gruen`, `lcd`, `gehaeuse`, `gehaeuse-hell` und `signalgelb` (8:1 bis 16:1); Auswahlbalken auf der Anzeige des Communicators. |
| `nacht` | `#18233b` | Abend- und Nachthimmel, Grund des Titelbilds, dunkle Fenster. Text darauf in `papier` (13:1) oder `signalgelb` (9:1). |
| `nacht-hell` | `#2c3d63` | Zweite Tiefe neben `nacht`: Fassaden im Schatten, Straße bei Nacht, Dither-Partner im Himmel. Text darauf in `papier` (9:1). |
| `gehaeuse-dunkel` | `#6f6654` | Schattenkante von Knöpfen und Leiste (unten, rechts); gedämpfter Text auf `papier` (5:1), in nicht verfügbaren Einträgen auch auf `endlos-gruen`, `signalgelb`, `lcd` und im Auswahlbalken `tusche` (3:1 bis 4,1:1, nur `menue`). |
| `gehaeuse` | `#bdb39a` | Grundfläche von Bedienleiste und Knöpfen: das Beige der PC-Gehäuse um 1990. Text darauf in `tusche` (8:1). |
| `gehaeuse-hell` | `#e4dcc6` | Lichtkante von Knöpfen und Leiste (oben, links). |
| `papier` | `#f5f0e2` | Endlospapier, Zeitung, Menüs, helle Textflächen; Text auf `nacht`, `nacht-hell`, `kassenrot` und `petrol`. |
| `endlos-gruen` | `#cfe2c3` | Querstreifen des Endlospapiers, jede zweite Zeile in Listen und Tabellen auf `papier`. Text darauf in `tusche`. |
| `lcd` | `#b8c4a8` | Grund der Anzeige des Communicators beim Organizer, ein graugrünes LCD. Text darauf in `tusche` (9,6:1), gedämpft in `gehaeuse-dunkel` (3,1:1, nur `menue`); im Auswahlbalken umgekehrt `lcd` auf `tusche`. Nur in der Oberfläche, nie in einem Bild und nicht in der Hauptpalette. |
| `anzeige-grund` | `#0d1716` | Grund der Leuchtanzeige für Datum, Uhrzeit und Kontostand. |
| `anzeige` | `#6ff0cf` | Leuchtziffern auf `anzeige-grund` (13:1). Nur in Anzeigen, nie für Fließtext. |
| `kassenrot` | `#c0392b` | Preise, Sonderangebote, Verluste, Warnungen. Als Text auf `papier` (4,8:1), als Fläche mit Text in `papier`. |
| `signalgelb` | `#f2bf2f` | Überfahren und Auswahl (Fläche unter `tusche`-Text, 10:1), Leuchtschrift, Akzent auf `nacht`. Nie als Text auf hellem Grund. |
| `petrol` | `#1f6f75` | Aktiver Reiter, ausgewählte Zeile, Verweise. Als Text auf `papier` (5,1:1), als Fläche mit Text in `papier`. |
| `holz` | `#8b5a34` | Ladentheke, Regale, Schilderrahmen. Kein Text. |
| `holz-dunkel` | `#57351d` | Schatten im Holz, Kanten von Schildern, Dächer. Kein Text. |

## Schrift

### Schriftdateien

| Familie | Datei | Gewicht |
|---|---|---|
| Ark Pixel 10 | `src/assets/fonts/ark-pixel-10px-proportional-latin.otf` | 400 |
| Ark Pixel 12 | `src/assets/fonts/ark-pixel-12px-proportional-latin.woff2` | 400 |

### Familien

| Name | Schriftliste |
|---|---|
| `display` | `Saira, "Arial Black", sans-serif` |
| `pixel-10` | `"Ark Pixel 10", ui-monospace, monospace` |
| `pixel-12` | `"Ark Pixel 12", ui-monospace, monospace` |
| `matrix` | `Doto, "Courier New", monospace` |
| `werkzeug` | `"Open Sans", system-ui, sans-serif` |

### Schriftstile

| Gruppe | Name | Familie | Größe | Zeile | Gewicht | weitere | Probe | Verwendung |
|---|---|---|---|---|---|---|---|---|
| Titel | `ueberschrift` | `display` | 20px | 1.05 | 800 | fontStyle italic | Jahresbilanz 1991 | Bildschirmtitel und Schlagzeilen. Breite 125 %. |
| Oberfläche | `menue` | `pixel-12` | 12px | 16px | 400 | – | Neues Spiel | Menüpunkte und Knopfbeschriftungen. Ark Pixel 12, nur in 12 Pixeln oder ganzzahligen Vielfachen. |
| Oberfläche | `text` | `pixel-10` | 10px | 14px | 400 | – | Lieferung eingetroffen: 12 Mäuse, 4 Tastaturen. | Fließtext, Dialoge, Hinweise, Tooltips, Tabellen mit ihren Köpfen, Etiketten. Ark Pixel 10, nur in 10 Pixeln oder ganzzahligen Vielfachen. |
| Anzeige und Drucker | `anzeige-ziffern` | `matrix` | 14px | 16px | 700 | – | 12.450,00 DM | Kontostand, Datum und Uhrzeit in der Leuchtanzeige. Die Größe ist noch offen: Bei 14 liegen die Punkte von Doto ungleich, sauber sind 10 und 20. Das klärt der Baustein Anzeige. |
| Anzeige und Drucker | `drucker` | `matrix` | 10px | 12px | 600 | letterSpacing 1px | RECHNUNG NR. 0815 | Nadeldrucker auf Endlospapier: Rechnungen, Lieferscheine, Bilanzen, Kopfzeilen von Menüs; im Titel der Untertitel und die Versionszeile. Mit 1 Pixel Laufweite. Kleiner wird Doto nicht gesetzt. |
| Werkzeuge | `werkzeug-titel` | `werkzeug` | 16px | 22px | 600 | – | Prüfung · 3 Fehler, 1 Warnung | Titel von Bereichen in Werkzeugen wie der Zeitleisten-Werkstatt. Open Sans SemiBold, die eingebaute Schrift von Godot; nur in Werkzeugen, nie im Spiel. |
| Werkzeuge | `werkzeug-text` | `werkzeug` | 14px | 20px | 600 | – | Intel Pentium erscheint · 22.03.1993 · Preis cpu_486 −30 % | Text, Eingabefelder, Listen und Tooltips in Werkzeugen. |
| Werkzeuge | `werkzeug-klein` | `werkzeug` | 12px | 16px | 600 | – | 1985   1986   1987   März 1993 | Beschriftung der Zeitachse und kleine Angaben in Werkzeugen. |

## Abstände

| Name | Wert | Verwendung |
|---|---|---|
| `raster-2` | `2px` | Abstand Symbol zu Beschriftung, Versatz des Pixelschattens. |
| `raster-4` | `4px` | Innenabstand von Leiste und Menüzeilen, Abstand zwischen Knöpfen. |
| `raster-8` | `8px` | Innenabstand von Fenstern, Zeitung und Textknöpfen. |
| `raster-16` | `16px` | Abstand zwischen Bereichen, Rand zum Bildschirmrand im Titel. |

## Ecken

| Name | Wert | Verwendung |
|---|---|---|
| `ecke-0` | `0` | Alles Bedienbare: Knöpfe, Leiste, Fenster, Menüs, Rahmen. |
| `ecke-2` | `2px` | Preisschilder und Aufkleber. |
| `ecke-rund` | `50%` | Lochrand des Endlospapiers, Leuchtpunkte. |

## Schatten und Relief

| Name | Wert | Verwendung |
|---|---|---|
| `relief-erhaben` | `inset 1px 1px 0 #e4dcc6, inset -1px -1px 0 #6f6654` | Knöpfe und Leiste in Ruhe. Licht von oben links. |
| `relief-gedrueckt` | `inset 1px 1px 0 #6f6654, inset -1px -1px 0 #e4dcc6` | Gedrückter oder eingeschalteter Knopf. |
| `pixelschatten` | `2px 2px 0 #1d1916` | Harter Schlagschatten unter Menüs, Fenstern, Zeitung und Aufklebern; dazu unter Text, der direkt auf einem unruhigen oder hellen Bild steht, etwa Logo, Untertitel und Versionszeile im Titel. |

## Bildschirm

Maße in Oberflächenpixeln (640 × 360), bildraster-* in Bildpixeln (320 × 180). Ein Oberflächenpixel ist auf 1080p 3 × 3, auf 1440p 4 × 4 und auf 4K 6 × 6 Bildschirmpixel groß.

| Name | Wert | Verwendung |
|---|---|---|
| `bild-breite` | `640px` | Breite des Oberflächenrasters: jeder Bildschirm, alle Bedienelemente und Texte. |
| `bild-hoehe` | `360px` | Höhe des Oberflächenrasters. |
| `bildraster-breite` | `320px` | Breite des Bildrasters in Bildpixeln: Szenen, Figuren, Gegenstände. |
| `bildraster-hoehe` | `180px` | Höhe des Bildrasters in Bildpixeln. |
| `bildpixel` | `2px` | Kantenlänge eines Bildpixels auf dem Oberflächenraster. Szenenbilder werden genau so vergrößert. |
| `szene-breite` | `624px` | Breite des Szenenbilds im Spielbildschirm, innerhalb des Rahmens: 312 Bildpixel. |
| `szene-hoehe` | `288px` | Höhe des Szenenbilds zwischen oberem Rahmen und Bedienleiste: 144 Bildpixel. |
| `rahmen-breite` | `8px` | Endlospapier-Rahmen oben, links und rechts um die Szene. |
| `leiste-hoehe` | `64px` | Höhe der Bedienleiste am unteren Rand. |
| `geraet-anzeige-breite` | `320px` | Breite der Anzeige des Communicators, für jedes Gehäuse gleich: Platz für die Liste der Spielstände. |
| `geraet-anzeige-hoehe` | `160px` | Höhe der Anzeige des Communicators: 8 Zeilen zu 20, ohne Rest. |
