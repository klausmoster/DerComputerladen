# Implementation Plan: Godot- und Spielarchitektur mit Prüf-Agent

**Branch**: `feature/008-architektur` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-architektur/spec.md`

## Summary

Klaus legt in einem Architektur-Leitfaden fest, wie „Der Computerladen“ gebaut wird: fünf
Godot-Prinzipien, die Muster aus „Game Programming Patterns“, die das Spiel braucht, und ein Vorbild
je Schicht (SCUMM und Thimbleweed Park für das Adventure, Factorio für die Wirtschaft). Ein neuer
Architektur-Prüfer prüft Pläne und Code-Phasen dagegen, so wie Stil- und Text-Prüfer gegen den
Style-Guide. Er prüft einmal den ganzen Bestand. Was davon ein System betrifft, behebt der
Godot-Agent ohne Änderung am Verhalten; Messbares wird Test.

Technischer Ansatz (Details in [research.md](research.md), Verträge unter [contracts/](contracts/)):
- **Leitfaden** als eine Datei `docs/architektur-leitfaden.md` mit festen Nummern `AR-NN`; Klaus
  entscheidet jede Regel in einer Durchsicht (R1, R2, R12).
- **Ausnahmen** mit Kommentar an der Stelle und Zeile im Leitfaden (R3).
- **Prüfer** als Subagent `architektur-pruefer` mit `Read, Grep, Glob`, drei Aufträgen (Phase, Plan,
  Bestand) und eigener Fehlerprobe (R4, R8).
- **Bestandsprüfung** in drei gleichzeitigen Läufen nach Schicht (R5).
- **Tests** `test_architektur.gd` für Kerne ohne Node, genau diese Autoloads, keinen Weg nach oben;
  erst nach dem Bestand, mit Listen für Ausnahmen und offene Behebungen (R6, R7).
- **Behebung** nur innerhalb eines Systems und gemessen: Fahrpläne bytegleich, Startprobe still
  (R9).
- **Arbeitsweise** an den Stellen, an denen die anderen Prüfer stehen; Grundsatz VI über
  `/speckit-constitution` (R10).

## Technical Context

**Language/Version**: Markdown für Leitfaden, Arbeitsweise und Agent; GDScript, typisiert, Godot
4.7.2 für die Tests und die Behebung

**Primary Dependencies**: keine neuen. Claude Code Subagents (`.claude/agents/`), Spec Kit 1.2.3 mit
den Vorlagen unter `.specify/templates/overrides/`, GUT 9.7.1

**Storage**: keine; nur Dateien im Repo

**Testing**: GUT 9.7.1 headless für `test_architektur.gd`, jede Prüffunktion mit Fehlerprobe. Der
Prüfer selbst wird mit einer Fehlerprobe aus fünf Dateien gemessen (SC-002). Die Behebung wird an
festen Größen gemessen: Testzahl, Startprobe, Fahrpläne für drei Seeds, ein Spielstand (R9)

**Target Platform**: Desktop: Windows, macOS, Linux; geprüft auf macOS (Apple Silicon)

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`) und Arbeitsweise mit KI

**Performance Goals**: Ein Lauf des Prüfers je Code-Phase plus eine Nachprüfung (SC-005); der
Leitfaden passt ganz in einen Lauf (20 bis 30 Regeln)

**Constraints**:
- Die Behebung ändert kein Verhalten (FR-027, FR-028).
- Der Prüfer ändert nichts (FR-010).
- Spec Kits eigene Vorlagen und die Skills `speckit-*` bleiben unverändert (R10).
- Verfassung und `CLAUDE.md` nur auf Klaus' Beschluss (FR-023).
- 008 wird erst nach 007 gemergt (Spec, Assumptions).

**Scale/Scope**: Bestand am 2026-10-28: 58 Skripte mit 19.662 Zeilen und 14 Szenen in `src/`
ohne `addons/` und `test/`. Neu: Leitfaden, Agent, Fehlerprobe, Bestandsbericht,
`test_architektur.gd`. Geändert: `ki_pruefung.md`, `ki_dev.md`, `ki_workflow/README.md`,
`dcl-phasenpruefung`, Aufgaben-Vorlage, `godot-entwickler.md`, Verfassung, auf Klaus' OK `CLAUDE.md`;
in Phase 5 die Skripte, die Klaus zur Behebung freigibt; `docs/spielbeschreibung/architektur.md`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | nichts Sichtbares; die Behebung ändert kein Verhalten, Forward+ bleibt | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Leitfaden, Agent, Arbeitsweise und Bestandsprüfung sind `[C]`, Tests und Behebung `[A]`, Regeln, Verfassung und Abweichungen entscheidet Klaus `[K]`. Phasenweise, `/speckit-implement` nie; Lernnotizen zu jeder Aufgabe, auch zu Leitfaden und Prüfer | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit 10 Klärungen, eigener Branch, System 11 genannt; 12 Entscheidungen mit verworfenen Alternativen in research.md. Die Spec nennt Godot-Begriffe, weil sie selbst Gegenstand sind (checklists/requirements.md) | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | nichts Sichtbares; der Leitfaden regelt den Aufbau, nicht das Aussehen, und schreibt keine Werte aus dem Style-Guide ab | erfüllt | erfüllt |
| V. Daten sauber halten | game_bible und Katalog unberührt; die Fahrpläne bleiben bytegleich (R9) | erfüllt | erfüllt |
| VI. Prüfen mit eigenem Maßstab | Wird in 008 erweitert (FR-023). Bis dahin gilt 2.2.0: Phasen mit Texten, auch Testmeldungen, bekommen den Text-Prüfer; die Phase mit Code (5) schon den Architektur-Prüfer. Bei der Checkliste von 008 gibt es keine Wortlaute und den Prüfer noch nicht (R11) | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7, GUT 9.7.1, Projekt in `src/`. Kein neuer Autoload; die vier bleiben und werden im Leitfaden und im Test festgeschrieben | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch. Die Änderung an der Verfassung läuft über `/speckit-constitution` mit Versionssprung; Spec Kits Vorlagen bleiben unberührt, nur `overrides/` ändert sich | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf.

## Project Structure

### Documentation (this feature)

```text
specs/008-architektur/
├── spec.md                      # Spezifikation, geklärt
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R12
├── data-model.md                # Phase 1: Regel, Ausnahme, Befund, Bericht
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── leitfaden.md             # Aufbau des Leitfadens, Form einer Regel
│   ├── architektur-pruefer.md   # Agent: Kopf, Anweisung, Bericht, Schwere
│   ├── architektur-tests.md     # test_architektur.gd
│   └── arbeitsweise.md          # Verfassung, ki_workflow, Skill, Vorlage, Godot-Agent
├── checklists/
│   ├── requirements.md          # Qualitätsprüfung der Spec
│   └── review.md                # Review der Anforderungen, 19 Punkte, freigegeben
├── fehlerprobe/                 # Phase 2: fünf Proben
├── fehlerprobe-loesung.md       # Phase 2: Lösung, außerhalb des Ordners der Probe
├── bestandsbericht.md           # Phase 3
├── tasks.md                     # Aufgaben je Phase (/speckit-tasks)
└── lernnotizen.md               # entsteht bei der Umsetzung
```

### Source Code (repository root)

```text
docs/
├── architektur-leitfaden.md                 # neu [C], Regeln entscheidet [K]
├── recherche/architektur-quellen.md         # neu [C]: Quellen
├── ki_workflow/ki_pruefung.md, ki_dev.md, README.md   # geändert [C]
└── spielbeschreibung/architektur.md         # geändert nach der Behebung
.claude/
├── agents/architektur-pruefer.md            # neu [C]
├── agents/godot-entwickler.md               # geändert [C]
└── skills/dcl-phasenpruefung/SKILL.md       # geändert [C]
.specify/
├── memory/constitution.md                   # Grundsatz VI, [K] beschließt
└── templates/overrides/tasks-template.md    # geändert [C]
src/
├── test/test_architektur.gd                 # neu [A]
└── …                                        # Phase 5: nur freigegebene Behebungen [A]
```

**Structure Decision**: Der Leitfaden liegt direkt unter `docs/`, neben `game_design.md`, weil er wie
das GDD für das ganze Spiel gilt und keinem Feature gehört. Die Quellen liegen bei den anderen
Recherchen in `docs/recherche/`. Bestandsbericht und Fehlerprobe gehören zum Feature und bleiben in
`specs/008-architektur/`.

## Complexity Tracking

Keine Einträge, die Prüfung der Verfassung zeigt keine Verstöße.

## Ausnahmen vom Leitfaden

Keine; den Leitfaden gibt es noch nicht. Der Abschnitt steht hier, weil künftige Pläne ihn haben;
verlangt wird er von Grundsatz VI in der Fassung 2.3.0 (Vertrag [arbeitsweise.md](contracts/arbeitsweise.md)),
nicht von einer Plan-Vorlage (Analyse, C6).

## Vorarbeiten vor dem Bauen

1. Die Recherche `docs/recherche/architektur-quellen.md` liegt vor (R12) und wird mit dem Plan
   committet.
2. Möglich als `[K]`: Klaus schreibt einzelne Regeln selbst oder sucht die Beispiele im Code, um den
   Aufbau kennenzulernen. Ohne Wunsch schreibt Claude alles als Entwurf.

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit Klaus' Abnahme und einem Commit; erst dann folgt die nächste. Die Phasen laufen
streng nacheinander (Grundsatz II).

| Phase | Inhalt | Story |
|---|---|---|
| 1 | Leitfaden: Claude schreibt den Entwurf aus Recherche und Spec, mit Beispielen aus dem Code; Klaus geht ihn durch und entscheidet je Regel (R2); messbare Regeln markiert. Kein Code | US1 |
| 2 | Prüfer und Arbeitsweise: Agent `architektur-pruefer`; Fehlerprobe mit fünf Proben und Lauf (SC-002, höchstens zwei Wiederholungen); Planprobe am Plan von 006 (Story 3); `ki_pruefung.md`, `ki_dev.md`, README, Skill, Aufgaben-Vorlage, `godot-entwickler.md`; Vorschlag für Grundsatz VI, den Klaus über `/speckit-constitution` beschließt; `CLAUDE.md` nur mit OK. Der neue Agent-Typ steht erst in einer neuen Sitzung bereit; Fehler- und Planprobe laufen deshalb über einen allgemeinen Agent, der die Datei des Prüfers liest | US2, US3 |
| 3 | Bestandsprüfung: vorher fragt Claude, ob 007 gemergt ist, und holt `main` mit Klaus' OK in den Branch; drei Läufe über Skripte, Szenen, Resources und `project.godot`, Claude prüft nach, `bestandsbericht.md`; Klaus entscheidet je Abweichung; Einträge in `Feature_Ideas.md` für große Umbauten; Ausnahmen in den Leitfaden. Danach ergänzt Claude die Aufgaben von Phase 5 | US4 |
| 4 | Tests: `test_architektur.gd` mit Listen aus dem Bericht und Fehlerprobe; erste echte Phasenprüfung mit dem Architektur-Prüfer | FR-008 |
| 5 | Behebung, notfalls in zwei Teilen, erst wenn 007 gemergt und `main` im Branch ist: die freigegebenen Abweichungen; `BIS_BEHEBUNG` wird leer; feste Größen und zwei Spielstände vorher und nachher (R9) | US5 |
| 6 | Abschluss: Lückensuche mit `/speckit-converge`, der Architektur-Prüfer einmal über das ganze Feature; Gesamtabnahme; Zählung und Auswertung in `ki_pruefung.md` (SC-007 vorbereitet); `Features.md`; Spielbeschreibung prüfen (`architektur.md`, `build-und-tests.md`, README) und Klaus vorlegen; Tagebuch. Merge erst nach 007 | – |

Phase 2 hängt an 1, Phase 3 an 2, Phase 4 an 3 (Listen), Phase 5 an 3 und 4 und an 007.

## Änderungen nach der Analyse

Aus `/speckit-analyze`, gelesen von einem unabhängigen Prüfer, von Claude nachgeprüft; Klaus hat am
2026-10-28 alle 18 Empfehlungen freigegeben. Keiner kritisch, keiner gegen die Verfassung; die
Zahlen in research.md hat der Prüfer am Code bestätigt.

| ID | Schwere | Befund | Änderung |
|---|---|---|---|
| I1 | hoch | Der Code von 007 (`src/tools/selbsttest/`) fehlt in Bestand, FR-027 und Tests | Selbsttest zählt als Werkzeug; Lauf „Werkzeuge“ in T023; Ordner in FR-027 und R9; in T035 Nachprüfung über den Code von 007 und Angleichen der Testlisten |
| I2 | mittel | 007 ändert dieselben Dateien der Arbeitsweise wie Phase 2 | vor T012 Stand von 007 prüfen, gemergt ⇒ `main` zuerst herein; danach Tasks auf die Regel „[A] Selbsttest-Abläufe anpassen“ durchsehen |
| I3 | mittel | Ausnahme ohne Skript widersprüchlich | Datenmodell, Prüfer-Vertrag Punkt 5, Begriffe der Spec an CHK010 angeglichen |
| A4 | mittel | Fehlerprobe erwartet Befunde zu Gemessenem | der Auftrag zur Fehlerprobe nennt keine Regel als gemessen |
| U5 | mittel | Lösung im Ordner der Probe | `fehlerprobe-loesung.md` daneben, Lesen im Auftrag verboten |
| C6 | mittel | Plan-Vorlage fehlt | FR-021 eingeschränkt; „Ausnahmen vom Leitfaden“ verlangt Grundsatz VI |
| U7 | mittel | keine Liste für vorgemerkte Abweichungen | `VORGEMERKT` im Test-Vertrag und Datenmodell |
| I8 | niedrig | SC-005 ohne Teil-Wiederholungen | SC-005 ergänzt |
| I9 | niedrig | drei Namen für eine Liste | überall `ERLAUBT_NACH_OBEN` |
| I10 | niedrig | R4 ohne Resources | R4 ergänzt |
| I11 | niedrig | Spec sagt „Kopie“, R8 verwirft sie | Unabhängiger Test von US2 angeglichen |
| I12 | niedrig | Reihenfolge ohne Tests | Annahme ergänzt |
| C13 | niedrig | zwei weitere Stellen in `ki_pruefung.md` | in den Vertrag arbeitsweise.md aufgenommen |
| U14 | niedrig | Fahrpläne vorher und nachher in einer Datei | getrennte Ordner im Scratchpad |
| U15 | niedrig | Ort der Spielstände offen | per Skript in `user://test_008_behebung/`; Klaus legt für die Handprobe selbst einen an |
| C16 | niedrig | SC-005 ohne Task | in T042 |
| I17 | niedrig | `review.md` fehlt in der Struktur | ergänzt |
| U18 | niedrig | Platzhalter bis T028 | nach T028 Spec, Tasks und Verträge abgleichen (in T028) |

## Änderungen nach der Checkliste

Aus `checklists/review.md`, von Klaus am 2026-10-28 alle 19 Punkte nach Vorschlag freigegeben:

| Punkt | Änderung | Wo |
|---|---|---|
| CHK001 | Story 2 meldet einen Aufruf nach oben; das Autoload ohne Grund gehört zur Planprüfung | Spec US2, US3 |
| CHK002 | „Code“ = Skripte, Szenen, Resources unter `src/`; Tests lösen den Architektur-Prüfer nicht aus; Phase 4 nur Text-Prüfer | Spec FR-016, FR-019; Prüfer je Phase; Verträge |
| CHK003 | Annahme zu Stil- und Text-Prüfer an den Plan angeglichen | Spec, Assumptions |
| CHK004 | SC-005 gilt für Features nach 008; Bestand ausgenommen | Spec SC-005 |
| CHK005 | Planprobe am Plan von 006 in Phase 2 | Phase 2, R8, Quickstart |
| CHK006 | Fehlerprobe höchstens zweimal wiederholt, dann entscheidet Klaus | Spec SC-002, R8 |
| CHK007 | Bestand mit Resources und `project.godot` | Spec FR-025, SC-003, R5, Quickstart |
| CHK008 | vor Phase 3 `main` mit 007 in den Branch, mit Klaus' OK | Spec, Assumptions; Phase 3 |
| CHK009 | Regeln als Tabelle mit Empfehlung, Antwort „alle wie Vorschlag außer …“ | R2 |
| CHK010 | Ausnahme ohne Skript: nur die Zeile in der Tabelle, mit Knoten | R3, Vertrag leitfaden |
| CHK011 | ein Lauf, der nicht alles schafft, wird geteilt und nur das Fehlende wiederholt | R5 |
| CHK012 | „ein System“ = ein Ordner, keine geänderte Schnittstelle nach außen | Spec FR-027, R9 |
| CHK013 | zwei gesicherte Spielstände belegen „lädt wie vorher“ | Spec FR-028, R9, Quickstart |
| CHK014 | „vorgemerkt“ = in `Features.md` und `Feature_Ideas.md` | Spec FR-003 |
| CHK015 | Tabelle „Schwere“ auch im Leitfaden | Spec FR-011, Vertrag leitfaden |
| CHK016 | SC-006 und SC-007: in 008 an Vorlage und Skill belegt, Ergebnis später nachgetragen | Spec |
| CHK017 | SC-001 zählt ein kurzes Skript, kein Test | Quickstart Phase 1 |
| CHK018 | neuer Agent erst in neuer Sitzung; Proben über allgemeinen Agent | Phase 2 |
| CHK019 | Behebung erst mit 007 im Branch | Spec, Assumptions; Phase 5 |

## Prüfer je Phase

Jede Phase mit Sichtbarem, Texten oder Code endet mit der [C]-Aufgabe „Phasenprüfung“ durch
`/dcl-phasenpruefung` vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`; ab Phase 2 mit dem
Architektur-Prüfer).

| Phase | Ändert | Prüfer | Maßstab für die Prüfer |
|---|---|---|---|
| 1 Leitfaden | den Maßstab selbst | keine; Klaus nimmt ab | – |
| 2 Prüfer und Arbeitsweise | Agent, Doku, Vorlage; kein Code | keine; die Fehlerprobe misst den Prüfer | – |
| 3 Bestandsprüfung | nur den Bericht und den Leitfaden | keine; der Lauf ist selbst die Prüfung | – |
| 4 Tests | ein Testskript, deutsche Testmeldungen; Tests lösen den Architektur-Prüfer nicht aus (FR-016) | Text | Abschnitt „Sprache“ des Style-Guides für die Meldungen |
| 5 Behebung | Skripte und Szenen, nichts Sichtbares | Architektur; Stil nur, wenn sich wider Erwarten Sichtbares ändert | Leitfaden, Bestandsbericht |
| 6 Abschluss | Doku | bei der Lückensuche Architektur einmal über das ganze Feature | Leitfaden |
