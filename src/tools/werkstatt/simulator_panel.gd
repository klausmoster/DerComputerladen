class_name SimulatorPanel
extends VBoxContainer

## Der Simulator der Werkstatt (FR-040 bis FR-043, FR-051; contracts/werkstatt.md, „Simulator
## (SimulatorPanel)“): Klaus erzeugt aus einem Seed und dem Katalog einen Fahrplan und spielt ihn
## ab, ohne das Spiel zu starten. Oben stehen Seed, „Würfeln“, „Fahrplan erzeugen“, die Neustarts,
## die Proben und die Schalter für die Zeit mit dem Stand des Laufs. Links steht der Fahrplan als
## Tabelle, darunter die Begründung des gewählten Termins, rechts das Protokoll und darunter die
## Eingriffe.
##
## In der Vorgabe-Teilung, ohne gespeicherte Teiler, bekommen die Tabellen den Platz zuerst; die
## Bereiche darunter haben nur ihre Mindesthöhe (Klaus, 2026-10-21, T101). Die Begründung zeigt dann
## Titel und zwei Zeilen, der Rest rollt; die Eingriffe zeigen einen Modifikator. Unter 80 Pixel
## geht kein Bereich an einem Teiler (Werkstatt, „Teiler“). Mehr Mindesthöhe machte das Panel bei
## 1920 × 925 höher als seinen Reiter, und der Reiter nähme die Höhe dem Zeitstrahl, jedes Mal,
## wenn der Simulator nach vorn kommt.
##
## Gerechnet wird mit einem eigenen TimelineRun auf einer Kopie des Katalogs, wie er gerade in der
## Werkstatt steht, auch ungespeichert, und ohne die Ereignisse mit Fehlern (without_faulty()). Der
## Simulator kennt weder die Spieluhr noch das Autoload Timeline, und den Katalog liest er über den
## CatalogEditor nur.
##
## Ändert sich der Katalog während eines Laufs, rechnet der Lauf mit seiner Kopie weiter, und ein
## Hinweis sagt „Katalog geändert, neu starten“. Die Werkstatt ruft dafür nach catalog_changed und
## nach issues_changed refresh() auf: Beides kann den Katalog ändern, mit dem ein neuer Lauf
## rechnen würde.
##
## Was wäre, wenn (US6): Klaus setzt Modifikatoren, sagt Termine ab, verschiebt sie und plant
## Ereignisse ein. Jeden angenommenen Eingriff sammelt das Panel in [member probe], einer
## WhatIfProbe ohne Datei. Sie überlebt Neustarts und Änderungen am Katalog und wird erst durch eine
## geladene Probe ersetzt. Läuft ein Lauf mit Eingriffen, rechnet das Panel denselben Seed ohne sie
## bis zum selben Tag mit und markiert in der Tabelle, was anders ist (ScheduleDiff).
##
## Schwierigkeitsgrade (Feature 003, FR-018, R13): Neben dem Seed wählt Klaus in %DifficultyOption
## einen Grad, Vorgabe Mittel. Jeder Lauf hat seinen Grad fest ab dem Anlegen, wie im Spiel; ein
## Wechsel baut deshalb einen neuen Lauf, so, wie der alte war, nur mit dem neuen Grad. Die Auswahl
## zeigt immer den Grad des Laufs. Verglichen wird wie bisher mit demselben Grad ohne Eingriffe;
## das Häkchen %CompareMittel vergleicht stattdessen mit Mittel ohne Eingriffe und zeigt so, was
## der Grad bewirkt. Mit Mittel und ohne Häkchen läuft alles wie in Feature 002.

## Klaus hat im Fahrplan einen Termin gewählt; [param id] ist die Kennung seines Ereignisses. Die
## Werkstatt wählt das Ereignis dann auch in Liste, Formular und Zeitstrahl.
signal event_selected(id: String)

enum PlanColumn { DATE, EVENT, ORIGIN, STATE, DIFF }
enum ModifierColumn { EVENT, VALUE, FROM, TO, REASON }
enum ProbeColumn { NAME, SEED, DIFFICULTY, UNTIL, COUNT }
enum MenuItem { CANCEL, MOVE }

## Der größte Seed (FR-014, FR-040), wie im Autoload Timeline und in der Textausgabe.
const MAX_SEED := 2147483647
## Die Spalten des Fahrplans. „Unterschied“ gibt es nur, solange ein Lauf mit Eingriffen läuft.
const PLAN_TITLES: Array[String] = ["Datum", "Ereignis", "Herkunft", "Zustand", "Unterschied"]
## Breite der schmalen Spalten; das Ereignis nimmt den Rest. Mit der Spalte „Unterschied“ werden
## die übrigen schmaler, damit für das Ereignis Platz bleibt; was nicht passt, steht im Hinweis.
const PLAN_WIDTHS: Array[int] = [100, 0, 160, 100]
const PLAN_WIDTHS_WITH_DIFF: Array[int] = [92, 0, 112, 96, 116]
## Die Spalten, die bei einem weggefallenen Termin durchgestrichen sind. Der Unterschied bleibt
## lesbar, denn er sagt, warum.
const STRUCK_COLUMNS: Array[int] = [
	PlanColumn.DATE, PlanColumn.EVENT, PlanColumn.ORIGIN, PlanColumn.STATE,
]
const PROTOCOL_TITLES: Array[String] = ["Protokoll"]
const PROTOCOL_WIDTHS: Array[int] = [0]
const MODIFIER_TITLES: Array[String] = ["Ereignis", "Wert", "von", "bis", "Grund"]
const MODIFIER_WIDTHS: Array[int] = [0, 60, 100, 100, 0]
## Die Liste beim Laden; „Grad“ steht neben dem Seed, denn beide zusammen bestimmen das Spiel.
const PROBE_TITLES: Array[String] = ["Name", "Seed", "Grad", "Stand", "Eingriffe"]
const PROBE_WIDTHS: Array[int] = [0, 110, 80, 120, 90]
## Der Hinweis an „Entfernen“, solange ein Start-Modifikator gewählt ist (FR-010; Analyse, I4).
const START_MODIFIER_TIP := ("Start-Modifikatoren gehören zum Grad und lassen sich im laufenden "
	+ "Spiel nicht entfernen; ändern lassen sie sich im Reiter „Schwierigkeitsgrade“")
## Die Markierungen der Unterschiede: nicht nur Farbe, sondern Zeichen und Wort (Style-Guide).
## Verschoben nennt dazu den alten Tag.
const DIFF_TEXTS := {
	ScheduleDiff.Mark.ADDED: "+ neu",
	ScheduleDiff.Mark.MOVED: "→ verschoben",
	ScheduleDiff.Mark.STATE_CHANGED: "≠ Zustand",
	ScheduleDiff.Mark.REMOVED: "− weggefallen",
}
## Die Texte beim Vergleich mit demselben Grad ohne Eingriffe, wie in Feature 002: Jeder
## Unterschied kommt dort von den Eingriffen.
const DIFF_TIPS := {
	ScheduleDiff.Mark.ADDED: "Neu durch die Eingriffe; ohne sie gäbe es den Termin nicht.",
	ScheduleDiff.Mark.MOVED: "Ein Eingriff hat den Termin vom %s hierher verschoben.",
	ScheduleDiff.Mark.STATE_CHANGED: "Mit den Eingriffen in einem anderen Zustand als ohne sie.",
	ScheduleDiff.Mark.REMOVED: "Fällt durch die Eingriffe weg; ohne sie stünde der Termin hier.",
}
## Die zweite Reihe beim Vergleich mit Mittel ohne Eingriffe (Feature 003, R13): Ein Unterschied
## kann dort vom Grad kommen oder von einem Eingriff; die Texte nennen deshalb den Vergleichslauf.
## Verschieben kann nur ein Eingriff.
const DIFF_TIPS_MITTEL := {
	ScheduleDiff.Mark.ADDED: "Neu gegenüber Mittel ohne Eingriffe; dort gibt es den Termin nicht.",
	ScheduleDiff.Mark.MOVED: "Ein Eingriff hat den Termin vom %s hierher verschoben.",
	ScheduleDiff.Mark.STATE_CHANGED: "In einem anderen Zustand als bei Mittel ohne Eingriffe.",
	ScheduleDiff.Mark.REMOVED:
		"Fällt gegenüber Mittel ohne Eingriffe weg; dort stünde der Termin hier.",
}
## Der Hinweis an „nur Unterschiede“ beim Vergleich mit Mittel; sonst gilt der aus der Szene.
const DIFF_FILTER_TIP_MITTEL := "Zeigt nur Termine, die anders sind als bei Mittel ohne Eingriffe."
## %CompareLabel, wenn es keinen Vergleichslauf gibt (Analyse, A3).
const NO_COMPARISON := "Kein Vergleich: Der Lauf hat keine Eingriffe."

## Der einzige, der den Katalog ändert; der Simulator liest nur daraus. Die Werkstatt setzt ihn.
var editor: CatalogEditor
## Der aktuelle Lauf; null, bis „Fahrplan erzeugen“ einen anlegt.
var run: TimelineRun
## Die gesammelten Eingriffe in der Reihenfolge, in der Klaus sie gemacht hat, jeder mit seinem
## Tag; dazu Seed, Tag, Kennung und Name, sobald die Probe gespeichert oder geladen ist. Ein
## Neustart mit Eingriffen spielt sie nach at_day geordnet nach (WhatIfProbe.build_run()); die
## Liste selbst bleibt in der Reihenfolge der Aktionen. Sie ist nie einfach eine Kopie von
## run.interventions: Darin stehen nach einem Neustart nur die anwendbaren.
var probe := WhatIfProbe.new()
## Hier liegen die Proben; Tests setzen einen eigenen Ordner unter user://.
var probe_folder: String = WhatIfProbe.FOLDER
## Ob der Fahrplan mit Mittel ohne Eingriffe vergleicht statt mit demselben Grad ohne Eingriffe
## (FR-018, R13). Das Häkchen %CompareMittel setzt es; wer es aus dem Code setzt, setzt das Häkchen
## mit, und der Vergleich rechnet neu. Bei Mittel ändert es nichts (Edge Case „Vergleich bei
## Mittel“).
var compare_with_mittel: bool = false:
	set(value):
		if value == compare_with_mittel:
			return
		compare_with_mittel = value
		if is_node_ready():
			_compare_mittel.set_pressed_no_signal(value)
			_on_comparison_changed()

## Der Katalog, mit dem der Lauf rechnet, als Text (_catalog_key()). Daran erkennt refresh(), dass
## sich der Katalog seitdem geändert hat.
var _run_key := ""
## Ob ein neuer Lauf jetzt mit einem anderen Katalog rechnen würde als der aktuelle.
var _stale := false
## Was der Lauf wegen Fehlern auslässt: die Titel der Ereignisse, dann die Orte der
## Start-Modifikatoren.
var _excluded := PackedStringArray()
## Der Hinweis an „Entfernen“ aus der Szene; er gilt, solange kein Start-Modifikator gewählt ist.
var _remove_tip := ""
## Der Hinweis an „nur Unterschiede“ aus der Szene, für den Vergleich mit demselben Grad.
var _diff_filter_tip := ""
## Was sich beim letzten Neustart mit Eingriffen oder beim Laden nicht anwenden ließ.
var _not_applicable := PackedStringArray()
## Der gewählte Termin: eine laufende Nummer im Lauf, sonst −1; oder ein weggefallener Termin aus
## dem Lauf ohne Eingriffe, sonst null.
var _selected_serial := -1
var _selected_removed: ScheduleEntry
var _refresh_queued := false
## Ob der Simulator die Tabelle gerade selbst füllt; ihre Signale zählen dann nicht.
var _syncing := false
## Derselbe Seed ohne Eingriffe bis zum selben Tag und der Vergleich mit dem Lauf; beide null,
## solange der Lauf keine Eingriffe hat.
var _baseline: TimelineRun
var _diff: ScheduleDiff
## Die Zeilen der weggefallenen Termine; _draw_struck_rows() streicht sie durch.
var _struck_items: Array[TreeItem] = []
## Wie viele Meldungen des Laufs das Protokoll schon zeigt.
var _protocol_count := 0
## Die Proben im Dialog „Probe laden“, an derselben Stelle wie in der Liste.
var _listed: Array[WhatIfProbe] = []
## Der Name, unter dem nach der Rückfrage „Überschreiben?“ gespeichert wird.
var _pending_name := ""
## Streifen, Auswahl und Überfahren der vier Tabellen (Zebra).
var _plan_zebra: Zebra
var _protocol_zebra: Zebra
var _modifier_zebra: Zebra
var _probe_zebra: Zebra
## Liegt über dem Fahrplan und zeichnet die Striche durch weggefallene Termine. Der Tree malt seine
## Zeilen auf eine eigene Ebene über allem, was er selbst zeichnet; nur ein Kind liegt darüber.
var _strike_overlay := Control.new()

@onready var _run_bar: HFlowContainer = %RunBar
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _roll_button: Button = %RollButton
@onready var _difficulty_option: OptionButton = %DifficultyOption
@onready var _generate_button: Button = %GenerateButton
@onready var _restart_with_button: Button = %RestartWithButton
@onready var _restart_without_button: Button = %RestartWithoutButton
@onready var _save_probe_button: Button = %SaveProbeButton
@onready var _load_probe_button: Button = %LoadProbeButton
@onready var _delete_probe_button: Button = %DeleteProbeButton
@onready var _day_button: Button = %DayButton
@onready var _month_button: Button = %MonthButton
@onready var _year_button: Button = %YearButton
@onready var _until_button: Button = %UntilButton
@onready var _until_edit: LineEdit = %UntilEdit
@onready var _end_button: Button = %EndButton
@onready var _date_label: Label = %DateLabel
@onready var _input_hint: Label = %InputHint
@onready var _catalog_notice: Label = %CatalogNotice
@onready var _excluded_notice: Label = %ExcludedNotice
@onready var _probe_notice: Label = %ProbeNotice
@onready var _state_filter: OptionButton = %StateFilter
@onready var _diff_filter: CheckBox = %DiffFilter
@onready var _compare_mittel: CheckBox = %CompareMittel
@onready var _compare_label: Label = %CompareLabel
@onready var _plan_count: Label = %PlanCount
@onready var _plan_table: Tree = %PlanTable
@onready var _cancel_button: Button = %CancelButton
@onready var _move_button: Button = %MoveButton
@onready var _detail_title: Label = %DetailTitle
@onready var _detail_text: Label = %DetailText
@onready var _protocol: Tree = %Protocol
@onready var _probe_label: Label = %ProbeLabel
@onready var _modifier_button: Button = %ModifierButton
@onready var _schedule_button: Button = %ScheduleButton
@onready var _modifier_list: Tree = %ModifierList
@onready var _remove_modifier_button: Button = %RemoveModifierButton
@onready var _chance_label: Label = %ChanceLabel
@onready var _intervention_hint: Label = %InterventionHint
@onready var _plan_menu: PopupMenu = %PlanMenu
@onready var _dialog: InterventionDialog = %InterventionDialog
@onready var _save_dialog: ConfirmationDialog = %SaveProbeDialog
@onready var _probe_name_edit: LineEdit = %ProbeNameEdit
@onready var _save_hint: Label = %SaveHint
@onready var _overwrite_dialog: ConfirmationDialog = %OverwriteDialog
@onready var _load_dialog: ConfirmationDialog = %LoadProbeDialog
@onready var _probe_list: Tree = %ProbeList
@onready var _load_hint: Label = %LoadHint
@onready var _delete_dialog: ConfirmationDialog = %DeleteProbeDialog


func _ready() -> void:
	_set_up_table(_plan_table, PLAN_TITLES.slice(0, PlanColumn.DIFF), PLAN_WIDTHS)
	_set_up_table(_protocol, PROTOCOL_TITLES, PROTOCOL_WIDTHS)
	_set_up_table(_modifier_list, MODIFIER_TITLES, MODIFIER_WIDTHS)
	_set_up_table(_probe_list, PROBE_TITLES, PROBE_WIDTHS)
	_plan_zebra = Zebra.new(_plan_table)
	_protocol_zebra = Zebra.new(_protocol)
	_modifier_zebra = Zebra.new(_modifier_list)
	_probe_zebra = Zebra.new(_probe_list)
	_strike_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plan_table.add_child(_strike_overlay, false, Node.INTERNAL_MODE_FRONT)
	_strike_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_strike_overlay.draw.connect(_draw_struck_rows)
	# Rollt oder malt der Fahrplan neu, malt die Ebene darüber im selben Bild mit.
	_plan_table.draw.connect(_strike_overlay.queue_redraw)
	_state_filter.add_item("Alle Zustände")
	# Die Namen der Zustände kennt ScheduleEntry; ein Termin ohne Lauf liefert sie.
	var probe_entry := ScheduleEntry.new()
	for state: int in ScheduleEntry.State.values():
		probe_entry.state = state as ScheduleEntry.State
		_state_filter.add_item(probe_entry.state_label())
	_plan_menu.add_item("Absagen …", MenuItem.CANCEL)
	_plan_menu.add_item("Verschieben …", MenuItem.MOVE)
	_remove_tip = _remove_modifier_button.tooltip_text
	_diff_filter_tip = _diff_filter.tooltip_text
	_compare_mittel.set_pressed_no_signal(compare_with_mittel)
	_connect_signals()
	_reset_protocol()
	_fill_plan()
	_fill_modifiers()
	_show_detail()
	_update_notices()
	_update_controls()


func _connect_signals() -> void:
	# Hat die Leiste ihre Kinder auf die Zeilen verteilt, stehen deren Positionen fest.
	_run_bar.sort_children.connect(_update_run_bar_separators)
	_seed_edit.text_changed.connect(_on_seed_changed)
	_seed_edit.text_submitted.connect(func(_text: String) -> void: generate_plan())
	_roll_button.pressed.connect(roll_seed)
	# Die Kennung eines Eintrags ist sein Grad (Szene: id 0 bis 2 wie Difficulty.Level).
	_difficulty_option.item_selected.connect(func(index: int) -> void:
		select_difficulty(_difficulty_option.get_item_id(index) as Difficulty.Level))
	_generate_button.pressed.connect(generate_plan)
	_restart_with_button.pressed.connect(restart.bind(true))
	_restart_without_button.pressed.connect(restart.bind(false))
	_save_probe_button.pressed.connect(_open_save_dialog)
	_load_probe_button.pressed.connect(_open_load_dialog)
	_delete_probe_button.pressed.connect(_open_delete_dialog)
	_day_button.pressed.connect(func() -> void: play_until(_today() + 1))
	_month_button.pressed.connect(func() -> void: play_until(_first_of_next_month(_today())))
	_year_button.pressed.connect(func() -> void: play_until(_first_of_next_year(_today())))
	_until_button.pressed.connect(_on_until_pressed)
	_until_edit.text_submitted.connect(func(_text: String) -> void: _on_until_pressed())
	_end_button.pressed.connect(func() -> void: play_until(TimelineRun.LAST_DAY))
	_state_filter.item_selected.connect(func(_index: int) -> void: _fill_plan())
	_diff_filter.toggled.connect(func(_on: bool) -> void: _fill_plan())
	_compare_mittel.toggled.connect(func(on: bool) -> void: compare_with_mittel = on)
	_plan_table.item_selected.connect(_on_plan_item_selected)
	_plan_table.item_mouse_selected.connect(_on_plan_mouse_selected)
	_plan_menu.id_pressed.connect(_on_plan_menu)
	_cancel_button.pressed.connect(_open_cancel_dialog)
	_move_button.pressed.connect(_open_move_dialog)
	_modifier_button.pressed.connect(_open_modifier_dialog)
	_schedule_button.pressed.connect(_open_schedule_dialog)
	_modifier_list.item_selected.connect(_update_controls)
	_remove_modifier_button.pressed.connect(_remove_selected_modifier)
	_save_dialog.confirmed.connect(_on_save_confirmed)
	_save_dialog.register_text_enter(_probe_name_edit)
	_overwrite_dialog.confirmed.connect(func() -> void: _finish_save(_pending_name))
	_load_dialog.confirmed.connect(_on_load_confirmed)
	_probe_list.item_selected.connect(func() -> void:
		_load_dialog.get_ok_button().disabled = false)
	_probe_list.item_activated.connect(_on_load_confirmed)
	_delete_dialog.confirmed.connect(_on_delete_confirmed)


# --- Für die Werkstatt ------------------------------------------------------------------------

## Nach catalog_changed und issues_changed: prüft am Ende des Bilds, ob ein neuer Lauf jetzt mit
## einem anderen Katalog rechnen würde als der aktuelle, und zeigt dann „Katalog geändert, neu
## starten“. Der Lauf selbst behält seinen Stand (FR-042). Am Ende des Bilds, weil beide Signale
## nach jeder Änderung kommen; so wird nur einmal verglichen.
func refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_apply_refresh.call_deferred()


## „Würfeln“: ein zufälliger Seed von 0 bis 2.147.483.647 ins Feld. Erzeugt wird erst mit
## „Fahrplan erzeugen“.
func roll_seed() -> void:
	_seed_edit.text = str(randi_range(0, MAX_SEED))
	_update_controls()


## Der Grad in %DifficultyOption. Mit einem Lauf ist es immer dessen Grad (R13).
func selected_difficulty() -> Difficulty.Level:
	return _difficulty_option.get_selected_id() as Difficulty.Level


## Wie eine Wahl durch Klaus in %DifficultyOption (FR-018, R13): Gibt es einen Lauf mit einem
## anderen Grad, baut der Simulator ihn mit dem neuen Grad neu, so, wie er war; siehe
## _switch_difficulty(). Ohne Lauf merkt sich die Auswahl den Grad nur für „Fahrplan erzeugen“.
## Ein unbekannter Grad wie 7 ändert nichts.
func select_difficulty(level: Difficulty.Level) -> void:
	if not Difficulty.is_valid(level):
		return
	_difficulty_option.select(level)
	if run != null and run.difficulty != level:
		_switch_difficulty(level)


## „Fahrplan erzeugen“ (FR-040, FR-042): ein neuer Lauf mit dem Seed aus dem Feld und dem Grad aus
## der Auswahl, auf einer Kopie des Katalogs, wie er gerade in der Werkstatt steht, ohne die
## Ereignisse mit Fehlern und ohne Eingriffe; die gesammelten bleiben. Der Lauf steht vor dem
## 01.01.1985; im Fahrplan stehen alle Termine, die schon feststehen, als „geplant“ (US5,
## Szenario 1).
func generate_plan() -> void:
	if not _can_generate():
		return
	run = TimelineRun.new(_effective_catalog(), _seed_edit.text.to_int(), selected_difficulty())
	_start_run(PackedStringArray())


## Spielt den Lauf bis einschließlich [param day] ab, höchstens bis zum 31.12.1999 (FR-041). Der
## erste Schritt nach „Fahrplan erzeugen“ spielt den 01.01.1985 ab; Tage, die schon abgespielt
## sind, ändern nichts. Danach stehen die neuen Meldungen im Protokoll und die Zustände im Fahrplan.
func play_until(day: int) -> void:
	if run == null:
		return
	var target := mini(day, TimelineRun.LAST_DAY)
	if target <= run.today:
		return
	run.advance_to(target)
	_show_input_problem("")
	_after_change()


## „Neu starten mit Eingriffen“ bzw. „ohne Eingriffe“ (FR-043): ein frischer Lauf mit dem Seed des
## aktuellen Laufs auf dem Katalog, wie er jetzt dasteht. Ohne Eingriffe spielt er bis zu dem Tag,
## auf dem der alte Lauf stand. Mit Eingriffen spielt WhatIfProbe.build_run() die gesammelten an
## ihren Tagen nach (R22), bis zum Endtag aus _end_day(); was nicht passt, nennt ein Hinweis. Die
## gesammelten Eingriffe bleiben so oder so.
##
## Beide behalten den Grad des Laufs (Feature 003). Die Probe des Panels bekommt ihn deshalb wie
## den Seed vor build_run(); sonst bliebe dort der Grad einer früher geladenen Probe, und nach
## „Probe laden“ mit Schwer und „Fahrplan erzeugen“ mit Leicht spielte der Neustart Schwer.
func restart(with_interventions: bool) -> void:
	if run == null or not _has_catalog():
		return
	if with_interventions:
		probe.seed = run.seed
		probe.difficulty = run.difficulty
		probe.until_day = _end_day()
		run = probe.build_run(_effective_catalog())
		_start_run(probe.not_applicable)
		return
	var fresh := TimelineRun.new(_effective_catalog(), run.seed, run.difficulty)
	fresh.advance_to(run.today)
	run = fresh
	_start_run(PackedStringArray())


## Lädt eine Probe (FR-051, FR-019): Ihre Eingriffe ersetzen die gesammelten, Seed und Grad kommen
## in Feld und Auswahl, und der Lauf entsteht mit build_run() auf dem Katalog, wie er jetzt
## dasteht. Die Auswahl springt dabei ohne eigenen Neubau um, denn die Probe baut ihren Lauf selbst.
## Eingriffe, die sich nicht mehr anwenden lassen, nennt ein Hinweis (US6, Szenario 8).
func load_probe(loaded: WhatIfProbe) -> void:
	if loaded == null or not _has_catalog():
		return
	probe = loaded
	_seed_edit.text = str(probe.seed)
	run = probe.build_run(_effective_catalog())
	_start_run(probe.not_applicable)


## Schreibt die gesammelten Eingriffe mit Seed und Grad des aktuellen Laufs und dem Endtag aus
## _end_day() als Probe [param probe_name] nach probe_folder (FR-051). Die Kennung, zugleich der
## Dateiname, entsteht aus dem Namen; eine Probe mit derselben Kennung wird überschrieben, gefragt
## wird vorher im Dialog. Danach gehören Name und Kennung zur Probe des Panels, „Probe löschen“
## meint diese.
func save_probe(probe_name: String) -> Error:
	if run == null:
		return ERR_UNCONFIGURED
	var saved := WhatIfProbe.new()
	saved.name = probe_name.strip_edges()
	saved.id = CatalogEditor.id_from(saved.name, "probe")
	saved.seed = run.seed
	saved.difficulty = run.difficulty
	saved.until_day = _end_day()
	saved.interventions = probe.interventions.duplicate(true)
	var error := saved.write_file(probe_folder)
	if error == OK:
		probe.id = saved.id
		probe.name = saved.name
		probe.seed = saved.seed
		probe.difficulty = saved.difficulty
		probe.until_day = saved.until_day
	_update_controls()
	return error


## Löscht die Datei der Probe, die zuletzt gespeichert oder geladen wurde. Die gesammelten
## Eingriffe bleiben im Simulator, nur ohne Datei.
func delete_probe() -> Error:
	if probe.id.is_empty():
		return ERR_DOES_NOT_EXIST
	var error := probe.delete_file(probe_folder)
	if error == OK:
		probe.id = ""
		probe.name = ""
	_update_controls()
	return error


## Die Zeilen der weggefallenen Termine, die durchgestrichen sind; für die Tests.
func struck_rows() -> Array[TreeItem]:
	return _struck_items.duplicate()


# --- Lauf -------------------------------------------------------------------------------------

## Gemeinsam für „Fahrplan erzeugen“, die Neustarts, den Wechsel des Grads und das Laden einer
## Probe: Der neue Lauf steht in run; alles, was am alten hing, beginnt neu. Die Auswahl zeigt
## danach seinen Grad. select() meldet kein item_selected, baut also nicht noch einmal neu.
func _start_run(not_applicable: PackedStringArray) -> void:
	_difficulty_option.select(run.difficulty)
	_run_key = _catalog_key()
	_stale = false
	_excluded = _excluded_titles()
	_not_applicable = not_applicable.duplicate()
	_selected_serial = -1
	_selected_removed = null
	_baseline = null
	_show_input_problem("")
	_show_intervention_problem("")
	_update_diff()
	_reset_protocol()
	_fill_plan()
	_fill_modifiers()
	_show_detail()
	_update_notices()
	_update_controls()


## Wechsel des Grads mit einem Lauf (R13): Der neue Lauf entsteht so, wie der alte war, nur mit
## [param level]. Dafür baut eine eigene, kurzlebige WhatIfProbe ihn auf: derselbe Seed, dieselben
## angewandten Eingriffe (run.interventions) an ihren Tagen und derselbe Tag, mit dem aktuellen
## Katalog wie bei jedem Neustart. Ein Lauf ohne Eingriffe bleibt so ohne, und Eingriffe, die schon
## im alten Lauf nicht anwendbar waren, versucht der Wechsel nicht neu (Review, CHK029).
##
## Die gesammelten Eingriffe in [member probe] bleiben unberührt, für „Neu starten mit Eingriffen“;
## nur ihr Grad wird der neue. Was im neuen Grad nicht anwendbar ist, etwa die Absage eines
## gewürfelten Termins, den es dort nicht gibt, nennt %ProbeNotice.
func _switch_difficulty(level: Difficulty.Level) -> void:
	if not _has_catalog():
		return
	var rebuild := WhatIfProbe.new()
	rebuild.seed = run.seed
	rebuild.difficulty = level
	rebuild.interventions = run.interventions.duplicate(true)
	# Der Lauf steht nie vor seinem letzten Eingriff, denn er spielt nie zurück.
	rebuild.until_day = run.today
	run = rebuild.build_run(_effective_catalog())
	probe.difficulty = level
	_start_run(rebuild.not_applicable)


## Nach jedem Schritt und jedem Eingriff: Unterschiede, Protokoll, Fahrplan, Modifikatoren und die
## Begründung zeigen den neuen Stand.
func _after_change() -> void:
	_update_diff()
	_sync_protocol()
	_fill_plan()
	_fill_modifiers()
	_show_detail()
	_update_controls()


## Bis wohin „Neu starten mit Eingriffen“ spielt und welchen Stand „Probe speichern“ festhält: der
## spätere Tag aus dem Stand des Laufs und dem letzten at_day der gesammelten Eingriffe, höchstens
## der 31.12.1999. Früher geht es nicht, denn um einen Eingriff nachzuspielen, muss der Lauf bis zu
## dessen Tag kommen, und zurück spielt er nie. Beispiel: Gesammelt ist ein Modifikator vom
## 01.01.1992, dann kam „Fahrplan erzeugen“; der Lauf steht vor dem 01.01.1985, der Endtag ist der
## 01.01.1992. Nur für einen Lauf, also run != null.
func _end_day() -> int:
	var day := run.today
	for record in probe.interventions:
		# Ohne lesbaren Tag gibt es −1; das hebt den Endtag nie.
		day = maxi(day, TimelineRun.intervention_day(record))
	return mini(day, TimelineRun.LAST_DAY)


func _effective_catalog() -> EventCatalog:
	return editor.catalog.without_faulty(editor.issues())


func _has_catalog() -> bool:
	return editor != null and editor.catalog != null


# --- Seed und Schalter ------------------------------------------------------------------------

## Das Seed-Feld nimmt nur Ziffern an, höchstens 2.147.483.647 (FR-040). Ein LineEdit meldet
## text_changed erst am Ende des Bilds, gesammelt für alles, was in diesem Bild getippt oder
## eingefügt wurde; gezeichnet ist da noch nichts. Was keine Ziffer ist, fällt also weg, bevor
## Klaus es sieht. Eine größere Zahl wird zum größten Seed.
func _on_seed_changed(text: String) -> void:
	var digits := ""
	for character in text:
		if character >= "0" and character <= "9":
			digits += character
	# Der Cursor stand hinter dem Getippten; was wegfällt, stand davor.
	var caret := _seed_edit.caret_column - (text.length() - digits.length())
	# Die Länge zuerst, ohne führende Nullen: Eine sehr lange Zahl liefe in to_int() über.
	if digits.lstrip("0").length() > 10 or digits.to_int() > MAX_SEED:
		digits = str(MAX_SEED)
		caret = digits.length()
	if digits != text:
		_seed_edit.text = digits
		_seed_edit.caret_column = clampi(caret, 0, digits.length())
	_update_controls()


## „Bis“ mit dem Datum aus dem Feld daneben, auch ohne führende Nullen wie „1.3.1993“. Ein
## Datum, das nicht passt, spielt nichts ab; ein Hinweis sagt, warum.
func _on_until_pressed() -> void:
	if run == null:
		return
	var parsed := EventForm.parse_date(_until_edit.text)
	var day: int = parsed[1] if parsed[0] else -1
	var problem := ""
	if _until_edit.text.strip_edges().is_empty():
		problem = "Gib ein Datum ein, etwa 31.12.1990."
	elif not parsed[0]:
		problem = parsed[1]
	elif day < TimelineRun.FIRST_DAY or day > TimelineRun.LAST_DAY:
		problem = "Der Simulator spielt vom 01.01.1985 bis zum 31.12.1999."
	elif day <= run.today:
		problem = "Der %s ist schon abgespielt." % EventForm.format_date(day)
	_show_input_problem(problem)
	if problem.is_empty():
		_until_edit.text = EventForm.format_date(day)
		play_until(day)


## Zeigt [param problem] unter den Schaltern; das Datumsfeld bekommt dann die rote Kontur des
## Fehlers (Style-Guide, „Bedienelemente“). Ein leerer Text nimmt beides weg.
func _show_input_problem(problem: String) -> void:
	_input_hint.text = problem
	_input_hint.visible = not problem.is_empty()
	_until_edit.theme_type_variation = &"" if problem.is_empty() else &"ErrorLineEdit"


## Die Leiste oben bricht um, wenn der Platz nicht reicht; die drei Knöpfe der Proben stehen in
## einer eigenen Gruppe (%ProbeButtons) und brechen nur gemeinsam um. Ein Trennstrich gilt nur
## zwischen zwei Nachbarn in derselben Zeile; bricht die Gruppe dahinter um, stünde er allein am
## Zeilenende und wird durchsichtig. Durchsichtig statt unsichtbar: Er behält seine Breite. Ohne
## sie passte die Gruppe wieder in die Zeile, der Strich käme zurück, und die Leiste spränge von
## Bild zu Bild zwischen beiden Umbrüchen hin und her.
func _update_run_bar_separators() -> void:
	var children := _run_bar.get_children()
	for index in children.size():
		var separator := children[index] as VSeparator
		if separator == null:
			continue
		var between := index > 0 and index + 1 < children.size() \
			and _same_line(separator, children[index - 1] as Control) \
			and _same_line(separator, children[index + 1] as Control)
		separator.self_modulate.a = 1.0 if between else 0.0


## Ob [param a] und [param b] in derselben Zeile einer Leiste stehen: Ihre Höhen überschneiden
## sich. Die Lage oben allein genügt nicht, denn ein Label steht in seiner Zeile mittig.
static func _same_line(a: Control, b: Control) -> bool:
	return a.position.y < b.position.y + b.size.y and b.position.y < a.position.y + a.size.y


func _today() -> int:
	return run.today if run != null else TimelineRun.FIRST_DAY - 1


## Der Erste des Monats nach [param day], wie GameClock.advance_one_month(). Vor dem Spielbeginn
## steht der Lauf auf −1, dem 31.12.1984, und der nächste Erste ist der 01.01.1985.
static func _first_of_next_month(day: int) -> int:
	var date := GameDate.from_day_index(day)
	if date.month == 12:
		return GameDate.new(date.year + 1, 1, 1).to_day_index()
	return GameDate.new(date.year, date.month + 1, 1).to_day_index()


## Der 1. Januar des Jahres nach [param day], wie GameClock.advance_one_year(); vor dem
## Spielbeginn also der 01.01.1985.
static func _first_of_next_year(day: int) -> int:
	return GameDate.new(GameDate.from_day_index(day).year + 1, 1, 1).to_day_index()


func _can_generate() -> bool:
	return _has_catalog() and not _seed_edit.text.is_empty()


## Sperrt, was gerade nicht geht, und schreibt den Stand des Laufs und der Probe.
func _update_controls() -> void:
	_generate_button.disabled = not _can_generate()
	if not _has_catalog():
		_generate_button.tooltip_text = "Ohne lesbaren Katalog gibt es keinen Fahrplan."
	elif _seed_edit.text.is_empty():
		_generate_button.tooltip_text = "Gib zuerst einen Seed ein oder würfle einen."
	else:
		_generate_button.tooltip_text = ("Neuer Lauf mit diesem Seed und Grad und dem Katalog, "
			+ "wie er gerade dasteht, auch ungespeichert, ohne Eingriffe. Die Spieluhr bleibt, wie "
			+ "sie ist.")
	var can_play := run != null and not run.is_finished()
	for button: Button in [_day_button, _month_button, _year_button, _until_button, _end_button]:
		button.disabled = not can_play
	_restart_with_button.disabled = run == null or probe.interventions.is_empty()
	_restart_without_button.disabled = run == null
	_save_probe_button.disabled = run == null
	_load_probe_button.disabled = not _has_catalog()
	_delete_probe_button.disabled = probe.id.is_empty()
	_delete_probe_button.tooltip_text = "Die Probe „%s“ löschen" % probe.name \
		if not probe.id.is_empty() else "Löscht die zuletzt gespeicherte oder geladene Probe."
	_modifier_button.disabled = run == null
	_schedule_button.disabled = run == null
	_cancel_button.disabled = _selected_run_entry() == null
	_move_button.disabled = _selected_run_entry() == null
	# Ein Start-Modifikator gehört zum Grad; „Entfernen“ sagt dann, warum es nicht geht.
	var chosen := _modifier_list.get_selected()
	var is_start := chosen != null and _is_start_modifier_row(chosen)
	_remove_modifier_button.disabled = chosen == null or is_start
	_remove_modifier_button.tooltip_text = START_MODIFIER_TIP if is_start else _remove_tip
	_diff_filter.disabled = _diff == null
	_diff_filter.tooltip_text = DIFF_FILTER_TIP_MITTEL if _compares_with_mittel() \
		else _diff_filter_tip
	# Zu lang für die Leiste, endet der Text mit „…“; ganz steht er im Hinweis.
	_compare_label.text = _comparison_text()
	_compare_label.tooltip_text = _compare_label.text
	_date_label.text = _date_text()
	_probe_label.text = _probe_text()


## „Stand: 22.03.1993 · Seed 4711“; vor dem ersten Schritt „vor dem 01.01.1985“.
func _date_text() -> String:
	if run == null:
		return "Kein Katalog geladen" if not _has_catalog() else "Noch kein Fahrplan"
	var when := "vor dem 01.01.1985"
	if run.is_finished():
		when = "%s, Spielende" % EventForm.format_date(run.today)
	elif run.today >= TimelineRun.FIRST_DAY:
		when = EventForm.format_date(run.today)
	return "Stand: %s · Seed %d" % [when, run.seed]


## „3 Eingriffe gesammelt · Probe „Windiger Händler ab 1990““.
func _probe_text() -> String:
	var count := probe.interventions.size()
	var text := "%s %s gesammelt" % [_grouped(count), "Eingriff" if count == 1 else "Eingriffe"]
	if not probe.name.is_empty():
		text += " · Probe „%s“" % probe.name
	return text


# --- Katalog ----------------------------------------------------------------------------------

func _apply_refresh() -> void:
	_refresh_queued = false
	_stale = run != null and _catalog_key() != _run_key
	_update_notices()
	_update_controls()


## Der Katalog, mit dem ein neuer Lauf jetzt rechnen würde, als Text: sein Inhalt
## (CatalogEditor.content_key(), so genau wie die kanonische Form, mit den Profilen), die
## Kennungen, die without_faulty() wegen Fehlern auslässt, und die Stellen der
## Start-Modifikatoren, die es weglässt. Ist alles gleich, rechnete ein neuer Lauf mit demselben
## Katalog. So verschwindet der Hinweis auch wieder, wenn Klaus eine Änderung rückgängig macht.
func _catalog_key() -> String:
	if not _has_catalog():
		return ""
	var issues := editor.issues()
	var faulty := PackedStringArray()
	for issue in issues:
		if issue.severity == CatalogIssue.Severity.ERROR and not faulty.has(issue.event_id):
			faulty.append(issue.event_id)
	faulty.sort()
	var skipped := PackedStringArray()
	for skip in editor.catalog.skipped_start_modifiers(issues):
		skipped.append("%d:%d" % [skip["level"], skip["index"]])
	return "%s\n%s\n%s" % [editor.content_key(), ",".join(faulty), ",".join(skipped)]


## Was im Katalog der Werkstatt steht, aber nicht im Lauf, weil es Fehler hat: die Titel der
## Ereignisse, die without_faulty() ausgenommen hat, dann die Orte der Start-Modifikatoren, die es
## weglässt (FR-013; Analyse, G1). Das sind die mit eigenem Fehler und die, deren Ereignis
## ausgenommen ist, aus allen Profilen, wie in der Prüfung; etwa „Profil „Schwer“,
## Start-Modifikator „reklamationswelle““.
func _excluded_titles() -> PackedStringArray:
	var kept := {}
	for event in run.catalog.events:
		kept[event.id] = true
	var titles := PackedStringArray()
	for event in editor.catalog.events:
		if not kept.has(event.id):
			titles.append("„%s“" % _title_of(event))
	for skip in editor.catalog.skipped_start_modifiers(editor.issues()):
		titles.append(skip["place"])
	return titles


## Die Hinweise über der Tabelle: eine Warnung als Text in holz mit „?“, ein Fehler als gefülltes
## Feld in kassenrot mit „!“ (Style-Guide, „Farbrollen“).
func _update_notices() -> void:
	_catalog_notice.visible = run != null and _stale
	_excluded_notice.visible = run != null and not _excluded.is_empty()
	if _excluded_notice.visible:
		_excluded_notice.text = ("! Ausgenommen, weil fehlerhaft: %s. Die Gründe stehen in der "
			+ "Prüfung.") % ", ".join(_excluded)
	_probe_notice.visible = run != null and not _not_applicable.is_empty()
	if _probe_notice.visible:
		_probe_notice.text = "? Nicht anwendbar, deshalb weggelassen:\n%s" \
			% "\n".join(_not_applicable)


# --- Eingriffe --------------------------------------------------------------------------------

## Ein Eingriff ist geschehen oder abgelehnt worden. Abgelehnt: der Grund aus last_refusal kommt
## zurück, im Dialog steht er dann. Angenommen: Der neue Eintrag des Eingriffsprotokolls kommt in
## die gesammelten Eingriffe, und alles zeigt den neuen Stand.
func _after_intervention(error: Error) -> String:
	if error != OK:
		return run.last_refusal
	probe.interventions.append(run.interventions.back().duplicate(true))
	_show_intervention_problem("")
	_after_change()
	return ""


func _open_modifier_dialog() -> void:
	if run == null:
		return
	var events := _events_where(func(event: TimelineEvent) -> bool:
		return event.kind == TimelineEvent.Kind.CHANCE)
	_dialog.open_modifier(events, _selected_event_id(), maxi(run.today, TimelineRun.FIRST_DAY),
		_apply_modifier)


## Setzt den Modifikator aus dem Dialog. Seine Kennung entsteht aus dem Grund und ist eindeutig,
## denn FR-025 verlangt eine (Ware vom windigen Händler → ware_vom_windigen_haendler).
func _apply_modifier(values: Dictionary) -> String:
	var modifier := ChanceModifier.new()
	modifier.id = _new_modifier_id(values["reason"])
	modifier.event_id = values["event_id"]
	modifier.value = values["value"]
	modifier.reason = values["reason"]
	modifier.from_day = values["from_day"]
	modifier.to_day = values["to_day"]
	return _after_intervention(run.add_modifier(modifier))


## Eine Kennung aus [param reason], die weder im Lauf noch unter den gesammelten Eingriffen schon
## vergeben ist; sonst lehnte ein Neustart mit Eingriffen den zweiten gleichen Modifikator ab.
func _new_modifier_id(reason: String) -> String:
	var taken := {}
	for modifier in run.modifiers:
		taken[modifier.id] = true
	for record in probe.interventions:
		var data: Variant = record.get("modifier")
		if typeof(data) == TYPE_DICTIONARY:
			taken[str(data.get("id", ""))] = true
	return CatalogEditor.unique_id(CatalogEditor.id_from(reason, "modifikator"), taken)


func _open_schedule_dialog() -> void:
	if run == null:
		return
	var events := _events_where(func(event: TimelineEvent) -> bool:
		return event.kind != TimelineEvent.Kind.FIXED and event.kind != TimelineEvent.Kind.YEARLY)
	_dialog.open_schedule(events, _selected_event_id(), func(values: Dictionary) -> String:
		return _after_intervention(run.schedule_event(values["event_id"], values["day"],
			values["reason"])))


## Absagen und Verschieben gelten dem gewählten Termin. Ob es der Termin erlaubt, entscheidet der
## Lauf; lehnt er ab, nennt der Dialog den Grund, etwa bei einem fixen Termin (US6, Szenario 5).
func _open_cancel_dialog() -> void:
	var entry := _selected_run_entry()
	if entry == null:
		return
	var serial := entry.serial
	_dialog.open_cancel(entry, func(values: Dictionary) -> String:
		return _after_intervention(run.cancel_entry(serial, values["reason"])))


func _open_move_dialog() -> void:
	var entry := _selected_run_entry()
	if entry == null:
		return
	var serial := entry.serial
	_dialog.open_move(entry, func(values: Dictionary) -> String:
		return _after_intervention(run.move_entry(serial, values["new_day"], values["reason"])))


## Rechtsklick auf einen Termin des Laufs: Er ist schon gewählt (allow_rmb_select), das Menü
## öffnet sich an der Maus. Weggefallene Termine gehören nicht zum Lauf; für sie gibt es keins.
func _on_plan_mouse_selected(at: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_RIGHT or _selected_run_entry() == null:
		return
	# Das Menü ist ein eigenes Fenster; get_screen_transform() rechnet die Stelle samt
	# Bildschirmfaktor in die Lage auf dem Bildschirm um, wie im Zeitstrahl.
	_plan_menu.reset_size()
	_plan_menu.position = Vector2i(_plan_table.get_screen_transform() * at)
	_plan_menu.popup()


func _on_plan_menu(item: int) -> void:
	match item:
		MenuItem.CANCEL:
			_open_cancel_dialog()
		MenuItem.MOVE:
			_open_move_dialog()


func _remove_selected_modifier() -> void:
	var item := _modifier_list.get_selected()
	if run == null or item == null or _is_start_modifier_row(item):
		return
	var id: String = item.get_metadata(ModifierColumn.EVENT)
	_show_intervention_problem(_after_intervention(run.remove_modifier(id)))


func _show_intervention_problem(problem: String) -> void:
	_intervention_hint.text = problem
	_intervention_hint.visible = not problem.is_empty()


## Die Modifikatoren des Laufs mit Ereignis, Wert, Zeitraum und Grund (FR-025); darunter je
## Ereignis die Chance in der nächsten Würfelrunde.
##
## Zuerst stehen die Start-Modifikatoren des Grads, mit dem Grad vor dem Grund, etwa „Schwer:
## Anspruchsvolle Kunden“ (FR-010). Eine eigene Farbe bekommen sie nicht: Gedämpfter Text hielte auf
## Zebra und Auswahl den Kontrast nicht (Analyse, U10). Ihre Zeilen tragen in der Spalte „Wert“ die
## Metadaten true; daran erkennt _is_start_modifier_row() sie.
func _fill_modifiers() -> void:
	_modifier_zebra.forget()
	_modifier_list.clear()
	var root := _modifier_list.create_item()
	if run != null:
		var level := Difficulty.label(run.difficulty)
		for modifier in run.start_modifiers:
			var item := _add_modifier_row(root, modifier, "%s: %s" % [level, modifier.reason])
			item.set_metadata(ModifierColumn.VALUE, true)
			for column in ModifierColumn.size():
				item.set_tooltip_text(column, "Start-Modifikator von %s: %s · Kennung %s" % [level,
					modifier.reason, modifier.id])
		for modifier in run.modifiers:
			var item := _add_modifier_row(root, modifier, modifier.reason)
			for column in ModifierColumn.size():
				item.set_tooltip_text(column, "%s · Kennung %s" % [modifier.reason, modifier.id])
	_modifier_zebra.paint_all()
	_chance_label.text = _chance_text()
	_update_controls()


## Eine Zeile der Liste der Modifikatoren; die Metadaten der ersten Spalte sind die Kennung.
func _add_modifier_row(root: TreeItem, modifier: ChanceModifier, reason: String) -> TreeItem:
	var item := _modifier_list.create_item(root)
	item.set_text(ModifierColumn.EVENT, _event_title(modifier.event_id))
	item.set_text(ModifierColumn.VALUE, _points(modifier.value))
	item.set_text(ModifierColumn.FROM, EventForm.format_date(modifier.from_day))
	item.set_text(ModifierColumn.TO, EventForm.format_date(modifier.to_day))
	item.set_text(ModifierColumn.REASON, reason)
	item.set_metadata(ModifierColumn.EVENT, modifier.id)
	return item


## Ob [param item] in der Liste der Modifikatoren ein Start-Modifikator ist.
static func _is_start_modifier_row(item: TreeItem) -> bool:
	return item.get_metadata(ModifierColumn.VALUE) == true


## Je Ereignis mit Modifikatoren eine Zeile mit Grundchance, Summe und wirksamer Chance in der
## nächsten Würfelrunde, etwa „Reklamationswelle: Grundchance 3 %, Summe −3 % → 0 % (begrenzt)“
## (US6, Szenario 3; FR-025: Chancen in Prozent, begrenzt auf 0 bis 100 %).
##
## Die Ereignisse kommen aus beiden Listen, erst die der Start-Modifikatoren. Gelten am Tag
## Start-Modifikatoren, nennt die Zeile den Anteil des Grads als Summe ihrer Werte, etwa
## „Reklamationswelle: Grundchance 3 %, Schwer +5, Summe 8 % → 8 %“ (Feature 003). Mit Mittel
## bleibt alles wie bisher.
func _chance_text() -> String:
	if run == null or (run.modifiers.is_empty() and run.start_modifiers.is_empty()):
		return ""
	var day := _first_of_next_month(run.today)
	var heading := "Nächste Würfelrunde am %s:" % EventForm.format_date(day)
	if day > TimelineRun.LAST_DAY:
		day = TimelineRun.LAST_DAY
		heading = "Keine Würfelrunde mehr; am %s:" % EventForm.format_date(day)
	var lines := PackedStringArray([heading])
	var seen := {}
	var all: Array[ChanceModifier] = []
	all.append_array(run.start_modifiers)
	all.append_array(run.modifiers)
	for modifier in all:
		if seen.has(modifier.event_id):
			continue
		seen[modifier.event_id] = true
		var info := run.chance_info(modifier.event_id, day)
		var share := ""
		var from_profile: Array[ChanceModifier] = info["start_modifiers"]
		if not from_profile.is_empty():
			var points := 0.0
			for start in from_profile:
				points += start.value
			share = " %s %s," % [Difficulty.label(run.difficulty), _points(points)]
		var line := "%s: Grundchance %s,%s Summe %s → %s" % [_event_title(modifier.event_id),
			_percent(info["base"]), share, _percent(info["sum"]), _percent(info["effective"])]
		if not is_equal_approx(info["sum"], info["effective"]):
			line += " (begrenzt)"
		lines.append(line)
	return "\n".join(lines)


## Die Ereignisse des Laufs, für die [param test] wahr ist, nach Titel.
func _events_where(test: Callable) -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	for event in run.catalog.events:
		if test.call(event):
			events.append(event)
	events.sort_custom(func(a: TimelineEvent, b: TimelineEvent) -> bool:
		return a.title.naturalnocasecmp_to(b.title) < 0)
	return events


## Das Ereignis des gewählten Termins, damit der Dialog es vorwählt; leer ohne Wahl.
func _selected_event_id() -> String:
	var entry := _selected_any_entry()
	return entry.event.id if entry != null else ""


func _selected_run_entry() -> ScheduleEntry:
	if run == null or _selected_serial < 1:
		return null
	return run.get_entry(_selected_serial)


## Der gewählte Termin, auch ein weggefallener.
func _selected_any_entry() -> ScheduleEntry:
	var entry := _selected_run_entry()
	return entry if entry != null else _selected_removed


# --- Unterschiede -----------------------------------------------------------------------------

## Rechnet den Vergleichslauf mit und vergleicht ihn mit dem Lauf (FR-043, R24; Feature 003,
## FR-018): derselbe Seed ohne Eingriffe bis zum selben Tag, mit dem Grad aus _comparison_level().
## Er entsteht einmal aus dem Katalog des Laufs, samt dessen Profilen, und spielt bei jedem Schritt
## mit; ein anderer Vergleichsgrad legt ihn neu an.
##
## Gerechnet wird er nur, wenn er sich vom Lauf unterscheiden kann: Der Lauf hat Eingriffe, oder
## das Häkchen vergleicht einen anderen Grad als Mittel mit Mittel. Sonst gibt es keinen, wie in
## Feature 002 bei einem Lauf ohne Eingriffe; bei Mittel ändert das Häkchen deshalb nichts.
func _update_diff() -> void:
	var needed := run != null and (not run.interventions.is_empty() or _compares_with_mittel())
	if not needed:
		_baseline = null
		_diff = null
		return
	var level := _comparison_level()
	if _baseline == null or _baseline.difficulty != level:
		_baseline = TimelineRun.new(run.catalog, run.seed, level)
	_baseline.advance_to(run.today)
	_diff = ScheduleDiff.compare(_baseline, run)


## Der Grad des Vergleichslaufs: Mittel mit Häkchen, sonst der des Laufs.
func _comparison_level() -> Difficulty.Level:
	return Difficulty.Level.MITTEL if compare_with_mittel else run.difficulty


## Ob gerade mit Mittel statt mit demselben Grad verglichen wird; dann gilt die zweite Reihe von
## Texten. Bei Mittel mit Häkchen ist es derselbe Grad, und es gelten die Texte von Feature 002
## (Analyse, A3).
func _compares_with_mittel() -> bool:
	return compare_with_mittel and run != null and run.difficulty != Difficulty.Level.MITTEL


## Die Texte der Markierungen zum gerade gültigen Vergleich.
func _diff_tips() -> Dictionary:
	return DIFF_TIPS_MITTEL if _compares_with_mittel() else DIFF_TIPS


## Das Häkchen hat gewechselt: Vergleich, Fahrplan und Begründung zeigen den neuen Stand. Der Lauf
## selbst bleibt, wie er ist.
func _on_comparison_changed() -> void:
	_update_diff()
	# Ohne Unterschiede gibt es keinen gewählten weggefallenen Termin mehr.
	if _diff == null or not _diff.removed.has(_selected_removed):
		_selected_removed = null
	_fill_plan()
	_show_detail()
	_update_controls()


## Der Text an %CompareLabel: wogegen der Fahrplan gerade vergleicht (FR-018), etwa „Vergleich:
## Schwer ohne Eingriffe“; ohne Vergleichslauf „Kein Vergleich: Der Lauf hat keine Eingriffe.“
## Ohne Lauf ist er leer.
func _comparison_text() -> String:
	if run == null:
		return ""
	if _diff == null:
		return NO_COMPARISON
	return "Vergleich: %s ohne Eingriffe" % Difficulty.label(_baseline.difficulty)


## Die Markierung eines Termins; REMOVED für einen weggefallenen.
func _mark_of(entry: ScheduleEntry, removed: bool) -> ScheduleDiff.Mark:
	if removed:
		return ScheduleDiff.Mark.REMOVED
	return _diff.marks.get(entry.serial, ScheduleDiff.Mark.NONE)


## Streicht die weggefallenen Termine durch: je Spalte eine Linie von 1 Pixel durch die Mitte des
## Texts. Gezeichnet wird auf der Ebene über dem Fahrplan, in den Koordinaten des Tree, die
## get_item_area_rect() samt Rollen liefert. Zeilen unter den Spaltenköpfen bleiben frei.
func _draw_struck_rows() -> void:
	if _struck_items.is_empty():
		return
	var first := _plan_table.get_root().get_first_child()
	# Die Unterkante der Spaltenköpfe ist da, wo die erste Zeile ohne Rollen begänne.
	var top := _plan_table.get_item_area_rect(first).position.y + _plan_table.get_scroll().y
	var font := _plan_table.get_theme_font(&"font")
	var font_size := _plan_table.get_theme_font_size(&"font_size")
	# So weit rückt der Tree den Text in seiner Zelle ein.
	var inset := float(_plan_table.get_theme_constant(&"h_separation")
		+ _plan_table.get_theme_constant(&"inner_item_margin_left"))
	for item in _struck_items:
		var color := UiPalette.PAPIER if item.is_selected(0) else UiPalette.TUSCHE
		for column in STRUCK_COLUMNS:
			var area := _plan_table.get_item_area_rect(item, column)
			var y := roundf(area.get_center().y)
			if y < top or y > _plan_table.size.y:
				continue
			var width := minf(font.get_string_size(item.get_text(column),
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, area.size.x - 2.0 * inset)
			if width > 0.0:
				_strike_overlay.draw_rect(Rect2(area.position.x + inset, y, width, 1.0), color)


# --- Fahrplan ---------------------------------------------------------------------------------

## Baut die Tabelle neu: je Termin eine Zeile, nach den Filtern für Zustand und Unterschiede.
## Läuft der Lauf mit Eingriffen, stehen die weggefallenen Termine an ihrem Tag dabei, und eine
## Spalte nennt die Unterschiede. Der gewählte Termin bleibt gewählt und zu sehen; ohne Auswahl
## rollt die Tabelle zum ersten Termin nach dem Stand des Laufs, am Spielende ans Ende.
func _fill_plan() -> void:
	_syncing = true
	_plan_zebra.forget()
	_plan_table.clear()
	_struck_items.clear()
	var columns := PLAN_TITLES.size() if _diff != null else PlanColumn.DIFF
	if _plan_table.columns != columns:
		_set_up_columns(_plan_table, PLAN_TITLES.slice(0, columns),
			PLAN_WIDTHS_WITH_DIFF if _diff != null else PLAN_WIDTHS)
	var root := _plan_table.create_item()
	var wanted := _state_filter.selected - 1
	var only_differences := _diff != null and _diff_filter.button_pressed
	var shown := 0
	var selected: TreeItem = null
	var upcoming: TreeItem = null
	var last: TreeItem = null
	for row in _plan_rows():
		var entry: ScheduleEntry = row["entry"]
		var removed: int = row["removed"]
		if wanted >= 0 and entry.state != wanted:
			continue
		if only_differences and _mark_of(entry, removed >= 0) == ScheduleDiff.Mark.NONE:
			continue
		last = _add_plan_row(root, entry, removed)
		if removed < 0:
			shown += 1
		if (removed < 0 and entry.serial == _selected_serial) \
				or (removed >= 0 and entry == _selected_removed):
			last.select(PlanColumn.DATE)
			selected = last
		if upcoming == null and entry.day > run.today:
			upcoming = last
	_plan_zebra.paint_all()
	_syncing = false
	_plan_count.text = _plan_count_text(shown)
	if selected != null:
		_plan_table.scroll_to_item(selected)
	elif upcoming != null:
		_plan_table.scroll_to_item(upcoming, true)
	elif last != null:
		_plan_table.scroll_to_item(last)
	_strike_overlay.queue_redraw()


## Die Zeilen in ihrer Reihenfolge, je { "entry", "removed" }: die Termine des Laufs und, bei
## Unterschieden, die weggefallenen an ihrem Tag hinter denen des Laufs. "removed" ist die Stelle
## in ScheduleDiff.removed, bei Terminen des Laufs −1.
func _plan_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if run == null:
		return rows
	var removed: Array[ScheduleEntry] = []
	if _diff != null:
		removed = _diff.removed
	var next := 0
	for entry in run.entries:
		while next < removed.size() and removed[next].day < entry.day:
			rows.append({"entry": removed[next], "removed": next})
			next += 1
		rows.append({"entry": entry, "removed": -1})
	while next < removed.size():
		rows.append({"entry": removed[next], "removed": next})
		next += 1
	return rows


## Eine Zeile des Fahrplans. Die Metadaten der ersten Spalte sind die laufende Nummer, bei einem
## weggefallenen Termin −1 − seine Stelle in ScheduleDiff.removed.
func _add_plan_row(root: TreeItem, entry: ScheduleEntry, removed: int) -> TreeItem:
	var item := _plan_table.create_item(root)
	item.set_text(PlanColumn.DATE, EventForm.format_date(entry.day))
	item.set_text(PlanColumn.EVENT, _title_of(entry.event))
	item.set_text(PlanColumn.ORIGIN, entry.origin_label())
	item.set_text(PlanColumn.STATE, entry.state_label())
	item.set_metadata(PlanColumn.DATE, entry.serial if removed < 0 else -1 - removed)
	var tooltip := "%s\n%s · %s · %s" % [_title_of(entry.event), _period(entry),
		entry.origin_label(), entry.state_label()]
	if _diff != null:
		var mark := _mark_of(entry, removed >= 0)
		item.set_text(PlanColumn.DIFF, _diff_text(mark))
		if mark != ScheduleDiff.Mark.NONE:
			tooltip += "\n%s" % _diff_tip(mark, entry, _diff_tips())
	for column in _plan_table.columns:
		item.set_tooltip_text(column, tooltip)
	if removed >= 0:
		_struck_items.append(item)
	return item


static func _diff_text(mark: ScheduleDiff.Mark) -> String:
	return DIFF_TEXTS.get(mark, "")


## Der Text zur Markierung [param mark] aus [param tips], DIFF_TIPS oder DIFF_TIPS_MITTEL.
static func _diff_tip(mark: ScheduleDiff.Mark, entry: ScheduleEntry, tips: Dictionary) -> String:
	var tip: String = tips.get(mark, "")
	if mark == ScheduleDiff.Mark.MOVED:
		tip = tip % EventForm.format_date(entry.moved_from_day)
	return tip


## „152 Termine“, mit Filter „37 von 152 Terminen“; bei Unterschieden dahinter deren Zahl.
func _plan_count_text(shown: int) -> String:
	var text := _count_text(shown, run.entries.size() if run != null else 0)
	if _diff == null:
		return text
	var differences := _diff.removed.size()
	for serial: int in _diff.marks:
		if _diff.marks[serial] != ScheduleDiff.Mark.NONE:
			differences += 1
	return "%s · %s %s" % [text, _grouped(differences),
		"Unterschied" if differences == 1 else "Unterschiede"]


## „152 Termine“; mit Filter „37 von 152 Terminen“.
static func _count_text(shown: int, total: int) -> String:
	if shown == total:
		return "%s %s" % [_grouped(total), "Termin" if total == 1 else "Termine"]
	return "%s von %s %s" % [_grouped(shown), _grouped(total),
		"Termin" if total == 1 else "Terminen"]


func _on_plan_item_selected() -> void:
	if _syncing or run == null:
		return
	var item := _plan_table.get_selected()
	if item == null:
		return
	var key: int = item.get_metadata(PlanColumn.DATE)
	_selected_serial = key if key > 0 else -1
	_selected_removed = _diff.removed[-1 - key] if key < 0 and _diff != null else null
	_show_detail()
	_update_controls()
	var entry := _selected_any_entry()
	if entry != null:
		event_selected.emit(entry.event.id)


## Unter der Tabelle: warum der gewählte Termin dort steht (SC-007), und seine verzögerten
## Wirkungen (FR-013, FR-041); bei Unterschieden auch, was die Eingriffe geändert haben.
func _show_detail() -> void:
	var entry := _selected_any_entry()
	_detail_title.visible = entry != null
	_detail_text.theme_type_variation = &"" if entry != null else &"MutedLabel"
	if entry == null:
		_detail_text.text = "Wähle einen Termin; hier steht dann, warum er dort steht." \
			if run != null else "Erzeuge einen Fahrplan und wähle einen Termin."
		return
	_detail_title.text = "%s (%s)" % [_title_of(entry.event), entry.event.id]
	var text := _explanation(entry)
	if _diff != null:
		var mark := _mark_of(entry, entry == _selected_removed)
		if mark != ScheduleDiff.Mark.NONE:
			text = "Unterschied: %s\n%s" % [_diff_tip(mark, entry, _diff_tips()), text]
	_detail_text.text = text


## Zeitraum, Herkunft und Zustand, die Begründung aus explain() und die verzögerten Wirkungen mit
## ihrem Tag. Bei einem gewürfelten Termin nennt die Begründung Würfelwert, Grundchance,
## Modifikatoren und Schwelle (US5, Szenario 3).
static func _explanation(entry: ScheduleEntry) -> String:
	var when := _period(entry)
	if entry.end_day > entry.day and entry.end_day > TimelineRun.LAST_DAY:
		when += " (Ende nach Spielende)"
	var lines := PackedStringArray([
		"%s · %s · %s" % [when, entry.origin_label(), entry.state_label()],
		"Begründung: %s" % entry.explain(),
	])
	var due := entry.due_effects()
	if entry.state == ScheduleEntry.State.SKIPPED or entry.state == ScheduleEntry.State.CANCELLED:
		# Ein solcher Termin beginnt nie, due_effects() nennt dann nichts (T097). Hat das Ereignis
		# verzögerte Wirkungen, sagt die Zeile, dass sie mit dem Termin wegfallen.
		lines.append("Verzögerte Wirkungen: entfallen mit dem Termin"
			if _has_delayed_effects(entry.event) else "Verzögerte Wirkungen: keine")
	elif due.is_empty():
		lines.append("Verzögerte Wirkungen: keine")
	else:
		lines.append("Verzögerte Wirkungen:")
		for item in due:
			var effect: EventEffect = item["effect"]
			var day: int = item["day"]
			var line := "%s  %s" % [EventForm.format_date(day), effect.describe()]
			if day > TimelineRun.LAST_DAY:
				line += " (nach Spielende, wird nicht gemeldet)"
			lines.append(line)
	return "\n".join(lines)


## Ob [param event] Wirkungen mit Verzögerung hat, für die Begründung eines Termins, der nie
## beginnt.
static func _has_delayed_effects(event: TimelineEvent) -> bool:
	for effect in event.effects:
		if effect.delay_days > 0:
			return true
	return false


## „22.03.1993“, mit Dauer „01.11.1993 bis 31.12.1993“: Der letzte Tag ist der vor end_day, denn
## das Ende wird am Tag danach gemeldet.
static func _period(entry: ScheduleEntry) -> String:
	var start := EventForm.format_date(entry.day)
	if entry.end_day <= entry.day:
		return start
	return "%s bis %s" % [start, EventForm.format_date(entry.end_day - 1)]


# --- Protokoll --------------------------------------------------------------------------------

## Leert das Protokoll und zeigt alle Meldungen des Laufs; nach „Fahrplan erzeugen“, einem
## Neustart oder dem Laden einer Probe.
func _reset_protocol() -> void:
	_protocol_zebra.forget()
	_protocol.clear()
	_protocol.create_item()
	_protocol_count = 0
	_sync_protocol()


## Hängt an, was im Protokoll des Laufs neu ist, je eine Zeile mit TimelineMessage.to_line(), genau
## wie in der Textausgabe mit --protokoll, und rollt zur letzten. Neu sind die Meldungen eines
## Schritts und die eines Eingriffs; die kommen nicht aus advance_to(), stehen aber im Protokoll.
##
## Eine zu lange Zeile endet mit „…“; ganz steht sie im Hinweis. Umbrechen ginge auch
## (TreeItem.set_autowrap_mode()), aber dann kennt der Tree die Höhe einer Zeile erst, wenn er sie
## einmal gezeichnet hat, und scroll_to_item() landete mitten im Protokoll.
func _sync_protocol() -> void:
	var root := _protocol.get_root()
	var last: TreeItem = null
	while run != null and _protocol_count < run.protocol.size():
		var line := run.protocol[_protocol_count].to_line()
		last = _protocol.create_item(root)
		last.set_text(0, line)
		last.set_tooltip_text(0, line)
		_protocol_zebra.paint(last, _protocol_count)
		_protocol_count += 1
	if last != null:
		_protocol.scroll_to_item(last)


# --- Proben -----------------------------------------------------------------------------------

func _open_save_dialog() -> void:
	if run == null:
		return
	_probe_name_edit.text = probe.name
	_show_save_hint("")
	_save_dialog.popup_centered(Vector2i(420, 0))
	_probe_name_edit.grab_focus()
	_probe_name_edit.select_all()


## „Speichern“ im Dialog: Ohne Namen geht es nicht. Gibt es die Kennung schon, fragt erst ein
## zweiter Dialog „Überschreiben?“; zwei Namen können dieselbe Kennung ergeben.
func _on_save_confirmed() -> void:
	var probe_name := _probe_name_edit.text.strip_edges()
	if probe_name.is_empty():
		_show_save_hint("Gib einen Namen ein, etwa „Windiger Händler ab 1990“.")
		return
	var id := CatalogEditor.id_from(probe_name, "probe")
	var existing: WhatIfProbe = null
	for listed in WhatIfProbe.list_probes(probe_folder):
		if listed.id == id:
			existing = listed
	_save_dialog.hide()
	if existing != null:
		_pending_name = probe_name
		_overwrite_dialog.dialog_text = "Die Probe „%s“ gibt es schon (%s.json). Überschreiben?" \
			% [existing.name, id]
		_overwrite_dialog.popup_centered(Vector2i(440, 0))
		return
	_finish_save(probe_name)


func _finish_save(probe_name: String) -> void:
	var error := save_probe(probe_name)
	_show_intervention_problem("" if error == OK else "Die Probe ließ sich nicht speichern: %s."
		% error_string(error))


## Der Hinweis im Dialog „Probe speichern“ gilt dem Namen; solange er dasteht, hat das Feld die
## Kontur des Fehlers (Style-Guide, „Bedienelemente“, T093). Ein leerer Text nimmt beides weg.
func _show_save_hint(text: String) -> void:
	_save_hint.text = text
	_save_hint.visible = not text.is_empty()
	_probe_name_edit.theme_type_variation = &"" if text.is_empty() else &"ErrorLineEdit"
	if _save_dialog.visible:
		_save_dialog.reset_size()


## „Probe laden …“: alle Proben im Ordner nach Name, mit Seed, Grad, Stand und Zahl der Eingriffe.
func _open_load_dialog() -> void:
	_probe_zebra.forget()
	_probe_list.clear()
	var root := _probe_list.create_item()
	_listed = WhatIfProbe.list_probes(probe_folder)
	for i in _listed.size():
		var listed := _listed[i]
		var item := _probe_list.create_item(root)
		item.set_text(ProbeColumn.NAME, listed.name)
		item.set_text(ProbeColumn.SEED, str(listed.seed))
		item.set_text(ProbeColumn.DIFFICULTY, Difficulty.label(listed.difficulty))
		item.set_text(ProbeColumn.UNTIL, EventForm.format_date(listed.until_day)
			if listed.until_day >= TimelineRun.FIRST_DAY else "vor Spielbeginn")
		item.set_text(ProbeColumn.COUNT, _grouped(listed.interventions.size()))
		item.set_metadata(ProbeColumn.NAME, i)
		item.set_tooltip_text(ProbeColumn.NAME, "%s.json" % listed.id)
	_probe_zebra.paint_all()
	_load_hint.text = "In %s liegt noch keine Probe." % probe_folder
	_load_hint.visible = _listed.is_empty()
	_load_dialog.get_ok_button().disabled = true
	_load_dialog.popup_centered(Vector2i(640, 320))


func _on_load_confirmed() -> void:
	var item := _probe_list.get_selected()
	if item == null:
		return
	var index: int = item.get_metadata(ProbeColumn.NAME)
	_load_dialog.hide()
	load_probe(_listed[index])


func _open_delete_dialog() -> void:
	if probe.id.is_empty():
		return
	_delete_dialog.dialog_text = ("Die Probe „%s“ löschen? Die Datei %s verschwindet; die "
		+ "gesammelten Eingriffe bleiben im Simulator.") % [probe.name,
		probe_folder.path_join(probe.id + ".json")]
	_delete_dialog.popup_centered(Vector2i(440, 0))


func _on_delete_confirmed() -> void:
	var error := delete_probe()
	_show_intervention_problem("" if error == OK else "Die Probe ließ sich nicht löschen: %s."
		% error_string(error))


# --- Hilfen -----------------------------------------------------------------------------------

## Spalten mit Köpfen, eine Zeile je Eintrag ohne Klapp-Pfeil, Auswahl der ganzen Zeile; wie in
## der Prüfung (IssuesPanel).
static func _set_up_table(tree: Tree, titles: Array[String], widths: Array[int]) -> void:
	tree.column_titles_visible = true
	tree.hide_root = true
	tree.hide_folding = true
	tree.select_mode = Tree.SELECT_ROW
	_set_up_columns(tree, titles, widths)
	tree.create_item()


## Zahl, Titel und Breiten der Spalten; eine Breite 0 heißt: nimmt den Rest.
static func _set_up_columns(tree: Tree, titles: Array[String], widths: Array[int]) -> void:
	tree.columns = titles.size()
	for column in tree.columns:
		tree.set_column_title(column, titles[column])
		tree.set_column_title_alignment(column, HORIZONTAL_ALIGNMENT_LEFT)
		tree.set_column_clip_content(column, true)
		tree.set_column_expand(column, widths[column] == 0)
		if widths[column] > 0:
			tree.set_column_custom_minimum_width(column, widths[column])


static func _title_of(event: TimelineEvent) -> String:
	if not event.title.strip_edges().is_empty():
		return event.title
	return event.id if not event.id.is_empty() else "(ohne Titel)"


## Titel eines Ereignisses im Katalog des Laufs; die Kennung, wenn es dort fehlt.
func _event_title(event_id: String) -> String:
	var event := run.catalog.get_event(event_id) if run != null else null
	return _title_of(event) if event != null else event_id


## Eine Anzahl mit Tausenderpunkt wie im Spiel: 1234 als „1.234“.
static func _grouped(count: int) -> String:
	var digits := str(count)
	var groups := PackedStringArray()
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.insert(0, digits)
	return ".".join(groups)


## Ein Anteil als Prozent mit Komma und echtem Minuszeichen: −0,03 als „−3 %“.
static func _percent(share: float) -> String:
	return "%s %%" % EventForm.format_number(share * 100.0).replace("-", "−")


## Ein Modifikator in Prozentpunkten mit Vorzeichen (Style-Guide): +0,05 als „+5“, −0,06 als „−6“.
static func _points(share: float) -> String:
	var number := EventForm.format_number(absf(share) * 100.0)
	if number == "0":
		return "0"
	return ("+" if share > 0.0 else "−") + number
