# Lernnotizen: Zeitleisten-Werkstatt

Zu jeder `[A]`-Aufgabe die Godot-Konzepte und warum es so gebaut ist, an den Stellen im Projekt.
Der Agent schreibt die Notizen, Claude trägt sie je Phase hier ein.

## Phase 1

### T003 Schnappschuss der alten Daten

- **SceneTree-Skript mit `-s`:** Normalerweise baut Godot selbst einen `SceneTree` und lädt die
  Hauptszene. Mit `-s skript.gd` wird das Skript zur Hauptschleife, deshalb steht oben
  `extends SceneTree`. Godot ruft einmal `_initialize()` auf. Das Skript beendet den Lauf selbst
  mit `quit()` oder `quit(1)`, der Wert wird zum Exit-Code; ohne `quit()` liefe der Prozess
  headless endlos weiter.
- **`--path src`** macht `src/` zum Projekt: `res://` zeigt dorthin, und Namen aus `class_name`
  wie `EventDatabase` kennt Godot aus dem Klassen-Cache des Projekts. Deshalb konnte das
  Einmal-Skript außerhalb des Repos liegen und brauchte kein `load()`.
- Genauso laufen GUT (`-s res://addons/gut/gut_cmdln.gd`) und später die Textausgabe
  `fahrplan_ausgabe.gd` (T026).
- **Warum vor dem Umbau:** `src/test/fixtures/historische_ereignisse.txt` ist der Maßstab für
  SC-005. Mit T010 fallen `event_database.gd` und die alten Klassen weg; danach könnte kein Code
  mehr sagen, was die alte Engine geliefert hat. Als schlichter Text braucht die Datei keine
  Godot-Klasse, und `git diff` zeigt sie zeilenweise. T028 prüft den neuen Fahrplan gegen sie.
- Das Skript prüfte vorher, dass der Tag, an dem die alte Engine ein Ereignis meldete
  (`trigger_day_index()`), genau dem Datum der Zeile entspricht und dass keine Kennung und kein
  Ziel ein Trennzeichen `|`, `;` oder `:` enthält.
- Eine `.txt` ist für Godot keine Ressource; es entstehen weder `.uid` noch `.import`.

### T004 Übernahme in den Katalog

- **`JSON.stringify(daten, "\t", true)`:** Der zweite Parameter rückt ein: Jedes Element eines
  Dictionarys oder einer Liste steht auf einer eigenen Zeile, je Ebene ein Tab mehr; leere Listen
  bleiben `[]`. Der dritte sortiert die Schlüssel jedes Dictionarys alphabetisch, deshalb ist die
  Reihenfolge egal, in der das Skript sie einträgt. Listen sortiert `stringify` nicht: Die
  Ereignisse sortiert das Skript selbst nach Kennung, die Kategorien bleiben in ihrer Reihenfolge.
  So ergibt gleicher Inhalt dieselbe Datei, und eine Feldänderung ändert genau eine Zeile (FR-035).
- In Texten maskiert Godot nur Steuerzeichen, Anführungszeichen und Backslash. Umlaute, „ß“ und
  „–“ stehen als UTF-8 in `src/data/event_catalog.json`.
- **`int` und `float` in JSON:** JSON kennt nur „Zahl“. Godot schreibt ein `int` ohne Nachkomma
  (`14`) und ein `float` immer mit (`0.0`, `-0.3`); entscheidend ist der Typ in GDScript.
  `JSON.parse()` liest jede Zahl als `float` (`14` → `14.0`). Deshalb wandelt der Katalog ab T011
  ganzzahlige Felder mit `int()` zurück, sonst stünde nach dem nächsten Speichern `14.0`.
- Gerundet wird mit `roundf(x * 10000.0) / 10000.0`. `round()` liefert ein untypisiertes
  `Variant`, mit `var x :=` meldet der Parser dann einen Fehler. Eine 32-Bit-Zahl stünde dagegen
  als `0.150000005960464` in der Datei.
- **Warum die endgültige Form erst in T012 entsteht:** Das Einmal-Skript baut die Dictionaries
  von Hand und ahmt die Schreibregeln nur nach. Verbindlich ist der Code, der die Datei künftig
  schreibt, `TimelineEvent.to_dict()` und `EventCatalog.to_json()`. Erst wenn T012 den Katalog
  damit neu schreibt, ist sicher, dass das erste Speichern in der Werkstatt keinen reinen
  Formatierungs-Diff erzeugt.
- **Keine `.uid`:** Godot importiert JSON nicht, sondern lädt es direkt als Ressource vom Typ
  `JSON`; eine UID bekommt die Datei in 4.7.2 nicht. Verweise gehen deshalb über den Pfad, und
  gelesen wird der Katalog ohnehin per `FileAccess` (R4).

### T005 Export-Filter

- In `src/export_presets.cfg` steht `export_filter="all_resources"`: Godot packt jede Ressource
  des Projekts ins Spiel, außer Pfaden, die zu einem Muster in `exclude_filter` passen. Die Muster
  gelten relativ zu `res://`, `*` steht für beliebige Zeichen, auch über Unterordner hinweg.
- `tools/*` hält Werkstatt, Textausgabe und Proben aus dem ausgelieferten Spiel heraus, so wie
  `test/*` die Tests. Daraus folgt eine Regel: Spielcode darf nie etwas unter `res://tools/`
  laden, denn im Export fehlt es.
- Geheime Exportfelder wie Zertifikat- oder Apple-ID-Passwörter legt Godot 4 nicht in
  `export_presets.cfg` ab, sondern in `.godot/export_credentials.cfg`, und `.godot/` ist von Git
  ausgenommen. Angesehen wird `export_presets.cfg` vor jedem Commit trotzdem (CLAUDE.md).

## Phase 2

### T007 Tage vor 1985

- `GameDate.to_day_index()` in `src/core/game_date.gd` hat zwei Schleifen: `range(EPOCH_YEAR, year)`
  zählt die Jahre ab 1985 dazu, `range(year, EPOCH_YEAR)` zieht die Jahre vor 1985 ab. Ein
  `range()`, dessen Start nicht unter dem Ende liegt, läuft gar nicht; es läuft also immer
  höchstens eine der beiden. `from_day_index()` geht bei einem negativen Rest erst Jahre zurück.
- Der Rundreisetest von −400 bis 5477 prüft zusätzlich `is_valid()`. Der alte Fehler hätte die
  reine Rundreise bestanden: −1 ergab einen „0. Januar 1985“, und der führt rechnerisch wieder
  zu −1.

### T008 Farben über ihren Namen

- `UiPalette.TOKENS` ist ein konstantes Dictionary, `CATEGORY_TOKENS` ein typisiertes Array als
  Konstante. Beides hängt an der Klasse, `UiPalette.by_token(&"petrol")` geht also ohne `new()`.
- `&"…"` ist ein `StringName`: Godot legt den Namen einmal ab und vergleicht danach über die
  Adresse statt Zeichen für Zeichen.
- Magenta als Ersatzfarbe macht einen Tippfehler im Katalog sofort sichtbar, statt still eine
  falsche Farbe zu zeigen.

### T009 und T010 Datenklassen

- **`RefCounted` statt `Resource`:** Die Datenklassen unter `src/core/timeline/` geben sich
  selbst frei, sobald niemand mehr auf sie verweist, brauchen also kein `free()`. Als `.tres`
  speichern lassen sie sich nicht, und das ist gewollt: Der Katalog ist JSON.
- **`static func from_dict()` als Fabrik:** Die Funktion ist `static`, weil sie das Objekt erst
  erzeugt: zuerst `TimelineEvent.new()` mit den Vorgaben aus den `var`-Zeilen, dann überschreibt
  sie die Felder, die sich lesen lassen. Arrays werden als Verweis übergeben; was `from_dict()`
  an `issues` anhängt, kommt deshalb beim Aufrufer an.
- Eine Wirkung weiß nicht, zu welchem Ereignis sie gehört. Darum ergänzt
  `TimelineEvent.from_dict()` ihre Meldungen danach um die Stelle (`prefix_fields()` macht aus
  `scope` dann `effects[1].scope`) und um das Ereignis (`locate()`).
- Enums stehen als Text in der Datei. Hin geht es über `KIND_NAMES[kind]`, zurück über
  `CatalogIssue.read_choice()`. Das `as Kind` beim Zurückwandeln braucht es, sonst warnt
  GDScript, dass eine Zahl in ein Enum-Feld kommt.
- Falle bei typisierten Arrays: `KIND_NAMES.has(5)` auf einem `Array[String]` erzeugt einen
  Engine-Fehler, und GUT wertet Engine-Fehler als fehlgeschlagenen Test. `_is_one_of()` prüft
  deshalb erst den Typ.
- **`git mv` mit `.uid`:** Die `.uid` hält die feste ID des Skripts, über die Szenen und
  Ressourcen verweisen. Zieht sie mit um, findet Godot das Skript am neuen Ort unter derselben
  ID; Git sieht eine Umbenennung statt Löschen und Neuanlegen.
- **Leeres Autoload:** `src/core/timeline.gd` bleibt in `project.godot` eingetragen, damit T017
  nur noch den Inhalt der Datei füllt. Ein Autoload ist ein Knoten, den Godot vor der
  Hauptszene in den Baum hängt.

### T011 bis T013 Katalog lesen und schreiben

- **Mit Fehlerzeile lesen:** `EventCatalog.from_json()` nutzt `JSON.new()` und `parse()`, denn
  `get_error_line()` und `get_error_message()` nennen die Stelle; `JSON.parse_string()` gäbe nur
  `null`. `get_error_line()` zählt ab 0, deshalb steht im Code `+ 1`.
- Godots Parser lässt nachgestellte Kommas und doppelte Schlüssel durch; bei doppelten gilt der
  letzte.
- **Kanonisch schreiben:** `JSON.stringify(data, "\t", true)` setzt Tabs und sortiert die
  Schlüssel, aber keine Listen; die Ereignisse sortiert `_sorted_by_id()`. `sort_custom()` ist
  nicht stabil, darum entscheidet bei gleicher Kennung die alte Position.
- **`int` und `float`:** `parse()` liefert jede Zahl als `float`. `CatalogIssue.read_int()`
  wandelt ganze floats mit `int()` zurück; ganzzahlige Gewichte schreibt `_weights_for_file()`
  als `int`, Anteile rundet `to_dict()` mit `roundf(x * 10000.0) / 10000.0`.
- **Startprobe mit `-d`:** Dann gibt Godot GDScript-Warnungen jedes geladenen Skripts aus.
  `GameDate` und `UiPalette` werden beim Start geladen und müssen deshalb warnungsfrei sein.
- **T012:** Die Übernahme hatte die Form schon richtig nachgeahmt; neu geschrieben mit
  `write_file()` blieb `src/data/event_catalog.json` bytegleich. Damit belegt der Code, der die
  Datei künftig schreibt, dass das erste Speichern in der Werkstatt keinen Diff erzeugt.

### T014 Die Prüfregeln

- **Kreise im Graphen finden:** Die Folgeereignisse bilden einen Graphen: Jedes Ereignis ist ein
  Knoten, jedes Folgeereignis mit 100 % ein Pfeil zu seinem Ziel. Ein Pfeil von A nach B liegt
  genau dann auf einem Kreis, wenn man von B aus wieder zu A kommt. `_reachable()` in
  `src/core/timeline/catalog_validator.gd` sucht das mit einer Liste noch offener Knoten und
  einem Dictionary als Menge der schon erreichten; das Ergebnis bleibt je Start im Cache.
- V18 sucht nur über Pfeile ohne Verzögerung. V23 nimmt alle Knoten, die sich gegenseitig
  erreichen; liegt darin ein Pfeil mit Verzögerung, läuft die Kette bis Spielende weiter.
- **Nachschlagen statt suchen:** `_index_by_id()` baut einmal ein Dictionary Kennung →
  Ereignisse. Danach kostet jeder Verweis einen Zugriff statt eines Durchlaufs durch die ganze
  Liste; 500 Ereignisse mit einem Kreis über 250 Ereignisse brauchten 33 ms. Mehrere Ereignisse
  unter einer Kennung ergeben nebenbei V02.
- **float vergleichen:** 33,33 + 33,33 + 33,33 ergibt in float nicht genau 99,99, der Abstand zu
  100 liegt bei 0,0100000000000051. `WEIGHT_TOLERANCE` ist darum 0,01 plus ein winziger
  Zuschlag.
- **Reihenfolge nach Regel:** `_finish()` gruppiert die Meldungen in einem Dictionary nach Regel,
  statt `sort_custom()` zu nehmen. Das ist stabil: Innerhalb einer Regel bleibt `effects[0]` vor
  `effects[1]`.

### T015 Fixtures und Tests mit vielen Fällen

- Jede Fixture unter `src/test/fixtures/` ist der Grundkatalog `catalog_minimal.json` mit einer
  gezielten Änderung. `git diff --no-index` zeigt deshalb sofort, was kaputt ist, und der Test
  erwartet genau die Meldung dieser Regel.
- `func test_x(fall: Array = use_parameters(FAELLE))` ist GUTs Weg für einen Test mit vielen
  Fällen: GUT ruft ihn je Eintrag einmal auf und zeigt jeden Durchlauf einzeln.

### T016 Termine als Daten

- `ScheduleEntry` speichert Würfelwert, Schwelle und Modifikatoren als Zahlen und Texte. Den Satz
  baut `explain()` erst beim Anzeigen, mit `"%.3f"` und Komma statt Punkt. So bleibt die
  Begründung lesbar, auch wenn ein Modifikator später entfernt wird.

### T017 und T018 Die stille Hülle

- **Signale mit typisierten Parametern:** `signal event_fired(event: TimelineEvent, date:
  GameDate)` in `src/core/timeline.gd` legt schon jetzt fest, was jeder Abnehmer bekommt. Editor
  und Autovervollständigung kennen die Typen, und wer sich später verbindet, muss nichts umbauen.
- Godot warnt bei Signalen, die deklariert, aber nie gesendet werden; mit `-d` stünde die Warnung
  beim Start in der Ausgabe. Darum trägt jedes Signal bis T024 `@warning_ignore("unused_signal")`.
- **Warum die Hülle noch nichts abspielt:** Den Lauf `TimelineRun` gibt es erst in Phase 3. Laden
  und Prüfen gibt es aber schon, damit FR-048 und FR-049 greifen: Ein fehlerhaftes Ereignis wird
  beim Start gemeldet und übersprungen, statt das Spiel aufzuhalten. Autoloads laufen auch beim
  GUT-Lauf; ein Fehler im echten Katalog stünde deshalb in jeder Testausgabe.
- **Falle bei SceneTree-Skripten:** In `_initialize()` bekommt ein neuer Knoten sein `_ready()`
  noch nicht sofort. Arbeit mit Knoten gehört dort ins erste `_process()`, und `--quit-after`
  sichert gegen Hängen ab. Das gilt auch für die Textausgabe in T026.
- **T018:** `test_shipped_catalog.gd` prüft am echten Katalog nur, dass er fehlerfrei ist;
  `test_uebernahme.gd` prüft an der eingefrorenen Kopie, was die Übernahme enthielt.
