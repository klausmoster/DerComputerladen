# Bestandsbericht: Architektur des Codes aus 001 bis 006

Feature 008, Phase 3 (T022 bis T026). Der Architektur-Prüfer hat den ganzen Code des Spiels und der
Werkstatt gegen den Leitfaden geprüft, in drei Läufen gleichzeitig (research.md, R5). Claude hat
jeden Befund am Code nachgesehen. **Klaus hat am 2026-10-28 alle Abweichungen und Lücken wie
empfohlen entschieden (T027);** eingearbeitet in T028: Lücken und Ausnahme im Leitfaden, Listen im
Vertrag der Tests, Aufgaben T036a und T036b, Einträge 11-09 und 11-10 in `Feature_Ideas.md`.

- **Stand:** `feature/008-architektur` nach Phase 2 (`dbf7efc`), Code wie `main` nach Feature 006
  (`528442e`). **Feature 007 fehlt:** Es ist nicht gemergt; sein Code unter `src/tools/selbsttest/`
  wird in T035 nachgeprüft.
- **Maßstab:** `docs/architektur-leitfaden.md`, AR-01 bis AR-15; AR-16 bis AR-20 nicht, weil die
  Schichten Wirtschaft und Adventure noch nicht begonnen haben.
- **Läufe:** allgemeiner Agent mit der Anweisung `.claude/agents/architektur-pruefer.md`, nur
  lesend, Auftrag „Bestand“.

## Geprüfte Dateien (SC-003)

76 von 76, ohne `src/addons/` und `src/test/`; jede steht im Bericht ihres Laufs unter „Geprüft“.

| Lauf | Dateien | gelesen |
|---|---|---|
| Kern | `src/core/` (28) und `src/project.godot` | alle ganz |
| Spiel und Oberfläche | `src/scenes/`, `src/ui/` (24) und `src/default_bus_layout.tres` | alle ganz |
| Werkzeuge | `src/tools/werkstatt/` (22) | kleine ganz; große Dateien gezielt (Kopf, Aufbau, Stellen mit Autoloads, Pfaden, Signalen, Zufall), Umriss des Rests |

Die Dateien je Lauf, Pfade unter `src/` (nachgetragen nach der Lückensuche T040, FR-025):

**Kern** (29):
`core/game_clock.gd`, `core/game_date.gd`, `core/game_session.gd`, `core/game_window.gd`,
`core/save/save_game.gd`, `core/save/save_slot.gd`, `core/save/save_store.gd`, `core/timeline.gd`,
`core/timeline/catalog_issue.gd`, `core/timeline/catalog_validator.gd`,
`core/timeline/chance_modifier.gd`, `core/timeline/difficulty.gd`,
`core/timeline/difficulty_profile.gd`, `core/timeline/event_catalog.gd`,
`core/timeline/event_category.gd`, `core/timeline/event_condition.gd`,
`core/timeline/event_dice.gd`, `core/timeline/event_effect.gd`, `core/timeline/event_statistic.gd`,
`core/timeline/follow_up.gd`, `core/timeline/intervention_file.gd`,
`core/timeline/schedule_diff.gd`, `core/timeline/schedule_entry.gd`,
`core/timeline/schedule_text.gd`, `core/timeline/timeline_event.gd`,
`core/timeline/timeline_message.gd`, `core/timeline/timeline_run.gd`,
`core/timeline/timeline_statistics.gd`, `project.godot`.

**Spiel und Oberfläche** (25):
`default_bus_layout.tres`, `scenes/game/game_screen.gd`, `scenes/game/game_screen.tscn`,
`scenes/title/invaders/invaders_game.gd`, `scenes/title/invaders/invaders_page.gd`,
`scenes/title/invaders/invaders_page.tscn`, `scenes/title/invaders/invaders_sprites.gd`,
`scenes/title/key_sequence.gd`, `scenes/title/main_menu.gd`, `scenes/title/main_menu.tscn`,
`scenes/title/menu_entry.gd`, `scenes/title/menu_hint.gd`, `scenes/title/menu_hint.tscn`,
`scenes/title/menu_paper.gd`, `scenes/title/save_list.gd`, `scenes/title/save_list.tscn`,
`scenes/title/title_screen.gd`, `scenes/title/title_screen.tscn`, `scenes/title/title_texts.gd`,
`ui/communicator/case_key.gd`, `ui/communicator/communicator.gd`,
`ui/communicator/communicator.tscn`, `ui/computerladen_theme.tres`, `ui/knopf.gd`,
`ui/ui_palette.gd`.

**Werkzeuge** (22):
`tools/werkstatt/catalog_editor.gd`, `tools/werkstatt/difficulty_panel.gd`,
`tools/werkstatt/difficulty_panel.tscn`, `tools/werkstatt/event_form.gd`,
`tools/werkstatt/event_form.tscn`, `tools/werkstatt/event_list.gd`,
`tools/werkstatt/event_list.tscn`, `tools/werkstatt/fahrplan_ausgabe.gd`,
`tools/werkstatt/intervention_dialog.gd`, `tools/werkstatt/intervention_dialog.tscn`,
`tools/werkstatt/issues_panel.gd`, `tools/werkstatt/relief_style_box.gd`,
`tools/werkstatt/simulator_panel.gd`, `tools/werkstatt/simulator_panel.tscn`,
`tools/werkstatt/statistics_panel.gd`, `tools/werkstatt/statistics_panel.tscn`,
`tools/werkstatt/timeline_view.gd`, `tools/werkstatt/werkstatt.gd`,
`tools/werkstatt/werkstatt.tscn`, `tools/werkstatt/werkstatt_theme.tres`,
`tools/werkstatt/what_if_probe.gd`, `tools/werkstatt/zebra.gd`.

Von den großen Dateien der Werkstatt hat der Architektur-Prüfer in der Phasenprüfung von
Phase 5 (T038) alle ganz gelesen, die Phase 5 geändert hat.

## Abweichungen

Urteil von Claude: **bestätigt** (die Stelle verletzt die Regel) oder **verworfen** (mit Grund).
Empfehlung je bestätigter Abweichung: **beheben in 008** (ein System nach FR-027, Verhalten gleich),
**Ausnahme**, **Regel ändern** oder **Feature** (mehrere Systeme; Eintrag in `Feature_Ideas.md`).

### Kern

| ID | Schwere | Ort | Regel | Befund | Urteil | Empfehlung, Aufwand |
|---|---|---|---|---|---|---|
| K1 | mittel | `core/game_clock.gd:34-42` | AR-10 | `_process()` ruft `advance_day()` ohne Obergrenze je Bild; nach einem Hänger rechnet die Uhr beliebig viele Tage in einem Bild | bestätigt | beheben in 008: Obergrenze je Bild wie `InvadersPage.MAX_STEPS`; klein |
| K2 | mittel | `core/game_clock.gd:21, 26` | AR-11 | läuft, angehalten, am Ende als zwei Schalter `paused` und `_ended`; nach dem Ende kann `paused` false werden, obwohl die Uhr am Ende steht | bestätigt | beheben in 008: `enum` für den Zustand, `paused` bleibt als lesbare Eigenschaft; nur Tests nutzen sie; klein |
| K3 | mittel | `core/timeline.gd:85` | AR-08 | `start_game()` würfelt ohne Seed mit `randi_range()` aus dem globalen Zufall; das Spiel übergibt immer einen Seed, nur Tests rufen ohne | bestätigt | beheben in 008: eigener `rng` als Naht wie `GameSession.rng`; klein |
| K4 | niedrig | `core/save/save_slot.gd:25-33`, `save_game.gd:49-69` | AR-15 | Felder, die die Oberfläche liest, ohne „Nur lesen.“ | bestätigt | beheben in 008, zusammen mit S5 und Lücke KL9: Kommentare; klein |
| K5 | niedrig | `core/game_session.gd:52` | AR-11 | `current == null` und ein Schalter `_close_failed` | verworfen: ein einzelner Schalter neben einer Prüfung auf `null` ist keine „Sammlung von Wahrheitswerten“ (Lücke L8 unten) | – |

### Spiel und Oberfläche

| ID | Schwere | Ort | Regel | Befund | Urteil | Empfehlung, Aufwand |
|---|---|---|---|---|---|---|
| S1 | mittel | `scenes/title/title_screen.gd:83, 86, 147-168, 549` | AR-11 | Eingabephase (vor den Einträgen, bedienbar, fährt hinaus) als zwei Schalter; die Ebene (Hauptmenü, Gradwahl, Liste, Löschmodus, Rückfrage, Space Invaders) aus der Sichtbarkeit von fünf Seiten | bestätigt; die Planprobe fand dasselbe am Plan von 006 | beheben in 008: `enum` für Phase und Ebene; mittel, eigener Teil der Phase |
| S2 | mittel | `scenes/title/invaders/invaders_page.gd:66, 76, 186, 316` | AR-11 | keine Partie, läuft, Ergebnis gesperrt, Ergebnis wartet, beendet aus `_game == null`, `_active`, `_is_over()` und `_lock_steps` | bestätigt; ebenso aus der Planprobe | beheben in 008: `enum`; klein |
| S3 | mittel | `title_screen.tscn:56`, `title_screen.gd:43, 176` | AR-04 | Untertitel, „PROTOTYP“ und die Vorlage der Versionszeile stehen nicht in `TitleTexts`, obwohl der Kopf von `title_screen.gd` das sagt | bestätigt | beheben in 008; klein |
| S4 | niedrig | `main_menu.gd:50`, `main_menu.tscn:27`, `save_list.tscn:27` | AR-04 | Kopfzeilen „HAUPTMENÜ“ und „SPIELSTÄNDE“ ein zweites Mal neben `TitleTexts` | bestätigt | beheben in 008; klein |
| S5 | niedrig | `scenes/title/invaders/invaders_game.gd:95-102` | AR-15 | `score`, `lives` ohne „Nur lesen.“, `state` mit „nur lesen“ in anderer Form | bestätigt | mit K4; klein |

### Werkzeuge

| ID | Schwere | Ort | Regel | Befund | Urteil | Empfehlung, Aufwand |
|---|---|---|---|---|---|---|
| W1 | mittel | `tools/werkstatt/werkstatt.gd:917` | AR-02 | `get_node_or_null(^"/root/GameWindow")`; Grund im Kommentar: Mit `-s` geladen kennt GDScript den Namen des Autoloads beim Kompilieren nicht | bestätigt; der Grund ist echt | Ausnahme AR-02 mit Kommentar und Zeile im Leitfaden, dazu W2; klein |
| W2 | mittel | `tools/werkstatt/werkstatt.gd:911-920` | AR-12 | GameWindow wird ohne Naht angehalten | bestätigt | beheben in 008: Variable `game_window`, leer heißt der Pfad aus W1; klein |
| W3 | mittel | `tools/werkstatt/simulator_panel.gd:510-516` und Felder von `WhatIfProbe` | AR-15 | Das Panel setzt Felder der Probe und rechnet die Regel für `until_day`, die `what_if_probe.gd:54-56` beschreibt, selbst | teils: Felder eines reinen Datenobjekts vor dem Schreiben zu setzen ist kein Verstoß (Lücke L13); bestätigt ist, dass die Regel für `until_day` an zwei Stellen steht | beheben in 008: `_end_day()` als Methode in `WhatIfProbe`; klein |
| W4 | mittel | `tools/werkstatt/statistics_panel.gd:102-103` | AR-11 | nie gerechnet, rechnet, abgebrochen, fertig aus `statistics == null`, `_running`, `_aborted` | bestätigt | beheben in 008: `enum`; klein |
| W5 | mittel | `tools/werkstatt/simulator_panel.gd:607-620, 916-919` | AR-01 | Das Panel rechnet den nächsten Monats- und Jahresersten „wie `GameClock`“ selbst nach und leitet daraus die nächste Würfelrunde der Zeitleiste ab | bestätigt | Feature: die Regel gehört nach `GameDate` oder `TimelineRun` in `core/`, betrifft also zwei Ordner (FR-027); klein, aber außerhalb von 008 |
| W6 | mittel | rund 135 Texte über die Werkstatt verteilt | AR-04 | keine Textklasse wie `TitleTexts` | verworfen, wenn Klaus Lücke L14 wie empfohlen entscheidet (Werkzeuge halten Texte je Panel) | – |
| W7 | niedrig | `simulator_panel.gd:51`, `what_if_probe.gd:31`, `fahrplan_ausgabe.gd:27`; dazu `core/timeline.gd:35`, `core/save/save_game.gd:26` | AR-04 | `MAX_SEED` steht fünfmal | bestätigt | Feature, zusammen mit W5 und Lücke L9: Grundgrenzen einmal in `core/`; betrifft zwei Ordner |

### Was der Prüfer ausdrücklich ohne Befund fand

AR-02: keine Wege nach oben im Spiel; die drei `get_parent()` im Communicator fragen nach dem
Eltern-Node einer Seite. AR-03: genau die vier Autoloads. AR-12: `GameSession` und `GameClock` nur
über Nähte. AR-13: `SaveGame` mit Formatversion und `_upgrade()`, Eingriffe über Ereignis und Tag.
AR-14: kein Verweis aus dem Spiel auf `src/tools/`. Kerne werden in Tests ohne Szene angelegt.

## Lücken im Leitfaden

21 Lücken aus drei Läufen, zusammengefasst zu 19. Je mit Empfehlung; was eine Empfehlung im Bestand
nach sich zieht, steht dabei.

| ID | Frage | Empfehlung | Folge im Bestand |
|---|---|---|---|
| L1 (KL1) | Dürfen Autoloads eigenen Zustand halten, etwa die Uhr ihr Datum? | Ja: ein Autoload darf kleinen Ablaufzustand halten (Datum, laufendes Spiel); Spielmechanik gehört in einen Kern | keine |
| L2 (KL2) | Dürfen Kerne Dateien lesen und die Uhr des Rechners lesen? | Dateien ja; die Rechneruhr nur für Zeitstempel und Rechenbudgets, die das Ergebnis nicht ändern; Spielzeit nie | keine |
| L3 (KL3, WL5) | Wie entsteht der Seed eines neuen Spiels? Welche Funktionen sind „globaler Zufall“? | Der Seed wird einmal aus einem eigenen Würfel ohne festen Startwert gezogen, an einer Stelle (`GameSession.rng`; in Werkzeugen das Seed-Feld). Globaler Zufall sind alle Funktionen ohne eigenen Würfel: `randi`, `randf`, `randi_range`, `randf_range`, `randfn`, `randomize`, `Array.shuffle`, `pick_random` | K3 bleibt; der Test aus Phase 4 prüft die volle Liste |
| L4 (SL2, KL4) | Darf ein Kern etwas aus `src/ui/` kennen? | Nur Klassen mit Konstanten wie `UiPalette`, keine Szenen oder Bausteine | keine |
| L5 (SL1) | Wo liegt ein Baustein, den mehrere Bildschirme nutzen? Darf `src/ui/` auf `src/scenes/` verweisen? | Was mehrere Bildschirme nutzen, liegt unter `src/ui/`; `src/ui/` verweist nie auf `src/scenes/` | neue Abweichung: `MenuHint`, `MenuEntry` und `TitleTexts` liegen unter `scenes/title/`, der Communicator und der Spielbildschirm nutzen sie → Feature (drei Ordner) |
| L6 (SL3) | Ist das Theme eine zweite Stelle für Farben? | Ja, erlaubt: Tests halten Theme und `UiPalette` gleich (`test_werkstatt_theme.gd`, `test_ui_palette.gd`) | keine |
| L7 (SL4) | Ist ein Rückgabewert „Melden“ im Sinne von AR-06? | Ja zwischen Kern und Hülle; die Hülle macht daraus Signale. AR-06 gilt zwischen Systemen | keine |
| L8 (SL5, K5) | Was ist eine „Sammlung von Wahrheitswerten“? | Ab zwei eigenen Schaltern, die zusammen Zustände bilden. Nicht: Eigenschaften der Engine wie `visible`, Prüfungen auf `null`, unabhängige Achsen wie Fokus des Fensters, ein einzelner Schalter | K5 verworfen; Communicator und `MenuHint` ohne Befund |
| L9 (KL5) | Gilt „an einer Stelle“ auch für Grundgrenzen wie Spielzeitraum und `MAX_SEED`? | Ja: Grundgrenzen stehen einmal in `core/` und werden von dort gelesen | neue Abweichung: Spielzeitraum in fünf Klassen, 5477 als Zahl in `timeline_event.gd:70`, `MAX_SEED` fünfmal → Feature mit W5 und W7 |
| L10 (KL6) | Gilt „Texte an einer Stelle“ auch für Texte, die ein Kern liefert? | Ja: als Konstanten am Kopf des Kerns, wie `SaveGame.REASON_*` | neue Abweichung: Gründe in `TimelineRun._refuse()`, Beschriftungen in `ScheduleEntry`, Meldungen in `CatalogValidator` → Feature (nur Werkstatt zeigt sie; niedrig) |
| L11 (KL7) | Dürfen Autoloads einander aufrufen? | Ja, über eine Naht und in der Reihenfolge aus `project.godot`; ein Methodenaufruf ist kein „fremde Daten ändern“. Einstellungen des `SceneTree` nur mit Kommentar | keine |
| L12 (KL8) | Ist ein Befehl ein `RefCounted` oder ein `Dictionary`? | Beides; ein `Dictionary` mit festen Schlüsseln, wenn ein Kern die Form an einer Stelle prüft (`TimelineRun`, `InterventionFile`). Tabelle „Muster“ angleichen | keine |
| L13 (KL9, W3) | Gilt „Nur lesen.“ auch für Felder eines Autoloads? Ist ein Datenobjekt wie `WhatIfProbe` ein Kern? | Ja für Autoloads (`GameSession.current`, `last_error`). Ein reines Datenobjekt, das nur Werte für eine Datei sammelt, ist kein Kern; seine Felder darf setzen, wer es füllt | mit K4 |
| L14 (WL1) | Welche Regeln gelten für Werkzeuge? Ist ein Werkzeugfenster ein „Bildschirm“? | Alle Regeln gelten; Ausnahme: Texte stehen je Panel als Konstanten am Kopf, nicht in einer Textklasse | W6 verworfen |
| L15 (WL2) | Ist ein hineingereichtes `Callable` erlaubt? | Ja, wenn der gemeinsame Eltern-Node es hineinreicht; ein Kind hält nie eine Referenz auf seinen Eltern | keine |
| L16 (WL3) | Dürfen Geschwister statische Hilfen voneinander nutzen? | Gemeinsame Hilfen gehören in eine eigene Klasse; private Funktionen (`_name`) fremder Klassen ruft niemand | neue Abweichung: Panels der Werkstatt rufen private Hilfen anderer Panels (`EventForm._reason`, `EventForm._mark_error` in `difficulty_panel.gd:274, 282, 295`; `EventList._category_label` in `event_form.gd:471`) und nutzen öffentliche statische Hilfen von `EventForm` → beheben in 008 (ein Ordner): Hilfen in eine eigene Klasse; mittel |
| L17 (WL4) | Wie tief darf „nach unten“ gehen? | Bis zu den eigenen Kindern und deren öffentlichen Methoden; nicht in innere Nodes einer eingesetzten Szene | neue Abweichung: `werkstatt.gd` greift in innere Nodes von Simulator und Statistik (Z. 310, 441, 563, 496-506) → Feature (Werkstatt-Umbau; die Einstellungsdatei hängt an den Pfaden) |
| L18 (WL6) | Sind Vorgaben für eine neue Datendatei Spielinhalt? | Nein: Vorgaben eines Werkzeugs für eine leere Datei dürfen im Code stehen | keine |
| L19 (WL7) | Ist `get_parent()` innerhalb der eigenen Szene erlaubt? | Ja | keine |

## Zählung

Für `docs/ki_workflow/ki_pruefung.md`, „Nachmessen“. „Nur er fand“: Claudes eigene Prüfung hatte es
nicht gefunden.

| Lauf | Befunde | bestätigt | verworfen | Lücken | nur er fand |
|---|---|---|---|---|---|
| Kern | 5 | 4 | 1 (K5) | 9 | 4 |
| Spiel und Oberfläche | 5 | 5 | 0 | 5 | 3 (S1 und S2 kannte Claude aus der Planprobe) |
| Werkzeuge | 7 | 5, dazu W3 zum Teil | 1 (W6, nach L14) | 7 | 5 (W1 kannte Claude aus der Recherche) |

## Zusammenfassung der Empfehlungen

- **Beheben in 008 (Phase 5):** K1, K2, K3, K4 mit S5 und L13, S1, S2, S3, S4, W2, W3, W4, L16.
  Teil 1 klein (Kern, Kommentare, Texte, Werkstatt-Kleinigkeiten), Teil 2 mittel (Zustand des Titels
  S1, Hilfen der Werkstatt L16).
- **Ausnahme:** W1.
- **Feature, Eintrag in `Feature_Ideas.md`:**
  - „Gemeinsames in `core/` und `ui/`“: W5, W7, L9 (Grundgrenzen, Kalenderhilfen), L5 (geteilte
    Bausteine nach `src/ui/`), L10 (Texte der Kerne).
  - „Werkstatt entkoppeln“: L17 (Griffe in innere Nodes).
- **Verworfen:** K5, W6.

## Nachprüfung des Codes aus Feature 007 (T035)

007 kam nach der Bestandsprüfung nach `main` (`26a1363`) und in den Branch (`6270da6`). Geprüft in
zwei Läufen gleichzeitig, wie oben: Kern des Selbsttests (`src/tools/selbsttest/selbsttest_*`, 14
Dateien, und `project.godot`) sowie Abläufe (`ablaeufe/`, 11 Dateien), die von 007 geänderten Stellen
in fünf Spieldateien (nur der Diff) und `tools/build/baue_alles.sh`, `tools/selbsttest/vergleich.py`.
33 von 33 Dateien unter „Geprüft“, aufgelistet unten. Claude hat jeden Befund am Code nachgesehen. **Klaus hat am
2026-10-28 alles wie empfohlen entschieden:** B1 bis B3 und B5 bis B8 mit M1, M8 und M10 in T036a,
M11 in T036c, B4 in Feature 11-09; die Lücken stehen im Leitfaden („Geschichte“); Test geschärft
und `KERNE` ergänzt in T035; Selbsttest in T037 und Phase 6.

Die 33 Dateien, Pfade unter `src/`:

**Kern des Selbsttests und Projekt** (15):
`tools/selbsttest/selbsttest_ablage.gd`, `tools/selbsttest/selbsttest_eingabe.gd`,
`tools/selbsttest/selbsttest_ergebnis.gd`, `tools/selbsttest/selbsttest_ergebnis.tscn`,
`tools/selbsttest/selbsttest_fahrer.gd`, `tools/selbsttest/selbsttest_laeufer.gd`,
`tools/selbsttest/selbsttest_lauf.gd`, `tools/selbsttest/selbsttest_logger.gd`,
`tools/selbsttest/selbsttest_protokoll.gd`, `tools/selbsttest/selbsttest_start.gd`,
`tools/selbsttest/selbsttest_start.tscn`, `tools/selbsttest/selbsttest_system.gd`,
`tools/selbsttest/selbsttest_texte.gd`, `tools/selbsttest/selbsttest_theme.tres`, `project.godot`.

**Abläufe** (11):
`tools/selbsttest/ablaeufe/ablauf_bedienung.gd`, `tools/selbsttest/ablaeufe/ablauf_easter_egg.gd`,
`tools/selbsttest/ablaeufe/ablauf_fenster.gd`, `tools/selbsttest/ablaeufe/ablauf_laden.gd`,
`tools/selbsttest/ablaeufe/ablauf_liste.gd`, `tools/selbsttest/ablaeufe/ablauf_loeschen.gd`,
`tools/selbsttest/ablaeufe/ablauf_neues_spiel.gd`, `tools/selbsttest/ablaeufe/ablauf_titel.gd`,
`tools/selbsttest/ablaeufe/ablauf_titel_echtzeit.gd`,
`tools/selbsttest/ablaeufe/selbsttest_ablauf.gd`,
`tools/selbsttest/ablaeufe/selbsttest_szenario.gd`.

**Von 007 geänderte Spieldateien, nur der Diff** (5):
`core/game_window.gd`, `core/save/save_game.gd`, `scenes/title/invaders/invaders_page.gd`,
`scenes/title/save_list.gd`, `tools/werkstatt/werkstatt.gd`.

**Außerhalb von `src/`** (2): `tools/build/baue_alles.sh`, `tools/selbsttest/vergleich.py`.

**Test nach dem Merge:** zweimal 1364 Tests, 1363 grün, 188485 von 188486 Prüfungen; Startprobe
still. Rot ist `test_kein_weg_nach_oben` mit zwei Stellen: `selbsttest_ergebnis.gd:152` (B1 unten)
und `selbsttest_system.gd:166`, `"../Resources"`. Die zweite ist ein Dateipfad im App-Paket, kein
Knotenpfad; der Test zählt `../` in jeder Zeichenkette ohne `://`.

### Selbsttest

| ID | Schwere | Ort | Regel | Befund | Urteil | Empfehlung, Aufwand |
|---|---|---|---|---|---|---|
| B1 | mittel | `selbsttest_ergebnis.gd:150-155` | AR-02, AR-12 | `get_node_or_null(^"/root/GameWindow")` ohne Naht, „wie in der Werkstatt“ | bestätigt; der Grund der Werkstatt gilt hier nicht: Die Seite läuft nur als Teil der App oder der Probe-Szene, beide mit Autoloads | beheben in 008: Naht `game_window`, leer heißt `GameWindow`; kein Pfad, keine Ausnahme; klein |
| B2 | niedrig | `selbsttest_start.gd:50-54` | AR-12, „Werkzeuge“ | setzt `GameSession.folder`, `now`, `rng` direkt; Grund im Kommentar steht da, die Naht fehlt | bestätigt; Schwere niedriger als gemeldet, weil die Startszene die einzige Stelle ist, die die Sitzung einrichtet | beheben in 008: Variable `session` wie bei Läufer und Fahrer; klein |
| B3 | mittel | `selbsttest_laeufer.gd:80-83` | AR-11 | bereit, läuft, abgebrochen, geschrieben, beendet aus vier Schaltern | bestätigt; wie S2 und W4 | beheben in 008: `enum`; klein |
| B4 | mittel | `selbsttest_fahrer.gd:546-566` | AR-01 | baut einen neuen Spielstand selbst nach, wie `GameSession.start_new()` (`game_session.gd:87-98`) | bestätigt; kommt ein Pflichtfeld dazu, weichen die Spielstände des Selbsttests ab | Feature 11-09: eine Fabrik für neue Spielstände in `core/`, die beide nutzen; berührt `core/` und `tools/` |
| B5 | mittel | `selbsttest_ergebnis.gd:82` | AR-04 | schreibt die Schrift in das geladene, geteilte `selbsttest_theme.tres`; der Kommentar meint mit „Kopie“ die Datei | bestätigt | beheben in 008: vorher `theme = theme.duplicate()`; klein |
| B6 | niedrig | `selbsttest_start.gd:24`, `selbsttest_fahrer.gd:52`; `selbsttest_ablage.gd:18`, `selbsttest_laeufer.gd:30` | AR-04 | Seed 4711 und der Ordner `user://selbsttest/` je zweimal (`DEVICE := 4711` in `selbsttest_eingabe.gd` ist etwas anderes) | bestätigt | beheben in 008: je eine Konstante; klein |
| B7 | niedrig | `selbsttest_system.gd:48` | AR-04 | `RASTER := Vector2i(640, 360)` neben `GameWindow.BASE_SIZE` | bestätigt; der Fahrer liest schon von dort | beheben in 008; klein |
| B8 | niedrig | `selbsttest_lauf.gd:42-60, 72, 76` | AR-15 | Felder, die die Zusammenfassung liest, ohne „Nur lesen.“ | bestätigt | beheben in 008 mit K4; klein |
| B9 | niedrig | `selbsttest_texte.gd` | AR-04, „Werkzeuge“ | eigene Textklasse, obwohl „Werkzeuge“ Texte je Panel am Kopf verlangt | verworfen als Befund: Der Satz entstand als Erleichterung für die Panels der Werkstatt (L14); eine Textklasse erfüllt „an einer Stelle“ besser. Als Lücke M2 unten | – |

Die Abläufe selbst: ohne Befund. Sie kennen nur den Fahrer und Konstanten des Spiels; keiner nennt
die Zustände, die Phase 5 umstellt (`_ready_for_input`, `_leaving`, `paused`, `_ended`, `_active`,
`_lock_steps`, `_running`, `_aborted`). Der Fahrer liest den Titel über `current_page()`,
`is_visible_in_tree()` und `InvadersPage.game()`; S1 und S2 müssen diese Wege erhalten.

### Lücken im Leitfaden

| ID | Frage | Empfehlung | Folge |
|---|---|---|---|
| M1 | Darf ein Werkzeug das Spiel von außen über Namen innerer Knoten bedienen? (Fahrer: `Communicator`, Seiten, `Rows/DeleteMode`, `LeaveButton` …) | Ja, aber nur an einer Stelle: dem Fahrer. Die Abläufe gehen nur über ihn. Die Knotennamen sind damit eine Schnittstelle; wer sie umbenennt, ändert den Fahrer mit | neue Abweichung: `ablauf_fenster.gd:69-71, 97-98` setzt Größe und Lage über `fahrer.fenster()` selbst → über `stelle_fenster()`; klein |
| M2 | Gilt „Texte je Panel am Kopf“ für jedes Werkzeug? | Nein: „Ein Werkzeug darf seine Texte je Panel am Kopf halten; eines aus vielen Teilen wie der Selbsttest bekommt eine eigene Textklasse.“ | keine |
| M3 | Darf ein Kern eine programmweite `static var` als Naht haben? (`SaveGame.time_zone_bias`) | Ja, wenn nur Werkzeuge und Tests sie setzen und der Kommentar das sagt | keine: der Kommentar an `save_game.gd:47-52` sagt das schon |
| M4 | Gilt „Hilfsfunktionen mit `class_name`“ auch für reine Rechnungen eines Autoloads? (`GameWindow.best_factor()`, `centered_position()`) | Nein: Reine Rechnungen, die zum Autoload gehören, dürfen als `static func` im Autoload-Skript stehen und über `preload` getestet werden | keine |
| M5 | Zählt eine Projekteinstellung mit Feature-Tag als Verweis nach `tools/` (AR-14)? | Nein, wenn sie nur mit einem Tag gilt, dessen Export `tools/` enthält (`run/main_scene.selbsttest`) | keine |
| M6 | Darf ein Werkzeug Godots globalen Würfel stellen? (`seed(SEED)` für das versteckte Spiel) | Ja, mit Grund im Kommentar; AR-08 gilt für Kern und Wirtschaft, das versteckte Spiel würfelt in seiner Seite | keine |
| M7 | Darf ein Werkzeug ein anderes kennen? (`selbsttest_theme.tres` nutzt `relief_style_box.gd` und Symbole der Werkstatt) | Ja, solange beide gemeinsam aus dem Spiel-Export fallen | keine |
| M8 | Gilt „an einer Stelle“ auch für Szenenpfade? (`title_screen.tscn` dreimal im Selbsttest) | Ja: Pfade, die ein Werkzeug startet, einmal als Konstante | neue Abweichung, klein |
| M9 | Ist eine Kopie des Themes eine dritte Stelle für Farben? | Erlaubt, wenn ein Test sie gleich hält; das tut `test_selbsttest_ergebnis.gd:467` | keine |
| M10 | Was ist ein `RefCounted` mit Zugriff auf den Baum? (`SelbsttestFahrer`, `SelbsttestEingabe`) Darf ein Kern Engine-Dienste fragen? (`SelbsttestSystem`: `DisplayServer`, `OS`, `Thread`) | Kern ist, was AR-01 nach dem Inhalt erfüllt; ein `RefCounted` mit Baum ist ein Helfer der Hülle und sagt das im Kopf. Engine-Dienste nur in Werkzeugen, nicht in Kernen des Spiels | Kopf von Fahrer und Eingabe ergänzen, klein; `KERNE` bekommt `selbsttest_ablage.gd`, `selbsttest_lauf.gd`, `selbsttest_protokoll.gd`, `selbsttest_texte.gd`; nicht `selbsttest_system.gd` (Engine-Dienste) und nicht `selbsttest_logger.gd` (erbt von `Logger`) |
| M11 | Gilt der Leitfaden für Werkzeuge außerhalb von `src/`? (`vergleich.py` kennt Protokollformat, 640 × 360 und Kassenrot ein zweites Mal) | Nein, er gilt für `src/`. Über die Grenze zu Python nennt ein Kommentar die Quelle in Godot | Kommentare in `vergleich.py`; klein |

### Zählung

| Lauf | Befunde | bestätigt | verworfen | Lücken | nur er fand |
|---|---|---|---|---|---|
| Selbsttest | 9 | 8 | 1 (B9, als Lücke) | 8 | 7 (B1 hatte der Test schon gemeldet) |
| Abläufe und Änderungen | 0 | – | – | 6; M1 und M5 auch im anderen Lauf, M2 dort als B9 | – |

## Fund bei der Behebung (T036b)

Beim Umbau von L16 fand der Godot-Agent eine Abweichung derselben Art, die weder in L16 noch in
diesem Bericht stand: `src/tools/werkstatt/difficulty_panel.gd` ruft zweimal `TimelineRun._points()`,
eine private Funktion des Kerns (AR-02). **Klaus hat am 2026-10-29 entschieden:** jetzt mit beheben,
als T036d; die Funktion wird öffentlich, das Verhalten bleibt gleich.

## Phasenprüfung Phase 5 (T038)

Der Architektur-Prüfer las die 32 geänderten Dateien gegen Leitfaden und Bestandsbericht. Alle 26
Behebungen aus T036a, T036b und T036d sind erledigt; neue Abweichungen durch den Umbau fand er
nicht. Er hatte in dieser Sitzung nur Read, keine Suche; Claude hat die Suche nach Aufrufen privater
Funktionen fremder Klassen selbst nachgeholt: keine mehr.

| # | Schwere | Ort | Regel | Befund | Entscheidung (Klaus, 2026-10-29) |
|---|---|---|---|---|---|
| A | niedrig | `timeline_view.gd:1708-1715` | AR-02 | `_reason()` ist eine Kopie von `FieldHelpers.reason()`, Rest von L16 | beheben in T036e |
| B | Lücke | `timeline.gd:42-44` | AR-08 | `Timeline.rng` ist eine zweite Stelle neben `GameSession.rng` | Leitfaden: nur Naht für `start_game()` ohne Seed |
| C | Lücke | `save_game.gd:58-74` | AR-15 | Wen bindet „Nur lesen.“? | Leitfaden: Oberfläche und andere Leser; Besitzer und wer anlegt, schreiben |
| D | Lücke | `timeline_run.gd:1090-1093` | AR-14 | Doku-Kommentar eines Kerns nennt `FieldHelpers` | Kommentar umformulieren in T036e; weil 14 ältere Kommentare in Kernen Werkzeuge nennen, bekam AR-14 einen Satz: ein Name im Kommentar ist kein Verweis |
| E | Lücke | Werkstatt | AR-02, AR-04 | Zählen private Kopien gleicher Hilfen? | Leitfaden: ja, unter AR-04; übrige Kopien in Feature 11-10 |
| F | Lücke | `title_screen.gd:558-561` | AR-11 | Darf ein Zustand aus einem Baustein abgeleitet werden? | Leitfaden: ja, aus dem Baustein, der ihn besitzt |
| G | alter Code | `selbsttest_fahrer.gd:56`, `simulator_panel.gd:316`, `intervention_dialog.gd:254-257` | AR-04, AR-08 | `SPIELBILDSCHIRM` doppelt; `roll_seed()` mit globalem Würfel; Regel „änderbar“ doppelt | die ersten beiden in T036e, die Regel in Feature 11-10 |
| H | Ablauf | – | – | Prüfer ohne Suchwerkzeuge | Erfahrung in `ki_pruefung.md` |
