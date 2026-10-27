# Spielbeschreibung

Was im Code von „Der Computerladen“ steckt, nach Systemen geschnitten. Jede Datei ist für sich
verständlich und lässt sich einzeln laden. Gedacht für Menschen und vor allem für die KI: Vor der
Arbeit an einem System lädt sie die passende Datei, statt Specs und Code zu durchsuchen.

**Abgrenzung:** `docs/game_design.md` ist die Vision, also was das Spiel werden soll.
`specs/` ist der Bauplan mit allen Entscheidungen; `docs/features/` hält die Systemliste, den
Backlog und das Archiv. `docs/game_bible/` ist der Spielinhalt. Dieser Ordner beschreibt den
**Stand im Code**. Wo Spec und Code auseinandergehen, gilt hier der Code.

**Stand:** Features 001 bis 004, 2026-10-27.

## Dateien

| Datei | Inhalt | Laden, wenn … |
|---|---|---|
| [architektur.md](architektur.md) | Das Spiel in einem Absatz, Ordner, Autoloads, wer wen kennt, Grundsätze | die Arbeit mehrere Systeme berührt, Neues angelegt oder angebunden wird; im Zweifel zuerst |
| [spielzeit.md](spielzeit.md) | Tagesindex, `GameDate`, Spieluhr `GameClock` mit ihren Signalen | Datum, Tage, Monate, Uhr oder Tempo betroffen sind |
| [zeitleiste.md](zeitleiste.md) | Fahrplan-Modell: Ereignisse, Termine, Würfel und Seed, Tagesablauf, Signale, Modifikatoren, Eingriffe | Ereignisse, Zufall, Signale der Zeitleiste oder Eingriffe betroffen sind; ein System an die Zeitleiste angebunden wird |
| [ereigniskatalog.md](ereigniskatalog.md) | Datei `event_catalog.json`: Aufbau, Felder, Schreibregeln, Prüfregeln V01–V31, Ausnehmen von Fehlerhaftem | der Katalog gelesen, geschrieben oder geprüft wird; eine Prüfmeldung zu deuten ist |
| [schwierigkeitsgrade.md](schwierigkeitsgrade.md) | Leicht, Mittel, Schwer; Profile aus Start-Modifikatoren; Seed und Grad | Grade, Balance oder ein Spielstart mit Grad betroffen sind |
| [spielablauf.md](spielablauf.md) | `GameSession`: neues Spiel, Fortsetzen, Speichern, Verlassen, Speichern beim Schließen; der Spielbildschirm | ein Spiel beginnt, fortgesetzt oder verlassen wird; ein System beim Spielstart mitmachen muss |
| [spielstaende.md](spielstaende.md) | Inhalt und Datei eines Spielstands, sicheres Schreiben, Lesen und Zustand, Liste, Löschen | Speichern, Laden oder das Format betroffen sind; ein System mitgespeichert werden muss |
| [werkstatt.md](werkstatt.md) | Zeitleisten-Werkstatt: Editor, Zeitstrahl, Simulator, Proben, Statistik, Textausgabe | die Werkstatt benutzt oder geändert wird |
| [titel-und-hauptmenue.md](titel-und-hauptmenue.md) | App-Start, Titelbildschirm, Hauptmenü, Gradwahl, Liste der Spielstände mit Löschen, Rückfrage, Hinweis | Titel, Menü oder ein Blatt geändert werden |
| [darstellung.md](darstellung.md) | Fenster, Raster, Skalierung, Theme, Farben, Schriften | Oberfläche gebaut wird, Farben oder Schriften gebraucht werden |
| [bilder.md](bilder.md) | Rasterfassung: Palette, Rastern, Aufräumen, App-Symbol | ein Bild ins Spiel kommt |
| [build-und-tests.md](build-und-tests.md) | Starten, Export, Versionierung, Tests und Fixtures | exportiert oder getestet wird |
| [glossar.md](glossar.md) | Begriffe des Spiels und ihre Namen im Code | ein Begriff unklar ist |

## Stand der Systeme

Die Systeme 01–11 aus `docs/features/Features.md`:

| System | Stand im Code |
|---|---|
| 01 Zeitleiste | gebaut: Spieluhr, Fahrplan-Modell, Werkstatt, Schwierigkeitsgrade |
| 02–09 | noch nichts: Produktdatenbank, Wirtschaft, Information, Standort, Marketing, Handel, Qualität, Adventure |
| 10 Präsentation & UI | Titelbildschirm mit Blättern, leerer Spielbildschirm, Fenster, Theme, Baustein Knopf |
| 11 Infrastruktur | Spielstände, Export für macOS, Tests |

## Pflege

Am Ende jedes Features prüft Claude, was hier veraltet ist und was neu dazukommen sollte, und
legt das Klaus vor. Geändert wird erst nach seinem OK (`docs/ki_workflow/ki_dev.md`, „Ablauf je
Feature“). Jede Datei nennt im Kopf ihren Stand.

Aufbau einer Datei: Kopf mit „Worum es geht“, „Laden, wenn“, „Code“, „Herkunft“, „Stand“;
danach der Inhalt, knapp, mit Mermaid, wo ein Bild hilft. Was nicht gebaut ist, steht nur da, wo
es eine Entscheidung erklärt.
