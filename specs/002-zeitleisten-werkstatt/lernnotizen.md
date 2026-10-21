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

## Phase 6

### T047 Der Zeitstrahl zeichnet sich selbst

- **Ein Control statt vieler Nodes:** `TimelineView` in `src/tools/werkstatt/timeline_view.gd`
  erbt von `Control` und malt Zeilen, Raster, Marken, Titel und Achse in `_draw()`. Ein Node je
  Marke wäre bei 500 Ereignissen und jedem Zoomschritt teuer (R16). Godot ruft `_draw()` nur nach
  `queue_redraw()` auf und behält die Zeichenbefehle bis dahin; die Setter von `visible_from` und
  `days_per_pixel` rufen es deshalb selbst auf.
- **Reihenfolge heißt Ebene:** Was später gezeichnet wird, liegt oben. Spalte und Achse kommen
  nach den Marken; was beim Verschieben oder Rollen darunter gerät, verschwindet.
  `clip_contents = true` schneidet am Rand des Controls ab.
- **Nur, was zu sehen ist:** `_is_shown()` überspringt Marken außerhalb der Zeitfläche,
  `bsearch()` in `_draw_lines()` springt zur ersten sichtbaren Jahres- oder Monatsgrenze. Mit 500
  erzeugten Ereignissen braucht ein Bild beim Zoomen und Ziehen im Mittel rund 3 ms.
- **Tag ↔ Pixel:** `day_to_x()` und `x_to_day()` sind eine Gerade: x = Breite der Spalte +
  (Tag − `visible_from`) / `days_per_pixel`. Ein Tag d belegt die Strecke von d bis d + 1, ein
  Punkt steht bei d + 0,5. `_zoom_at()` merkt sich den Tag unter der Maus, ändert den Zoom und
  setzt `visible_from` so, dass derselbe Tag wieder unter der Maus liegt.
- **Stapeln:** `_stack()` rechnet in Pixeln ab dem 01.01.1985, nicht ab dem linken Rand. Darum
  ändert Verschieben nichts am Stapel, Zoomen schon. Die Marken kommen nach ihrem Anfang dran,
  jede nimmt die erste Unterzeile mit 6 Pixeln Platz; mehr Unterzeilen, als sich Marken an einer
  Stelle überlappen, entstehen so nie.
- **Innere Klassen:** `Mark` und `Row` sind reine Datenträger ohne Node. Sie sehen die Enums und
  Konstanten der äußeren Klasse, etwa `Shape.POINT`.
- **Theme beim eigenen Zeichnen:** `_update_theme()` holt Schrift und Größen mit
  `get_theme_default_font()` und `get_theme_font_size(&"small", &"Werkstatt")`. Godot schickt
  `NOTIFICATION_THEME_CHANGED` auch, wenn das Control in den Baum kommt. Die Farben stehen als
  Konstanten aus `UiPalette` oben in der Datei. `draw_rect()` ohne Füllung legt die Linie mittig
  auf den Rand; `_draw_outline()` baut Rahmen deshalb aus vier gefüllten Rechtecken.
- **Eine Regel an einer Stelle:** `TimelineRun.yearly_occurrences()` ist neu und öffentlich.
  `_plan_yearly()` im Lauf und `_add_marks()` im Zeitstrahl fragen beide dort, wie `_hits()` in
  Phase 3. Die Jahre begrenzt die Funktion auf 1984 bis 1999: Am Ergebnis ändert das nichts, aber
  ein Tippfehler wie 999999999 im Formular hielte sonst GameDate in einer Schleife fest.

### T048 Maus, Vorschau und Hinweise

- **`_gui_input(event)`:** Godot schickt jede Mauseingabe über dem Control dorthin, die Position
  in seinen eigenen Koordinaten. Wer gedrückt hat, bekommt Bewegung und Loslassen auch außerhalb.
  `accept_event()` hält die Eingabe von den Eltern fern.
- **Ziehen als kleiner Zustandsautomat:** `_drag` sagt, was gerade geschieht (`PAN`, `DATE`,
  `DURATION`, `WINDOW_FROM`, `WINDOW_TO`, `LOCKED`). Drücken legt es in `_start_drag()` fest,
  Bewegen zählt erst ab 3 Pixeln und rundet mit `roundi()` auf ganze Tage, Loslassen sendet einmal
  `event_moved`. Das Signal geht erst nach `_cancel_drag()` hinaus; wer daraufhin `refresh()`
  aufruft, findet einen aufgeräumten Zustand.
- **Vorschau (R16):** `_first_error()` prüft eine Kopie aus `duplicate_event()` mit dem neuen
  Wert über `CatalogValidator.validate_event()`. Katalog und Verlauf bleiben unberührt, bis die
  Werkstatt beim Loslassen `set_event_field()` aufruft; ein Cmd+Z nimmt dann das ganze Ziehen
  zurück (R15).
- **Ein Ziehen, ein Feld:** `event_moved` trägt genau ein Feld. Ein Balken hat deshalb nur rechts
  einen Griff, die Dauer; sein Beginn ist das Datum, und das verschiebt den ganzen Balken. Die
  Fläche eines Zeitfensters bräuchte zwei Felder; dort verschiebt Ziehen die Ansicht.
- **`_get_tooltip(at_position)`:** Godot fragt danach, sobald die Maus kurz stillsteht, auch ohne
  `tooltip_text`; ein leerer Text heißt: kein Hinweis. Die Probe im Fenster zeigte außerdem, dass
  Godot Hinweise nur in einem Fenster mit Fokus zeigt.
- **Doppelklick:** Godot meldet erst einen einfachen Klick, dann einen mit `double_click`. Der
  erste wählt oder verschiebt, erst der zweite legt an.
- **Menü als internes Kind:** `add_child(_menu, false, INTERNAL_MODE_FRONT)` hängt das
  `PopupMenu` an, ohne dass es in einer Szene steht. Es ist ein eigenes Fenster;
  `get_screen_transform() * at` rechnet die Stelle samt Bildschirmfaktor um. Mit Faktor 2 sitzt
  es an der Maus.
- **Mauszeiger und Fokus:** `mouse_default_cursor_shape` wechselt je nach Griff, und Godot zeigt
  den neuen Zeiger sofort. `_release_focus()` nimmt einem Feld im Formular beim Klick den Fokus,
  damit es seine Eingabe übernimmt, wie bei Cmd+S.

### T050 Tests

- `src/test/test_timeline_view.gd` ruft `_gui_input()` direkt mit selbst gebauten
  `InputEventMouseButton` und `InputEventMouseMotion` auf. Beim Zoomen sind Cmd und Ctrl beide
  gesetzt; `is_command_or_control_pressed()` fragt unter macOS Cmd, sonst Ctrl.
- Die neue Fixture `src/test/fixtures/catalog_us4_zeitstrahl.json` hat zwei Ereignisse am selben
  Tag, ein Zeitfenster mit einem Balken darin, ein gesetztes Ereignis mit 1 bis 2 Terminen und 365
  Tagen Abstand für V10 und von jeder Art eines. `to_json()` ergibt sie bytegleich.
- `mark_rects()`, `event_at()`, `preview_text()` und `preview_issue()` sind öffentlich: Tests
  fragen, wo eine Marke liegt und was am Mauszeiger stünde, statt Pixel zu raten.
- **Fehlerprobe:** In einer Kopie außerhalb des Repos wurden nacheinander 16 Fehler eingebaut, etwa
  „kein Stapeln“, „Vorschau ändert den Katalog“ oder „Ränder vertauscht“. „Abschneiden statt
  Runden“ fiel zuerst nicht auf; dafür gibt es jetzt `test_ziehen_rundet_auf_den_naechsten_tag`.
  Seitdem lassen 15 Fehler Tests scheitern, und „Jahre ohne Grenze“ lässt den Lauf hängen.
- **Bilder im Fenster:** Unter macOS zeichnet Godot nicht, solange sein Fenster verdeckt ist; die
  Bildschirmfotos kamen erst mit dem Fenster im Vordergrund.

### T049 Der Zeitstrahl in der Werkstatt

- **Skript an einen vorhandenen Node:** In `src/tools/werkstatt/werkstatt.tscn` stand schon ein
  `Control` namens `TimelineView` mit eindeutigem Namen. Es bekommt nur
  `script = ExtResource("6_timeline")`; `%TimelineView` findet es wie vorher, und die
  Mindesthöhe von 220 bleibt. Ein Skript, das von `Control` erbt, passt an jeden Control-Node.
  `size_flags_vertical = 3` lässt den Zeitstrahl im `VSplitContainer` die Höhe mit der Prüfung
  teilen.
- **Verdrahtung wie bei der Liste:** `_connect_signals()` in `werkstatt.gd` verbindet die Signale
  nach oben. `event_moved` geht direkt an `editor.set_event_field`; die Parameter passen eins zu
  eins, also braucht es keine Zwischenfunktion. Von oben ruft `_on_catalog_changed()`
  `refresh()` und `_on_selection_changed()` `select_event()` auf.
- **Ein Ziehen, ein Schritt:** `event_moved` kommt erst beim Loslassen, deshalb entsteht genau eine
  Aktion im Verlauf, und Cmd+Z nimmt das ganze Ziehen zurück (US4, Szenario 7).
- **Doppelklick über den Dialog:** `create_requested` öffnet den Dialog „Neu …“ der Liste
  vorbelegt. Angelegt wird erst mit „Anlegen“, und von dort geht es über `event_created` weiter
  wie bei jedem neuen Ereignis; ein versehentlicher Doppelklick legt nichts an.
- **Tests headless:** Das Fenster ist dort 640 × 360 groß, neben Liste und Formular bleibt dem
  Zeitstrahl keine Breite. `test_werkstatt_scene.gd` gibt ihm deshalb selbst eine Größe und
  prüft ohne `await`: Der Container ordnet seine Kinder erst im nächsten Bild neu
  (`queue_sort()`). Wo es nur um die Verdrahtung geht, senden die Tests die Signale direkt.

### Ergänzungen: Trackpad, vorbelegter Dialog, Fehlerfarbe

- **Trackpad:** macOS meldet Wischen mit zwei Fingern als `InputEventPanGesture` mit `delta`,
  positiv wie das Mausrad nach unten bzw. rechts, und Kneifen als `InputEventMagnifyGesture` mit
  einem `factor` um 1. Beide erben von `InputEventWithModifiers`, Cmd fragt also wieder
  `is_command_or_control_pressed()`. Die Empfindlichkeit steht in `GESTURE_STEPS`, eine Einheit
  zählt wie eine halbe Raste, und in `MAGNIFY_POWER`. `_zoom_to()` ist das gemeinsame Zoomen um
  eine Stelle für Mausrad, Cmd+Wischen und Kneifen.
- **Rollleiste aus dem Code:** `_scroll.value += …` genügt. Die `ScrollBar` begrenzt den Wert selbst
  auf 0 bis `max_value − page` und meldet `value_changed`, worauf der Zeitstrahl neu zeichnet.
- **Vorgabewerte statt zweier Methoden:** `EventList.open_new_dialog(kind, category, day)` hat für
  alles Vorgaben. Der Knopf „Neu …“ ruft dieselbe Methode über `pressed.connect(open_new_dialog)`
  ohne Argumente auf; ein Signal ohne Parameter darf eine Methode mit lauter Vorgabewerten
  aufrufen.
- **Zeile ein- und ausblenden:** Die Datumszeile im `GridContainer` des Dialogs sind zwei Labels,
  die zusammen sichtbar werden, solange ein Tag vorbelegt und die Art „fix“ ist. Unsichtbare
  Kinder überspringt der Container, die beiden Spalten bleiben gerade.
- **Fehlerfarbe statt Magenta:** `_row_color()` gibt der Zeile „Ohne Kategorie“ und Kategorien mit
  falscher Farbe (V21) kassenrot, die Rolle Fehler. `UiPalette.by_token()` gäbe für ein
  unbekanntes Token Magenta, und das ist keine Farbe der Palette.
- **Fehlerprobe:** 14 weitere eingebaute Fehler, etwa „Zeitstrahl nicht neu“, „Dialog nicht
  vorbelegt“ oder „Kneifen verkehrt“, ließen jeweils mindestens einen Test scheitern.

### Waagerechte Leiste

- **Synchron ohne Rückkopplung:** Die `HScrollBar` ist ein internes Kind wie die senkrechte
  Leiste. `value` ist `visible_from`, `page` sind die sichtbaren Tage, `max_value` die 5478 Tage.
  Zieht Klaus an ihr, setzt `_on_hscroll_changed()` `visible_from`. Ändert sich die Ansicht auf
  anderem Weg, stellt der Setter von `visible_from` die Leiste über `_sync_hscroll()` nach, mit
  `set_value_no_signal()`. Das meldet kein `value_changed`, also ruft die Leiste die Ansicht
  nicht wieder auf. Muss `Range` beim Ändern von `page` den Wert begrenzen, meldet es das aber
  von sich aus; diesen Fall fängt die Sperre `_syncing_hscroll` ab.
- **Platz statt Überdecken:** `time_rect()` endet über der Leiste, und Zeilen, Raster und
  senkrechte Leiste rechnen damit. Ein Streifen Grund unter der Zeitfläche deckt zu, was eine
  halb sichtbare Zeile dorthin zeichnen würde. Alle Leisten der Werkstatt sind 8 Pixel breit,
  auch die von Tree und ScrollContainer.

### Zoom-Knöpfe

- **Knöpfe in einem selbst zeichnenden Control:** „−“, „+“ und „Alles“ sind echte `Button` als
  interne Kinder, wie die Leisten. Sie zeichnen sich nach `_draw()` des Zeitstrahls, also über
  der Ecke, und bekommen Relief, Kontur und Sperrzustand aus dem Theme. Weil der Zeitstrahl kein
  Container ist, setzt `_layout_buttons()` Größe und Lage selbst.
- **Erst messen, wenn das Theme da ist:** Die Mindestgröße eines Knopfs stimmt erst, wenn er sein
  Theme kennt, und das ist nach dem Zeitstrahl selbst. Gemessen ohne Theme waren es 14 × 22
  Pixel, mit Theme 27 × 29. Deshalb meldet jeder Knopf `minimum_size_changed` an
  `_on_parts_resized()`, wie die Leisten. Die Spalte wird nur so breit, wie Namen oder Knöpfe es
  verlangen; beim echten Katalog sind beides 118 Pixel.
- `focus_mode = FOCUS_NONE` lässt einem Feld im Formular seinen Fokus. Die Knöpfe sperren sich an
  den Grenzen über `disabled`, das der Setter von `days_per_pixel` nach jedem Zoom nachstellt.

## Phase 7

### T052 Der Simulator

- **Feste Teile in der Szene, Zeilen im Code:** `src/tools/werkstatt/simulator_panel.tscn` hält
  Knöpfe, Felder, Hinweise und die beiden Tabellen; die Zeilen legt `simulator_panel.gd` an, denn
  sie hängen am Lauf. Mit `unique_name_in_owner` findet `%SeedEdit` sein Feld, egal wo es steht.
- **Ein eigener Lauf statt der Spieluhr:** `generate_plan()` legt
  `TimelineRun.new(editor.catalog.without_faulty(editor.issues()), seed)` an. Der Lauf kopiert den
  Katalog in `_init()` selbst, spätere Änderungen erreichen ihn nicht. Das Panel nennt weder
  `GameClock` noch `Timeline`; dass es die Uhr nicht anfasst, folgt schon daraus.
- **Schritte wie die Spieluhr:** `_first_of_next_month()` und `_first_of_next_year()` rechnen wie
  `GameClock.advance_one_month()` bis zum nächsten Ersten. Vor dem ersten Schritt steht der Lauf
  auf −1, dem 31.12.1984 (negative Tage seit T007); deshalb landet jeder erste Schritt auf dem
  01.01.1985. `play_until()` ruft `advance_to()`, das von Stichtag zu Stichtag springt (R6):
  „Bis zum Ende“ dauert mit dem echten Katalog rund 21 ms, samt Tabelle und Protokoll.
- **Seed-Feld:** Ein `LineEdit` meldet `text_changed` erst am Ende des Bilds, einmal für alles, was
  in diesem Bild getippt wurde (Probe). `_on_seed_changed()` wirft dort Nicht-Ziffern hinaus und
  begrenzt auf 2.147.483.647; gezeichnet ist bis dahin nichts. Das Setzen von `text` meldet sich
  nicht noch einmal.
- **„Katalog geändert“:** `_catalog_key()` ist der Katalog als kanonischer Text plus die Kennungen,
  die `without_faulty()` auslässt. Stimmt er nicht mehr mit dem beim Erzeugen überein, erscheint
  der Hinweis; macht Klaus die Änderung rückgängig, verschwindet er wieder. `refresh()` merkt den
  Vergleich per `call_deferred()` vor, so kosten die zwei Signale je Änderung nur einen.
- **Zebra von Hand:** Eine Probe im Fenster zeigte, dass `Tree` und `ItemList` die eigene Farbe
  einer Zelle über Auswahl und Überfahren malen; eine grüne Zeile verdeckte das petrol der Auswahl.
  `Zebra` setzt deshalb alle drei Farben selbst mit `set_custom_bg_color()`, zuerst als innere
  Klasse, inzwischen in eigener Datei (siehe unten). Das Signal `gui_input` kommt, bevor der Tree
  die Maus verarbeitet; `get_item_at_position()` sucht die Zeile darunter einmal je Bild.
- **Protokoll ohne Umbruch:** Mit `TreeItem.set_autowrap_mode()` kennt der Tree die Höhe einer
  Zeile erst, nachdem er sie gezeichnet hat, und `scroll_to_item()` landete mitten im Protokoll
  (Probe). Jede Meldung bleibt eine Zeile wie `to_line()`, zu lang endet sie mit „…“, ganz steht
  sie im Hinweis.
- **Typvariante für das Fehlerfeld:** `ErrorNoticeLabel` in `werkstatt_theme.tres` gibt einem
  `Label` einen `normal`-Kasten in kassenrot und Text in papier: der Fehler als gefülltes Feld.
  Die Warnung „Katalog geändert“ nutzt das vorhandene `WarningLabel`.
- **Vorhandene Helfer:** `EventForm.parse_date()` und `format_date()` lesen und schreiben
  „1.3.1993“, die Begründung kommt aus `ScheduleEntry.explain()` und `due_effects()`, das
  Protokoll aus `TimelineMessage.to_line()`.

### T053 Der Simulator in der Werkstatt

- **Teilszene als Reiter:** `src/tools/werkstatt/werkstatt.tscn` setzt `simulator_panel.tscn` als
  Kind von `Tabs` ein. Ein `TabContainer` macht aus jedem Kind einen Reiter und nimmt den Namen des
  Knotens als Titel; `set_tab_title(get_tab_idx_from_control(...), "Simulator")` gibt ihm den
  richtigen.
- **Verdrahtung wie bei den anderen Teilen:** Die Werkstatt gibt dem Panel ihren `editor` und ruft
  `refresh()` nach `catalog_changed` und nach `issues_changed`. Das zweite braucht es fürs
  Speichern: Danach fallen die Meldungen beim Lesen weg, und ein neuer Lauf nähme andere
  Ereignisse aus. Weil beide Signale nach jeder Änderung kommen, fällt das Fehlen des ersten in
  keinem Test auf; es bleibt trotzdem, denn der Hinweis gehört zur Änderung am Katalog.
- **Auswahl folgt:** `event_selected(id)` wählt das Ereignis in Liste, Formular und Zeitstrahl,
  aber nur, wenn es im Katalog noch steht; der Lauf rechnet mit einer älteren Kopie.

### T054 Tests

- **Tippen im Test:** `get_viewport().push_input()` mit einem `InputEventKey`, das nur `unicode`
  trägt, schreibt ins Feld mit dem Fokus; `text_changed` kommt am Ende des Bilds, deshalb
  `await wait_process_frames(1)`.
- **Autoloads über ihren Pfad:** `get_node(^"/root/GameClock")` statt `GameClock`. Den Namen kennt
  GDScript erst, wenn Godot das Autoload angelegt hat; `--check-only -s` übersetzte das Testskript
  früher und meldete „Identifier not found: GameClock“.
- **Protokoll gleich Textausgabe:** Der Test baut den Lauf wie `fahrplan_ausgabe.gd` (lesen,
  prüfen, `without_faulty()`) und spielt ihn in einem Zug; der Simulator spielt in Schritten.
  Gleiche Zeilen belegen damit auch SC-002 in der Werkstatt.
- **Messen:** `test_bis_zum_ende_dauert_unter_einer_sekunde` misst an der eingefrorenen Übernahme
  rund 11 ms; den echten Katalog lassen die Tests aus (R20). Mit ihm im Fenster: 21 ms, bis Tabelle
  und Protokoll stehen, 44 ms bis zum gezeichneten Bild (SC-004: unter 1 Sekunde).
- **Fehlerprobe:** 22 eingebaute Fehler in einer Kopie außerhalb des Repos, etwa „Buchstaben im
  Seed“, „Auswahl ohne petrol“ oder „Simulator stellt die Spieluhr“; 21 ließen Tests scheitern.
  „+1 Monat sind 30 Tage“ fiel zuerst nicht auf, weil der Test vom 02.01. aus sprang; jetzt springt
  er auch von der Mitte eines Monats.
- **Bilder im Fenster:** Ein Testgerüst, das „Fahrplan erzeugen“ und „Bis“ im selben Bild drückt,
  sieht anderes als Klaus: Der rote Hinweis verkleinert die Tabelle erst am Ende des Bilds, nach
  `scroll_to_item()`. Zwischen zwei Klicks wartet das Gerüst deshalb ein paar Bilder.

### Eine Klasse für alle Tabellen

- **Eigene Datei mit `class_name`:** `src/tools/werkstatt/zebra.gd` ist ein `RefCounted` ohne Node,
  das sich an die Signale eines `Tree` hängt. Liste, Prüfung und beide Tabellen des Simulators
  legen je eins an und halten es in einer Variablen; eine Signalverbindung allein hielte es nicht
  am Leben.
- **Zellen mit eigener Bedeutung:** `keep_cell()` merkt sich eine Farbe je Zelle, die `paint()` nie
  übermalt: das „!“ in kassenrot und das „?“ auf papier. Holz steht nur auf papier lesbar, auf
  petrol kaum; deshalb behält auch die Warnung ihren Grund in einer gewählten Zeile.
- **Zwei Regeln für die Besitzer:** `forget()` vor `Tree.clear()`, sonst hielte Zebra Zeilen, die
  es nicht mehr gibt; `paint_all()` nach jeder Auswahl aus dem Code, denn `deselect_all()` sendet
  kein Signal (`EventList._highlight()`).

## Phase 8

### T056 Eingriffe im Kern

- **Fehler als Rückgabewert:** GDScript kennt keine Exceptions. Die Eingriffe in
  `src/core/timeline/timeline_run.gd` geben deshalb Godots `Error` zurück, `OK` oder etwa
  `ERR_UNAVAILABLE`, und den deutschen Grund in `last_refusal`. `_refuse()` erledigt beides in
  einem Aufruf, also ist jede Prüfung eine Zeile `return _refuse(…)`. Ob ein Aufruf geklappt hat,
  sagt nur der Rückgabewert; `last_refusal` bleibt bis zur nächsten Ablehnung stehen.
- **Eingriffsprotokoll als reine Daten:** `interventions` hält Dictionaries mit Zahlen und Texten,
  keine Verweise auf Termine. So lassen sie sich ohne Umweg als JSON speichern. Absagen und
  Verschiebungen nennen Ereignis und Tag statt der laufenden Nummer, denn die Nummer ändert sich,
  sobald sich der Katalog ändert; `apply_intervention()` findet den Termin über `find_planned()`.
- **Kopie statt Verweis:** Objekte wie `ChanceModifier` werden als Verweis übergeben.
  `add_modifier()` merkt sich deshalb eine Kopie; sonst änderte ein späteres
  `modifier.value = 0.9` heimlich den Lauf, ohne Spur im Protokoll.
- **Sortiert halten:** `move_entry()` nimmt den Termin aus `entries` heraus und setzt ihn mit
  `bsearch_custom(entry, _comes_before)` neu ein, nach derselben Regel wie beim Anlegen. Der alte
  Stichtag bleibt stehen; an ihm geschieht dann eben nichts.
- **`match` über Konstanten:** `apply_intervention()` verzweigt mit `match kind:` über die
  Konstanten `INTERVENTION_*`, mehrere Muster stehen mit Komma in einer Zeile. Weil Einträge aus
  einer Datei kommen dürfen, liest `_int_of()` auch float wie `1826.0` als ganze Zahl.
- **Meldung ohne Signal:** `_accept()` hängt die Meldung `INTERVENTION` nur an `protocol`, nicht an
  die Rückgabe von `advance_to()`. Das Autoload bekommt sie deshalb gar nicht erst zu sehen.

### T057 Tests der Eingriffe

- **Nachrechnen statt festschreiben** wie in Phase 3: `catalog_us6_schwelle` hat keinen
  Mindestabstand, jeder Treffer wird ein Termin. So rechnet der Test zu Szenario 1 mit demselben
  `EventDice` jeden Monat nach, mit 8 % von 1990 bis 1993 und 3 % davor und danach.
- **Suchen statt Seeds raten:** Die Absage eines gewürfelten Termins braucht einen, der nach seiner
  Würfelrunde noch geplant ist. `_naechster_geplanter_gewuerfelter()` spielt Monat für Monat ab,
  bis es einen gibt; der Test hängt so nicht an einem Datum, das eine andere Godot-Version anders
  würfelt.
- **SC-003 parametrisiert:** `use_parameters()` lässt denselben Test einmal mit
  `catalog_us6_reklamation` laufen, deren Kundenflucht und Zeitungsartikel von der
  Reklamationswelle abhängen, und einmal mit der eingefrorenen Übernahme.
- **Fehlerprobe:** 25 eingebaute Fehler in einer Kopie außerhalb des Repos. Zwei fielen zuerst
  nicht auf: `find_planned()` ohne Blick auf den Zustand und die Reihenfolge in Schritt 1 des
  Vergleichs. Zwei Tests kamen dazu, jetzt lässt jeder der 25 Fehler Tests scheitern.

### T058 Eingriffe im Autoload

- `src/core/timeline.gd` reicht die fünf Eingriffe mit gleichen Signaturen an `run` durch; die
  Regeln stehen nur im Lauf. Ohne laufendes Spiel gibt es `ERR_UNCONFIGURED`.
- **Autoload ohne Baum:** `ZEITLEISTE.new()` mit `autofree()` kommt in `test_timeline.gd` nie in
  den Szenenbaum. `_ready()` läuft dann nicht, es gibt keinen Lauf, und genau das prüft der Test.

### T059 Vergleich zweier Läufe

- **Paaren statt Nummern vergleichen:** `ScheduleDiff.compare()` in
  `src/core/timeline/schedule_diff.gd` gruppiert beide Fahrpläne je Ereignis und paart erst am
  selben Tag, dann über `moved_from_day`. Ein Termin, den ein Modifikator dazubringt, heißt so nie
  „verschoben“.
- **Arrays sind Verweise:** `unpaired.get(event_id, [])` liefert die Liste, die im Dictionary
  steckt; `_take()` nimmt den Partner direkt daraus heraus. Was am Ende darin übrig ist, ist
  weggefallen. Termine dienen in `left` als Schlüssel eines Dictionarys, verglichen wird dabei das
  Objekt selbst.
- **Unverschobene zuerst:** Liegen an einem Tag mehr Termine als ohne Eingriffe, bekommen die
  unverschobenen den Partner am selben Tag zuerst. Der Test
  `test_verschobener_termin_auf_einem_belegten_tag` zeigt, was sonst geschähe.
- **Typ beim Ergebnis von `filter()`:** `var x := liste.filter(…)[0]` scheitert mit „Cannot infer
  the type“. `filter()` ist als `Array` ohne Elementtyp deklariert, auch auf einem typisierten
  Array; ein Element daraus hat für den Compiler keinen festen Typ. Die Variable braucht ihn dann
  ausdrücklich, `var x: ScheduleEntry = …`.

### T060 Was-wäre-wenn-Proben

- **Kanonisch wie der Katalog:** `WhatIfProbe.write_file()` in
  `src/tools/werkstatt/what_if_probe.gd` schreibt mit `JSON.stringify(data, "\t", true)` und
  `"format": 1`. Lesen und wieder schreiben ergibt bytegleichen Text (siehe auch die Nacharbeiten
  unten: Tage als Datum).
- **Neu abspielen statt Fahrplan speichern:** `build_run()` spielt den Lauf bis zum `at_day` jedes
  Eingriffs und wendet ihn dort an. Ein gewürfelter Termin entsteht erst in seiner Würfelrunde;
  vor Spielbeginn angewandt, ginge seine Absage ins Leere.
- **`res://` und `user://`:** In `res://` schreiben geht nur, solange das Spiel aus dem Projekt
  läuft, nicht im Export; für Proben unter `tools/` reicht das. Die Tests schreiben nach `user://`,
  in den Benutzerordner außerhalb des Projekts, und räumen in `after_each()` auf.
- **Kleine Bordmittel:** `DirAccess.get_files_at()` listet den Ordner, `String.path_join()` setzt
  Pfade ohne doppelten Schrägstrich zusammen, `naturalnocasecmp_to()` sortiert „Probe 2“ vor
  „Probe 10“, und `duplicate(true)` kopiert auch die Dictionaries im Eingriffsprotokoll.
- **Namen und Warnungen:** `from_run(name, …)` heißt laut Vertrag wie das Feld `name`;
  `@warning_ignore("shadowed_variable")` hält den Start mit `-d` still. In den Tests heißt die
  Schleifenvariable dagegen `titel`, denn `GutTest` erbt von `Node`, und `Node` hat schon `name`.
- **`.gitkeep`:** Git versioniert nur Dateien. Die leere `proben/.gitkeep` hält den Ordner im
  Repository, bis die erste Probe dort liegt.

### Nacharbeiten nach dem Review

- **Eine Regel, öffentlich:** `CatalogEditor.id_from()` und `CatalogEditor.unique_id()` in
  `src/tools/werkstatt/catalog_editor.gd` sind jetzt öffentliche statische Funktionen. `static`
  heißt: aufrufbar über den Klassennamen, ohne Objekt. So nutzen `suggest_id()`, das Duplizieren,
  neue Kategorien und `WhatIfProbe.from_run()` dieselbe Regel, ohne dass eine fremde Klasse eine
  private Funktion aufruft; der Unterstrich ist in GDScript nur Absprache, kein Schutz.
- **Lesbare Probedateien:** In der Datei stehen alle Tage als „JJJJ-MM-TT“ wie im Katalog, −1
  als „1984-12-31“. Im Speicher bleiben es Tagesindizes, damit `interventions` genau das
  Dictionary ist, das `TimelineRun` hält. Umgesetzt wird nur an der Grenze zur Datei:
  `_to_file()` beim Schreiben, `_from_file()` beim Lesen, beide rekursiv auch für den Modifikator
  darin. `GameDate.to_iso()` und `from_iso()` sind dafür genau umkehrbar.
- **Format zuerst:** `read_file()` prüft `"format"` vor allem anderen und lehnt eine Datei ohne
  Format oder mit einem anderen per `push_error()` ab; in einer anderen Version können alle
  übrigen Schlüssel anders aussehen.
- **Ein falsches Datum kostet nur seinen Eintrag:** Steht etwa „1992-02-30“ oder eine Zahl in
  einem Eintrag, übernimmt `read_file()` ihn nicht und nennt ihn in `not_applicable`, die übrigen
  gelten. Gewählt statt `push_error()`, weil `not_applicable` in der Werkstatt sichtbar ist,
  `push_error()` nur in der Konsole. Damit `build_run()` die Liste neu füllen kann, ohne die
  Lesefehler zu verlieren, hält die Probe sie in `_read_problems` und stellt sie jedes Mal voran.

### T061 Eingriffe im Simulator

- **Ein Dialog für vier Eingriffe:** `InterventionDialog` in
  `src/tools/werkstatt/intervention_dialog.gd` erbt von `ConfirmationDialog` und blendet je nach
  `Kind` Zeilen seines `GridContainer` ein und aus. Ausgeblendet wird immer ein Paar aus
  Beschriftung und Feld; ein einzelnes verschöbe alle folgenden Zellen um eine Spalte.
- **Der Dialog fragt, der Lauf entscheidet:** Beim Öffnen bekommt der Dialog ein Callable
  `apply`, das die Werte nimmt und den Grund einer Ablehnung zurückgibt, wie `_line()` im
  Formular. Mit `dialog_hide_on_ok = false` bleibt er nach „OK“ offen und schließt erst bei
  Erfolg. So steht `last_refusal` da, wo Klaus korrigieren kann, etwa „… ist fix und lässt sich
  weder absagen noch verschieben.“
- **Gesammelt, nicht kopiert:** `_after_intervention()` in `simulator_panel.gd` hängt nach jedem
  angenommenen Eingriff den letzten Eintrag von `run.interventions` mit `duplicate(true)` an
  `probe.interventions`. Ersetzt wird die Liste nie durch `run.interventions`; nach `build_run()`
  stehen dort nur die anwendbaren.
- **Kennung aus dem Grund:** `CatalogEditor.unique_id(CatalogEditor.id_from(grund, "modifikator"),
  vergeben)`. Vergeben sind die Kennungen im Lauf und in den gesammelten Eingriffen; sonst lehnte
  ein Neustart mit Eingriffen den zweiten Modifikator mit gleichem Grund ab.
- **Protokoll aus `run.protocol`:** Die Meldung eines Eingriffs kommt nicht aus `advance_to()`.
  `_sync_protocol()` zeigt deshalb alles, was in `run.protocol` hinter `_protocol_count` neu ist,
  nach Schritten wie nach Eingriffen.
- **Rechtsklick in der Tabelle:** Mit `allow_rmb_select` wählt der Tree auch mit der rechten
  Taste, danach kommt `item_mouse_selected(position, button)`; dort öffnet das `PopupMenu` an der
  Maus wie im Zeitstrahl.
- **Geerbte Namen nicht überdecken:** Mit `-d` warnt GDScript, wenn eine lokale Variable so heißt
  wie eine geerbte Eigenschaft. Im Dialog wäre das `title` (von `Window`), im Test `name` (ein
  `GutTest` ist ein `Node`). Deshalb heißen sie `shown` in `_entry_text()` und `pfad` oder
  `probenname` in `test_simulator.gd`.

### T062 Unterschiede und Proben

- **Gegenlauf:** Hat der Lauf Eingriffe, legt `_update_diff()` einmal
  `TimelineRun.new(run.catalog, run.seed)` an und spielt ihn bei jedem Schritt bis `run.today` mit;
  `ScheduleDiff.compare()` vergleicht beide. Der Gegenlauf nimmt den Katalog des Laufs, nicht den
  der Werkstatt, damit beide mit demselben rechnen.
- **Spalten zur Laufzeit:** `Tree.columns` lässt sich ändern. `_fill_plan()` stellt vier oder fünf
  Spalten ein, mit „Unterschied“ schmalere feste, damit das Ereignis lesbar bleibt.
- **Zeichen statt nur Farbe:** „+ neu“, „→ verschoben“, „≠ Zustand“, „− weggefallen“. Eine eigene
  Farbe für Unterschiede kennt der Style-Guide nicht, also gibt es keine.
- **Durchstreichen auf einer Ebene darüber:** Proben im Fenster zeigten zweierlei. Ein Callback in
  `CELL_MODE_CUSTOM` zeichnet vor dem Hintergrund der Zelle, und auch das Signal `draw` des Tree
  landet unter den Zeilen, denn der Tree malt sie auf eine eigene Ebene über sich. Darüber liegen
  nur Kinder, wie seine Rollleisten. `_strike_overlay` ist so ein Kind: ein `Control` mit
  `INTERNAL_MODE_FRONT` und `MOUSE_FILTER_IGNORE`. Es malt neu, sobald der Tree malt
  (`draw.connect(queue_redraw)`), im selben Bild, auch beim Rollen. Die Lage jeder Zelle samt
  Rollen liefert `get_item_area_rect()`. Nebenbei: `set_cell_mode()` leert den Text einer Zelle;
  erst die Art setzen, dann den Text.
- **Weggefallene an ihrem Tag:** `_plan_rows()` mischt `run.entries` und `ScheduleDiff.removed`
  nach Tag. Ihre Metadaten sind −1 − ihre Stelle in `removed`; laufende Nummern sind ab 1.
- **Proben:** „Probe speichern …“ schreibt die gesammelten Eingriffe mit Seed und `run.today`
  nach `probe_folder`; gibt es die Kennung schon, fragt ein zweiter Dialog „Überschreiben?“.
  „Probe löschen“ meint die zuletzt gespeicherte oder geladene. Die Tests setzen `probe_folder`
  auf einen Ordner unter `user://`.
- **Tests und Fehlerprobe:** Die neuen Tests stehen in `src/test/test_simulator.gd`, damit
  `test_werkstatt_scene.gd` nicht weiter wächst. 18 eingebaute Fehler in einer Kopie außerhalb des
  Repos, etwa „Neustart nimmt run.interventions“ oder „Ablehnung schließt den Dialog“, ließen
  jeweils mindestens einen Test scheitern.
- **Knöpfe, die zusammen umbrechen:** Die drei Proben-Knöpfe stehen in einem eigenen
  `HBoxContainer` in der `HFlowContainer`-Leiste; so bricht die Leiste sie nur gemeinsam um.
  `sort_children` kommt, wenn der Container seine Kinder verteilt hat, erst dann stehen ihre
  Positionen fest. Ein Trennstrich ohne Nachbarn in seiner Zeile wird durchsichtig statt
  unsichtbar, damit sich das Layout nicht selbst umwirft.

## Phase 9

### T064 Statistik nach Zeitbudget

- **Häppchen statt Thread:** `run_for(budget_msec)` in `src/core/timeline/timeline_statistics.gd`
  setzt mit `Time.get_ticks_usec()` eine Frist und spielt das laufende Spiel Monat für Monat weiter
  (`_play_month()`), danach das nächste. Die Zeit prüft es nach jedem Monat, also kehrt es höchstens
  um einen Schritt zu spät zurück; gemessen 15,0 bis 16,4 ms bei 15 ms Budget. Was zwischen zwei
  Aufrufen gilt, steht in Variablen: das angefangene Spiel `_run`, `games_done` und die Zählung. Es
  gibt keinen Thread und deshalb nichts, was vor gleichzeitigem Zugriff geschützt werden müsste
  (R17).
- **Erst fertig, dann gezählt:** `_count_game()` läuft nur nach `is_finished()`. `results()` sieht
  nie ein halbes Spiel, und ein Abbruch verliert nur das angefangene. `results()` gibt Kopien
  heraus; was die Werkstatt daran ändert, erreicht die Rechnung nicht.
- **Feste Seeds:** Spiel n hat den Seed `first_seed + n`, also 1 bis 1.000. Dieselbe Rechnung
  ergibt dasselbe Ergebnis, in Häppchen von einem Monat wie am Stück.
- **Eingriffe wie beim Neu abspielen:** `_seed_free()` nimmt aus dem Protokoll `add_modifier`,
  `remove_modifier` und `schedule` und kopiert sie mit `duplicate(true)`. Vor jedem Monat wendet
  `_play_month()` die an, deren `at_day` in diesen Monat fällt: erst `advance_to(at_day)`, dann
  `apply_intervention()`, genau wie `WhatIfProbe.build_run()`. Ein Modifikator, den Klaus im
  Simulator am 31.12.1989 entfernt hat, wirkt so in jedem Spiel bis zu diesem Tag.
- **Kern ohne Werkzeug:** `TimelineStatistics` liegt unter `src/core/timeline/` und kennt
  `WhatIfProbe` nicht. Die liegt unter `tools/` und fehlt im Export; das Spiel könnte die
  Statistik sonst nicht laden.
- **Packed Arrays als Verweis:** `_statistics[index].per_year[jahr] += 1` zählt direkt im
  `PackedInt32Array` des Objekts. In Godot 4.7 werden Packed Arrays wie Arrays als Verweis
  weitergegeben: Nach `var b := a` ändert `b[0] = 5` auch `a` (Probe). Eine eigene Kopie gibt es
  nur mit `duplicate()`; deshalb gibt `_copy()` für `results()` `per_year.duplicate()` heraus.
- **Fehlerhafte Ereignisse nimmt der Aufrufer aus:** Die Statistik bekommt den Katalog wie
  `TimelineRun` schon aus `without_faulty()`. Prüfte sie ihn noch einmal, wäre jede Bedingung auf
  ein ausgenommenes Ereignis eine Meldung V15, und das Ereignis mit der Bedingung fiele auch weg;
  das Spiel behält es. Prüfte sie dagegen statt des Aufrufers, fehlten ihr die Meldungen beim
  Lesen (V22), die der Simulator ausnimmt.
- **Obergrenze an einer Stelle:** `upper_limit(event)` ist statisch, damit Rechnung und Tabelle
  dieselbe Regel nutzen: Höchstzahl bei `CHANCE`, `count_min` + Zahl der Gewichte − 1 bei `PRESET`,
  sonst −1.

### T065 Tests der Statistik

- **Gegenprobe statt Sollwerte:** `_pruefe_zaehlung()` in `src/test/test_timeline_statistics.gd`
  rechnet dieselben Seeds einzeln mit `TimelineRun` und vergleicht jede Zahl. Drei Kataloge decken
  dabei entfallene Termine (US3) und am Ende noch geplante (US1) ab; beide dürfen nicht zählen.
- **Monat für Monat:** `run_for(0)` rechnet genau einen Monat. Nach 179 Aufrufen ist das erste
  Spiel noch nicht fertig, nach dem 180. schon; das belegt die Monatsschritte genauer als eine
  Zeitmessung. Die Zeitmessung selbst misst zuerst den längsten einzelnen Schritt und erlaubt dann
  15 ms plus diesen Schritt plus 10 ms, weil der Rechner nebenher anderes tut.
- **Eingriffe aus einem echten Lauf:** Die Tests setzen Modifikatoren, Einplanung, Absage und
  Verschiebung an einem `TimelineRun` und geben dessen `interventions` weiter, so wie der Simulator
  sie sammelt.
- **Test-Kataloge:** `src/test/fixtures/catalog_us7_*.json`, einmal mit `EventCatalog` gelesen und
  wieder geschrieben, damit sie kanonisch sind.
- **Laufzeit:** SC-008 mit 1.000 Spielen dauert 3,3 s, denn ein Spiel mit 90 Beginnen braucht im
  Kern rund 3 ms. Zwei Schleifen über alle Termine eines Ereignisses, `_may_start_again()` und
  `_running_entry()`, kosten davon rund 40 % (Probe außerhalb des Repos); ein Kandidat für
  Phase 10 und SC-011.
- **Fehlerprobe:** 23 eingebaute Fehler in einer Kopie außerhalb des Repos, etwa „Seeds ab 0“,
  „Absagen gelten“, „Zeit nur nach jedem Spiel geprüft“, „Wert auf dem Balken“ oder „Werkstatt
  gibt keine Eingriffe weiter“. „Geplante zählen mit“ fiel zuerst nicht auf; seit der Zähltest
  auch `catalog_us1_spielende.json` rechnet, lässt jeder der 23 einen Test scheitern.

### T066 Die Statistik in der Werkstatt

- **await als Pause:** `_calculate()` in `src/tools/werkstatt/statistics_panel.gd` rechnet
  `run_for(15)` und wartet dann mit `await get_tree().process_frame`. Dort gibt die Funktion die
  Kontrolle an Godot zurück: Der Rest des Bilds läuft, Eingaben und Zeichnen eingeschlossen, und
  zu Beginn des nächsten Bilds geht es hinter dem `await` weiter. `start()` ruft `_calculate()`
  ohne `await` auf; so kehrt `start()` beim ersten `await` zurück, und die Schleife läuft allein
  weiter.
- **Abbrechen ohne Flag von außen:** Nach jedem `await` prüft die Schleife, ob `statistics` noch
  ihre Rechnung ist und `_running` gilt. Ein Abbruch oder ein neuer Start beendet die alte Schleife
  so beim nächsten Bild, ohne dass jemand sie anhalten muss; `cancel()` zeigt das Ergebnis sofort.
- **Freigabe mitten im Warten:** Wird der Knoten freigegeben, während die Koroutine wartet,
  verwirft Godot sie still (Probe). Nur wenn das im selben Signal geschieht, das sie gerade wecken
  will, meldet Godot „Resumed function '_calculate()' after await, but class instance is gone“. Der
  Test, der mit „Abbrechen“ endet, wartet deshalb noch ein Bild.
- **Ein Callable statt eines Verweises:** `interventions_source` ist ein `Callable`, das die
  Werkstatt auf `_simulator_interventions()` setzt; das liefert `probe.interventions` des
  Simulators. Das Panel holt das Protokoll erst beim Start, und die beiden Panels kennen sich nicht
  (Datenfluss der Werkstatt).
- **Fortschrittsbalken ohne Text auf der Fläche:** Ein `ProgressBar` mit `show_percentage = false`;
  „45 % · 450 von 1.000 Spielen · 3,8 s“ steht im Label daneben. Die Kästen `background` und
  `fill` kommen neu aus `werkstatt_theme.tres`: papier mit tusche-Kontur, gefüllt in petrol.
  `test_werkstatt_theme.gd` prüft sie mit, ohne Änderung.
- **Zeichnen über ein Signal:** Das Diagramm ist ein schlichtes `Control` in der Szene. Das Panel
  hängt `_draw_years()` an dessen Signal `draw` und zeichnet mit `draw_rect()` und `draw_string()`
  auf dessen Fläche, wie `_strike_overlay` im Simulator; eine eigene Klasse braucht es nicht.
- **Rechnen und Zeichnen getrennt:** `year_bars()` rechnet Lage, Farbe und Text jedes Balkens,
  `_draw_years()` zeichnet nur, was es liefert. Headless zeichnet Godot nichts Sichtbares; die
  Tests prüfen deshalb die Rechtecke, etwa dass kein Text auf einem Balken liegt. Die Farbe ist die
  der Kategorie, bei einer unerlaubten kassenrot wie im Zeitstrahl.
- **Zahlen in der Tabelle:** `TreeItem.set_text_alignment()` setzt die Zahlen rechtsbündig, die
  Köpfe folgen mit `set_column_title_alignment()`, und `set_column_title_tooltip_text()` erklärt
  jede Spalte. Ohne Obergrenze steht „–“.
- **Katalog geändert:** wie im Simulator über `_catalog_key()`. Die Rechnung hat ihre eigene
  Kopie: `TimelineStatistics` kopiert den Katalog, jeder `TimelineRun` noch einmal.
- **Messung (SC-004):** 1.000 Spiele mit dem echten Katalog dauern headless 7,9 s, im Fenster vom
  Start bis 100 % 8,6 s. Ein Bild dauert dabei im Median 17 ms, 95 % unter 18 ms; das längste mit
  46 ms ist das, in dem „Starten“ gedrückt wird.
