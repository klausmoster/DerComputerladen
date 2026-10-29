# Implementation Plan: Ladeneröffnung

**Branch**: `feature/010-ladeneroeffnung` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/010-ladeneroeffnung/spec.md`

## Summary

Nach der Gradwahl sucht sich der Spieler im Büro des Maklers einen von vier Läden einer fiktiven
westdeutschen Mittelstadt aus, liest die Exposés mit Kleingedrucktem, unterschreibt den
Mietvertrag, meldet sein Gewerbe unter eigenem Namen an und steht dann in seinem leeren Laden. Die
Uhr läuft mit Pause und Tempo, am Monatsersten geht die Miete vom Konto ab. Der Ladenname ist der
Name des Spielstands. Erstes Feature der Schichten Adventure und Wirtschaft.

Technischer Ansatz (Details in [research.md](research.md), Verträge unter [contracts/](contracts/)):
- **Ablauf über drei Szenen:** Titel, Büro des Maklers, Spielbildschirm. Die Gradwahl beginnt eine
  Eröffnung in `GameSession`; geschrieben wird erst bei der Anmeldung (R1).
- **Kerne ohne Node** unter `src/core/shop/`: `ShopOpening` mit den Schritten als `enum`,
  `ShopAccount` für das Konto, `ShopName`, `ShopRules`, `Money`; alles Geld in Pfennig (R2 bis R4,
  R7).
- **Spielstand** mit den Pflichtteilen `shop` und `account`, Formatversion bleibt 1, alte Stände
  ohne Laden gelten als beschädigt; eine Fabrik für neue Spielstände (R5, R12).
- **Daten aus der game_bible:** neue Vorlagen für Laden, Stadt und Figur, ein Importer in Python
  schreibt `.tres` nach `src/data/` (R6, R9). Dazu die Übersicht der Figuren (R16).
- **Bausteine des Adventures** ohne Inhalt: anklickbare Stelle, Sprechblase, Papierblatt (R8).
- **Spielbildschirm** mit Bildrahmen, Ladenbild und Bedienleiste mit Anzeige und Uhr (R10).
- **Style-Guide zuerst** für Büro, Papiere, Eingabefeld, Sprechblase, Uhr in der Leiste (R14).
- **Bilder zuletzt:** Platzhalter als echte Dateien, ersetzt in einer eigenen Phase (R11).

## Technical Context

**Language/Version**: GDScript, typisiert, Godot 4.7.2 (Compatibility); Python 3 für Importer und
Platzhalter.

**Primary Dependencies**: keine neuen in Godot. Bordmittel: `Resource`, `ResourceLoader`,
`LineEdit`, `Control` (Fokus, Mauszeiger, Tooltip), `TextureRect`, `SceneTree.change_scene_to_file()`.
Python mit `yaml` wie `regenerate_tables.py`, `Pillow` wie `tools/raster/`. Tests mit GUT 9.7.1,
der Importer mit `unittest`.

**Storage**: Spielstände wie bisher als JSON unter `user://spielstaende/`, erweitert um `shop` und
`account`. Spielinhalt in der game_bible, erzeugt nach `src/data/*.tres`.

**Testing**: GUT headless; Kerne ohne Szene, Bausteine in Probeszenen, das Büro mit eigener Session
und eigenem Ordner. Importer mit Beispielnotizen unter `tools/bible/fixtures/`. Oberfläche
zusätzlich mit Bildschirmfotos aus dem echten Fenster und von Hand nach [quickstart.md](quickstart.md).

**Target Platform**: Desktop: Windows, macOS, Linux; entwickelt und geprüft auf macOS.

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`)

**Performance Goals**: Jedes Blatt erscheint in unter 0,2 s (SC-001). Ein Spiel über 15 Jahre im
Test vorgespult mit Konto in unter 2 s.

**Constraints**:
- Vor der Anmeldung wird nichts geschrieben (FR-003, SC-007).
- Fahrplan der Zeitleiste bytegleich, egal welcher Laden (SC-005).
- Jede Miete genau einmal, auch über Speichern und Fortsetzen (SC-003, SC-004).
- Geld in Pfennig (AR-16); Sätze und Spielinhalt als Daten (AR-04, AR-20); Bausteine ohne Inhalt
  (AR-18).
- Nur Desktop mit Maus und Tastatur; Oberflächenraster 640 × 360, Bilder auf 320 × 180.

**Scale/Scope**: neun neue Kernklassen und Datenklassen, eine Fabrik; geändert `SaveGame`,
`GameSession`, `TitleScreen`, `GameScreen`. Drei neue Bausteine unter `src/ui/`, zwei weitere für
Bildrahmen und Bedienleiste, eine neue Szene mit vier Blättern. Zwei Python-Werkzeuge. Drei
Vorlagen und sieben Notizen in der game_bible. Zehn Bilder und eine Figur. Etwa 15 neue
Testdateien. Im Style-Guide etwa sechs neue oder geänderte Abschnitte.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Maus und Tastatur, Hover mit Mauszeiger und Tooltip, Tab und Enter in der Szene, Leertaste für die Uhr. Keine Touch-Eingabe. Renderer Compatibility unverändert | erfüllt | erfüllt |
| II. Klaus entscheidet | Plan nur mit Signaturen. Umgesetzt wird phasenweise auf Klaus' Auftrag. Namen, Texte und Steckbrief wählt Klaus (R17); Claudes Festlegungen stehen in research.md und `docs/offene-punkte.md`. Lernnotizen je Aufgabe | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit zehn Klärungen, davon drei zum Plan, dazu Klaus' Wunsch nach einer Übersicht der Figuren; eigener Branch; Systeme 05, 03, 10, 11 genannt; 17 Entscheidungen mit verworfenen Alternativen | erfüllt | erfüllt |
| IV. Ein Look | Style-Guide vor dem Bau der Oberfläche (R14, Phase 4); der Vertrag nennt keine Farben und Maße außer denen, die der Style-Guide schon hat (Bildrahmen 312 × 144). Bilder nach dem Leonardo-Workflow mit Prompt-Log (Phase 8) | erfüllt, mit Vorarbeit | erfüllt, mit Vorarbeit |
| V. Daten sauber halten | Stadt, Läden und Figuren in der game_bible nach eigenen Vorlagen, Preise als Range in DM, Freitext nur unter `## +…`; ins Spiel nur über den Importer | erfüllt | erfüllt |
| VI. Prüfen | Prüfer je Phase unten; was messbar ist, prüfen Tests. Bei der Checkliste lesen Text- und Stil-Prüfer die Wortlaute und Blätter, der Architektur-Prüfer Plan und Verträge | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7, GUT 9.7.1, Autoloads unverändert (`GameSession` bekommt Ablaufzustand und hält das Konto als Kern, AR-03). Die Zeitleiste meldet weiter nur; die Miete ist Mechanik eines Kerns, kein Ereignis (AR-07) | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch; `.uid` und `.import` der neuen Dateien werden committet; erzeugte `.tres` auch | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf. Zu Grundsatz IV ist Vorarbeit nötig (Phase 4).

## Prüfer je Phase

| Phase | Ändert | Prüfer |
|---|---|---|
| Phase 1: Vorbereitung (Godot-Referenz) | nichts davon | keine |
| Phase 2: Inhalt (Vorlagen, Notizen, Namen, Steckbrief, Sätze, Übersicht der Figuren) | Texte in der game_bible | Text |
| Phase 3: Kern (Daten- und Kernklassen, Spielstand, Fabrik, `GameSession`, Importer) | Code, Texte der Kerne | Architektur, Text |
| Phase 4: Style-Guide (R14) | Style-Guide | keine; der Style-Guide ist selbst der Maßstab, Klaus gibt frei |
| Phase 5: Bausteine (Hotspot, Sprechblase, Papierblatt, Bildrahmen, Bedienleiste, Platzhalter) | Sichtbares, Code | Stil, Architektur |
| Phase 6: Büro (Szene, vier Blätter, Titel angebunden) | Sichtbares, Texte, Code | Stil, Text, Architektur |
| Phase 7: Spielbildschirm (Laden, Anzeige, Uhr) | Sichtbares, Texte, Code | Stil, Text, Architektur |
| Phase 8: Bilder (Büro, Makler, Stadtplan, Läden) | Sichtbares | Stil |
| Phase 9: Selbsttest-Abläufe | Code der Werkzeuge, Texte des Selbsttests | Architektur, Text |

Dazu vor der Lückensuche die **Bestandsprüfung** über ganz `src/`, weil mit 010 die Schichten
Adventure und Wirtschaft beginnen (Fahrplan, D0; Klaus, 2026-10-29).

## Ausnahmen vom Leitfaden

| Regel | Stelle | Grund |
|---|---|---|
| AR-13 | `src/core/save/save_game.gd`, `FORMAT` | Zwei neue Pflichtteile (`shop`, `account`), die Formatversion bleibt trotzdem 1, und ein alter Spielstand bekommt nur den allgemeinen Grund. Vor der ersten Herausgabe keine Rücksicht auf alte Spielstände: „Ich möchte keinen Code drin haben, der Sonderlocken für alten Käse hat.“ (Klaus, 2026-10-29; freigegeben mit der Checkliste, CHK038). Kommentar an der Stelle und Zeile in der Tabelle „Ausnahmen“ des Leitfadens in Phase 3 |

Dazu in Phase 3: `res://core/shop/` kommt in `KERNORDNER` von `test_architektur.gd`, damit der Test
AR-01 auch für die neuen Kerne misst (CHK042).

Hinweis für Klaus: Mit diesem Feature gelten AR-16 bis AR-20 zum ersten Mal (Klaus, 2026-10-29).
Der Stand im Leitfaden ändert sich dafür von „gilt ab dem ersten Feature der Schicht …“ auf „gilt
seit 2026-10-29, Klaus“; das trägt Claude in Phase 1 ein.

## Project Structure

### Documentation (this feature)

```text
specs/010-ladeneroeffnung/
├── spec.md                      # Spezifikation, geklärt
├── recherche-geld.md            # Recherche zu Mieten und Startkapital, mit Quellen
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R17
├── data-model.md                # Phase 1: Daten, Kerne, Spielstand, Zustände
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── ladenwahl.md             # Büro, Blätter, Wege, Wortlaute, Bausteine
│   ├── spielbildschirm.md       # Laden, Anzeige, Uhr
│   ├── spielstand.md            # shop, account, Fabrik
│   └── game_bible.md            # Vorlagen, Notizen, Importer
├── checklists/
│   └── requirements.md          # Qualitätsprüfung der Spec
├── tasks.md                     # Aufgaben je Phase (/speckit-tasks)
└── lernnotizen.md               # entsteht bei der Umsetzung
```

### Source Code (repository root)

```text
docs/game_bible/
├── Templates/TEMPLATE_Laden.md, TEMPLATE_Stadt.md, TEMPLATE_Figur.md
├── Stadt/, Läden/, Figuren/     # Notizen
└── Läden.md, Figuren.md         # Übersichten
tools/
├── bible/importiere.py          # game_bible → src/data/
└── raster/platzhalter.py        # Platzhalterbilder
src/
├── core/shop/                   # ShopRules, Money, ShopOffer, CityData, FigureData,
│                                # ShopName, ShopOpening, ShopLease, ShopAccount
├── core/save/                   # SaveGame geändert, SaveGameFactory neu
├── core/game_session.gd         # Eröffnung, Konto, start_new(), leave()
├── data/                        # stadt.tres, laeden/, figuren/ (erzeugt)
├── ui/adventure/                # Hotspot, SpeechBubble
├── ui/paper/                    # PaperSheet
├── ui/frame/, ui/bar/           # Bildrahmen, Bedienleiste
├── scenes/opening/              # Büro mit Stadtplan, Exposé, Mietvertrag, Anmeldung, Texte
├── scenes/title/                # Gradwahl beginnt die Eröffnung
├── scenes/game/                 # Spielbildschirm
├── assets/images/buero/, laeden/
├── tools/selbsttest/            # Abläufe neues_spiel, ladenwahl; Fahrer über die Fabrik
└── test/                        # neue und geänderte Tests, Fixtures
```

**Structure Decision**: Das bestehende Godot-Projekt unter `src/` mit seinen Schichten: Kerne in
`src/core/`, geteilte Bausteine in `src/ui/`, Bildschirme in `src/scenes/`, Daten in `src/data/`.
Der neue Ordner `src/core/shop/` sammelt alles zum Laden; `src/scenes/opening/` ist das Büro, das ein
späterer Umzug wieder öffnet.

## Änderungen nach der Analyse

`/speckit-analyze` vom 2026-10-29 fand 13 Befunde, keinen kritischen; Klaus hat alle nach Empfehlung
freigegeben. Eingearbeitet:
- **U1** Vertrag Ladenwahl: Im Büro liegt immer das Blatt des Schritts vorn; was Stadtplan und
  Schreibtisch im Raum tun.
- **U2** Vertrag Ladenwahl: Tabelle Anlass → Auslöser für die Sätze des Maklers, `abschied` als
  linearer Ablauf.
- **I1** Spec: Parkplätze in FR-006, FR-007, FR-028.
- **D1** Tasks: T002a, T002b ziehen das Minuszeichen vor Phase 3.
- **D2** Tasks: T047 und T053 ziehen den Fahrer des Selbsttests mit.
- **C1** Tasks: T025 misst 15 Jahre in unter 2 s.
- **K1** Tasks: T048 prüft, dass der Übergang aus T026 weg ist.
- **A1 bis A6** Wortlaute in Spec, Quickstart und Vertrag Spielbildschirm.

## Complexity Tracking

Keine Verstöße gegen die Verfassung.
