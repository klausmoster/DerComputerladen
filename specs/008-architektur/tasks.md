---

description: "Taskliste für Feature 008 Godot- und Spielarchitektur mit Prüf-Agent"
---

# Tasks: Godot- und Spielarchitektur mit Prüf-Agent

**Input**: Design-Dokumente aus `specs/008-architektur/`

**Prerequisites**: plan.md, spec.md, research.md (R1 bis R12), data-model.md,
contracts/leitfaden.md, contracts/architektur-pruefer.md, contracts/architektur-tests.md,
contracts/arbeitsweise.md, quickstart.md, checklists/review.md,
`docs/recherche/architektur-quellen.md`

**Tests**: Die Spec verlangt Tests für die messbaren Regeln (FR-008); sie entstehen in Phase 4 nach
[architektur-tests.md](contracts/architektur-tests.md). Vor jeder Abnahme mit Code laufen alle Tests
zweimal mit derselben Zahl von Prüfungen grün, und die Startprobe ist still. Den Prüfer selbst messen
Fehlerprobe und Planprobe in Phase 2.

**Organization**: Die Tasks folgen den sechs Phasen aus plan.md, „Umsetzungsphasen“: Phase 1
Leitfaden (US1), Phase 2 Prüfer und Arbeitsweise (US2, US3), Phase 3 Bestandsprüfung (US4), Phase 4
Tests, Phase 5 Behebung (US5), Phase 6 Abschluss. Umgesetzt wird nach Verfassung 2.2.0, Grundsatz
II: eine Phase nach der anderen, nur auf Klaus' Auftrag, `/speckit-implement` nie. Jede Phase endet
mit Klaus' Abnahme und einem Commit. Die [C]-Aufgabe „Phasenprüfung“ steht nur in den Phasen, für die
plan.md unter „Prüfer je Phase“ Prüfer nennt (4 und 5). Kürzel wie „CHK008“ verweisen auf
[review.md](checklists/review.md), „R5“ auf [research.md](research.md).

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Entscheidungen, Freigaben, Abnahmen, was er selbst machen will.
  - `[A]` Godot-Agent `godot-entwickler`: GDScript, Tests.
  - `[C]` Claude: Leitfaden, Agent, Arbeitsweise, Proben, Bestandsprüfung, Doku, Prüfung.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: zugehörige User Story aus spec.md (US1 Architektur festlegen, US2 Code-Phase prüfen,
  US3 Plan prüfen, US4 Bestandsprüfung, US5 Behebung); Tests und Abschluss tragen keine

## Path Conventions

- Leitfaden `docs/architektur-leitfaden.md`, Quellen `docs/recherche/architektur-quellen.md`
- Agent `.claude/agents/architektur-pruefer.md`; Arbeitsweise unter `docs/ki_workflow/`, Skill unter
  `.claude/skills/dcl-phasenpruefung/`, Aufgaben-Vorlage `.specify/templates/overrides/tasks-template.md`
- Fehlerprobe `specs/008-architektur/fehlerprobe/`, Bestandsbericht `specs/008-architektur/bestandsbericht.md`,
  Lernnotizen `specs/008-architektur/lernnotizen.md`
- Godot-Projekt unter `src/`, Tests unter `src/test/`
- Form der Dokumente laut den Verträgen unter [contracts/](contracts/)

---

## Phase 1: Leitfaden (US1, Priority P1)

**Goal**: Ein Leitfaden mit Regeln, die Klaus einzeln entschieden hat.

**Independent Test**: Jede Regel hat alle acht Teile, keine steht auf „Vorschlag“ (SC-001); eine
Stelle aus `src/` lässt sich nur mit dem Leitfaden beurteilen (quickstart.md, Phase 1).

- [x] T001 [C] [US1] Entwurf `docs/architektur-leitfaden.md` nach contracts/leitfaden.md: Kopf;
  „So liest man eine Regel“ mit Teilen, Ständen, Nummern und der Tabelle „Schwere“ (CHK015);
  AR-01 bis AR-05 für die fünf Godot-Prinzipien; die Muster und Schichten nach research.md, R12;
  „Was bisher woanders stand“ mit den Grundsätzen aus `docs/spielbeschreibung/architektur.md` und
  der Verfassung (FR-006); leere Tabelle „Ausnahmen“; leere „Geschichte“. Jede Regel mit Beispiel aus
  `src/` (Pfad, gesucht mit `grep`), sonst ausgedachtem Beispiel aus dem Spiel, Gegenbeispiel,
  Quelle aus `docs/recherche/architektur-quellen.md`, Schicht, Prüfweise (Test für die messbaren
  nach R6) und Stand „Vorschlag“. Wo der Leitfaden strenger ist als die Godot-Doku, sagt er es (R12).
- [x] T002 [C] [US1] Die echten Alternativen einzeln als Auswahl an Klaus, die Empfehlung zuerst, je
  mit Aufwand: Ereigniskatalog bleibt JSON als Ausnahme zu AR-04 oder wird Resource; Probe
  „speichern, laden, vergleichen“ als vierter Test in Phase 4 oder nicht (R12); dazu jede weitere,
  die beim Schreiben von T001 auftaucht.
- [x] T003 [C] [US1] Tabelle zur Durchsicht vorlegen: Regel, Kurzfassung, Empfehlung (R2, CHK009).
- [x] T004 [K] [US1] Durchsicht: je Regel übernehmen, ändern oder streichen („alle wie Vorschlag
  außer …“).
- [x] T005 [C] [US1] Entscheidungen aus T002 und T004 einarbeiten: Stand „gilt seit 2026-…, Klaus“
  oder „gilt ab dem ersten Feature der Schicht …“; Gestrichenes und Geändertes in „Geschichte“.
  Wählt Klaus den vierten Test, contracts/architektur-tests.md ergänzen. SC-001 mit einem kurzen
  Skript zählen (CHK017). `docs/offene-punkte.md`, Abschnitt „Feature 008, Plan“, nachführen.
- [x] T006 [C] [US1] Lernnotiz Phase 1 in `specs/008-architektur/lernnotizen.md`: was die fünf
  Prinzipien an konkreten Stellen im Code bedeuten, etwa `TimelineRun` als Kern, `case_key_pressed`
  als Signal nach oben, die Naht `session if session != null else GameSession`.
- [x] T007 [K] [US1] Abnahme Phase 1 nach quickstart.md, Phase 1.

**Checkpoint**: Der Leitfaden gilt; Spec, Plan und Godot-Agent können sich daran halten.

---

## Phase 2: Prüfer und Arbeitsweise (US2, US3, Priority P1/P2)

**Goal**: Ein Prüfer, der Phasen und Pläne gegen den Leitfaden prüft und von selbst eingeplant wird.

**Independent Test**: Fehlerprobe mit fünf Verstößen bestanden (SC-002); Planprobe am Plan von 006
liefert einen Bericht in der Form des Vertrags; Vorlage und Skill nennen Code als Auslöser (SC-006).

- [x] T008 [C] [US2] `.claude/agents/architektur-pruefer.md` nach contracts/architektur-pruefer.md:
  Kopf mit `tools: Read, Grep, Glob`, `model: inherit`; Anweisung mit den Punkten 1 bis 8; Bericht mit
  fünf Abschnitten; Tabelle „Schwere“.
- [x] T009 [C] [US2] Fehlerprobe unter `specs/008-architektur/fehlerprobe/` (R8): fünf Dateien als
  Text, je ein Verstoß gegen AR-01 bis AR-05 und daneben eine ähnliche, erlaubte Stelle; dazu die
  Lösung `specs/008-architektur/fehlerprobe-loesung.md` außerhalb des Ordners der Probe (Analyse, U5).
- [x] T010 [C] [US2] Fehlerprobe laufen lassen. Der neue Agent-Typ steht erst in einer neuen Sitzung
  bereit; deshalb ein allgemeiner Agent, der zuerst die Datei des Prüfers liest, mit „nur lesen“ im
  Auftrag (CHK018). Der Auftrag verbietet, die Lösung zu lesen, und nennt keine Regel als von Tests
  gemessen (Analyse, U5, A4). Ergebnis gegen die Lösung; besteht er nicht,
  Anweisung nachschärfen und höchstens zweimal wiederholen, dann entscheidet Klaus (SC-002, CHK006).
- [x] T011 [C] [US3] Planprobe (CHK005): Plan, research.md, data-model.md und contracts/ von
  `specs/006-easter-egg-space-invaders/` als Auftrag „Plan“; Bericht nachprüfen.
Vor T012 bis T016 sieht Claude nach dem Stand von 007, das dieselben Dateien in seinem Abschluss
ändert (Analyse, I2). Ist 007 gemergt, holt Claude `main` mit Klaus' OK zuerst herein
(`sync_with_base_branch`) und sieht die Tasks auf die Regel „[A] Selbsttest-Abläufe anpassen“ aus 007
durch; sonst löst Claude die Konflikte beim späteren Hereinholen.

- [x] T012 [P] [C] [US2] `docs/ki_workflow/ki_pruefung.md` nach contracts/arbeitsweise.md: Stand,
  Grundsatz 5 und der Satz unter der Auswertung des Pilots (Analyse, C13),
  „Wer prüft was“, Schaubild, „Die Prüfer“, „Nicht vorgesehen“ mit „bis 2026-10-28“ und Grund,
  „Maßstäbe“, Ablauf, „Anbindung an Spec Kit“; Zeilen im „Nachmessen“ für T010 und T011.
- [x] T013 [P] [C] [US2] `docs/ki_workflow/ki_dev.md` (Punkt 8, Schaubild „Ablauf je Feature“) und
  `docs/ki_workflow/README.md` (Schaubild „Wer macht was“, Tabelle „Was steht wo“).
- [x] T014 [P] [C] [US2] `.claude/skills/dcl-phasenpruefung/SKILL.md`: Beschreibung, Schritt 2,
  Vorbereitung mit `.gd`, `.tscn` und `.tres` aus dem Diff, Ersatz-Auftrag, Checkliste mit Plan und
  Vertrag, Bericht mit Abschnitt „Architektur-Prüfer“.
- [x] T015 [P] [C] [US2] `.specify/templates/overrides/tasks-template.md`: an jeder Phasenprüfung
  „nur wenn die Phase Sichtbares, Texte oder Code ändert“ (FR-021). Danach mit `git diff` prüfen,
  dass Spec Kits eigene Vorlagen unberührt sind.
- [x] T016 [P] [C] [US2] `.claude/agents/godot-entwickler.md`: Leitfaden unter „Vor jeder Aufgabe
  lesen“, Verweis unter „Godot“, Abweichungen unter „Abliefern“, „Offen“ (FR-022).
- [x] T017 [C] [US2] Vorschlag für Grundsatz VI aus contracts/arbeitsweise.md vorlegen.
- [x] T018 [K] [US2] Grundsatz VI beschließen; Claude führt `/speckit-constitution` mit Klaus'
  Wortlaut aus, Version 2.3.0 (FR-023).
- [x] T019 [C] [US2] Zeile für den Leitfaden in der Tabelle „Aufbau“ von `CLAUDE.md` vorlegen;
  eintragen nur mit Klaus' OK.
- [x] T020 [C] [US2] Lernnotiz Phase 2: was ein Subagent ist, warum die Positivliste der Werkzeuge
  ihn zum reinen Leser macht, warum Fehlerprobe und Planprobe den Prüfer messen.
- [x] T021 [K] [US2] Abnahme Phase 2 nach quickstart.md, Phase 2.

**Checkpoint**: Ab jetzt planen neue Features den Architektur-Prüfer von selbst ein.

---

## Phase 3: Bestandsprüfung (US4, Priority P2)

**Goal**: Ein Bericht über den ganzen Bestand, je Abweichung mit Klaus' Entscheidung.

**Independent Test**: Der Bericht nennt jede Datei (SC-003) und je Abweichung Ort, Regel, Beleg,
Schwere, Claudes Urteil und Klaus' Entscheidung (quickstart.md, Phase 3).

- [x] T022 [C] [US4] Fragen, ob 007 gemergt ist. Wenn ja: `main` mit Klaus' OK in den Branch holen
  (`sync_with_base_branch`), Tests zweimal und Startprobe. Wenn nein: im Bericht vermerken (CHK008).
- [x] T023 [C] [US4] Dateilisten für die drei Läufe aus `find`: Kern (`src/core/` und
  `src/project.godot`), Spiel und Oberfläche (`src/scenes/`, `src/ui/`, `src/default_bus_layout.tres`),
  Werkzeuge (`src/tools/werkstatt/` und, wenn 007 im Branch ist, `src/tools/selbsttest/`); je Skripte,
  Szenen und Resources, ohne `addons/` und `test/` (R5; Analyse, I1).
- [x] T024 [C] [US4] Drei Läufe gleichzeitig, Auftrag „Bestand“, je mit Leitfaden und Liste. Meldet
  ein Lauf ungelesene Dateien, diesen Teil teilen und nur das Fehlende wiederholen (CHK011).
- [x] T025 [C] [US4] Jede Abweichung nachprüfen, bestätigt oder verworfen mit Grund; die drei Berichte
  zu `specs/008-architektur/bestandsbericht.md` nach data-model.md zusammenführen; SC-003 gegen die
  Listen aus T023 prüfen.
- [x] T026 [C] [US4] Klaus vorlegen: je bestätigte Abweichung eine Empfehlung mit Aufwand (in 008
  beheben, wenn ein System nach FR-027; begründete Ausnahme; Regel ändern; eigenes Feature), je
  Lücke im Leitfaden eine Empfehlung.
- [x] T027 [K] [US4] Entscheidungen zu Abweichungen und Lücken.
- [x] T028 [C] [US4] Einarbeiten: Ausnahmen in die Tabelle des Leitfadens; geänderte Regeln mit
  „Geschichte“; Einträge in `docs/features/Feature_Ideas.md` für große Umbauten; die Listen `KERNE`,
  `ERLAUBT_NACH_OBEN`, `BIS_BEHEBUNG` und `VORGEMERKT` in contracts/architektur-tests.md; die
  Behebungen als Aufgaben in Phase 5 dieser Datei; Zählung der drei Läufe in `ki_pruefung.md`,
  „Nachmessen“. Danach Spec, Tasks und Verträge auf die neuen Aufgaben abgleichen (Analyse, U18).
- [x] T029 [C] [US4] Lernnotiz Phase 3: was der Bestand über den Aufbau zeigt, an den
  aufschlussreichsten Abweichungen und Ausnahmen.
- [x] T030 [K] [US4] Abnahme Phase 3.

**Checkpoint**: Es steht fest, was behoben wird, was Ausnahme ist und was ein eigenes Feature wird.

---

## Phase 4: Architektur-Tests (FR-008)

**Goal**: Die messbaren Regeln prüft ein Test bei jedem Lauf.

**Independent Test**: Alle Tests zweimal grün; jede Prüffunktion hat eine Fehlerprobe (quickstart.md,
Phase 4).

- [x] T031 [A] `src/test/test_architektur.gd` nach contracts/architektur-tests.md mit den Listen aus
  T028: Prüffunktionen `kern_verstoesse` (mit globalem Zufall), `autoloads_aus`, `wege_nach_oben`,
  `verweise_auf_werkzeuge`; Tests `test_kerne_ohne_node`, `test_genau_diese_autoloads`,
  `test_kein_weg_nach_oben`, `test_spiel_kennt_werkzeuge_nicht`, `test_listen_ohne_leichen`, `test_ausnahmen_wie_im_leitfaden`; Meldungen deutsch mit Datei, Zeile
  und AR-Nummer; Fehlerprobe je Prüffunktion an Kopien außerhalb des Repos; Lernnotiz.
- [x] T032 [C] Ergebnis prüfen: Tests zweimal, Startprobe, Fehlerprobe nachvollziehen, Code lesen;
  Auslegungen in Vertrag oder research.md.
- [x] T033 [C] Phasenprüfung Phase 4 mit `/dcl-phasenpruefung`: nur Text-Prüfer über die
  Testmeldungen; Tests lösen den Architektur-Prüfer nicht aus (plan.md, „Prüfer je Phase“; FR-016).
- [x] T034 [K] Abnahme Phase 4.

**Checkpoint**: Ein neues Autoload oder ein Kern mit Node fällt bei jedem Testlauf auf.

---

## Phase 5: Behebung (US5, Priority P3)

**Goal**: Die freigegebenen Abweichungen sind behoben, das Spiel verhält sich wie vorher.

**Independent Test**: Fahrpläne bytegleich, Startprobe still, Tests zweimal grün, `BIS_BEHEBUNG` leer,
beide Spielstände laden (SC-004; quickstart.md, Phase 5).

Die Behebungen stehen seit T028 fest (Klaus, 2026-10-28; `bestandsbericht.md`). Die Phase hat
zwei Teile (ki_dev, Punkt 4): erst die kleinen Behebungen (T036a), dann Titel und Werkstatt (T036b);
dazwischen prüft Claude. Die Buchstaben halten die Nummern ab T037 fest.

- [x] T035 [C] [US5] Voraussetzung prüfen: 007 gemergt und `main` im Branch (CHK019); sonst wartet die
  Phase. Kam 007 erst nach der Bestandsprüfung herein: Bestandsprüfung über den Code, den 007
  mitbringt (`src/tools/selbsttest/` und geänderte Dateien), Abweichungen Klaus vorlegen, Listen in
  `test_architektur.gd` durch den Agent angleichen lassen (Analyse, I1); nach der Nachprüfung
  (Klaus, 2026-10-28) dazu `wege_nach_oben` auf Knotenpfade schärfen und `KERNE` um vier Kerne des
  Selbsttests ergänzen (Vertrag der Tests, „Auslegungen“). Ausgangsmessung festhalten:
  Testzahl, Startprobe, Fahrpläne für die Seeds 1, 4711 und 99999 nach `vorher/` im Scratchpad;
  zwei Spielstände per Skript in `user://test_008_behebung/` anlegen (Mittel, Seed 4711, gespeichert
  1987; Schwer mit einem Eingriff, gespeichert 1993; CHK013), nicht im echten Ordner; Klaus bitten,
  für die Handprobe selbst einen Spielstand anzulegen (Analyse, U14, U15).
- [x] T036a [A] [US5] Teil 1, kleine Behebungen ohne Änderung am Verhalten, je mit Lernnotiz:
  - K1 `src/core/game_clock.gd`: Obergrenze an Tagen je Bild in `_process()`, wie
    `InvadersPage.MAX_STEPS` (AR-10).
  - K2 `src/core/game_clock.gd`: `enum` für läuft, angehalten, am Ende statt `paused` und `_ended`;
    `paused` bleibt als Eigenschaft lesbar und setzbar, wie die Tests sie nutzen (AR-11).
  - K3 `src/core/timeline.gd`: `start_game()` ohne Seed würfelt aus einem eigenen `rng` als Naht wie
    `GameSession.rng`, nicht aus `randi_range()` (AR-08).
  - K4, S5, L13: Doku-Kommentar „Nur lesen.“ an den Feldern, die die Oberfläche liest:
    `SaveSlot` (`number`, `state`, `reason`, `game`), `SaveGame` (`name`, `difficulty`, `day`,
    `last_played_at`), `GameSession` (`current`, `last_error`), `InvadersGame` (`state`, `score`,
    `lives`) (AR-15).
  - S2 `src/scenes/title/invaders/invaders_page.gd`: `enum` für keine Partie, läuft, Ergebnis
    gesperrt, Ergebnis wartet, beendet; `_window_focused` bleibt eigene Achse (AR-11).
  - S3 `title_screen.gd`, `title_screen.tscn`: Untertitel, `STAGE` und Vorlage der Versionszeile
    nach `TitleTexts` (AR-04).
  - S4 `main_menu.gd`, `main_menu.tscn`, `save_list.tscn`: keine zweite Kopfzeile neben
    `TitleTexts`; die Vorgabe in Szene und `header_text` leer (AR-04).
  - W1, W2 `src/tools/werkstatt/werkstatt.gd`: Variable `game_window` als Naht, leer heißt der Pfad
    `/root/GameWindow`; dort der Kommentar `# Ausnahme AR-02: …` wie in der Tabelle des Leitfadens
    (AR-02, AR-12).
  - W3 `simulator_panel.gd`, `what_if_probe.gd`: `_end_day()` als Methode von `WhatIfProbe` (AR-15).
  - W4 `statistics_panel.gd`: `enum` für nie gerechnet, rechnet, abgebrochen, fertig (AR-11).
  - Aus der Nachprüfung von 007 (T035; Klaus, 2026-10-28; `bestandsbericht.md`, „Nachprüfung des
    Codes aus Feature 007“), alle unter `src/tools/selbsttest/`:
    - B1 `selbsttest_ergebnis.gd`: Naht `game_window`, leer heißt das Autoload `GameWindow`; kein
      Pfad `/root/` mehr (AR-02, AR-12).
    - B2 `selbsttest_start.gd`: Variable `session` als Naht für `GameSession` wie bei Läufer und
      Fahrer (AR-12).
    - B3 `selbsttest_laeufer.gd`: `enum` für bereit, läuft, abgebrochen, geschrieben, beendet statt
      `_laeuft`, `_abgebrochen`, `_geschrieben`, `_beendet` (AR-11).
    - B5 `selbsttest_ergebnis.gd`: das Theme vor dem Setzen der Schrift duplizieren (AR-04).
    - B6 Seed 4711 (`selbsttest_start.gd`, `selbsttest_fahrer.gd`) und der Ordner
      `user://selbsttest/` (`selbsttest_ablage.gd`, `selbsttest_laeufer.gd`) je einmal als
      Konstante; M8 ebenso der Pfad der Titelszene (`selbsttest_start.gd`, `selbsttest_laeufer.gd`,
      `selbsttest_fahrer.gd`) (AR-04).
    - B7 `selbsttest_system.gd`: Raster aus `GameWindow.BASE_SIZE` statt eigener Zahl (AR-04).
    - B8 `selbsttest_lauf.gd`: „Nur lesen.“ an den Feldern, die die Zusammenfassung liest (AR-15).
    - M1 `ablaeufe/ablauf_fenster.gd`: Größe und Lage über eine Methode des Fahrers statt über
      `fahrer.fenster()` (Leitfaden, „Werkzeuge“).
    - M10 `selbsttest_fahrer.gd`, `selbsttest_eingabe.gd`: im Kopf sagen, dass sie Helfer der Hülle
      sind, kein Kern (AR-01).
- [x] T036b [A] [US5] Teil 2, nach Claudes Prüfung von Teil 1, je mit Lernnotiz:
  - S1 `src/scenes/title/title_screen.gd`: `enum` für die Eingabephase (vor den Einträgen,
    bedienbar, fährt hinaus) und für die Ebene (Hauptmenü, Gradwahl, Liste, Löschmodus, Rückfrage,
    Space Invaders) statt `_ready_for_input`, `_leaving` und der Sichtbarkeit der Seiten; Esc und
    Gehäusetasten über `match` (AR-11).
  - L16 `src/tools/werkstatt/`: gemeinsame Hilfen von `EventForm` und `EventList` in eine eigene
    Klasse; kein Aufruf privater Funktionen fremder Klassen mehr (`difficulty_panel.gd:274, 282,
    295`, `event_form.gd:471`) (AR-02).
  - Aus der Prüfung von Teil 1 (Klaus, 2026-10-29): `test_selbsttest_laeufer.gd` prüft, dass
    die Kette der Abläufe nach dem Schließen des Fensters stillsteht; bisher fiel das in der
    Fehlerprobe nur im folgenden Test auf.
- [x] T036d [A] [US5] Fund aus T036b (Klaus, 2026-10-29; `bestandsbericht.md`, „Fund bei der
  Behebung“): `TimelineRun._points()` wird öffentlich, etwa `points()`, und
  `src/tools/werkstatt/difficulty_panel.gd` ruft sie unter diesem Namen; kein Aufruf privater
  Funktionen fremder Klassen mehr in `src/` außer in Tests (AR-02). Fahrpläne bytegleich; mit
  Lernnotiz.
- [x] T036e [A] [US5] Aus der Phasenprüfung T038 (Klaus, 2026-10-29; `bestandsbericht.md`,
  „Phasenprüfung Phase 5“), je mit Lernnotiz:
  - A `src/tools/werkstatt/timeline_view.gd`: `_reason()` entfällt, die Zeitleiste ruft
    `FieldHelpers.reason()` (AR-02, Rest von L16).
  - D `src/core/timeline/timeline_run.gd`: Der Doku-Kommentar von `format_points()` nennt keine
    Klasse der Werkzeuge mehr (AR-14).
  - G `src/tools/selbsttest/selbsttest_fahrer.gd`: `SPIELBILDSCHIRM` entfällt, der Fahrer nimmt
    `TitleScreen.GAME_SCENE` (AR-04).
  - G `src/tools/werkstatt/simulator_panel.gd`: `roll_seed()` würfelt aus einem eigenen
    `RandomNumberGenerator` als Naht statt aus `randi_range()` (AR-08).
- [x] T036c [C] [US5] M11: In `tools/selbsttest/vergleich.py` nennt je ein Kommentar die Stelle in
  Godot, deren Wert oder Format das Skript ein zweites Mal kennt: Protokoll (`selbsttest_protokoll.gd`,
  `selbsttest_texte.gd`), Raster (`GameWindow.BASE_SIZE`), Kassenrot (`UiPalette.KASSENROT`).
- [x] T037 [C] [US5] Nach jedem Teil Vergleich nach R9: Fahrpläne `vorher/` gegen `nachher/` mit `cmp`, Startprobe,
  Tests zweimal, beide Spielstände aus `user://test_008_behebung/` mit einem kurzen Skript laden;
  Code lesen. Nach Teil 2 dazu ein Lauf des Selbsttests auf dem Mac (`tools/build/baue_alles.sh`,
  `tools/selbsttest/vergleich.py`), weil S1 den Zustand des Titels umbaut, den der Fahrer liest
  (Klaus, 2026-10-28).
- [x] T038 [C] [US5] Phasenprüfung Phase 5 mit `/dcl-phasenpruefung`: Architektur-Prüfer über das
  Geänderte, Maßstab Leitfaden und Bestandsbericht; Stil nur, wenn sich wider Erwarten Sichtbares
  ändert; danach Nachprüfung des Betroffenen.
- [x] T039 [K] [US5] Abnahme Phase 5 von Hand: den eigenen Spielstand von vor der Phase fortsetzen, ein neues
  Spiel beginnen, die drei grauen Knöpfe drücken, die Werkstatt öffnen und einen Lauf simulieren.

**Checkpoint**: Der Bestand folgt dem Leitfaden, bis auf begründete Ausnahmen und vorgemerkte Features.

---

## Phase 6: Abschluss

**Purpose**: Godot-Referenz, Lückensuche, Gesamtabnahme, Doku, Spielbeschreibung, Tagebuch.

Lokale Godot-Referenz (Klaus, 2026-10-29, nachträglich aufgenommen): eine API-Referenz in genau der
installierten Version statt eines fremden Dienstes wie Context7. Sie kommt vor T040, damit
Lückensuche und Architektur-Prüfer schon in ihr nachsehen. Die Buchstaben halten die Nummern ab
T040 fest.

- [ ] T039a [C] Erzeugen-Skript `tools/godot_referenz/erzeuge.sh`: ruft `Godot --doctool <ordner>`
  der installierten Godot auf (derzeit 4.7.2) und schreibt die Klassenreferenz als XML nach
  `godot_referenz/klassen/` im Repo-Root; schreibt `Godot --version` daneben in `version.txt`;
  bricht ab, wenn die Version nicht die in `src/project.godot` ist. Vorher Klaus die Entscheidung
  vorlegen, ob die XML-Dateien ins Repo kommen (Empfehlung: bei Bedarf erzeugen, nicht committen,
  `/godot_referenz/` in `.gitignore`; Aufwand: klein). Prüfen: zweimal laufen lassen, gleiche
  Dateien; `Node.xml`, `RegEx.xml` und `@GDScript.xml` vorhanden; `git status` zeigt den Ordner
  nicht.
- [ ] T039b [C] Optional, nur mit Klaus' Erlaubnis: das Handbuch `godot-docs`, Zweig 4.7 (rst), als
  flacher Klon nach `godot_referenz/handbuch/` (ebenfalls nicht im Repo). Vor dem Download Quelle
  (`https://github.com/godotengine/godot-docs`, Zweig 4.7) und Größe nennen; das Skript aus T039a
  bekommt dafür einen eigenen Schalter, kein Download ohne ihn.
- [ ] T039c [C] Verweise auf die Referenz: je ein Satz in `.claude/agents/godot-entwickler.md`,
  `.claude/agents/architektur-pruefer.md` und `docs/ki_workflow/ki_dev.md`: wo sie liegt, dass bei
  API-Fragen dort nachgesehen wird statt aus dem Gedächtnis, und dass bei fehlendem Ordner zuerst
  `tools/godot_referenz/erzeuge.sh` läuft. Den Eintrag für `tools/godot_referenz/` in der Tabelle
  „Aufbau“ von `CLAUDE.md` legt Claude Klaus als Vorschlag vor, geändert wird sie nur auf seine
  Entscheidung.
- [ ] T040 [C] Lückensuche mit `/speckit-converge` über das ganze Feature (`ki_dev.md`, „Ablauf je
  Feature“), dazu der Architektur-Prüfer einmal über alles, was 008 an Code geändert hat. Lücken
  werden eine eigene Phase mit Klaus' Freigabe.
- [ ] T040a [A] Selbsttest-Abläufe anpassen (vor der Gesamtabnahme; `docs/ki_workflow/ki_dev.md`,
  Punkt 11): Abläufe unter `src/tools/selbsttest/ablaeufe/`; entfällt, wenn 008 nichts ändert, was
  der Selbsttest durchspielt.
- [ ] T040b [C] Selbsttest zur Gesamtabnahme: `tools/build/baue_alles.sh`, Lauf auf dem Mac,
  `tools/selbsttest/vergleich.py`; Ergebnis in der Bitte um Gesamtabnahme; neue Referenzbilder nur
  mit Klaus' OK.
- [ ] T041 [K] Gesamtabnahme nach dem ganzen Quickstart.
- [ ] T042 [C] Doku nachziehen: `docs/features/Features.md` (008 fertig, System 11);
  `docs/features/Feature_Ideas.md` (11-06 gebaut); `docs/offene-punkte.md`; in `ki_pruefung.md` die
  Auswertung der Läufe aus 008 und die Notiz, dass SC-005, SC-006 und SC-007 im nächsten Feature
  mit Code nachgetragen werden (Analyse, C16).
- [ ] T043 [C] Spielbeschreibung prüfen (die letzte Aufgabe vor dem Tagebuch, nach der
  Gesamtabnahme und vor dem Merge; `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“): Claude
  gleicht `docs/spielbeschreibung/` mit dem Code ab und legt Klaus eine Liste vor, welche Dateien
  veralten und welche neu angelegt werden sollten, mit Grund, mindestens `architektur.md` (FR-029:
  Grundsätze verweisen auf den Leitfaden, neuer Stand nach der Behebung), `build-und-tests.md`
  (`test_architektur.gd`) und den Index. Abweichungen zwischen Spec und Code gehören dazu. Geändert
  wird erst nach Klaus' OK.
- [ ] T044 [C] Tagebuch vor dem Merge (`ki_dev.md`, Punkt 10): eigene Datei für Feature 008 unter
  `docs/tagebuch/` nach dem README dort, auf Englisch, je echter Entscheidung ein Eintrag, oben die
  Zeile „Tokens and cost“ aus `python3 -I tools/tagebuch/token_bilanz.py feature/008-architektur`.
  Klaus nimmt die Einträge ab.

---

## Dependencies & Execution Order

### Phase Dependencies

Die Phasen laufen streng nacheinander, jede erst nach Klaus' Abnahme der vorigen (Verfassung,
Grundsatz II):

- **Phase 1** (Leitfaden): keine.
- **Phase 2** (Prüfer, Arbeitsweise): nach Phase 1, weil der Prüfer den Leitfaden als Maßstab
  braucht und die Fehlerprobe auf AR-01 bis AR-05 zielt.
- **Phase 3** (Bestand): nach Phase 2; fragt vorher nach 007 (T022).
- **Phase 4** (Tests): nach Phase 3, weil die Listen aus dem Bericht kommen (R7).
- **Phase 5** (Behebung): nach Phase 4 und erst, wenn 007 gemergt und `main` im Branch ist (T035).
- **Phase 6** (Abschluss): nach Phase 5; die Godot-Referenz (T039a bis T039c) vor T040, T044 vor dem Merge. Der Merge erst nach 007 und nur auf
  Klaus' Wort.

### User Story Dependencies

- **US1** (Leitfaden) trägt alles andere.
- **US2** (Phase prüfen) und **US3** (Plan prüfen) brauchen US1.
- **US4** (Bestand) braucht US2.
- **US5** (Behebung) braucht US4 und die Tests aus Phase 4.

### Within Each Phase

- Entwurf vor Entscheidung, Entscheidung vor Einarbeiten; bei Code: Agent baut, Claude prüft,
  Phasenprüfung, Klaus' Abnahme, Commit.

### Parallel Opportunities

- T012 bis T016 ändern je eine andere Datei und hängen nur an T008; Claude kann sie in einem Zug
  schreiben.
- T024: die drei Läufe der Bestandsprüfung laufen gleichzeitig.
- Sonst keine `[P]`-Tasks: Jede Phase hängt an Klaus' Entscheidungen der vorigen.

---

## Implementation Strategy

### Kleinster nützlicher Stand

Phase 1 allein: Der Leitfaden gilt, und Spec, Plan und Godot-Agent halten sich daran, auch ohne
Prüfer. Mit Phase 2 prüft der Prüfer jedes neue Feature; das ist der eigentliche Nutzen (US2, US3).

### Schrittweise

1. Phase 1 → Abnahme: Leitfaden gilt.
2. Phase 2 → Abnahme: Prüfer und Arbeitsweise stehen, Verfassung 2.3.0.
3. Phase 3 → Abnahme: Bestand bekannt, Entscheidungen getroffen.
4. Phase 4 → Abnahme: messbare Regeln als Test.
5. Phase 5 → Abnahme: Bestand angeglichen (wartet auf 007).
6. Phase 6 → Gesamtabnahme, Merge nach 007.

---

## Notes

- `[P]` = andere Dateien, keine offene Abhängigkeit.
- Die Aufgaben von Phase 5 sind Platzhalter, bis T028 sie aus dem Bestandsbericht ergänzt.
- Nur eigene Dateien committen; Claude committet, Klaus pusht.
