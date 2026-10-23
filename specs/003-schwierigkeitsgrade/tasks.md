---

description: "Taskliste für Feature 003 Schwierigkeitsgrade der Zeitleiste"
---

# Tasks: Schwierigkeitsgrade der Zeitleiste

**Input**: Design-Dokumente aus `specs/003-schwierigkeitsgrade/`

**Prerequisites**: plan.md, spec.md, research.md (R1 bis R19), data-model.md,
contracts/ereigniskatalog.md, contracts/zeitleiste.md, contracts/werkstatt.md, quickstart.md,
checklists/review.md

**Tests**: Die Verträge legen GUT-Tests fest (zeitleiste.md und werkstatt.md, Abschnitte Tests).
Sie entstehen mit der Logik und müssen vor jeder Abnahme grün sein, zweimal hintereinander mit
derselben Zahl von Prüfungen. Reiter, Formular, Simulator und Statistik prüft Klaus von Hand nach
quickstart.md.

**Organization**: Die Tasks folgen den sechs Phasen aus plan.md, „Umsetzungsphasen“, je User Story
eine Phase. Umgesetzt wird nach Verfassung 2.1.1, Grundsatz II, eine Phase nach der anderen und
nur auf Klaus' Auftrag; jede Phase endet mit seiner Abnahme. Welche Abschnitte des Quickstarts zu
welcher Abnahme gehören, steht dort in der Tabelle „Abnahme je Phase“. Die Befunde der Analyse vom
2026-10-22 sind eingearbeitet; Kürzel wie „B1“ oder „G1“ verweisen auf sie (plan.md, „Änderungen
nach der Analyse“).

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Entscheidungen, Freigaben, Abnahmen, Pflege in der Werkstatt, was er selbst bauen
    will.
  - `[A]` Godot-Agent `godot-entwickler`: Szenen, Nodes, GDScript, Tests, Fixtures.
  - `[C]` Claude: Doku, Review, Prüfung zwischen den Teilen einer Phase.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: zugehörige User Story aus spec.md (US1 bis US4)

## Path Conventions

- Godot-Projekt unter `src/`, Tests unter `src/test/`, Test-Kataloge unter `src/test/fixtures/`
  (GUT 9.7.1)
- Kern der Zeitleiste unter `src/core/timeline/`, Werkstatt und Textausgabe unter
  `src/tools/werkstatt/` (nicht im Export)
- Pfade, Klassen, Signale und Signaturen laut [zeitleiste.md](contracts/zeitleiste.md),
  [werkstatt.md](contracts/werkstatt.md) und [ereigniskatalog.md](contracts/ereigniskatalog.md);
  was dort nicht steht, gilt aus den Verträgen von Feature 002
- Nach dem Anlegen von Skripten ruft der Agent einmal `Godot --headless --path src --import` auf
  (siehe Notes)

---

## Phase 1: Setup und Grundlage (blockiert alles)

**Purpose**: Die Grundlinie festhalten, solange der Lauf noch der aus Feature 002 ist. Dann Grade,
Profile, Lesen und Schreiben des Abschnitts `profiles` und die Prüfregeln V25 bis V31, dazu alles,
was sonst Tests aus Feature 002 bräche.

**⚠️ CRITICAL**: Keine User Story beginnt, bevor diese Phase abgenommen ist. T001 kommt vor jeder
Änderung am Code.

- [x] T001 [A] Grundlinie einfrieren (research.md, R17; SC-007), mit dem Code auf dem Stand von
  `994b9f5`, bevor sich irgendetwas am Lauf ändert:
  - Mit der Textausgabe und `--no-header` für die Seeds 1, 4711 und 99999 und dem Katalog
    `res://test/fixtures/event_catalog_uebernahme.json`:
    - den Fahrplan bis zum 31.12.1999 nach
      `src/test/fixtures/fahrplan_uebernahme_seed_<n>.txt`, ohne die erste Zeile „# Seed …“;
    - mit `--protokoll` das Protokoll nach `src/test/fixtures/protokoll_uebernahme_seed_<n>.txt`.
  - Neuer Test `src/test/test_difficulty_baseline.gd`:
    - Er liest die Übernahme und stellt fest, dass `CatalogValidator.validate()` keinen Fehler
      meldet.
    - Je Seed `TimelineRun.new(catalog, seed)`, dann `advance_to(TimelineRun.LAST_DAY)`.
    - `ScheduleText.plan_lines()` ohne die erste Zeile und `ScheduleText.protocol_lines()` sind
      Zeichen für Zeichen wie die Fixtures.

    Er ist sofort grün und muss es bis zum Ende des Features bleiben (Analyse, U9).
- [x] T002 [A] [P] `src/core/timeline/difficulty.gd` (`Difficulty`) laut zeitleiste.md:
  - `enum Level { LEICHT, MITTEL, SCHWER }`, `DEFAULT := Level.MITTEL`,
    `WITH_PROFILE: Array[int] = [Level.LEICHT, Level.SCHWER]`;
  - `key()` mit `"leicht"`, `"mittel"`, `"schwer"`, leer bei einem unbekannten Grad; `label()`
    mit „Leicht“, „Mittel“, „Schwer“, sonst „Grad 7“; `from_key()` gibt −1 für einen unbekannten
    Namen, „Groß- und Kleinschreibung zählt“; `is_valid()`.

  Test `src/test/test_difficulty.gd`: alle drei Namen hin und zurück, `from_key("Schwer")` und
  `from_key("extrem")` ergeben −1, `is_valid(7)` und `is_valid(-1)` sind falsch.
- [x] T003 [A] [P] `src/core/timeline/chance_modifier.gd` laut zeitleiste.md, Abschnitt
  „ChanceModifier“; Felder, Vorgaben der Klasse und `is_active()` bleiben:
  - `KEYS := ["event_id", "from_day", "id", "reason", "to_day", "value"]`;
  - `from_dict(data, issues)` liest die Form der Katalogdatei. Ein fehlender Schlüssel, ein
    falscher Typ, ein unbekannter Schlüssel und ein Datum, das kein Kalendertag ist, ergeben V22
    und die Vorgabe aus data-model.md: „`from_day` = 0 und `to_day` = 5477“, „`value` = 0.0,
    `reason` = „““, `event_id` und `id` leer. Das Feld der Meldung ist der bloße Schlüssel, etwa
    `value`; Stelle und Ort setzt `DifficultyProfile.from_list()` (Analyse, U8).
  - `to_dict()`: Tage als `"JJJJ-MM-TT"`, `value` „auf vier Nachkommastellen“ gerundet.

  Tests kommen mit T004 in `src/test/test_difficulty_profile.gd`.
- [x] T004 [A] `src/core/timeline/difficulty_profile.gd` (`DifficultyProfile`) laut zeitleiste.md:
  - `level`, `modifiers` „in der Reihenfolge der Datei“, `_init()`, `from_list()`, `to_list()`,
    `to_dict()` als `{ "schwer": to_list() }` (Analyse, U1), `duplicate_profile()`.
  - `from_list()` setzt vor die Felder der Meldungen aus `ChanceModifier.from_dict()`
    `field_prefix()` und davor den Ort aus `place()`. Ein Eintrag, der kein Objekt ist, wird ein
    Start-Modifikator mit den Vorgaben, Feld `profiles.schwer[2]`, damit die Stellen zu den
    Feldern der Meldungen passen.
  - `field_prefix()` ergibt `profiles.schwer[2].`; `place()` ergibt „Profil „Schwer“,
    Start-Modifikator „reklamationswelle““, ohne Kennung „Profil „Schwer“, Start-Modifikator Nr. 3
    ohne Kennung“, „gezählt ab 1“.
  - `faulty_indices(issues, level)`: Stellen mit einer Meldung der Stufe `ERROR`, Feld
    `profiles.<key>[<i>]` oder mit `profiles.<key>[<i>].` am Anfang, nach ganzen Pfadteilen; zu
    `profiles.schwerr` gehört keine Stelle von Schwer (Analyse, U4).
  - `chance_periods()` und `describe_periods()` laut data-model.md, „Chance je Zeitabschnitt“:
    - Grenzen bei 0, je `from_day` und `to_day + 1` und bei 5478, „begrenzt auf 0 bis 1“, gleiche
      Nachbarn zusammengelegt;
    - Texte „8 %“, „3 % bis 31.12.1994, 6 % ab 01.01.1995“ und in der Mitte „5 % vom 01.01.1990 bis
      31.12.1994“, deutsches Komma, höchstens zwei Nachkommastellen;
    - formatiert im Kern wie `ScheduleEntry._percent()`, nie über `EventForm` (Analyse, U11).

  Test `src/test/test_difficulty_profile.gd`, die Liste aus zeitleiste.md:
  - `ChanceModifier.from_dict()` und `to_dict()` als Rundreise; jeder Fall von V22 aus T003, mit
    dem bloßen Schlüssel als Feld.
  - `from_list()` mit Stelle und Ort in den Meldungen, `to_list()`, `to_dict()`, `field_prefix()`,
    `place()` mit und ohne Kennung.
  - `faulty_indices()` für beide Formen des Felds und nicht für `profiles.schwerr`.
  - US2, Szenario 6 (Leicht 1 %, Mittel 3 %, Schwer 8 %) und Szenario 7 (3 % bis 31.12.1994, 6 % ab
    01.01.1995), drei Abschnitte, Begrenzung auf 0 % und 100 %, Fehlerhaftes zählt nicht, Mittel.

  Hängt an T002 und T003.
- [x] T005 [A] `src/core/timeline/event_catalog.gd` laut zeitleiste.md und ereigniskatalog.md:
  - `KEYS` mit `"profiles"`; `profiles` „immer zwei: [0] Leicht, [1] Schwer, auch leer“, angelegt
    in `_init()`; `get_profile()` gibt für Mittel und unbekannte Grade `null`.
  - `to_dict()` als einzige Stelle für die oberste Ebene, den Abschnitt aus
    `DifficultyProfile.to_dict()`; `to_json()` nutzt es.
  - `from_json()` liest den Abschnitt. Fehlt er oder fehlt ein Grad, ist das Profil leer, ohne
    Meldung. V22 kommt bei `"mittel"` und bei einem unbekannten Grad, mit den Texten aus R4 und dem
    Feld `profiles.<schlüssel>`. Ebenso kommt V22 für Abschnitt, Profil und Eintrag mit falschem
    Typ.
  - `duplicate_catalog()` kopiert die Profile.
  - `without_faulty()` lässt Start-Modifikatoren weg, zu deren Stelle eine Meldung der Stufe
    `ERROR` gehört. Ebenso die, deren Ereignis in der Kopie kein Ereignis über Wahrscheinlichkeit
    ist.
  - `skipped_start_modifiers(issues)` liefert genau diese, mit Grad, Stelle, Start-Modifikator, Ort
    und Fehlergrund. `by_event` kennzeichnet die, die ohne eigene Meldung nur wegen ihres
    Ereignisses wegfallen. Beide teilen sich eine Hilfe (Analyse, G1).
  - Jede Umwandlung einer Zahl in `Difficulty.Level` mit `as Difficulty.Level` (Analyse, U3).
  - Fixtures: `src/test/fixtures/catalog_alle_arten.json` bekommt je einen Start-Modifikator in
    Leicht und Schwer. Neu sind `catalog_v22_profil_mittel.json`,
    `catalog_v22_profil_unbekannt.json` und `catalog_v22_profil_wert_text.json` (Analyse, I8).

  Tests in `src/test/test_event_catalog.gd`, die Liste aus zeitleiste.md, mit den drei neuen
  Fixtures und `skipped_start_modifiers()`:
  - Die Rundreise der eingefrorenen Übernahme ergibt sie selbst „mit Komma hinter `"format": 1`
    und den vier Zeilen des leeren Abschnitts“; eine zweite Rundreise ändert nichts.
  - Die Übernahme selbst bleibt Byte für Byte, wie sie ist.

  Danach die Startprobe mit `-d`: still. Hängt an T004.
- [x] T006 [A] Was sonst Tests aus Feature 002 bräche (research.md, R17; Klaus, 2026-10-22,
  CHK036):
  - `src/test/fixtures/catalog_minimal.json` und `src/test/fixtures/catalog_500.json` bekommen nur
    den leeren Abschnitt: Komma hinter `"format": 1`, dazu vier Zeilen. Ihre Ereignisse bleiben, wie
    sie sind.
  - `src/tools/werkstatt/catalog_editor.gd`: Die Sicherungskopie baut ihr `"catalog"` aus
    `catalog.to_dict()` statt aus `_catalog_dict()` (R10).
  - Die ganze Testsuite laufen lassen. Vergleicht ein weiterer Test geschriebenen Text mit einer
    Fixture, die kein eingefrorener Beleg ist, bekommt sie den Abschnitt genauso; der Bericht nennt
    jede.

  Hängt an T005.
- [x] T007 [A] `src/core/timeline/catalog_validator.gd` laut data-model.md, „Prüfregeln“:
  - `validate_profiles()` mit V25 bis V31; `validate()` hängt sie hinter die Kategorien, „Leicht
    vor Schwer, je Profil nach Stelle und je Start-Modifikator nach Regel“.
  - `WARNING_RULES` bekommt `"V31"`.
  - Meldungen haben ein leeres `event_id`, das Feld wie in der Datei und im Text den Ort aus
    `place()` und das volle Feld, etwa „Feld „profiles.schwer[2].reason““ (Analyse, B4).
  - V30 meldet „eine Dublette bei jedem Start-Modifikator mit dieser Kennung“.
  - V31 prüft Beginn und Ende einzeln, mit den Texten aus R8. Liegt im Zeitraum kein Monatserster,
    gibt es nur eine Warnung an `from_day`: Er wirkt nie. Gilt V27 oder V28, prüft V31 nicht
    (Analyse, U7).

  Fixtures unter `src/test/fixtures/`, je Regel eine, die sich wie die übrigen von
  `catalog_minimal.json` in genau einer Stelle unterscheidet:
  `catalog_v25_profil_ereignis_unbekannt.json` bis `catalog_v31_profil_monatsmitte.json`.

  Tests:
  - `src/test/test_catalog_validator.gd`:
    - V25 bis V31 kommen in `FAELLE`. Die Schleife des Tests erwartet bei Feldern `profiles…`
      „Profil „“ statt „Ereignis „“ (Analyse, B4).
    - Randfälle im Code: V26 für alle vier falschen Arten, V30 leer, mit falschen Zeichen und
      doppelt, V31 an Beginn, an Ende, an beiden und „wirkt nie“ (Analyse, G6).
    - Beginn 01.01.1985 und Ende 31.12.1999 ohne Meldung; die Reihenfolge der Meldungen.
  - `src/test/test_large_catalog.gd`: `catalog_500.json` bekommt im Speicher 20
    Start-Modifikatoren je Profil, und die Prüfung bleibt unter 100 ms (Analyse, G9).

  Hängt an T006, denn die neuen Fixtures entstehen aus dem geänderten `catalog_minimal.json`.
- [x] T008 [K] Phase 1 abnehmen nach quickstart.md, Abschnitte 1 und 2. Danach schließt Klaus jede
  ältere Werkstatt, öffnet den echten Katalog in der neuen und speichert einmal mit Cmd+S. So hat
  `src/data/event_catalog.json` den leeren Abschnitt, und Claude committet die Datei mit der Phase
  (R3, CHK037).

**Checkpoint**: Grade, Profile und Prüfregeln stehen, Mittel ist an der Grundlinie festgehalten,
alle Tests aus Feature 002 sind grün. Abnahme durch Klaus, dann Auftrag für Phase 2.

---

## Phase 2: User Story 1 - Ein Spiel startet mit einem Schwierigkeitsgrad (Priority: P1) 🎯 MVP

**Goal**: Ein Spiel startet mit Leicht, Mittel oder Schwer; die Start-Modifikatoren gelten vor der
ersten Würfelrunde, Seed und Grad sind unabhängig, und die Textausgabe nimmt einen Grad.

**Independent Test**: Textausgabe mit Seed 4711 und `catalog_us1_grade.json` zweimal mit Schwer
und einmal mit Mittel; `diff` zeigt nur die Reklamationswelle und ihre Abhängigen
(quickstart.md, Abschnitt 3).

### Implementation for User Story 1

- [x] T009 [A] [US1] `src/core/timeline/timeline_message.gd`: `Kind.START_MODIFIER` am Ende der
  Aufzählung, `KIND_LABELS` bekommt „Grad“; die übrigen Arten behalten ihre Nummern. In
  `src/test/test_timeline_run.gd` bekommt der Test der Zeilen je Art „Grad“ als achte Art in seiner
  Liste (Analyse, B1).
- [x] T010 [A] [US1] `src/core/timeline/timeline_run.gd` laut zeitleiste.md, „Der Lauf“:
  - `difficulty`, `start_modifiers`, `start_refusals`;
    `_init(p_catalog, p_seed, p_difficulty = Difficulty.DEFAULT)`; ein unbekannter Grad „gilt als
    Mittel und steht in start_refusals“.
  - Nach Fahrplan und Würfeln die Start-Modifikatoren des Profils setzen, „bevor begin() zum ersten
    Mal würfelt“. Dabei wie `add_modifier()` prüfen: Ereignis über Wahrscheinlichkeit, Kennung und
    Grund nicht leer, Ende gesetzt und nicht vor dem Beginn, Kennung nicht zweimal im Profil.
  - Je gesetztem Start-Modifikator eine Meldung `START_MODIFIER` mit dem Tag −1 und dem Text aus
    data-model.md. Sie kommt nicht in die Rückgabe von `begin()` und nie nach `interventions`.
  - `chance_info()` mit `"start_modifiers"`; `"sum"` und `"effective"` rechnen sie mit,
    `"modifiers"` bleiben die Eingriffe.
  - `_roll_month()` schreibt die Start-Modifikatoren zuerst in `modifier_notes`, als „Schwer:
    Anspruchsvolle Kunden +5“.
  - `remove_modifier()` gibt `ERR_UNAVAILABLE` mit dem Grund aus R5, wenn nur ein
    Start-Modifikator die Kennung hat. `add_modifier()` prüft doppelte Kennungen nur unter
    `modifiers`.
  - Würfel, Zwecke und Würfe bleiben, wie sie sind; Zahlen werden mit `as Difficulty.Level` zum
    Grad.

  Fixtures laut zeitleiste.md, „Fixtures“ (Analyse, I6 und U6):
  - `src/test/fixtures/catalog_us1_grade.json`, mit einer Folge, die nur als Folge vorkommt, einem
    Ereignis mit Bedingung und einem fixen, einem jährlichen und einem gesetzten Ereignis;
  - `src/test/fixtures/catalog_us1_profil_kaputt.json` mit drei Start-Modifikatoren in Schwer.

  Test `src/test/test_difficulty_run.gd`, die Liste aus zeitleiste.md:
  - US1, Szenarien 1, 3, 4 und 7; SC-001 mit 100 Wiederholungen.
  - SC-002 mit 100 Seeds: Jede Markierung und jeder weggefallene Termin in `removed` gehört zur
    Hülle der abhängigen Ereignisse (data-model.md, „Abhängige Ereignisse“; Analyse, G2).
  - Ein Start-Modifikator vom 15.03.1990 bis 15.06.1994 wirkt erst in der Würfelrunde am
    01.04.1990 und zuletzt in der am 01.06.1994 (Analyse, G3).
  - Gesetzte, fixe und jährliche Termine außerhalb der Hülle sind in allen Graden gleich (FR-003).
  - Der Rest der Liste.

  In `src/test/test_difficulty_baseline.gd` kommt Mittel ausdrücklich dazu, ebenso Schwer mit
  leerem Profil, beide wie die Grundlinie (SC-007). Hängt an T009.
- [x] T011 [A] [P] [US1] `src/core/timeline.gd` (Autoload) laut zeitleiste.md, „Autoload
  `Timeline`“:
  - `start_game(seed = -1, difficulty = Difficulty.DEFAULT)`: Ein Seed über `MAX_SEED` oder ein
    unbekannter Grad ergibt `ERR_INVALID_PARAMETER` und ein `push_error()`; das laufende Spiel
    bleibt (FR-011).
  - `get_difficulty()`, −1 ohne Spiel.
  - `_load_catalog()`:
    - „Das Ereignis wird übersprungen.“ nur bei Meldungen mit einer Kennung eines Ereignisses;
    - „Der Start-Modifikator wird übersprungen.“ bei Meldungen an der Stelle eines
      Start-Modifikators;
    - Start-Modifikatoren, die nur wegen ihres Ereignisses wegfallen, aus
      `skipped_start_modifiers()`, die mit `by_event`; so steht jeder genau einmal da (FR-013;
      Analyse, G1 und U5).
  - `start_game()` meldet `run.start_refusals`; `_send()` macht aus `START_MODIFIER` kein Signal.
  - Ein gültiger Katalog erzeugt keine Ausgabe.

  Tests in `src/test/test_timeline.gd`, die Liste aus zeitleiste.md:
  - Für US1, Szenario 2 setzt der Test den globalen Zufall mit `seed()` fest (CHK027).
  - Mit `catalog_us1_profil_kaputt.json` werden beide Start-Modifikatoren übersprungen und genannt,
    der dritte gilt.

  Danach die Startprobe mit `-d`: still (Analyse, U3). Hängt an T010.
- [x] T012 [A] [P] [US1] Kopfzeile und Textausgabe:
  - `src/core/timeline/schedule_text.gd`: Kopfzeile „# Seed 4711, Grad Schwer, bis 31.12.1999“,
    auch mit „Grad Mittel“.
  - `src/tools/werkstatt/fahrplan_ausgabe.gd`: `--grad leicht|mittel|schwer`, Vorgabe `mittel`.
    - Ein anderer oder fehlender Wert ist ein falsches Argument: Meldung und Aufrufhilfe mit
      `--grad` auf stderr, Exit-Code 1.
    - Fehler in Profilen stehen über die vorhandene Schleife auf stderr, Exit-Code 1. Eine
      Meldung an der Stelle eines Start-Modifikators bekommt „Der Start-Modifikator fehlt in der
      Ausgabe.“
    - Start-Modifikatoren, die nur wegen ihres Ereignisses wegfallen, nennt die Textausgabe dazu
      aus `skipped_start_modifiers()`, die mit `by_event`. So steht jeder genau einmal auf stderr
      (FR-013; Analyse, G1).

  Tests in `src/test/test_schedule_text.gd`: die drei Erwartungen an die Kopfzeile mit „Grad
  Mittel“, dazu eine mit „Grad Schwer“. Hängt an T010.
- [x] T013 [K] [US1] Phase 2 abnehmen nach quickstart.md, Abschnitte 1, 2 und 3

**Checkpoint**: Ein Spiel startet mit einem Grad, wiederholbar und nur dort anders, wo das Profil
wirkt. Abnahme durch Klaus, dann Auftrag für Phase 3.

---

## Phase 3: User Story 2 - Profile in der Werkstatt anlegen und pflegen (Priority: P1)

**Goal**: Klaus pflegt die Profile im Reiter „Schwierigkeitsgrade“ und liest die Chance je Grad im
Formular. Gespeichert und rückgängig gemacht wird wie beim Katalog.

**Independent Test**: In einem leeren Profil drei Start-Modifikatoren anlegen, speichern, die
Werkstatt schließen und wieder öffnen; alle drei stehen da, und die Textausgabe mit diesem Grad
nutzt sie (quickstart.md, Abschnitt 4.1, Zeile mit der Textausgabe).

Die Phase hat zwei Teile: erst der Kern (T014), dann die Oberfläche (T016 bis T018). Dazwischen
prüft Claude (T015). Am Ende prüft Klaus erst auf einer Kopie mit leeren Profilen (T019), dann legt
er die echten an (T020).

### Implementation for User Story 2

- [x] T014 [A] [US2] Teil 1: `src/tools/werkstatt/catalog_editor.gd` laut werkstatt.md,
  „CatalogEditor“:
  - `add_start_modifier()`, `duplicate_start_modifier()`, `delete_start_modifier()`,
    `set_start_modifier_field()`, `profile_references_to()`.
  - Vorgaben für „Neu“ aus data-model.md: Ereignis wie übergeben, sonst das erste über
    Wahrscheinlichkeit nach Kennung; „`value` = 0.0“; das ganze Spiel; Grund leer; Kennung aus der
    Kennung des Ereignisses, im Profil eindeutig wie `reklamationswelle_2`.
  - **Ganze Profile ersetzen** (R10): Jede Änderung ersetzt das betroffene `DifficultyProfile`
    durch eine Kopie aus `duplicate_profile()`, Schritt `[&"replace", altes_profil,
    neues_profil]` in `catalog.profiles`. `_run()` wählt diese Liste.
  - `delete_event()` entfernt die Start-Modifikatoren auf das Ereignis im selben Schritt;
    `rename_event()` zieht sie still nach (R9).
  - `content_key()` nimmt die Profile über `_text_of()` und `DifficultyProfile.to_dict()` auf
    (Analyse, U1); `set_event_kind()` lässt Start-Modifikatoren stehen.
  - **Lesemeldungen eines Profils:** Ersetzt ein Schritt in `_run()` ein Profil, auch beim
    Rückgängigmachen, verwirft der Editor dessen Meldungen V22 aus `_read_issues`, nach ganzen
    Pfadteilen. Rückgängig bringt sie nicht zurück; Meldungen zu anderen Profilen und zu
    Ereignissen bleiben bis zum Speichern (werkstatt.md; Analyse, U2).
  - Jede Aktion hat einen Namen wie „Wert von Schwer: reklamationswelle“.

  Tests in `src/test/test_catalog_editor.gd`, die Liste aus werkstatt.md:
  - SC-006: ein Wert, eine geänderte Zeile;
  - Rückgängig nach dem Löschen eines Ereignisses, auf das zwei Start-Modifikatoren in Schwer
    zeigen, ein dritter dazwischen auf ein anderes;
  - die Vorgaben von „Neu“ (G5), Duplizieren und Art ändern (G7);
  - die Lesemeldungen eines Profils mit `catalog_v22_profil_wert_text.json` (U2).

  In `src/test/test_large_catalog.gd` bleibt eine Änderung über `set_start_modifier_field()` samt
  Prüfung mit 20 Start-Modifikatoren je Profil unter 100 ms (G9). Dazu die Fehlerprobe: In einer
  Kopie baut der Agent Fehler ein und zeigt, dass die Tests sie finden (Analyse, I9).
- [x] T015 [C] [US2] Teil 1 prüfen, bevor die Oberfläche beginnt: Tests zweimal, die Fehlerprobe
  des Agents, Verlauf, verworfene Lesemeldungen und Sicherungskopie an den kritischen Stellen im
  Code lesen. Hängt an T014.
- [x] T016 [A] [P] [US2] Teil 2: `src/tools/werkstatt/difficulty_panel.tscn` und
  `src/tools/werkstatt/difficulty_panel.gd` (`DifficultyPanel`), Aufbau und Verhalten laut
  werkstatt.md:
  - `%DifficultyOption` mit Vorgabe Leicht, `show_difficulty()`, `shown_difficulty()` (Analyse,
    I2); `%CountLabel` und `%MittelNote` mit Umbruch;
  - `%Split` mit `%Table` und den Knöpfen links, `%Fields` rechts;
  - Felder entstehen einmal und übernehmen ihren Wert mit Enter und beim Verlassen. Mit dem Fokus
    im Feld gehört Cmd+Z dem Feld; zeigt es noch den übernommenen Wert, schluckt das Panel die
    Taste, wie das Formular (Analyse, U10). Der Wert steht mit dem einfachen Minus da, etwa
    „-2,5“, und wird mit `EventForm.parse_percent()` gelesen.
  - `%EventOption` mit `fit_to_longest_item = false` und `clip_text`; ohne `editor` tut
    `refresh()` nichts (Analyse, U10);
  - Fehlerkontur und Hinweis bei Fehlern; bei V31 nur der Hinweis in der Warnfarbe; Zeichen „!“
    bzw. „?“ in der Zeile;
  - „Neu“, „Duplizieren“, „Löschen“ und `focus_field()`.

  Test `src/test/test_difficulty_panel.gd`, die Liste aus werkstatt.md. Den Platz belegt T017,
  denn erst dann steht der Reiter im Fenster. Hängt an T015.
- [x] T017 [A] [US2] Verdrahtung in `src/tools/werkstatt/werkstatt.tscn`,
  `src/tools/werkstatt/werkstatt.gd` und `src/tools/werkstatt/issues_panel.gd`:
  - der vierte Reiter „Schwierigkeitsgrade“ und `editor`;
  - `refresh()` nach `catalog_changed` und `issues_changed`; `selected_event_id` nach
    `selection_changed`;
  - eine Meldung mit Feld `profiles…` wechselt in den Reiter und ruft `focus_field()` auf;
  - der Löschdialog nennt die Start-Modifikatoren, mit dem Text für den Fall ohne Ereignisverweise
    (Analyse, I3);
  - die Prüfung zeigt „Profil Leicht“, „Profil Schwer“ oder „Profile“ in der Spalte „Ereignis“,
    nach dem zweiten Pfadteil des Felds (Analyse, U4).

  Tests:
  - `src/test/test_werkstatt_scene.gd`: vierter Reiter, Sprung zum Feld, Löschdialog, Spalte
    „Ereignis“; die Erwartungen an `%DateLabel` bleiben.
  - `src/test/test_werkstatt_settings.gd`: `…/Tabs/DifficultyPanel/Split` am Ende der Liste der
    Teiler, sieben statt sechs gespeicherte Teiler; die Mindestgröße auch im neuen Reiter, elf statt
    acht geprüfte Bereiche (Analyse, B3).

  Platz: Bei 1920 × 925 zeigt der Reiter in der Vorgabe-Teilung mindestens vier Zeilen der Tabelle
  und alle Felder ohne Rollen. Belegt wird das mit einem Bildschirmfoto aus dem echten Fenster, auf
  einer Kopie des echten Katalogs mit mindestens vier Start-Modifikatoren in einem Profil (CHK028;
  Analyse, G10). Hängt an T016.
- [x] T018 [A] [P] [US2] `src/tools/werkstatt/event_form.gd`: Zeile „Je Grad“ bei Ereignissen über
  Wahrscheinlichkeit laut werkstatt.md, „EventForm“:
  - drei Zeilen in `MutedLabel` aus `DifficultyProfile.describe_periods()`;
  - Fehlerhaftes über `faulty_indices(editor.issues(), level)` ausgelassen;
  - der Hinweis „Ändern im Reiter „Schwierigkeitsgrade““; die Zeile bricht um;
  - bei anderen Arten keine Zeile.

  Ein Bildschirmfoto bei 1920 × 925 zeigt die Zeile mit mehreren Zeitabschnitten ohne
  waagerechtes Rollen (Analyse, G10). Tests in `src/test/test_event_form.gd`: US2, Szenarien 6 und
  7, keine Zeile bei anderen Arten, Fehlerhaftes zählt nicht, aktuell nach einer Änderung im
  Profil. Gut als `[K]`-Aufgabe (plan.md, „Was Klaus dabei lernt“). Hängt an T015.
- [x] T019 [K] [US2] Prüfen nach quickstart.md, Abschnitt 4.1, auf einer Kopie des echten
  Katalogs, die entsteht, solange seine Profile noch leer sind (Analyse, I1). Darin liegt SC-005
  (ein frisches Profil mit drei Start-Modifikatoren in unter 5 Minuten) und SC-006. Hängt an T017
  und T018.
- [x] T020 [K] [US2] Profile im echten Katalog anlegen: In der Werkstatt bekommen Leicht und Schwer
  je mindestens einen Start-Modifikator, Ausgangspunkt ist der Vorschlag in research.md, R18; dann
  speichern. Hängt an T019.
- [x] T021 [A] [US2] `src/test/test_shipped_catalog.gd`: ein Test, dass Leicht und Schwer im
  echten Katalog nicht leer sind; Werte prüft er nicht (FR-014, CHK008). Hängt an T020.
- [x] T022 [K] [US2] Phase 3 abnehmen: quickstart.md, Abschnitte 1 und 2, mit dem echten Katalog
  samt Profilen und dem Test aus T021

**Checkpoint**: Klaus pflegt Profile ohne Datei, der echte Katalog hat gefüllte Profile. Abnahme
durch Klaus, dann Auftrag für Phase 4.

---

## Phase 4: User Story 3 - Grade im Simulator durchspielen (Priority: P2)

**Goal**: Der Simulator spielt einen Seed mit einem Grad, baut beim Wechsel neu, vergleicht
umschaltbar mit Mittel, und Proben merken sich den Grad.

**Independent Test**: Seed 4711 mit Schwer bis zum Ende, Vergleich auf Mittel umstellen; das
Protokoll nennt die Start-Modifikatoren, markiert sind nur veränderte und abhängige Termine
(quickstart.md, Abschnitt 4.2).

### Implementation for User Story 3

- [x] T023 [A] [US3] `src/tools/werkstatt/what_if_probe.gd` laut werkstatt.md, „WhatIfProbe“:
  - `difficulty` mit Vorgabe Mittel;
  - `write_file()` schreibt `"difficulty"` immer, auch bei Mittel;
  - `read_file()`: Fehlt der Schlüssel, gilt Mittel. Ist er kein Text oder ein unbekannter Grad,
    gibt es `null` und den Fehlertext aus dem Vertrag;
  - `from_run()` übernimmt den Grad, `build_run()` legt den Lauf mit ihm an.

  Tests in `src/test/test_what_if_probe.gd`: die Liste aus werkstatt.md. Der Vergleich der ganzen
  Datei erwartet `"difficulty": "mittel"` als ersten Schlüssel.
- [x] T024 [C] [US3] Den Kern aus T023 prüfen, bevor die Oberfläche beginnt (`docs/ki_dev.md`,
  „Ablauf je Feature“, Punkt 4; Analyse, I9). Hängt an T023.
- [x] T025 [A] [US3] `src/tools/werkstatt/simulator_panel.tscn` und
  `src/tools/werkstatt/simulator_panel.gd`, Grad und Neubau laut werkstatt.md:
  - `%DifficultyOption` hinter „Würfeln“, Vorgabe Mittel; `selected_difficulty()` und
    `select_difficulty()`;
  - „Fahrplan erzeugen“ mit dem Grad;
  - `restart()` setzt vor `probe.build_run()` `probe.difficulty = run.difficulty`;
  - der Wechsel des Grads baut aus einer kurzlebigen `WhatIfProbe`: `run.seed`, der neue Grad,
    `run.interventions`, bis `run.today`, mit `build_run(_effective_catalog())`. Nicht
    anwendbare Eingriffe nennt `%ProbeNotice`;
  - Proben speichern und laden den Grad, die Liste beim Laden bekommt die Spalte „Grad“;
  - `_fill_modifiers()` zeigt die Start-Modifikatoren mit dem Grad vor dem Grund, ohne eigene Farbe
    (Analyse, U10). „Entfernen“ ist dafür gesperrt, mit dem Hinweis aus dem Vertrag (Analyse, I4);
    `_chance_text()` nennt den Anteil des Grads;
  - `%ExcludedNotice` nennt die Start-Modifikatoren aus `skipped_start_modifiers()` mit dem Ort
    aus `place()` (Analyse, G1); `%DateLabel` bleibt.

  Ein Bildschirmfoto bei 1920 × 925 zeigt `%RunBar` mit der neuen Auswahl (Analyse, G10). Tests in
  `src/test/test_simulator.gd`, mit `catalog_us1_grade.json`:
  - US3, Szenarien 1 bis 4, die Proben und die Modifikatoren aus der Liste in werkstatt.md;
  - die bisherige Erwartung an die Liste der Proben mit fünf Spalten und „Mittel“ (Analyse, B2);
  - `%ExcludedNotice` mit beiden Arten weggelassener Start-Modifikatoren (G1);
  - „Katalog geändert“ nach einer Änderung an einem Profil und der Wechsel des Grads danach (G4).

  Hängt an T024.
- [x] T026 [A] [US3] Vergleich umschaltbar in `src/tools/werkstatt/simulator_panel.tscn` und
  `src/tools/werkstatt/simulator_panel.gd`:
  - `%CompareMittel` „mit Mittel vergleichen“ und `%CompareLabel` „Vergleich: Schwer ohne
    Eingriffe“, „Vergleich: Mittel ohne Eingriffe“ oder „Kein Vergleich: Der Lauf hat keine
    Eingriffe.“ (Analyse, A3);
  - `_update_diff()` mit Mittel oder `run.difficulty`. Gerechnet wird mit Eingriffen oder mit
    Häkchen bei einem anderen Grad als Mittel;
  - beim Vergleich mit demselben Grad, auch bei Mittel mit Häkchen, bleiben die Texte wie in
    Feature 002; beim Vergleich mit Mittel gilt die zweite Reihe von Texten samt `%DiffFilter`;
  - die FilterBar wird nicht breiter als bisher in der kleinen Fenstergröße aus
    `test_werkstatt_settings.gd`; `%CompareLabel` kürzt mit „…“ (Analyse, G10).

  Bildschirmfotos der Leiste bei 1920 × 925 und in dieser kleinen Größe. Tests in
  `src/test/test_simulator.gd`:
  - US3, Szenarien 5 und 6;
  - Mittel mit Häkchen ändert nichts;
  - die Texte beim Vergleich mit demselben Grad wie bisher;
  - der Text ohne Vergleichslauf.

  Gut als `[K]`-Aufgabe (plan.md). Hängt an T025.
- [x] T027 [K] [US3] Phase 4 abnehmen nach quickstart.md, Abschnitte 1 und 4.2

**Checkpoint**: Grade lassen sich im Simulator durchspielen und vergleichen. Abnahme durch Klaus,
dann Auftrag für Phase 5.

---

## Phase 5: User Story 4 - Grade in der Statistik vergleichen (Priority: P2)

**Goal**: Die Statistik rechnet einen Grad oder alle drei mit denselben Seeds und zeigt die Werte
nebeneinander.

**Independent Test**: `catalog_us1_grade.json` mit 1.000 Spielen: Mittelwert der Reklamationswelle
bei Mittel zwischen 4,9 und 5,9, bei Schwer zwischen 13,4 und 15,4 (SC-003).

### Implementation for User Story 4

- [ ] T028 [A] [US4] `src/core/timeline/timeline_statistics.gd` laut zeitleiste.md, „Statistik“:
  - `difficulties: Array[int]`, „leer heißt nur Mittel“;
  - ein Spiel ist ein Seed, gespielt in jedem Grad der Liste mit denselben Eingriffen. Gezählt
    wird er erst, wenn alle Grade fertig sind, und ein Abbruch verwirft ihn in allen;
  - `results()` liefert den ersten Grad, `results_for(level)` einen bestimmten. `accepted` und
    `refused` kommen aus dem ersten Seed im ersten Grad;
  - mit nur Mittel genau wie in Feature 002.

  Tests in `src/test/test_timeline_statistics.gd`: SC-003, US4, Szenarien 2 bis 4, ein Abbruch
  mitten im Seed lässt alle Grade gleich, `results_for()`.
- [ ] T029 [C] [US4] Den Kern aus T028 prüfen, bevor die Oberfläche beginnt (`docs/ki_dev.md`,
  „Ablauf je Feature“, Punkt 4; Analyse, I9). Hängt an T028.
- [ ] T030 [A] [US4] `src/tools/werkstatt/statistics_panel.tscn` und
  `src/tools/werkstatt/statistics_panel.gd` laut werkstatt.md, „Statistik“:
  - `%DifficultyOption` mit Leicht, Mittel, Schwer und „Alle drei vergleichen“, Vorgabe Mittel;
    `difficulties` immer als `Array[int]` (Analyse, I2);
  - die Texte nennen den Grad, auch Mittel; beim Vergleich steht „je Grad“;
  - die Vergleichstabelle hat zehn Spalten mit Hinweisen. Der Bereich der Verteilung auf die Jahre
    bleibt mit seiner Mindesthöhe stehen und zeigt den Text (Analyse, U10);
  - `%ExcludedNotice` nennt die Start-Modifikatoren aus `skipped_start_modifiers()` (Analyse, G1).

  Platz: Bei 1920 × 925 passen in der Vorgabe-Teilung alle zehn Spalten ohne waagerechtes Rollen,
  belegt mit einem Bildschirmfoto (CHK028). Tests in `src/test/test_statistics_panel.gd`:
  - die Liste aus werkstatt.md, mit der geänderten Erwartung „…, Seeds 1 bis 200, Mittel, ohne
    Eingriffe“;
  - „Katalog geändert“ nach einer Änderung an einem Profil (Analyse, G4);
  - `%ExcludedNotice` mit beiden Arten weggelassener Start-Modifikatoren (G1).

  Hängt an T029.
- [ ] T031 [K] [US4] Phase 5 abnehmen nach quickstart.md, Abschnitte 1 und 4.3, darin SC-004

**Checkpoint**: Alle vier User Stories sind erfüllt. Abnahme durch Klaus, dann Auftrag für die
letzte Phase.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Doku, Lückensuche, Gesamtprüfung, Abnahme

- [ ] T032 [C] Doku nachziehen (CHK021, CHK038):
  - `CLAUDE.md`: In der Tabelle „Aufbau“ nennt `src/core/timeline/` die Schwierigkeitsgrade, und
    der Absatz zur Timeline sagt „je Spiel, Seed und Grad“. Claude schlägt den Wortlaut vor;
    eingetragen wird er erst mit Klaus' OK.
  - `docs/features/Features.md`: Stand von Feature 003.
  - `docs/features/Feature_Ideas.md`:
    - 01-05 heißt „Neues Spiel: Startdatum, Seed und Grad“. Seed und Grad übergibt es mit
      `Timeline.start_game(seed, difficulty)`, für das Startdatum braucht es eine eigene
      Erweiterung (R19);
    - 11-05 sagt, dass die Grade der Zeitleiste mit Feature 003 gebaut sind;
    - 11-01 sagt, dass Spielstände den Grad speichern.
  - `docs/game_design.md`: die offene Frage „Schwierigkeitsgrade?“ nur mit Klaus' OK.
- [ ] T033 [C] Lückensuche mit `/speckit-converge` über das ganze Feature (`docs/ki_dev.md`,
  „Ablauf je Feature“, Punkt 6). Die Lernnotizen aller Phasen stehen vollständig in
  `specs/003-schwierigkeitsgrade/lernnotizen.md`. Gefundene Lücken werden eine eigene Phase mit
  Klaus' Freigabe, die vor T034 fertig ist.
- [ ] T034 [K] Quickstart vollständig durchgehen, Abschnitte 1 bis 5, dazu den Quickstart von
  Feature 002 mit den zwei bekannten Ausnahmen (quickstart.md, Einleitung). Für 4.1 braucht es
  eine Kopie mit geleerten Profilen, für 4.2 und 4.3 eine mit den echten (quickstart.md,
  Voraussetzungen). Hängt an T033 und an der Phase für Lücken, falls es eine gibt (Analyse, I9).
- [ ] T035 [K] Feature abnehmen: Die Abnahmen T008, T013, T022, T027, T031 und T034 sind erledigt,
  Leicht und Schwer im echten Katalog sind gefüllt. Dann entscheidet Klaus über den Merge nach
  `main`.

---

## Abdeckung der Anforderungen

| Anforderung | Tasks |
|---|---|
| FR-001 drei Grade | T002 |
| FR-002 Profil und Start-Modifikator | T003, T004, T005, T014 |
| FR-003 nur Chancen | T007, T010 |
| FR-004 Mittel ist der Katalog | T001, T002, T005, T010, T016 |
| FR-005 Abschnitt in der Katalogdatei | T005, T006, T008, T014 |
| FR-006 Grad beim Start, Vorgabe Mittel | T010, T011, T012 |
| FR-007 vor der ersten Würfelrunde, Summe, Monatserste | T010 |
| FR-008 Seed unabhängig vom Grad | T010, T011 |
| FR-009 nur Abhängige anders | T010 |
| FR-010 Protokoll, nicht entfernbar | T009, T010, T025 |
| FR-011 unbekannter Grad | T002, T005, T010, T011, T012, T023 |
| FR-012 Prüfregeln, Warnung V31 | T003, T004, T005, T007, T010, T016 |
| FR-013 überspringen und melden | T005, T011, T012, T025, T030 |
| FR-014 Tests am echten Katalog | T007, T021 |
| FR-015 Reiter, Anzeige je Grad | T004, T014, T016, T017, T018 |
| FR-016 Prüfen, Speichern, Rückgängig, Sicherung | T006, T014, T016, T017 |
| FR-017 Verweise beim Löschen und Umbenennen | T014, T017 |
| FR-018 Simulator mit Grad und Vergleich | T025, T026 |
| FR-019 Proben mit Grad | T023, T025 |
| FR-020 Statistik mit Graden | T028, T030 |
| FR-021 Textausgabe mit Grad | T012 |
| SC-001 | T010 |
| SC-002 | T010 |
| SC-003 | T028 |
| SC-004 | T031 |
| SC-005 | T019 |
| SC-006 | T014, T019 |
| SC-007 | T001, T010, T013 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1:** T001 kommt vor jeder Änderung am Code.
  - Danach laufen T002 und T003 parallel; T004 braucht beide, T005 braucht T004.
  - T006 braucht T005, T007 braucht T006.
  - T008 schließt die Phase ab.
- **US1 (Phase 2):** braucht Phase 1.
  - T010 braucht T009.
  - T011 und T012 brauchen T010 und laufen parallel.
- **US2 (Phase 3):** braucht Phase 1; die Textausgabe für ihren unabhängigen Test kommt aus
  Phase 2.
  - T015 braucht T014; T016 und T018 brauchen T015 und laufen parallel; T017 braucht T016.
  - T019 braucht T017 und T018, T020 braucht T019, T021 braucht T020, T022 schließt ab.
- **US3 (Phase 4):** braucht Phase 2 für den Lauf mit Grad und Phase 3 für die Profile im echten
  Katalog. T024 braucht T023, T025 braucht T024, T026 braucht T025.
- **US4 (Phase 5):** braucht Phase 2; das Häkchen „aus dem Simulator“ nutzt die Proben aus
  Phase 4. T029 braucht T028, T030 braucht T029.
- **Polish (Phase 6):** braucht alle User Stories. T034 kommt nach T033 und einer Phase für Lücken.

Umgesetzt wird trotzdem in der Reihenfolge der Phasen, eine nach der anderen (plan.md).

### User Story Dependencies

- **US1** ist der Kern und kommt zuerst; **US2** folgt direkt danach. Zusammen sind sie das MVP,
  beide P1.
- **US3** baut auf dem Lauf aus US1 und den Profilen aus US2 auf.
- **US4** braucht den Lauf aus US1.
- `simulator_panel.gd` ändern T025 und T026, `test_simulator.gd` ebenso; die beiden laufen
  nacheinander.

### Within Each User Story

- Erst Klassen und Logik, dann Tests, dann die Oberfläche, dann die Abnahme durch Klaus.
- Zwischen Kern und Oberfläche prüft Claude: T015, T024 und T029.
- Eine Phase gilt erst als fertig, wenn Claude das Ergebnis des Agents geprüft und Klaus es
  abgenommen hat.

### Parallel Opportunities

- Phase 1: T002 und T003 parallel.
- Phase 2: T011 und T012 parallel nach T010.
- Phase 3: T016 und T018 parallel nach T015.

---

## Parallel Example: User Story 1

```text
# Nach dem Lauf (T010) baut der Agent Autoload und Textausgabe gleichzeitig:
Task: "T011 [A] Timeline.start_game() mit Grad in src/core/timeline.gd"
Task: "T012 [A] Kopfzeile und --grad in src/core/timeline/schedule_text.gd und src/tools/werkstatt/fahrplan_ausgabe.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 und 2)

1. Phase 1: Setup und Grundlage, mit der Grundlinie zuerst. Das blockiert alles.
2. Phase 2: US1. **Halt und prüfen:** Mittel ist bytegleich, Schwer wirkt nur, wo sein Profil
   wirkt (T013).
3. Phase 3: US2. **Halt und prüfen:** Klaus pflegt Profile ohne Datei, der echte Katalog hat sie
   (T022).

### Incremental Delivery

1. Setup und Grundlage: Grade, Profile und Prüfregeln stehen.
2. US1: Ein Spiel startet mit Grad.
3. US2: Die Werkstatt pflegt die Profile.
4. US3: Grade im Simulator.
5. US4: Grade in der Statistik.
6. Jede Phase einzeln von Klaus beauftragt und abgenommen.

### Arbeitsteilung

- Claude beauftragt den Agent je Phase mit den `[A]`-Tasks und prüft sein Ergebnis gegen Verträge
  und Verfassung. Dann bekommt Klaus Diff, Erklärung und Lernnotiz.
- `[K]`-Tasks erledigt Klaus selbst. Vor jeder Phase kann er sich `[A]`-Tasks nehmen, die er selbst
  bauen will. Gute Kandidaten sind T018 (Zeile „Je Grad“ im Formular) und T026 (Vergleich im
  Simulator umschaltbar).
- `[C]`-Tasks erledigt Claude.
- Committet wird nach Klaus' Abnahme einer Phase, auf `feature/003-schwierigkeitsgrade`.

---

## Notes

- Format: Task-ID, Besitzer, `[P]` für parallel ausführbar, `[Story]` für die User Story.
- Die Verfassung verlangt kein testgetriebenes Vorgehen; Tests entstehen mit der Logik und müssen
  vor der Abnahme grün sein.
- Zu jeder umgesetzten Task gibt es eine Lernnotiz in `specs/003-schwierigkeitsgrade/lernnotizen.md`
  (Verfassung, Grundsatz II). Bei `[A]`-Tasks schreibt sie der Agent, und Claude trägt sie nach
  jeder Phase ein. Baut Klaus eine Task selbst, schreibt Claude die Notiz beim Review (Analyse, K2).
- Nach dem Anlegen von Skripten ruft der Agent einmal `Godot --headless --path src --import` auf.
  Erst dabei bekommen neue Skripte ihre `.uid`, und Godot lernt neue `class_name` kennen; ohne das
  scheitern Tests an unbekannten Klassen. Neue `.uid`-Dateien werden committet.
- **Feste Größen** für jeden Auftrag an den Agent:
  - Mit Mittel bleiben Fahrplan und Protokoll Zeichen für Zeichen wie die Grundlinie aus T001,
    für die Seeds 1, 4711 und 99999 (SC-007).
  - Die eingefrorene Übernahme `src/test/fixtures/event_catalog_uebernahme.json` ändert sich nie.
  - Die Startprobe mit `-d` bleibt still.
- Den echten Katalog `src/data/event_catalog.json` fasst der Agent nicht an. Klaus speichert ihn
  in T008 und füllt die Profile in T020; Tests vergleichen nur mit Fixtures, Bildschirmfotos
  entstehen auf Kopien.
- Neue Bausteine im Look gibt es nicht. Braucht der Agent doch einen, hält er an und fragt
  (Grundsatz IV, CHK023).
