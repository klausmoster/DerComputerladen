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
├── relief_style_box.gd               # class_name ReliefStyleBox: Relief und Pixelschatten, die StyleBoxFlat nicht kann
├── icons/schliessen.svg              # Schließen-Kreuz der Dialoge in tusche
├── icons/griff_h.svg, griff_v.svg    # Griffe der Split-Container in tusche
├── catalog_editor.gd                 # class_name CatalogEditor, ohne Oberfläche
├── event_list.tscn / event_list.gd   # class_name EventList
├── event_form.tscn / event_form.gd   # class_name EventForm
├── timeline_view.gd                  # class_name TimelineView
├── issues_panel.gd                   # class_name IssuesPanel
├── zebra.gd                          # Streifen, Auswahl und Überfahren für alle Tabellen der Werkstatt
├── simulator_panel.tscn / .gd        # class_name SimulatorPanel
├── statistics_panel.tscn / .gd       # class_name StatisticsPanel
├── intervention_dialog.tscn / .gd    # class_name InterventionDialog: Modifikator, Absagen, Verschieben, Einplanen
├── what_if_probe.gd                  # class_name WhatIfProbe: Probe lesen, schreiben, neu abspielen
├── proben/                           # gespeicherte Was-wäre-wenn-Proben, eine JSON-Datei je Probe
└── fahrplan_ausgabe.gd               # Textausgabe, siehe zeitleiste.md

src/test/
├── test_catalog_editor.gd            # Bearbeiten, Kennungen, Verweise, Rückgängig, Speichern, Verwerfen, Lesemeldungen, Sicherung
├── test_event_form.gd                # Eingaben mit Komma, Prozent und Datum, ungültige Eingaben, Gewichte verteilen, focus_field()
├── test_what_if_probe.gd             # Speichern, Laden, Neu abspielen, Löschen, nicht anwendbare Eingriffe
├── test_timeline_view.gd             # Tag ↔ Pixel, Stapeln, jährliche nicht ziehbar, Vorschau beim Ziehen
├── test_werkstatt_theme.gd           # Farben des Themes stammen aus UiPalette, Schriftgröße, Kästen
├── test_simulator.gd                 # Eingriffe, Unterschiede, Neustarts und Proben im Simulator (US6)
└── test_werkstatt_scene.gd           # Rauchtest: Szene baut headless auf, Prüfmeldung führt zum Feld, Simulator rechnet, Spieluhr bleibt unberührt
```

## Start und Fenster

- Start im Editor mit F6, wenn `werkstatt.tscn` offen ist, oder im Terminal:

  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --path src res://tools/werkstatt/werkstatt.tscn
  ```

- Nur für Prüfungen wie SC-011 nimmt sie nach `--` einen anderen Katalog an:
  `… werkstatt.tscn -- --katalog res://test/fixtures/catalog_500.json`. Dahinter steht
  `Werkstatt.catalog_path` mit der Vorgabe `EventCatalog.DEFAULT_PATH`; Tests setzen den Pfad,
  bevor die Szene in den Baum kommt.
- `Werkstatt._ready()` richtet, außer headless, das Fenster ein (R13):
  - `get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED`;
  - `get_window().content_scale_factor = DisplayServer.screen_get_scale()`, damit Text auf dem
    Retina-Bildschirm scharf und in normaler Größe steht (Style-Guide „Werkzeuge“);
  - `get_window().mode = Window.MODE_MAXIMIZED`, außer bei `Engine.is_embedded_in_editor()`;
    das greift sofort, weil das Projekt im Fenster startet (Feature 001, FR-004, seit T040);
  - `GameWindow.set_process(false)` und `GameWindow.set_process_unhandled_input(false)`, damit
    dessen Fenstergröße weder beim Start noch beim Wechsel aus dem Vollbild greift.

  Das betrifft nur den Prozess, in dem die Werkstatt läuft. Das Spiel lädt die Werkstatt nie,
  `test_game_window.gd` bleibt unverändert. `GameWindow` setzt seit T040 auch beim Start die
  Fenstergröße des Spiels, im ersten `_process()` (Feature 001, Vertrag).
- Danach öffnet sie `catalog_path` über den `CatalogEditor` und prüft, ob es eine
  Sicherungskopie gibt (R23).
  - Fehlt die Datei, bietet ein Dialog an, einen leeren Katalog mit den zehn Kategorien
    anzulegen; geschrieben wird er erst beim Speichern.
  - Ist die Datei unlesbar, zeigt ein Dialog Zeile und Grund.
  - Gehört die Kopie zu diesem Katalog (`backup_matches()`), fragt ein Dialog „Übernehmen“,
    „Verwerfen“ oder „Später“ und nennt beide Zeiten. „Später“ (auch Esc) lässt die Kopie liegen,
    bis Klaus speichert oder nach seiner ersten Änderung die nächste Sicherung sie ersetzt.
    Gehört sie zu einem anderen Katalog, bleibt sie liegen, und ein Hinweis nennt ihren Pfad.
- Speichern (Knopf oder Cmd+S): Hat der Katalog Fehler (`has_errors()`), fragt ein Dialog „Der
  Katalog hat N Fehler. Trotzdem speichern?“ (FR-034). Danach `save()`; meldet es
  `ERR_FILE_ALREADY_IN_USE`, folgt die Rückfrage zur fremden Änderung und erst dann `save(true)`.
- Verwerfen (Knopf): Bei ungespeicherten Änderungen fragt ein Dialog nach, dann `revert()`.
- Schließen (R15): `get_tree().auto_accept_quit = false`. In `_notification()` fängt sie
  `NOTIFICATION_WM_CLOSE_REQUEST` ab. Bei ungespeicherten Änderungen fragt ein Dialog „Speichern“,
  „Verwerfen“ oder „Abbrechen“; „Speichern“ läuft über dieselben Rückfragen wie oben. Danach
  beendet sie mit `get_tree().quit()`. Nach dem Speichern, nach dem Verwerfen und beim regulären
  Schließen löscht sie die Sicherungskopie, beim Schließen nicht, solange „Später“ gilt.

## Szenenaufbau

```text
Werkstatt (Control, volle Fläche)        werkstatt.gd; theme = werkstatt_theme.tres; default_font per Code
└── Layout (VBoxContainer)
    ├── Toolbar (PanelContainer, Variante Toolbar)
    │   └── HBoxContainer                Speichern, Verwerfen, Rückgängig, Wiederholen | Datei, „ungespeichert“, Zahl der Fehler und Warnungen
    └── Main (HSplitContainer)
        ├── EventList                    links, Breite etwa 280
        ├── Center (VSplitContainer)
        │   ├── TimelineView             oben
        │   └── Tabs (TabContainer)      „Prüfung“ (IssuesPanel), „Simulator“ (SimulatorPanel), „Statistik“ (StatisticsPanel)
        └── FormScroll (ScrollContainer) rechts, Breite etwa 380
            └── EventForm
```

Dazu Dialoge als Kinder der Werkstatt: `ConfirmationDialog` für Schließen, Verwerfen, Löschen,
Speichern trotz Fehlern, eine fremde Änderung und die Sicherungskopie; `AcceptDialog` für einen
unlesbaren Katalog. Den Dialog für „Neu …“ bringt `EventList` selbst mit, ebenso bringt das
`SimulatorPanel` den `InterventionDialog`, die Dialoge für Proben und sein Menü am Termin mit
(T061/T062): Nur das Panel nutzt sie, und es bleibt allein testbar.

**Datenfluss:**
- `CatalogEditor` ist der einzige, der den Katalog ändert. Liste, Formular und Zeitstrahl rufen
  seine Methoden.
- Er meldet jede Änderung mit `catalog_changed`; daraufhin zeichnen sich alle neu.
- Die Auswahl gehört der Werkstatt, nicht dem Verlauf: `Werkstatt.selected_id` und das Signal
  `selection_changed(id: String)`. Ein Klick in der Liste, im Zeitstrahl oder in der Prüfung wählt
  ein Ereignis.

**Verdrahtung in `werkstatt.gd`:**
- `EventList.event_selected`, `TimelineView.event_clicked` und `IssuesPanel.issue_activated`
  setzen die Auswahl; `selection_changed` zeigt das Ereignis im Formular und hebt es in Liste und
  Zeitstrahl hervor.
- Vom `TimelineView` (T049): `event_moved` geht direkt an `CatalogEditor.set_event_field()`, ein
  Ziehen ist ein Schritt im Verlauf; `create_requested` öffnet `EventList.open_new_dialog()`
  vorbelegt; `event_created` wie aus der Liste; `edit_requested` wählt und setzt den Fokus in den
  Titel; `delete_requested` führt zur Rückfrage wie in der Liste. Nach `catalog_changed` ruft die
  Werkstatt `refresh()`, nach `selection_changed` `select_event()`.
- `IssuesPanel.issue_activated(event_id, field)` ruft danach `EventForm.focus_field(field)` auf
  (FR-033).
- `CatalogEditor.catalog_changed` zeichnet Liste, Formular und Zeitstrahl neu;
  `issues_changed` aktualisiert Prüfung, Zeichen in der Liste und die Zahlen in der Toolbar.
- Ein neues Ereignis, ob aus dem Dialog oder per Doppelklick, wird gewählt, und das Formular
  setzt den Fokus auf den Titel.
- Fehlt das gewählte Ereignis nach einer Änderung, etwa nach dem Löschen oder nach dem
  Rückgängigmachen eines Umbenennens, ist keins mehr gewählt.
- Ohne lesbaren Katalog ist „Speichern“ gesperrt, damit eine kaputte Datei nicht überschrieben
  wird; ohne ungespeicherte Änderungen ist „Verwerfen“ gesperrt.

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
## nach und speichert erst auf ausdrücklichen Wunsch mit force = true. Fehler im Katalog halten
## save() nicht auf; ob trotzdem gespeichert wird, fragt die Werkstatt vorher über has_errors().
func save(force: bool = false) -> Error
## Liest path neu, leert den Verlauf und löscht die Sicherungskopie (FR-034, Verwerfen).
func revert() -> Error
## Leerer Katalog mit den zehn Kategorien der Übernahme, ungespeichert (Edge Case „keine Datei“).
func new_catalog() -> void
func is_dirty() -> bool                # UndoRedo-Version ≠ Version beim letzten Öffnen/Speichern
## Meldungen beim Lesen (V22) und die letzte Prüfung, nach jeder Änderung neu. Die Meldungen
## beim Lesen bleiben bis zum nächsten erfolgreichen save() stehen (ereigniskatalog.md, Regel 5).
func issues() -> Array[CatalogIssue]
func has_errors() -> bool              # CatalogValidator.has_errors(issues())

## Sicherungskopie (FR-050, R23): {"catalog", "format": 1, "path", "saved"}, kanonisch
var backup_path: String = "user://werkstatt_sicherung.json"   # Tests setzen eine eigene Datei
func write_backup() -> Error           # nur, wenn is_dirty()
func has_backup() -> bool
func backup_matches() -> bool          # ob "path" der Kopie zu path passt
func backup_info() -> Dictionary       # { "path": String, "saved": int, "catalog_modified": int }
func restore_backup() -> Error         # übernimmt die Kopie als ungespeicherten Stand
func discard_backup() -> void

## Ereignisse
func suggest_id(title: String) -> String      # klein, ä→ae, ö→oe, ü→ue, ß→ss, sonst _; eindeutig mit _2, _3 …
static func id_from(text: String, fallback: String) -> String   # die Regel von suggest_id(), ohne Editor; auch für Proben und Modifikatoren
static func unique_id(base: String, taken: Dictionary) -> String # hängt _2, _3 … an, bis die Kennung nicht in taken steht
## Legt ein Ereignis mit den Vorgaben seiner Art an; leere Kennung heißt suggest_id(title),
## day ≥ 0 setzt bei fixen Ereignissen das Datum.
func add_event(kind: TimelineEvent.Kind, title: String, category: String, day: int = -1, id: String = "") -> TimelineEvent
func duplicate_event(id: String) -> TimelineEvent
func references_to(id: String) -> PackedStringArray   # Kennungen, die per Folge oder Bedingung darauf zeigen
func delete_event(id: String) -> void         # entfernt die Verweise mit, eine Aktion (FR-036)
func rename_event(old_id: String, new_id: String) -> Error   # zieht Verweise nach; ERR_ALREADY_EXISTS bei Dublette
func set_event_field(id: String, field: StringName, value: Variant) -> void
## Mehrere Felder in einer Aktion, etwa Anzahl von–bis samt neu verteilten Gewichten.
func set_event_fields(id: String, changes: Dictionary) -> void
## Behält Werte, die auch die neue Art hat (Zeitfenster, Mindestabstand, Dauer), setzt die übrigen
## Felder der neuen Art auf Vorgaben, verwirft die der alten (FR-031).
func set_event_kind(id: String, kind: TimelineEvent.Kind) -> void

## Listen im Ereignis: list ist &"effects", &"follow_ups" oder &"conditions"
func add_item(id: String, list: StringName) -> void
func remove_item(id: String, list: StringName, index: int) -> void
func set_item_field(id: String, list: StringName, index: int, field: StringName, value: Variant) -> void

## Kategorien: Kennung aus dem Namen, danach fest; Farbe = erstes noch freies Token aus
## UiPalette.CATEGORY_TOKENS, sind alle vergeben, das am seltensten benutzte, bei Gleichstand
## das frühere
func add_category(name: String) -> EventCategory
func set_category_field(id: String, field: StringName, value: Variant) -> void   # &"name" oder &"color"
func delete_category(id: String) -> Error     # ERR_UNAVAILABLE, solange Ereignisse dazugehören

## Verlauf
func undo() -> bool
func redo() -> bool
func can_undo() -> bool
func can_redo() -> bool
## Name der Aktion, die undo() bzw. redo() als Nächstes ausführt, etwa „Datum von Intel Pentium
## erscheint“; leer, wenn es keine gibt. Für die Tooltips der Knöpfe.
func undo_name() -> String
func redo_name() -> String
```

Regeln:
- Jede ändernde Methode ist genau eine `UndoRedo`-Aktion mit verständlichem Namen, etwa „Datum
  von Intel Pentium erscheint“.
- Ein Ziehen im Zeitstrahl ruft beim Loslassen einmal `set_event_field()` auf; während des
  Ziehens ändert sich der Katalog nicht.
- Der Verlauf überlebt das Speichern; `open()` und `revert()` leeren ihn (FR-034).
- `CatalogEditor` gibt sein `UndoRedo` in `NOTIFICATION_PREDELETE` frei (R15).
- Die Werkstatt ruft `write_backup()` über einen `Timer` alle 120 Sekunden auf. Nach `save()`,
  nach `revert()` und beim regulären Schließen ruft sie `discard_backup()` auf.

## Liste, Formular, Prüfung

**EventList** (`signal event_selected(id: String)`):
- Suchfeld (Titel, Teilwort, Groß- und Kleinschreibung egal), Auswahl Art und Kategorie,
  darunter die Liste. Jede Zeile zeigt Titel, Art und ein Zeichen für Fehler oder Warnung.
- Unter der Liste stehen „Neu …“, „Duplizieren“ und „Löschen“; Löschen fragt nach und nennt
  Verweise (FR-036).
- „Neu …“ öffnet einen Dialog mit Art, Titel und Kategorie. Darunter steht die Kennung, die
  `suggest_id()` aus dem Titel vorschlägt; Klaus kann sie ändern (US2, Szenario 1; FR-032).
  „Anlegen“ ruft `add_event()`.
- `open_new_dialog(kind: TimelineEvent.Kind = FIXED, category: String = "", day: int = -1)`
  öffnet diesen Dialog; der Knopf ruft es ohne Argumente auf. Der Zeitstrahl lässt ihn nach einem
  Doppelklick vorbelegt öffnen: Art fix, Kategorie der Zeile, Tag. Das Datum steht im Dialog,
  solange die Art fix ist; bei einer anderen Art gelten deren Vorgaben. Abbrechen legt nichts an.

**EventForm:**
- Felder für das gewählte Ereignis; die Art bestimmt, welche Felder sichtbar sind (FR-031). Die
  Auswahl „Art“ hat fünf Einträge, „fix, jährlich“ ist einer davon (data-model.md):
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
- Eine Eingabe gilt beim Verlassen des Felds oder mit Enter; Enter gibt dabei den Fokus ab, damit
  das nächste Cmd+Z den Katalog erreicht (R15). Ist sie ungültig, bleibt der alte Wert stehen,
  und ein Hinweis am Feld sagt, warum (FR-031).
- Ändert Klaus „Anzahl von–bis“, verteilt das Formular die Gewichte neu, alle gleich (FR-004)
  auf zwei Nachkommastellen; den Rest bekommt das letzte Gewicht, damit die Summe genau 100 ist.
  Beides schickt es mit `set_event_fields()` als eine Aktion.
- `func focus_field(field: String) -> void` setzt den Fokus auf das Feld einer Prüfmeldung, auch
  in den Listen, etwa `effects[1].delay_days`; ein unbekanntes Feld wählt nur das Ereignis.
- Kategorien verwaltet ein kleiner Bereich unter dem Formular: anlegen, umbenennen, Farbe wählen,
  löschen; Löschen ist gesperrt, solange Ereignisse dazugehören. Zur Wahl stehen die Farben aus
  `UiPalette.CATEGORY_TOKENS`.

**IssuesPanel** (`signal issue_activated(event_id: String, field: String)`): Liste aller
Prüfmeldungen mit Stufe, Ereignis, Feld und Text. Ein Klick sendet `issue_activated`; die
Werkstatt wählt das Ereignis und setzt den Fokus auf das Feld (FR-033). Meldungen zu Kategorien
führen zum Bereich für Kategorien.

## Zeitstrahl (TimelineView)

```gdscript
class_name TimelineView extends Control
signal event_clicked(id: String)
signal event_moved(id: String, field: StringName, value: Variant)   # beim Loslassen, an CatalogEditor
signal create_requested(category: String, day: int)                  # Doppelklick auf freie Fläche
signal edit_requested(id: String)      # Menü „Bearbeiten“
signal event_created(id: String)       # Menü „Duplizieren“, über CatalogEditor.duplicate_event()
signal delete_requested(id: String)    # Menü „Löschen“; die Rückfrage stellt die Werkstatt (FR-036)
var editor: CatalogEditor
var visible_from: float                # Tagesindex am linken Rand
var days_per_pixel: float              # Zoom; ganz herausgezoomt passen 1985–1999 in die Breite
func refresh() -> void                 # nach catalog_changed; bricht ein laufendes Ziehen ab
func select_event(id: String) -> void  # hebt hervor, ohne Signal, wie EventList
# Für Tests: day_to_x(), x_to_day(), time_rect(), event_at(), mark_rects(), preview_text(),
# preview_issue()
```

| Eingabe | Wirkung |
|---|---|
| Mausrad | seitlich verschieben |
| Shift+Mausrad | seitlich verschieben, schneller |
| Cmd+Mausrad (Ctrl unter Windows/Linux) | Zoom um die Mausposition, vom ganzen Zeitraum bis zu einem Monat |
| Ziehen auf freier Fläche | seitlich verschieben |
| Ziehen eines Punkts | Datum eines fixen Ereignisses, tagesgenau, Datum steht am Mauszeiger |
| Ziehen eines Balken- oder Fensterrands | Beginn bzw. Ende von Zeitfenster oder Dauer; ein Fehler der Vorschau steht sofort am Mauszeiger |
| Ziehen eines jährlichen Ereignisses | nicht möglich; der Hinweis sagt „nur im Formular änderbar“ (FR-039) |
| Überfahren | Hinweis über `_get_tooltip()`: Titel, Art, Datum oder Zeitfenster, Chance |
| Klick | wählt das Ereignis |
| Rechtsklick | `PopupMenu`: Bearbeiten, Duplizieren, Löschen |
| Doppelklick auf freie Fläche | `create_requested`; die Werkstatt öffnet den Dialog „Neu …“ vorbelegt mit fix, der Kategorie der Zeile und dem Tag (R16) |
| Wischen mit zwei Fingern (Trackpad) | waagerecht seitlich verschieben, senkrecht die Zeilen rollen, mit Cmd Zoom um die Maus (R16) |
| Kneifen (Trackpad) | Zoom um die Mausposition, in denselben Grenzen wie Cmd+Mausrad |
| Knöpfe „+“, „−“ und „Alles“ oben links | Zoom um die Mitte des Ausschnitts, je Klick Faktor 2; „Alles“ zeigt 1985 bis 1999; an den Grenzen gesperrt (Wunsch von Klaus bei T055) |

Darstellung (FR-037):
- je Kategorie eine Zeile in deren Farbe;
- fix: Punkt, mit Dauer als Balken;
- jährlich: Punkt oder Balken in jedem seiner Jahre;
- gesetzt: Rahmen über das Zeitfenster;
- über Wahrscheinlichkeit: Band über das Zeitfenster mit der Chance als Zahl;
- nur als Folge: keine Marke auf der Achse, aber in der Liste;
- überlappende Marken einer Zeile: gestapelt in Unterzeilen, die Zeile wird so hoch wie nötig;
- Titel neben der Marke, wenn bis zur nächsten Marke Platz ist, sonst nur im Hinweis.

Achse mit Jahren, ab Monatszoom mit Monaten und Tagesstrichen. Titel stehen in Textfarbe auf dem
Grund neben der Marke, nicht auf der farbigen Fläche (R14).

Ergänzt bei der Umsetzung (T047 bis T049):
- Links eine Spalte mit Farbfeld und Namen je Kategorie; Zeilen abwechselnd `papier` und
  `endlos-gruen`. Achse und Raster nach den Rollen „Fläche“ und „Raster“ im Style-Guide.
- Gibt es Ereignisse ohne gültige Kategorie (V05), erscheint eine Zeile „Ohne Kategorie“; sie und
  Kategorien mit unerlaubter Farbe (V21) zeichnen in `kassenrot`, der Rolle Fehler.
- Passen die Zeilen nicht in die Höhe, rollt eine Leiste am Rand; das Mausrad bleibt beim
  seitlichen Verschieben.
- Unten liegt immer eine waagerechte Leiste über die ganze Zeitfläche (Wunsch von Klaus bei der
  Abnahme T055): Der Griff zeigt den sichtbaren Ausschnitt von 1985 bis 1999, Ziehen verschiebt
  die Ansicht, und Mausrad, Wischen, Ziehen auf freier Fläche und Zoom stellen den Griff nach.
- Titel am rechten Rand dürfen angeschnitten sein, Achsenbeschriftungen nicht.
- Ein Ziehen ändert genau ein Feld: Ein Balken hat rechts den Griff für die Dauer, Ziehen am
  Körper verschiebt das Datum; Zeitfenster haben Griffe an beiden Rändern, Ziehen auf ihrer
  Fläche verschiebt die Ansicht. Datum und Fenster bleiben in 1985 bis 1999.
- Für den Doppelklick zählt die Fläche von Rahmen und Bändern als frei.
- `event_clicked` kommt beim Drücken, auch beim Rechtsklick; ein Klick auf freie Fläche behält
  die Auswahl. Ein Klick in den Zeitstrahl nimmt einem Formularfeld den Fokus, damit es seine
  Eingabe übernimmt.

**Vorschau beim Ziehen (R16):** Während des Ziehens ändert sich der Katalog nicht. Die Ansicht
prüft eine Kopie des Ereignisses mit dem neuen Wert über `CatalogValidator.validate_event()` und
zeigt die erste Fehlermeldung in der Fehlerfarbe neben dem Datum am Mauszeiger, etwa V10, wenn
Anzahl und Mindestabstand nicht mehr ins Fenster passen (US4, Szenario 2). Beim Loslassen geht
der Wert trotzdem an den Katalog; die Prüfung zeigt den Fehler dann wie jeden anderen.

## Simulator (SimulatorPanel)

```gdscript
class_name SimulatorPanel extends VBoxContainer
signal event_selected(id: String)        # Termin gewählt; die Werkstatt wählt das Ereignis mit,
                                         # wenn es noch im Katalog steht
const MAX_SEED := 2147483647
var editor: CatalogEditor
var run: TimelineRun                     # null bis „Fahrplan erzeugen“
func refresh() -> void                   # nach catalog_changed und issues_changed
func roll_seed() -> void                 # „Würfeln“ füllt nur das Feld
func generate_plan() -> void             # „Fahrplan erzeugen“ mit dem Seed aus dem Feld
func play_until(day: int) -> void        # alle Schalter laufen hierüber
```

Umgesetzt in Phase 7 (T052, T053): „+1 Monat“ und „+1 Jahr“ springen wie die Spieluhr zum
nächsten Ersten bzw. 1. Januar. „Bis“ ist ein Knopf mit Datumsfeld daneben, Enter im Feld spielt
ebenso ab; ein ungültiges oder schon gespieltes Datum spielt nichts ab und gibt einen Hinweis.
„? Katalog geändert, neu starten“ steht als Warnung in der Schalterzeile, ausgenommene Ereignisse
stehen als Fehlerfeld (Theme-Variante `ErrorNoticeLabel`) über der Tabelle. Rechts unter dem
Protokoll hält `%InterventionBox` den Platz für die Eingriffe aus Phase 8.

- **Oben:**
  - Seed-Feld, das nur Ziffern annimmt (0 bis 2.147.483.647, FR-040), „Würfeln“, „Fahrplan
    erzeugen“ und das aktuelle Datum;
  - „+1 Tag“, „+1 Monat“, „+1 Jahr“, „Bis …“ (Datum) und „Bis zum Ende“; der erste Schritt nach
    „Fahrplan erzeugen“ spielt den 01.01.1985 ab;
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
- **Katalog:** Jeder Lauf arbeitet auf `editor.catalog.without_faulty(editor.issues())`, also mit
  einer Kopie des aktuellen, auch ungespeicherten Stands (FR-042). Er ändert weder Spieluhr noch
  Katalog.
  - Ereignisse mit Fehlern fehlen damit im Lauf; ein Hinweis über der Tabelle nennt sie.
  - Ändert sich der Katalog während eines Laufs, zeigt der Hinweis „Katalog geändert, neu
    starten“, und der Lauf behält seinen Stand.
- **Eingriffe:** Das Panel sammelt sie in einer `WhatIfProbe` ohne Datei: jeden angenommenen
  Eingriff mit dem Tag, an dem er geschah, aus `TimelineRun.interventions`.
  - „Fahrplan erzeugen“ beginnt einen Lauf mit dem Seed aus dem Feld, vor dem 01.01.1985 und ohne
    Eingriffe; die gesammelten bleiben erhalten.
  - „Neu starten mit Eingriffen“ übernimmt Seed und Tag des aktuellen Laufs in die Probe und baut
    den Lauf mit `WhatIfProbe.build_run()` neu: bis zum Tag jedes Eingriffs abspielen, dort
    anwenden, dann weiter bis zu dem Tag, auf dem der alte Lauf stand (R22). Nicht anwendbare
    Eingriffe nennt ein Hinweis.
  - „Neu starten ohne Eingriffe“ spielt einen frischen Lauf mit demselben Seed bis zu diesem Tag;
    die gesammelten Eingriffe bleiben für den nächsten Neustart mit Eingriffen.
  - Die Eingriffe bleiben über Neustarts und Änderungen am Katalog erhalten, bis die Werkstatt
    schließt oder eine Probe geladen wird (FR-043). Abgelehnte Eingriffe zeigen `last_refusal`.

**Proben (FR-051, R22):**

```gdscript
class_name WhatIfProbe extends RefCounted
const FOLDER := "res://tools/werkstatt/proben/"
var id: String
var name: String
var seed: int
var until_day: int = -1                      # bis hierher war der Lauf beim Speichern abgespielt
var interventions: Array[Dictionary] = []    # Eingriffsprotokoll wie TimelineRun.interventions
var not_applicable: PackedStringArray = []   # nach build_run(): deutsche Sätze, etwa „Absage: Konkurrent eröffnet am 01.06.1992 nicht im Fahrplan“

static func list_probes(folder: String = FOLDER) -> Array[WhatIfProbe]   # alle Dateien im Ordner, nach Name
static func read_file(path: String) -> WhatIfProbe       # null und push_error bei unlesbarer Datei
func write_file(folder: String = FOLDER) -> Error         # folder + id + ".json", kanonisch wie der Katalog
func delete_file(folder: String = FOLDER) -> Error        # „Probe löschen“ (FR-051)
static func from_run(name: String, run: TimelineRun) -> WhatIfProbe   # Seed, today und Protokoll des Laufs
## Neuer Lauf mit seed auf catalog; spielt das Protokoll nach (data-model.md, „Neu abspielen“)
## und dann bis until_day. Füllt not_applicable.
func build_run(catalog: EventCatalog) -> TimelineRun
```

„Probe speichern …“ schreibt die Probe des Panels mit Namen, „Probe laden …“ setzt sie als
Eingriffe des Panels und baut den Lauf mit `build_run()`.

## Statistik (StatisticsPanel)

- **Eingaben:** Anzahl der Spiele (Vorgabe 1.000), „Mit Modifikatoren und Einplanungen aus dem
  Simulator“, „Starten“, „Abbrechen“ und ein Fortschrittsbalken.
- **Eingriffe:** Mit dem Häkchen bekommt die Statistik das Eingriffsprotokoll des Simulators;
  angewandt werden davon nur Modifikatoren und Einplanungen (FR-045).
- **Ablauf:** Je Bild `run_for(15)`, dazwischen `await get_tree().process_frame` (R17).
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

Solange ein Textfeld den Fokus hat, gehören Cmd+Z und Shift+Cmd+Z dem Textfeld. Enter und das
Verlassen des Felds übernehmen den Wert; Enter gibt dabei den Fokus ab (R15).
