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

- [ ] T001 [C] Die drei grauen Knöpfe in `src/assets/images/organizer_1991.png` vermessen: Montage
  ×8 mit Raster und Koordinaten in den Scratchpad, je Knopf Rechteck, Fläche, Vorderkante, Spalt
  links und darüber, ob es eine helle linke Spalte gibt (R2, R3; CHK020, CHK029). Ergebnis als
  Tabelle in research.md, R2, mit Verweis auf die Montage; die Montage selbst kommt nicht ins Repo.
- [ ] T002 [C] Style-Guide ergänzen, https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX, Dateien
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

  Vorher liest Claude die betroffenen Dateien neu und ändert nur diese; danach bekommt Klaus den
  Link und eine Liste der Änderungen. Wünscht Klaus, die Pixelmuster selbst zu zeichnen (plan.md,
  „Vorarbeiten“), wird daraus vorher eine `[K]`-Aufgabe, und Claude übernimmt seine Muster.
- [ ] T003 [K] Phase 1 abnehmen: Montage und Rechtecke, die Ausnahme für die Gehäusetasten, die
  Pixelmuster, Maße und Tempi und die Töne auf dem Papier freigeben oder ändern lassen.

**Checkpoint**: Der Style-Guide regelt alles, was Knöpfe, Spiel und Ton brauchen.

---

## Phase 2: Ton (Grundlage für US1 und US2)

**Goal**: Die zehn Töne liegen bytegleich erzeugbar im Projekt, und das Spiel hat seine Tonkanäle
(FR-040 bis FR-043; R13 bis R15; contracts/ton.md).

**Independent Test**: `python3 -I tools/ton/make_sounds.py` zweimal; `git status` zeigt danach keine
Änderung an den Dateien; `test_ton.gd` grün; Klaus hört die Töne mit `afplay` an.

- [ ] T004 [C] `tools/ton/make_sounds.py` und `tools/ton/README.md` laut contracts/ton.md, „Skript“:
  nur Standardbibliothek, Rauschen mit festem Seed, Werte aus dem Abschnitt „Ton“ des Style-Guides;
  Option `--pruefsummen` schreibt `src/test/fixtures/ton_pruefsummen.txt`. Lauf erzeugt die zehn
  Dateien unter `src/assets/sounds/`. Zwei Läufe hintereinander ergeben dieselben Bytes.
- [ ] T005 [A] `src/default_bus_layout.tres` mit `Master` (0 dB) und `Effekte` (Pegel aus dem
  Style-Guide, Ziel `Master`); einmal `Godot --headless --path src --import`, damit die WAV ihre
  `.import` bekommen. `project.godot` bleibt unverändert.
- [ ] T006 [A] `src/test/test_ton.gd` laut contracts/ton.md, „Tests“: zehn Dateien als
  `AudioStreamWAV`, mono, 22 050 Hz; erste Probe nicht null (SC-007), letzte nahe null; Länge je
  Datei ±1 ms aus dem Style-Guide; Kanal `Effekte` mündet in `Master` mit dem Pegel aus dem
  Style-Guide; Prüfsummen gleich `ton_pruefsummen.txt`.
- [ ] T007 [A] Lernnotizen zu T005 und T006 in `specs/006-easter-egg-space-invaders/lernnotizen.md`:
  was ein Bus ist und warum Effekte einen eigenen haben, warum Godot `default_bus_layout.tres` von
  selbst lädt, was `.import` bei einer WAV festhält.
- [ ] T008 [C] Prüfen: Skript zweimal, Tests zweimal, Startprobe still; die Töne selbst anhören.
- [ ] T009 [K] Phase 2 abnehmen: Töne nach quickstart.md, „Töne anhören“; Tonhöhen, Längen und
  Pegel freigeben oder im Style-Guide ändern lassen (dann T004 erneut).

**Checkpoint**: Ton ist da; keine Phasenprüfung, denn die Phase ändert nichts Sichtbares und keinen
Text (plan.md, „Prüfer je Phase“).

---

## Phase 3: Spielkern (Grundlage für US2)

**Goal**: Eine Partie Space Invaders lässt sich ohne Szene Schritt für Schritt spielen,
deterministisch mit Seed (FR-011 bis FR-015; R6 bis R8; contracts/invaders.md, `InvadersGame`,
`InvadersSprites`).

**Independent Test**: `test_invaders_game.gd` und `test_invaders_sprites.gd` grün; ein gezielter
Durchlauf gewinnt, ohne Schuss landet der Block.

- [ ] T010 [P] [A] [US2] `src/scenes/title/invaders/invaders_sprites.gd` (`class_name
  InvadersSprites`): die Muster aus dem Style-Guide Zeichen für Zeichen, `pixels()`, `size_of()`;
  `src/test/test_invaders_sprites.gd` laut Vertrag.
- [ ] T011 [A] [US2] `src/scenes/title/invaders/invaders_game.gd` (`class_name InvadersGame`) laut
  Vertrag und data-model.md, „Partie“: Zustände `PLAYING`, `RESPAWN`, `WON`, `LOST`; Ereignisse
  `SHOT`, `ALIEN_HIT`, `MARCH`, `CANNON_HIT`, `WON`, `LOST`; Schritt 1/60 s; alle Maße, Lagen,
  Tempi und Punkte als Konstanten an einer Stelle mit den Werten aus dem Style-Guide (R7). Regeln:
  „Die Kanone bleibt im Feld; links und rechts zugleich heben sich auf“, „Ein neuer Schuss nur,
  wenn keiner im Feld ist. In `RESPAWN` gibt es keinen Schuss und keine Bombe“, „ein Schuss trifft
  höchstens einen“, „Schuss und Bombe fliegen aneinander vorbei“, Explosion 0,25 s, die nichts
  aufhält, gelandet, sobald „die Unterkante eines lebenden Außerirdischen die Oberkante der Kanone
  erreicht“, höchstens 3 Bomben, Kanone nach einem Treffer bei x 75 (data-model.md; CHK010 bis
  CHK012, CHK023).
- [ ] T012 [A] [US2] `src/test/test_invaders_game.gd` laut Vertrag, „Tests“, mit festem Seed, dazu
  SC-002: Ein gezielter Durchlauf gewinnt in höchstens 3 Minuten Spielzeit (10 800 Schritte); ohne
  Schuss landet der Block frühestens nach 1 Minute (3 600 Schritte). Zwei Partien mit gleichem Seed
  und gleichen Eingaben ergeben gleiche Folgen von Ereignissen.
- [ ] T013 [A] [US2] Lernnotizen zu T010 bis T012: Kern ohne Node wie `TimelineRun`, fester Schritt
  statt `delta`, eigener `RandomNumberGenerator` mit Seed, Muster als Daten.
- [ ] T014 [C] [US2] Prüfen: Tests zweimal mit gleicher Zahl, Startprobe still; Fehlerprobe: in
  einer Kopie Treffer, Landung und die Obergrenze der Bomben absichtlich brechen und zeigen, dass
  die Tests es finden.
- [ ] T015 [K] [US2] Phase 3 abnehmen: Diff, Lernnotizen und Testergebnis.

**Checkpoint**: Das Spiel rechnet; zu sehen ist noch nichts, deshalb keine Phasenprüfung.

---

## Phase 4: User Story 2 – Eine Runde spielen (Priority: P1)

**Goal**: Das Spiel läuft als Seite auf einem Communicator, mit Tasten, Bild, Ton, Ergebnisanzeige
und Anhalten ohne Fokus (FR-010, FR-012, FR-014, FR-016, FR-017, FR-020, FR-021, FR-030, FR-031,
FR-040, FR-044; R9 bis R11; contracts/invaders.md, `InvadersPage`).

**Independent Test**: Probeszene `src/test/fixtures/invaders_probe.tscn` von Anfang bis Sieg oder
Niederlage durchspielen, ohne Titel (Spec, Story 2); `test_invaders_page.gd` grün.

- [ ] T016 [A] [US2] Texte in `src/scenes/title/title_texts.gd` laut Vertrag, „Texte“:
  `INVADERS_SCORE`, `INVADERS_WON`, `INVADERS_LOST_HIT`, `INVADERS_LOST_LANDED`, `INVADERS_POINTS`,
  `INVADERS_CONTINUE` mit den Wortlauten aus R10; `src/test/test_title_texts.gd`: jede Zeile der
  Ergebnisanzeige passt in die Breite der Anzeige in ihrer Schrift.
- [ ] T017 [A] [US2] `src/scenes/title/invaders/invaders_page.tscn` und `invaders_page.gd`
  (`class_name InvadersPage`) laut Vertrag: `start()`, `advance()`, `autoplay`, `finished`;
  Takt mit festem Schritt, höchstens 4 Schritte je Bild (SC-003); Eingabe in `_gui_input()`
  nach der Tabelle im Vertrag, Tasten mit Cmd, Strg oder Alt und `toggle_fullscreen` gehen durch
  (CHK006), Shift, Strg, Alt, Cmd allein zählen nicht (CHK009); Fokus holen und zurückholen, kein
  Fokusrahmen, Zeiger Pfeil (CHK022, CHK025); Malen auf dem Bildraster nur in `tusche`, Kopfzeile
  in `drucker`, Ergebnisanzeige nach R10 (CHK005, CHK024); Sperre der Ergebnisanzeige 0,5 s.
- [ ] T018 [A] [US2] Töne der Seite: ein `AudioStreamPlayer` je Ton auf `Effekte`, ein gemeinsamer
  für die vier Marschtöne (CHK015); Zuordnung nach der Tabelle im Vertrag; `finished` und eine
  verborgene Seite stoppen alles (FR-044); ohne Fokus des Fensters kein Takt und `stream_paused`,
  auch die Sperre der Ergebnisanzeige steht (R11; CHK014).
- [ ] T019 [A] [US2] Probeszene `src/test/fixtures/invaders_probe.tscn` und `.gd`: ein Communicator
  mit G-03 und der Seite, die gleich startet; nach `finished` startet eine neue Partie. Ohne Titel
  und ohne `GameSession`.
- [ ] T020 [A] [US2] `src/test/test_invaders_page.gd` laut Vertrag, „Tests“, mit `autoplay = false`
  und erfundenen Ereignissen.
- [ ] T021 [A] [US2] Lernnotizen zu T016 bis T020: Fokus als Weg der Tasten, `accept_event()` und was
  durchgehen muss, Malen in `_draw()` auf dem Bildraster, Zeitspeicher mit festem Schritt,
  Benachrichtigungen der App für den Fokus des Fensters.
- [ ] T022 [C] [US2] Prüfen: Tests zweimal, Startprobe still; Bildschirmfotos der Probeszene im
  echten Fenster in 1920 × 925: Spiel am Anfang, mitten im Spiel mit Bomben und Explosion,
  Ergebnisanzeige gewonnen, Kanone kaputt, gelandet; Spiel und Ton halten ohne Fokus an.
- [ ] T023 [C] [US2] Phasenprüfung Phase 4 mit `/dcl-phasenpruefung`: Stil-Prüfer mit „Spiel auf der
  Anzeige“, Baustein Communicator, `tokens.json`; Text-Prüfer mit `Sprache.md` und den sechs
  Wortlauten; die Bildschirmfotos aus T022.
- [ ] T024 [K] [US2] Phase 4 abnehmen nach quickstart.md, „Das Spiel allein“: spielen, Tempi und
  Pegel nach Gefühl einstellen lassen (Änderungen erst in den Style-Guide, dann in die Konstanten;
  SC-002).

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

- [ ] T025 [A] [US1] `src/ui/communicator/case_key.gd` (`class_name CaseKey`) und die Erweiterung
  von `src/ui/communicator/communicator.gd` und `.tscn` laut contracts/gehaeusetasten.md:
  `case_keys` mit den Rechtecken aus dem Style-Guide als Vorgabe, `case_key_pressed(index)`,
  `is_case_key_down()`, Knoten `Keys` und `KeyClick` (`knopf.wav` auf `Effekte`); gezählt beim
  Loslassen über derselben Taste, Klick beim Drücken, rechte und mittlere Maustaste tun nichts;
  `_set_locked(true)` ruft `cancel()` jeder Taste; Eindrücken in `Keys._draw()` nach R3 und dem
  Ergebnis von T001, im nächsten Bild (FR-001a); Zeiger Pfeil, kein Fokus (FR-001b);
  `_page_list()` nimmt `Keys` und `KeyClick` aus.
- [ ] T026 [A] [US1] Probeszene `src/test/fixtures/communicator_probe.tscn` und `.gd`: zeigt
  `case_key_pressed` an; Tests in `src/test/test_communicator.gd` laut contracts/gehaeusetasten.md,
  „Tests“; alle Tests aus Feature 005 bleiben unverändert grün.
- [ ] T027 [A] [US1] Lernnotizen zu T025 und T026: Klickflächen über einem Bild, warum gezählt wird
  beim Loslassen, Ausschnitt aus einer Textur mit `draw_texture_rect_region`, warum der Communicator
  nichts von der Folge weiß.
- [ ] T028 [C] [US1] Prüfen von Teil 1: Tests zweimal, Startprobe still, Bildschirmfotos der
  Probeszene mit jeder Taste eingedrückt, ×4 vergrößert neben der Montage aus T001.

### Teil 2: Folge und Titel

- [ ] T029 [P] [A] [US1] `src/scenes/title/key_sequence.gd` (`class_name KeySequence`) laut
  contracts/titelbildschirm.md und data-model.md, „Folge“; `src/test/test_key_sequence.gd` mit den
  Beispielen aus dem Vertrag und SC-005 (20 zufällige Folgen, fester Seed).
- [ ] T030 [A] [US1] [US3] `src/scenes/title/title_screen.tscn` und `title_screen.gd` laut
  contracts/titelbildschirm.md: Seite `Invaders` unter dem Communicator; Druck nur, wenn der Titel
  Eingaben annimmt und das Spiel nicht läuft; Start mit Merken von Seite, Fokus und Hinweis,
  `hide_hint()`, `start()`, `show_page()`; Ende bei `finished` mit Seite, Fokus und Hinweis zurück,
  eine Meldung kommt als Hinweis zurück (CHK008); Folge auf 0 bei Start und neuem Erscheinen.
- [ ] T031 [A] [US1] [US3] Tests in `src/test/test_title_screen.gd` laut
  contracts/titelbildschirm.md, „Tests“, mit erfundenen Mausereignissen auf den Tasten, auch: kein
  Spielstand beim Schließen des Fensters während des Spiels (CHK019).
- [ ] T032 [A] [US1] [US3] Lernnotizen zu T029 bis T031: eine Folge ohne Node, Fokus merken und
  zurückgeben, warum der Titel die Folge kennt und der Communicator nicht.
- [ ] T033 [C] [US1] [US3] Prüfen: Tests zweimal, Startprobe still; Bildschirmfotos im echten
  Fenster in Klaus' Größe: Knopf eingedrückt, Spiel auf jeder der vier Seiten gestartet, nach Esc
  zurück mit Hinweis, Ergebnisanzeige im Titel.
- [ ] T034 [C] [US1] [US3] Phasenprüfung Phase 5 mit `/dcl-phasenpruefung`: Stil-Prüfer mit dem
  Baustein Communicator (Gehäusetasten), „Spiel auf der Anzeige“, README (Bewegung, Bildaufbau
  Titel), `tokens.json`; die Bildschirmfotos aus T028 und T033.
- [ ] T035 [K] [US1] [US3] Phase 5 abnehmen nach quickstart.md, „Im Titel“.

**Checkpoint**: Das Easter Egg ist fertig; der Titel ohne Knopfdruck unverändert.

---

## Phase 6: Abschluss

**Purpose**: Lückensuche, Gesamtabnahme, Doku, Tagebuch.

- [ ] T036 [C] Lückensuche mit `/speckit-converge` über das ganze Feature (`ki_dev.md`, „Ablauf je
  Feature“), dazu Stil- und Text-Prüfer einmal über alles. Lücken werden eine eigene Phase mit
  Klaus' Freigabe; hat sie Sichtbares, endet sie mit eigener Phasenprüfung.
- [ ] T037 [K] Gesamtabnahme nach dem ganzen Quickstart.
- [ ] T038 [C] Doku nachziehen: `docs/features/Features.md` (006 fertig, Systeme 10 und 11; System
  11 „Sound“ nicht mehr nur Idee); `docs/offene-punkte.md`; `CLAUDE.md` (Tabelle „Aufbau“:
  `src/assets/sounds/`, `tools/ton/`, `default_bus_layout.tres`) nur mit Klaus' OK.
- [ ] T039 [C] Spielbeschreibung prüfen (immer die letzte Aufgabe des Features, nach der
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

- T010 (Muster) neben T011 (Kern): andere Dateien; T011 nutzt die Muster nur über `size_of()`.
- T029 (Folge) neben T030: eigene Datei ohne Abhängigkeit.
- Sonst keine: T016 bis T020 teilen die Seite, T025 und T026 den Communicator.

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
