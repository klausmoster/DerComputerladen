# Spielbeschreibung

Was im Code von „Der Computerladen“ steckt, nach Systemen geschnitten. Jede Datei ist für sich
verständlich und lässt sich einzeln laden. Gedacht für Menschen und vor allem für die KI: Vor der
Arbeit an einem System lädt sie die passende Datei, statt Specs und Code zu durchsuchen.

**Abgrenzung:** `docs/game_design.md` ist die Vision, also was das Spiel werden soll.
`specs/` ist der Bauplan mit allen Entscheidungen; `docs/features/` hält die Systemliste, den
Backlog und das Archiv. `docs/game_bible/` ist der Spielinhalt. Dieser Ordner beschreibt den
**Stand im Code**. Wo Spec und Code auseinandergehen, gilt hier der Code.

**Stand:** Features 001 bis 009, 2026-10-29.

## Dateien

| Datei | Inhalt | Laden, wenn … |
|---|---|---|
| [architektur.md](architektur.md) | Das Spiel in einem Absatz, Ordner, Autoloads, wer wen kennt, Grundsätze mit Verweis auf den Architektur-Leitfaden; Kern, Hülle, Nähte, Zustände | die Arbeit mehrere Systeme berührt, Neues angelegt oder angebunden wird; im Zweifel zuerst |
| [spielzeit.md](spielzeit.md) | Tagesindex, `GameDate`, Spieluhr `GameClock` mit ihren Signalen | Datum, Tage, Monate, Uhr oder Tempo betroffen sind |
| [zeitleiste.md](zeitleiste.md) | Fahrplan-Modell: Ereignisse, Termine, Würfel und Seed, Tagesablauf, Signale, Modifikatoren, Eingriffe | Ereignisse, Zufall, Signale der Zeitleiste oder Eingriffe betroffen sind; ein System an die Zeitleiste angebunden wird |
| [ereigniskatalog.md](ereigniskatalog.md) | Datei `event_catalog.json`: Aufbau, Felder, Schreibregeln, Prüfregeln V01–V31, Ausnehmen von Fehlerhaftem | der Katalog gelesen, geschrieben oder geprüft wird; eine Prüfmeldung zu deuten ist |
| [schwierigkeitsgrade.md](schwierigkeitsgrade.md) | Leicht, Mittel, Schwer; Profile aus Start-Modifikatoren; Seed und Grad | Grade, Balance oder ein Spielstart mit Grad betroffen sind |
| [spielablauf.md](spielablauf.md) | `GameSession`: neues Spiel, Fortsetzen, Speichern, Verlassen, Speichern beim Schließen; der Spielbildschirm | ein Spiel beginnt, fortgesetzt oder verlassen wird; ein System beim Spielstart mitmachen muss |
| [spielstaende.md](spielstaende.md) | Inhalt und Datei eines Spielstands, sicheres Schreiben, Lesen und Zustand, Liste, Löschen | Speichern, Laden oder das Format betroffen sind; ein System mitgespeichert werden muss |
| [werkstatt.md](werkstatt.md) | Zeitleisten-Werkstatt: Editor, Zeitstrahl, Simulator, Proben, Statistik, Textausgabe | die Werkstatt benutzt oder geändert wird |
| [titel-und-hauptmenue.md](titel-und-hauptmenue.md) | App-Start, Titelbildschirm, Hauptmenü, Gradwahl, Liste der Spielstände mit Löschen, Rückfrage, Hinweis, Fahrt vor dem Spielstart, Weg ins Easter Egg | Titel, Menü oder eine Seite geändert werden |
| [communicator.md](communicator.md) | Baustein Communicator: Gehäuse, Anzeige, Seiten, Fahrt, Hinweis, Gehäusetasten; Menü und Liste auf der Anzeige | ein Bildschirm den Communicator braucht, eine Seite, ein Gehäuse oder eine Gehäusetaste dazukommt |
| [easter-egg.md](easter-egg.md) | Easter Eggs: wie sie gebaut sind; das versteckte Spiel mit Kern, Mustern, Seite, Ergebnisanzeige, Texten und Probeszene | am versteckten Spiel etwas geändert wird oder ein Easter Egg dazukommt |
| [ton.md](ton.md) | Tonkanäle `Master` und `Effekte`, die zehn Töne, `make_sounds.py`, Prüfsummen, Verhalten ohne Fokus und ohne Tonausgang | ein Ton dazukommt oder sich ändert, etwas Töne spielen soll, Kanäle oder Lautstärke betroffen sind |
| [darstellung.md](darstellung.md) | Fenster, Raster, Skalierung, Theme, Farben, Schriften | Oberfläche gebaut wird, Farben oder Schriften gebraucht werden |
| [bilder.md](bilder.md) | Rasterfassung: Palette, Rastern, Aufräumen, App-Symbol | ein Bild ins Spiel kommt |
| [build-und-tests.md](build-und-tests.md) | Starten, Probeszenen, Töne erzeugen, Export mit sechs Presets und `baue_alles.sh`, Prüfung auf Testcode, Versionierung, Godot-Referenz, Tests und Fixtures, Architektur-Test | exportiert oder getestet wird, die Godot-Referenz fehlt |
| [selbsttest.md](selbsttest.md) | Selbsttest-App: Feature-Tag, die neun Abläufe, Läufer, Fahrer, Eingabe, Protokoll, Zusammenfassung, Vergleich mit Referenzbildern, Ablauf ergänzen, Grenzen | ein Feature Seiten, Wege, Texte oder Eingaben ändert; der Selbsttest gebaut, gestartet oder ausgewertet wird |
| [glossar.md](glossar.md) | Begriffe des Spiels und ihre Namen im Code | ein Begriff unklar ist |

## Stand der Systeme

Die Systeme 01–11 aus `docs/features/Features.md`:

| System | Stand im Code |
|---|---|
| 01 Zeitleiste | gebaut: Spieluhr, Fahrplan-Modell, Werkstatt, Schwierigkeitsgrade |
| 02–09 | noch nichts: Produktdatenbank, Wirtschaft, Information, Standort, Marketing, Handel, Qualität, Adventure |
| 10 Präsentation & UI | Titelbildschirm auf dem Communicator, leerer Spielbildschirm, Fenster, Theme, Bausteine Knopf und Communicator mit Gehäusetasten, das versteckte Spiel auf der Anzeige |
| 11 Infrastruktur | Spielstände, Export für macOS, Windows und Linux, Selbsttest, Tests, Ton: Kanäle `Master` und `Effekte`, Töne aus `make_sounds.py`; Architektur-Leitfaden mit Architektur-Prüfer und `test_architektur.gd`; Renderer Compatibility auf allen drei Systemen |

## Pflege

Am Ende jedes Features prüft Claude, was hier veraltet ist und was neu dazukommen sollte, und
legt das Klaus vor. Geändert wird erst nach seinem OK (`docs/ki_workflow/ki_dev.md`, „Ablauf je
Feature“). Jede Datei nennt im Kopf ihren Stand.

Aufbau einer Datei: Kopf mit „Worum es geht“, „Laden, wenn“, „Code“, „Herkunft“, „Stand“;
danach der Inhalt, knapp, mit Mermaid, wo ein Bild hilft. Was nicht gebaut ist, steht nur da, wo
es eine Entscheidung erklärt.
