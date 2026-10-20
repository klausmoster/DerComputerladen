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
