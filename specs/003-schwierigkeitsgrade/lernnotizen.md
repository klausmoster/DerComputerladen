# Lernnotizen: Schwierigkeitsgrade der Zeitleiste

Zu jeder umgesetzten Task die Godot-Konzepte und warum es so gebaut ist, an den Stellen im
Projekt. Bei `[A]`-Tasks schreibt der Agent die Notizen, Claude trägt sie je Phase hier ein; baut
Klaus eine Task selbst, schreibt Claude die Notiz beim Review.

## Phase 1

### T001 Grundlinie zuerst

- `src/test/test_difficulty_baseline.gd` vergleicht Fahrplan und Protokoll der eingefrorenen
  Übernahme für die Seeds 1, 4711 und 99999 Zeichen für Zeichen mit
  `src/test/fixtures/fahrplan_uebernahme_seed_<n>.txt` und `protokoll_uebernahme_seed_<n>.txt`.
- Die Fixtures entstanden mit der Textausgabe, bevor sich Code änderte. Nur so belegen sie den
  Stand von Feature 002; nach dem Umbau könnte kein Code mehr sagen, was vorher herauskam.
- Die Kopfzeile „# Seed …“ fehlt im Fahrplan, weil sie mit FR-021 gewollt den Grad nennen wird.
  `--no-header` vor `-s` unterdrückt dagegen nur die Kopfzeile der Engine.
- `use_parameters(SEEDS)` macht aus einem Test drei Fälle, wie `FAELLE` im Test der Prüfregeln.

### T002 `Difficulty`

- **Aufzählung als Typ, zur Laufzeit eine Zahl** (`src/core/timeline/difficulty.gd`):
  `Difficulty.Level` gibt Parametern einen Typ, aber eine 7 kommt trotzdem durch. Deshalb nehmen
  `key()`, `label()` und `is_valid()` ein `int`, und wer einen Grad von außen bekommt, prüft ihn
  mit `is_valid()`.
- Wo eine Zahl zum Grad wird, steht `as Difficulty.Level`, etwa in `EventCatalog._init()` und
  `from_json()`. Ohne die Umwandlung warnt Godot mit `-d`, und die Startprobe wäre nicht still.
- Die Namen stehen als private Konstanten `_KEYS` und `_LABELS` nur in dieser Klasse; außen gibt
  es nur `key()` und `label()`.

### T003 und T004 `ChanceModifier` und `DifficultyProfile`

- **Meldungen in Schichten:** `ChanceModifier.from_dict()` kennt beim Lesen nur den Schlüssel,
  etwa `value`. Erst `DifficultyProfile.from_list()` kennt die Stelle und setzt mit
  `CatalogIssue.prefix_fields()` `profiles.schwer[1].` davor, mit `locate()` den Ort. So muss keine
  Datenklasse wissen, wo sie in der Datei steht.
- **Leeres `event_id`:** Meldungen zu Profilen tragen keine Ereigniskennung. Sonst nähme
  `without_faulty()` wegen eines Tippfehlers im Profil die Reklamationswelle aus dem Spiel; welcher
  Start-Modifikator betroffen ist, steht im Feld.
- **Ganze Pfadteile** (`faulty_indices()`): Verglichen wird mit dem Anfang `profiles.schwer[`, also
  mit Klammer. Dadurch gehört `profiles.schwerr[1]` nicht zu Schwer.
- `chance_periods()` legt gleiche Nachbarn mit `is_equal_approx()` zusammen, denn
  0,03 + 0,01 − 0,01 ist als Kommazahl nicht genau 0,03.

### T005 Profile im `EventCatalog`

- **Freiwilliger Abschnitt ohne neue Formatnummer** (`_read_profile_lists()`): Fehlt `profiles`,
  kehrt die Funktion ohne Meldung zurück, und die Profile aus `_init()` bleiben leer. Geschrieben
  wird der Abschnitt immer. `JSON.stringify(…, "\t", true)` sortiert die Schlüssel, deshalb landet
  `profiles` von selbst hinter `format`.
- **Zwei Funktionen, eine Regel** (`_start_modifier_skips()`, `_first_error_at()`):
  `without_faulty()` und `skipped_start_modifiers()` teilen sich eine Hilfe, und auch der Fehlertext
  wird über `faulty_indices()` gefunden. So steht die Regel „gehört zu dieser Stelle“ nur einmal im
  Code und kann nicht auseinanderlaufen.

### T006 Eine Stelle für die oberste Ebene

- `EventCatalog.to_dict()` baut jetzt die ganze Datei; `to_json()` und die Sicherungskopie der
  Werkstatt nutzen es. Vorher baute die Sicherung ihr Dictionary selbst (`_catalog_dict()`), und
  ihr hätten die Profile still gefehlt. Genau das zeigte der rote Test der Sicherung nach T005.
- Die Sicherung speichert ein Dictionary statt Text, weil `JSON.parse_string()` aus jeder ganzen
  Zahl eine Kommazahl machte (14 → 14.0).
- Nach T005 schlugen genau die Tests fehl, die geschriebenen Text mit `catalog_minimal.json` oder
  `catalog_500.json` vergleichen. Beide Fixtures haben jetzt den leeren Abschnitt.

### T007 Prüfregeln V25 bis V31

- `validate_profiles()` hängt die Regeln der Profile hinter die Kategorien. Jede Meldung bekommt
  Stelle und Ort erst dort, wie in T004; die Regeln selbst prüfen nur einen Start-Modifikator.
- V31 ist eine Warnung: Sie nimmt nichts aus, sie erklärt nur, ab welcher Würfelrunde ein Beginn
  mitten im Monat wirkt. Gilt schon V27 oder V28, schweigt sie, denn dann gibt es keine sinnvolle
  Würfelrunde.
- **Fehlerprobe:** Zwölf absichtlich eingebaute Fehler in einer Kopie; elf fanden die Tests
  sofort. Der zwölfte, ein Zeitraum aus genau einem Monatsersten, galt fälschlich als „wirkt nie“;
  dafür gibt es jetzt
  `test_v31_zeitraum_mit_genau_einem_monatsersten_wirkt_in_dieser_wuerfelrunde`.

## Phase 2

### T009 und T010 Meldung „Grad“ und der Lauf mit Grad

- **Ein optionaler Parameter hält alte Aufrufe gültig** (`TimelineRun._init()`):
  `p_difficulty: Difficulty.Level = Difficulty.DEFAULT` heißt, dass `TimelineRun.new(catalog,
  seed)` weiter Mittel ist. Simulator, Statistik und Proben laufen deshalb unverändert, bis sie in
  späteren Phasen ihren Grad bekommen.
- **Eine Aufzählung ist zur Laufzeit eine Zahl:** Der typisierte Parameter nimmt trotzdem eine 7
  an. Deshalb prüft `_init()` mit `Difficulty.is_valid()`; ein unbekannter Grad gilt als Mittel und
  steht in `start_refusals`.
- **Zwei Listen statt einer Markierung** (R5): `start_modifiers` steht neben `modifiers`.
  `remove_modifier()` und die Prüfung auf doppelte Kennungen sehen nur `modifiers`. Dass sich ein
  Start-Modifikator nicht entfernen lässt, folgt aus dem Aufbau und braucht keine Namensregel.
- **Protokoll statt Rückgabe, also kein Signal:** `_set_start_modifiers()` hängt die Meldung
  „Grad“ nur an `protocol`, nie an die Liste, die `begin()` zurückgibt. Das Autoload macht nur aus
  Rückgaben Signale.
- **Reihenfolge beim Addieren von Kommazahlen** (`chance_info()`): erst die Start-Modifikatoren,
  dann die Eingriffe. Bei Mittel ist die erste Schleife leer, es wird also addiert wie in Feature
  002, und jede Schwelle bleibt bis aufs Bit gleich. Darum hält die Grundlinie.
- **Der Seed hängt nicht am Grad:** Die Würfel entstehen weiter nur aus Seed, Zweck und Kennung
  (`EventDice.make`); der Grad verschiebt nur die Schwelle.

### T011 Autoload `Timeline`

- `start_game(seed, difficulty)` lehnt einen unbekannten Grad ab, bevor es etwas ändert; das
  laufende Spiel bleibt.
- **Eine Regel, eine Stelle:** `_at_start_modifier()` fragt `DifficultyProfile.faulty_indices()`,
  dieselbe Regel wie `without_faulty()`. Jeder weggelassene Start-Modifikator steht so genau einmal
  da: mit seiner eigenen Meldung oder, mit `by_event`, aus `skipped_start_modifiers()`.
- **Fehler in GUT prüfen:** `assert_push_error(text)` hakt eine erwartete Meldung ab,
  `assert_push_error_count(3)` sichert, dass keine doppelt kam.

### T012 Kopfzeile und Textausgabe

- Die Kopfzeile nennt den Grad auch bei Mittel. Deshalb fehlt sie in der Grundlinie aus T001.
- **Ein Kommandozeilen-Skript testen** (`test_fahrplan_ausgabe.gd`): `fahrplan_ausgabe.gd` erbt
  von `SceneTree` und läuft nur als eigener Prozess. Der Test startet es mit `OS.execute()`, wie der
  Quickstart. Mit `read_stderr = false` kommt nur stdout zurück, mit `true` beides; was der zweite
  Aufruf mehr hat, ist stderr. Die Erwartung rechnet der Test selbst mit `TimelineRun` und
  `ScheduleText` und vergleicht sie als Ganzes.
- **Fehlerprobe:** Von 15 eingebauten Fehlern fanden die Tests 14. Durch fiel nur „die
  Textausgabe nennt einen fehlerhaften Start-Modifikator doppelt“, denn bis dahin prüfte kein Test
  die Textausgabe selbst. Dafür gibt es jetzt `test_fahrplan_ausgabe.gd`.
