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

## Phase 3

### T014 `CatalogEditor` mit Start-Modifikatoren

- **Ganze Profile im Verlauf** (`_run()`, `_profile_redirections()`): `UndoRedo` merkt sich hier
  keine Stellen, sondern alte und neue Objekte. Löscht Klaus ein Ereignis, auf das in Schwer die
  Stellen 0 und 2 zeigen, stimmte nach dem ersten Entfernen eine gemerkte 2 nicht mehr. Deshalb
  kommt ein ganz neues Profil-Objekt hinein, und Rückgängig setzt einfach das alte wieder ein. Weil
  Profile `RefCounted` sind, lebt das alte Objekt weiter, solange der Verlauf es hält.
- **Identität statt Inhalt:** `list.find(item)` in `_run()` sucht das Objekt selbst, und `_texts` in
  `content_key()` hat Objekte als Schlüssel. Ein neues Objekt heißt also „geändert“; Simulator und
  Statistik merken eine Profiländerung, ohne dass `to_json()` laufen muss.
- **Die Kehrseite:** Ein Start-Modifikator, den `add_start_modifier()` zurückgibt, steht nur bis zur
  nächsten Änderung an diesem Profil im Katalog. Wer ihn danach braucht, holt ihn über Grad und
  Stelle neu, so wie ein Ereignis über seine Kennung. Das muss das Panel in T016 beachten.
- **Typisierte Arrays:** Gefiltert wird in ein neues `Array[ChanceModifier]` oder
  `Array[CatalogIssue]`, das dann zugewiesen wird; so bleibt der Typ der Liste erhalten.
- **Lesemeldungen** (`_drop_read_issues()`): Ersetzt ein Schritt ein Profil, verschwinden dessen
  Meldungen V22, nach ganzen Pfadteilen, auch beim Rückgängigmachen. Eine gemerkte Stelle kann so
  nie den falschen Start-Modifikator treffen.
- **GUT:** `assert_same` vergleicht die Identität von Objekten, `assert_eq` auf Arrays Element für
  Element. Damit prüft ein Test, dass ein unverändertes Profil dasselbe Objekt bleibt.
- **Fehlerprobe:** elf eingebaute Fehler, alle gefunden. Den Test zu `profiles.schwerr` hatte der
  Agent vorher ergänzt, weil er sah, dass ihn sonst keiner gefunden hätte.

### T016 bis T018 Reiter „Schwierigkeitsgrade“, Verdrahtung, „Je Grad“

- **Stelle statt Objekt merken** (`difficulty_panel.gd`, `_modifier()`, `_index`): Jede Änderung
  ersetzt das ganze Profil durch eine Kopie; ein gemerkter `ChanceModifier` stünde danach nicht
  mehr im Katalog. Das Panel merkt sich nur Grad und Stelle und holt den Start-Modifikator bei jedem
  Zugriff frisch, so wie Ereignisse über ihre Kennung.
- **Felder einmal in der Szene, Zeilen neu am Ende des Bilds:** Die sechs Felder stehen fest in der
  `.tscn`, `refresh()` setzt nur ihre Werte und lässt das Feld mit dem Fokus aus. Die
  Tabellenzeilen baut `_fill_rows_later()` mit `call_deferred()` erst am Ende des Bilds, sonst träfe
  ein Klick, der einem Feld den Fokus nimmt, schon eine neue Zeile.
- **Cmd+Z und `gui_input`** (`_set_up_edit()`): `gui_input` kommt, bevor das LineEdit die Taste
  verarbeitet. Zeigt das Feld noch den übernommenen Text, verschluckt `accept_event()` die Taste;
  sonst nähme der eigene Verlauf des Felds das Setzen des Texts zurück, und das Feld wäre leer.
- **`_commit_focused()` vor jedem Wechsel:** Ein Knopfdruck aus dem Code oder ein Gradwechsel nimmt
  dem Feld den Fokus nicht; ohne diesen Aufruf ginge die offene Eingabe verloren.
- **GridContainer und Mindestgrößen:** Eine Zeile des Rasters ist so hoch wie ihre höchste Zelle,
  deshalb bekommt die Beschriftung die Höhe des Felds und steht oben. Mindestgrößen wandern im Baum
  nach oben: Eine feste Breite von 340 px für `%Fields` machte bei 1280 px die ganze Werkstatt zu
  breit. Jetzt teilen sich beide Seiten mit `size_flags_stretch_ratio` (2,3 : 1).
- **Signale nach oben, Aufrufe nach unten** (`werkstatt.gd`): Das Panel kennt Liste und Formular
  nicht. Die Werkstatt reicht `selected_event_id` herunter, ruft `refresh()` und `focus_field()` und
  wechselt den Reiter; die Prüfung meldet nur `issue_activated`.
- **Hinweis an der Zeile** (`event_form.gd`, `_add_difficulty_row()`): Labels lassen die Maus
  durch, und Godot sucht den Hinweis bei den Eltern weiter; ein `tooltip_text` an der HBox reicht.
  Vor „%“ steht ein geschütztes Leerzeichen (U+00A0), damit der Umbruch Zahl und Zeichen nie trennt.
- **Fehlerprobe:** neun eingebaute Fehler; einer fiel zuerst durch, `refresh()` überschrieb das Feld
  mit dem Fokus. Dafür gibt es jetzt `test_refresh_laesst_das_feld_mit_dem_fokus_stehen`.

### T021 Profile im echten Katalog nicht leer

- `test_leicht_und_schwer_haben_je_mindestens_einen_start_modifikator()` in
  `src/test/test_shipped_catalog.gd` geht über `Difficulty.WITH_PROFILE` und `get_profile()`, statt
  „leicht“ und „schwer“ auszuschreiben; welche Grade ein Profil haben, steht so nur an einer Stelle.
- Er prüft absichtlich nur `modifiers.is_empty()`. Ein Test, der Werte festschreibt, bräche bei
  jeder Änderung in der Werkstatt.
- Die Fehlerprobe zeigte: Der Test „keine Fehler“ bemerkt ein leeres Profil nicht, denn ein leeres
  Profil ist kein Prüffehler. Gegen ein leer gewordenes Profil schützt nur dieser Test.

## Phase 4

### T023 Proben mit Grad

- **Eine Aufzählung ist zur Laufzeit eine Zahl** (`what_if_probe.gd`): `write_file()` prüft den
  Grad mit `Difficulty.is_valid()`, `read_file()` wandelt erst nach der Prüfung mit
  `as Difficulty.Level` um. `typeof(value) != TYPE_STRING` steht vor `Difficulty.from_key()`, denn
  `"difficulty": 1` wäre als Zahl Mittel, soll aber abgelehnt werden.
- **JSON liefert `Variant`:** `JSON.parse()` kennt keine Typen. `_read_difficulty()` prüft deshalb
  mit `typeof()`, wie es `_structure_problem()` mit `seed` und `format` tut.
- **Kanonisch über sortierte Schlüssel:** `JSON.stringify(data, "\t", true)` setzt „difficulty“ von
  selbst vor „format“, ohne Sonderregel.
- **Der Grad wirkt im Lauf, nicht in der Probe:** Die Probe speichert nur den Namen. Die
  Start-Modifikatoren setzt `TimelineRun._init()` aus dem Profil des Katalogs, wie er gerade ist.
  Ändert Klaus ein Profil, spielt eine alte Probe mit dem neuen Profil.
- **`:=` braucht einen bekannten Typ:** Der Zugriff auf ein untypisiertes Dictionary liefert
  `Variant`, und `var pfad := …` scheitert mit „Cannot infer the type“. Ein solcher Parse-Fehler
  lässt GUT die ganze Datei still überspringen: Die Suite zeigt ein Skript weniger und trotzdem
  „All tests passed“. Auf die Zahl der Skripte zu achten lohnt sich.
- **GUT verfolgt Fehler:** Jedes `push_error()` muss genau einmal mit `assert_push_error()`
  abgehakt werden, sonst wird der Test rot.

### T025 und T026 Simulator mit Grad und Vergleich mit Mittel

- **Der Grad gehört zum Lauf:** `TimelineRun.difficulty` ist ab `_init()` fest, deshalb baut ein
  Wechsel einen neuen Lauf (`_switch_difficulty()`), über eine kurzlebige `WhatIfProbe` mit
  `build_run()`, statt eine zweite Logik zum Nachspielen zu schreiben.
- `_start_run()` setzt die Auswahl mit `select()`, das kein `item_selected` sendet: Nur Klaus'
  Klick baut neu, ein geladener Lauf stellt nur die Auswahl um.
- **Metadaten in TreeItems:** Zeilen mit Start-Modifikatoren erkennt die Liste an
  `set_metadata()`, nicht an Farbe oder Text.
- **Property mit Setter:** `compare_with_mittel` zieht das Häkchen mit `set_pressed_no_signal()`
  nach; ohne `no_signal` liefen Signal und Setter im Kreis.
- **`HFlowContainer` statt `HBoxContainer`:** Eine HBox ist mindestens so breit wie alle Kinder
  zusammen und drückt sonst das Layout aus dem Fenster; ein FlowContainer bricht um.
  `%CompareLabel` kürzt mit `text_overrun_behavior` und braucht `mouse_filter = PASS` für den
  Hinweis.
- **Fehlerprobe:** 19 eingebaute Fehler, alle gefunden.

## Phase 5

### T028 Statistik mit mehreren Graden

- **Zählen erst am Ende des Seeds** (`timeline_statistics.gd`): Ein fertiger Lauf wandert nach
  `_finished_runs`. Erst wenn alle Grade des Seeds fertig sind, zählt `_count_seed()` jeden in die
  Zählung seines Grads, und `games_done` steigt. Bricht die Werkstatt ab, gehen die wartenden Läufe
  verloren, und jeder Grad hat gleich viele Spiele.
- **Mit nur Mittel** zählt der Seed im selben Schritt wie in Feature 002; die Rechnung bleibt
  Schritt für Schritt gleich.
- **Verschachtelte typisierte Arrays:** GDScript kennt kein `Array[Array[EventStatistic]]`.
  `_statistics` ist deshalb `Array[Array]`, jedes Element ein echtes `Array[EventStatistic]`; den Typ
  prüft Godot beim Übergeben zur Laufzeit.
- **Gemessen:** SC-003 mit Mittel 5,601 und Schwer 14,715 Reklamationswellen im Mittel; alle drei
  Grade mit je 1.000 Spielen auf dem echten Katalog headless in 25,5 s.

### T030 Statistik-Panel mit Grad

- **Die Rechnung entscheidet, nicht die Auswahl** (`_is_comparing()` liest
  `statistics.difficulties`): Stellt Klaus die Auswahl nach der Rechnung um, gehören Tabelle und
  Text weiter zum Ergebnis, das dasteht.
- **Kennung statt Stelle im `OptionButton`:** Das Panel liest `get_selected_id()`; die Kennung ist
  direkt der Grad, „Alle drei“ hat die Konstante `COMPARE_ALL`. So darf sich die Reihenfolge der
  Einträge ändern.
- **Typisierte Arrays:** `TimelineStatistics.new()` erwartet `Array[int]`. `assign()` kopiert in ein
  typisiertes Array und prüft dabei jedes Element; ein untypisiertes `[]` fiele erst zur Laufzeit
  auf.
- **Ein Tree kann seine Spaltenzahl ändern** (`_table.columns = n`): Danach setzt
  `_set_up_columns()` Titel, Ausrichtung und Breiten neu. Godot verbreitert eine Spalte selbst bis
  zur Breite ihres Titels; die Breiten in `COMPARE_WIDTHS` sind Untergrenzen.
- **Ein Schlüssel für „Katalog geändert“:** Er beschreibt den Katalog, mit dem ein neuer Start
  rechnen würde. Was `without_faulty()` weglässt, hängt auch an den Meldungen, deshalb gehören
  die weggelassenen Stellen hinein, wie im Simulator.
- **Gemessen:** „Alle drei vergleichen“ mit 1.000 Spielen auf dem echten Katalog im Fenster 26,6 s;
  SC-004 erlaubt 90 s.
