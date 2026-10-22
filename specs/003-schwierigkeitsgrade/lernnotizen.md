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
