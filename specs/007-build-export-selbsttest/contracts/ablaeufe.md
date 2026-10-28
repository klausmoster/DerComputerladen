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
- **Verfügbarkeit:** Ist die gewählte Zeile nicht verfügbar, steht hinter ihr „nicht verfügbar“, auch
  in `gefunden:`; „verfügbar“ steht nur dort, wo ein Schritt es ausdrücklich erwartet.
- **Zeile mit Spielstand:** in der Liste mit Grad und Spieldatum, etwa `Spiel 1 mit Mittel, 01.01.1985`,
  in `erwartet:` wie in `gefunden:`; hinter `Spielstände:` stehen nur die Namen.
- **Eingaben** nennen ihr Ziel, auch Tasten auf einer vorgewählten Zeile, etwa „Enter auf Mittel“.
  Ohne Ziel stehen nur: Esc und die Tasten in Invaders, die auf die ganze Seite wirken; Tasten, deren
  Weg die Erwartung nennt („Auswahl wandert: …“); eine Taste direkt nach einer Eingabe, die das Ziel
  schon nennt („Maus über „Neues Spiel“, Enter“). Gehäusetasten heißen links, Mitte, rechts.
- **Beschreibung** eines Schritts: beginnt mit der Eingabe und sagt, was sie bewirkt, etwa „Enter auf
  „Neues Spiel“ öffnet die Gradwahl“; ohne Eingabe, oder wenn das Fenster gestellt wird, sagt sie das
  erwartete Ergebnis.
- **Spielstände:** die Spielstände im Ordner des Selbsttests, als Liste der Namen, etwa
  `Spielstände: Spiel 1` oder `Spielstände: keine`.

## titel

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `start` | keine | Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine |
| 02 | `nicht_verfuegbar` | Maus über „Weiterspielen“ | Menü steht: HAUPTMENÜ, „Weiterspielen“, nicht verfügbar, Hinweis „Noch kein Spiel angefangen.“; nichts ausgelöst |
| 03 | `beenden_da` | Maus über „Beenden“ | Menü steht: HAUPTMENÜ, „Beenden“, verfügbar, Hinweis „Laden abschließen und zurück zum Desktop.“; nichts ausgelöst |

## neues_spiel

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `gradwahl` | Maus über „Neues Spiel“, Enter | Menü steht: SCHWIERIGKEIT, Mittel |
| 02 | `zurueck_esc` | Esc | Menü steht: HAUPTMENÜ, „Neues Spiel“ |
| 03 | `gradwahl_klick` | Linksklick auf „Neues Spiel“ | Menü steht: SCHWIERIGKEIT, Mittel |
| 04 | `grad_mittel` | Enter auf Mittel | Communicator hinausgefahren; Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt ins Hauptmenü.“; Spielstände: Spiel 1 |
| 05 | `zum_hauptmenue` | Linksklick auf „Zum Hauptmenü“ | Titel neu, Menü steht: HAUPTMENÜ, „Weiterspielen“, verfügbar, Hinweis „Weiter mit Spiel 1, Mittel, am 01.01.1985.“; Spielstände: Spiel 1 |

## laden (baut auf `neues_spiel`)

Name „Spiel laden“.

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `weiterspielen` | Enter auf „Weiterspielen“ | Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt ins Hauptmenü.“ |
| 02 | `zurueck` | Enter auf „Zum Hauptmenü“ | Menü steht: HAUPTMENÜ, „Weiterspielen“ |
| 03 | `liste` | Pfeil runter bis „Spiel laden“, Enter | Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985 |
| 04 | `zeile` | Linksklick auf Spiel 1 | Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt ins Hauptmenü.“ |
| 05 | `zurueck_2` | Linksklick auf „Zum Hauptmenü“ | Menü steht: HAUPTMENÜ, „Weiterspielen“ |

## loeschen (baut auf `laden`)

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `liste` | Linksklick auf „Spiel laden“ | Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985 |
| 02 | `loeschmodus` | Linksklick auf „Löschen …“ | Menü steht: WELCHES LÖSCHEN?, „Löschen …“, nicht verfügbar |
| 03 | `rueckfrage` | Linksklick auf Spiel 1 | Menü steht: LÖSCHEN?, „Abbrechen“ |
| 04 | `abbrechen` | Enter auf „Abbrechen“ | Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985; Spielstände: Spiel 1 |
| 05 | `rueckfrage_2` | Linksklick auf „Löschen …“, Linksklick auf Spiel 1 | Menü steht: LÖSCHEN?, „Abbrechen“ |
| 06 | `loeschen` | Pfeil runter bis „Spiel 1 löschen“, Enter | Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine |

## easter_egg

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `auswahl` | Pfeil runter bis „Spiel laden“ | Menü steht: HAUPTMENÜ, „Spiel laden“, nicht verfügbar |
| 02 | `falsche_folge` | Linksklick auf Gehäusetasten Mitte, links, rechts | Seite Invaders nicht sichtbar, Menü steht: HAUPTMENÜ, „Spiel laden“, nicht verfügbar |
| 03 | `start` | Linksklick auf Gehäusetasten links, Mitte, rechts | Seite Invaders sichtbar und aktiv, Hinweis aus |
| 04 | `spielen` | Pfeil rechts halten 0,5 s, Leertaste | Kanone weiter rechts als beim Start; ein Schuss unterwegs oder ein Treffer gezählt |
| 05 | `ende_esc` | Esc | Menü steht: HAUPTMENÜ, „Spiel laden“, nicht verfügbar, Hinweis „Noch keine Spielstände.“; Spielstände: keine |

Fotos von 03 und 04 sind nicht vergleichbar: Das versteckte Spiel rechnet nach Zeit (R7).

## bedienung

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `pfeile` | Pfeil runter, Pfeil hoch, Pfeil hoch, Pfeil hoch | Auswahl wandert: „Spiel laden“, „Neues Spiel“, „Weiterspielen“, „Beenden“; Menü steht: HAUPTMENÜ, „Beenden“ |
| 02 | `tab` | Tab, Umschalt+Tab | Auswahl wandert: „Weiterspielen“, „Beenden“; Menü steht: HAUPTMENÜ, „Beenden“ |
| 03 | `rechtsklick` | Rechtsklick auf „Neues Spiel“ | Menü steht: HAUPTMENÜ, „Neues Spiel“; nichts ausgelöst |
| 04 | `leertaste` | Leertaste auf „Neues Spiel“ | Menü steht: SCHWIERIGKEIT, Mittel |
| 05 | `zurueck_klick` | Linksklick auf „Zurück“ | Menü steht: HAUPTMENÜ, „Neues Spiel“ |
| 06 | `mausrad` | Vorbereitung: 7 Spielstände; Linksklick auf „Spiel laden“, Mausrad runter über Spiel 1 | Liste oben bei Spiel 2, Rollmarke oben sichtbar; Menü steht: SPIELSTÄNDE, Spiel 2 mit Mittel, 01.01.1985 |

Für Schritt 06 legt der Selbsttest die sieben Spielstände über `SaveStore` an, mit fester Uhrzeit und
festem Seed, lädt danach den Titel neu, damit „Spiel laden“ verfügbar ist (Analyse, U1), und räumt
sie am Ende weg; im Protokoll `eingaben: Vorbereitung: 7 Spielstände; …` (Review CHK001).

## fenster

Ohne Vollbild (Spec, Clarify). Prüft Zahlen, kein Spielbild; die Fotos zeigen dennoch das Raster.

| nn | Schritt | Eingabe | Erwartet |
|---|---|---|---|
| 01 | `start` | keine | Fenster W × H, Bild Faktor f, ohne Rand; mittig im nutzbaren Bereich, auf 1 Pixel genau (f der größte ganzzahlige Faktor, der samt Titelleiste passt; auf dem Mac 3200 × 1800, Faktor 5) |
| 02 | `faktor_1` | Fenster auf 640 × 360 | Fenster 640 × 360, Bild Faktor 1, ohne Rand |
| 03 | `krumm` | Fenster auf 1318 × 742 | Fenster 1318 × 742, Bild Faktor 2, mittig, Rand ringsum, ganze Pixel |
| 04 | `zurueck` | Fenster auf die Startgröße | Fenster W × H, Bild Faktor f, ohne Rand |

„Mittig im nutzbaren Bereich“ heißt: das Fenster samt Titelleiste in der Mitte der Fläche ohne
Menüleiste und Dock (Klaus, Phase 3; `GameWindow` stellt es so). 1318 × 742 ist krumm und lässt sich
auch bei Skalierung 2 genau setzen; 1317 × 741 rundete macOS auf 1316 × 740 (Phase 3). Die Farbe des
Rands steht nicht in der Erwartung, sie lässt sich nicht nachmessen. 04 stellt auch die Lage vom Start
wieder her. 01 wartet wie jeder erste Schritt nach dem frischen Titel, bis der Communicator steht;
sonst fotografierten 02 bis 04 eine Fahrt, und die Fotos wichen je Lauf ab (Phase 3).

Die Fenstergröße stellt der Selbsttest über das Fenster ein, nicht über Eingaben: Größe ziehen ist
Sache des Betriebssystems (Spec FR-004); im Protokoll `eingaben: Fenster auf …`. W, H und f in 04 sind dieselben wie in 01.

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
