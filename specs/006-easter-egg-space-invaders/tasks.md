---

description: "Taskliste für Feature 006 Easter Egg 01: Space Invaders"
---

# Tasks: Easter Egg 01: Space Invaders

**Input**: Design-Dokumente aus `specs/006-easter-egg-space-invaders/`

**Prerequisites**: plan.md, spec.md, research.md (R1 bis R16), data-model.md,
contracts/gehaeusetasten.md, contracts/ton.md, contracts/invaders.md, contracts/titelbildschirm.md,
quickstart.md, checklists/review.md

**Tests**: Die Verträge legen GUT-Tests fest, je im Abschnitt „Tests“. Sie entstehen mit der Logik
und müssen vor jeder Abnahme grün sein, zweimal hintereinander mit derselben Zahl von Prüfungen.
Klang, Spielgefühl und Oberfläche prüft Klaus zusätzlich von Hand nach quickstart.md.

**Organization**: Die Tasks folgen den sechs Phasen aus plan.md, „Umsetzungsphasen“: Phase 1
Style-Guide und Vermessung, Phase 2 Ton, Phase 3 Spielkern, Phase 4 Spielseite (US2, US3 zum Teil),
Phase 5 Knöpfe und Titel (US1, US3), Phase 6 Abschluss. Umgesetzt wird nach Verfassung 2.2.0,
Grundsatz II: eine Phase nach der anderen, nur auf Klaus' Auftrag, `/speckit-implement` nie. Jede
Phase endet mit Klaus' Abnahme; jede Phase mit Sichtbarem oder Texten hat davor die [C]-Aufgabe
„Phasenprüfung“ (plan.md, „Prüfer je Phase“). Kürzel wie „CHK004“ verweisen auf die Checkliste
[review.md](checklists/review.md), „R7“ auf [research.md](research.md).

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Entscheidungen, Freigaben, Abnahmen, was er selbst bauen will.
  - `[A]` Godot-Agent `godot-entwickler`: Szenen, Nodes, GDScript, Bus-Layout, Tests.
  - `[C]` Claude: Style-Guide, Vermessung, Tonskript, Doku, Phasenprüfung, Review.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: zugehörige User Story aus spec.md (US1 Geheimnis finden, US2 eine Runde spielen, US3
  zurück zum Titel); Grundlagen tragen keine

## Path Conventions

- Godot-Projekt unter `src/`, Tests unter `src/test/`, Probeszenen unter `src/test/fixtures/` (GUT
  9.7.1; `test/*` ist vom Export ausgeschlossen)
- Gehäusetasten unter `src/ui/communicator/`, Spiel unter `src/scenes/title/invaders/`, Folge und
  Titel unter `src/scenes/title/`, Töne unter `src/assets/sounds/`, Tonskript unter `tools/ton/`
- Pfade, Klassen, Signale und Signaturen laut den Verträgen unter [contracts/](contracts/); was dort
  nicht steht, gilt aus den Verträgen von Feature 005
- Werte für Maße, Lagen, Muster, Töne und Pegel kommen nach T001 aus dem Style-Guide, nicht aus
  diesen Tasks (Grundsatz IV)

---

## Phase 1: Style-Guide und Vermessung (Vorarbeit, kommt vor allem anderen)

**Purpose**: Was Phase 2 bis 5 zeigen und spielen, steht vorher im Style-Guide (research.md, R12).
Kein Code.

- [x] T001 [C] Die drei grauen Knöpfe in `src/assets/images/organizer_1991.png` vermessen: Montage
  ×8 mit Raster und Koordinaten in den Scratchpad, je Knopf Rechteck, Fläche, Vorderkante, Spalt
  links und darüber, ob es eine helle linke Spalte gibt (R2, R3; CHK020, CHK029). Ergebnis als
  Tabelle in research.md, R2, mit Verweis auf die Montage; die Montage selbst kommt nicht ins Repo.
- [x] T002 [C] Style-Guide ergänzen, https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX, Dateien
  unter `project/`, nach research.md, R12:
  - Baustein **Communicator**: Abschnitt „Gehäusetasten“ mit den Rechtecken aus T001, Eindrücken
    (R3), Klick; die Ausnahme von allen Regeln für anklickbare Stellen mit Grund (kein
    Zeigerwechsel, kein `signalgelb`, kein Tooltip, kein Hinweis, kein Relief; CHK002, CHK003);
    „Das Gehäuse ist reine Grafik“ wird „Das Gehäuse ist Grafik bis auf seine Gehäusetasten“
    (CHK001); G-03 nennt die drei grauen Tasten (CHK027); eine Seite ist ein Menü, eine Liste oder
    das Spiel, während des Spiels ist der Hinweis verborgen (CHK021, CHK027).
  - Neuer Abschnitt **Spiel auf der Anzeige** mit Vorschau: Feld 160 × 80 Bildpixel, Innenrand,
    Kopfzeile in `drucker`, Maße, Lagen und Tempi (R7; CHK023), die Pixelmuster `alien_a`,
    `alien_b`, `alien_c` (je zwei Bilder), `cannon`, `shot`, `bomb`, `explosion`, `life` als
    eigene Entwürfe (R8; CHK012, CHK013), Ergebnisanzeige (R10; CHK024), nur `tusche` auf `lcd`,
    kein Fokusrahmen, Zeiger Pfeil (CHK022, CHK025), „Bewegung reduzieren“ gilt nicht (CHK026),
    `raster-*` gilt nicht im Feld (CHK028), Regeln für Texte im Spiel und führende Nullen (CHK033,
    CHK034).
  - Neuer Abschnitt **Ton**: Klang Rechteckwelle, die zehn Töne mit Tonhöhe und Länge (R13),
    Anfang ohne Stille, 5 ms Ausblenden, Spitzenpegel, Tonkanäle `Master` und `Effekte` mit Pegel
    (R14), ein Player für den Marschtakt (CHK015), das Menü bleibt stumm.
  - Abschnitt **Sprache**: Verweis auf die Regeln für Texte im Spiel (CHK034).
  - Dazu aus der Analyse: Tempo der Kanone (U2), Takt in ganzen Schritten (U3), Rand des Blocks nach
    den lebenden (M2), der Block steht in der Pause nach einem Treffer (M3), senkrechte Lage von
    Punkten und Leben in der Kopfzeile, welche Leben sie zeigt, Explosion an der Stelle der Kanone
    (U5), Zählweise einschließlich mit der Kanone in den Zeilen 73 bis 77 (I1).

  Danach markiert Claude die Tabellen in research.md, R7 und R13, als „übernommen in den Style-Guide
  am …“; ab dann gilt nur noch der Style-Guide (Analyse, V1).

  Vorher liest Claude die betroffenen Dateien neu und ändert nur diese; danach bekommt Klaus den
  Link und eine Liste der Änderungen. Wünscht Klaus, die Pixelmuster selbst zu zeichnen (plan.md,
  „Vorarbeiten“), wird daraus vorher eine `[K]`-Aufgabe, und Claude übernimmt seine Muster.
- [x] T003 [K] Phase 1 abnehmen: Montage und Rechtecke, die Ausnahme für die Gehäusetasten, die
  Pixelmuster, Maße und Tempi und die Töne auf dem Papier freigeben oder ändern lassen.

Erledigt am 2026-10-27, von Klaus abgenommen: Style-Guide Version 50. Neu sind im Baustein
Communicator der Abschnitt „Gehäusetasten“ mit den vermessenen Rechtecken (11 × 8, 12 × 8, 12 × 8
Bildpixel, keine eigene Lichtkante) und der vollständigen Ausnahme, der Baustein „Spiel auf der
Anzeige“ mit Raster, Maßen, Tempi, Pixelmustern, Ergebnisanzeige und Vorschau, der Abschnitt „Ton“,
dazu Verweise in README und Sprache. Die Bombe ist 2 × 3 statt 1 × 3 (R7).

**Checkpoint**: Der Style-Guide regelt alles, was Knöpfe, Spiel und Ton brauchen.

---

## Phase 2: Ton (Grundlage für US1 und US2)

**Goal**: Die zehn Töne liegen bytegleich erzeugbar im Projekt, und das Spiel hat seine Tonkanäle
(FR-040 bis FR-043; R13 bis R15; contracts/ton.md).

**Independent Test**: `python3 -I tools/ton/make_sounds.py` zweimal; `git status` zeigt danach keine
Änderung an den Dateien; `test_ton.gd` grün; Klaus hört die Töne mit `afplay` an.

- [x] T004 [C] `tools/ton/make_sounds.py` und `tools/ton/README.md` laut contracts/ton.md, „Skript“:
  nur Standardbibliothek, Rauschen mit festem Seed, Werte aus dem Abschnitt „Ton“ des Style-Guides;
  Option `--pruefsummen` schreibt `src/test/fixtures/ton_pruefsummen.txt` (über die Rohdateien). Lauf erzeugt die zehn
  Dateien unter `src/assets/sounds/`. Zwei Läufe hintereinander ergeben dieselben Bytes.
- [x] T005 [A] `src/default_bus_layout.tres` mit `Master` (0 dB) und `Effekte` (Pegel aus dem
  Style-Guide, Ziel `Master`); einmal `Godot --headless --path src --import`, damit die WAV ihre
  `.import` bekommen, und in jeder `.import` Kompression aus (PCM), kein Trimmen, kein Normalisieren,
  keine Schleife (Analyse, U6). `project.godot` bleibt unverändert.
- [x] T006 [A] `src/test/test_ton.gd` laut contracts/ton.md, „Tests“: zehn Dateien als
  `AudioStreamWAV`, mono, 22 050 Hz; aus der Rohdatei gelesen: erste Probe nicht null (SC-007),
  letzte nahe null; Länge je
  Datei ±1 ms aus dem Style-Guide; Kanal `Effekte` mündet in `Master` mit dem Pegel aus dem
  Style-Guide; Prüfsummen gleich `ton_pruefsummen.txt`.
- [x] T007 [A] Lernnotizen zu T005 und T006 in `specs/006-easter-egg-space-invaders/lernnotizen.md`:
  was ein Bus ist und warum Effekte einen eigenen haben, warum Godot `default_bus_layout.tres` von
  selbst lädt, was `.import` bei einer WAV festhält. Claude ergänzt die Lernnotiz zu T004: wie eine
  Rechteckwelle als Zahlen aussieht und warum ein fester Seed bytegleiche Dateien gibt (Analyse,
  V2).
- [x] T008 [C] Prüfen: Skript zweimal, Tests zweimal, Startprobe still; die Töne selbst anhören.
- [x] T009 [K] Phase 2 abnehmen: Töne nach quickstart.md, „Töne anhören“; dass sie ohne hörbare
  Verzögerung einsetzen (SC-007), ist eine Abnahme von Hand, kein Messwert (Analyse, A3); Tonhöhen, Längen und
  Pegel freigeben oder im Style-Guide ändern lassen (dann T004 erneut).

Erledigt am 2026-10-27, von Klaus nach dem Anhören abgenommen: zehn WAV aus
`tools/ton/make_sounds.py`, bytegleich mit `ton_pruefsummen.txt`; Kanäle `Master` (0 dB) und
`Effekte` (−10 dB) in `src/default_bus_layout.tres`; Import als PCM ohne Trimmen, Normalisieren und
Schleife; `test_ton.gd` mit 8 Tests; zweimal 1034 von 1034 Tests grün, Startprobe still. Dazu in
dieser Phase: beide Niederlagen heißen „GAME OVER“ (Klaus; Spec, „Phase 2“; Style-Guide Version 51).

**Checkpoint**: Ton ist da; keine Phasenprüfung, denn die Phase ändert nichts Sichtbares und keinen
Text (plan.md, „Prüfer je Phase“).

---

## Phase 3: Spielkern (Grundlage für US2)

**Goal**: Eine Partie Space Invaders lässt sich ohne Szene Schritt für Schritt spielen,
deterministisch mit Seed (FR-011 bis FR-015; R6 bis R8; contracts/invaders.md, `InvadersGame`,
`InvadersSprites`).

**Independent Test**: `test_invaders_game.gd` und `test_invaders_sprites.gd` grün; ein gezielter
Durchlauf gewinnt, ohne Schuss landet der Block.

- [x] T010 [A] [US2] `src/scenes/title/invaders/invaders_sprites.gd` (`class_name
  InvadersSprites`): die Muster aus dem Style-Guide Zeichen für Zeichen, `pixels()`, `size_of()`;
  `src/test/test_invaders_sprites.gd` laut Vertrag.
- [x] T011 [A] [US2] `src/scenes/title/invaders/invaders_game.gd` (`class_name InvadersGame`) laut
  Vertrag und data-model.md, „Partie“: Zustände `PLAYING`, `RESPAWN`, `WON`, `LOST`; Ereignisse
  `SHOT`, `ALIEN_HIT`, `MARCH`, `CANNON_HIT`, `WON`, `LOST`; Schritt 1/60 s; alle Maße, Lagen,
  Tempi und Punkte als Konstanten an einer Stelle mit den Werten aus dem Style-Guide (R7). Regeln:
  „Die Kanone bleibt im Feld; links und rechts zugleich heben sich auf“, „Ein neuer Schuss nur,
  wenn keiner im Feld ist. In `RESPAWN` gibt es keinen Schuss und keine Bombe“, „ein Schuss trifft
  höchstens einen“, „Schuss und Bombe fliegen aneinander vorbei“, Explosionen, die nichts aufhalten,
  gelandet, sobald „die unterste Zeile eines lebenden Außerirdischen die oberste Zeile der Kanone“
  erreicht, Rand nach den lebenden, „In `RESPAWN` steht der Block“, Zahl der Bomben, Dauer der
  Explosion und Lage der Kanone aus dem Style-Guide (data-model.md; CHK010 bis CHK012, CHK023;
  Analyse, I1, M2, M3, V1).
- [x] T012 [A] [US2] `src/test/test_invaders_game.gd` laut Vertrag, „Tests“, mit festem Seed, dazu
  SC-002: Ein gezielter Durchlauf gewinnt in höchstens 3 Minuten Spielzeit (10 800 Schritte); ohne
  Schuss landet der Block frühestens nach 1 Minute (3 600 Schritte). Zwei Partien mit gleichem Seed
  und gleichen Eingaben ergeben gleiche Folgen von Ereignissen.
- [x] T013 [A] [US2] Lernnotizen zu T010 bis T012: Kern ohne Node wie `TimelineRun`, fester Schritt
  statt `delta`, eigener `RandomNumberGenerator` mit Seed, Muster als Daten.
- [x] T014 [C] [US2] Prüfen: Tests zweimal mit gleicher Zahl, Startprobe still; Fehlerprobe: in
  einer Kopie Treffer, Landung und die Obergrenze der Bomben absichtlich brechen und zeigen, dass
  die Tests es finden.
- [x] T015 [K] [US2] Phase 3 abnehmen: Diff, Lernnotizen und Testergebnis.

Erledigt am 2026-10-27, von Klaus abgenommen: `InvadersSprites` und `InvadersGame` unter
`src/scenes/title/invaders/`, 28 Tests; nach der Fehlerprobe ein Test für die Obergrenze der Bomben
über 50 Seeds. Zweimal 1062 von 1062 Tests grün (185 771 Prüfungen), Startprobe still. Auslegungen in
research.md, „Auslegungen aus Phase 3“.

**Checkpoint**: Das Spiel rechnet; zu sehen ist noch nichts, deshalb keine Phasenprüfung.

---

## Phase 4: User Story 2 – Eine Runde spielen (Priority: P1)

**Goal**: Das Spiel läuft als Seite auf einem Communicator, mit Tasten, Bild, Ton, Ergebnisanzeige
und Anhalten ohne Fokus (FR-010, FR-012, FR-014, FR-016, FR-017, FR-020, FR-021, FR-030, FR-031,
FR-040, FR-044; R9 bis R11; contracts/invaders.md, `InvadersPage`).

**Independent Test**: Probeszene `src/test/fixtures/invaders_probe.tscn` von Anfang bis Sieg oder
Niederlage durchspielen, ohne Titel (Spec, Story 2); `test_invaders_page.gd` grün.

- [x] T016 [A] [US2] Texte in `src/scenes/title/title_texts.gd` laut Vertrag, „Texte“:
  `INVADERS_SCORE`, `INVADERS_WON`, `INVADERS_LOST`, `INVADERS_POINTS`,
  `INVADERS_CONTINUE` mit den Wortlauten aus R10; `src/test/test_title_texts.gd`: jede Zeile der
  Ergebnisanzeige passt in die Breite der Anzeige in ihrer Schrift. `src/test/test_texte.gd` findet
  die Anrede auch in Versalien („SIE“, „IHNEN“), mit eigenem Test (Analyse, U7).
- [x] T017 [A] [US2] `src/scenes/title/invaders/invaders_page.tscn` und `invaders_page.gd`
  (`class_name InvadersPage`) laut Vertrag: `start()`, `advance()`, `autoplay`, `finished`;
  Takt mit festem Schritt, höchstens 4 Schritte je Bild (SC-003); Eingabe in `_gui_input()`
  nach der Tabelle im Vertrag, Tasten mit Cmd, Strg oder Alt und `toggle_fullscreen` gehen durch
  (CHK006), Shift, Strg, Alt, Cmd allein zählen nicht (CHK009); Fokus holen und zurückholen, kein
  Fokusrahmen, Zeiger Pfeil (CHK022, CHK025); Malen auf dem Bildraster nur in `tusche`, Kopfzeile
  in `drucker`, Ergebnisanzeige nach R10 (CHK005, CHK024); Sperre der Ergebnisanzeige mit der Dauer aus
  dem Style-Guide; Kürzel mit Cmd, Strg oder Alt führen dort nicht weiter (Analyse, M4, V1). Nach
  `finished` und verborgen taktet die Seite nicht; Fokus nur zurückholen, wenn sie noch sichtbar ist
  (Analyse, U1, C5).
- [x] T018 [A] [US2] Töne der Seite: ein `AudioStreamPlayer` je Ton auf `Effekte`, ein gemeinsamer
  für die vier Marschtöne (CHK015); Zuordnung nach der Tabelle im Vertrag; `finished` und eine
  verborgene Seite stoppen alles (FR-044); ohne Fokus des Fensters kein Takt und `stream_paused`,
  auch die Sperre der Ergebnisanzeige steht (R11; CHK014).
- [x] T019 [A] [US2] Probeszene `src/test/fixtures/invaders_probe.tscn` und `.gd`: ein Communicator
  mit G-03 und der Seite, die gleich startet; nach `finished` startet eine neue Partie. Ohne Titel
  und ohne `GameSession`.
- [x] T020 [A] [US2] `src/test/test_invaders_page.gd` laut Vertrag, „Tests“, mit `autoplay = false`
  und erfundenen Ereignissen; auch: nach Esc mitten im Spiel kein Takt und kein Marschton mehr
  (Analyse, U1).
- [x] T021 [A] [US2] Lernnotizen zu T016 bis T020: Fokus als Weg der Tasten, `accept_event()` und was
  durchgehen muss, Malen in `_draw()` auf dem Bildraster, Zeitspeicher mit festem Schritt,
  Benachrichtigungen der App für den Fokus des Fensters.
- [x] T022 [C] [US2] Prüfen: Tests zweimal, Startprobe still; Bildschirmfotos der Probeszene im
  echten Fenster in 1920 × 925: Spiel am Anfang, mitten im Spiel mit Bomben und Explosion,
  Ergebnisanzeige gewonnen, Kanone kaputt, gelandet; Spiel und Ton halten ohne Fokus an; die Bildrate
  im echten Fenster gemessen, 60 Bilder je Sekunde (SC-003; Analyse, A2).
- [x] T023 [C] [US2] Phasenprüfung Phase 4 mit `/dcl-phasenpruefung`: Stil-Prüfer mit „Spiel auf der
  Anzeige“, Baustein Communicator, `tokens.json`; Text-Prüfer mit `Sprache.md` und den sechs
  Wortlauten; die Bildschirmfotos aus T022.
- [x] T024 [K] [US2] Phase 4 abnehmen nach quickstart.md, „Das Spiel allein“: spielen, Tempi und
  Pegel nach Gefühl einstellen lassen (Änderungen erst in den Style-Guide, dann in die Konstanten;
  SC-002); dass die Töne ohne hörbare Verzögerung kommen, von Hand (SC-007).

Erledigt am 2026-10-27, von Klaus nach dem Spielen abgenommen, Tempi und Pegel unverändert:
`InvadersPage` mit Szene, Probeszene, Texte in `TitleTexts`, Anrede in Versalien in `test_texte.gd`;
im echten Fenster ein Skriptfehler durch die Fokus-Meldung vor `_ready()` gefunden und behoben.
Zweimal 1092 von 1092 Tests grün (185 909 Prüfungen), Startprobe still, 60 Bilder je Sekunde bei
1920 × 925. Phasenprüfung: Stil 0 Befunde, 3 Lücken; Text 0 Befunde, 2 Lücken; alle fünf nach
Empfehlung geschlossen (Style-Guide Version 53).

**Checkpoint**: Das Spiel ist spielbar, nur noch nicht im Titel zu finden.

---

## Phase 5: User Story 1 und 3 – Das Geheimnis finden, zurück zum Titel (Priority: P1, P2) 🎯

**Goal**: Die drei Knöpfe sind drückbar, 1-2-3 startet das Spiel auf jeder Seite des Titels, und
danach steht der Titel da wie vorher (FR-001 bis FR-007, FR-017, FR-021, FR-022, FR-041; R1 bis
R5, R16). In zwei Teilen (ki_dev Punkt 4): erst die Gehäusetasten am Communicator, dann der Titel.

**Independent Test**: Auf dem Titel 1-2-3 klicken: Das Spiel startet; 2-1-3 startet nichts; nach
Esc, Sieg und Niederlage stehen Seite, Auswahl und Hinweis wie vorher (Spec, Story 1 und 3); alle
bisherigen Tests des Titels grün (SC-004).

### Teil 1: Gehäusetasten am Communicator

- [x] T025 [A] [US1] `src/ui/communicator/case_key.gd` (`class_name CaseKey`) und die Erweiterung
  von `src/ui/communicator/communicator.gd` und `.tscn` laut contracts/gehaeusetasten.md:
  `case_keys` mit leerer Vorgabe (Analyse, I2), `case_key_pressed(index)`,
  `is_case_key_down()`, Knoten `Keys` und `KeyClick` (`knopf.wav` auf `Effekte`); gezählt beim
  Loslassen über derselben Taste, Klick beim Drücken, rechte und mittlere Maustaste tun nichts;
  `_set_locked(true)` ruft `cancel()` jeder Taste; Eindrücken in `Keys._draw()` nach R3 und dem
  Ergebnis von T001, im nächsten Bild (FR-001a); Zeiger Pfeil, kein Fokus (FR-001b);
  `_page_list()` nimmt `Keys` aus, `KeyClick` ist kein Control (Analyse, C4).
- [x] T026 [A] [US1] Probeszene `src/test/fixtures/communicator_probe.tscn` und `.gd`: zeigt
  `case_key_pressed` an; Tests in `src/test/test_communicator.gd` laut contracts/gehaeusetasten.md,
  „Tests“; alle Tests aus Feature 005 bleiben unverändert grün.
- [x] T027 [A] [US1] Lernnotizen zu T025 und T026: Klickflächen über einem Bild, warum gezählt wird
  beim Loslassen, Ausschnitt aus einer Textur mit `draw_texture_rect_region`, warum der Communicator
  nichts von der Folge weiß.
- [x] T028 [C] [US1] Prüfen von Teil 1: Tests zweimal, Startprobe still, Bildschirmfotos der
  Probeszene mit jeder Taste eingedrückt, ×4 vergrößert neben der Montage aus T001.

### Teil 2: Folge und Titel

- [x] T029 [A] [US1] `src/scenes/title/key_sequence.gd` (`class_name KeySequence`) laut
  contracts/titelbildschirm.md und data-model.md, „Folge“; `src/test/test_key_sequence.gd` mit den
  Beispielen aus dem Vertrag und SC-005 (20 zufällige Folgen, fester Seed).
- [x] T030 [A] [US1] [US3] `src/scenes/title/title_screen.tscn` und `title_screen.gd` laut
  contracts/titelbildschirm.md: `case_keys` der Instanz auf die drei Rechtecke aus dem Style-Guide
  (Analyse, I2); Seite `Invaders` unter dem Communicator; Druck nur, wenn der Titel Eingaben annimmt
  und das Spiel nicht läuft; Start mit Merken von Seite und Fokus (Zeile und Hinweis aus
  `_selected_row` und `_selected_hint`; D1), `_hide_hint()` des Titels (C2), erst `show_page()`, dann
  `start()` (C1); Esc-Wache in `_unhandled_input()`, solange `Invaders` sichtbar ist (C3); Ende bei
  `finished` mit Seite, Fokus und Hinweis zurück, eine Meldung kommt als Hinweis zurück (CHK008);
  Folge auf 0 bei Start und neuem Erscheinen.
- [x] T031 [A] [US1] [US3] Tests in `src/test/test_title_screen.gd` laut
  contracts/titelbildschirm.md, „Tests“, mit erfundenen Mausereignissen auf den Tasten, auch: kein
  Spielstand beim Schließen des Fensters während des Spiels (CHK019); Meldung, Folge, Esc ohne
  Meldung danach (C2); Esc direkt an den Titel während des Spiels (C3); gemessen SC-001 und SC-006
  (Analyse, A2).
- [x] T032 [A] [US1] [US3] Lernnotizen zu T029 bis T031: eine Folge ohne Node, Fokus merken und
  zurückgeben, warum der Titel die Folge kennt und der Communicator nicht.
- [x] T033 [C] [US1] [US3] Prüfen: Tests zweimal, Startprobe still; Bildschirmfotos im echten
  Fenster in Klaus' Größe: Knopf eingedrückt, Spiel auf jeder der vier Seiten gestartet, nach Esc
  zurück mit Hinweis, Ergebnisanzeige im Titel.
- [x] T034 [C] [US1] [US3] Phasenprüfung Phase 5 mit `/dcl-phasenpruefung`: Stil-Prüfer mit dem
  Baustein Communicator (Gehäusetasten), „Spiel auf der Anzeige“, README (Bewegung, Bildaufbau
  Titel), `tokens.json`; die Bildschirmfotos aus T028 und T033.
- [x] T035 [K] [US1] [US3] Phase 5 abnehmen nach quickstart.md, „Im Titel“.

Erledigt am 2026-10-27, von Klaus im Titel ausprobiert und abgenommen: Gehäusetasten am
Communicator (`CaseKey`, `case_keys` ab Werk leer), `KeySequence`, Einbau in den Titel mit Rückweg
und Esc-Wache. Nach der Phasenprüfung (Stil 0 Befunde, Lücken nach Klaus' Entscheidung im
Style-Guide 54 geschlossen): Taste springt bei Fokusverlust des Fensters zurück, ohne zu zählen;
liegen gebliebene Knoten in einem Test aufgeräumt. Dazu die Meldung „Ausgelöst: …“ der Probeszene im
Bild. Zweimal 1131 von 1131 Tests grün (186 181 Prüfungen), Startprobe und echtes Fenster still;
SC-001 und SC-006 im selben Bild erfüllt.

**Checkpoint**: Das Easter Egg ist fertig; der Titel ohne Knopfdruck unverändert.

---

## Phase 6: Abschluss

**Purpose**: Lückensuche, Gesamtabnahme, Doku, Tagebuch.

- [x] T036 [C] Lückensuche mit `/speckit-converge` über das ganze Feature (`ki_dev.md`, „Ablauf je
  Feature“), dazu Stil- und Text-Prüfer einmal über alles. Lücken werden eine eigene Phase mit
  Klaus' Freigabe; hat sie Sichtbares, endet sie mit eigener Phasenprüfung.
- [x] T037 [K] Gesamtabnahme nach dem ganzen Quickstart.
- [ ] T038 [C] Doku nachziehen: `docs/features/Features.md` (006 fertig, Systeme 10 und 11; System
  11 „Sound“ nicht mehr nur Idee); `docs/offene-punkte.md`; `CLAUDE.md` (Tabelle „Aufbau“:
  `src/assets/sounds/`, `tools/ton/`, `default_bus_layout.tres`) nur mit Klaus' OK.
- [ ] T039 [C] Spielbeschreibung prüfen (die letzte Aufgabe vor dem Tagebuch, nach der
  Gesamtabnahme und vor dem Merge; `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“): Claude
  gleicht `docs/spielbeschreibung/` mit dem Code ab und legt Klaus eine Liste vor, welche Dateien
  veralten und welche neu angelegt werden sollten, mit Grund, mindestens `communicator.md`,
  `titel-und-hauptmenue.md`, `darstellung.md`, `build-und-tests.md`, `glossar.md`, `architektur.md`
  und ein mögliches neues `ton.md` samt Index. Abweichungen zwischen Spec und Code gehören dazu.
  Geändert wird erst nach Klaus' OK.
- [ ] T040 [C] Tagebuch vor dem Merge (`ki_dev.md`, Punkt 10): eigene Datei für Feature 006 unter
  `docs/tagebuch/` nach dem README dort, auf Englisch, je echter Entscheidung ein Eintrag, oben die
  Zeile „Tokens and cost“ aus `python3 -I tools/tagebuch/token_bilanz.py
  feature/006-easter-egg-space-invaders`. Klaus nimmt die Einträge ab.

---

## Dependencies & Execution Order

### Phase Dependencies

Die Phasen laufen streng nacheinander, jede erst nach Klaus' Abnahme der vorigen (Verfassung,
Grundsatz II):

- **Phase 1** (Style-Guide, Vermessung): keine.
- **Phase 2** (Ton): nach Phase 1, weil die Töne aus dem Abschnitt „Ton“ kommen.
- **Phase 3** (Spielkern): nach Phase 2; braucht aus Phase 1 Muster und Maße.
- **Phase 4** (Spielseite, US2): nach Phase 3; braucht die Töne aus Phase 2.
- **Phase 5** (Knöpfe und Titel, US1, US3): nach Phase 4, weil der Titel die Seite einbaut; Teil 2
  erst nach Claudes Prüfung von Teil 1.
- **Phase 6** (Abschluss): nach Phase 5; T040 vor dem Merge, der Merge nur auf Klaus' Wort.

### User Story Dependencies

- **US2** (spielen) ist der Kern; ohne sie ist der Auslöser wertlos.
- **US1** (finden) braucht US2, weil 1-2-3 das Spiel startet.
- **US3** (zurück) entsteht mit US1 im Titel; der Rückweg in der Probeszene (Esc, Ergebnisanzeige)
  ist schon Teil von Phase 4.

### Within Each Phase

- Kern vor Szene, Szene vor Tests der Szene, Tests vor Lernnotiz; dann Claudes Prüfung,
  Phasenprüfung, Klaus' Abnahme, Commit.

### Parallel Opportunities

- Keine `[P]`-Tasks: T011 braucht die Muster aus T010 über `size_of()`, T030 die API von
  `KeySequence` aus T029; T016 bis T020 teilen die Seite, T025 und T026 den Communicator (Analyse,
  R2).

---

## Implementation Strategy

### Erst spielbar, dann versteckt

1. Phase 1: Style-Guide und Vermessung, Klaus nimmt ab.
2. Phase 2: Töne zum Anhören.
3. Phase 3: der Kern, geprüft mit Tests.
4. Phase 4: das Spiel in der Probeszene; hier stellt Klaus das Spielgefühl ein.
5. Phase 5: Knöpfe und Einbau in den Titel; erst hier ist das Easter Egg zu finden.
6. Phase 6: Lückensuche, Gesamtabnahme, Spielbeschreibung, Tagebuch.

Das Spiel kommt vor dem Auslöser, weil ein Auslöser ohne Spiel nichts zeigt und das Spielgefühl
mehr Abstimmung braucht als die Knöpfe.

---

## Notes

- Format: Task-ID, Besitzer, `[P]` für parallel ausführbar, `[Story]` für die User Story.
- Die Verfassung verlangt kein testgetriebenes Vorgehen; Tests entstehen mit der Logik und müssen
  vor der Abnahme grün sein.
- Zu jeder umgesetzten Task gibt es eine Lernnotiz in
  `specs/006-easter-egg-space-invaders/lernnotizen.md` (Verfassung, Grundsatz II). Bei
  `[A]`-Tasks schreibt sie der Agent, und Claude trägt sie nach jeder Phase ein.
- Nach dem Anlegen von Skripten, Szenen oder WAV ruft der Agent einmal
  `Godot --headless --path src --import` auf; `.uid` und `.import` werden committet.
- **Feste Größen** für jeden Auftrag an den Agent:
  - Ohne Druck auf eine Gehäusetaste bleibt der Titel unverändert; alle Tests aus Feature 001, 004
    und 005 laufen unverändert grün (FR-006, SC-004).
  - Die Töne sind bytegleich mit `ton_pruefsummen.txt`; das Gehäusebild und die Hauptpalette
    bleiben Byte für Byte gleich.
  - Die Startprobe mit `-d` bleibt still.
- **Echte Daten:** Kein Test schreibt nach `user://spielstaende/`; das Easter Egg schreibt gar
  nichts.
- **Nur ein Testlauf zur selben Zeit:** Alle Sitzungen teilen sich `user://`.
- Braucht der Agent einen Wert oder eine Regel, die der Style-Guide nach T002 nicht hat, hält er an
  und fragt (Grundsatz IV).

---

## Phase 7: Convergence

Aus T036 (`/speckit-converge` mit Lückensucher, Stil- und Text-Prüfer über das ganze Feature,
2026-10-27). Der Code erfüllt alle 28 FR, 7 SC und 16 Akzeptanzszenarien, die Werte stimmen mit dem
Style-Guide. Es bleiben Doku, die nicht mehr stimmt, drei Randfälle ohne eigenen Test, zwei
ungenaue Kommentare und vier Lücken im Style-Guide. Claude hat jeden Befund nachgeprüft; alle sind
NIEDRIG. Umgesetzt wird erst nach Klaus' Freigabe.

- [x] T041 [C] Doku angleichen: `contracts/gehaeusetasten.md` Tests, erster Punkt auf „Mit den drei
  Rechtecken aus dem Style-Guide gibt es drei Tasten ×2“ (Lückensuche F1, contradicts); Regel und
  Test „Fokusverlust des Fensters lässt die Taste ohne Zählen hoch“ in `contracts/gehaeusetasten.md`,
  den Übergang in `data-model.md` („Gehäusetaste“) und einen Randfall in die Spec (F2,
  unrequested); `research.md` R4 „ohne eigenen Code“ → `_set_locked()` ruft `cancel()`, R3
  `AtlasTexture` → `draw_texture_rect_region` (F3, contradicts); `plan.md` „Scale/Scope“ um
  `test_texte.gd`; in `tools/ton/make_sounds.py` den Kommentar „(Version 49)“ ohne Versionsnummer
  (F7, contradicts).
- [x] T042 [A] Kommentare in `src/scenes/title/invaders/invaders_page.gd`: `_finish()` „dann die
  Meldung“ → „dann `finished`“; `_on_focus_exited()` „etwa an eine Gehäusetaste“ → „etwa durch einen
  Klick auf eine Gehäusetaste“ (Stil B1, B2, contradicts).
- [x] T043 [A] Drei Randfälle der Spec mit Test in `src/test/test_title_screen.gd`: die Folge während
  der Fahrt herein verhält sich wie die Seiten (F4, Randfall „noch hereinfährt“, FR-004); die Folge
  mit einem beschädigten Spielstand startet das Spiel (F5); während des Spiels drücken sich die
  Knöpfe ein und klicken (`is_case_key_down`, `KeyClick.playing`), ohne ein zweites Spiel (F6)
  (partial).
- [x] T044 [C] Lücken im Style-Guide nach Klaus' Entscheidung schließen: Communicator „Einsatz“ nennt
  das Spiel als Seite, Menü „Seiten im Titel“ gilt für Menü- und Listenseiten (Stil L1);
  Gehäusetasten „heute im Titel und in der Probeszene des Communicators“ (Stil L3); „Der Name des
  Vorbilds erscheint nirgends“ gilt für alles Sichtbare, nicht für Datei- und Klassennamen (Stil
  L2); „Werkzeuge und Probeszenen folgen denselben Regeln“ in „Anrede“ (Text L2). Nicht übernommen,
  mit Grund in `docs/offene-punkte.md`: „Taste“ neben sichtbaren Gehäusetasten (Text L1, kein Verstoß,
  die Zeile passt sonst nicht in die Breite), Meldung oder Warnung (Text L3, hier ohne Folge),
  Satzform der Probe-Meldungen (Text L4, Probe).
- [x] T045 [C] Prüfen: Tests zweimal, Startprobe still; Prüfer nur über das Geänderte; dann Klaus'
  Gesamtabnahme (T037).
