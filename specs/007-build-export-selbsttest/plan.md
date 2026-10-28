# Implementation Plan: Build & Export mit Selbsttest

**Branch**: `feature/007-build-export-selbsttest` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-build-export-selbsttest/spec.md`

## Summary

Eine zweite App, „Der Computerladen Selbsttest“, entsteht aus demselben Projekt über ein eigenes
Preset mit Feature-Tag. Sie gehört zur Endabnahme eines Features, nicht zu jeder Phase. Per
Doppelklick bedient sie den Titel im echten Fenster und im Zeitraffer: Eingaben gehen als
markierte Ereignisse durch Godots Eingabe, echte Maus und Tastatur filtert sie weg. Je Schritt wartet
sie auf den erwarteten Zustand, fotografiert das Raster 640 × 360 und schreibt am Ende Protokoll,
Ausgabe und Zip; eine Zusammenfassung im Look der Werkzeuge zeigt das Ergebnis mit „Kopieren“,
„Ordner zeigen“ und „Beenden“. Ein Python-Werkzeug vergleicht Fotos Pixel für Pixel mit
Referenzbildern vom Mac. In Teil 2 kommen Windows und Linux dazu, mit eigener ICO, ohne Ausweichen auf
OpenGL und mit F11 und Alt+Enter für das Vollbild; ein Befehl baut dann alles für die Endabnahme.

Technischer Ansatz (Details in [research.md](research.md), Verträge unter [contracts/](contracts/)):
- **Eigener Läufer** statt GUT, Code unter `src/tools/selbsttest/`, damit der normale Export ihn
  wie die Werkstatt weglässt (R1, R2).
- **Eigene App** über den Tag `selbsttest` mit Overrides für Name, Datenordner und Startszene (R3).
- **Eingabe** mit `device = 4711` durch `Input.parse_input_event()`, Filter am Fenster über
  `DisplayServer.window_set_input_event_callback()` (R4), Ziele über einen **Fahrer** (R5).
- **Gleiche Fotos** durch feste Uhrzeit, festen Seed und festen Zeitzonenversatz (R7, R8).
- **Protokoll** als Text mit festen Schlüsseln, Ausgabe über einen eigenen `Logger` (R9, R10).
- **Windows ohne `rcedit`**, Symbol als ICO aus `tools/raster/` (R14).
- **Zeitraffer** über `Engine.time_scale = 8`, der Titel einmal in Echtzeit (R24).
- **Endabnahme** statt Lauf nach jeder Phase; **ein Befehl** `tools/build/baue_alles.sh` baut alles
  (R25, R26). **Szenarien** bekommen nur den Rahmen (R27).

## Technical Context

**Language/Version**: GDScript, typisiert, Godot 4.7.2 (Forward+); Python 3 für Vergleich und ICO

**Primary Dependencies**: keine neuen. Godot-Bordmittel: `Input.parse_input_event`,
`DisplayServer.window_set_input_event_callback`, `Logger`/`OS.add_logger`, `ZIPPacker`,
`OS.shell_show_in_file_manager`, `DisplayServer.clipboard_set`, `Image.save_png`. Python nur mit
Standardbibliothek und `tools/raster/pngio.py`. Tests mit GUT 9.7.1. Für Teil 2 die vollständigen
Export-Templates 4.7.2 (Download, `[K]`).

**Storage**: Datenordner der Selbsttest-App: `selbsttest/<lauf-id>/` mit Protokoll, Ausgabe, Fotos;
Zip daneben; Spielstände des Selbsttests in `selbsttest/spielstaende/`. Im Repo: Referenzbilder unter
`tools/selbsttest/referenz/macos/`, Belege unter `specs/007-…/belege/`.

**Testing**: GUT headless für alles ohne Fenster (R23). Die App selbst im echten Fenster, gebaut und
mit `open` gestartet, dazu die Fehlerprobe (SC-004). Vergleich mit Proben (SC-008).

**Target Platform**: macOS (Teil 1), Windows x86_64 und Linux x86_64 (Teil 2).

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`) mit Werkzeugen unter `tools/`.

**Performance Goals**: Zeitraffer 8; `titel` braucht weniger Zeit als `titel_echtzeit`
(SC-001, seit der Analyse I1); keine feste Obergrenze für einen Lauf; Höchstzeit je Schritt 5 s in echter
Zeit (R6, R24).

**Constraints**:
- Spiel ohne Selbsttest unverändert; alle bisherigen Tests grün; Änderungen am Spielcode sind nur die
  Stellschraube für den Zeitzonenversatz in `SaveGame` (R7, Phase 1), die Fenstermitte in
  `GameWindow` (Klaus, Phase 3), das Abfangen des Vollbild-Kürzels in `GameWindow._input()` und in
  `InvadersPage` (R15, Phase 6; Analyse, I2) und die lesende Abfrage der Rollmarke in `SaveList`.
- Normaler Export ohne Datei des Selbsttests (SC-005); echte Spielstände unberührt (SC-006).
- Fotos pixelgleich über zwei Läufe auf dem Mac (SC-002).
- Nur Desktop, Forward+; kein Ausweichen auf OpenGL (R13).

**Scale/Scope**: neu `src/tools/selbsttest/` (rund 15 Skripte, zwei Szenen), sechs Testdateien und
Fixtures, `tools/selbsttest/` (Vergleich, README, rund 35 Referenzbilder), ICO in `tools/raster/` und
`src/assets/icon/`. Geändert: `project.godot`, `export_presets.cfg`, `save_game.gd`, `make_icon.py`,
`test_save_game.gd`. Doku: `ki_dev.md`, Tasks-Vorlage, `ki_pruefung.md` nur nach Klaus' Entscheidung.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Windows, macOS, Linux; Maus und Tastatur als eingespeiste Ereignisse. Forward+ bleibt, das Ausweichen auf OpenGL wird abgeschaltet (R13) | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Godot-Code `[A]`; Vergleich, ICO, Style-Guide, Regel-Vorschlag `[C]`; Templates installieren, Läufe auf Windows und Linux, Abnahmen und die Entscheidung über die Regel `[K]`. Phasenweise auf Klaus' Freigabe, kein `/speckit-implement`; Lernnotizen je Aufgabe | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit 13 Klärungen und dem Abgleich mit Klaus' Ablauf, Branch, System 11; 27 Entscheidungen mit verworfenen Alternativen in research.md | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Die Zusammenfassung folgt dem Abschnitt „Werkzeuge“; was fehlt, kommt vor dem Bauen hinein (R12, Phase 4). Fotos zeigen nur das bestehende Spiel | erfüllt, mit Vorarbeit | erfüllt, mit Vorarbeit |
| V. Daten sauber halten | keine Spieldaten berührt; game_bible und Katalog unberührt | erfüllt | erfüllt |
| VI. Prüfen mit eigenem Maßstab | Phasen mit Texten oder Sichtbarem enden mit der Phasenprüfung, siehe „Prüfer je Phase“; Wortlaute der Zusammenfassung lesen die Prüfer bei der Checkliste | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7, GUT 9.7.1 bleibt für Tests ohne Fenster; kein neuer Autoload (R3); Zeitleiste unberührt | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch; `.uid` der neuen Skripte werden committet; `export_presets.cfg` sieht Claude vor jedem Commit an, keine Zugangsdaten (FR-025); Downloads nur mit Erlaubnis | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf. Zu Grundsatz IV ist Vorarbeit in Phase 4 nötig.

## Project Structure

### Documentation (this feature)

```text
specs/007-build-export-selbsttest/
├── spec.md                  # Spezifikation, geklärt
├── plan.md                  # dieser Plan
├── research.md              # Phase 0: Entscheidungen R1–R27
├── data-model.md            # Phase 1: Lauf, Systemdaten, Ablauf, Schritt, Ziel, Dateien, Vergleich
├── quickstart.md            # Phase 1: Bauen, Starten, Prüfen auf drei Systemen
├── contracts/
│   ├── selbsttest-app.md    # Start, Läufer, Fahrer, Eingabe, Zusammenfassung, Änderung am Spiel
│   ├── ablaeufe.md          # acht Abläufe mit Schritten und Erwartungen, Zeitraffer, Rahmen für Szenarien
│   ├── protokoll.md         # Form von protokoll.txt, „Kopieren“, ausgabe.txt
│   ├── vergleich.md         # Vergleichswerkzeug, Referenzbilder, Belege
│   └── export.md            # Presets, Projekteinstellungen, ICO, ein Befehl für alles, Prüfung SC-005
├── checklists/requirements.md
├── belege/                  # entsteht in Teil 2: Protokolle und Vergleiche von Windows und Linux
├── tasks.md                 # /speckit-tasks
└── lernnotizen.md           # entsteht bei der Umsetzung
```

### Source Code (repository root)

```text
src/
├── project.godot                  # geändert: Overrides selbsttest; Teil 2: Renderer, Vollbildtasten
├── export_presets.cfg             # geändert: Selbsttest macOS; Teil 2: vier Presets
├── assets/icon/app_icon.ico       # neu in Teil 2
├── core/save/save_game.gd         # geändert: Zeitzonenversatz
├── tools/selbsttest/              # neu, siehe contracts/selbsttest-app.md
└── test/                          # sechs neu oder erweitert, fixtures/selbsttest/
tools/
├── build/baue_alles.sh            # neu: alles bauen, prüfen, packen
├── raster/make_icon.py            # geändert: ICO
└── selbsttest/                    # neu: vergleich.py, README.md, referenz/macos/
```

**Structure Decision**: Der Selbsttest ist ein Werkzeug wie die Werkstatt und liegt deshalb unter
`src/tools/`, das der normale Export ausschließt. Vergleich und Referenzbilder liegen außerhalb des
Godot-Projekts unter `tools/selbsttest/`, damit Godot die Bilder nicht importiert.

## Complexity Tracking

Keine Einträge, die Prüfung der Verfassung zeigt keine Verstöße.

## Vorarbeiten vor dem Bauen

1. **Style-Guide** (R12), Phase 4: Claude ergänzt den Abschnitt „Werkzeuge“ um die Regeln aus der
   Checkliste (CHK019, CHK020, CHK024 bis CHK027, CHK030, CHK039), Klaus gibt frei.
2. **Export-Templates** (R14), Teil 2: Klaus installiert die vollständigen Templates 4.7.2. Claude
   nennt vorher Dateiname, Quelle und Größe.
3. Möglich als `[K]`: Klaus legt das Preset „Selbsttest macOS“ selbst im Export-Dialog des Editors
   an, um Presets und Feature-Tags zu lernen. Ohne Wunsch schreibt es der Agent in die Datei.

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit grünen Tests, Lernnotizen und Klaus' Abnahme; erst dann folgt die nächste.

| Phase | Inhalt | Story |
|---|---|---|
| 1 | **Gerüst, Teil 1 Kern:** `SelbsttestLauf`, `SelbsttestProtokoll`, `SelbsttestSystem`, `SelbsttestLogger`, `SelbsttestAblage` mit Tests ohne Fenster; Zeitzonenversatz in `SaveGame` | US1 |
| 2 | **Gerüst, Teil 2 im Fenster:** Startszene, Läufer mit Zeitraffer, Eingabe mit Filter, Fahrer, Overrides, Preset „Selbsttest macOS“; Abläufe `titel` und `titel_echtzeit`; App endet nach dem Lauf ohne Zusammenfassung. Claude baut, startet, liest Protokoll und Fotos | US1, US2 |
| 3 | **Alle Abläufe**, in zwei Teilen (ki_dev Punkt 4): erst `neues_spiel`, `laden`, `loeschen`; dann `easter_egg`, `bedienung`, `fenster` und der Rahmen für Szenarien mit Test. Fehlerprobe SC-004 | US1 |
| 4 | **Zusammenfassung:** Style-Guide zuerst `[C]`, dann Szene mit „Kopieren“, „Ordner zeigen“, „Beenden“, Meldung bei nicht beschreibbarem Ordner `[A]`; Prüfung SC-005 am normalen Paket | US1, US2 |
| 5 | **Vergleich:** `tools/selbsttest/vergleich.py` und README `[C]`, Proben SC-008, Referenzbilder vom Mac nach Klaus' Abnahme des Laufs | US3 |
| 6 | **Windows und Linux:** Templates `[K]`, ICO `[C]`, vier Presets, Renderer, Vollbildtasten, `test_projekt_einstellungen.gd` `[A]`; `tools/build/baue_alles.sh` `[C]`; Klaus startet auf beiden Rechnern `[K]`; Vergleich und Belege `[C]` | US4 |
| 7 | **Abschluss:** Vorschlag der Regel für `ki_dev.md`, Tasks-Vorlage und `ki_pruefung.md` `[C]`: Selbsttest zur Endabnahme, „[A] Selbsttest-Abläufe anpassen“ vor der Gesamtabnahme; Klaus entscheidet je Datei `[K]`; die Gesamtabnahme von 007 ist die erste mit Selbsttest auf drei Systemen; Lückensuche mit `/speckit-converge`; Gesamtabnahme; Spielbeschreibung (`build-und-tests.md`, `darstellung.md` Vollbildtasten, Index; neu wohl `selbsttest.md`); Tagebuch | US5 |

Phase 2 hängt an 1, Phase 3 an 2, Phase 4 an 3, Phase 5 an 4 (Referenzbilder aus einem vollständigen
Lauf), Phase 6 an 5. In 007 läuft der Selbsttest in den Phasen 2 bis 6, weil er dort selbst gebaut
wird; ab 008 nur zur Endabnahme (R25).

## Änderungen nach der Checkliste

Aus [checklists/review.md](checklists/review.md), 39 Punkte: 15 von Claude, 13 vom Stil-Prüfer, 11
vom Text-Prüfer aus 18 Befunden; von Klaus am 2026-10-28 alle nach Vorschlag freigegeben.
Eingearbeitet in Spec (Clarifications „Review 2026-10-28“, FR-004, FR-007 bis FR-009, FR-011.8,
FR-013 bis FR-016, FR-019, FR-024, Story 5, Randfälle, SC-002 bis SC-004, Reihenfolge der SC),
research.md (R12), Datenmodell, Verträge (App: Zusammenfassung und Texte neu; Abläufe: Form der
Spalte „Erwartet“; Protokoll: Beispiel und Formen) und Quickstart. Die wichtigsten:
- **CHK001**: Vorbereiten eines Ablaufs und Fenstergröße sind die einzigen Schritte ohne Eingabe.
- **CHK016, CHK017**: Die Zusammenfassung hält `GameWindow` an und setzt die eingebaute Schrift; sie
  bleibt im Fenster des Laufs, ohne zu maximieren (Klaus, Phase 4).
- **CHK019, CHK020**: Fehler mit Feld „!“, nicht gelaufen mit Feld „–“, in Ordnung ohne Farbe;
  gesperrter Knopf bei nicht beschreibbarem Ordner.
- **CHK029 bis CHK039**: `computerladen.version`, „Spiel laden“, eine Ergebniszeile, Gründe ohne
  „gescheitert“, Fenstertitel mit „Schritt“, Maschinenform im Protokoll.

## Änderungen nach der Analyse

Aus `/speckit-analyze` am 2026-10-28 mit 19 Befunden (2 kritisch, 2 hoch, 9 mittel, 6 niedrig),
gelesen von einem unabhängigen Prüfer; Claude hat alle nachgeprüft, I1 und I2 am Code
(`communicator.gd`, `MAX_STEP`; Godots Regel für Aktionen ohne Zusatztaste). Klaus hat alle
Empfehlungen freigegeben.
- **V1** (kritisch): Phase 6 zeigt das App-Symbol in sechs Größen. Vor T042 kommt die Regel dafür in
  den Abschnitt „App-Symbol“ des Style-Guides (T041a, T041b); vor der Abnahme prüft der
  Stil-Prüfer eine Montage (T048a).
- **V2** (kritisch): Phase 5 schreibt Werkzeugtexte; Phasenprüfung mit dem Text-Prüfer (T038a).
- **I1** (hoch): Der Communicator begrenzt seinen Schritt; SC-001 verlangt nur noch „schneller“,
  R24 nennt die Grenze. `dauer_ms` zählt bei Schritten ohne Eingabe ab Beginn des Schritts.
- **I2** (hoch): Alt+Enter trifft auch `ui_accept`; `GameWindow` fängt das Kürzel in `_input()` ab
  (R15, FR-023, T043).
- **I3**: Frischer Titel über `leave()` und Ordner leeren; ob der Communicator steht, erkennt der
  Fahrer am Signal `slide_finished`. Keine weitere Änderung am Spiel.
- **I4**: In den Phasen 1 bis 3 sind CHK030 und CHK039 Maßstab der Text-Prüfer.
- **I5**: Bis Phase 5 vergleicht Claude Fotos mit `cmp`; `vergleich.py` bekommt `--gegen <lauf>`.
- **I6, U1, U2, U3, U5, U6, U7, M1, M2, I7, I8, A1**: Zeitpunkt von `system.fenster`, Titel neu
  laden nach der Vorbereitung in `bedienung.06`, eigener `quit_callback` und Schließtest,
  „ausschalten“ heißt durchreichen, kopierter Text bei nicht beschreibbarem Ordner, `.gitkeep`,
  `zeitraffer:` je Schritt, „scrollt“, 37 Schritte im Beispiel, sechs Fehler in R23, T043 nach T042,
  Probe des kopierten Texts in T032.
- **U4**: Neue Aufgabe „Quickstart nachziehen“ (T046a).

Eingearbeitet in Spec (Clarifications „Analyse 2026-10-28“, FR-023, SC-001, Story 1), research.md
(R4, R15, R23, R24), Datenmodell, Verträge, Quickstart und tasks.md.

## Prüfer je Phase

Jede Phase mit Sichtbarem oder Texten endet mit der `[C]`-Aufgabe „Phasenprüfung“ durch
`/dcl-phasenpruefung` vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`).

| Phase | Ändert | Prüfer | Maßstab für die Prüfer |
|---|---|---|---|
| 1 Kern | Texte im Protokoll (Kopfzeile, Ergebnissatz, Gründe) | Text | `Sprache.md`; Protokolle aus den Fixtures |
| 2 Fenster | Fenstertitel, Beschreibungen des Ablaufs `titel` | Text | `Sprache.md`; Protokoll eines echten Laufs |
| 3 Abläufe | Beschreibungen und Erwartungen aller Abläufe | Text | wie Phase 2 |
| 4 Zusammenfassung | eine sichtbare Seite und ihre Texte | Stil, Text | Abschnitt „Werkzeuge“, `tokens.json`, `Sprache.md`; Bildschirmfotos: alles in Ordnung, mit Fehlern, Ordner nicht beschreibbar |
| 5 Vergleich | Texte eines Werkzeugs: Bericht `vergleich.md` und README (Analyse, V2) | Text | `Sprache.md`, `Werkzeuge.md`; ein Bericht aus den Proben |
| 6 Windows, Linux | App-Symbol in sechs Größen (Analyse, V1), Vollbildtasten | Stil | Abschnitt „App-Symbol“ nach der Ergänzung; Montage der sechs Größen ×8 |
| 7 Abschluss | Doku | bei der Lückensuche Stil und Text einmal über das ganze Feature | wie 4 |
