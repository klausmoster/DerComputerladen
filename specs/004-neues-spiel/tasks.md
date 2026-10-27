---

description: "Taskliste für Feature 004 Neues Spiel starten"
---

# Tasks: Neues Spiel starten

**Input**: Design-Dokumente aus `specs/004-neues-spiel/`

**Prerequisites**: plan.md, spec.md, research.md (R1 bis R18), data-model.md,
contracts/spielstand.md, contracts/spielablauf.md, contracts/titelbildschirm.md, quickstart.md,
checklists/review.md

**Tests**: Die Verträge legen GUT-Tests fest, je im Abschnitt „Tests“. Sie entstehen mit der Logik
und müssen vor jeder Abnahme grün sein, zweimal hintereinander mit derselben Zahl von Prüfungen.
Die Oberfläche prüft Klaus zusätzlich von Hand nach quickstart.md.

**Organization**: Die Tasks folgen den sechs Phasen aus plan.md, „Umsetzungsphasen“. Phase 1 ist
Vorarbeit im Style-Guide, Phase 2 und 3 sind der Kern, Phase 4 und 5 die Oberfläche je zwei User
Stories, Phase 6 der Abschluss. Umgesetzt wird nach Verfassung 2.1.1, Grundsatz II: eine Phase nach
der anderen, nur auf Klaus' Auftrag, `/speckit-implement` nie. Jede Phase endet mit Klaus' Abnahme;
jede Phase mit Sichtbarem oder Texten hat davor die [C]-Aufgabe „Phasenprüfung“ (plan.md, „Prüfer je
Phase“). Welche Abschnitte des Quickstarts zu welcher Abnahme gehören, steht dort in der Tabelle
„Abnahme je Phase“. Kürzel wie „CHK002“ verweisen auf die Checkliste
[review.md](checklists/review.md).

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Entscheidungen, Freigaben, Abnahmen, was er selbst bauen will.
  - `[A]` Godot-Agent `godot-entwickler`: Szenen, Nodes, GDScript, Tests, Fixtures.
  - `[C]` Claude: Style-Guide, Doku, Phasenprüfung, Review.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: zugehörige User Story aus spec.md (US1 bis US4); Grundlagen für mehrere Stories
  tragen keine

## Path Conventions

- Godot-Projekt unter `src/`, Tests unter `src/test/`, Fixtures unter `src/test/fixtures/` (GUT
  9.7.1)
- Spielstände unter `src/core/save/`, das Autoload `GameSession` in `src/core/game_session.gd`,
  Kern der Zeitleiste unter `src/core/timeline/`, Oberfläche unter `src/scenes/title/` und
  `src/scenes/game/`, der Baustein Knopf in `src/ui/`
- Pfade, Klassen, Signale und Signaturen laut [spielstand.md](contracts/spielstand.md),
  [spielablauf.md](contracts/spielablauf.md) und [titelbildschirm.md](contracts/titelbildschirm.md);
  was dort nicht steht, gilt aus den Verträgen von Feature 001 bis 003
- Nach dem Anlegen von Skripten ruft der Agent einmal `Godot --headless --path src --import` auf
  (siehe Notes)

---

## Phase 1: Style-Guide (Vorarbeit, kommt vor Phase 2)

**Purpose**: Was Phase 4 und 5 zeigen, steht vorher im Style-Guide (Verfassung, Grundsatz IV;
research.md, R17). Kein Code.

- [x] T001 [C] Style-Guide ergänzen, https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX, Dateien
  unter `project/`, nach research.md, R17 und Checkliste CHK017:
  - Baustein Menü: Abschnitt „Blätter im Titel“. Gradwahl, Spielstände und Rückfrage ersetzen das
    Hauptmenü an seiner Stelle, „oben bei y 150“ und „rechts bei x 616“; Breite nach Inhalt (144,
    die Liste 304, links also bei x 312); genau ein Blatt sichtbar; „Zurück“, in der Rückfrage
    „Abbrechen“, und Esc führen eine Ebene zurück; die Kopfzeile darf den Modus nennen, etwa WELCHES
    LÖSCHEN?.
  - Neuer Baustein Liste: Spalten mit festen Anfängen (Name, Grad, Spieldatum, zuletzt gespielt;
    0, 64, 108, 172 ab dem Text der Zeile), keine Spaltenköpfe, „höchstens 6“ sichtbare Zeilen,
    Rollen um je eine Zeile mit Auswahl und Mausrad; Rollmarken als Dreieck in `tusche`, 7 breit
    und 4 hoch wie der gedrehte Pfeil, rechts in der Kopfzeile (oben mehr) und rechts in der Zeile
    „Löschen …“ (unten mehr), mit 12 Abstand zum Papierrand; „Löschen …“ und „Zurück“ immer unten;
    nicht fortsetzbare Zeilen gedämpft wie ein nicht verfügbarer Menüeintrag, in den Spalten Grad
    und Spieldatum „beschädigt“ oder „neuere Version“; Namen, die nicht in die Spalte passen, mit
    „…“ gekürzt; Löschmodus, in dem „Zurück“ nur den Modus beendet (Analyse, F3, F9, B4).
  - Rückfrage im Titel: ein Blatt, „Abbrechen“ vorgewählt, die Hinweise nennen, worum es geht.
  - Neuer Baustein Meldung: wie der Hinweis, Kontur `kassenrot`; ersetzt den Hinweis, bis der
    Spieler die Auswahl ändert oder etwas auslöst.
  - Baustein Knopf: Fokuslinie auf dunklem Grund in `papier`; ein Knopf, der allein auf einem
    Bildschirm steht und den Fokus hat, zeigt seinen Hinweis wie ein Menüeintrag, ohne Verzögerung;
    Knöpfe in Fenstern behalten den Tooltip (CHK017).
  - README, „Bildaufbau“: der Spielbildschirm als Platzhalter, Vollbild in `nacht`, Knopf in der
    Mitte (bei „Zum Hauptmenü“ x 270, y 170), Hinweis links daneben, bis die Bedienleiste kommt.

  Die Maße stammen aus research.md, R11, R12 und R15; Maß und Farbe der Rollmarken legt T001 neu
  fest. Nach T002 gelten die Werte im Style-Guide;
  Verträge und Tasks verweisen nur noch dorthin (Verfassung, Grundsatz IV; Analyse, D1).

  Vorher liest Claude die betroffenen Dateien neu (Menue, Hinweis, Knopf, README) und ändert nur
  diese; danach gibt Claude Klaus den Link und eine Liste der Änderungen.
- [x] T002 [K] Phase 1 abnehmen: die neuen Abschnitte im Style-Guide lesen und freigeben oder
  ändern lassen. Erst danach beginnt Phase 2.

Erledigt am 2026-10-26: Style-Guide Version 22, von Klaus freigegeben. Neu sind beim Menü die
Abschnitte „Blätter im Titel“ und „Rückfrage“, die Bausteine Liste und Meldung, beim Knopf der
allein stehende Knopf und die Fokuslinie auf dunklem Grund, beim Hinweis Liste und Knopf, im README
der Spielbildschirm als Platzhalter und die Meldung unter „Oberfläche“.

**Checkpoint**: Der Style-Guide regelt alles, was die Oberfläche braucht. Abnahme durch Klaus, dann
Auftrag für Phase 2; die Phasen laufen nacheinander (Verfassung, Grundsatz II; Analyse, D2).

---

## Phase 2: Kern Spielstand (Grundlage für US1 bis US4)

**Purpose**: Spielstände lesen, prüfen, sicher schreiben und löschen; Eingriffe teilen sich Spiel
und Werkstatt. Keine Oberfläche.

**⚠️ CRITICAL**: Phase 3 braucht `SaveStore` aus dieser Phase.

- [x] T003 [A] `src/core/timeline/intervention_file.gd` (`InterventionFile`) laut spielstand.md,
  übernommen aus `WhatIfProbe`: `DATE_KEYS`, `to_file()`, `from_file()`, `wrong_date()`,
  `is_date()`, `is_whole_number()`, `shown()`. `src/tools/werkstatt/what_if_probe.gd` ruft sie auf
  statt eigener Funktionen; nur Hilfen wie `_label()` bleiben dort (Analyse, C12). Test
  `src/test/test_intervention_file.gd`: Umrechnung hin und zurück, „−1 als „1984-12-31““, der Wert
  „auf vier Nachkommastellen“, falsches Datum mit Satz, auch im Modifikator. **Feste Größe:**
  `test_what_if_probe.gd` und `test_simulator.gd` laufen unverändert grün, und eine Probe, die die
  Werkstatt schreibt, ist Byte für Byte dieselbe wie vorher (R5).
- [x] T004 [A] `TimelineRun.replay(records, until_day)` in `src/core/timeline/timeline_run.gd` laut
  spielstand.md: Reihenfolge aus `in_replay_order()`, je Eintrag `advance_to(at_day)` und
  `apply_intervention()`, dann bis `until_day`; zurück je abgelehntem Eintrag
  `{ "record": Dictionary, "reason": String }` „in der Reihenfolge des Nachspielens“.
  `WhatIfProbe.build_run()` nutzt es und setzt `not_applicable` wie bisher. Tests in
  `src/test/test_timeline_run.gd`: dieselben Fahrpläne wie mit dem bisherigen Nachspielen, ein
  abgelehnter Eintrag mit Grund. Feste Größe wie T003. Hängt an T003 (beide ändern
  `what_if_probe.gd`).
- [x] T005 [A] [P] `EventCatalog.from_data(data, issues)` in `src/core/timeline/event_catalog.gd`
  laut spielstand.md; `from_json()` parst und ruft es. „Die Meldungen von `from_json()` bleiben
  Zeichen für Zeichen gleich“; `test_event_catalog.gd` läuft unverändert. Neue Fälle dort: ein
  Objekt ohne JSON-Text, eine Zahl statt Objekt, Format 2.
- [x] T006 [A] `src/core/save/save_game.gd` (`SaveGame`) laut spielstand.md und data-model.md,
  „SaveGame“:
  - Felder mit den Regeln der Tabelle, darunter: `name` „nicht leer; beim Anlegen „Spiel N““,
    `seed` „0 bis 2.147.483.647“, `day` „0 bis 5477, also 01.01.1985 bis 31.12.1999“,
    `created_at` und `last_played_at` als Unix-Zeit, in der Datei „UTC, lesbar“ mit „Z“, `catalog`
    „lässt sich lesen; Fehler in Einträgen erlaubt“, `interventions` „jedes Datum gültig“,
    `"format": 1`.
  - `to_json()` kanonisch: „Schlüssel alphabetisch, Tabs, ein Zeilenumbruch am Ende“; Katalog über
    `EventCatalog.to_dict()`, Eingriffe über `InterventionFile.to_file()`.
  - `from_data(data, p_number, problems)` mit allen Zeilen der Tabelle „Zustand“ außer Format > 1,
    je mit dem Satz aus data-model.md; Pflichtfelder laut data-model.md, „ein leerer `name` zählt
    wie ein fehlender“ (Analyse, B3); `_upgrade(data, from_format)` als Stelle für spätere
    Formatversionen (Analyse, E4); `default_name()`, `day_text()` („14.03.1986“), `time_text()`
    („26.10.2026 21:40“, Ortszeit) und `time_sentence()` („am 26.10.2026 um 21:40 Uhr“), beide mit
    `bias_minutes` (Analyse, C3). Feldnamen und Werte aus der Datei stehen nur im Protokoll, nie im
    Satz für den Spieler (Analyse, B4).

  Test `src/test/test_save_game.gd`: Rundreise Speicher → Text → Speicher, der Text Zeichen für
  Zeichen gegen eine Erwartung; jede Zeile der Tabelle mit ihrem Grund; Zeitpunkte als UTC; Ortszeit
  mit vorgegebenem Versatz. Hängt an T003 und T005.
- [x] T007 [A] `src/core/save/save_slot.gd` (`SaveSlot`) laut spielstand.md: `State { OK,
  DAMAGED, TOO_NEW }`, `read()` „wirft nie und gibt nie null zurück“, die Prüfreihenfolge aus
  data-model.md, „Zustand“, mit Format > 1 als `TOO_NEW` „Stammt aus einer neueren Version des
  Spiels.“, `push_warning()` mit Datei, Feld und Stelle; `can_resume()`, `display_name()`. Dazu die
  Fixtures unter `src/test/fixtures/spielstaende/` aus spielstand.md, „Tests“:
  `spiel_kein_json.json`, `spiel_format_2.json`, `spiel_ohne_format.json`,
  `spiel_grad_extrem.json`, `spiel_seed_negativ.json`, `spiel_seed_zu_gross.json`,
  `spiel_datum_2000.json`, `spiel_eingriff_datum.json`, `spiel_katalog_zahl.json` und
  `spiel_gueltig.json` mit `catalog_alle_arten.json` und einem Eingriff. Tests in
  `src/test/test_save_game.gd`: jede Fixture mit Zustand und Grund. Hängt an T006.
- [x] T008 [A] `src/core/save/save_store.gd` (`SaveStore`) laut spielstand.md und data-model.md,
  „SaveStore“:
  - Dateien nur nach dem Muster `spiel_<N>.json`, `.json.neu`, `.json.alt`, „N eine Zahl ohne
    führende Null“; fremde Dateien nie gelistet, nie gelöscht.
  - `list_slots()`: je Nummer nach der Regel „Lesen“ aus R3: `.json`, wenn sie fortsetzbar oder
    zu neu ist, sonst die erste fortsetzbare von `.neu` und `.alt`; ein zu neuer Spielstand fällt
    nie auf eine Zwischendatei zurück (Analyse, B2). Lesen aus `.neu` oder `.alt` mit
    `push_warning()` (CHK021); eine allein stehende `.neu`, die nicht fortsetzbar ist, erscheint
    nicht; Ordnung nach R12; fehlt der Ordner, leer.
  - `next_number()`: „größte Nummer unter allen Dateien nach dem Muster, auch `.neu` und `.alt`,
    plus 1; ohne Dateien 1“.
  - `write(game, is_new)`: die fünf Schritte aus R3, mit dem Aufräumen in Schritt 1 und 3 und dem
    Vergleich „Text gleich `to_json()`“ in Schritt 2 (Analyse, B1, C5); mit `is_new` nur, wenn es
    zur Nummer keine Datei gibt, sonst `ERR_ALREADY_EXISTS` (CHK002); `last_error` nennt Datei und
    Schritt.
  - `delete(number)`: nur die drei Dateien dieser Nummer (FR-018), in der Reihenfolge `.json`,
    `.neu`, `.alt`; scheitert eine, hört es dort auf, gibt den Fehler zurück und setzt
    `last_error`. So bleibt nach einem Fehlschlag die Zwischendatei, aus der der Spielstand noch
    lesbar ist; `path_of()`.

  Test `src/test/test_save_store.gd` mit der Liste aus spielstand.md, darunter jeder Abbruch aus R3
  mit dem lesbaren Stand danach, die Regel „Lesen“ mit einer zu neuen `.json` neben einer
  fortsetzbaren `.alt`, Speichern scheitert über einen Ordner mit Inhalt an der Stelle der `.neu`,
  Löschen scheitert über einen Ordner mit Inhalt an der Stelle von `spiel_N.json` neben einer
  fortsetzbaren `spiel_N.json.alt`, und der Spielstand ist danach noch in der Liste (Analyse, E2),
  beschädigte und zu neue nie überschrieben, und 20 Spielstände mit `catalog_500.json` in
  höchstens 1 s gelesen (SC-002). Reicht die Sekunde nicht, meldet der Agent das mit der Messung,
  statt die Prüfung zu ändern (R10). Hängt an T007.
- [x] T009 [A] `src/test/test_save_resume_run.gd` (SC-003 im Kern): Seeds 1, 4711, 99999 in allen
  drei Graden, ein Lauf ohne Pause gegen einen, der am 14.03.1986 über `SaveGame.to_json()` und
  `SaveSlot.read()` als Datei gespeichert, gelesen und mit `replay()` bis zum 31.12.1999
  weitergespielt wird; alle Zeilen ab dem 15.03.1986 gleich. Dasselbe mit Eingriffen vor und nach
  dem 14.03.1986. Eine Kopie mit einem fehlerhaften Ereignis läuft ohne dieses weiter, und ein
  Spielstand läuft mit seinem Katalog weiter, auch wenn der aktuelle ein anderer ist (FR-022;
  Analyse, E1). Katalog `catalog_alle_arten.json`. Hängt an T004 und T008.
- [x] T010 [C] Phasenprüfung Phase 2 mit `/dcl-phasenpruefung`, **Beginn des Piloten** (Analyse,
  F7): Text-Prüfer mit `Sprache.md` und der Textliste der Gründe aus `save_slot.gd` und
  `save_game.gd`; Befunde nachprüfen, zählen.
- [x] T011 [K] Phase 2 abnehmen nach quickstart.md, Abschnitt 1.

Erledigt am 2026-10-26, von Klaus abgenommen: 747 Tests zweimal grün, Startprobe still, Proben
Byte für Byte gleich, SC-002 mit rund 0,6 s. Phasenprüfung mit dem Text-Prüfer: 7 Befunde, alle
behoben; Klaus hat entschieden, dass die Gründe nur Spielerwörter nennen und Listenspalten die
Uhrzeit ohne „Uhr“ zeigen (Style-Guide, Version 24).

**Checkpoint**: Spielstände lassen sich lesen, prüfen, sicher schreiben und löschen; ein
gespeichertes Spiel läuft weiter wie ohne Pause. Abnahme durch Klaus, dann Auftrag für Phase 3.

---

## Phase 3: Spielablauf (Kern für US1, US2, US3)

**Purpose**: Kein Spiel startet mehr von selbst; `GameSession` legt an, setzt fort, speichert und
verlässt, auch beim Schließen des Fensters.

- [x] T012 [A] [P] `GameClock.set_date(new_date)` in `src/core/game_clock.gd` laut spielablauf.md:
  „ohne Signale“, `paused` bleibt; am 31.12.1999 nicht am Ende. Test in
  `src/test/test_game_clock.gd`.
- [x] T013 [A] `src/core/timeline.gd` laut spielablauf.md:
  - `_ready()` ohne `start_game.call_deferred()` (FR-003);
  - `resume_game(game_catalog, seed, difficulty, interventions, day)`: Kopie prüfen wie
    `_load_catalog()`, Lauf anlegen, `replay()`, still bis `day`; „das erste [Signal] kommt für
    den Tag nach [param day]“; abgelehnter Eingriff als `push_warning()`; `ERR_INVALID_PARAMETER`
    bei Seed, Grad oder Tag außerhalb, ein laufendes Spiel bleibt;
  - `stop_game()`, `is_running()`.

  `src/test/test_timeline.gd`: Der Helfer `_zeitleiste()` startet kein Spiel mehr, sein
  Doc-Kommentar sagt das. Fünf Tests nutzten den Selbststart und rufen künftig `start_game()` selbst
  auf, mit unveränderten Erwartungen: `test_ohne_seed_wird_gewuerfelt`,
  `test_ohne_grad_gilt_mittel`, `test_meldung_zu_einem_profil_bekommt_keinen_zusatz_zum_ereignis`,
  `test_fehlender_katalog_ergibt_leeren_lauf_und_fehlermeldung` und
  `test_unlesbarer_katalog_ergibt_leeren_lauf_und_fehlermeldung` (Analyse, F1). Neu: Nach `_ready()`
  und zwei Bildern läuft kein Spiel, und Uhrtage senden nichts; `resume_game()` am 14.03.1986 sendet
  für den 14.03. nichts und ab dem 15.03. dasselbe wie ein Spiel ohne Pause, Tag für Tag bis zum
  31.12.1986, Seed 4711, Schwer (US3, Szenario 4); `resume_game()` nimmt die übergebene Kopie, nicht
  den Katalog der Zeitleiste; Grenzen; `stop_game()`. In `src/test/test_title_screen.gd`: Die
  Hauptszene läuft mehrere Bilder, danach läuft kein Spiel (US1, Szenario 5); dass dabei auch keine
  Datei entsteht, prüft T020, sobald `TitleScreen.session` da ist. **Feste Größe:** Ein Spiel mit
  `start_game(4711)` sendet dieselben Signale wie vorher. Hängt an T004.
- [x] T014 [A] `src/core/game_session.gd` (Autoload `GameSession`) laut spielablauf.md und
  data-model.md, „GameSession“; in `src/project.godot` als viertes Autoload nach `GameWindow`:
  - Felder `folder`, `clock`, `timeline`, `now`, `rng`, `quit_callback`, `current`,
    `last_error`; Signal `save_failed`.
  - `start_new()` in der Reihenfolge aus data-model.md (Analyse, C6): Seed mit `rng`, „Spiel N“
    mit dem Katalog der Zeitleiste, `write(game, true)` mit Ausweichen auf die nächste Nummer
    (CHK002), erst dann Uhr auf 01.01.1985 und `Timeline.start_game(seed, difficulty)`; bei Fehler
    beginnt kein Spiel, und die Zeitleiste sendet nichts.
  - `resume()` nur bei `OK`, sonst `ERR_UNAVAILABLE`; Uhr auf `day`, `resume_game()`, „zuletzt
    gespielt“ = jetzt, speichern (R9); scheitert das, läuft das Spiel, `resume()` gibt OK zurück,
    `last_error` ist „Speichern ging nicht. Dein Spiel läuft weiter.“, `save_failed` kommt
    (Analyse, F5).
  - `save()` mit dem Tag der Uhr, höchstens `TimelineRun.LAST_DAY` (Analyse, C11); `leave()`;
    `last_error` nach jedem gelungenen Speichern leer.
  - `auto_accept_quit` aus, solange ein Spiel läuft; `_notification()` für
    `NOTIFICATION_WM_CLOSE_REQUEST`: speichern und beenden, bei Fehler offen bleiben, beim zweiten
    Mal ohne Speichern beenden (R8).
  - Die Meldungen zum Speichern als Konstanten: „Speichern ging nicht. Dein Spiel läuft weiter.“
    (auch beim Beenden; bis zur Phasenprüfung von Phase 3 stand dort „Speichern ging nicht.
    Schließt du noch einmal, dann ohne.“) und „Speichern ging nicht. Es ist kein Spiel angelegt.“

  Test `src/test/test_game_session.gd` mit der Liste aus spielablauf.md, darunter SC-005
  (01.01.1985, 15.02.1985, 14.03.1986, 31.12.1999, vorgespult mit der eigenen Uhr); zwei Fenster:
  eine Datei mit der nächsten Nummer liegt schon da, das neue Spiel weicht aus, ohne sie zu berühren
  (Analyse, C4); `rng` mit festem Seed ergibt den erwarteten Seed, das nächste Spiel einen anderen;
  Katalog der Zeitleiste tauschen und fortsetzen, der Fahrplan ist der gespeicherte (FR-022;
  Analyse, E1); Fortsetzen nach dem Löschen der Datei von außen schreibt den gelesenen Stand wieder
  (Analyse, E3); ein Spielstand mit `catalog_500.json` vom 31.12.1999 in höchstens 1 s fortgesetzt
  (SC-002), Speichern scheitert beim Anlegen, Fortsetzen, Verlassen und Schließen. Jeder Test mit
  eigener Uhr, Zeitleiste und eigenem Ordner unter `user://`. Hängt an T008, T012 und T013.
- [x] T015 [C] Phasenprüfung Phase 3 mit `/dcl-phasenpruefung`: Text-Prüfer mit `Sprache.md` und den
  Meldungen aus `game_session.gd`; Befunde nachprüfen, zählen (Analyse, F18); dazu prüft Claude die
  Startprobe: still, und danach keine neue Datei in `user://spielstaende/` (FR-003).
- [x] T016 [K] Phase 3 abnehmen nach quickstart.md, Abschnitte 1 und 2.

Erledigt am 2026-10-26, von Klaus abgenommen: 783 Tests zweimal grün, Startprobe still,
`start_game(4711)` unverändert, Fortsetzen vom 31.12.1999 in rund 0,15 s. Phasenprüfung mit dem
Text-Prüfer: 1 Befund im Protokoll, behoben; Klaus hat entschieden, dass beim Beenden nur der
Fehler erscheint („Speichern ging nicht. Dein Spiel läuft weiter.“).

**Checkpoint**: Ein Spiel beginnt, läuft weiter und endet nur über `GameSession`; im Hintergrund
läuft nichts. Abnahme durch Klaus, dann Auftrag für Phase 4.

---

## Phase 4: User Story 1 und 2 - Neues Spiel beginnen und verlassen (Priority: P1) 🎯 MVP

**Goal**: Vom Hauptmenü über die Gradwahl auf den Spielbildschirm und mit „Zum Hauptmenü“ zurück,
gespeichert.

**Independent Test**: Quickstart 3.1: „Neues Spiel“, „Leicht“, Spielbildschirm; `spiel_1.json` mit
Leicht am 01.01.1985; „Zum Hauptmenü“ wählt danach „Weiterspielen“ vor.

**Erste Phasenprüfung mit dem Stil-Prüfer.** Braucht Phase 1 und Phase 3.

- [x] T017 [A] Vor jeder Änderung ein Bild des Hauptmenüs ohne Spielstände mit `scripts/fotos.gd`
  aus `dcl-phasenpruefung` in den Scratchpad legen, nicht ins Repo (Analyse, C8). Dann
  `src/scenes/title/menu_paper.gd` (`MenuPaper`, statische Funktionen) aus dem Malen in `MainMenu`:
  Papier, Zebra, Lochränder, Schatten, Auswahl, Pfeil. `src/scenes/title/main_menu.gd` und
  `main_menu.tscn`: `header_text`, `paper_width`, `set_entries(new_entries, index)`.
  `src/scenes/title/menu_entry.gd`: die neuen Kennungen aus titelbildschirm.md. Test
  `src/test/test_main_menu.gd` erweitert; `PAPER_WIDTH` bleibt als Vorgabe von `paper_width`
  (Analyse, F11). **Feste Größe:** Das Hauptmenü sieht Pixel für Pixel aus wie das Bild von vorher,
  verglichen nach der Änderung; die bisherigen Erwartungen bleiben.
- [x] T018 [A] [P] Baustein Knopf und Meldung laut titelbildschirm.md und Style-Guide aus T001:
  `src/ui/knopf.gd` (`Knopf`, Relief und Fokuslinie in `_draw()`, `on_dark`), Theme-Varianten
  `Knopf` und `WarningPanel` in `src/ui/computerladen_theme.tres`, `MenuHint.show_text()` und
  `show_warning()` in `src/scenes/title/menu_hint.gd` (Analyse, C2). Tests
  `src/test/test_knopf.gd`: Farben nur aus der Palette, Relief, Fokuslinie hell und dunkel; und
  `src/test/test_menu_hint.gd`: `show_text()` und `show_warning()` mit Lage, Breite und Kontur
  (Analyse, F16).
- [x] T019 [A] [P] `src/scenes/title/title_texts.gd` (`TitleTexts`): alle Texte aus
  titelbildschirm.md, „Texte“, mit Platzhaltern, auch die Sätze zu den Graden (Leicht „Das Glück
  ist eher auf deiner Seite.“, Mittel „Das Glück hält sich raus.“, Schwer „Das Glück ist eher auf
  der Seite der anderen.“), „Nicht löschen. Esc geht auch.“, die Rückfrage bei nicht fortsetzbaren
  Spielständen und „Löschen ging nicht. Der Spielstand ist noch da.“ Test
  `src/test/test_title_texts.gd`: Jeder Text mit den längsten Platzhaltern („Spiel 9999“,
  „Schwer“, „neuere Version“) passt in höchstens zwei Zeilen des Hinweises, gemessen mit der
  Schrift des Themes; ebenso die zwei Meldungen aus `GameSession` und die Gründe aus `SaveGame`
  und `SaveSlot` (Analyse, C10).
- [x] T020 [A] [US1] `src/scenes/title/title_screen.gd` und `title_screen.tscn`, Teil 1, laut
  titelbildschirm.md und data-model.md, „Titelbildschirm: Blätter und Wege“:
  - `session` (null heißt `GameSession`) und `scene_callback` (ungültig heißt
    `change_scene_to_file()`; Analyse, C1); fünf Einträge nach FR-001; Verfügbarkeit und Hinweise
    nach FR-002 aus `TitleTexts`; Vorwahl „Weiterspielen“ oder „Neues Spiel“ (FR-001a); der Ordner
    wird beim Erscheinen und bei jeder Rückkehr ins Hauptmenü neu gelesen (Analyse, F2).
  - DifficultySheet als zweite Instanz von `main_menu.tscn`, SCHWIERIGKEIT, vier Einträge Leicht,
    Mittel, Schwer, Zurück aus `TitleTexts`, Mittel vorgewählt, die Sätze als Hinweis (FR-004).
  - Esc und „Zurück“ eine Ebene zurück, im Hauptmenü nichts; zurück steht die Auswahl auf dem
    Eintrag, der das Blatt geöffnet hat.
  - Bestätigen: `session.start_new()`, bei OK über `scene_callback` zum Spielbildschirm, sonst
    Meldung auf der Gradwahl. „Weiterspielen“: `session.resume()` mit dem ersten fortsetzbaren
    Spielstand.

  Test `src/test/test_title_screen.gd` mit eigener Session, eigenem Ordner und eigenem
  `scene_callback`: fünf Einträge,
  Vorwahl ohne, mit und mit nur beschädigten Spielständen, Hinweise, Gradwahl mit Tastatur und
  Maus, Esc, Abbrechen legt keine Datei an (US1, Szenario 3), SC-001 mit 3 Eingaben,
  „Weiterspielen“ mit 1 Eingabe (SC-002), Meldung bei gescheitertem Anlegen. Hängt an T014, T017,
  T018 und T019.
- [x] T021 [A] [US2] `src/scenes/game/game_screen.tscn` und `game_screen.gd` (`GameScreen`) laut
  titelbildschirm.md: Grund `nacht`, `LeaveButton` mit `knopf.gd` und `on_dark`, Lage laut
  Style-Guide (README, „Bildaufbau“; Analyse, D1), Fokus von Anfang an, Hinweis über
  `show_text()` links daneben „Speichert Spiel 2 und führt ins Hauptmenü.“ aus `TitleTexts`; Esc
  tut nichts; Knopf: `session.leave()`, bei OK über `scene_callback` zum Titelbildschirm, sonst
  Meldung; `save_failed` und `last_error` beim Erscheinen zeigen die Meldung. Test
  `src/test/test_game_screen.gd` nach titelbildschirm.md. Hängt an T014, T018 und T019 (Analyse,
  F8).
- [x] T022 [A] [US1] Bildschirmfotos und Platz laut titelbildschirm.md, „Bildschirmfotos und
  Platz“, für die Teile dieser Phase: Hauptmenü ohne und mit Spielständen, Gradwahl mit dem Satz zu
  Mittel, Spielbildschirm mit Hinweis und mit Meldung; mit `scripts/fotos.gd` im Raster 640 × 360
  und dreifach, mit eigener Session und einem Ordner unter `user://test_fotos/`, nie mit den echten
  Spielständen (Analyse, C7); dazu die Aussage, ob jede Zeile und jeder Hinweis in sein Feld passt.
  Ins Repo kommt kein Foto.
- [x] T023 [C] [US1] Phasenprüfung Phase 4 mit `/dcl-phasenpruefung`, Pilot: Stil-Prüfer mit README,
  Bausteinen Menü, Hinweis, Knopf, Meldung und `tokens.json`; Text-Prüfer mit `Sprache.md` und der
  Textliste aus `title_texts.gd`, `game_screen.gd` und `title_screen.tscn` (Analyse, F19); Befunde
  nachprüfen, bestätigte an den Agent, zählen für `ki_pruefung.md`, „Nachmessen“.
- [x] T024 [K] [US1] Phase 4 abnehmen nach quickstart.md, Abschnitte 1, 2 und 3.1.

Erledigt am 2026-10-26, von Klaus abgenommen: 853 Tests zweimal grün, Startprobe still, Hauptmenü
vor und nach dem Umbau des Papiers Pixel für Pixel gleich. Erste Phasenprüfung mit Stil- und
Text-Prüfer; Klaus hat entschieden: Rückfrage mit dem Namen vorn, kein Loch an der Unterkante,
Hinweis am allein stehenden Knopf ab der Fokuslinie (Style-Guide, Version 27). „Spiel laden“
tut bis T026 noch nichts.

**Checkpoint**: Ein neues Spiel lässt sich beginnen, verlassen und mit „Weiterspielen“ fortsetzen
(US1, US2). Abnahme durch Klaus, dann Auftrag für Phase 5.

---

## Phase 5: User Story 3 und 4 - Fortsetzen über die Liste und Löschen (Priority: P2, P3)

**Goal**: Die Liste der Spielstände mit Fortsetzen, Löschmodus und Rückfrage.

**Independent Test**: Quickstart 3.2 bis 3.4: drei Spiele in der Liste, das älteste fortsetzen,
eins löschen, nicht fortsetzbare gedämpft und löschbar.

- [x] T025 [A] [US3] `src/scenes/title/save_list.tscn` und `save_list.gd` (`SaveList`) laut
  titelbildschirm.md: Signale,
  `show_slots()`, `set_delete_mode()`, `is_delete_mode()`, `selected_slot()`; die Werte von
  `VISIBLE_ROWS`, `COLUMNS` und `PAPER_WIDTH` aus dem Style-Guide, Baustein Liste (Analyse, D1);
  Papier über `MenuPaper`; Fenster aus Zeilen statt `ScrollContainer` (R12); Rollmarken in Kopfzeile
  und Zeile „Löschen …“; gedämpfte Zeilen; Namen mit „…“ gekürzt, wenn sie nicht passen; „Löschen
  …“ im Löschmodus nicht verfügbar (FR-017a); `back_requested` auch im Löschmodus; Hinweise über
  `show_text()` aus `TitleTexts`, auch „Zuletzt gespielt am …“, der Grund und im Löschmodus „Nicht
  löschen. Esc geht auch.“ bei „Zurück“ (Analyse, F3). Test
  `src/test/test_save_list.gd` nach titelbildschirm.md, mit 3, 7 und 20 Spielständen. Hängt an
  T017, T018 und T019.
- [x] T026 [A] [US3] `title_screen.gd`, Teil 2: „Spiel laden“ öffnet die Liste, „bei jedem Öffnen
  neu gelesen“ (CHK001); eine fortsetzbare Zeile setzt fort; nicht fortsetzbare lösen außerhalb des
  Löschmodus nichts aus. Tests in `test_title_screen.gd`: 2 Klicks und höchstens 4 Tasten über
  die Liste, Anzeige mit 20 Spielständen in höchstens 1 s (SC-002), ein älterer Spielstand rückt
  nach dem Fortsetzen nach oben (US3, Szenario 3), eine Datei, die nach dem Erscheinen des Titels
  in den Ordner kommt, steht beim Öffnen der Liste darin (Analyse, E3). Hängt an T020 und T025.
- [x] T027 [A] [US4] Löschen in `title_screen.gd` und `title_screen.tscn`: ConfirmSheet als
  Instanz von `main_menu.tscn`, LÖSCHEN?, „Abbrechen“ vorgewählt und „Spiel 2 löschen“, Hinweise
  mit Name, Grad und Spieldatum, bei nicht fortsetzbaren mit dem Zustand (FR-017); Esc und
  „Abbrechen“ zurück zur Liste, Löschmodus aus; „Zurück“ und Esc im Löschmodus beenden nur den
  Modus (Analyse, F3); bestätigt `store().delete()`, Liste neu, Auswahl nach data-model.md; leer,
  dann Hauptmenü mit „Neues Spiel“; Löschen scheitert: Meldung, Liste neu, Löschmodus aus (CHK003).
  Tests in `test_title_screen.gd` und `test_save_list.gd`: alle Szenarien von US4, das Ende des
  Löschmodus auf allen vier Wegen, fremde Dateien bleiben; den zuletzt gespielten löschen, zurück
  ins Hauptmenü, „Weiterspielen“ nennt den nächsten (Analyse, F2); Löschen scheitert über einen
  Ordner mit Inhalt an der Stelle von `spiel_N.json` neben einer fortsetzbaren `spiel_N.json.alt`:
  Meldung, der Spielstand steht weiter in der Liste (Analyse, E2). Hängt an T026.
- [x] T028 [A] [US3] [US4] Bildschirmfotos und Platz für diese Phase: Liste mit 3 und mit 9
  Spielständen, darunter ein beschädigter und ein zu neuer, aus den Fixtures im Fotoordner;
  Löschmodus; Rückfrage; wie T022.
- [x] T029 [C] [US3] [US4] Phasenprüfung Phase 5 mit `/dcl-phasenpruefung`: Stil- und Text-Prüfer
  wie T023, dazu Baustein Liste und Rückfrage und die Gründe aus `save_slot.gd` und `save_game.gd`
  (Analyse, F17); Befunde nachprüfen, zählen.
- [x] T030 [K] [US3] [US4] Phase 5 abnehmen nach quickstart.md, Abschnitte 1, 2 und 3.2 bis 3.5.

**Checkpoint**: Alle vier User Stories sind erfüllt. Abnahme durch Klaus, dann Auftrag für den
Abschluss.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Doku, Pilot auswerten, Lückensuche, Gesamtabnahme

- [x] T031 [C] Doku nachziehen:
  - `CLAUDE.md`: Tabelle „Aufbau“ mit `src/core/save/` und `src/scenes/game/`; `GameSession` bei den
    Autoloads; die Zeitleiste startet kein Spiel mehr von selbst. Claude schlägt den Wortlaut vor;
    eingetragen wird er erst mit Klaus' OK.
  - `docs/features/Features.md`: Stand von Feature 004.
  - `docs/features/Feature_Ideas.md`: 11-01 Spielstände und 01-05 Neues Spiel mit Verweis auf
    Feature 004; was offen bleibt, etwa ein späteres Startdatum.
- [x] T032 [C] Pilot auswerten: die Zählung aller Phasenprüfungen in
  `docs/ki_workflow/ki_pruefung.md`, „Nachmessen“, und unter „Erfahrungen“, was der Pilot gelehrt
  hat. Klaus entscheidet danach, ob die Prüfer bleiben und ob die Regel in die Verfassung kommt
  (Schritt 10).
- [x] T033 [C] Lückensuche mit `/speckit-converge` über das ganze Feature (`ki_dev.md`, „Ablauf je
  Feature“, Punkt 6); dabei Stil- und Text-Prüfer einmal über alles. Die Lernnotizen aller Phasen
  stehen vollständig in `specs/004-neues-spiel/lernnotizen.md`. Gefundene Lücken werden eine
  eigene Phase mit Klaus' Freigabe, die vor T034 fertig ist; ändert sie Sichtbares oder Texte, endet
  sie mit einer eigenen Phasenprüfung (Analyse, D3).
- [ ] T034 [K] Quickstart vollständig durchgehen, Abschnitte 1 bis 4, dazu die Quickstarts von
  Feature 001 bis 003 mit den zwei bekannten Ausnahmen (quickstart.md, Einleitung). Hängt an T033
  und an den Phasen für Lücken (7 und 8).
- [ ] T035 [K] Feature abnehmen: Die Abnahmen T002, T011, T016, T024, T030 und T034 sind erledigt.
  Dann entscheidet Klaus über den Merge nach `main`.

---

## Abdeckung der Anforderungen

| Anforderung | Tasks |
|---|---|
| FR-001 fünf Einträge | T017, T019, T020 |
| FR-001a Vorwahl | T020 |
| FR-002 nicht verfügbar mit Grund | T019, T020 |
| FR-003 kein Spiel ohne Beginn | T013, T015 |
| FR-004 Gradwahl mit Sätzen | T001, T019, T020 |
| FR-005 bestätigen und abbrechen | T020 |
| FR-006 Spiel beginnen und speichern | T014, T020 |
| FR-007 Inhalt des Spielstands | T006 |
| FR-008 gleicher Verlauf | T004, T009, T013 |
| FR-009 beliebig viele, „Spiel N“ | T008, T014 |
| FR-010 automatisch speichern | T014, T021 |
| FR-011 sicher speichern, Meldung | T008, T014, T018, T020, T021 |
| FR-012 Benutzerordner | T008 |
| FR-013 nicht fortsetzbar | T006, T007, T008, T025 |
| FR-014 ältere Formatversion | T006 (`_upgrade()`) |
| FR-015 Liste | T008, T025, T026 |
| FR-016 fortsetzen | T014, T020, T026 |
| FR-017 Rückfrage | T027 |
| FR-017a Löschmodus | T025, T027 |
| FR-018 nur den Spielstand löschen | T008, T027 |
| FR-019 leerer Spielbildschirm | T021 |
| FR-020 Knopf „Zum Hauptmenü“ | T018, T021 |
| FR-021 Style-Guide, duzen | T001, T018, T019, T023, T029 |
| FR-022 eigener Katalog | T006, T009, T013, T014 |
| FR-023 Blätter auf dem Titelbildschirm | T001, T020, T025, T027 |
| SC-001 | T020 |
| SC-002 | T008, T014, T020, T026 |
| SC-003 | T009, T013 |
| SC-004 | T007, T008, T014 |
| SC-005 | T014 |
| SC-006 | T013, T015, T017, T020 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Style-Guide):** hängt an nichts; kommt vor Phase 2.
- **Phase 2 (Kern Spielstand):** braucht die Abnahme von Phase 1 (Reihenfolge der Phasen).
  - T003, dann T004; T005 parallel zu T003.
  - T006 braucht T003 und T005, T007 braucht T006, T008 braucht T007, T009 braucht T004 und T008.
- **Phase 3 (Spielablauf):** braucht Phase 2.
  - T012 parallel zu T013; T014 braucht T008, T012 und T013.
- **Phase 4 (US1, US2):** braucht Phase 1 und 3.
  - T017, T018 und T019 parallel; T020 braucht alle drei und T014; T021 braucht T014, T018 und
    T019; T022 nach T020 und T021.
- **Phase 5 (US3, US4):** braucht Phase 4.
  - T025 braucht T017, T018 und T019; T026 braucht T020 und T025; T027 braucht T026; T028 danach.
- **Phase 6:** braucht alle User Stories. T034 kommt nach T033 und einer Phase für Lücken.

Umgesetzt wird in der Reihenfolge der Phasen, eine nach der anderen (Verfassung, Grundsatz II;
plan.md; Analyse, D2).

### User Story Dependencies

- **US1** und **US2** kommen zusammen in Phase 4; ohne Ausgang aus dem Spiel ist ein neues Spiel
  nicht prüfbar. Zusammen sind sie das MVP.
- **US3** braucht die Blätter aus Phase 4; „Weiterspielen“ ist schon in Phase 4 da.
- **US4** braucht die Liste aus US3.
- `title_screen.gd` ändern T020, T026 und T027 nacheinander.

### Within Each Phase

- Erst Klassen und Logik, dann Tests, dann die Oberfläche, dann Bildschirmfotos, Phasenprüfung und
  die Abnahme durch Klaus.
- Eine Phase gilt erst als fertig, wenn Claude das Ergebnis des Agents geprüft hat (Tests zweimal,
  Startprobe, feste Größen, Code an den kritischen Stellen) und Klaus es abgenommen hat.

### Parallel Opportunities

- Phase 2: T005 parallel zu T003.
- Phase 3: T012 parallel zu T013.
- Phase 4: T017, T018 und T019 parallel.

---

## Parallel Example: Phase 4

```text
# Nach Phase 1 und 3 baut der Agent Papier, Knopf und Texte gleichzeitig:
Task: "T017 [A] MenuPaper und MainMenu in src/scenes/title/menu_paper.gd und main_menu.gd"
Task: "T018 [A] Knopf und Meldung in src/ui/knopf.gd und src/scenes/title/menu_hint.gd"
Task: "T019 [A] Texte in src/scenes/title/title_texts.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 und 2)

1. Phase 1: Style-Guide, von Klaus freigegeben.
2. Phase 2 und 3: Kern. **Halt und prüfen:** Ein gespeichertes Spiel läuft weiter wie ohne Pause
   (T009, T013), und ohne Beginn läuft keins (T015).
3. Phase 4: US1 und US2. **Halt und prüfen:** Neues Spiel, verlassen, „Weiterspielen“ (T024).

### Incremental Delivery

1. Style-Guide: Blätter, Liste, Meldung und Knopf sind beschrieben.
2. Kern: Spielstände und Spielablauf stehen, ohne Oberfläche.
3. US1 und US2: neues Spiel beginnen und verlassen.
4. US3 und US4: Liste, Fortsetzen und Löschen.
5. Jede Phase einzeln von Klaus beauftragt und abgenommen.

### Arbeitsteilung

- Claude beauftragt den Agent je Phase mit den `[A]`-Tasks und prüft sein Ergebnis gegen Verträge,
  Verfassung und Style-Guide. Dann bekommt Klaus Diff, Erklärung und Lernnotiz.
- `[K]`-Tasks erledigt Klaus selbst. Vor jeder Phase kann er sich `[A]`-Tasks oder Teile davon
  nehmen. Gute Kandidaten (plan.md, „Was Klaus dabei lernt“): die Gradwahl als zweite Instanz von
  `main_menu.tscn` im Editor mit Lage und Kopfzeile, die Einträge kommen aus `TitleTexts` (Teil von
  T020; Analyse, F4) und der Spielbildschirm als Szene mit `ColorRect` und
  Knopf samt Signalverbindung im Editor (Teil von T021).
- `[C]`-Tasks erledigt Claude.
- Committet wird nach Klaus' Abnahme einer Phase, auf `feature/004-neues-spiel`.

---

## Notes

- Format: Task-ID, Besitzer, `[P]` für parallel ausführbar, `[Story]` für die User Story.
- Die Verfassung verlangt kein testgetriebenes Vorgehen; Tests entstehen mit der Logik und müssen
  vor der Abnahme grün sein.
- Zu jeder umgesetzten Task gibt es eine Lernnotiz in `specs/004-neues-spiel/lernnotizen.md`
  (Verfassung, Grundsatz II). Bei `[A]`-Tasks schreibt sie der Agent, und Claude trägt sie nach
  jeder Phase ein. Baut Klaus eine Task selbst, schreibt Claude die Notiz beim Review.
- Nach dem Anlegen von Skripten ruft der Agent einmal `Godot --headless --path src --import` auf.
  Erst dabei bekommen neue Skripte ihre `.uid`, und Godot lernt neue `class_name` kennen. Neue
  `.uid`-Dateien werden committet.
- **Feste Größen** für jeden Auftrag an den Agent:
  - Proben der Werkstatt bleiben Byte für Byte gleich; `test_what_if_probe.gd` und
    `test_simulator.gd` laufen unverändert (ab T003).
  - Ein Spiel mit `start_game(4711)` sendet dieselben Signale wie vor dem Feature (ab T013).
  - Das Hauptmenü sieht Pixel für Pixel aus wie vorher, bis auf Einträge, Hinweise und Höhe
    (ab T017; SC-006).
  - Die Startprobe mit `-d` bleibt still, und danach gibt es keine neue Datei in
    `user://spielstaende/`.
- **Echte Daten:** Kein Test schreibt nach `user://spielstaende/`; jeder Test setzt einen eigenen
  Ordner unter `user://` und räumt ihn ab. Den echten Katalog `src/data/event_catalog.json` fasst
  der Agent nicht an; Tests nehmen Kataloge aus `src/test/fixtures/`.
- **Nur ein Testlauf zur selben Zeit:** Alle Sitzungen teilen sich `user://` (`ki_pruefung.md`,
  „Tests“).
- Braucht der Agent einen Baustein oder eine Regel, die der Style-Guide nach T001 nicht hat, hält
  er an und fragt (Grundsatz IV).

---

## Phase 7: Convergence

**Purpose**: Lücken aus T033 (`/speckit-converge`, Stil- und Text-Prüfer über das ganze Feature),
mit Klaus' Entscheidungen vom 2026-10-26. Fertig vor T034. Ändert Texte, endet deshalb mit einer
eigenen Phasenprüfung (Analyse, D3).

- [x] T036 [A] Speichern ohne Verlust bei zwei Fehlern hintereinander in `src/core/save/save_store.gd`,
  Schritt 1: Ist `spiel_N.json.neu` der einzige lesbare Stand (keine lesbare `spiel_N.json`), wird
  sie zu `spiel_N.json.alt` umbenannt statt gelöscht; eine vorhandene `.alt` wird dabei nur
  ersetzt, wenn sie nicht fortsetzbar ist. Test in `src/test/test_save_store.gd`: nur eine
  fortsetzbare `.neu`, das nächste Speichern scheitert nach Schritt 1, der Spielstand ist danach
  noch fortsetzbar; `research.md`, R3, nachziehen [C] per SC-004, Edge Case „Absturz oder
  Stromausfall während des Speicherns“ (contradicts)
- [x] T037 [A] Grund eines zu neuen Spielstands in `src/core/save/save_slot.gd` (`REASON_TOO_NEW`):
  „Mit einer neueren Version gespeichert.“ statt „Stammt aus einer neueren Version des Spiels.“;
  Tests nachziehen; `data-model.md`, Tabelle „Zustand“, nachziehen [C] per FR-013, Style-Guide
  Sprache „Kein Wort für zwei Dinge“ (contradicts)
- [x] T038 [A] Hinweis von „Spiel laden“: immer derselbe Satz „Zurück in einen deiner Läden.“
  in `src/scenes/title/title_texts.gd`, auch wenn sich kein Spielstand fortsetzen
  lässt; nicht verfügbar bleibt „Noch keine Spielstände.“; gesetzt in `title_screen.gd`,
  `_main_entries()`; Tests in `test_title_texts.gd` und `test_title_screen.gd`; Vertrag
  `titelbildschirm.md`, „Texte“, und Style-Guide, Baustein Hinweis, nachziehen [C] per FR-002
  (partial; Klaus, 2026-10-27: keine Hinweise, die mit der Lage wechseln, statt eines eigenen
  Satzes nur fürs Löschen; beim Quickstart um „Oder einen aufgeben.“ gekürzt)
- [x] T039 [A] `SaveGame.time_sentence()` mit seinem Test aus `src/core/save/save_game.gd` und
  `src/test/test_save_game.gd` entfernen; `contracts/spielstand.md` und `data-model.md`
  nachziehen [C] per plan: Vertrag Spielstand (unrequested, seit Phase 5 ungenutzt)
- [x] T040 [A] Die 4 Orphans in `src/test/test_main_menu.gd` beseitigen (Buttons, die ein Test nicht
  freigibt), ohne Erwartungen zu ändern per Verfassung, Arbeitsweise „Tests“ (partial)
- [x] T041 [C] Auslegung in `docs/offene-punkte.md` festhalten: Der Knopf des Spielbildschirms führt
  ohne laufendes Spiel gleich ins Hauptmenü (`game_screen.gd`, für den Start der Szene im Editor)
  per FR-020 (unrequested)
- [x] T042 [C] Phasenprüfung Phase 7 mit `/dcl-phasenpruefung`: Text-Prüfer über die Texte aus T037
  und T038; Tests zweimal, Startprobe.
- [x] T043 [K] Phase 7 abnehmen; danach T034 und T035.

## Phase 8: Prüfordner im Quickstart

**Purpose**: Entscheidungen von Klaus beim Quickstart (T034, 2026-10-27).

- [x] T044 [A] ~~Je Datei nur eine Warnung je Programmstart in `src/core/save/`~~ Verworfen (Klaus,
  2026-10-27): Gebaut und wieder zurückgenommen. Die Regel kostete rund 50 Zeilen Code und ein
  Gedächtnis, das jeder Test leeren musste, nur damit eine Meldung im Protokoll seltener steht.
  Klaus will keine Regel „wurde diese Meldung schon gezeigt“; die Warnung zu einem Spielstand, der
  sich nicht fortsetzen lässt, kommt weiter bei jedem Einlesen des Ordners.
- [x] T045 [C] `quickstart.md`, Abschnitt 4: Der Prüfordner bekommt beim Aufräumen das Datum in
  den Namen (`spielstaende_pruefung_JJJJ-MM-TT`), damit er nie in einem älteren Prüfordner landet
  (Quickstart Feature 004: `spielstaende` landete als Unterordner in `spielstaende_pruefung`).
- [x] T046 [C] Prüfen: Tests zweimal mit derselben Zahl, Startprobe still.
- [x] T047 [K] Phase 8 abnehmen; danach T034 und T035.
