# Implementation Plan: Neues Spiel starten

**Branch**: `feature/004-neues-spiel` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-neues-spiel/spec.md`

## Summary

Der Spieler beginnt ein eigenes Spiel: Er wählt im Hauptmenü „Neues Spiel“, dann Leicht, Mittel
oder Schwer. Das Spiel wird als Spielstand „Spiel N“ gespeichert, und er landet auf einem noch
leeren Spielbildschirm mit dem Knopf „Zum Hauptmenü“. Er kann das Spiel verlassen, mit
„Weiterspielen“ oder über die Liste fortsetzen und Spielstände löschen. Ohne begonnenes Spiel läuft
keins mehr im Hintergrund.

Technischer Ansatz (Details in [research.md](research.md), Verträge unter [contracts/](contracts/)):
- **Spielstand als JSON-Datei** `spiel_<N>.json` unter `user://spielstaende/`, kanonisch wie Katalog
  und Proben. Darin Formatversion, Nummer, Name, Grad, Seed, Spieldatum, Zeitpunkte, Spielversion,
  eine Kopie des Katalogs samt Profilen und das Eingriffsprotokoll; der Fahrplan entsteht beim
  Fortsetzen neu (R1, R2).
- **Sicher speichern** in fünf Schritten über `.neu` und `.alt`: Ein Abbruch an jeder Stelle lässt
  einen lesbaren Stand übrig (R3).
- **Kernklassen ohne Node:** `SaveGame`, `SaveSlot` und `SaveStore` unter `src/core/save/`; das
  Nachspielen der Eingriffe und die Umrechnung der Tage teilen sich Spielstand und Probe
  (`TimelineRun.replay()`, `InterventionFile`, R5).
- **Kein Selbststart:** Die Zeitleiste beginnt kein Spiel mehr von selbst. `Timeline.resume_game()`
  spielt ein gespeichertes Spiel still bis zu seinem Datum ab, `GameClock.set_date()` stellt die
  Uhr (R6).
- **Autoload `GameSession`** hält das laufende Spiel, legt an, setzt fort, speichert, verlässt und
  speichert beim Schließen des Fensters und bei Cmd+Q (R7 bis R9).
- **Blätter auf dem Titelbildschirm:** Gradwahl, Liste mit vier Spalten, Rollen und Löschmodus,
  Rückfrage; alle an der Stelle des Hauptmenüs, gemessen auf dem Raster 640 × 360 (R11 bis R14).
- **Spielbildschirm** in `nacht` mit dem Baustein Knopf und einem Hinweis, der das Spiel nennt
  (R15).
- **Style-Guide zuerst:** Blätter, Liste, Rückfrage, Meldung und Knopf auf dunklem Grund kommen vor
  dem Bauen in den Style-Guide (R17).
- **Pilot der Prüf-Agents:** Jede Phase mit Sichtbarem oder Texten endet mit der Phasenprüfung
  durch `/dcl-phasenpruefung` (Abschnitt „Prüfer je Phase“).

## Technical Context

**Language/Version**: GDScript, typisiert, Godot 4.7.2 (Forward+)

**Primary Dependencies**: keine neuen. Godot-Bordmittel: `JSON`, `FileAccess`, `DirAccess`,
`Time`, `Button`, `Control._draw()`, `SceneTree.change_scene_to_file()`. Tests mit GUT 9.7.1.

**Storage**: Spielstände als JSON unter `user://spielstaende/`, unter macOS
`~/Library/Application Support/Godot/app_userdata/Der Computerladen/spielstaende/`. Der Ordner liegt
außerhalb der App und übersteht Updates (FR-012). Tests schreiben in eigene Ordner unter `user://`.
Der Ereigniskatalog bleibt, wo er ist; jeder Spielstand führt eine Kopie.

**Testing**: GUT 9.7.1 headless mit Test-Katalogen und kaputten Spielständen unter
`src/test/fixtures/`. Oberfläche zusätzlich mit Bildschirmfotos aus dem echten Fenster und von Hand
nach [quickstart.md](quickstart.md).

**Target Platform**: Desktop: Windows, macOS, Linux; entwickelt und geprüft auf macOS (Apple
Silicon). Das sichere Speichern ist so gebaut, dass es nicht vom Verhalten von `rename` unter
Windows abhängt (R3).

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`)

**Performance Goals**: Liste und Anzeige von 20 Spielständen mit je 500 Ereignissen in höchstens
1 s (SC-002). Fortsetzen am 31.12.1999 baut den Lauf über 15 Jahre auf; der Lauf springt von
Stichtag zu Stichtag, „Bis zum Ende“ dauerte in Feature 002 21 ms.

**Constraints**:
- Gleicher Spielstand, gleiches Spiel: Ab dem Spieldatum dieselben Meldungen an denselben Tagen
  wie ohne Unterbrechung (FR-008, SC-003).
- Ein Abbruch beim Speichern lässt immer einen lesbaren Stand (FR-011).
- Nie einen beschädigten oder zu neuen Spielstand überschreiben, nie fremde Dateien löschen
  (FR-013, FR-018).
- Die Zeitleiste meldet nur; vergangene Tage meldet sie beim Fortsetzen nicht noch einmal (R6).
- Startprobe still; ohne Spielstände sieht der Titel aus wie in Feature 001 (SC-006).
- Nur Desktop mit Maus und Tastatur; alles auf dem Oberflächenraster 640 × 360.

**Scale/Scope**: drei neue Kernklassen, ein neues Autoload, eine neue Hilfsklasse für Eingriffe;
geändert `Timeline`, `GameClock`, `TimelineRun`, `EventCatalog`, `WhatIfProbe`. Oberfläche: drei
neue Blätter, ein neuer Bildschirm, ein neuer Baustein Knopf, Meldung im Hinweis. Zehn neue
Testdateien, sechs geänderte (`test_timeline.gd`, `test_timeline_run.gd`, `test_event_catalog.gd`,
`test_game_clock.gd`, `test_main_menu.gd`, `test_title_screen.gd`), etwa zehn kleine Fixtures. Im
Style-Guide fünf Abschnitte und eine Ergänzung im README (R17, T001).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Bedienung mit Maus und Tastatur wie im Hauptmenü: Überfahren wählt, Rechtsklick zeigt den Hinweis, Pfeile, Tab, Enter, Esc, Mausrad zum Rollen. Fenster schließen und Cmd+Q speichern. Keine Touch-Eingaben, Forward+ bleibt | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Der Plan enthält nur Signaturen. Umgesetzt wird phasenweise auf Klaus' Auftrag, eine Phase nach der anderen, auch Phase 1 vor Phase 2 (Analyse, D2), `/speckit-implement` nie; Lernnotizen in `lernnotizen.md` zu jeder umgesetzten Task. Die fünf Festlegungen aus der Spec und die Sätze zu den Graden hat Klaus entschieden; Claudes Festlegungen aus dem Plan stehen gekennzeichnet in research.md und `docs/offene-punkte.md` | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit zehn Klärungen, zwei davon zum Plan, dazu das Review mit 36 Punkten, eigener Branch, Systeme 11, 01 und 10 genannt. 18 Entscheidungen mit verworfenen Alternativen in research.md | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Neue Bausteine und Regeln kommen in Phase 1 in den Style-Guide, bevor gebaut wird (R17). Die Maße in R11, R12 und R15 sind Messungen für den Platz; T001 trägt sie in den Style-Guide ein, und Verträge und Tasks verweisen danach nur noch auf ihn, statt Werte abzuschreiben (Analyse, D1) | erfüllt, mit Vorarbeit | erfüllt, mit Vorarbeit |
| V. Daten sauber halten | Spielstände sind Spieldaten des Spielers unter `user://`, nicht Spielinhalt; game_bible unberührt. Der Katalog wird nicht verändert, ein Spielstand führt eine Kopie | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7, GUT 9.7.1, Projekt in `src/`. `GameClock` und `Timeline` bleiben Autoloads, `GameSession` kommt dazu. Die Timeline meldet weiter nur und bleibt die eine Quelle für Ereignisse; der Spielstand hält nur, was ihren Fahrplan festlegt | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch. `.uid` der neuen Skripte wird committet; `export_presets.cfg` bleibt unberührt, `test/*` und `tools/*` sind ausgeschlossen. Spielstände entstehen nur unter `user://`, nie im Projekt | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf. Zu Grundsatz IV ist Vorarbeit nötig: fünf
Abschnitte und eine Ergänzung im Style-Guide in Phase 1. Die Analyse fand zwei Verstöße, Werte im
Vertrag statt im Style-Guide (D1) und Phase 1 parallel zu Phase 2 und 3 (D2); beide sind behoben.

## Project Structure

### Documentation (this feature)

```text
specs/004-neues-spiel/
├── spec.md                      # Spezifikation, geklärt
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R18
├── data-model.md                # Phase 1: Klassen, Dateiformat, Zustände, Wege
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── spielstand.md            # SaveGame, SaveSlot, SaveStore, InterventionFile, replay()
│   ├── spielablauf.md           # Timeline, GameClock, GameSession
│   └── titelbildschirm.md       # Blätter, Liste, Rückfrage, Spielbildschirm, Knopf, Texte
├── checklists/
│   ├── requirements.md          # Qualitätsprüfung der Spec
│   └── review.md                # Review der Anforderungen, 36 Punkte, von Klaus freigegeben
├── tasks.md                     # Aufgaben je Phase (/speckit-tasks), T001 bis T035
└── lernnotizen.md               # entsteht bei der Umsetzung
```

### Source Code (repository root)

```text
src/
├── project.godot                        # geändert: Autoload GameSession
├── core/
│   ├── game_session.gd                  # neu: Autoload GameSession
│   ├── timeline.gd                      # geändert: kein Selbststart, resume_game(), stop_game()
│   ├── game_clock.gd                    # geändert: set_date()
│   ├── save/
│   │   ├── save_game.gd                 # neu
│   │   ├── save_slot.gd                 # neu
│   │   └── save_store.gd                # neu
│   └── timeline/
│       ├── intervention_file.gd         # neu, aus WhatIfProbe
│       ├── timeline_run.gd              # geändert: replay()
│       └── event_catalog.gd             # geändert: from_data()
├── ui/
│   ├── computerladen_theme.tres         # geändert: Knopf, WarningPanel
│   └── knopf.gd                         # neu: Baustein Knopf
├── scenes/
│   ├── title/                           # geändert: Blätter, Liste, Texte
│   └── game/                            # neu: Spielbildschirm
├── tools/werkstatt/what_if_probe.gd     # geändert: nutzt die geteilten Hilfen
└── test/                                # neue und geänderte Tests, fixtures/spielstaende/
```

**Structure Decision**: Spielstände gehören zum Kern unter `src/core/save/`, weil sie keine Szene
brauchen und so ohne Fenster testbar sind wie der Lauf. Das laufende Spiel ist ein Autoload, weil
es den Szenenwechsel überlebt. Die Oberfläche bleibt in `src/scenes/`, der wiederverwendbare Knopf
in `src/ui/`. Einzelheiten stehen in den Verträgen.

## Complexity Tracking

Keine Einträge, die Prüfung der Verfassung zeigt keine Verstöße.

## Vorarbeiten vor dem Bauen

1. **Style-Guide** (R17), Phase 1: Claude schreibt die fünf Abschnitte, Klaus gibt sie frei.
2. **Sätze zu den Graden** (R18): entschieden, Vorschlag A; sie gehen in den Abschnitt der
   Gradwahl ein.
3. **Fünf Festlegungen aus der Spec:** bestätigt (unten, „Entscheidungen von Klaus zum Plan“).

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit grünen Tests, Lernnotizen und Klaus' Abnahme; erst dann folgt die nächste.
Jede Phase mit Sichtbarem oder Texten hat vor der Abnahme die [C]-Aufgabe „Phasenprüfung“ mit
`/dcl-phasenpruefung` (`ki_pruefung.md`). Hat eine Phase Kern und Oberfläche, prüft Claude den Kern,
bevor die Oberfläche beginnt.

| Phase | Inhalt | Story |
|---|---|---|
| 1 | Style-Guide: Blätter im Titel, Liste, Rückfrage, Meldung, Knopf auf dunklem Grund mit Spielbildschirm (R17); die Sätze zu den Graden nach Klaus' Wahl. Kein Code | Vorarbeit |
| 2 | Kern Spielstand: `InterventionFile` und `TimelineRun.replay()` mit `WhatIfProbe` darauf, Proben Byte für Byte gleich; `EventCatalog.from_data()`; `SaveGame`, `SaveSlot`, `SaveStore` mit sicherem Schreiben, Liste, Nummer, Löschen; Fixtures; SC-003 im Kern, SC-004, Messung für SC-002 | US3, US4 (Kern) |
| 3 | Spielablauf: Selbststart entfällt, `resume_game()`, `stop_game()`, `GameClock.set_date()`, `GameSession` mit Anlegen, Fortsetzen, Speichern, Verlassen, Schließen; `test_timeline.gd` angepasst; SC-005, SC-003 über die Autoloads, FR-003 | US1, US2, US3 (Kern) |
| 4 | Oberfläche Teil 1: `MenuPaper` aus `MainMenu`, Kopfzeile und Einträge zur Laufzeit; Hauptmenü mit fünf Einträgen und Vorwahl; Gradwahl mit Sätzen; Esc; Baustein Knopf; Spielbildschirm mit Hinweis und Meldung; Szenenwechsel. **Erste Phasenprüfung mit dem Stil-Prüfer** | US1, US2 |
| 5 | Oberfläche Teil 2: `SaveList` mit Spalten, Rollen, gedämpften Zeilen und Löschmodus; Rückfrage; Fortsetzen und Löschen über die Liste, Rückkehr ins Hauptmenü nach dem letzten | US3, US4 |
| 6 | Abschluss: CLAUDE.md (Tabelle „Aufbau“ mit `src/core/save/` und `src/scenes/game/`, Autoload `GameSession`, kein Selbststart der Zeitleiste) nur mit Klaus' OK; `docs/features/Features.md` und `Feature_Ideas.md` (11-01 Spielstände, 01-05 Neues Spiel); Zählung des Piloten in `ki_pruefung.md`, „Nachmessen“; Lückensuche mit `/speckit-converge`, die Prüfer einmal über das ganze Feature; Quickstart vollständig; Gesamtabnahme | – |

Phase 2 und 3 sind Kern ohne Oberfläche; Phase 4 und 5 bauen darauf. Phase 3 braucht `SaveStore`
aus Phase 2, Phase 5 die Blätter aus Phase 4. Die Phasen laufen streng nacheinander, auch Phase 1
vor Phase 2 (Verfassung, Grundsatz II; Analyse, D2).

## Prüfer je Phase

Pilot der Prüf-Agents (`docs/ki_workflow/ki_pruefung.md`, Schritt 9). Der Pilot beginnt mit der
ersten Phase mit Texten, Phase 2, mit dem Text-Prüfer; der Stil-Prüfer kommt in Phase 4 dazu
(Analyse, F7). Jede Phase mit Sichtbarem oder Texten endet mit der [C]-Aufgabe „Phasenprüfung“ durch
`/dcl-phasenpruefung` vor Klaus' Abnahme. Claude zählt je Prüfer gemeldete, bestätigte und
verworfene Befunde und trägt sie unter „Nachmessen“ ein.

| Phase | Ändert | Prüfer | Maßstab für die Prüfer |
|---|---|---|---|
| 1 Style-Guide | den Maßstab selbst | keine; Klaus nimmt ab | – |
| 2 Kern Spielstand | Daten und die Gründe, die die Liste zeigt (R10) | Text | `Sprache.md`; Textliste der Gründe aus `save_slot.gd` und `save_game.gd` |
| 3 Spielablauf | Kern und die Meldungen zum Speichern | Text | `Sprache.md`; Meldungen aus `game_session.gd` |
| 4 Neues Spiel und Spielbildschirm | Hauptmenü, Gradwahl, Spielbildschirm, Knopf, Hinweise, Sätze zu den Graden | Stil, Text | `README.md`, Bausteine Menü, Hinweis, Knopf und die neuen aus Phase 1, `tokens.json`; `Sprache.md`; Bildschirmfotos aus titelbildschirm.md |
| 5 Liste und Löschen | Liste, Löschmodus, Rückfrage, Meldung, Gründe im Hinweis | Stil, Text | wie Phase 4, dazu Baustein Liste und Rückfrage |
| 6 Abschluss | Doku | bei der Lückensuche Stil und Text einmal über das ganze Feature; eine Phase für Lücken mit Sichtbarem oder Texten endet mit eigener Phasenprüfung (Analyse, D3) | wie 4 und 5 |

## Was Klaus dabei lernt

Kandidaten für Lernnotizen und für `[K]`-Aufgaben, die Klaus sich aussucht:
- Eine Datei sicher ersetzen: schreiben, prüfen, tauschen; warum ein Absturz an jeder Stelle einen
  lesbaren Stand lässt (Phase 2).
- `user://` und wo Godot es unter macOS, Windows und Linux ablegt (Phase 2).
- Unix-Zeit, UTC und Ortszeit mit `Time` (Phase 2).
- Ein Autoload, das den Szenenwechsel überlebt, und warum es Uhr und Zeitleiste über Felder kennt
  statt direkt (Phase 3).
- `NOTIFICATION_WM_CLOSE_REQUEST` und `auto_accept_quit`: das Beenden abfangen (Phase 3).
- Ein Spiel still nachspielen statt alle Signale noch einmal zu senden (Phase 3).
- Gemeinsames Malen in einer Klasse mit statischen Funktionen, `MenuPaper` (Phase 4).
- **Gut als `[K]`-Aufgabe:** die Gradwahl als zweite Instanz von `main_menu.tscn` im Editor
  anlegen: Instanz, Lage und Kopfzeile. Die vier Einträge (Leicht, Mittel, Schwer, Zurück) mit
  ihren Hinweisen setzt `TitleScreen` zur Laufzeit aus `TitleTexts` (Analyse, F4). Klein, im
  Inspector machbar, und Klaus sieht, wie eine Szene mehrfach benutzt wird (Phase 4).
- **Ebenfalls geeignet:** der Spielbildschirm als Szene mit `ColorRect` und Knopf, die Verbindung
  des Signals im Editor (Phase 4).
- Ein Fenster aus Zeilen, deren Inhalt beim Rollen wechselt (Phase 5).

## Was sich an Feature 001 bis 003 ändert

| Teil | Bisher | Danach | Wer es merkt |
|---|---|---|---|
| Hauptmenü | vier Einträge, „Neues Spiel“ und „Spiel laden“ nie verfügbar | fünf Einträge mit „Weiterspielen“ oben, Verfügbarkeit nach Spielständen (FR-001, FR-002) | Quickstart von 001; neue Tests in `test_title_screen.gd`, dessen zwei Tests zur Versionszeile bleiben (Analyse, F11) |
| Vorwahl im Hauptmenü | immer die erste Zeile | „Weiterspielen“ oder „Neues Spiel“ (FR-001a) | `test_main_menu.gd` bleibt; neue Tests in `test_title_screen.gd` |
| Hinweise „Neues Spiel“, „Spiel laden“ | „Der Laden hat noch zu …“, „Noch keine Spielstände. Speichern kommt bald.“ | neue Texte (titelbildschirm.md) | Klaus, der Text-Prüfer |
| `MainMenu` | Kopfzeile in der Szene, Breite fest, Einträge nur in `_ready()` | `header_text`, `paper_width` mit `PAPER_WIDTH` als Vorgabe, `set_entries()`; Malen in `MenuPaper` | `test_main_menu.gd` unverändert, Hauptmenü Pixel für Pixel gleich |
| `Timeline._ready()` | startet per `call_deferred()` ein Spiel mit Mittel | startet keins (FR-003) | `test_timeline.gd`: fünf Tests und der Helfer `_zeitleiste()` (Analyse, F1) |
| `Timeline` | `start_game()` | dazu `resume_game()`, `stop_game()`, `is_running()` | niemand, Neues kommt hinzu |
| `GameClock` | Datum nur vorwärts | dazu `set_date()` | `test_game_clock.gd` |
| `WhatIfProbe` | eigene Umrechnung und eigenes Nachspielen | ruft `InterventionFile` und `TimelineRun.replay()` | niemand: Proben und Tests Byte für Byte gleich |
| `EventCatalog.from_json()` | parst und liest | parst und ruft `from_data()` | niemand: Meldungen gleich |
| Autoloads | `GameClock`, `Timeline`, `GameWindow` | dazu `GameSession` | `project.godot`, CLAUDE.md in Phase 6 |
| `auto_accept_quit` | nur die Werkstatt schaltet es | dazu `GameSession`, solange ein Spiel läuft | in der Werkstatt läuft nie ein Spiel |

## Änderungen nach der Checkliste

Im Review der Checkliste [review.md](checklists/review.md) am 2026-10-26 hat Klaus alle 36
Vorschläge freigegeben. An Spec und Plan hat das geändert:
- **Fehlerwege, neu in den Edge Cases:** Datei ändert sich von außen (CHK001), zwei Fenster legen
  gleichzeitig ein Spiel an (CHK002; R4, `SaveStore.write(game, is_new)`), Löschen scheitert
  (CHK003), Speichern scheitert beim Anlegen, beim Fortsetzen und beim Schließen (CHK004, CHK020,
  CHK022), was nach einem Absturz beim Speichern zu sehen ist (CHK021), Werte außerhalb ihres
  Bereichs mit Spieldatum und Eingriffen (CHK009).
- **Präzisiert:** FR-004 mit dem Satz im Hinweis (CHK011), FR-010 mit dem Fortsetzen (CHK004),
  FR-011 mit dem Ort der Meldung (CHK014), FR-015 mit Ordnung, Ortszeit und Rollen (CHK005,
  CHK006, CHK013), FR-017 bei nicht fortsetzbaren Spielständen (CHK008), FR-017a mit „Löschen …“
  im Löschmodus (CHK007), FR-018 mit den Zwischendateien (CHK012), FR-023 mit „Abbrechen“ und Esc
  im Hauptmenü (CHK010, CHK016).
- **Messbar gemacht:** SC-002 mit 20 Spielständen zu je 500 Ereignissen und dem Fortsetzen vom
  31.12.1999 (CHK024), SC-006 mit Hinweisen und Höhe des Menüs (CHK019).
- **Annahmen:** Katalog beim Start gelesen (CHK018), Spielstände sind nur Daten (CHK035), die Uhr
  des Rechners geht richtig (CHK023), geprüft bis 20 Spielstände (CHK036).
- **Plan und Verträge:** Hinweis am allein stehenden Knopf statt Tooltip, als Regel für den
  Style-Guide (CHK017, R17); Esc in den Hinweisen von „Zurück“ und „Abbrechen“ (CHK031); Liste bei
  jedem Öffnen neu gelesen (CHK001); FR-012 im Quickstart (CHK026).

Die übrigen Punkte waren erfüllt oder brauchten keine Änderung.

## Änderungen nach der Analyse

Die Analyse mit `/speckit-analyze` am 2026-10-26 fand 44 Befunde: zwei kritische, sieben hohe, 22
mittlere und 13 niedrige. Ein unabhängiger Prüfer hat sie gefunden, Claude hat sie nachgeprüft, und
Klaus hat am selben Tag alle nach Empfehlung freigegeben. Die Kürzel stehen an den Stellen, die sie
geändert haben, etwa „(Analyse, F2)“.
- **Kritisch, Verfassung:** Werte wie Spalten, Papierbreite und Lage des Knopfs standen im Vertrag;
  jetzt kommen sie mit T001 in den Style-Guide, und Vertrag und Tasks verweisen darauf (D1). Phase 1
  lief parallel zu Phase 2 und 3; jetzt laufen alle Phasen nacheinander (D2).
- **Hoch:**
  - fünf Tests in `test_timeline.gd` statt zwei rufen künftig `start_game()` selbst auf, mit
    unveränderten Erwartungen (F1);
  - das Hauptmenü wird bei jeder Rückkehr neu gelesen, damit ein gelöschter Spielstand nicht über
    „Weiterspielen“ zurückkommt (F2);
  - „Zurück“ im Löschmodus beendet nur den Modus und hat einen eigenen Hinweis (F3);
  - der Vorschlag für Klaus' Aufgabe zur Gradwahl passt zu `TitleTexts` (F4);
  - scheitert das Speichern beim Fortsetzen, gibt `resume()` OK zurück, und der Spielbildschirm
    zeigt die Meldung (F5);
  - `scene_callback` macht den Szenenwechsel testbar, ohne die echte Session (C1);
  - ein Test belegt FR-022 über `GameSession` (E1).
- **Sicheres Speichern:** In Schritt 2 heißt „prüfen“ „Text gleich `to_json()`“; „lesbar“ heißt
  fortsetzbar; ein zu neuer Spielstand fällt nie auf eine Zwischendatei zurück; das Aufräumen hat
  seinen Platz in Schritt 1 und 3 (B1, B2, C5). Ein zweites Fenster verringert nur den
  Zusammenstoß (F10).
- **Maße:** Spalten bei 0, 64, 108, 172, Papier 304 bei x 312, Rollmarken in Kopfzeile und „Löschen
  …“, Namen bis „Spiel 9999“ (F9, B4); die Rechnung zum Knopf mit Kontur (F13).
- **Anlegen:** erst Spielstand schreiben, dann `start_game()`; Seed über `rng` (C4, C6).
- **Texte:** Gründe ohne Werte aus der Datei (B4); Rückfrage bei beschädigten und zu neuen
  Spielständen (C9); ein Längentest für alle Texte in `test_title_texts.gd` (C10).
- **Übrige:** Pflichtfelder (B3), `_upgrade()` (E4), Versatz der Ortszeit (C3), `show_text()` (C2),
  Hilfen in `InterventionFile` (C12), Tag höchstens 31.12.1999 (C11), Fotos mit eigenem Ordner und
  Vergleichsbild des Hauptmenüs (C7, C8), Tests für Löschen scheitert und Datei von außen (E2, E3),
  Quickstart 3.2 und 3.4 (F6, F12), Pilot ab Phase 2 (F7), Zahlen, Labels und Abhängigkeiten in Plan
  und Tasks (F8, F11, F14 bis F20, D3), FR-016 (B5).

## Eigene Festlegungen des Plans

Claude hat beim Planen festgelegt, was nicht aus Spec und Klärung folgt. Jede steht mit Grund in
research.md. Mit der Checkliste hat Klaus am 2026-10-26 die bestätigt, die jetzt in der Spec
stehen: Ordnung und Rollen der Liste, „Löschen …“ im Löschmodus, Sätze im Hinweis, „Abbrechen“ in
der Rückfrage, Speichern beim Fortsetzen, Schließen bei gescheitertem Speichern, falsche Eingriffe
als Schaden, Katalog beim Start. Offen in `docs/offene-punkte.md`, „Feature 004, Plan“, bleiben:
- alle Blätter oben bei y 150 und rechts bündig wie das Hauptmenü; sechs sichtbare Spielstände
  (R11, R12);
- „zuletzt gespielt“ als vierte Spalte „26.10.2026 21:40“ (R12);
- Spielbildschirm in `nacht`, Knopf in der Mitte, Hinweis nennt das Spiel (R15);
- zurück aus einem Blatt steht die Auswahl auf dem Eintrag, der es geöffnet hat (data-model.md).

## Entscheidungen von Klaus zum Plan

Am 2026-10-26, beide nach Empfehlung:
1. **Die fünf Festlegungen aus der Spec** sind bestätigt: Esc auf dem Spielbildschirm löst nichts
   aus; „Spiel N“ mit N = größte Nummer + 1; der Löschmodus mit seinen Enden und „Abbrechen“
   vorgewählt; nur beschädigte Spielstände machen „Spiel laden“ verfügbar; kein Speichern während
   des Spiels.
2. **Die Sätze zu den Graden** sind Vorschlag A (R18): Leicht „Das Glück ist eher auf deiner
   Seite.“, Mittel „Das Glück hält sich raus.“, Schwer „Das Glück ist eher auf der Seite der
   anderen.“

Offen bleiben nur Claudes eigene Festlegungen oben; Klaus kann sie mit der Checkliste oder jeder
Abnahme ändern.

Später, nicht für dieses Feature: ein eigener Name des Benutzerordners
(`application/config/use_custom_user_dir`), damit Spielstände unter „Der Computerladen“ statt unter
„Godot/app_userdata“ liegen. Das gehört vor die erste Veröffentlichung; heute würde es die
Einstellungen und Sicherungskopien der Werkstatt an einen neuen Ort verschieben.
