# Vertrag: Zeitleisten-Werkstatt

Technischer Vertrag zu [spec.md](../spec.md) (US2, US4 bis US7), Entscheidungen in
[research.md](../research.md) (R13 bis R17, R22 bis R24), Kern in [zeitleiste.md](zeitleiste.md).
Die Werkstatt ist ein Entwicklungswerkzeug und gehört nicht zum Spiel; ihr Look folgt dem Abschnitt
„Werkzeuge“ im Style-Guide, der vor ihrem Bau entsteht (Verfassung, Grundsatz IV).

## Dateien

```text
src/tools/werkstatt/                  # ganzer Ordner vom Export ausgeschlossen
├── werkstatt.tscn / werkstatt.gd     # Wurzel, class_name Werkstatt
├── werkstatt_theme.tres              # Theme nach Style-Guide „Werkzeuge“
├── catalog_editor.gd                 # class_name CatalogEditor, ohne Oberfläche
├── event_list.tscn / event_list.gd   # class_name EventList
├── event_form.tscn / event_form.gd   # class_name EventForm
├── timeline_view.gd                  # class_name TimelineView
├── issues_panel.gd                   # class_name IssuesPanel
├── simulator_panel.tscn / .gd        # class_name SimulatorPanel
├── statistics_panel.tscn / .gd       # class_name StatisticsPanel
├── intervention_dialog.tscn / .gd    # class_name InterventionDialog: Modifikator, Verschieben, Einplanen
├── what_if_probe.gd                  # class_name WhatIfProbe: Probe lesen, schreiben, anwenden
├── proben/                           # gespeicherte Was-wäre-wenn-Proben, eine JSON-Datei je Probe
└── fahrplan_ausgabe.gd               # Textausgabe, siehe zeitleiste.md

src/test/
├── test_catalog_editor.gd            # Bearbeiten, Kennungen, Verweise, Rückgängig, Speichern, Sicherung
├── test_what_if_probe.gd             # Speichern, Laden, nicht anwendbare Eingriffe
└── test_werkstatt_scene.gd           # Rauchtest: Szene baut headless ohne Fehler auf
```

## Start und Fenster

- Start im Editor mit F6, wenn `werkstatt.tscn` offen ist, oder im Terminal:

  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --path src res://tools/werkstatt/werkstatt.tscn
  ```

- Nur für Prüfungen wie SC-011 nimmt sie nach `--` einen anderen Katalog an:
  `… werkstatt.tscn -- --katalog res://test/fixtures/catalog_500.json`.
- `Werkstatt._ready()` richtet, außer headless, das Fenster ein (R13):
  - `get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED`;
  - `get_window().mode = Window.MODE_MAXIMIZED`, außer bei `Engine.is_embedded_in_editor()`;
  - `GameWindow.set_process(false)` und `GameWindow.set_process_unhandled_input(false)`.

  Das betrifft nur den Prozess, in dem die Werkstatt läuft. Das Spiel lädt die Werkstatt nie,
  `GameWindow` und `test_game_window.gd` bleiben unverändert.
- Danach prüft sie, ob es eine Sicherungskopie gibt (R23), und öffnet dann
  `EventCatalog.DEFAULT_PATH` über den `CatalogEditor`.
  - Fehlt die Datei, bietet ein Dialog an, einen leeren Katalog mit den zehn Kategorien
    anzulegen; geschrieben wird er erst beim Speichern.
  - Ist die Datei unlesbar, zeigt ein Dialog Zeile und Grund.
- Schließen (R15): `get_tree().auto_accept_quit = false`. In `_notification()` fängt sie
  `NOTIFICATION_WM_CLOSE_REQUEST` ab. Bei ungespeicherten Änderungen fragt ein Dialog „Speichern“,
  „Verwerfen“ oder „Abbrechen“, sonst beendet sie mit `get_tree().quit()`. Nach dem Speichern und
  beim regulären Schließen löscht sie die Sicherungskopie.

## Szenenaufbau

```text
Werkstatt (Control, volle Fläche)        werkstatt.gd; theme = werkstatt_theme.tres; default_font per Code
└── Layout (VBoxContainer)
    ├── Toolbar (HBoxContainer)          Speichern, Rückgängig, Wiederholen | Datei, „ungespeichert“, Zahl der Fehler und Warnungen
    └── Main (HSplitContainer)
        ├── EventList                    links, Breite etwa 280
        ├── Center (VSplitContainer)
        │   ├── TimelineView             oben
        │   └── Tabs (TabContainer)      „Prüfung“ (IssuesPanel), „Simulator“ (SimulatorPanel), „Statistik“ (StatisticsPanel)
        └── FormScroll (ScrollContainer) rechts, Breite etwa 380
            └── EventForm
```

Dazu Dialoge als Kinder der Werkstatt: `ConfirmationDialog` für Schließen, Verwerfen, Löschen und
eine fremde Änderung; `AcceptDialog` für einen unlesbaren Katalog; `InterventionDialog`.

**Datenfluss:**
- `CatalogEditor` ist der einzige, der den Katalog ändert. Liste, Formular und Zeitstrahl rufen
  seine Methoden.
- Er meldet jede Änderung mit `catalog_changed`; daraufhin zeichnen sich alle neu.
- Die Auswahl gehört der Werkstatt, nicht dem Verlauf: `Werkstatt.selected_id` und das Signal
  `selection_changed(id: String)`. Ein Klick in der Liste, im Zeitstrahl oder in der Prüfung wählt
  ein Ereignis.

## CatalogEditor

```gdscript
class_name CatalogEditor extends RefCounted

signal catalog_changed()
signal issues_changed(issues: Array[CatalogIssue])

var catalog: EventCatalog
var path: String = ""
var last_error: String = ""            # deutscher Text des letzten Fehlers beim Öffnen oder Speichern

## Öffnet eine Katalogdatei. Bei einem Parse-Fehler bleibt der bisherige Katalog, last_error
## nennt Zeile und Grund; die Datei wird nicht angefasst (Edge Case „Katalog unlesbar“).
func open(p_path: String) -> Error
## Schreibt kanonisch nach path. Ohne force gibt es ERR_FILE_ALREADY_IN_USE, wenn die Datei seit
## dem Öffnen von außen geändert wurde oder beim Öffnen unlesbar war. Die Werkstatt fragt dann
## nach und speichert erst auf ausdrücklichen Wunsch mit force = true.
func save(force: bool = false) -> Error
## Leerer Katalog mit den zehn Kategorien der Übernahme, ungespeichert (Edge Case „keine Datei“).
func new_catalog() -> void
func is_dirty() -> bool                # UndoRedo-Version ≠ Version beim letzten Öffnen/Speichern
func issues() -> Array[CatalogIssue]   # letzte Prüfung, nach jeder Änderung neu

## Sicherungskopie (FR-050, R23) unter BACKUP_PATH
const BACKUP_PATH := "user://werkstatt_sicherung.json"
func write_backup() -> Error           # nur, wenn is_dirty()
func has_backup() -> bool
func restore_backup() -> Error         # übernimmt die Kopie als ungespeicherten Stand
func discard_backup() -> void

## Ereignisse
func suggest_id(title: String) -> String      # klein, ä→ae, ö→oe, ü→ue, ß→ss, sonst _; eindeutig mit _2, _3 …
func add_event(kind: TimelineEvent.Kind, title: String, category: String, day: int = -1) -> TimelineEvent
func duplicate_event(id: String) -> TimelineEvent
func references_to(id: String) -> PackedStringArray   # Kennungen, die per Folge oder Bedingung darauf zeigen
func delete_event(id: String) -> void         # entfernt die Verweise mit, eine Aktion (FR-036)
func rename_event(old_id: String, new_id: String) -> Error   # zieht Verweise nach; ERR_ALREADY_EXISTS bei Dublette
func set_event_field(id: String, field: StringName, value: Variant) -> void
## Behält Werte, die auch die neue Art hat (Zeitfenster, Mindestabstand, Dauer), setzt die übrigen
## Felder der neuen Art auf Vorgaben, verwirft die der alten (FR-031).
func set_event_kind(id: String, kind: TimelineEvent.Kind) -> void

## Listen im Ereignis: list ist &"effects", &"follow_ups" oder &"conditions"
func add_item(id: String, list: StringName) -> void
func remove_item(id: String, list: StringName, index: int) -> void
func set_item_field(id: String, list: StringName, index: int, field: StringName, value: Variant) -> void

## Kategorien: Kennung aus dem Namen, danach fest; Farbe = erstes noch freies Token der Palette
func add_category(name: String) -> EventCategory
func set_category_field(id: String, field: StringName, value: Variant) -> void   # &"name" oder &"color"
func delete_category(id: String) -> Error     # ERR_UNAVAILABLE, solange Ereignisse dazugehören

## Verlauf
func undo() -> bool
func redo() -> bool
func can_undo() -> bool
func can_redo() -> bool
```

Regeln:
- Jede ändernde Methode ist genau eine `UndoRedo`-Aktion mit verständlichem Namen, etwa „Datum
  von Intel Pentium erscheint“.
- Ein Ziehen im Zeitstrahl ruft beim Loslassen einmal `set_event_field()` auf; während des
  Ziehens ändert sich der Katalog nicht.
- Der Verlauf überlebt das Speichern; `open()` leert ihn (FR-034).
- `CatalogEditor` gibt sein `UndoRedo` in `NOTIFICATION_PREDELETE` frei (R15).
- Die Werkstatt ruft `write_backup()` über einen `Timer` alle 120 Sekunden auf. Nach `save()` und
  beim regulären Schließen ruft sie `discard_backup()` auf.

## Liste, Formular, Prüfung

**EventList:** Suchfeld (Titel, Teilwort, Groß- und Kleinschreibung egal), Auswahl Art und
Kategorie, darunter die Liste. Jede Zeile zeigt Titel, Art und ein Zeichen für Fehler oder
Warnung. Unter der Liste stehen „Neu“ (mit Art), „Duplizieren“ und „Löschen“; Löschen fragt nach
und nennt Verweise (FR-036).

**EventForm:**
- Felder für das gewählte Ereignis; die Art bestimmt, welche Felder sichtbar sind (FR-031):
  - fix: Datum und Dauer;
  - jährlich: Jahre von–bis, Beginn, Ende oder „ohne Dauer“;
  - gesetzt: Zeitfenster, Anzahl von–bis mit Wahrscheinlichkeit je Anzahl, Mindestabstand,
    Dauer;
  - über Wahrscheinlichkeit: Zeitfenster, Chance in %, Höchstzahl, Mindestabstand, Dauer;
  - nur als Folge: Dauer.
- Dazu je eine Liste für Wirkungen, Folgeereignisse und Bedingungen mit „+“ und „−“.
- Folgeereignisse und Bedingungen wählen ihr Ziel aus einer Liste der Ereignisse.
- Wirkungsziele werden aus den schon benutzten Zielen vorgeschlagen oder frei eingegeben.
- Prozentwerte erscheinen in Prozent, gespeichert wird der Anteil.
- Zahlen nehmen Komma oder Punkt an und erscheinen mit Komma.
- Datumsfelder nehmen `TT.MM.JJJJ` an, auch ohne führende Nullen (`1.3.1993`).
- Eine Eingabe gilt beim Verlassen des Felds oder mit Enter. Ist sie ungültig, bleibt der alte
  Wert stehen, und ein Hinweis am Feld sagt, warum (FR-031).
- Kategorien verwaltet ein kleiner Bereich unter dem Formular: anlegen, umbenennen, Farbe wählen,
  löschen; Löschen ist gesperrt, solange Ereignisse dazugehören.

**IssuesPanel:** Liste aller Prüfmeldungen mit Stufe, Ereignis, Feld und Text. Ein Klick wählt das
Ereignis und setzt den Fokus auf das Feld (FR-033).

## Zeitstrahl (TimelineView)

```gdscript
class_name TimelineView extends Control
signal event_clicked(id: String)
signal event_moved(id: String, field: StringName, value: Variant)   # beim Loslassen, an CatalogEditor
signal create_requested(category: String, day: int)                  # Doppelklick auf freie Fläche
var editor: CatalogEditor
var visible_from: float                # Tagesindex am linken Rand
var days_per_pixel: float              # Zoom; ganz herausgezoomt passen 1985–1999 in die Breite
```

| Eingabe | Wirkung |
|---|---|
| Mausrad | seitlich verschieben |
| Shift+Mausrad | seitlich verschieben, schneller |
| Cmd+Mausrad (Ctrl unter Windows/Linux) | Zoom um die Mausposition, vom ganzen Zeitraum bis zu einem Monat |
| Ziehen auf freier Fläche | seitlich verschieben |
| Ziehen eines Punkts | Datum eines fixen Ereignisses, tagesgenau, Datum steht am Mauszeiger |
| Ziehen eines Balken- oder Fensterrands | Beginn bzw. Ende von Zeitfenster oder Dauer |
| Ziehen eines jährlichen Ereignisses | nicht möglich; der Hinweis sagt „nur im Formular änderbar“ (FR-039) |
| Überfahren | Hinweis über `_get_tooltip()`: Titel, Art, Datum oder Zeitfenster, Chance |
| Klick | wählt das Ereignis |
| Rechtsklick | `PopupMenu`: Bearbeiten, Duplizieren, Löschen |
| Doppelklick auf freie Fläche | neues fixes Ereignis an diesem Tag in der Kategorie der Zeile |

Darstellung (FR-037):
- je Kategorie eine Zeile in deren Farbe;
- fix: Punkt, mit Dauer als Balken;
- jährlich: Punkt oder Balken in jedem seiner Jahre;
- gesetzt: Rahmen über das Zeitfenster;
- über Wahrscheinlichkeit: Band über das Zeitfenster mit der Chance als Zahl;
- nur als Folge: keine Marke auf der Achse, aber in der Liste;
- überlappende Marken einer Zeile: gestapelt in Unterzeilen, die Zeile wird so hoch wie nötig;
- Titel neben der Marke, wenn bis zur nächsten Marke Platz ist, sonst nur im Hinweis.

Achse mit Jahren, ab Monatszoom mit Monaten und Tagesstrichen.

## Simulator (SimulatorPanel)

- **Oben:**
  - Seed-Feld (0 bis 2.147.483.647), „Würfeln“, „Fahrplan erzeugen“ und das aktuelle Datum;
  - „+1 Tag“, „+1 Monat“, „+1 Jahr“, „Bis …“ (Datum) und „Bis zum Ende“;
  - „Neu starten mit Eingriffen“ und „Neu starten ohne Eingriffe“;
  - „Probe speichern …“, „Probe laden …“ und „Probe löschen“.
- **Links:** der Fahrplan als Tabelle mit Datum, Ereignis, Herkunft und Zustand, filterbar nach
  Zustand. Darunter für den gewählten Termin die Begründung (`ScheduleEntry.explain()`) und die
  verzögerten Wirkungen (FR-041, SC-007).
- **Unterschiede:** Läuft ein Durchlauf mit Eingriffen, rechnet das Panel denselben Seed ohne
  Eingriffe bis zum selben Tag mit und vergleicht beide mit `ScheduleDiff.compare()`. Jede
  Tabellenzeile bekommt ihre Markierung: neu, verschoben, anderer Zustand. Weggefallene Termine
  stehen durchgestrichen an ihrem Tag. Ein Filter „nur Unterschiede“ blendet den Rest aus (FR-043).
- **Rechts:** das Protokoll (`TimelineMessage.to_line()`) und die Eingriffe: „Modifikator …“,
  „Absagen …“, „Verschieben …“, „Einplanen …“. Die gesetzten Modifikatoren stehen in einer Liste
  mit „Entfernen“; für ein Ereignis über Wahrscheinlichkeit zeigt die Liste
  `TimelineRun.chance_info()` mit Summe und Begrenzung (US6, Szenario 3).
- **Katalog:** Jeder Lauf arbeitet auf `editor.catalog.duplicate_catalog()`, also mit dem
  aktuellen, auch ungespeicherten Stand (FR-042). Er ändert weder Spieluhr noch Katalog.
  - Ereignisse mit Fehlern nimmt der Lauf aus; ein Hinweis über der Tabelle nennt sie.
  - Ändert sich der Katalog während eines Laufs, zeigt der Hinweis „Katalog geändert, neu
    starten“, und der Lauf behält seinen Stand.
- **Eingriffe:** Sie bleiben über Neustarts und Änderungen am Katalog erhalten, bis die Werkstatt
  schließt oder eine Probe geladen wird. Abgelehnte Eingriffe zeigen `last_refusal`.

**Proben (FR-051, R22):**

```gdscript
class_name WhatIfProbe extends RefCounted
const FOLDER := "res://tools/werkstatt/proben/"
var id: String
var name: String
var seed: int
var modifiers: Array[ChanceModifier] = []
var schedulings: Array[Dictionary] = []    # [{ "event_id", "day", "reason" }]
var cancellations: Array[Dictionary] = []  # [{ "event_id", "day", "reason" }]
var moves: Array[Dictionary] = []          # [{ "event_id", "day", "new_day", "reason" }]

static func list_probes() -> Array[WhatIfProbe]          # alle Dateien in FOLDER, nach Name
static func read_file(path: String) -> WhatIfProbe       # null und push_error bei unlesbarer Datei
func write_file() -> Error                                # FOLDER + id + ".json", kanonisch wie der Katalog
## Setzt Seed und Eingriffe auf einen frisch angelegten Lauf; gibt die nicht anwendbaren als
## deutsche Sätze zurück, etwa „Absage: Konkurrent eröffnet am 01.06.1992 nicht im Fahrplan“.
func apply_to(run: TimelineRun) -> PackedStringArray
static func from_run(name: String, run: TimelineRun) -> WhatIfProbe
```

Die Eingriffe eines Laufs hält das Panel selbst als `WhatIfProbe` ohne Datei. Beim Neustart
wendet es diese Probe auf den neuen Lauf an; „Probe speichern …“ schreibt sie mit Namen.

## Statistik (StatisticsPanel)

- **Eingaben:** Anzahl der Spiele (Vorgabe 1.000), „Mit Modifikatoren und Einplanungen aus dem
  Simulator“, „Starten“, „Abbrechen“ und ein Fortschrittsbalken.
- **Ablauf:** Je Bild `run_batch(25)`, dazwischen `await get_tree().process_frame` (R17).
  „Abbrechen“ hält an und zeigt das Ergebnis der fertigen Spiele samt deren Zahl.
- **Ergebnis:** eine Tabelle je Ereignis mit Mittelwert, kleinster und größter Anzahl, „ohne“ in %
  und „Obergrenze“ in %; ohne Obergrenze steht dort „–“. Für die gewählte Zeile darunter die
  Verteilung auf 1985 bis 1999 als Balken (FR-044).
- Ereignisse mit Fehlern nimmt die Statistik aus wie der Simulator und nennt sie (FR-042).

## Kürzel

Über `InputEventKey` mit `command_or_control_autoremap = true` (R15):

| Kürzel (Mac) | Windows/Linux | Wirkung |
|---|---|---|
| Cmd+S | Ctrl+S | Speichern |
| Cmd+Z | Ctrl+Z | Rückgängig |
| Shift+Cmd+Z | Ctrl+Shift+Z | Wiederholen |

Solange ein Textfeld den Fokus hat, gehören Cmd+Z und Shift+Cmd+Z dem Textfeld.
