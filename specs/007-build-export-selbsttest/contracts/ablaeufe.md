# Vertrag: Abläufe des Selbsttests

Welche Schritte der Selbsttest macht und was er je Schritt erwartet (Spec FR-006, FR-011, FR-012).
Felder und Zustände in [data-model.md](../data-model.md), Entscheidungen in [research.md](../research.md)
R5 bis R7 und R16. Wortlaute kommen zur Laufzeit aus `TitleTexts`, nicht aus dem Selbsttest; ändert
sich ein Text, bleibt der Ablauf gültig (R5).

Die Kennungen sind fest; die Nummern `nn` dürfen Lücken haben, damit ein Schritt dazukommen kann, ohne
dass sich alle Kennungen danach ändern. Ein Schritt hat ein Foto; „nicht vergleichbar“ steht dabei, wo
das Bild von der Bildrate abhängt (R7); diese Schritte nennt der Absatz unter ihrer Tabelle.

Form der Spalte „Erwartet“ (Review CHK031, CHK032): Seiten und Kopfzeilen in Versalien, Menüeinträge
in Anführungszeichen, Grade und Spielstände ohne, etwa `Menü steht: SCHWIERIGKEIT, Mittel`. Kein
Verweis auf Spec oder Plan im Text; der Text landet so in `erwartet:` des Protokolls.

## Gemeinsame Prüfungen

- **Menü steht:** die genannte Seite ist die sichtbare Seite des Communicators, der Communicator steht
  in Endlage (`is_in()`, keine Fahrt), die genannte Zeile hat den Fokus, der Hinweis zeigt den Text
  dieser Zeile.
- **Spielbildschirm steht:** aktuelle Szene ist der Spielbildschirm, „Zum Hauptmenü“ hat den Fokus,
  der Hinweis nennt das laufende Spiel.
- **Spielstände:** die Spielstände im Ordner des Selbsttests, als Liste der Namen, etwa
  `Spielstände: Spiel 1` oder `Spielstände: keine`.

## titel

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `start` | keine | Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine |
| 02 | `nicht_verfuegbar` | Maus über „Weiterspielen“ | Zeile gewählt, Hinweis „Noch kein Spiel angefangen.“; nichts ausgelöst |
| 03 | `beenden_da` | Maus über „Beenden“ | Zeile gewählt, verfügbar, Hinweis von „Beenden“; nicht ausgelöst |

## neues_spiel

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `gradwahl` | Maus über „Neues Spiel“, Enter | Menü steht: SCHWIERIGKEIT, Mittel |
| 02 | `zurueck_esc` | Esc | Menü steht: HAUPTMENÜ, „Neues Spiel“ |
| 03 | `gradwahl_klick` | Linksklick auf „Neues Spiel“ | Menü steht: SCHWIERIGKEIT, Mittel |
| 04 | `grad_mittel` | Enter | Communicator hinausgefahren; Spielbildschirm steht; Spielstände: Spiel 1 |
| 05 | `zum_hauptmenue` | Linksklick auf „Zum Hauptmenü“ | Titel neu, Menü steht: HAUPTMENÜ, „Weiterspielen“ mit Hinweis zu Spiel 1, Mittel; Spielstände: Spiel 1 |

## laden: Spiel laden (baut auf `neues_spiel`)

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `weiterspielen` | Enter auf „Weiterspielen“ | Spielbildschirm steht mit Spiel 1 |
| 02 | `zurueck` | Enter auf „Zum Hauptmenü“ | Menü steht: HAUPTMENÜ, „Weiterspielen“ |
| 03 | `liste` | Pfeil runter bis „Spiel laden“, Enter | Menü steht: SPIELSTÄNDE, Spiel 1 mit Grad und Spieldatum |
| 04 | `zeile` | Linksklick auf Zeile Spiel 1 | Spielbildschirm steht mit Spiel 1 |
| 05 | `zurueck_2` | Linksklick auf „Zum Hauptmenü“ | Menü steht: HAUPTMENÜ, „Weiterspielen“ |

## loeschen (baut auf `laden`)

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `liste` | Linksklick auf „Spiel laden“ | Menü steht: SPIELSTÄNDE, Spiel 1 |
| 02 | `loeschmodus` | Linksklick auf „Löschen …“ | Kopfzeile WELCHES LÖSCHEN? |
| 03 | `rueckfrage` | Linksklick auf Spiel 1 | Menü steht: LÖSCHEN?, „Abbrechen“ |
| 04 | `abbrechen` | Enter | Menü steht: SPIELSTÄNDE; Spielstände: Spiel 1 |
| 05 | `rueckfrage_2` | Linksklick auf „Löschen …“, Linksklick auf Spiel 1 | Menü steht: LÖSCHEN?, „Abbrechen“ |
| 06 | `loeschen` | Pfeil runter, Enter | Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine |

## easter_egg

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `auswahl` | Pfeil runter bis „Spiel laden“ | Menü steht: HAUPTMENÜ, „Spiel laden“ |
| 02 | `falsche_folge` | Linksklick auf Gehäusetaste 1, 0, 2 | Seite Invaders nicht sichtbar, Menü steht: HAUPTMENÜ, „Spiel laden“ |
| 03 | `start` | Linksklick auf Gehäusetaste 0, 1, 2 | Seite Invaders sichtbar und aktiv, Hinweis aus |
| 04 | `spielen` | Pfeil rechts halten 0,5 s, Leertaste | Kanone weiter rechts als beim Start, ein Schuss unterwegs oder ein Treffer gezählt |
| 05 | `ende_esc` | Esc | Menü steht: HAUPTMENÜ, „Spiel laden“ mit Hinweis; Spielstände: keine |

Fotos von 03 und 04 sind nicht vergleichbar: Das versteckte Spiel rechnet nach Zeit (R7).

## bedienung

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `pfeile` | Pfeil runter, Pfeil hoch, Pfeil hoch | Auswahl wandert und läuft am Anfang ans Ende um |
| 02 | `tab` | Tab, Umschalt+Tab | Auswahl eine Zeile weiter und zurück |
| 03 | `rechtsklick` | Rechtsklick auf „Neues Spiel“ | Zeile gewählt, nichts ausgelöst |
| 04 | `leertaste` | Leertaste | Menü steht: SCHWIERIGKEIT, Mittel |
| 05 | `zurueck_klick` | Linksklick auf „Zurück“ | Menü steht: HAUPTMENÜ, „Neues Spiel“ |
| 06 | `mausrad` | Vorbereitung: sieben Spielstände; Linksklick auf „Spiel laden“, Mausrad runter | Liste rollt um eine ganze Zeile, Rollmarke oben sichtbar |

Für Schritt 06 legt der Selbsttest die sieben Spielstände über `SaveStore` an, mit fester Uhrzeit und
festem Seed, und räumt sie danach weg; im Protokoll `eingaben: Vorbereitung, …` (Review CHK001).

## fenster

Ohne Vollbild (Spec, Clarify). Prüft Zahlen, kein Spielbild; die Fotos zeigen dennoch das Raster.

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `start` | keine | Fenster 640 × 360 mal dem größten ganzzahligen Faktor, der auf den Bildschirm passt; mittig im nutzbaren Bereich, auf 1 Pixel genau |
| 02 | `faktor_1` | Fenster auf 640 × 360 | Bild 1:1, ohne Rand |
| 03 | `krumm` | Fenster auf 1317 × 741 | Bild Faktor 2, mittig, schwarzer Rand ringsum, ganze Pixel |
| 04 | `zurueck` | Fenster auf die Startgröße | Fenster in der Startgröße, Bild mit dem Startfaktor, ohne Rand |

Die Fenstergröße stellt der Selbsttest über das Fenster ein, nicht über Eingaben: Größe ziehen ist
Sache des Betriebssystems (Spec FR-004); im Protokoll `eingaben: Fenster, …`.

## titel_echtzeit

Name „Titel in Echtzeit“. Dieselben Schritte wie `titel`, ohne Zeitraffer (`Engine.time_scale = 1`), mit eigenen Kennungen
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
