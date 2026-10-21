---

description: "Taskliste für Feature 002 Zeitleisten-Werkstatt"
---

# Tasks: Zeitleisten-Werkstatt

**Input**: Design-Dokumente aus `specs/002-zeitleisten-werkstatt/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ereigniskatalog.md,
contracts/zeitleiste.md, contracts/werkstatt.md, quickstart.md, checklists/review.md

**Tests**: Die Verträge legen GUT-Tests fest (zeitleiste.md und werkstatt.md, Abschnitte Tests).
Sie entstehen mit der Logik und müssen vor jeder Abnahme grün sein. Zeitstrahl, Formulare,
Fenster und Look prüft Klaus von Hand nach quickstart.md.

**Organization**: Die Tasks sind nach User Stories gruppiert. Umgesetzt wird nach Verfassung 2.1.0,
Grundsatz II, eine Phase nach der anderen und nur auf Klaus' Auftrag; jede Phase endet mit seiner
Abnahme. Nach Grundsatz IV kommt der Style-Guide-Abschnitt „Werkzeuge“ zuerst (T001, T002).
Welche Abschnitte des Quickstarts zu welcher Abnahme gehören, steht dort in der Tabelle „Abnahme
je Phase“.

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Entscheidungen, Freigaben, Abnahmen, Pflege in der Werkstatt, was er selbst bauen
    will.
  - `[A]` Godot-Agent `godot-entwickler`: Szenen, Nodes, GDScript, Tests, Projekteinstellungen,
    Export.
  - `[C]` Claude: Style-Guide, Doku, Review, Werkzeuge außerhalb von Godot.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: zugehörige User Story aus spec.md (US1 bis US7)

## Path Conventions

- Godot-Projekt unter `src/`, Tests unter `src/test/`, Test-Kataloge unter `src/test/fixtures/`
  (GUT 9.7.1)
- Kern der Zeitleiste unter `src/core/timeline/`, Werkstatt und Textausgabe unter
  `src/tools/werkstatt/` (nicht im Export)
- Pfade, Klassen, Signale und Signaturen laut [zeitleiste.md](contracts/zeitleiste.md),
  [werkstatt.md](contracts/werkstatt.md) und [ereigniskatalog.md](contracts/ereigniskatalog.md)
- Einmal-Skripte für Schnappschuss, Übernahme und großen Katalog laufen außerhalb des Repos mit
  `Godot --headless --path src -s /absoluter/pfad/skript.gd` und werden nicht committet
- Nach dem Anlegen, Verschieben oder Löschen von Skripten ruft der Agent einmal
  `Godot --headless --path src --import` auf (siehe Notes)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Style-Guide-Abschnitt „Werkzeuge“, Schnappschuss der alten Daten und Übernahme in den
Katalog, solange der alte Code noch da ist

- [x] T001 [C] Style-Guide um den Abschnitt „Werkzeuge“ ergänzen (plan.md, Vorarbeit 1) im
  Artifact https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX:
  - Werkzeuge laufen in voller Auflösung, nicht im 640 × 360-Raster.
  - Schrift ohne Pixelraster: Vorschlag `ThemeDB.fallback_font`, dazu eine Größe (research.md,
    R14).
  - Farbrollen aus der Hauptpalette: Grund, Fläche, Text, gedämpfter Text, Auswahl, Fehler,
    Warnung, Ziehen. Je Paar aus Text und Grund steht der Kontrast dabei, mindestens 4,5 : 1
    (FR-029).
  - Kategorienfarben: die Tokens, die Kategorien tragen dürfen, in fester Reihenfolge, jedes mit
    mindestens 3 : 1 Kontrast zum Grund des Zeitstrahls; die Grundfarbe ist nicht dabei (R14).
    Daraus die Startfarben der zehn Kategorien `hardware`, `software`, `tech`, `wirtschaft`,
    `lokal`, `konkurrenz`, `kunde`, `reklamation`, `lieferung` und `kalender`.
  - Titel im Zeitstrahl stehen in Textfarbe auf dem Grund, nie auf der Kategorienfarbe.
- [x] T002 [K] Abschnitt „Werkzeuge“ aus T001 im Style-Guide ansehen und freigeben
- [x] T003 [A] [P] Schnappschuss der alten Daten (research.md, R19). Ein Einmal-Skript schreibt mit
  `EventDatabase.build_fixed_events()` die Datei `src/test/fixtures/historische_ereignisse.txt`:
  - je fixes Ereignis eine Zeile `JJJJ-MM-TT|kennung|wirkung;wirkung;…`;
  - jede Wirkung als `kind:target:magnitude:delay_days`; `kind` klein aus dem bisherigen Enum,
    etwa `preis`; `magnitude` mit `str()`;
  - Wirkungen in Listenreihenfolge, Zeilen nach Datum, dann Kennung.
- [x] T004 [A] Übernahme in `src/data/event_catalog.json` (research.md, R19). Ein Einmal-Skript
  schreibt den Katalog nach [ereigniskatalog.md](contracts/ereigniskatalog.md), Tabelle „Übernahme
  aus EventDatabase“:
  - die 25 Ereignisse, 19 mit `"kind": "fixed"` und 6 mit `"kind": "chance"`, alle Wirkungen mit
    `"scope": "once"`, leere `follow_ups` und `conditions`;
  - zehn Kategorien in der Reihenfolge aus T001, mit deutschem Namen und Startfarbe;
  - so weit es ohne die neuen Klassen geht, nach den Schreibregeln 1 bis 5:
    `JSON.stringify(daten, "\t", true)` mit Zeilenumbruch am Ende, `events` nach `id` sortiert,
    ganze Zahlen als `int`, `"format": 1`. Die endgültige kanonische Form entsteht in T012.

  Hängt an T002.
- [x] T005 [A] [P] `src/export_presets.cfg`: `exclude_filter` von `"addons/gut/*, test/*"` auf
  `"addons/gut/*, test/*, tools/*"` setzen; die Datei vor der Abgabe auf Zugangsdaten durchsehen
  (Verfassung, Arbeitsweise)
- [x] T006 [K] Phase 1 abnehmen:
  - `src/test/fixtures/historische_ereignisse.txt` ansehen: 19 Zeilen, darunter der Pentium am
    1993-03-22 mit seinen drei Wirkungen.
  - `src/data/event_catalog.json` im Diff ansehen: 25 Ereignisse, zehn Kategorien mit den
    Startfarben aus T001.
  - `src/export_presets.cfg` nach quickstart.md, Abschnitt 6, erste Zeile.
  - Die Tests laufen mit dem alten Code weiter grün.

**Checkpoint**: Abschnitt „Werkzeuge“ freigegeben, Schnappschuss und Katalogdatei liegen vor,
`tools/*` ist vom Export ausgeschlossen. Der alte Code läuft noch unverändert. Abnahme durch Klaus,
dann Auftrag für Phase 2.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Datenklassen, Katalog lesen und schreiben, Prüfregeln. Die alte Engine fällt im
selben Schritt, in dem ihre Klassen umgebaut werden; danach wird das Autoload zur stillen Hülle,
die nur den Katalog lädt.

**⚠️ CRITICAL**: Keine User Story beginnt, bevor diese Phase abgenommen ist.

- [x] T007 [A] [P] `src/core/game_date.gd` laut Vertrag, Abschnitt „Geänderte Bestandteile“:
  - `to_day_index()` und `from_day_index()` rechnen auch vor 1985, mit negativen Indizes
    (research.md, R9). Bisher ergab der 31.12.1984 den Index 365.
  - Neu `from_iso()`, `to_iso()` und `is_valid()`.

  Tests in `src/test/test_game_date.gd`:
  - Der 31.12.1984 ergibt −1, der 01.12.1984 −31; `from_day_index(-31)` ergibt den 01.12.1984.
  - Index → Datum → Index ergibt für alle Tage von −400 bis 5477 wieder denselben Index.
  - `is_valid(1988, 2, 29)` ist wahr, `is_valid(1989, 2, 29)` falsch; `from_iso("1993-13-01")`
    liefert `null`.
  - `to_iso()` und `from_iso()` ergeben für den 01.01.1985 und den 31.12.1999 wieder dasselbe.
- [x] T008 [A] [P] `src/ui/ui_palette.gd`:
  - `TOKENS` mit allen 15 Token-Namen wie im Style-Guide (`&"tusche"` bis `&"holz-dunkel"`,
    Bindestriche wie `&"gehaeuse-hell"`);
  - `CATEGORY_TOKENS` mit den Kategorienfarben aus T001, in deren Reihenfolge;
  - `static func by_token(token: StringName) -> Color`, die für unbekannte Tokens Magenta
    `Color(1, 0, 1)` liefert.
- [x] T009 [A] [P] Kleine Datenklassen unter `src/core/timeline/` laut Vertrag, alle `RefCounted`
  mit `from_dict(data, issues)` und `to_dict()`:
  - `catalog_issue.gd`: `CatalogIssue` mit `Severity { ERROR, WARNING }`, `rule`, `event_id`,
    `field`, `message`.
  - `event_category.gd`: `EventCategory` mit `id` „`[a-z0-9_]+`, eindeutig“, `name` und `color`
    (Token aus `UiPalette.CATEGORY_TOKENS`).
  - `follow_up.gd`: `FollowUp` mit `target`, `chance` „float 0..1, Vorgabe 1.0“ und
    `delay_min`/`delay_max` „int ≥ 0; gleich heißt fest“.
  - `event_condition.gd`: `EventCondition` mit `event` und `occurred`.
- [x] T010 [A] `EventEffect` und `TimelineEvent` umbauen und im selben Schritt die alte Engine
  entfernen, damit das Projekt nach diesem Task wieder fehlerfrei lädt (Vertrag, Datenklassen;
  research.md, R19):
  - **EventEffect:** Datei mit `.uid` per
    `git mv src/core/event_effect.gd src/core/timeline/event_effect.gd` verschieben;
    `extends RefCounted`; `Kind { PREIS, NACHFRAGE, REPUTATION, KUNDENSTROM, PRESSE }`, `SPAWN`
    entfällt; `Scope { ONCE, DURING }`; `from_dict()`, `to_dict()`; `kind_label()` liefert
    „Preis“, „Nachfrage“, „Ruf“, „Kundenstrom“ bzw. „Presse“; `describe()` wie bisher.
  - **TimelineEvent:** Datei mit `.uid` per
    `git mv src/core/timeline_event.gd src/core/timeline/timeline_event.gd` verschieben;
    `extends RefCounted`; `Kind { FIXED, YEARLY, PRESET, CHANCE, FOLLOW_ONLY }`, Felder je Art wie
    im Datenmodell, darunter:
    - `duration_days` „int ≥ 0, 0 heißt Augenblick“;
    - `yearly_end` „Tag 0 heißt Monatsende; (0, 0) heißt ohne Dauer“;
    - `count_weights` „Array[float], Gewicht je Anzahl ab `count_min` in Prozent, Summe 100“;
    - `monthly_chance` „float 0..1“;
    - `max_occurrences` „0 heißt unbegrenzt“.
  - `from_dict()` hängt Strukturfehler als V22 an und füllt Vorgabewerte. `conditions` liest es
    bei jeder Art, damit die Prüfung sie an fixen und jährlichen Ereignissen als V17 meldet statt
    als V22. `to_dict()` schreibt nur die Schlüssel der eigenen Art (Schreibregel 4).
  - Dazu `has_duration()`, `kind_label()` („fix“, „fix, jährlich“, „beim Start gesetzt“, „über
    Wahrscheinlichkeit“, „nur als Folge“) und `duplicate_event()`.
  - **Alte Engine:** Gelöscht werden `src/data/event_database.gd`, `src/scenes/timeline_demo.gd`,
    `src/test/test_event_database.gd` und `src/test/test_timeline_event.gd`, jeweils mit `.uid`,
    dazu `src/scenes/timeline_demo.tscn`, die keine eigene `.uid` hat. `src/core/timeline.gd`
    wird zu einem leeren Autoload (`extends Node` mit Doc-Kommentar), bis T017 die Hülle baut.

  Hängt an T009.
- [x] T011 [A] `src/core/timeline/event_catalog.gd` (`EventCatalog`) laut Vertrag:
  - `from_json()`: bei einem Parse-Fehler `null` und V22 mit Zeile und Grund aus
    `get_error_line()`/`get_error_message()`; `format` ≠ 1 und unbekannte Schlüssel sind V22.
  - `read_file()`, `to_json()` nach den Schreibregeln 1 bis 5 (Anteile auf vier, Gewichte auf
    zwei Nachkommastellen gerundet, ganze Zahlen als `int`, nie ein `PackedFloat32Array`),
    `write_file()`, `get_event()`, `get_category()`, `duplicate_catalog()`, `sort_events()`.
  - `without_faulty(issues)` nach data-model.md, „Fehlerhafte Ereignisse ausnehmen“: Ereignisse
    mit einer Meldung der Stufe `ERROR` fallen weg, Folgeereignisse, die auf sie zeigen, ebenso;
    Bedingungen bleiben stehen.
  - Ganzzahlige Felder werden beim Lesen mit `int()` zurückgewandelt (research.md, R3).

  Hängt an T010.
- [x] T012 [A] Übernahme normalisieren und einfrieren (research.md, R19, Schritt 3):
  - `src/data/event_catalog.json` mit `EventCatalog.read_file()` lesen und mit `write_file()` neu
    schreiben. Im Diff ändert sich höchstens die Form, nie ein Wert.
  - Das Ergebnis als `src/test/fixtures/event_catalog_uebernahme.json` kopieren. Diese Datei
    ändert sich danach nie mehr.

  Hängt an T004 und T011.
- [x] T013 [A] `src/test/test_event_catalog.gd`:
  - Rundreise: `fixtures/event_catalog_uebernahme.json` lesen und wieder schreiben ergibt
    bytegleichen Text.
  - Ganze Zahlen stehen ohne Nachkomma; ein Gewicht 33,333333 wird als `33.33` geschrieben, eine
    Chance 0,123456 als `0.1235`.
  - `fixtures/catalog_v22_kaputt.json` liefert `null` und eine Meldung mit Zeile.
  - Eine fehlende Datei liefert eine Meldung mit Pfad; ein unbekannter Schlüssel gibt V22.
  - `without_faulty()`: Ein Ereignis mit Fehler fehlt samt dem Folgeereignis, das auf es zeigt.

  Hängt an T012.
- [x] T014 [A] `src/core/timeline/catalog_validator.gd` (`CatalogValidator`) mit den Regeln aus
  data-model.md, Tabelle „Prüfregeln“. Meldungen nach Kennung, dann Regel, Kategorien zuletzt:
  - **Kennung und Titel:** V01 Kennung leer · V02 Kennung doppelt · V03 Kennung enthält andere
    Zeichen als `a–z`, `0–9`, `_` · V04 Titel leer · V05 Kategorie unbekannt.
  - **Daten:** V06 Datum oder Zeitfenster außerhalb 01.01.1985 bis 31.12.1999 · V07 Zeitfenster
    endet vor seinem Beginn · V08 jährlich: Jahre außerhalb 1985 bis 1999 oder `yearly_from` >
    `yearly_to` · V09 jährlich: Beginn oder Ende kein gültiger Tag im Jahr oder 29.02.
  - **Gesetzt und Chancen:** V10 gesetzt: höchste Anzahl passt mit Mindestabstand nicht ins
    Zeitfenster · V11 gesetzt: Gewichte negativ oder Summe nicht 100 (Toleranz 0,01) · V12
    Grundchance oder Wahrscheinlichkeit eines Folgeereignisses außerhalb 0 bis 1 · V13
    Grundchance 0 (Warnung) · V14 Dauer, Verzögerung, Mindestabstand oder Höchstzahl negativ;
    `delay_min` > `delay_max`.
  - **Verweise:** V15 Folgeereignis oder Bedingung verweist auf unbekannte Kennung · V16
    Folgeereignis zeigt auf ein fixes oder jährliches Ereignis · V17 Bedingung an einem fixen oder
    jährlichen Ereignis, auch schon der Schlüssel `conditions` · V18 Kreis aus Folgeereignissen
    mit 100 % und Verzögerung 0, gemeldet bei jedem Ereignis des Kreises.
  - **Wirkungen und Kategorien:** V19 Wirkung `DURING` mit `delay_days` ≥ Dauer · V20 Wirkung
    auf Preis, Nachfrage, Ruf oder Kundenstrom mit Stärke 0 (Warnung) · V21 Kategorie: Kennung
    doppelt oder leer, Farbe nicht in `UiPalette.CATEGORY_TOKENS`.
  - **Neu aus dem Review:** V23 Kreis aus Folgeereignissen mit 100 % und Verzögerung, der bis
    Spielende weiterläuft (Warnung) · V24 gesetzt: Mindestabstand kürzer als die Dauer.
  - Dazu `validate_event(catalog, event)` mit allen Regeln außer V02, V18, V21 und V23, für die
    Vorschau beim Ziehen (R16); `validate()` nutzt sie je Ereignis.

  Hängt an T008 und T011.
- [x] T015 [A] Fixtures `src/test/fixtures/catalog_vNN_<zweck>.json`, je Regel eine, darunter
  `catalog_v04_titel_leer.json`, die auch der Quickstart nutzt; für V22 dient
  `catalog_v22_kaputt.json` aus T013. Dazu `catalog_minimal.json` ohne jede Meldung. Tests in
  `src/test/test_catalog_validator.gd` (SC-006):
  - Jede Fixture löst ihre Regel aus und nennt Ereignis und Feld; V18 meldet sich bei jedem
    Ereignis des Kreises, V21 nennt die Kategorie in `field`, V22 die Zeile.
  - Fehlerregeln kommen als `ERROR`; V13, V20 und V23 kommen als `WARNING`.
  - `catalog_minimal.json` und ein Ereignis ohne Wirkung melden nichts.
  - `validate_event()` meldet für ein Ereignis dasselbe wie `validate()`, ohne V02, V18, V21 und
    V23.

  Hängt an T013 und T014.
- [x] T016 [A] [P] `src/core/timeline/schedule_entry.gd` (`ScheduleEntry`). Die Klasse kommt schon
  hier, weil das Signal `entry_skipped(entry: ScheduleEntry, …)` der Hülle sie braucht:
  - `Origin` und `State { PLANNED, RUNNING, OCCURRED, ENDED, SKIPPED, CANCELLED }`, Felder wie im
    Datenmodell, darunter `roll`/`threshold` „bei `ROLLED` und `FOLLOW_UP`; sonst −1“,
    `base_chance`, `modifier_notes` „je „<grund> <wert in Prozentpunkten>““, `moved_from_day`
    „sonst −1“ und `started_before_game`.
  - `origin_label()`, `state_label()` („geplant“, „läuft“, „eingetreten“, „beendet“,
    „entfallen“, „abgesagt“), `explain()` aus den Feldern des Termins, `due_effects()`.

  Hängt an T010; läuft parallel zu T011 bis T015.
- [x] T017 [A] Stille Hülle `src/core/timeline.gd`:
  - Die fünf Signale laut Vertrag, typisiert.
  - `catalog_path`; `_ready()` liest den Katalog mit `read_file()`, prüft ihn mit
    `CatalogValidator`, meldet jedes Ereignis mit Fehler über `push_error()` mit Kennung und Grund
    und behält `catalog = without_faulty(issues)`.
  - Fehlt die Datei oder ist sie unlesbar, gibt es ein `push_error()` mit Pfad und Grund (FR-049).
  - Noch gibt es keinen Lauf und keine Verbindung zur Uhr.

  Hängt an T011, T014 und T016.
- [x] T018 [A] Katalogtests, Teil 1:
  - `src/test/test_shipped_catalog.gd`: Der echte Katalog hat keine Meldung der Stufe `ERROR`
    (FR-048). Mehr prüft dieser Test am echten Katalog nie, außer den Kalender-Ereignissen
    (T045).
  - `src/test/test_uebernahme.gd` an `fixtures/event_catalog_uebernahme.json`: 25 Ereignisse,
    davon 19 `FIXED` und 6 `CHANCE`, mit den Kennungen aus dem Schnappschuss und den bisherigen
    sechs; zehn Kategorien in der Reihenfolge aus T001.

  Hängt an T012 und T014.
- [x] T019 [K] Phase 2 abnehmen nach quickstart.md, Abschnitte 1 und 2: Alle Tests grün, die
  Startprobe bleibt ohne Ausgabe. Dazu `src/data/event_catalog.json` nach T012 im Diff ansehen
  und prüfen, dass neue Skripte ihre `.uid` haben.

**Checkpoint**: Katalog, Datenklassen und Prüfregeln stehen, die alte Engine ist weg, das Projekt
startet still. Abnahme durch Klaus, dann Auftrag für Phase 3.

---

## Phase 3: User Story 1 - Ein Spiel spult seinen Fahrplan ab (Priority: P1) 🎯 MVP

**Goal**: Aus Katalog und Seed entsteht der Fahrplan; das Spiel spult ihn mit der Spieluhr ab und
meldet jedes Ereignis; die Textausgabe zeigt den Fahrplan ohne Fenster.

**Independent Test**: Textausgabe für Seed 4711 zweimal erzeugen und mit `diff` vergleichen,
Seed 1 und 2 mit `catalog_us1_preset.json` vergleichen (quickstart.md, Abschnitt 3).

### Implementation for User Story 1

- [x] T020 [A] [P] [US1] `src/core/timeline/event_dice.gd` (`EventDice`): `make(seed, purpose,
  key)` liefert einen `RandomNumberGenerator` mit `seed = "<seed>|<purpose>|<key>"
  .sha256_buffer().decode_u64(0)` (research.md, R5)
- [x] T021 [A] [P] [US1] Zwei kleine Klassen unter `src/core/timeline/`:
  - `chance_modifier.gd`: `ChanceModifier` mit den Feldern aus dem Datenmodell und
    `is_active(day)` als „from_day ≤ day ≤ to_day“.
  - `timeline_message.gd`: `TimelineMessage` mit `Kind`, den Feldern und einem deterministischen
    `to_line()`.
- [x] T022 [A] [US1] `src/core/timeline/timeline_run.gd` (`TimelineRun`), Teil 1, laut Vertrag:
  - `_init()` kopiert den Katalog und legt den Fahrplan an: fixe Termine und gesetzte über den
    `preset`-Würfel nach R7. Erst `rand_weighted()` über die Gewichte als `PackedFloat32Array`,
    die Anzahl ist k = `count_min` + Index. Dann k Zahlen aus `randi_range(0, L − (k − 1) · g)`
    mit L = `window_to` − `window_from`, aufsteigend sortiert; der i-te Termin liegt auf
    `window_from` + zᵢ + i · g.
  - `begin()` und `advance_to()` springen von Stichtag zu Stichtag (R6).
  - Tagesablauf, Schritte 2 bis 4:
    - verzögerte Wirkungen;
    - Würfelrunde am Monatsersten, auch am 01.01.1985, mit genau zwei Würfen je Monat und
      Ereignis (zeitleiste.md, Tabelle „Zwecke und Würfe“);
    - Bedingungen (FR-006: „eingetreten“ heißt, bis zum Vortag begonnen);
    - Höchstzahl und Mindestabstand: Es zählen alle Termine außer entfallenen und abgesagten,
      auch geplante; der Abstand gilt zu jedem solchen Termin, 0 heißt keine Prüfung (FR-005);
      Teilmonate mit Tag nur im Fenster; eine Chance von 100 % trifft immer;
    - wirksame Chance nach FR-025. Der Termin hält Würfelwert, Schwelle, Grundchance und
      `modifier_notes` fest (R8).
  - Folgeereignisse mit eigenem Würfel je Entscheidung; ihr Termin hält Wurf und
    Wahrscheinlichkeit fest. Kettenbremse je Kette nach R10: Das 17. Glied wird `SKIPPED`, die
    Meldung heißt `CHAIN_STOPPED`.
  - Nach `LAST_DAY` keine Meldung mehr.
  - Dazu `chance_info()`, `get_entry()`, `running_entries()` und `is_finished()`.
  - Folgetermine bekommen `source_title`, den Titel des auslösenden Ereignisses.
  - `CatalogValidator` nutzt danach `TimelineRun.FIRST_DAY` und `LAST_DAY` statt eigener
    Konstanten.

  Dauer und jährliche Ereignisse folgen in Phase 5, Eingriffe in Phase 8.
- [x] T023 [A] [US1] `src/test/test_timeline_run.gd`, Teil 1, mit Fixtures
  `src/test/fixtures/catalog_us1_*.json`:
  - Fixe Termine liegen an ihrem Tag.
  - Gesetzte Termine liegen im Fenster und halten den Mindestabstand; Seed 1 und 2 unterscheiden
    sich, jeder Seed ist wiederholbar (US1, Szenarien 3 und 4).
  - 100 % Chance tritt im Januar 1985 ein (US1, Szenario 6); der Termin hat die Herkunft
    „gewürfelt“ mit Würfelwert und Schwelle (Szenario 7).
  - Tag für Tag und in Sprüngen ergibt dasselbe Protokoll (Szenario 8).
  - FR-015: Ändert sich die Chance eines Ereignisses, kommt eines hinzu oder fällt eines weg,
    behalten alle übrigen ihre Termine, außer denen, die davon abhängen.
  - Der Mindestabstand gilt zu jedem Termin, der weder entfallen noch abgesagt ist, in beide
    Richtungen, auch zu geplanten (FR-005; Wortlaut angeglichen 2026-10-21).
  - Bedingungen; Folgeereignis mit Chance und Spanne, sein Wurf steht im Termin; Kettenbremse je
    Kette, zwei Ketten am selben Tag werden getrennt gezählt; nichts nach dem 31.12.1999.
- [x] T024 [A] [US1] Autoload `src/core/timeline.gd` fertigstellen (Vertrag):
  - `clock` und `run`; Verbindung mit `day_passed` der Uhr.
  - `start_game(seed)`: ohne Seed wird aus 0 bis 2.147.483.647 gewürfelt.
  - `get_seed()`, `get_event()` und `running_entries()`, das an `run` durchreicht (R12).
  - `_on_day_passed()` macht aus jeder Meldung das Signal laut Vertrag; `CHAIN_STOPPED` wird zu
    `entry_skipped` und einer Warnung über `push_warning()` (FR-018).
  - `start_game()` per `call_deferred()` aus `_ready()` (R12); ein gültiger Katalog erzeugt keine
    Ausgabe.
  - Die fünf Signale senden jetzt; `@warning_ignore("unused_signal")` aus T017 entfällt.
- [x] T025 [A] [US1] `src/test/test_timeline.gd`, eigene Instanz mit `catalog_path` auf eine
  Fixture und eigener Uhr (Vertrag, Ablauf):
  - Signale in der Reihenfolge des Tagesablaufs.
  - Ein Ereignis mit Fehler fehlt im Lauf und wird gemeldet.
  - Ein fehlender Katalog ergibt einen leeren Lauf und eine Fehlermeldung mit Pfad (FR-049).
  - Die Kettenbremse kommt als `entry_skipped` mit Warnung.
- [x] T026 [A] [P] [US1] Textausgabe nach Vertrag, Abschnitt Textausgabe:
  - `src/core/timeline/schedule_text.gd` (`ScheduleText`) mit Kopfzeile und Zeilenformat
    „TT.MM.JJJJ  <bis, 14>  <kennung, 28>  <herkunft, 12>  <zustand, 12>  <titel>“, dahinter die
    Zusätze „(Folge von …)“, „(lief schon vor Spielbeginn)“ und „(Ende nach Spielende)“;
    verzögerte Wirkungen darunter.
  - `src/tools/werkstatt/fahrplan_ausgabe.gd` (`extends SceneTree`) mit `--seed`, `--bis`,
    `--katalog` und `--protokoll` nach `--`. Es spielt den Lauf bis `--bis` ab. Bei Katalogfehlern
    stehen die Meldungen auf stderr, die Ausgabe läuft ohne die fehlerhaften Ereignisse, Exit-Code
    1; bei unlesbarem Katalog nur die Meldung, Exit-Code 1 (R18).

  Hängt an T022.
- [x] T027 [A] [US1] `src/test/test_schedule_text.gd`:
  - Kopfzeile, Spaltenbreiten, Spalte „bis“ und die Zusätze; verzögerte Wirkung unter ihrem
    Termin.
  - SC-002: 10 Läufe mit gleichem Seed, fünf Tag für Tag und fünf in Sprüngen, ergeben 10 gleiche
    Ausgaben.
- [x] T028 [A] [US1] `src/test/test_uebernahme.gd`, Teil 2, an der eingefrorenen Übernahme:
  - Für die Seeds 1 bis 100 entsprechen die fixen Termine Zeile für Zeile
    `fixtures/historische_ereignisse.txt` (SC-005).
  - „Intel Pentium erscheint“ am 22.03.1993 meldet „Preis cpu_486 −30 %“, am 05.04.1993 folgt
    „Nachfrage ram +20 %“ (US1, Szenario 5).
  - Seed 4711 enthält alle 19 historischen Termine (Szenario 1).
- [x] T029 [A] [US1] Probe-Export (research.md, R4): macOS-App nach `build/macos/` exportieren,
  das Programm in der App im Terminal starten und prüfen, dass keine Meldung zum Ereigniskatalog
  erscheint. Falls doch, `*.json` in `include_filter` von `src/export_presets.cfg` aufnehmen und
  erneut prüfen. Danach `src/export_presets.cfg` auf Zugangsdaten durchsehen, die der Export
  eingetragen haben könnte (Verfassung, Arbeitsweise). Hängt an T024.
- [x] T030 [K] [US1] Phase 3 abnehmen nach quickstart.md, Abschnitte 1, 2, 3 und 6

**Checkpoint**: Das Spiel spult einen wiederholbaren Fahrplan ab, die Textausgabe zeigt ihn. Abnahme
durch Klaus, dann Auftrag für Phase 4.

---

## Phase 4: User Story 2 - Ereignisse in der Werkstatt anlegen und pflegen (Priority: P1)

**Goal**: Klaus pflegt den Katalog in der Werkstatt: anlegen, ändern, prüfen, speichern, mit
Rückgängig, Verwerfen und Sicherungskopie, ohne Code.

**Independent Test**: Je ein Ereignis jeder Art anlegen, speichern, Werkstatt schließen und wieder
öffnen; die Textausgabe zeigt die neuen Termine (quickstart.md, Abschnitt 4.1).

### Implementation for User Story 2

- [x] T031 [A] [P] [US2] `src/tools/werkstatt/werkstatt_theme.tres` nach dem Abschnitt
  „Werkzeuge“ (T002): Farbrollen mit den Werten aus `UiPalette`, StyleBoxes für Panel, Button,
  LineEdit, ItemList, Tree und TabContainer. Schrift laut Style-Guide: Open Sans SemiBold aus
  `ThemeDB.fallback_font` in der Größe 14 (`default_font_size`), Titel 16, Zeitachse 12; die
  Werkstatt setzt die Schrift per Code als `default_font` (R14).
- [x] T032 [A] [US2] `src/tools/werkstatt/catalog_editor.gd` (`CatalogEditor`) laut Vertrag:
  - **Datei:** `open()`; `save(force)` gibt ohne `force` `ERR_FILE_ALREADY_IN_USE` bei fremder
    Änderung oder beim Öffnen unlesbarer Datei; `revert()` liest neu, leert den Verlauf und löscht
    die Sicherungskopie (FR-034); `new_catalog()` mit den zehn Kategorien; `is_dirty()` über
    `UndoRedo.get_version()`.
  - **Meldungen:** `issues()` mit den Meldungen beim Lesen, die bis zum nächsten Speichern stehen
    bleiben (ereigniskatalog.md, Regel 5), und der Prüfung nach jeder Änderung; `has_errors()`.
  - **Ereignisse:**
    - `suggest_id()`: ä→ae, ö→oe, ü→ue, ß→ss, sonst `_`, eindeutig mit `_2`, `_3`.
    - `add_event(kind, title, category, day, id)`: eine leere Kennung heißt Vorschlag;
      `duplicate_event()`.
    - `delete_event()` entfernt die Verweise mit, in einer Aktion (FR-036); `rename_event()`
      zieht die Verweise nach.
    - `set_event_field()`; `set_event_fields()` ändert mehrere Felder in einer Aktion;
      `set_event_kind()` behält Zeitfenster, Mindestabstand und Dauer (FR-031).
  - **Listen und Kategorien:**
    - `add_item()`, `remove_item()`, `set_item_field()`.
    - `add_category()`: Kennung aus dem Namen, danach fest; die erste freie Farbe aus
      `UiPalette.CATEGORY_TOKENS`, sind alle vergeben, die am seltensten benutzte, bei Gleichstand
      die frühere.
    - `set_category_field()`; `delete_category()` gibt `ERR_UNAVAILABLE`, solange Ereignisse
      dazugehören.
  - **Verlauf:** `undo()`, `redo()`, `can_undo()`, `can_redo()`, je Änderung genau eine Aktion
    mit Namen.
  - **Sicherung** (FR-050, R23): `backup_path` mit der Vorgabe `user://werkstatt_sicherung.json`;
    Inhalt `{"catalog", "format": 1, "path", "saved"}`; `write_backup()`, `has_backup()`,
    `backup_matches()`, `backup_info()`, `restore_backup()` und `discard_backup()`. Abgelöst
    durch T078 (2026-10-21): je Katalog eine eigene Datei im `backup_folder`.
  - `UndoRedo` in `NOTIFICATION_PREDELETE` freigeben.
- [x] T033 [A] [US2] `src/test/test_catalog_editor.gd`, mit eigener Sicherungsdatei über
  `backup_path` und Katalogen in einem Testordner:
  - **Bearbeiten:** jede ändernde Methode samt Rückgängig und Wiederholen (US2, Szenario 7);
    Kennungsvorschlag „neubaugebiet_am_stadtrand“ (Szenario 1); Umbenennen zieht Verweise nach
    (Szenario 6); `set_event_fields()` ist ein Schritt.
  - **Löschen und Art:** Löschen mit Verweisen ist ein Schritt; ein Artwechsel behält gemeinsame
    Werte; eine belegte Kategorie lässt sich nicht löschen.
  - **Kategorienfarben:** Neben den zehn Kategorien der Übernahme bekommt eine elfte `kassenrot`,
    die erste der am seltensten benutzten Farben.
  - **Speichern und Verwerfen:** Eine Feldänderung ändert genau eine Zeile der Datei (Szenario 2,
    FR-035); eine fremde Änderung wird erkannt; eine unlesbare Datei bleibt unberührt;
    `revert()` stellt den Stand der Datei her und leert den Verlauf. Ein unbekannter Schlüssel
    bleibt als V22 in `issues()`, auch nach einer Änderung, und `has_errors()` ist wahr.
  - **Sicherung:** schreiben, übernehmen und verwerfen; `backup_matches()` erkennt die Kopie
    eines anderen Katalogs.
- [x] T034 [A] [US2] `src/tools/werkstatt/werkstatt.tscn` und `werkstatt.gd` (`Werkstatt`) laut
  Vertrag:
  - **Aufbau:** Toolbar mit Speichern, Verwerfen, Rückgängig, Wiederholen und Statuszeile;
    `Main` mit `EventList`, `Center` (Platz für `TimelineView`, `Tabs` vorerst mit „Prüfung“) und
    `FormScroll`; Theme aus T031, die Schrift per Code.
  - **Fenster** (außer headless): `CONTENT_SCALE_MODE_DISABLED`, `content_scale_factor` aus
    `DisplayServer.screen_get_scale()`, maximiert außer bei `Engine.is_embedded_in_editor()`,
    Verarbeitung von `GameWindow` aus.
  - **Start:** `catalog_path` mit der Vorgabe `EventCatalog.DEFAULT_PATH`, `--katalog` nach `--`
    setzt ihn. Die Sicherungskopie wird nur angeboten, wenn `backup_matches()`, sonst nennt ein
    Hinweis ihren Pfad (abgelöst durch T078: Kopien anderer Kataloge liegen in eigenen Dateien,
    einen Hinweis auf sie gibt es nicht mehr). Fehlende Datei → leeren Katalog anbieten; unlesbare
    Datei → Dialog mit Zeile und Grund.
  - **Speichern:** Bei `has_errors()` fragt ein Dialog „Der Katalog hat N Fehler. Trotzdem
    speichern?“; bei `ERR_FILE_ALREADY_IN_USE` folgt die Rückfrage zur fremden Änderung, dann
    `save(true)` (FR-034).
  - **Verwerfen:** Rückfrage, dann `revert()`.
  - **Schließen:** `auto_accept_quit = false`, `NOTIFICATION_WM_CLOSE_REQUEST` mit Rückfrage
    „Speichern / Verwerfen / Abbrechen“.
  - **Laufend:** `Timer` alle 120 s für `write_backup()`; Kürzel S, Z und Shift+Z mit
    `command_or_control_autoremap`.
- [x] T035 [A] [P] [US2] `src/tools/werkstatt/event_list.tscn` und `event_list.gd` (`EventList`):
  - Suche über den Titel (Teilwort, Groß- und Kleinschreibung egal), Filter nach Art und
    Kategorie; Signal `event_selected(id)`.
  - Zeichen für Fehler und Warnung je Zeile.
  - „Neu …“ öffnet einen Dialog mit Art, Titel, Kategorie und der vorgeschlagenen Kennung, die
    Klaus ändern kann (US2, Szenario 1; FR-032). Dazu „Duplizieren“ und „Löschen“ mit Rückfrage,
    die die Verweise nennt.
- [x] T036 [A] [US2] `src/tools/werkstatt/event_form.tscn` und `event_form.gd` (`EventForm`):
  - Felder je Art laut Vertrag.
  - Listen für Wirkungen (mit `scope` bei Ereignissen mit Dauer), Folgeereignisse (Ziel aus der
    Ereignisliste, Chance in %, Verzögerung von–bis) und Bedingungen.
  - Wirkungsziele aus den schon benutzten vorgeschlagen.
  - Eingaben: Komma oder Punkt, Prozent, `TT.MM.JJJJ` auch ohne führende Nullen. Ungültiges wird
    nicht übernommen: Der alte Wert bleibt, ein Hinweis erscheint. Eine Eingabe gilt beim
    Verlassen oder mit Enter; Enter gibt den Fokus ab (R15).
  - Eine Änderung von „Anzahl von–bis“ verteilt die Gewichte neu, alle gleich auf zwei
    Nachkommastellen; den Rest bekommt das letzte Gewicht, damit die Summe genau 100 ist (bei
    sechs Anzahlen 16,67 · 5 und 16,65). Beides geht mit `set_event_fields()` als eine Aktion an
    den Katalog.
  - `focus_field(field)` setzt den Fokus auf ein Feld, auch in den Listen wie
    `effects[1].delay_days`.
  - Bereich für Kategorien: anlegen, umbenennen, Farbe aus `UiPalette.CATEGORY_TOKENS`, löschen
    (FR-031).
- [x] T037 [A] [P] [US2] `src/tools/werkstatt/issues_panel.gd` (`IssuesPanel`): Liste mit Stufe,
  Ereignis, Feld und Text; ein Klick sendet `issue_activated(event_id, field)`
- [x] T038 [A] [US2] Verdrahtung in `src/tools/werkstatt/werkstatt.gd` nach Vertrag, Abschnitt
  „Verdrahtung“:
  - Auswahl aus Liste und Prüfung; das Formular zeigt das gewählte Ereignis.
  - `issue_activated` wählt das Ereignis und ruft `EventForm.focus_field()` auf (FR-033).
  - `catalog_changed` und `issues_changed` aktualisieren Liste, Formular, Prüfung und Toolbar.
  - Ein neues Ereignis wird gewählt, und der Fokus steht im Titel.

  Hängt an T034 bis T037.
- [x] T039 [A] [US2] `src/test/test_werkstatt_scene.gd`:
  - Die Szene baut headless mit `catalog_path` auf eine Kopie von `catalog_minimal.json` ohne
    Fehler auf und lässt das Fenster unangetastet.
  - Mit einer Fixture mit Fehler führt `issue_activated` zum Ereignis und zum Feld (FR-033).
- [x] T040 [K] [US2] Phase 4 abnehmen nach quickstart.md, Abschnitte 1 und 4.1, dazu FR-029
  (Lesbarkeit, Farben, Kontrast)

**Checkpoint**: Klaus pflegt Ereignisse in der Werkstatt ohne Code. Abnahme durch Klaus, dann
Auftrag für Phase 5.

---

## Phase 5: User Story 3 - Jährliche Ereignisse und Ereignisse mit Dauer (Priority: P2)

**Goal**: Dauer und jährliche Ereignisse im Kern; Weihnachtsgeschäft, Jahreszeiten und CeBIT stehen
im Katalog; die Spieluhr meldet das Weihnachtsgeschäft nicht mehr.

**Independent Test**: Die Textausgabe zeigt das Weihnachtsgeschäft in allen 15 Jahren mit Beginn
am 1. November und Ende mit dem 31. Dezember (quickstart.md, Abschnitt 4.2).

### Implementation for User Story 3

- [x] T041 [A] [US3] `src/core/timeline/timeline_run.gd`, Teil 2 (research.md, R9):
  - **Dauer:** `end_day` = Beginn + Dauer. Tagesablauf, Schritt 1: Enden vor Beginnen, Zustand
    `ENDED`.
  - **Wirkungen:** `ONCE` wird einmal gemeldet. `DURING` meldet `EFFECT_ENDED`; eine verzögerte
    `DURING`-Wirkung endet mit dem Ereignis.
  - **FR-022:** Läuft das Ereignis noch, wird der neue Termin `ENTRY_SKIPPED`.
  - **Jährlich:** Kandidaten sind die Vorkommen mit Beginn in den Jahren `yearly_from − 1` bis
    `yearly_to`. In den Fahrplan kommt nur, was sich mit dem 01.01. von `yearly_from` bis 31.12.
    von `yearly_to` und mit dem Spielzeitraum überschneidet. „ende“ heißt Monatsende.
  - Ein Vorkommen, das vor dem 01.01.1985 begonnen hat, beginnt am Tag 0 mit
    `started_before_game`; seine Tage rechnet `GameDate` mit negativen Indizes (T007).
  - Nach dem 31.12.1999 wird kein Ende mehr gemeldet.
- [x] T042 [A] [US3] `src/test/test_timeline_run.gd`, Teil 2, mit Fixtures
  `src/test/fixtures/catalog_us3_*.json`:
  - Weihnachtsgeschäft: Beginn am 01.11.1993, Ende am 01.01.1994 (US3, Szenario 1).
  - Der Winter 1984/85 beginnt am Tag 0 mit `started_before_game`; am 01.03.1985 kommt erst sein
    Ende, dann der Beginn des Frühlings (Szenario 2).
  - 42 Tage ab dem 10.03.1994: letzter Tag 20.04.1994, Ende am 21.04.1994 (Szenario 3); eine
    `ONCE`-Pressemeldung hat kein Ende (Szenario 4).
  - Ein laufender Lieferengpass entfällt beim zweiten Termin (Szenario 6).
  - Der Winter 1987/88 reicht bis zum 29.02.1988; der letzte Winter reicht bis zum 29.02.2000,
    sein Ende wird nicht gemeldet.
  - Eine CeBIT ab 1986 hat 1985 kein Vorkommen.
- [x] T043 [A] [P] [US3] Altlasten entfernen (FR-024):
  - `src/core/game_clock.gd`: `signal season_changed` und die beiden Zeilen in `advance_day()`,
    die es über `is_holiday_season()` auslösen.
  - `src/core/game_date.gd`: `is_holiday_season()` und `season()`.
  - Tests: in `src/test/test_game_clock.gd` der Test
    `test_weihnachtsgeschaeft_meldet_sich_am_ersten_november`, in `src/test/test_game_date.gd` die
    Tests zu Jahreszeit und Weihnachtsgeschäft.
- [x] T044 [K] [US3] Kalender-Ereignisse in der Werkstatt anlegen und speichern, Kategorie
  „Kalender“, Startwerte aus research.md, R19:
  - Weihnachtsgeschäft: jährlich 1985 bis 1999, 01.11. bis Ende Dezember, „Kundenstrom * +30 %“,
    gilt nur während.
  - Frühling, Sommer, Herbst, Winter: jährlich 1985 bis 1999, ab 01.03., 01.06., 01.09. und
    01.12. bis zum Monatsende vor der nächsten, ohne Wirkung.
  - CeBIT: jährlich 1986 bis 1999, 15.03. bis 21.03., „Presse messe“ als einmaliger Anstoß.

  Wenn Klaus lieber zusieht, legt Claude sie in der Werkstatt an. Hängt an T040 und T041.
  Erledigt am 2026-10-20: Auf Klaus' Wunsch hat Claude sie über den `CatalogEditor` angelegt,
  mit denselben Aufrufen wie die Werkstatt; Kennungen `weihnachtsgeschaeft`, `fruehling`,
  `sommer`, `herbst`, `winter`, `cebit`.
- [x] T045 [A] [US3] `src/test/test_shipped_catalog.gd`, Teil 2:
  - Die sechs Kalender-Ereignisse sind vorhanden (FR-023).
  - Das Weihnachtsgeschäft liegt in allen 15 Jahren vom 01.11. bis zum 31.12.; das Ende von 1999
    liegt nach Spielende (SC-009).
  - Der Katalog bleibt fehlerfrei.

  Hängt an T044.
- [x] T046 [K] [US3] Phase 5 abnehmen nach quickstart.md, Abschnitte 1 und 4.2

**Checkpoint**: Kalender-Ereignisse und Dauer funktionieren, die Uhr ist entschlackt. Abnahme durch
Klaus, dann Auftrag für Phase 6.

---

## Phase 6: User Story 4 - Ereignisse auf dem Zeitstrahl eintakten (Priority: P2)

**Goal**: Der Zeitstrahl zeigt den Katalog 1985 bis 1999 und lässt Klaus per Maus eintakten.

**Independent Test**: Ein fixes Ereignis auf dem Zeitstrahl verschieben, speichern, die
Textausgabe zeigt das neue Datum.

### Implementation for User Story 4

- [x] T047 [A] [US4] `src/tools/werkstatt/timeline_view.gd` (`TimelineView`), Zeichnen (FR-037):
  - Achse mit Jahren, ab Monatszoom mit Monaten und Tagesstrichen.
  - Je Kategorie eine Zeile in ihrer Farbe (`UiPalette.by_token()`).
  - Marken je Art; überlappende werden in Unterzeilen gestapelt. Titel stehen nur bei Platz, in
    Textfarbe auf dem Grund neben der Marke (R14).
  - „Nur als Folge“ bekommt keine Marke.

  Kandidat für eine `[K]`-Aufgabe (plan.md, „Was Klaus dabei lernt“).
- [x] T048 [A] [US4] `TimelineView`, Eingaben laut Vertrag, Tabelle der Eingaben:
  - **Navigation:** Zoom mit Cmd- bzw. Ctrl-Mausrad um die Mausposition, vom ganzen Zeitraum bis
    zu einem Monat; Verschieben mit Mausrad, Shift-Mausrad und Ziehen auf freier Fläche.
  - **Ziehen:** Datum fixer Ereignisse tagesgenau, das Datum steht am Mauszeiger; Ränder von
    Zeitfenster und Dauer. Jährliche Ereignisse lassen sich nicht ziehen (Hinweis). Beim
    Loslassen genau ein `event_moved`.
  - **Vorschau** (R16): Während des Ziehens prüft die Ansicht eine Kopie des Ereignisses mit
    `CatalogValidator.validate_event()` und zeigt die erste Fehlermeldung neben dem Datum am
    Mauszeiger; der Katalog ändert sich erst beim Loslassen.
  - **Übrige Maus:** `_get_tooltip()`; Rechtsklick öffnet ein `PopupMenu` mit Bearbeiten,
    Duplizieren, Löschen; Doppelklick auf freie Fläche sendet `create_requested`.
- [x] T049 [A] [US4] `TimelineView` in `src/tools/werkstatt/werkstatt.tscn` und `werkstatt.gd`
  einbinden:
  - `event_clicked` wählt das Ereignis.
  - `event_moved` geht an `CatalogEditor.set_event_field()`.
  - `create_requested` öffnet den Dialog „Neu …“ vorbelegt mit Art fix, der Kategorie der Zeile
    und dem Tag (R16, Klaus 2026-10-21); nach „Anlegen“ ist das neue Ereignis gewählt, der Fokus
    steht im Titel.
  - Das gewählte Ereignis ist hervorgehoben.
- [x] T050 [A] [P] [US4] `src/test/test_timeline_view.gd`: Umrechnung Tag ↔ Pixel bei mehreren
  Zoomstufen, Stapeln überlappender Marken, kein Ziehen bei jährlichen Ereignissen; die Vorschau
  meldet V10, wenn das Fenster zu klein wird, ohne den Katalog zu ändern. Hängt an T048.
- [x] T089 [A] [US4] Trackpad im Zeitstrahl: Wischen mit zwei Fingern verschiebt, Kneifen
  vergrößert um die Maus (Klaus, Phase 6, R16; Verfassung 2.1.1). Gebaut mit T048, nachgetragen
  mit T088.
- [x] T051 [K] [US4] Phase 6 abnehmen nach quickstart.md, Abschnitte 1 und 4.3 (US4, Szenarien 1
  bis 7, FR-037, FR-039)

**Checkpoint**: Eintakten per Maus funktioniert. Abnahme durch Klaus, dann Auftrag für Phase 7.

---

## Phase 7: User Story 5 - Die Zeitleiste ohne Spiel durchspielen (Priority: P2)

**Goal**: Der Simulator der Werkstatt erzeugt und spult Fahrpläne mit Begründungen ab, ohne das
Spiel.

**Independent Test**: Seed bis zum Ende laufen lassen, mit demselben Seed wiederholen; das
Protokoll stimmt mit der Textausgabe überein.

### Implementation for User Story 5

- [x] T052 [A] [US5] `src/tools/werkstatt/simulator_panel.tscn` und `simulator_panel.gd`
  (`SimulatorPanel`), Grundfunktionen laut Vertrag:
  - **Lauf:** Seed-Feld, das nur Ziffern annimmt, 0 bis 2.147.483.647 (FR-040), „Würfeln“,
    „Fahrplan erzeugen“. Gerechnet wird auf `editor.catalog.without_faulty(editor.issues())`;
    ein Hinweis nennt die ausgenommenen Ereignisse.
  - **Schalter:** „+1 Tag“, „+1 Monat“, „+1 Jahr“, „Bis …“ und „Bis zum Ende“, dazu das aktuelle
    Datum (FR-041).
  - **Anzeige:** Fahrplan-Tabelle mit Filter nach Zustand; Begründung und verzögerte Wirkungen des
    gewählten Termins; Protokoll.
  - **Katalog:** Ändert er sich während eines Laufs, erscheint „Katalog geändert, neu starten“.
- [x] T053 [A] [US5] `SimulatorPanel` als Tab „Simulator“ in `src/tools/werkstatt/werkstatt.tscn`
  einbinden
- [x] T054 [A] [US5] `src/test/test_werkstatt_scene.gd` erweitern:
  - Der Simulator erzeugt headless mit einer Fixture für Seed 4711 einen Fahrplan, und die
    Tabelle hat Zeilen.
  - Nach „Bis zum Ende“ sind `GameClock.date` und `GameClock.paused` unverändert (US5,
    Szenario 5).
- [x] T090 [A] [US4] Waagerechte Leiste unter der Zeitfläche und Knöpfe „+“, „−“ und „Alles“ oben
  links im Zeitstrahl (Wünsche von Klaus bei T055). Gebaut in Phase 7, nachgetragen mit T088.
- [x] T055 [K] [US5] Phase 7 abnehmen nach quickstart.md, Abschnitte 1 und 4.4, darin SC-004
  („Bis zum Ende“ unter 1 Sekunde), SC-007, FR-041 und FR-042

**Checkpoint**: Die Zeitleiste lässt sich ohne Spiel durchspielen. Abnahme durch Klaus, dann
Auftrag für Phase 8.

---

## Phase 8: User Story 6 - Was wäre, wenn: Spieleraktionen ausprobieren (Priority: P2)

**Goal**: Eingriffe im Kern und im Simulator, markierte Unterschiede, gespeicherte Proben.

**Independent Test**: Gleicher Seed mit und ohne Modifikator: Markiert sind nur die
Reklamationswelle und Abhängige; eine gespeicherte Probe ergibt nach dem Laden denselben Fahrplan.

### Implementation for User Story 6

- [x] T056 [A] [US6] `src/core/timeline/timeline_run.gd`, Teil 3, Eingriffe laut Vertrag:
  - `add_modifier()` lehnt mit `Error` und `last_refusal` ab: `to_day` < `from_day`, leerer
    Grund, doppelte Kennung, Ereignis nicht `CHANCE`.
  - `remove_modifier()`, `cancel_entry()`, `move_entry()`, `schedule_event()`: nur für Termine,
    die nicht fix oder jährlich sind, und für Tage nach `today` bis `LAST_DAY`; vor `begin()` ab
    Tag 0. Das erste Verschieben setzt `moved_from_day`.
  - **Eingriffsprotokoll:** Jeder angenommene Eingriff kommt mit `at_day = today` und den Feldern
    aus data-model.md nach `interventions`; Ablehnungen hinterlassen dort nichts.
  - `apply_intervention(record)` und `find_planned()`; jeder Eingriff erzeugt eine
    `INTERVENTION`-Meldung.
- [x] T057 [A] [US6] `src/test/test_interventions.gd` mit Fixtures
  `src/test/fixtures/catalog_us6_*.json`:
  - US6, Szenario 1: 8 % von 1990 bis 1993.
  - Szenario 3: 3 % Grundchance mit +4 und −6 ergibt 1 %; nach dem Entfernen von +4 bleibt −6,
    die Summe ist −3 %, die wirksame Chance 0 %.
  - Szenario 4: Absage des Termins vom 01.06.1992 am 01.01.1992.
  - Szenario 5: fix lässt sich nicht absagen; Szenario 6: Ablauf des Modifikators.
  - Randfälle aus den Edge Cases; Eingriffe vor `begin()`.
  - Eingriffsprotokoll: Jeder angenommene Eingriff steht mit seinem `at_day` darin; nachgespielt
    mit `apply_intervention()` an diesen Tagen ergibt ein frischer Lauf denselben Fahrplan.
  - SC-003: Seeds 1 bis 100 mit dem Modifikator aus Szenario 1, kein fremder Termin ändert sich.
- [x] T058 [A] [P] [US6] Eingriffe in `src/core/timeline.gd` mit gleichen Signaturen an `run`
  durchreichen. Hängt an T056.
- [x] T059 [A] [P] [US6] `src/core/timeline/schedule_diff.gd` (`ScheduleDiff`) mit der Paarung aus
  dem Vertrag: gleicher Tag, verschoben nur über `moved_from_day`, neu, weggefallen. Tests in
  `src/test/test_schedule_diff.gd`, darunter US6, Szenario 2, und ein Modifikator, der Termine
  nur dazubringt oder wegnimmt und dabei kein `MOVED` erzeugt. Hängt an T056.
- [x] T060 [A] [P] [US6] `src/tools/werkstatt/what_if_probe.gd` (`WhatIfProbe`) laut Vertrag:
  - Ordner `src/tools/werkstatt/proben/` mit `.gitkeep`; jede Methode mit Dateien nimmt den
    Ordner als Parameter mit dieser Vorgabe.
  - `write_file()` kanonisch wie beim Katalog, `read_file()`, `list_probes()`, `delete_file()`,
    `from_run()`.
  - `build_run()` nach data-model.md, „Neu abspielen“; füllt `not_applicable`.

  Tests in `src/test/test_what_if_probe.gd` mit eigenem Testordner: US6, Szenario 7, auch mit
  der Absage eines gewürfelten Termins; Szenario 8 nennt den nicht anwendbaren Eingriff;
  Löschen. Hängt an T056.
- [x] T061 [A] [US6] `SimulatorPanel`, Eingriffe:
  - `src/tools/werkstatt/intervention_dialog.tscn` und `intervention_dialog.gd`:
    - Modifikator: Ereignis, Wert in Prozentpunkten, Grund, Beginn, Ende als Pflichtfeld. Die
      Kennung entsteht aus dem Grund und ist eindeutig (`CatalogEditor.id_from()`,
      `unique_id()`), weil FR-025 eine verlangt.
    - Absagen: Grund. Verschieben: neuer Tag und Grund (FR-027, der Kern lehnt ohne Grund ab).
      Einplanen: Ereignis, Tag, Grund.
  - Liste der Modifikatoren mit „Entfernen“ und `chance_info()`, also Summe und Begrenzung.
  - `last_refusal` wird angezeigt.
  - Das Panel sammelt die Eingriffe in einer `WhatIfProbe` ohne Datei. „Fahrplan erzeugen“, „Neu
    starten mit Eingriffen“ (über `build_run()` bis zu dem Tag, auf dem der alte Lauf stand; seit
    T075 mindestens bis zum Tag des letzten Eingriffs) und „Neu starten ohne Eingriffe“ arbeiten wie
    im Vertrag. Die Eingriffe bleiben, bis die Werkstatt schließt oder eine Probe geladen wird.

  Hängt an T056 und T060.
- [x] T062 [A] [US6] `SimulatorPanel`, Unterschiede und Proben (FR-043, FR-051):
  - Gegenlauf ohne Eingriffe bis zum selben Tag, Markierungen über `ScheduleDiff`.
  - Weggefallene Termine stehen durchgestrichen, ein Filter zeigt „nur Unterschiede“.
  - „Probe speichern …“ mit Name, „Probe laden …“ aus der Liste, „Probe löschen“. Nicht
    anwendbare Eingriffe werden genannt.

  Hängt an T059 bis T061.
- [x] T063 [K] [US6] Phase 8 abnehmen nach quickstart.md, Abschnitte 1 und 4.5 (US6, Szenarien 1
  bis 8)

**Checkpoint**: Spieleraktionen lassen sich ausprobieren, vergleichen und als Probe speichern.
Abnahme durch Klaus, dann Auftrag für Phase 9.

---

## Phase 9: User Story 7 - Statistik über viele Spiele (Priority: P3)

**Goal**: Viele Spiele in Häppchen nach Zeitbudget durchrechnen und je Ereignis auswerten.

**Independent Test**: Test-Katalog mit 50 % pro Monat: Mittelwert über 1.000 Spiele zwischen 85,5
und 94,5.

### Implementation for User Story 7

- [x] T064 [A] [US7] Statistik-Klassen laut Vertrag:
  - `src/core/timeline/event_statistic.gd` (`EventStatistic`).
  - `src/core/timeline/timeline_statistics.gd` (`TimelineStatistics`) mit `run_for(budget_msec)`:
    das laufende Spiel monatsweise weiter, dann das nächste, bis das Budget verbraucht ist,
    gemessen mit `Time.get_ticks_usec()` (R17). Dazu `results()`.
  - `interventions`: Angewandt werden nur `add_modifier`, `remove_modifier` und `schedule`, je
    Spiel an ihrem `at_day` über `apply_intervention()` (R11, FR-045).
  - Obergrenze: Höchstzahl bei `CHANCE`, höchste Anzahl bei `PRESET`, sonst −1.
  - Gezählt werden Beginne (`RUNNING`, `OCCURRED`, `ENDED`); fehlerhafte Ereignisse sind
    ausgenommen; ein angefangenes Spiel zählt erst, wenn es fertig ist.
- [x] T065 [A] [US7] `src/test/test_timeline_statistics.gd`:
  - 50 % pro Monat ergibt einen Mittelwert von 85,5 bis 94,5 (SC-008, US7, Szenario 3).
  - Gesetzt 30/70 fehlt in 25 bis 35 % der Spiele (Szenario 6).
  - Wiederholt gerechnet ist das Ergebnis gleich (Szenario 5).
  - Ein Modifikator aus dem Eingriffsprotokoll wirkt in jedem Spiel (Szenario 4); einer, der am
    Tag d entfernt wurde, nur bis d.
  - Obergrenze −1 ohne Grenze.
  - `run_for(15)` kehrt nach etwa 15 ms zurück, höchstens um einen Monat Rechenzeit später.
- [x] T066 [A] [US7] `src/tools/werkstatt/statistics_panel.tscn` und `statistics_panel.gd`
  (`StatisticsPanel`) als Tab „Statistik“:
  - **Eingaben:** Anzahl (Vorgabe 1.000), Häkchen „Mit Modifikatoren und Einplanungen aus dem
    Simulator“, das das Eingriffsprotokoll des Simulators übergibt, „Starten“ und „Abbrechen“,
    Fortschrittsbalken.
  - **Ablauf:** je Bild `run_for(15)`.
  - **Ergebnis:** Tabelle mit Mittelwert, kleinster und größter Anzahl, „ohne“ in % und
    „Obergrenze“ in % (sonst „–“); Verteilung auf die Jahre als Balken; Hinweis auf ausgenommene
    Ereignisse.
- [x] T067 [K] [US7] Phase 9 abnehmen nach quickstart.md, Abschnitte 1 und 4.6, darin SC-004
  (unter 30 s vom Start bis 100 %)

**Checkpoint**: Alle sieben User Stories sind erfüllt. Abnahme durch Klaus, dann Auftrag für die
letzte Phase.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Großer Katalog, Doku, Gesamtprüfung, Abnahme

- [x] T068 [A] Großer Katalog (SC-011):
  - Ein Einmal-Skript erzeugt `src/test/fixtures/catalog_500.json` mit 250 fixen und 250
    Ereignissen über Wahrscheinlichkeit, kanonisch geschrieben.
  - `src/test/test_large_catalog.gd`: Die Prüfung braucht unter 100 ms, eine Änderung über den
    `CatalogEditor` samt neuer Prüfung unter 100 ms, ein Spiel unter 2 s.
  - Messwerte als Ausgangspunkt: Bei Phase 7 dauerte eine Änderung mit 500 Ereignissen 153 ms, also
    über dem Ziel. Bei Phase 9 gingen rund 40 % der Zeit eines Spiels auf `_may_start_again()` und
    `_running_entry()` in `TimelineRun`, die alle Termine eines Ereignisses durchgehen; eine Probe
    mit Abkürzung brauchte 1,8 statt 3,0 ms. Die Testsuite liegt seit Phase 9 bei rund 18 s.
- [x] T074 [A] Der Zeitstrahl folgt den Filtern der Liste (Klaus, 2026-10-21): Suche, Art und
  Kategorie der `EventList` gelten auch für den `TimelineView`; ohne Filter zeigt er alles wie
  bisher. Anlass: Mit `catalog_500.json` füllte allein die Kategorie Hardware die ganze Höhe des
  Zeitstrahls. Hängt an T068.
- [x] T091 [A] Die Werkstatt merkt sich die Lage ihrer Teiler in
  `user://werkstatt_einstellungen.cfg`, eine Sekunde nach dem Ziehen und beim Schließen; Test
  `src/test/test_werkstatt_settings.gd` (Wunsch von Klaus, Phase 10). Nachgetragen mit T088.
- [x] T069 [K] SC-011 nach quickstart.md, Abschnitt 5 von Hand prüfen:
  - `time` der Textausgabe;
  - Werkstatt mit `--katalog`, Ändern und Ziehen ohne Verzögerung. Gemessen bei Phase 7 mit 500
    Ereignissen, headless: eine Änderung ohne Lauf 153 ms, „Fahrplan erzeugen“ 200 ms, „Bis zum
    Ende“ 349 ms; nach T068 im Fenster: Feldwechsel 41 ms, Loslassen nach dem Ziehen 38 ms;
  - Statistik unter 5 Minuten.
  Erledigt (Klaus, 2026-10-21): Textausgabe mit 500 Ereignissen 0,56 s samt Start, Werkstatt und
  Statistik abgenommen.
- [x] T070 [C] [P] Doku nachziehen:
  - `CLAUDE.md`, Tabelle „Aufbau“: In der Zeile `src/core/` weicht „Event-Resources“ dem Kern
    unter `src/core/timeline/`; die Zeile `src/data/` nennt `event_catalog.json` statt
    `event_database.gd`; neu sind Zeilen für `src/core/timeline/` und `src/tools/werkstatt/`.
  - `CLAUDE.md`, Absatz zur Timeline: Fahrplan, Kern ohne Node, die fünf Signale.
  - `docs/features/Features.md`: Stand von Feature 002.
- [x] T071 [C] Review des ganzen Features gegen Spec und Verträge mit `/speckit-converge` als
  Lückensuche; die Lernnotizen aller Phasen stehen vollständig in
  `specs/002-zeitleisten-werkstatt/lernnotizen.md`. Ergebnis (2026-10-21): 14 Lücken, als
  Phase 11 mit T075 bis T088 angehängt
- [x] T072 [K] Quickstart vollständig durchgehen (Abschnitte 1 bis 6), dabei nach Abschnitt 4.7
  SC-001 (höchstens 10 Minuten) messen und die Werkstatt abnehmen (SC-010)
  Erledigt (Klaus, 2026-10-21): alle sechs Abschnitte bestanden, SC-001 in höchstens 10 Minuten,
  Werkstatt auch mit 500 Ereignissen flüssig und abgenommen (SC-010).
- [x] T073 [K] Feature abnehmen: die Abnahmen aus T006, T019, T030, T040, T046, T051, T055, T063,
  T067, T069 und T072 sind erledigt; über den Merge nach `main` entscheiden
  Erledigt (Klaus, 2026-10-21): Feature 002 abgenommen und nach `main` zusammengeführt.

---

## Abdeckung der Anforderungen

| Anforderung | Tasks |
|---|---|
| FR-001 Katalog als Datei | T004, T011, T012, T017, T018 |
| FR-002 bis FR-005 Ereignis und Arten | T010, T022, T023 |
| FR-006 Bedingungen | T009, T022, T023, T084 |
| FR-007 Wirkungen | T010, T041 |
| FR-008 Folgeereignisse, „nur als Folge“ | T009, T010, T022 |
| FR-009 Kategorien | T001, T004, T008, T009 |
| FR-010 bis FR-013 Fahrplan und Termine | T016, T022, T026, T079 |
| FR-014, FR-015 Seed und Würfel | T020, T023, T024, T052, T083; Betriebssysteme mit 11-03 |
| FR-016, FR-018, FR-019 Tagesablauf, Kettenbremse, Spielende | T022, T023, T024, T025, T041 |
| FR-017 Meldungen | T017, T024, T025, T085 |
| FR-020 bis FR-022 Dauer | T041, T042 |
| FR-023, FR-024 Kalender | T043, T044, T045 |
| FR-025 bis FR-027 Eingriffe | T021, T022, T056, T057, T058 |
| FR-028, FR-029 Werkstatt, Look | T001, T005, T031, T034, T040, T081 |
| FR-030 bis FR-032 Liste, Bearbeiten, Kennungen | T032, T033, T035, T036, T076, T080, T086 |
| FR-033 Prüfung in der Werkstatt | T014, T037, T038, T039, T076 |
| FR-034 bis FR-036 Speichern, Rückgängig, Löschen | T011, T032, T033, T034 |
| FR-037 bis FR-039 Zeitstrahl | T047, T048, T049, T050, T074, T077, T089, T090 |
| FR-040 bis FR-042 Simulator | T052, T053, T054 |
| FR-043 Eingriffe im Simulator, Vergleich | T059, T061, T062, T075 |
| FR-044, FR-045 Statistik | T064, T065, T066, T075, T082 |
| FR-046 Textausgabe | T026, T027 |
| FR-047 Übernahme | T003, T004, T012, T018, T028 |
| FR-048, FR-049 Prüfung und Fehler beim Start | T017, T018, T025 |
| FR-050 Sicherungskopie | T032, T033, T034, T078 |
| FR-051 Proben | T060, T062, T075 |
| SC-001, SC-010 | T072 |
| SC-002 | T023, T027, T085 |
| SC-003 | T057 |
| SC-004 | T055, T067 |
| SC-005 | T028 |
| SC-006 | T015 |
| SC-007 | T052, T055 |
| SC-008 | T065 |
| SC-009 | T045 |
| SC-011 | T068, T069 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: keine Abhängigkeiten nach außen. T001, dann die Freigabe T002; T004 braucht
  T002. T003 und T005 hängen an nichts; T006 schließt die Phase ab.
- **Foundational (Phase 2)**: braucht Phase 1.
  - T007, T008 und T009 parallel; T010 braucht T009.
  - T011 braucht T010; T012 braucht T004 und T011; T013 braucht T012.
  - T014 braucht T008 und T011; T015 braucht T013 und T014.
  - T016 braucht T010 und läuft parallel zu T011 bis T015.
  - T017 braucht T011, T014 und T016; T018 braucht T012 und T014.
- **US1 (Phase 3)**: braucht Phase 2.
  - T020 und T021 parallel; T022 braucht beide.
  - T023, T024, T026 und T028 brauchen T022; T025 und T029 brauchen T024; T027 braucht T026.
- **US2 (Phase 4)**: braucht Phase 2 und T002; die Textausgabe für ihren unabhängigen Test kommt
  aus Phase 3.
  - T031 parallel zu T032; T033 braucht T032; T034 braucht T031 und T032.
  - T035 und T037 parallel zu T036; T038 braucht T034 bis T037; T039 braucht T038.
- **US3 (Phase 5)**: braucht US1 (T022). T043 parallel zu T041; T042 braucht T041; T044 braucht
  T040 und T041; T045 braucht T044.
- **US4 (Phase 6)**: braucht US2 (T038). T048 braucht T047, T049 und T050 brauchen T048.
- **US5 (Phase 7)**: braucht US1 und US2. T053 braucht T052, T054 braucht T053.
- **US6 (Phase 8)**: braucht US5. T057 bis T060 brauchen T056; T058, T059 und T060 laufen danach
  parallel. T061 braucht T056 und T060; T062 braucht T059 bis T061.
- **US7 (Phase 9)**: braucht US1; das Häkchen „aus dem Simulator“ braucht das Eingriffsprotokoll
  aus US6.
- **Polish (Phase 10)**: braucht alle User Stories.

Umgesetzt wird trotzdem in der Reihenfolge der Phasen, eine nach der anderen (plan.md).

### User Story Dependencies

- **US1** ist der Kern und kommt zuerst; **US2** folgt direkt danach. Zusammen sind sie das MVP,
  beide P1.
- **US3** ergänzt den Kern aus US1; T044 nutzt die Werkstatt aus US2.
- **US4** und **US5** bauen auf der Werkstatt auf; **US6** auf dem Simulator aus US5.
- **US7** braucht den Kern und für das Häkchen das Eingriffsprotokoll aus US6.
- `timeline_run.gd` wird in Phase 3, 5 und 8 erweitert, `test_werkstatt_scene.gd` in Phase 4
  und 7: Diese Phasen laufen nacheinander.

### Within Each User Story

- Erst Klassen und Logik, dann Tests, dann die Oberfläche, dann die Abnahme durch Klaus.
- Eine Phase gilt erst als fertig, wenn Claude das Ergebnis des Agents geprüft und Klaus es
  abgenommen hat.

### Parallel Opportunities

- Phase 1: T003 und T005 parallel zum Style-Guide.
- Phase 2: T007, T008 und T009 parallel; T016 parallel zu T011 bis T015.
- Phase 3: T020 und T021 parallel; T026 parallel zu T023 bis T025.
- Phase 4: T031 parallel zu T032; T035 und T037 parallel zu T036.
- Phase 5: T043 parallel zu T041.
- Phase 6: T050 parallel zu T049.
- Phase 8: T058, T059 und T060 nach T056 parallel zueinander.

---

## Parallel Example: User Story 1

```text
# Der Godot-Agent baut die kleinen Klassen gleichzeitig:
Task: "T020 [A] EventDice in src/core/timeline/event_dice.gd"
Task: "T021 [A] ChanceModifier und TimelineMessage in src/core/timeline/"

# Textausgabe parallel zu den Tests des Laufs:
Task: "T026 [A] ScheduleText und fahrplan_ausgabe.gd"
Task: "T023 [A] test_timeline_run.gd, Teil 1"
```

---

## Implementation Strategy

### MVP First (User Story 1 und 2)

1. Phase 1: Setup, mit dem Style-Guide zuerst.
2. Phase 2: Foundational. Das blockiert alles.
3. Phase 3: US1. **Halt und prüfen:** Der Fahrplan ist wiederholbar (T030).
4. Phase 4: US2. **Halt und prüfen:** Klaus pflegt Ereignisse ohne Code (T040).

### Incremental Delivery

1. Setup und Foundational: Katalog und Prüfregeln stehen.
2. US1: Das Spiel spult den Fahrplan ab.
3. US2: Die Werkstatt pflegt den Katalog.
4. US3: Kalender und Dauer.
5. US4: Eintakten auf dem Zeitstrahl.
6. US5: Simulator.
7. US6: Was wäre, wenn.
8. US7: Statistik.
9. Jede Phase einzeln von Klaus beauftragt und abgenommen.

### Arbeitsteilung

- Claude beauftragt den Agent je Phase mit den `[A]`-Tasks und prüft sein Ergebnis gegen Verträge
  und Verfassung. Dann bekommt Klaus Diff, Erklärung und Lernnotiz.
- `[K]`-Tasks erledigt Klaus selbst. Vor jeder Phase kann er sich `[A]`-Tasks nehmen, die er
  selbst bauen will; gute Kandidaten sind T011 (Katalog lesen und schreiben) und T047 (Zeitstrahl
  zeichnen).
- `[C]`-Tasks erledigt Claude.
- Committet wird nach Klaus' Abnahme einer Phase, auf `feature/002-zeitleisten-werkstatt`.

---

## Notes

- Format: Task-ID, Besitzer, `[P]` für parallel ausführbar, `[Story]` für die User Story.
- Die Verfassung verlangt kein testgetriebenes Vorgehen; Tests entstehen mit der Logik und müssen
  vor der Abnahme grün sein.
- Zu jeder `[A]`-Task schreibt der Agent eine Lernnotiz. Claude trägt sie nach jeder Phase in
  `specs/002-zeitleisten-werkstatt/lernnotizen.md` ein.
- Nach dem Anlegen, Verschieben oder Löschen von Skripten ruft der Agent einmal
  `Godot --headless --path src --import` auf. Erst dabei bekommen neue Skripte ihre `.uid`, und
  Godot lernt neue `class_name` kennen; ohne das scheitern Tests an unbekannten Klassen. Neue
  `.uid`-Dateien werden committet, verschobene behalten ihre über `git mv`.
- Nach Phase 2 hat das Projekt bis zum Ende von Phase 3 keine Ereignismeldungen. Das ist gewollt,
  denn es gibt noch keinen Abnehmer.

## Phase 11: Convergence

Lückensuche T071 mit `/speckit-converge` (2026-10-21): vier Prüfer lasen Spec, Plan, Verträge und
Aufgaben gegen den Code, Claude hat die Befunde nachgeprüft. Umgesetzt wird erst nach Klaus'
Freigabe, wie jede Phase. Die Gesamtabnahme mit T072 und T073 aus Phase 10 folgt erst danach.

- [x] T075 [A] Gesammelte Eingriffe nach `at_day` stabil sortiert nachspielen, in
  `WhatIfProbe.build_run()` und `TimelineStatistics`; den Endtag eines Neustarts bzw. einer
  gespeicherten Probe als größten Wert aus Stand des Laufs und letztem `at_day` festlegen; Test
  für den Ablauf Eingriff 1992, „Fahrplan erzeugen“, Eingriff vor Spielbeginn, Neustart mit
  Eingriffen, Probe und Statistik per FR-043, FR-045, FR-051, US6/AC2, US6/AC7, R11, R22
  (contradicts)
- [x] T076 [A] Ein Klick in Liste oder Prüfung trifft nach einer offenen Eingabe die gemeinte
  Zeile: Neubau von `EventList` und `IssuesPanel` ans Ende des Bilds schieben oder Zeilen
  behalten; Test mit echter Mauseingabe per FR-030, FR-033, Vertrag „Datenfluss“ (contradicts)
- [x] T077 [A] Rechtsklick und Menü im Zeitstrahl übernehmen eine offene Eingabe vorher
  (`_release_focus()` in `_on_right_click()`); Test mit „Duplizieren“ aus dem Menü per FR-039,
  US4/AC4, Vertrag „Zeitstrahl“ (partial)
- [x] T078 [K] [A] (Klaus, 2026-10-21: Sicherungsdatei je Katalog) Sicherungskopie trotz Kopie eines
  anderen Katalogs: Klaus entscheidet zwischen einer Sicherungsdatei je Katalogpfad (Empfehlung) und
  einer festgehaltenen Ausnahme mit Warnung beim Start; danach umsetzen, mit Test per FR-050, R23
  (partial)
- [x] T079 [A] Wirkungen „während“, die nie beginnen, etwa im auf Spielbeginn gekürzten Winter
  1984/85, weder im Fahrplan noch in der Begründung zeigen: `ScheduleEntry.due_effects()` nach
  derselben Regel wie der Lauf; Test per FR-013, FR-021, V19 (partial)
- [x] T080 [A] Eine Auswahl im Formular bleibt offen, auch wenn vorher ein anderes Feld eine
  offene Eingabe hatte; Test per FR-031 (partial)
- [x] T081 [K] [A] (Klaus, 2026-10-21: ja, Style-Guide Version 17) Fehlerkontur an Auswahlfeldern:
  Klaus klärt, ob der Style-Guide sie meint („Ein Feld mit Fehler bekommt eine Kontur …“); falls ja,
  Theme-Variante für `OptionButton` und Aufruf ergänzen per Verfassung IV, Style-Guide
  „Bedienelemente“ (partial)
- [x] T082 [A] Die Statistik zählt in „mit N Eingriffen“ nur die angenommenen Eingriffe und nennt
  abgelehnte per FR-045 (partial)
- [x] T083 [A] `Timeline.start_game()` lehnt Seeds über 2.147.483.647 mit Meldung ab; Test per
  FR-014 (partial)
- [x] T084 [A] Prüfregeln für von Hand geänderte Dateien: V21 prüft Kategorie-Kennungen auf
  `[a-z0-9_]+`, V15 lehnt eine Bedingung auf das eigene Ereignis ab; je eine Fixture per
  data-model (EventCategory, EventCondition), FR-006 (partial)
- [x] T085 [A] Fehlende Tests: Signale `event_ended` und `effect_ended` des Autoloads mit
  `catalog_us3_kalender.json`; SC-002 mit Eingriffsprotokoll Tag für Tag gegen Sprünge; V22 mit
  falschem Typ und unbekanntem Wert für `kind` und `scope` per FR-017, SC-002, V22 (partial)
- [x] T086 [A] Die Grenze von 20 Anzahlen im Formular festhalten und bei mehr Gewichten einen
  Hinweis zeigen, statt das Feld still unbearbeitbar zu lassen per FR-004, FR-031 (unrequested)
- [x] T087 [C] Spec auf die datierten Entscheidungen nachziehen: FR-026 und Edge Case (Ablehnung
  nach 1999, Verschieben auf denselben Tag), FR-037 (Filter, T074), FR-038 und Annahmen
  (Trackpad, Zoom-Knöpfe, waagerechte Leiste, Teiler merken), FR-039 und US4/AC5 (vorbelegter
  Dialog), FR-043 und FR-051 (Laden einer Probe ersetzt die gesammelten Eingriffe), FR-050 und
  Edge Case Absturz („Später“, Kopie eines anderen Katalogs, nach T078), FR-012 (Würfelwert bei
  gewürfelten und Folgeterminen; am Termin steht der letzte Grund), V19 (gekürztes erstes
  Vorkommen), US1/AC7 (Würfelwert im Simulator) per spec.md (unrequested)
- [x] T088 [C] Übrige Dokumente nachziehen: die erledigten Wünsche (Trackpad, waagerechte Leiste,
  Zoom-Knöpfe, Teiler merken) als Aufgaben vermerken, T074 in die Abdeckungstabelle, Messwerte
  bei T069 aktualisieren (Änderung 41 ms, Ziehen 38 ms), Mindestabstand in plan.md und T023 wie
  FR-005, R2 auf die Katalogklassen eingrenzen, die Grenze aus T086 in Vertrag und Datenmodell per
  plan.md, tasks.md, research.md (unrequested)
- [x] T092 [C] Zweite Lückensuche mit `/speckit-converge` über das ganze Feature, wenn T075 bis
  T088 erledigt sind (`docs/ki_dev.md`, Ablauf je Feature, Punkt 6). Neue Lücken werden Phase 12
  mit Klaus' Freigabe; ohne Befund folgen T072 und T073. Ergebnis (2026-10-21): 16 Befunde, als
  Phase 12 mit T093 bis T103 angehängt

## Phase 12: Convergence

Zweite Lückensuche T092 mit `/speckit-converge` (2026-10-21): zwei Prüfer, Kern und Werkstatt, lasen
Spec, Plan, Verträge und Aufgaben gegen den Code, Claude hat jeden Befund nachgeprüft. Verwandte
Befunde sind zu einer Aufgabe zusammengefasst. Umgesetzt wird erst nach Klaus' Freigabe; die
Gesamtabnahme mit T072 und T073 folgt danach.

- [x] T093 [A] CRITICAL: Fehlerkontur an allen Feldern, unter denen ein Fehlerhinweis steht, auch in
  Dialogen: Kennung in „Neu …“, Wert, Beginn, Ende und Tag im Eingriff-Dialog, Name in „Probe
  speichern …“, Anzahl der Spiele in der Statistik; `ErrorLineEdit`, solange der Hinweis steht, wie
  beim Feld „Bis“ im Simulator per Verfassung IV, Style-Guide „Bedienelemente“ (partial)
- [x] T094 [A] CRITICAL: Fokuslinie rundum sichtbar: Formular und Farbwahl der Kategorien bekommen
  rundum mindestens 4 Pixel Rand, damit Rollleiste und Bereichsgrenze die Linie nicht abschneiden;
  Bild aus dem echten Fenster per Verfassung IV, Style-Guide Rolle „Fokus“ (partial)
- [x] T095 [A] Keine offene Eingabe geht beim Neubau des Formulars verloren: Der Neubau übernimmt
  sie zuerst. Betroffen sind der Rechtsklick in die Fahrplan-Tabelle des Simulators und die Wahl im
  Menü „…“ am Wirkungsziel; Tests mit Rechtsklick und Menü per FR-031, FR-043, Vertrag „EventForm“
  (partial)
- [x] T096 [A] Schließen bei offenem Dialog zur Sicherungskopie gilt wie „Später“: Die Kopie bleibt;
  Test per FR-050, R23 (partial)
- [x] T097 [K] [A] (Klaus, 2026-10-21: nicht zeigen) Verzögerte Wirkungen abgesagter und entfallener
  Termine: Klaus entscheidet, ob Fahrplan und Begründung sie zeigen (Empfehlung: nicht zeigen, sie
  kommen nie); danach `due_effects()` nach Zustand filtern oder den Vertrag enger fassen, mit Test
  per FR-013, Vertrag zeitleiste.md (partial)
- [x] T098 [A] (dazu Tag 00, Entscheidung von Claude) Ein jährliches Ende „00-00“ oder „00-ende“ als
  V22 melden, statt es still als „ohne Dauer“ zu lesen; Fixture per Vertrag ereigniskatalog.md, V22
  (partial)
- [x] T099 [A] Probe-Dateien, die jemand von Hand geändert hat: Ein Modifikator ohne lesbaren Wert
  oder Beginn ist nicht anwendbar und wird genannt, ein Seed außerhalb von 0 bis 2.147.483.647 ist
  ein Lesefehler; Tests per FR-051, FR-014 (partial)
- [x] T100 [K] [A] (Klaus, 2026-10-21: Grenze festhalten, im Datenmodell) Zwei geplante Termine
  eines Ereignisses am selben Tag: Klaus entscheidet zwischen „Herkunft im Eingriffsprotokoll
  mitspeichern“ und „Grenze im Datenmodell festhalten“ (Empfehlung) per US6/AC7, data-model „Neu
  abspielen“ (partial)
- [x] T101 [K] [A] (Klaus, 2026-10-21: Tabelle mit Vorrang) Vorgabe-Teilung der Tabellen in
  Statistik und Simulator: Klaus entscheidet, ob die Tabelle Vorrang vor dem Bereich darunter
  bekommt (Empfehlung: ja); Bild aus dem echten Fenster per FR-041, FR-044 (partial)
- [x] T102 [C] Doku nachziehen: R22 (Endtag und Nachspielen nach `at_day`, T075), R23 (die alte
  Datei `werkstatt_sicherung.json` wird nicht mehr beachtet), Quickstart 4.1 (nach dem Test zur
  Sicherungskopie „Verwerfen“, nicht speichern), Vermerk „abgelöst durch T078“ bzw. „durch T075“ bei
  T032, T034 und T061, Quickstart „Abnahme je Phase“ um Phase 11 und 12 per research.md,
  quickstart.md, tasks.md (contradicts)
- [x] T103 [K] Phase 11 und 12 abnehmen nach quickstart.md, Zeilen „ab Phase 11“ und die von Phase
  12; danach T072 und T073 per docs/ki_dev.md, Ablauf je Feature, Punkt 5 (missing). Erledigt
  (Klaus, 2026-10-21): Phase 11 und 12 abgenommen

Keine weitere Lückensuche nach Phase 12 (Klaus, 2026-10-21); weiter mit T072 und T073.
