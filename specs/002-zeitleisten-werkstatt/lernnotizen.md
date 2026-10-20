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

## Phase 3

### T020 Ein Würfel je Entscheidung

- Ein `RandomNumberGenerator` ist ein Objekt mit eigenem Zustand: Gleicher `seed` heißt gleiche
  Zahlenfolge. Das globale `randf()` teilt eine einzige Folge mit dem ganzen Spiel; ein
  zusätzlicher Wurf irgendwo würfelte alles danach neu. Deshalb bekommt in
  `src/core/timeline/event_dice.gd` jedes Ereignis und jede Folge-Entscheidung einen eigenen
  Generator.
- Ähnliche Seeds ergeben laut Doku ähnliche Folgen. SHA-256 über
  `"4711|chance|reklamationswelle"` mischt sie gründlich; `decode_u64(0)` liest die ersten 8 Byte
  als Zahl.
- Das Feld heißt laut Vertrag `seed`, wie die globale Funktion `seed()`. Mit `-d` warnt Godot
  dann; `@warning_ignore("shadowed_global_identifier")` hält den Start still.

### T021 Meldungen als Daten

- `TimelineMessage` hält Verweise auf Termin, Ereignis und Wirkung, keine Kopien. `to_line()`
  baut die Zeile nur aus Tag, Art und Text, etwa `22.03.1993  Beginn  Intel Pentium erscheint`.
  So lassen sich zwei Läufe Zeile für Zeile vergleichen (SC-002).

### T022 Der Kern ohne Node

- `TimelineRun` in `src/core/timeline/timeline_run.gd` erbt von `RefCounted` und braucht weder
  Szenenbaum noch Uhr. Jeder Aufruf von `begin()` und `advance_to()` gibt seine Meldungen als
  `Array[TimelineMessage]` zurück; Tests vergleichen einfach Listen, das Autoload macht daraus
  Signale.
- **Zwei feste Würfe je Monat:** In `_roll_month()` kommen beide `randf()` vor jeder Prüfung.
  Monat m nimmt also immer die Zahlen 2m und 2m+1 seines Würfels. Eine geänderte Chance,
  Bedingung oder Höchstzahl ändert nur, ob der Wurf trifft, nie die späteren Würfe (FR-015).
- **Stichtage statt Tagesschleife:** `_stop_days` ist ein sortiertes `PackedInt32Array` mit
  `bsearch()` und `insert()`, dazu kommt der nächste Monatserste. `advance_to()` springt von
  Stichtag zu Stichtag; an allen anderen Tagen geschieht nichts. Deshalb ist Tag für Tag dasselbe
  wie in Sprüngen, und ein ganzes Spiel dauert rund 4 ms.
- **Fahrplan sortiert halten:** `entries.bsearch_custom(entry, _comes_before)` liefert die Stelle
  zum Einfügen; eine statische Funktion lässt sich direkt als `Callable` übergeben. Auf einem
  typisierten Array sucht `bsearch_custom()` aber nur nach Werten des Elementtyps, deshalb gibt es
  für die Suche nach einem Tag eine eigene Binärsuche, `_first_index_from()`.
- **Folgen am selben Tag:** `_start_entries()` läuft mit `while` über eine Warteschlange, die
  während der Schleife wächst. So kommen Folgetermine „hinten an“; `_chain_links` merkt sich das
  Glied in der Kette.

### T023 Tests mit Zufall

- Wo der Zufall entscheidet, rechnet der Test mit demselben `EventDice` nach, statt Zahlen
  festzuschreiben. Damit prüft er die Tabelle „Zwecke und Würfe“ aus dem Vertrag selbst.
- Eine Fehlerprobe hat sechs typische Fehler nacheinander in eine Kopie des Laufs eingebaut, etwa
  „Kette je Tag statt je Kette gezählt“ oder „ein gemeinsamer Würfel für alle“. Jeder ließ Tests
  scheitern; so zeigt sich, dass die Tests das Richtige prüfen.

### Korrekturen nach dem Review

- **Eine Regel an einer Stelle:** `TimelineRun._hits()` entscheidet für Würfelrunde und
  Folgeereignisse, ob ein Wurf trifft: `roll < threshold` oder `threshold >= 1.0`, denn `randf()`
  kann genau 1,0 liefern. So kann die Regel nicht an einer Stelle anders sein als an der anderen.
- **Abrunden auf vier Stellen:** `floorf(x * 10000.0 + 1e-11) / 10000.0`. 0,412 liegt als float
  knapp unter 0,412; ohne den winzigen Zuschlag stünde dort „0,4119“.
- **Seltene Fälle testen:** Ein Wurf von genau 1,0 kommt etwa einmal in 33 Millionen Würfen vor.
  Der Agent hat Godots Würfel nachgebaut, Bit für Bit gegen Godot geprüft und Seeds gesucht, die
  ihn liefern. Der Test prüft zuerst diese Voraussetzung, damit er nach einem Godot-Update mit
  klarer Meldung scheitert, statt falsch grün zu sein.

### T024 und T025 Das Autoload

- **Signale aus Meldungen:** Der Lauf liefert Daten (`TimelineMessage`). Erst `_send()` in
  `src/core/timeline.gd` macht daraus Signale, an genau einer Stelle, per `match` über `Kind`.
- **`call_deferred()`:** `start_game.call_deferred()` ruft die Methode erst am Ende des Bilds
  auf, nach dem `_ready()` der Hauptszene. So ist jeder Abnehmer schon verbunden, wenn der
  01.01.1985 gemeldet wird.
- `clock.connect(&"day_passed", …)` nimmt den Signalnamen als Text, weil `game_clock.gd` kein
  `class_name` hat und `clock` nur als `Node` bekannt ist.
- **Autoload ohne Autoload testen:** `preload("res://core/timeline.gd").new()` ergibt in
  `test_timeline.gd` eine eigene Zeitleiste mit Test-Katalog und eigener Uhr. Erwartete Fehler
  hakt `assert_push_error()` ab; die Knoten entstehen dafür im Test selbst, nicht in
  `before_each()`.

### T026 und T027 Die Textausgabe

- **SceneTree-Skript mit eigenen Argumenten:** In `src/tools/werkstatt/fahrplan_ausgabe.gd`
  liefert `OS.get_cmdline_user_args()` alles nach `--`. `quit(code)` wird zum Exit-Code der
  Shell, `print()` geht nach stdout, `printerr()` nach stderr. So kann ein Aufrufer `$?` prüfen
  und die Ausgabe ohne Meldungen umleiten.
- Katalog und Lauf sind `RefCounted`; das Skript braucht keinen Knoten und erledigt alles in
  `_initialize()`.
- Die Kopfzeile „Godot Engine v4.7.2 …“ druckt die Engine vor dem Skript; nur `--no-header`
  unterdrückt sie.
- In `test_schedule_text.gd` stehen die erwarteten Zeilen mit ausdrücklichen Zählern im Test,
  nicht mit derselben `rpad()`-Logik wie im Code; sonst prüfte der Test sich selbst.

### T028 und T029 Übernahme und Export

- `test_uebernahme.gd` baut aus dem Protokoll genau das Format des Schnappschusses nach und
  vergleicht es für die Seeds 1 bis 100 Zeile für Zeile mit `historische_ereignisse.txt`.
- **Export-Filter:** `export_filter="all_resources"` packt alles, was Godot als Ressource kennt;
  JSON gehört dazu und liegt unverändert im Paket. Eine Gegenprobe mit `data/*` im
  `exclude_filter` zeigte, dass das Spiel einen fehlenden Katalog meldet.

## Phase 4

### T031 Das Theme der Werkstatt

- **Theme für einen Teilbaum:** Godot sucht jeden Eintrag zuerst in den Themes der
  Eltern-Controls, dann im Projekt-Theme, dann im Standard-Theme; der erste Treffer gilt.
  `src/tools/werkstatt/werkstatt_theme.tres` auf dem Wurzelknoten der Werkstatt überdeckt so das
  Theme des Spiels. Weil das Standard-Theme dunkel ist, hat jedes benutzte Control alle seine
  Farben im Werkstatt-Theme; sonst stünde Text in `tusche` auf dunklem Grund.
- Popups, Dialoge und Tooltips sind eigene Fenster, erben das Theme aber trotzdem, weil sie als
  Kinder im Baum hängen.
- **Typvarianten** wie `ErrorLineEdit` oder `TitleLabel`: `base_type` sagt, wovon sie erben, und
  ein Node wählt sie über `theme_type_variation`.
- **StyleBox:** Sie zeichnet den Hintergrund eines Controls; `content_margin_*` ist der
  Innenabstand. `StyleBoxFlat` kennt nur eine Randfarbe und nur weiche Schatten. Für Relief und
  Pixelschatten zeichnet `ReliefStyleBox` in `_draw(to_canvas_item, rect)` selbst Rechtecke mit
  `RenderingServer.canvas_item_add_rect()`: erst die Kontur, darauf die Fläche, darauf die Kanten.
- **Fokuslinie:** ein `StyleBoxFlat` mit `draw_center = false`, Rand 2 und `expand_margin` 4;
  das ergibt 2 Pixel Linie mit 2 Pixeln Abstand.
- Eine `.tres` kann keine `UiPalette`-Konstante nennen; die Farben stehen dort als Werte.
  `test_werkstatt_theme.gd` sorgt dafür, dass sie Palettenfarben bleiben.

### T032 und T033 Rückgängig zur Laufzeit

- **Ablauf:** `create_action(name)`, `add_do_method()`, `add_undo_method()`, `commit_action()`;
  das Commit führt die Do-Methode gleich aus.
- **`get_version()`** steigt bei Commit und Wiederholen und sinkt bei Rückgängig. Falle:
  Rückgängig und danach eine neue Aktion ergeben dieselbe Zahl wie vorher. `_commit()` in
  `src/tools/werkstatt/catalog_editor.gd` erklärt deshalb den gespeicherten Stand für
  unerreichbar, sobald unterhalb von ihm etwas Neues kommt.
- **Vorher/Nachher je Aktion:** Ein geändertes Ereignis wird nicht verändert, sondern durch eine
  Kopie ersetzt; das alte Objekt liegt unverändert im Verlauf. Eine Aktion kostet so nur die
  betroffenen Ereignisse, und Rückgängig setzt genau die alten Objekte wieder ein. Die Schritte
  sind Daten (`replace`, `insert`, `remove`), und `_inverse()` erzeugt das Rückgängig daraus.
- **Zyklus vermeiden:** `UndoRedo` hält das Ziel jeder Methode fest. Riefe eine Aktion den
  Editor selbst auf, hielte sein Verlauf ihn für immer am Leben. Jede Aktion zielt deshalb auf
  eine statische Funktion, die den Editor als `WeakRef` bekommt.
- **Fremde Änderung:** `get_modified_time()` zählt nur Sekunden; dazu kommt
  `FileAccess.get_sha256()` des Inhalts.
- Eine Änderung samt neuer Prüfung dauert bei 500 Ereignissen rund 5 ms (SC-011: unter 100 ms).

### T034 bis T039 Die Werkstatt-Szene

- **Szene aus Teilszenen:** `src/tools/werkstatt/werkstatt.tscn` setzt Liste und Formular als
  eigene Szenen ein; jede bringt ihr Skript und ihre Knoten mit. Mit `unique_name_in_owner`
  findet `%SaveButton` einen Knoten unabhängig vom Pfad.
- **Signale nach oben, Aufrufe nach unten:** Die Teile kennen sich nicht. Sie melden der
  Werkstatt (`event_selected`, `delete_requested`, `issue_activated`), und die Werkstatt ruft sie
  auf (`refresh()`, `show_event()`, `focus_field()`). Den Katalog ändert nur der
  `CatalogEditor`, die Auswahl gehört der Werkstatt.
- **Schließen:** Mit `get_tree().auto_accept_quit = false` schließt das Fenster nicht mehr von
  selbst; `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` fragt nach und ruft erst danach
  `get_tree().quit()`.
- **Kürzel:** Ein `Button.shortcut` mit `command_or_control_autoremap` ergibt Cmd auf dem Mac und
  Ctrl sonst. Ein Textfeld mit Fokus verbraucht Cmd+Z selbst, bevor die Kürzel drankommen; so
  gehört Z dem Feld ohne eigenen Code. Cmd+S gibt vorher den Fokus ab, damit das Feld seinen Wert
  übernimmt.
- **Geteilte Ressourcen:** Eine geladene `.tres` ist für alle dieselbe. Die Schrift kommt deshalb
  per `theme.duplicate()` in eine Kopie des Themes.
- **Tree statt ItemList:** Nur ein Tree hat Spalten und Farben je Zelle; das Fehlerzeichen „!“
  braucht seine eigene gefüllte Zelle. `select_mode = SELECT_ROW` markiert die ganze Zeile.
- **Formular aus Code:** Welche Felder es gibt, hängt an Art und Listenlänge. `event_form.gd`
  baut sie deshalb im Code und nach Änderungen neu, per `call_deferred()` am Ende des Bilds.
- **LineEdit-Falle:** Ein `LineEdit` merkt sich auch das Setzen von `text` in seinem eigenen
  Verlauf. Cmd+Z im frischen Feld hätte es geleert; das Formular schluckt Cmd+Z deshalb, solange
  das Feld den übernommenen Wert zeigt.
- **Szenen testen:** `test_werkstatt_scene.gd` wartet mit `wait_process_frames()` auf den Start
  per `call_deferred()`, löst Klicks über die Signale aus und Tasten über
  `get_viewport().push_input()`.
- **Fenstermodus unter macOS:** `window.mode = …` ist kein sofortiger Zustand, sondern eine Bitte
  an das System, das den Wechsel als Animation ausführt. Solange das Projekt im Vollbild
  startete, lief dieser Übergang bei `_ready()` noch: `window.mode` las 0, und die Bitte um
  `MODE_MAXIMIZED` ging verloren. Seit der Abnahme T040 startet das Projekt im Fenster, und die
  Bitte greift sofort. `GameWindow` wartet aus demselben Grund das Ende eines Übergangs ab, bevor
  es die Fenstergröße setzt.
- **Start-Fit über `_process()` statt `call_deferred()`:** `GameWindow` gibt dem Spielfenster
  seine Größe erst im ersten Bild. Ein aufgeschobener Aufruf liefe nach dem `_ready()` der
  Werkstatt und schrumpfte ihr maximiertes Fenster; `_process()` dagegen läuft gar nicht, weil die
  Werkstatt die Verarbeitung von `GameWindow` in ihrem `_ready()` anhält.
- **`Engine.is_embedded_in_editor()`:** wahr, wenn das Spiel im Tab „Spiel“ des Editors läuft.
  Dann gehört das Fenster dem Editor: `GameWindow` setzt beim Start keine Größe, und die
  Werkstatt maximiert nicht.

## Phase 5

### T041 Dauer und jährliche Ereignisse

- **Enden als Stichtage:** `_ends` in `src/core/timeline/timeline_run.gd` ist ein Dictionary
  Tag → Termine, gebaut wie `_due_effects` für verzögerte Wirkungen: Es enthält nur die Tage, an
  denen wirklich etwas endet. `_plan_end()` trägt das Ende beim Beginn ein und meldet den Tag mit
  `_add_stop()` als Stichtag an. Deshalb springt `advance_to()` auch zu Enden, und Tag für Tag
  ergibt weiter dasselbe wie in Sprüngen.
- **Enden vor Beginnen:** `_play_day()` ruft `_end_entries()` als ersten Schritt auf. Am 01.03.
  ist der Winter deshalb schon beendet, wenn der Frühling beginnt. Auch die Prüfung „läuft noch“
  (FR-022) in `_start_entry()` hält einen Termin, der heute endet, nicht mehr für laufend.
- **Jährliche Vorkommen in Tagesindizes:** `_occurrence()` macht aus Monat und Tag einen Beginn
  und einen letzten Tag, beide als Index von `GameDate`. Liegt das Ende im Jahr vor dem Beginn,
  gehört es ins Folgejahr. Für „ende“ fragt es `days_in_month()` im Jahr des Endes, so endet der
  Winter 1987/88 am 29.02. Der Winter 1984/85 beginnt beim Index −31; `maxi(…, FIRST_DAY)` setzt
  den Termin auf Tag 0, und `started_before_game` hält fest, dass er schon vorher lief.
- **Leeres Ergebnis statt Sonderwert:** `_occurrence()` gibt ein `PackedInt32Array` mit zwei
  Zahlen zurück, leer, wenn es das Vorkommen nicht gibt. Der Aufrufer fragt `is_empty()` und
  braucht keinen geheimen Wert wie −1.
- **Eine Regel an einer Stelle:** `_is_during()` und `_effect_day()` sind statische Hilfen, die
  Beginn und Ende gleichermaßen fragen. Ob eine Wirkung „während“ gilt und an welchem Tag sie
  beginnt, kann so beim Ende nicht anders ausfallen als beim Beginn, wie `_hits()` in Phase 3.
- Verzögerungen zählen ab `day`, dem Beginn im Fahrplan (data-model.md: Tag = `day +
  delay_days`). Beim Winter 1984/85 ist das der 01.01.1985, nicht der 01.12.1984.

### T042 Tests zu Dauer und Kalender

- **Vier Fixtures nach Zweck:** `catalog_us3_kalender.json` mit den sechs Kalender-Ereignissen
  und den Startwerten aus R19, `catalog_us3_dauer.json` für die Szenarien 3 und 4, FR-021 und
  das Spielende, `catalog_us3_laeuft_noch.json` für FR-022 beim Würfeln und bei Folgen,
  `catalog_us3_jaehrlich.json` für Sonderfälle der jährlichen Ereignisse. Ein Einmal-Skript hat
  geprüft, dass `read_file()` und `to_json()` jede Datei bytegleich wieder ergeben.
- **Ohne Würfel nachzurechnen:** Der Lieferengpass hat 100 %, ein Fenster von Januar bis Februar
  1990 und 60 Tage Dauer. Der Termin im Februar fällt bei jedem Seed in die Zeit des ersten.
  Der Test läuft deshalb über 20 Seeds, ohne mit `EventDice` nachzurechnen.
- Die Tests vergleichen ganze Protokollzeilen. So prüfen sie auch die Reihenfolge: das
  Wirkungsende vor dem Ende, das Ende vor dem Beginn.
- **GUT:** `assert_eq` vergleicht Arrays und Dictionaries nach Inhalt, etwa
  `{"Beginn": 14, "Wirkung": 14, "Ende": 14}`. `range(1985, 2000)` ist in Godot 4 ein Array und
  lässt sich direkt vergleichen. `assert_string_ends_with()` nimmt keinen eigenen Meldungstext.
- **Fehlerprobe:** In eine Kopie des Projekts außerhalb des Repos wurden nacheinander elf Fehler
  eingebaut, etwa „Enden nach den Beginnen“ oder „Monatsende ohne Schaltjahr“. Zehn haben Tests
  scheitern lassen. Der elfte, ein Ende nach dem 31.12.1999 trotzdem vorzumerken, ändert nichts,
  weil `advance_to()` am Tag 5477 aufhört; die Abfrage in `_plan_end()` hält nur `_ends` sauber,
  wie die gleiche in `_plan_effect()`.

### T043 Altlasten entfernen

- **Ein Signal ist Schnittstelle:** Wer ein Signal über seinen Namen als Text anspricht, etwa
  mit `connect(&"season_changed", …)` oder GUTs `assert_signal_emitted(_clock, "season_changed")`,
  merkt sein Fehlen erst zur Laufzeit; solche Texte prüft der Parser nicht. Darum zuerst ein
  `grep` über `src/`: Außer `game_clock.gd`, `game_date.gd` und ihren Tests nutzte nichts
  `season_changed`, `is_holiday_season()` oder `season()`.
- Das Weihnachtsgeschäft meldet jetzt die Zeitleiste über `event_fired` und `event_ended`, sobald
  T044 es in den Katalog legt. Bis dahin meldet es niemand; einen Abnehmer gibt es noch nicht.

### T045 Kalender im echten Katalog

- **Nur, was dauerhaft gilt:** `src/test/test_shipped_catalog.gd` prüft die sechs Kennungen, die
  Art „jährlich“, Beginn und Ende aus FR-023 und die Jahre. Titel, Texte, Wirkungen und die
  genauen Tage der CeBIT prüft er nicht, denn die stellt Klaus in der Werkstatt nach.
- **`const` mit `Vector2i`:** `JEDES_JAHR` ist ein konstantes Dictionary mit Werten wie
  `Vector2i(12, 0)`. Ein eingebauter Typ mit festen Zahlen ist ein konstanter Ausdruck und darf
  deshalb in `const` stehen.
- **SC-009 über einen Lauf:** Der Test legt den Lauf an wie das Autoload (lesen, prüfen,
  `without_faulty()`), spielt bis zum 31.12.1999 und liest die Termine. So prüft er Katalog und
  Lauf zusammen, bis zu „(Ende nach Spielende)“ in der Textausgabe. Jährliche Termine hängen
  nicht am Seed.
- **Gegenprobe:** Sechs falsche Kataloge in einer Kopie außerhalb des Repos, etwa „Ende 12-30“,
  „Winter fehlt“ oder „CeBIT im April“, ließen jeweils mindestens einen Test scheitern.

### Korrekturen nach dem Review

- **Zufall in Tests festhalten:** `test_ereignis_mit_fehler_fehlt_im_lauf_und_wird_gemeldet` in
  `src/test/test_timeline.gd` startete das Spiel per `call_deferred()` ohne Seed, und seine
  Schleife prüft jeden Termin einzeln. Je nach Wurf hatte das Neubaugebiet einen Termin oder
  keinen, und die Zahl der Asserts schwankte. `start_game(4711)` ersetzt den Lauf wie in den
  anderen Tests der Datei; die Schleife prüft jetzt 16 Termine, bei jedem Lauf gleich viele.
