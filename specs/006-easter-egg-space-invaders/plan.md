# Implementation Plan: Easter Egg 01: Space Invaders

**Branch**: `feature/006-easter-egg-space-invaders` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-easter-egg-space-invaders/spec.md`

## Summary

Auf dem Titel werden die drei grauen Knöpfe unter der Anzeige des Communicators drückbar. Wer sie der
Reihe nach drückt, spielt auf der Anzeige eine Welle Space Invaders: einfarbige Pixelmuster in
`tusche` auf `lcd`, Pfeile und Leertaste, drei Leben. Am Ende nennt die Ergebnisanzeige das Ergebnis, eine
Taste führt zurück zur Seite, auf der der Spieler war. Mit dem Feature kommt Ton ins Spiel:
Rechteck-Piepser aus einem Skript, über eigene Tonkanäle.

Technischer Ansatz (Details in [research.md](research.md), Verträge unter [contracts/](contracts/)):
- **Gehäusetasten** als Teil des Bausteins Communicator: Rechtecke im Gehäusebild, eingedrückt aus
  dem eigenen Bildausschnitt, Klick, Signal; die Sperre aus Feature 005 gilt mit (R1 bis R4).
- **Folge** `KeySequence` ohne Node im Titel; nur ein falscher Knopf bricht ab (R5).
- **Spiel** als Kern `InvadersGame` ohne Node mit festem Schritt und Seed, dazu die Seite
  `InvadersPage` für Eingabe, Bild und Ton (R6 bis R11).
- **Ton**: `tools/ton/make_sounds.py` erzeugt zehn WAV bytegleich; Kanäle `Master` und `Effekte`
  (R13 bis R15).
- **Style-Guide zuerst**: Gehäusetasten, „Spiel auf der Anzeige“ mit den Pixelmustern, „Ton“ (R12).

## Technical Context

**Language/Version**: GDScript, typisiert, Godot 4.7.2 (Forward+); Python 3 für das Tonskript

**Primary Dependencies**: keine neuen. Godot-Bordmittel: `Control._draw()`, `AtlasTexture` bzw.
`draw_texture_rect_region`, `AudioStreamPlayer`, `AudioStreamWAV`, Bus-Layout, `RandomNumberGenerator`.
Python: nur Standardbibliothek (`wave`, `struct`). Tests mit GUT 9.7.1.

**Storage**: keine; nichts wird gespeichert (FR-007).

**Testing**: GUT 9.7.1 headless. Kern Schritt für Schritt mit festem Seed; Seite mit erfundenen
Eingaben und `advance()`; Titel mit erfundenen Mausereignissen auf den Tasten. Ton headless über den
Dummy-Treiber: geprüft wird, welcher Player auf welchem Kanal anläuft, und an den Dateien, dass sie
ohne Stille beginnen (R15). Klang und Spielgefühl prüft Klaus von Hand nach [quickstart.md](quickstart.md).

**Target Platform**: Desktop: Windows, macOS, Linux; geprüft auf macOS (Apple Silicon).

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`)

**Performance Goals**: Spiel spielbereit 0,5 s nach dem dritten Knopf (SC-001); Ton höchstens 50 ms
nach dem Ereignis (SC-007); fester Schritt 1/60 s ohne Ruckeln (SC-003); zurück im Titel in höchstens
1 s (SC-006).

**Constraints**:
- Ohne Knopfdruck bleibt der Titel unverändert, alle bisherigen Tests grün (FR-006, SC-004).
- Der Communicator kennt den Titel weiterhin nicht (Feature 005, FR-007).
- Alles auf dem Bildraster der Anzeige (160 × 80 Bildpixel), nur `tusche` auf `lcd` (FR-030).
- Kein Hinweis auf das Easter Egg, Zeiger Pfeil (FR-005, FR-001b).
- Kein Spielstand, kein `GameSession` (FR-007). Nur Desktop mit Maus und Tastatur.

**Scale/Scope**: geändert: Communicator (Skript, Szene), Titel (Skript, Szene), `TitleTexts`.
Neu: `CaseKey`, `KeySequence`, `InvadersGame`, `InvadersSprites`, `InvadersPage` mit Szene, zwei
Probeszenen-Änderungen bzw. eine neue, `default_bus_layout.tres`, zehn WAV, `tools/ton/`. Neue
Testdateien: `test_ton.gd`, `test_invaders_game.gd`, `test_invaders_sprites.gd`,
`test_invaders_page.gd`, `test_key_sequence.gd`; geändert: `test_communicator.gd`,
`test_title_screen.gd`, `test_title_texts.gd`, `test_texte.gd`. Im Style-Guide ein erweiterter Baustein und zwei neue
Abschnitte.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Maus (Linksklick auf die Knöpfe, Zeiger) und Tastatur (Pfeile, Leertaste, Esc). Keine Touch-Eingaben, Forward+ bleibt | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Verträge nur mit Signaturen. Umgesetzt wird phasenweise auf Klaus' Auftrag, `/speckit-implement` nie. Tonskript, Style-Guide und Vermessung sind `[C]`, Godot-Code `[A]`, Abnahmen `[K]`; Lernnotizen zu jeder Task. Claudes Festlegungen stehen in research.md und `docs/offene-punkte.md` | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit 10 Klärungen (Specify, Clarify, Ton), eigener Branch, Systeme 10 und 11 genannt; 16 Entscheidungen mit verworfenen Alternativen in research.md | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Gehäusetasten, „Spiel auf der Anzeige“ mit Pixelmustern und „Ton“ kommen in Phase 1 in den Style-Guide, bevor gebaut wird (R12). Keine neue Farbe, kein neues Bild; der Leonardo-Workflow wird nicht gebraucht | erfüllt, mit Vorarbeit | erfüllt, mit Vorarbeit |
| V. Daten sauber halten | keine Spieldaten berührt; game_bible und Katalog unberührt | erfüllt | erfüllt |
| VI. Prüfen mit eigenem Maßstab | Phasen mit Sichtbarem oder Texten enden mit der Phasenprüfung; „Prüfer je Phase“ unten. Bei der Checkliste lesen die Prüfer Wortlaute (R10) und Zustände | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7, GUT 9.7.1, Projekt in `src/`. Kein neuer Autoload (R14); Zeitleiste und Spielablauf unberührt | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch. `.uid` und `.import` der neuen Skripte und WAV werden committet; `export_presets.cfg` bleibt unberührt | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf. Zu Grundsatz IV ist Vorarbeit nötig: Phase 1.

## Project Structure

### Documentation (this feature)

```text
specs/006-easter-egg-space-invaders/
├── spec.md                      # Spezifikation, geklärt
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R16
├── data-model.md                # Phase 1: Taste, Folge, Partie, Seite, Titel
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── gehaeusetasten.md        # Communicator: case_keys, CaseKey, Eindrücken, Klick
│   ├── ton.md                   # Tonskript, WAV, Tonkanäle
│   ├── invaders.md              # Kern, Muster, Seite, Texte
│   └── titelbildschirm.md       # KeySequence, Einbau in den Titel, Rückweg
├── checklists/
│   ├── requirements.md          # Qualitätsprüfung der Spec
│   └── review.md                # Review der Anforderungen, 34 Punkte, freigegeben
├── tasks.md                     # Aufgaben je Phase (/speckit-tasks)
└── lernnotizen.md               # entsteht bei der Umsetzung
```

### Source Code (repository root)

```text
tools/ton/                        # neu [C]: make_sounds.py, README.md
src/
├── default_bus_layout.tres       # neu: Master, Effekte
├── assets/sounds/                # neu: zehn WAV mit .import
├── ui/communicator/              # geändert: communicator.gd/.tscn; neu case_key.gd
├── scenes/title/
│   ├── key_sequence.gd           # neu
│   ├── invaders/                 # neu: invaders_game, invaders_sprites, invaders_page (.gd/.tscn)
│   ├── title_screen.gd/.tscn     # geändert
│   └── title_texts.gd            # geändert
└── test/                         # fünf neu, drei geändert; fixtures/invaders_probe neu, communicator_probe geändert, ton_pruefsummen.txt
```

**Structure Decision**: Die Gehäusetasten gehören zum Baustein in `src/ui/communicator/`, weil jedes
Gehäuse eigene Tasten hat. Folge und Spiel gehören zum Titel und liegen in `src/scenes/title/`, das
Spiel in einem eigenen Unterordner. Das Tonskript liegt neben `tools/raster/` unter `tools/ton/`.

## Complexity Tracking

Keine Einträge, die Prüfung der Verfassung zeigt keine Verstöße.

## Vorarbeiten vor dem Bauen

1. **Style-Guide** (R12), Phase 1: Claude schreibt die drei Teile, Klaus gibt sie frei, auch die
   Pixelmuster und die Töne.
2. **Vermessung** der drei Knöpfe an einer Montage ×8 (R2), Phase 1, `[C]`.
3. Möglich als `[K]`: Klaus zeichnet die Pixelmuster der Außerirdischen selbst (R8). Ohne Wunsch
   entwirft Claude sie.

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit grünen Tests, Lernnotizen und Klaus' Abnahme; erst dann folgt die nächste.
Die Phasen laufen streng nacheinander (Grundsatz II).

| Phase | Inhalt | Story |
|---|---|---|
| 1 | Vorarbeit: Style-Guide (Gehäusetasten, Spiel auf der Anzeige mit Pixelmustern, Ton) und Vermessung der Knöpfe. Kein Code | Vorarbeit |
| 2 | Ton: `tools/ton/make_sounds.py` und README `[C]`; zehn WAV; `default_bus_layout.tres` und `test_ton.gd` `[A]`; Klaus hört die Töne an | Grundlage US2, US1 |
| 3 | Spielkern: `InvadersGame`, `InvadersSprites`, `test_invaders_game.gd`, `test_invaders_sprites.gd`. Nichts Sichtbares | US2 |
| 4 | Spielseite: `InvadersPage` mit Szene, Eingabe, Malen, Tönen, Ergebnisanzeige, Anhalten; Texte in `TitleTexts`; Probeszene; `test_invaders_page.gd`. Klaus spielt in der Probeszene und stellt Tempi ein | US2, US3 (Teil) |
| 5 | Knöpfe und Titel, in zwei Teilen (ki_dev Punkt 4): erst Gehäusetasten am Communicator mit Probeszene und `test_communicator.gd`; dann `KeySequence`, Einbau in den Titel, Rückweg, `test_key_sequence.gd`, `test_title_screen.gd` | US1, US3 |
| 6 | Abschluss: Lückensuche mit `/speckit-converge`; Gesamtabnahme; `docs/features/Features.md`; `CLAUDE.md` (Tabelle „Aufbau“: `src/assets/sounds/`, `tools/ton/`) nur mit Klaus' OK; danach Spielbeschreibung prüfen (`communicator.md`, `titel-und-hauptmenue.md`, `darstellung.md`, `build-und-tests.md`, neu wohl `ton.md`; Index) und Klaus vorlegen; zuletzt das Tagebuch | – |

Phase 3 hängt an Phase 1 (Muster und Maße), Phase 4 an 2 und 3, Phase 5 an 4.

## Änderungen nach der Checkliste

Aus [checklists/review.md](checklists/review.md), 34 Punkte, davon 14 aus der Prüfung des Vertrags
durch Stil- und Text-Prüfer; von Klaus am 2026-10-27 alle freigegeben. Eingearbeitet in Spec
(Clarifications „Review 2026-10-27“, FR-001a, FR-001b, FR-011 bis FR-016, FR-020, FR-022, Randfälle,
SC-002, SC-003), research.md (R3, R7, R9 bis R13), Datenmodell, Verträge und Quickstart. Das Ende
heißt seitdem Ergebnisanzeige. Phase 1 hat dadurch mehr Inhalt für den Style-Guide (R12): die
vollständige Ausnahme für die Gehäusetasten, Änderungen an zwei Sätzen im Baustein Communicator, den
Abschnitt „Spiel auf der Anzeige“ mit Innenrand, Lagen, Ergebnisanzeige und Textregeln, und einen
Verweis im Abschnitt Sprache.

## Änderungen nach der Analyse

Aus `/speckit-analyze` am 2026-10-27 mit 32 Befunden (0 kritisch, 4 hoch, 14 mittel, 14 niedrig),
gelesen von einem unabhängigen Prüfer; Claude hat die Befunde zum Code (C1 bis C5, D1) in
`title_screen.gd` und `communicator.gd` nachgeprüft. Klaus hat alle Empfehlungen freigegeben. Die
wichtigsten:
- **I1** (hoch): Gezählt wird einschließlich; die Kanone belegt die Zeilen 73 bis 77, gelandet ist
  der Block, wenn seine unterste Zeile 73 erreicht.
- **V1** (hoch): Tasks und Verträge nennen keine Werte mehr, die der Style-Guide hält; R7 und R13
  werden nach T002 als übernommen markiert.
- **U1** (hoch): Nach `finished` und verborgen taktet die Seite nicht; sonst spielte der Kern im
  Hintergrund weiter Marschtöne.
- **A1** (hoch): Der Landetest (frühestens nach 1 Minute) steht jetzt auch im Vertrag.
- **C1 bis C5**: erst zeigen, dann `start()`; `_hide_hint()` des Titels vergisst die Meldung;
  Esc-Wache im Titel, solange das Spiel zu sehen ist; nur `Keys` aus `_page_list()` nehmen; Fokus nur
  zurückholen, wenn die Seite noch sichtbar ist.
- **I2**: `case_keys` ist leer, nur der Titel setzt die drei Tasten.
- **M1 bis M4, U2 bis U7**: „beim Start des Spiels“; Rand des Blocks nach den lebenden; der Block
  steht in der Pause nach einem Treffer; Kürzel führen nicht weiter; Tempo der Kanone; Takt in ganzen
  Schritten; Leben in der Kopfzeile; Import der WAV als PCM; Versalien im Test der Anrede.
- **A2, A3**: SC-001 und SC-006 gemessen in T031, die Bildrate in T022; SC-007 ist eine Abnahme von
  Hand (T009, T024).
- **R1, R2, I3 bis I7, D1 bis D3, V2, V3**: Reihenfolge in Phase 6, `[P]` nur, wo es stimmt,
  Nummern und Ordnung in der Spec, Lernnotiz auch zum Tonskript, Begründung für Phase 2 ohne
  Prüfer.

Eingearbeitet in Spec (Clarifications „Analyse 2026-10-27“), research.md (R1, R3, R6, R7, R10, R13),
Datenmodell, Verträge, hier, in tasks.md und bei CHK005 in der Checkliste.

## Prüfer je Phase

Jede Phase mit Sichtbarem oder Texten endet mit der [C]-Aufgabe „Phasenprüfung“ durch
`/dcl-phasenpruefung` vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`).

| Phase | Ändert | Prüfer | Maßstab für die Prüfer |
|---|---|---|---|
| 1 Style-Guide | den Maßstab selbst | keine; Klaus nimmt ab | – |
| 2 Ton | Töne, nichts Sichtbares; das Skript gibt nur Dateinamen, Längen und Größen aus, die README ist Doku für Entwickler, kein Text im Spiel (Analyse, V3) | keine; Klaus hört ab | Abschnitt „Ton“ |
| 3 Spielkern | nichts Sichtbares | keine | – |
| 4 Spielseite | Spiel und Ergebnisanzeige auf der Anzeige, neue Texte | Stil, Text | „Spiel auf der Anzeige“, Baustein Communicator, `tokens.json`, `Sprache.md`; Bildschirmfotos der Probeszene: Spiel läuft, Ergebnisanzeige gewonnen und verloren |
| 5 Knöpfe und Titel | Gehäuse mit eingedrückter Taste, Titel mit Spiel | Stil | Gehäusetasten, Bewegung, Titel; Bildschirmfotos aus dem echten Fenster |
| 6 Abschluss | Doku | bei der Lückensuche Stil und Text einmal über das ganze Feature | wie 4 und 5 |
