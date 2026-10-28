# Vertrag: Abläufe des Selbsttests

Welche Schritte der Selbsttest macht und was er je Schritt erwartet (Spec FR-006, FR-011, FR-012).
Felder und Zustände in [data-model.md](../data-model.md), Entscheidungen in [research.md](../research.md)
R5 bis R7 und R16. Wortlaute kommen zur Laufzeit aus `TitleTexts`, nicht aus dem Selbsttest; ändert
sich ein Text, bleibt der Ablauf gültig (R5).

Die Kennungen sind fest; die Nummern `nn` dürfen Lücken haben, damit ein Schritt dazukommen kann, ohne
dass sich alle Kennungen danach ändern. Ein Schritt hat ein Foto; „nicht vergleichbar“ steht dabei, wo
das Bild von der Bildrate abhängt (R7).

## Gemeinsame Prüfungen

- **Menü steht:** die genannte Seite ist die sichtbare Seite des Communicators, der Communicator steht
  in Endlage (`is_in()`, keine Fahrt), die genannte Zeile hat den Fokus, der Hinweis zeigt den Text
  dieser Zeile.
- **Spielbildschirm steht:** aktuelle Szene ist der Spielbildschirm, „Zum Hauptmenü“ hat den Fokus,
  der Hinweis nennt das laufende Spiel.
- **Ordner:** die Spielstände im Ordner des Selbsttests, als Liste der Nummern.

## titel

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `start` | keine | Menü steht: HAUPTMENÜ, „Neues Spiel“; Ordner leer |
| 02 | `nicht_verfuegbar` | Maus über „Weiterspielen“ | Zeile gewählt, Hinweis „Noch kein Spiel angefangen.“; nichts ausgelöst |
| 03 | `beenden_da` | Maus über „Beenden“ | Zeile gewählt, verfügbar, Hinweis von „Beenden“; nicht ausgelöst (FR-012) |

## neues_spiel

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `gradwahl` | Maus über „Neues Spiel“, Taste Enter | Menü steht: SCHWIERIGKEIT, „Mittel“ |
| 02 | `zurueck_esc` | Taste Esc | Menü steht: HAUPTMENÜ, „Neues Spiel“ |
| 03 | `gradwahl_klick` | Linksklick auf „Neues Spiel“ | Menü steht: SCHWIERIGKEIT, „Mittel“ |
| 04 | `grad_mittel` | Taste Enter | Communicator fährt hinaus; Spielbildschirm steht; Ordner: 1 |
| 05 | `zum_hauptmenue` | Linksklick auf „Zum Hauptmenü“ | Titel neu, Menü steht: HAUPTMENÜ, „Weiterspielen“ mit Hinweis zu Spiel 1, Mittel; Ordner: 1 |

## laden (baut auf `neues_spiel`)

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `weiterspielen` | Taste Enter auf „Weiterspielen“ | Spielbildschirm steht mit Spiel 1 |
| 02 | `zurueck` | Taste Enter auf „Zum Hauptmenü“ | Menü steht: HAUPTMENÜ, „Weiterspielen“ |
| 03 | `liste` | Pfeil runter bis „Spiel laden“, Taste Enter | Menü steht: SPIELSTÄNDE, Zeile Spiel 1 mit Grad und Spieldatum |
| 04 | `zeile` | Linksklick auf Zeile Spiel 1 | Spielbildschirm steht mit Spiel 1 |
| 05 | `zurueck_2` | Linksklick auf „Zum Hauptmenü“ | Menü steht: HAUPTMENÜ, „Weiterspielen“ |

## loeschen (baut auf `laden`)

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `liste` | Linksklick auf „Spiel laden“ | Menü steht: SPIELSTÄNDE, Spiel 1 gewählt |
| 02 | `loeschmodus` | Linksklick auf „Löschen …“ | Kopfzeile WELCHES LÖSCHEN? |
| 03 | `rueckfrage` | Linksklick auf Zeile Spiel 1 | Menü steht: LÖSCHEN?, „Abbrechen“ |
| 04 | `abbrechen` | Taste Enter | Menü steht: SPIELSTÄNDE; Ordner: 1 |
| 05 | `rueckfrage_2` | Linksklick auf „Löschen …“, Linksklick auf Spiel 1 | Menü steht: LÖSCHEN?, „Abbrechen“ |
| 06 | `loeschen` | Pfeil runter, Taste Enter | Menü steht: HAUPTMENÜ, „Neues Spiel“; Ordner leer |

## easter_egg

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `auswahl` | Pfeil runter bis „Spiel laden“ | Menü steht: HAUPTMENÜ, „Spiel laden“ |
| 02 | `falsche_folge` | Linksklick auf Gehäusetaste 1, 0, 2 | Spiel nicht zu sehen, Menü steht wie in 01 |
| 03 | `start` | Linksklick auf Gehäusetaste 0, 1, 2 | Seite Invaders sichtbar und aktiv, Hinweis aus; Foto nicht vergleichbar (R7) |
| 04 | `spielen` | Pfeil rechts halten 0,5 s, Leertaste | Kanone weiter rechts als in 03, ein Schuss unterwegs oder ein Treffer gezählt; Foto nicht vergleichbar |
| 05 | `ende_esc` | Taste Esc | Menü steht: HAUPTMENÜ, „Spiel laden“ mit Hinweis; Ordner leer |

## bedienung

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `pfeile` | Pfeil runter, Pfeil hoch, Pfeil hoch | Auswahl wandert und läuft am Anfang ans Ende um |
| 02 | `tab` | Tab, Shift+Tab | Auswahl eine Zeile weiter und zurück |
| 03 | `rechtsklick` | Rechtsklick auf „Neues Spiel“ | Zeile gewählt, nichts ausgelöst |
| 04 | `leertaste` | Leertaste | Menü steht: SCHWIERIGKEIT, „Mittel“ |
| 05 | `zurueck_klick` | Linksklick auf „Zurück“ | Menü steht: HAUPTMENÜ, „Neues Spiel“ |
| 06 | `mausrad` | Ordner mit sieben erfundenen Spielständen, Liste öffnen, Mausrad runter | Liste rollt um eine ganze Zeile, Rollmarke oben sichtbar |

Für Schritt 06 legt der Selbsttest die sieben Spielstände über `SaveStore` an, mit fester Uhrzeit und
festem Seed, und räumt sie danach weg.

## fenster

Ohne Vollbild (Spec, Clarify). Prüft Zahlen, kein Spielbild; die Fotos zeigen dennoch das Raster.

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `start` | keine | Fenstergröße = 640 × 360 × `best_factor()` für den Bildschirm des Fensters; Fenster mittig im nutzbaren Bereich (± 1 Pixel) |
| 02 | `faktor_1` | Fenster auf 640 × 360 | Bild 1:1, ohne Rand |
| 03 | `krumm` | Fenster auf 2 × 640 + 37 mal 2 × 360 + 21 | Bild Faktor 2, mittig, schwarzer Rand ringsum, ganze Pixel |
| 04 | `zurueck` | Fenster auf die Größe aus 01 | wie 01 |

Die Fenstergröße stellt der Selbsttest über das Fenster ein, nicht über Eingaben: Größe ziehen ist
Sache des Betriebssystems (Spec, Assumptions).

## titel_echtzeit

Dieselben Schritte wie `titel`, ohne Zeitraffer (`Engine.time_scale = 1`), mit eigenen Kennungen
`titel_echtzeit.01_start` usw. Die Fotos müssen den Fotos von `titel` gleichen; der Vergleich zeigt
es. Läuft als letzter Ablauf.

## Zeitraffer

Alle Abläufe außer `titel_echtzeit` und `fenster` laufen mit `Engine.time_scale = 8` (R24).
Höchstzeiten und das Halten von Tasten zählen in echter Zeit.

## Szenarien

Rahmen ohne Inhalt (Spec FR-011a, R27). Ein späteres Feature legt ein Szenario als Skript unter
`src/tools/selbsttest/szenarien/` an und trägt es in die Liste des Läufers ein; die Tabelle dazu hat
die Spalten Spieldatum, Art (Entscheidung oder Prüfpunkt), Eingabe, Erwartet.

## Neue Abläufe

Bringt ein Feature eine Seite, einen Weg oder eine Eingabe, bekommt es einen Ablauf oder Schritte in
einem vorhandenen (Story 5). Ein neuer Ablauf beginnt beim frischen Titel; ein Schritt nennt Eingabe und
erwarteten Zustand so, wie diese Tabellen es tun.
