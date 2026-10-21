class_name EventForm
extends VBoxContainer

## Das Formular rechts in der Werkstatt (FR-031; contracts/werkstatt.md, „EventForm“): die Felder
## des gewählten Ereignisses, je nach Art andere, dazu die Listen für Wirkungen, Folgeereignisse
## und Bedingungen. Darunter verwaltet ein Bereich die Kategorien.
##
## Was Klaus eingibt, geht über den CatalogEditor an den Katalog, sobald er das Feld verlässt oder
## Enter drückt. Enter gibt dabei den Fokus ab, damit das nächste Cmd+Z den Katalog erreicht statt
## das Textfeld (R15). Eine ungültige Eingabe übernimmt das Formular nicht: Der alte Wert bleibt,
## und ein Hinweis unter dem Feld sagt, warum. Darunter stehen auch die Meldungen der Prüfung zu
## diesem Feld.
##
## Welche Eingaben es gibt, hängt an der Art und an der Länge der Listen. Das Formular baut sie
## deshalb im Code und nach jeder Änderung am Katalog neu, am Ende des Bilds: So lebt das Feld noch,
## in das der Fokus gerade wandert, und bekommt ihn nach dem Neubau zurück. Jede Eingabe steht unter
## der Stelle, die Prüfmeldungen nennen, etwa "date", "window.from" oder "effects[1].delay_days";
## darüber findet focus_field() sie.

## Die Kennung des gezeigten Ereignisses hat sich geändert; die Werkstatt wählt es unter der neuen.
signal event_renamed(old_id: String, new_id: String)

## Breite der Beschriftungen links.
const LABEL_WIDTH := 120
## Breiten der Eingaben für Daten und kurze Zahlen.
const DATE_WIDTH := 100
const NUMBER_WIDTH := 64
## Mehr Anzahlen nimmt „Anzahl von–bis“ nicht an; ein Tippfehler wie 100 legte sonst 101 Felder an.
const MAX_COUNTS := 20
const SCOPE_LABELS: Array[String] = ["einmaliger Anstoß", "gilt nur während"]
const OCCURRED_LABELS: Array[String] = ["schon eingetreten", "noch nicht eingetreten"]
## Wie ein jährliches Ereignis endet: an einem Tag, am Ende eines Monats oder gar nicht.
const END_MODES: Array[String] = ["an einem Tag", "am Monatsende", "ohne Dauer"]
## Jahr ohne 29. Februar, in dem „an einem Tag“ den letzten Tag eines Monats sucht.
const REFERENCE_YEAR := 1985

static var _whole_pattern := RegEx.create_from_string("^[+-]?\\d{1,9}$")
static var _number_pattern := RegEx.create_from_string("^[+-]?(\\d{1,9}([.]\\d*)?|[.]\\d+)$")
static var _date_pattern := RegEx.create_from_string("^(\\d{1,2})\\.(\\d{1,2})\\.(\\d{4})$")
static var _day_pattern := RegEx.create_from_string("^(\\d{1,2})\\.(\\d{1,2})\\.?$")
## Farbfelder für die Wahl der Kategorienfarbe, je Token einmal gebaut.
static var _swatches := {}

var editor: CatalogEditor

## Das gezeigte Ereignis; leer heißt keins.
var _event_id := ""
## Ob das Formular gerade baut; Signale der alten Eingaben zählen dann nicht.
var _building := false
var _refresh_queued := false
## Stelle → Eingabe, etwa "date" → LineEdit.
var _inputs := {}
## Stelle → Hinweis unter der Zeile.
var _hints := {}
## Stelle → { "parse", "format", "apply" } für LineEdits.
var _specs := {}
## Stelle → Text, den das Feld zuletzt zeigte; eine ungültige Eingabe stellt ihn wieder her.
var _shown := {}

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _general_hint: Label = %GeneralHint
@onready var _event_box: VBoxContainer = %EventBox
@onready var _fields: VBoxContainer = %Fields
@onready var _effects: VBoxContainer = %Effects
@onready var _follow_ups: VBoxContainer = %FollowUps
@onready var _conditions_box: VBoxContainer = %ConditionsBox
@onready var _conditions_hint: Label = %ConditionsHint
@onready var _conditions: VBoxContainer = %Conditions
@onready var _add_condition: Button = %AddCondition
@onready var _categories: VBoxContainer = %Categories
@onready var _new_category_name: LineEdit = %NewCategoryName
@onready var _new_category_button: Button = %NewCategoryButton


func _ready() -> void:
	%AddEffect.pressed.connect(func() -> void: editor.add_item(_event_id, &"effects"))
	%AddFollowUp.pressed.connect(func() -> void: editor.add_item(_event_id, &"follow_ups"))
	_add_condition.pressed.connect(func() -> void: editor.add_item(_event_id, &"conditions"))
	_new_category_name.text_changed.connect(func(text: String) -> void:
		_new_category_button.disabled = text.strip_edges().is_empty())
	_new_category_name.text_submitted.connect(func(_text: String) -> void: _add_category())
	_new_category_button.pressed.connect(_add_category)
	_new_category_button.disabled = true
	_build()


# --- Für die Werkstatt ------------------------------------------------------------------------

## Zeigt das Ereignis [param id] sofort; leer heißt keins. Ist es schon das gezeigte, baut das
## Formular erst am Ende des Bilds neu, wie nach jeder Änderung.
func show_event(id: String) -> void:
	if id == _event_id:
		refresh()
		return
	_event_id = id
	_build()


## Baut nach einer Änderung am Katalog neu, einmal am Ende des Bilds.
func refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_rebuild.call_deferred()


## Setzt den Fokus auf das Feld einer Prüfmeldung, auch in den Listen, etwa
## "effects[1].delay_days" (FR-033). Ein unbekanntes Feld lässt den Fokus, wo er ist.
func focus_field(field: String) -> void:
	var input := get_input(field)
	if input == null or not input.is_visible_in_tree():
		return
	input.grab_focus()
	if input is LineEdit:
		var edit: LineEdit = input
		edit.caret_column = edit.text.length()


## Fokus in den Titel, alles markiert: für ein Ereignis, das gerade neu entstanden ist.
func focus_title() -> void:
	focus_field("title")
	var edit := get_input("title") as LineEdit
	if edit != null:
		edit.select_all()


## Die Eingabe zur Stelle [param field] oder null; für focus_field() und die Tests.
func get_input(field: String) -> Control:
	return _inputs.get(field)


## Der Hinweis unter der Eingabe zur Stelle [param field] oder null.
func get_hint(field: String) -> Label:
	return _hints.get(field)


# --- Lesen und Zeigen -------------------------------------------------------------------------
#
# Jede Lesefunktion gibt [true, Wert] oder [false, Grund] zurück. Der Grund steht dann als
# Hinweis am Feld.

## Text, ohne Leerzeichen am Rand.
static func parse_text(text: String) -> Array:
	return [true, text.strip_edges()]


## Ganze Zahl, auch mit Vorzeichen: „14“, „-3“.
static func parse_whole(text: String) -> Array:
	var clean := text.strip_edges()
	if _whole_pattern.search(clean) == null:
		return [false, "„%s“ ist keine ganze Zahl." % clean]
	return [true, clean.to_int()]


## Zahl mit Komma oder Punkt, wahlweise mit „%“ dahinter: „3,5“, „3.5“, „-30 %“.
static func parse_number(text: String) -> Array:
	var clean := text.strip_edges().trim_suffix("%").strip_edges().replace(",", ".")
	if _number_pattern.search(clean) == null:
		return [false, "„%s“ ist keine Zahl; erlaubt sind etwa 3,5 und 3.5." % text.strip_edges()]
	return [true, clean.to_float()]


## Prozent wie bei parse_number(), als Anteil: „3,5“ ergibt 0,035. Gespeichert werden Anteile auf
## vier Nachkommastellen (Schreibregel 3), deshalb rundet die Eingabe schon hier, genau wie der
## Katalog beim Schreiben: So ist der Wert im Speicher derselbe wie später in der Datei.
static func parse_percent(text: String) -> Array:
	var parsed := parse_number(text)
	if not parsed[0]:
		return parsed
	var percent: float = parsed[1]
	return [true, roundf(percent / 100.0 * 10000.0) / 10000.0]


## Gewicht je Anzahl in Prozent, auf zwei Nachkommastellen wie in der Datei.
static func parse_weight(text: String) -> Array:
	var parsed := parse_number(text)
	if not parsed[0]:
		return parsed
	var weight: float = parsed[1]
	return [true, roundf(weight * 100.0) / 100.0]


## Datum als Tagesindex aus „TT.MM.JJJJ“, auch ohne führende Nullen: „1.3.1993“. Ob es im
## Spielzeitraum liegt, prüft danach die Prüfung (V06) und meldet es am Feld.
static func parse_date(text: String) -> Array:
	var clean := text.strip_edges()
	var found := _date_pattern.search(clean)
	if found != null:
		var day := found.get_string(1).to_int()
		var month := found.get_string(2).to_int()
		var year := found.get_string(3).to_int()
		if GameDate.is_valid(year, month, day):
			return [true, GameDate.new(year, month, day).to_day_index()]
	return [false, "„%s“ ist kein Datum. Erwartet wird TT.MM.JJJJ, etwa 1.3.1993." % clean]


## Tag im Jahr als (Monat, Tag) aus „TT.MM.“: „1.11.“. Ob es den Tag in jedem Jahr gibt, prüft die
## Prüfung (V09).
static func parse_day_of_year(text: String) -> Array:
	var clean := text.strip_edges()
	var found := _day_pattern.search(clean)
	if found != null:
		var day := found.get_string(1).to_int()
		var month := found.get_string(2).to_int()
		if day >= 1 and day <= 31 and month >= 1 and month <= 12:
			return [true, Vector2i(month, day)]
	return [false, "„%s“ ist kein Tag im Jahr. Erwartet wird TT.MM., etwa 1.11." % clean]


## Zahl mit Komma und höchstens [param decimals] Nachkommastellen, ohne Nullen am Ende: „3,5“,
## „-30“, „33,33“.
static func format_number(value: float, decimals: int = 2) -> String:
	var text := ("%." + str(decimals) + "f") % value
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	if text == "-0":
		text = "0"
	return text.replace(".", ",")


## Anteil als Prozentzahl: 0,035 ergibt „3,5“.
static func format_percent(share: float) -> String:
	return format_number(share * 100.0)


static func format_date(day: int) -> String:
	return str(GameDate.from_day_index(day))


## (Monat, Tag) als „TT.MM.“; (0, 0) als leerer Text.
static func format_day_of_year(value: Vector2i) -> String:
	if value == Vector2i.ZERO:
		return ""
	return "%02d.%02d." % [value.y, value.x]


static func format_whole(value: int) -> String:
	return str(value)


static func _same_text(value: Variant) -> String:
	return str(value)


## [param count] gleiche Gewichte auf zwei Nachkommastellen; den Rest bekommt das letzte, damit
## die Summe genau 100 ist (FR-004). Bei sechs Anzahlen fünfmal 16,67 und einmal 16,65. Gerechnet
## wird in Hundertsteln, damit keine Kommazahl die Summe verschiebt.
static func spread_weights(count: int) -> Array[float]:
	var weights: Array[float] = []
	if count < 1:
		return weights
	var share := roundi(10000.0 / count)
	for i in count - 1:
		weights.append(share / 100.0)
	weights.append((10000 - share * (count - 1)) / 100.0)
	return weights


# --- Aufbau -----------------------------------------------------------------------------------

## Der vorgemerkte Neubau. Hat das Formular inzwischen sofort neu gebaut, etwa für ein anderes
## Ereignis, ist er schon erledigt.
func _rebuild() -> void:
	if _refresh_queued:
		_build()


## Baut alle Eingaben neu. Wer gerade den Fokus hatte, bekommt ihn danach in der neuen Eingabe
## derselben Stelle zurück.
func _build() -> void:
	_refresh_queued = false
	var focused := _focused_key()
	_building = true
	_clear()
	var event := _event()
	_event_box.visible = event != null
	if event == null:
		_title.text = "Kein Ereignis gewählt"
		_subtitle.text = "Wähle links ein Ereignis oder lege mit „Neu …“ eins an."
	else:
		_title.text = event.title if not event.title.strip_edges().is_empty() else "(ohne Titel)"
		_subtitle.text = "%s · %s" % [event.kind_label(), event.id]
		_build_event(event)
	_build_categories()
	_show_issues()
	_building = false
	if not focused.is_empty():
		focus_field(focused)


## Nimmt alle gebauten Eingaben heraus und gibt sie sofort frei; mit queue_free() lägen alte und
## neue Zeilen ein Bild lang übereinander. Das geht, weil das Formular nie aus einem Signal seiner
## eigenen Eingaben heraus sofort neu baut, sondern dann am Ende des Bilds (refresh()).
func _clear() -> void:
	for box: Container in [_fields, _effects, _follow_ups, _conditions, _categories]:
		for child in box.get_children():
			box.remove_child(child)
			child.free()
	_inputs.clear()
	_hints.clear()
	_specs.clear()
	_shown.clear()
	_general_hint.visible = false
	_conditions_hint.visible = false


func _event() -> TimelineEvent:
	if editor == null or editor.catalog == null or _event_id.is_empty():
		return null
	return editor.catalog.get_event(_event_id)


func _build_event(event: TimelineEvent) -> void:
	_add_line_row(_fields, "Titel", "title", event.title, parse_text, _same_text,
		_set_field(&"title"))
	_add_line_row(_fields, "Kennung", "id", event.id, parse_text, _same_text, _rename)
	_add_description_row(event)
	_add_category_row(event)
	_row(_fields, "Art", [_choice("kind", TimelineEvent.KIND_LABELS, event.kind,
		func(index: int) -> void: editor.set_event_kind(_event_id, index as TimelineEvent.Kind))],
		["kind"])
	match event.kind:
		TimelineEvent.Kind.FIXED:
			_row(_fields, "Datum", [_date_input("date", event.date, &"date")], ["date"])
			_add_days_row("Dauer", "duration_days", event.duration_days, "Tage, 0 heißt Augenblick")
		TimelineEvent.Kind.YEARLY:
			_add_years_row(event)
			_row(_fields, "Beginn", [_line("yearly.start", format_day_of_year(event.yearly_start),
				parse_day_of_year, format_day_of_year, _set_field(&"yearly_start"), NUMBER_WIDTH),
				_muted("TT.MM.")], ["yearly.start"])
			_add_yearly_end_row(event)
		TimelineEvent.Kind.PRESET:
			_add_window_row(event)
			_add_count_rows(event)
			_add_days_row("Mindestabstand", "min_gap_days", event.min_gap_days, "Tage")
			_add_days_row("Dauer", "duration_days", event.duration_days, "Tage, 0 heißt Augenblick")
		TimelineEvent.Kind.CHANCE:
			_add_window_row(event)
			_row(_fields, "Chance", [_percent_input("monthly_chance", event.monthly_chance,
				_set_field(&"monthly_chance")), _muted("% pro Monat")], ["monthly_chance"])
			_row(_fields, "Höchstzahl", [_line("max_occurrences",
				format_whole(event.max_occurrences), parse_whole, format_whole,
				_set_field(&"max_occurrences"), NUMBER_WIDTH), _muted("0 heißt unbegrenzt")],
				["max_occurrences"])
			_add_days_row("Mindestabstand", "min_gap_days", event.min_gap_days, "Tage")
			_add_days_row("Dauer", "duration_days", event.duration_days, "Tage, 0 heißt Augenblick")
		TimelineEvent.Kind.FOLLOW_ONLY:
			_add_days_row("Dauer", "duration_days", event.duration_days, "Tage, 0 heißt Augenblick")
	_build_effects(event)
	_build_follow_ups(event)
	_build_conditions(event)


func _add_description_row(event: TimelineEvent) -> void:
	var text := TextEdit.new()
	text.text = event.description
	# Sonst nähme Cmd+Z im Feld auch das Setzen des Texts zurück, und das Feld wäre leer.
	text.clear_undo_history()
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text.custom_minimum_size.y = 72
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Im TextEdit macht Enter eine neue Zeile; übernommen wird beim Verlassen.
	text.focus_exited.connect(func() -> void:
		if _building or text.is_queued_for_deletion() or _inputs.get("description") != text:
			return
		var shown := _event()
		if shown != null and shown.description != text.text:
			editor.set_event_field(_event_id, &"description", text.text))
	_inputs["description"] = text
	_row(_fields, "Beschreibung", [text], ["description"])


## Die Kategorien zur Wahl. Gibt es die Kategorie des Ereignisses nicht (V05), steht sie als
## eigener Eintrag dabei, damit der Wert sichtbar bleibt.
func _add_category_row(event: TimelineEvent) -> void:
	var labels: Array[String] = []
	var ids: Array[String] = []
	for category in editor.catalog.categories:
		labels.append(EventList._category_label(category))
		ids.append(category.id)
	var selected := ids.find(event.category)
	if selected < 0:
		labels.append("%s (gibt es nicht)" % event.category if not event.category.is_empty()
			else "– keine –")
		ids.append(event.category)
		selected = ids.size() - 1
	_row(_fields, "Kategorie", [_choice("category", labels, selected, func(index: int) -> void:
		editor.set_event_field(_event_id, &"category", ids[index]))], ["category"])


func _add_years_row(event: TimelineEvent) -> void:
	_row(_fields, "Jahre", [
		_line("yearly.from", format_whole(event.yearly_from), parse_whole, format_whole,
			_set_field(&"yearly_from"), NUMBER_WIDTH),
		_muted("bis"),
		_line("yearly.to", format_whole(event.yearly_to), parse_whole, format_whole,
			_set_field(&"yearly_to"), NUMBER_WIDTH),
	], ["yearly.from", "yearly.to"])


## Ende eines jährlichen Ereignisses: an einem Tag („31.12.“), am Ende eines Monats (bei Februar
## richtig in Schaltjahren) oder ohne Dauer.
func _add_yearly_end_row(event: TimelineEvent) -> void:
	var end := event.yearly_end
	var mode := 0
	if end == Vector2i.ZERO:
		mode = 2
	elif end.y == 0:
		mode = 1
	var inputs: Array[Control] = [_choice("yearly.end", END_MODES, mode, _set_end_mode)]
	if mode == 0:
		inputs.append(_line("yearly.end.day", format_day_of_year(end), parse_day_of_year,
			format_day_of_year, _set_field(&"yearly_end"), NUMBER_WIDTH))
	elif mode == 1:
		var months: Array[String] = []
		for month in range(1, 13):
			months.append(GameDate.MONTH_NAMES_DE[month])
		inputs.append(_choice("yearly.end.month", months, clampi(end.x, 1, 12) - 1,
			func(index: int) -> void:
				editor.set_event_field(_event_id, &"yearly_end", Vector2i(index + 1, 0))))
	_row(_fields, "Ende", inputs, ["yearly.end", "yearly.end.day", "yearly.end.month"])


func _set_end_mode(mode: int) -> void:
	var event := _event()
	var end := event.yearly_end
	var month := clampi(end.x if end.x > 0 else event.yearly_start.x, 1, 12)
	var value := Vector2i.ZERO
	match mode:
		0:
			value = end if end.y > 0 else Vector2i(month,
				GameDate.days_in_month(REFERENCE_YEAR, month))
		1:
			value = Vector2i(month, 0)
	editor.set_event_field(_event_id, &"yearly_end", value)


func _add_window_row(event: TimelineEvent) -> void:
	_row(_fields, "Zeitfenster", [
		_date_input("window.from", event.window_from, &"window_from"),
		_muted("bis"),
		_date_input("window.to", event.window_to, &"window_to"),
	], ["window.from", "window.to"])


## „Anzahl von–bis“ und darunter das Gewicht je Anzahl in Prozent.
func _add_count_rows(event: TimelineEvent) -> void:
	var low := event.count_min
	var high := event.count_min + event.count_weights.size() - 1
	_row(_fields, "Anzahl", [
		_line("count_min", format_whole(low), parse_whole, format_whole,
			func(value: Variant) -> String: return _set_counts(value, _current_high()),
			NUMBER_WIDTH),
		_muted("bis"),
		_line("count_max", format_whole(high), parse_whole, format_whole,
			func(value: Variant) -> String: return _set_counts(_event().count_min, value),
			NUMBER_WIDTH),
	], ["count_min", "count_max"])
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var keys: Array[String] = ["count_weights"]
	var total := 0.0
	for i in event.count_weights.size():
		var key := "count_weights[%d]" % i
		var piece := HBoxContainer.new()
		piece.add_child(_muted("%d×" % (low + i)))
		var edit := _line(key, format_number(event.count_weights[i]), parse_weight, format_number,
			func(value: Variant) -> String: return _set_weight(i, value), NUMBER_WIDTH)
		piece.add_child(edit)
		piece.add_child(_muted("%"))
		flow.add_child(piece)
		keys.append(key)
		if i == 0:
			_inputs["count_weights"] = edit
		total += event.count_weights[i]
	flow.add_child(_muted("Summe %s %%" % format_number(total)))
	_row(_fields, "je Anzahl", [flow], keys)


func _current_high() -> int:
	var event := _event()
	return event.count_min + event.count_weights.size() - 1


## Ändert „Anzahl von–bis“ und verteilt die Gewichte neu, beides als eine Aktion (FR-004).
func _set_counts(low: int, high: int) -> String:
	if high < low:
		return "„bis“ muss mindestens so groß sein wie „von“."
	if high - low + 1 > MAX_COUNTS:
		return "Höchstens %d verschiedene Anzahlen." % MAX_COUNTS
	var event := _event()
	if low == event.count_min and high == _current_high():
		return ""
	editor.set_event_fields(_event_id,
		{&"count_min": low, &"count_weights": spread_weights(high - low + 1)})
	return ""


func _set_weight(index: int, value: float) -> String:
	var weights := _event().count_weights.duplicate()
	weights[index] = value
	editor.set_event_field(_event_id, &"count_weights", weights)
	return ""


func _add_days_row(caption: String, key: String, value: int, unit: String) -> void:
	_row(_fields, caption, [_line(key, format_whole(value), parse_whole, format_whole,
		_set_field(StringName(key)), NUMBER_WIDTH), _muted(unit)], [key])


# --- Listen -----------------------------------------------------------------------------------

func _build_effects(event: TimelineEvent) -> void:
	var targets := _used_targets()
	for i in event.effects.size():
		var effect := event.effects[i]
		var prefix := "effects[%d]." % i
		var block := _item_block(_effects, "Wirkung %d" % (i + 1), "Diese Wirkung entfernen",
			func() -> void: editor.remove_item(_event_id, &"effects", i))
		_row(block, "Art", [_choice(prefix + "kind", EventEffect.KIND_LABELS, effect.kind,
			_set_item(&"effects", i, &"kind"))], [prefix + "kind"])
		var target := _line(prefix + "target", effect.target, parse_text, _same_text,
			_apply_item(&"effects", i, &"target"))
		var menu := MenuButton.new()
		menu.text = "…"
		menu.tooltip_text = "Ein schon benutztes Ziel wählen"
		menu.flat = false
		for used in targets:
			menu.get_popup().add_item(used)
		menu.get_popup().index_pressed.connect(func(index: int) -> void:
			editor.set_item_field(_event_id, &"effects", i, &"target", targets[index]))
		_row(block, "Ziel", [target, menu], [prefix + "target"])
		_row(block, "Stärke", [_percent_input(prefix + "magnitude", effect.magnitude,
			_apply_item(&"effects", i, &"magnitude")), _muted("%")], [prefix + "magnitude"])
		_row(block, "Verzögerung", [_line(prefix + "delay_days", format_whole(effect.delay_days),
			parse_whole, format_whole, _apply_item(&"effects", i, &"delay_days"), NUMBER_WIDTH),
			_muted("Tage")], [prefix + "delay_days"])
		# Ohne Dauer wirkt „gilt nur während“ wie ein einmaliger Anstoß (FR-021); die Wahl gibt es
		# deshalb nur bei Ereignissen mit Dauer.
		if event.has_duration():
			_row(block, "Geltung", [_choice(prefix + "scope", SCOPE_LABELS, effect.scope,
				_set_item(&"effects", i, &"scope"))], [prefix + "scope"])
		_add_line_row(block, "Notiz", prefix + "note", effect.note, parse_text, _same_text,
			_apply_item(&"effects", i, &"note"))


func _build_follow_ups(event: TimelineEvent) -> void:
	for i in event.follow_ups.size():
		var follow_up := event.follow_ups[i]
		var prefix := "follow_ups[%d]." % i
		var block := _item_block(_follow_ups, "Folgeereignis %d" % (i + 1),
			"Dieses Folgeereignis entfernen",
			func() -> void: editor.remove_item(_event_id, &"follow_ups", i))
		_row(block, "Ziel", [_event_choice(prefix + "target", follow_up.target, true,
			func(id: String) -> void:
				editor.set_item_field(_event_id, &"follow_ups", i, &"target", id))],
			[prefix + "target"])
		_row(block, "Chance", [_percent_input(prefix + "chance", follow_up.chance,
			_apply_item(&"follow_ups", i, &"chance")), _muted("%")], [prefix + "chance"])
		_row(block, "Verzögerung", [
			_line(prefix + "delay_min", format_whole(follow_up.delay_min), parse_whole,
				format_whole, _apply_item(&"follow_ups", i, &"delay_min"), NUMBER_WIDTH),
			_muted("bis"),
			_line(prefix + "delay_max", format_whole(follow_up.delay_max), parse_whole,
				format_whole, _apply_item(&"follow_ups", i, &"delay_max"), NUMBER_WIDTH),
			_muted("Tage"),
		], [prefix + "delay_min", prefix + "delay_max"])


## Bedingungen gibt es bei gesetzten Ereignissen, solchen über Wahrscheinlichkeit und solchen nur
## als Folge (FR-006). Hat ein fixes oder jährliches Ereignis trotzdem welche (V17), zeigt das
## Formular sie, damit Klaus sie entfernen kann.
func _build_conditions(event: TimelineEvent) -> void:
	var takes := event.kind != TimelineEvent.Kind.FIXED and event.kind != TimelineEvent.Kind.YEARLY
	_conditions_box.visible = takes or not event.conditions.is_empty()
	_add_condition.visible = takes
	_inputs["conditions"] = _add_condition if takes else null
	_hints["conditions"] = _conditions_hint
	for i in event.conditions.size():
		var condition := event.conditions[i]
		var prefix := "conditions[%d]." % i
		var block := _item_block(_conditions, "Bedingung %d" % (i + 1),
			"Diese Bedingung entfernen",
			func() -> void: editor.remove_item(_event_id, &"conditions", i))
		var choice := _event_choice(prefix + "event", condition.event, false,
			func(id: String) -> void:
				editor.set_item_field(_event_id, &"conditions", i, &"event", id))
		_row(block, "Ereignis", [choice], [prefix + "event"])
		if i == 0 and not takes:
			_inputs["conditions"] = choice
		_row(block, "Zustand", [_choice(prefix + "occurred", OCCURRED_LABELS,
			0 if condition.occurred else 1, func(index: int) -> void:
				editor.set_item_field(_event_id, &"conditions", i, &"occurred", index == 0))],
			[prefix + "occurred"])


## Ein Block für einen Listeneintrag: Überschrift und „−“, darunter die Zeilen.
func _item_block(box: Container, caption: String, remove_tooltip: String,
		remove: Callable) -> VBoxContainer:
	var block := VBoxContainer.new()
	var head := HBoxContainer.new()
	var label := Label.new()
	label.theme_type_variation = &"SmallLabel"
	label.text = caption
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(label)
	var button := Button.new()
	button.text = "−"
	button.tooltip_text = remove_tooltip
	button.pressed.connect(remove)
	head.add_child(button)
	block.add_child(head)
	box.add_child(block)
	return block


## Ziele aller Wirkungen im Katalog, sortiert und jedes einmal; das Formular schlägt sie vor.
func _used_targets() -> Array[String]:
	var seen := {}
	for event in editor.catalog.events:
		for effect in event.effects:
			if not effect.target.is_empty():
				seen[effect.target] = true
	var targets: Array[String] = []
	targets.assign(seen.keys())
	targets.sort()
	return targets


## Wahl eines Ereignisses für Folgeereignisse und Bedingungen. Folgeereignisse dürfen nicht fix
## oder jährlich sein (V16); [param only_followable] lässt diese weg. Ein Ziel, das es nicht gibt
## oder das nicht passt, steht als eigener Eintrag dabei.
func _event_choice(key: String, current: String, only_followable: bool,
		pick: Callable) -> OptionButton:
	var labels: Array[String] = ["– kein Ereignis –"]
	var ids: Array[String] = [""]
	for event in editor.catalog.events:
		var fixed := event.kind == TimelineEvent.Kind.FIXED \
			or event.kind == TimelineEvent.Kind.YEARLY
		if only_followable and fixed:
			continue
		if not only_followable and event.id == _event_id:
			continue
		labels.append("%s (%s)" % [event.title, event.id])
		ids.append(event.id)
	var selected := ids.find(current)
	if selected < 0:
		labels.append("%s (passt nicht)" % current)
		ids.append(current)
		selected = ids.size() - 1
	return _choice(key, labels, selected, func(index: int) -> void: pick.call(ids[index]))


# --- Kategorien -------------------------------------------------------------------------------

## Anlegen, umbenennen, Farbe wählen, löschen (FR-031). Löschen ist gesperrt, solange Ereignisse
## dazugehören. Die Kennung entsteht beim Anlegen aus dem Namen und bleibt; sie steht im Tooltip.
func _build_categories() -> void:
	if editor == null or editor.catalog == null:
		return
	var uses := {}
	for event in editor.catalog.events:
		uses[event.category] = int(uses.get(event.category, 0)) + 1
	for i in editor.catalog.categories.size():
		var category := editor.catalog.categories[i]
		var prefix := "categories[%d]." % i
		var id := category.id
		var color := _color_choice(prefix + "color", category.color,
			func(token: StringName) -> void: editor.set_category_field(id, &"color", token))
		var name_edit := _line(prefix + "name", category.name, parse_text, _same_text,
			func(value: Variant) -> String:
				editor.set_category_field(id, &"name", value)
				return "")
		name_edit.tooltip_text = "Kennung: %s" % id
		_inputs[prefix + "id"] = name_edit
		var delete := Button.new()
		delete.text = "Löschen"
		var count: int = uses.get(id, 0)
		delete.disabled = count > 0
		delete.tooltip_text = "Diese Kategorie löschen"
		if count > 0:
			delete.tooltip_text = "Gehört noch zu %d %s." % [count,
				"Ereignis" if count == 1 else "Ereignissen"]
		delete.pressed.connect(func() -> void: editor.delete_category(id))
		_row(_categories, "", [color, name_edit, delete],
			[prefix + "color", prefix + "name", prefix + "id"])


func _add_category() -> void:
	var name_text := _new_category_name.text.strip_edges()
	if name_text.is_empty():
		return
	_new_category_name.text = ""
	_new_category_button.disabled = true
	editor.add_category(name_text)


## Wahl der Kategorienfarbe aus UiPalette.CATEGORY_TOKENS, je mit Farbfeld. Ist die Farbe keine
## Kategorienfarbe (V21), steht sie als eigener Eintrag dabei.
func _color_choice(key: String, current: StringName, pick: Callable) -> OptionButton:
	var tokens: Array[StringName] = UiPalette.CATEGORY_TOKENS.duplicate()
	if not tokens.has(current):
		tokens.append(current)
	var labels: Array[String] = []
	for token in tokens:
		labels.append(String(token) if UiPalette.CATEGORY_TOKENS.has(token)
			else "%s (keine Kategorienfarbe)" % token)
	var choice := _choice(key, labels, tokens.find(current),
		func(index: int) -> void: pick.call(tokens[index]))
	# Hier soll die Auswahl so breit sein wie die längste Farbe, damit die Zeilen der Kategorien
	# untereinander gleich breit stehen; bei sieben Einträgen kostet das nichts.
	choice.fit_to_longest_item = true
	choice.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	choice.custom_minimum_size.x = 136
	for i in tokens.size():
		choice.set_item_icon(i, _swatch(tokens[i]))
	return choice


## Ein Farbfeld von 12 × 12 Pixeln in der Farbe des Tokens, mit Kontur in tusche.
static func _swatch(token: StringName) -> Texture2D:
	if _swatches.has(token):
		return _swatches[token]
	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(UiPalette.TUSCHE)
	image.fill_rect(Rect2i(1, 1, 10, 10), UiPalette.by_token(token))
	var texture := ImageTexture.create_from_image(image)
	_swatches[token] = texture
	return texture


# --- Eingaben ---------------------------------------------------------------------------------

## Eine Zeile in [param box]: links die Beschriftung, rechts [param inputs], darunter der Hinweis
## für alle [param keys]. Ohne Beschriftung nimmt die Eingabe die ganze Breite.
func _row(box: Container, caption: String, inputs: Array[Control], keys: Array[String]) -> void:
	var row := VBoxContainer.new()
	var line := HBoxContainer.new()
	if not caption.is_empty():
		var label := Label.new()
		label.text = caption
		label.custom_minimum_size.x = LABEL_WIDTH
		line.add_child(label)
	for input in inputs:
		line.add_child(input)
	row.add_child(line)
	var hint := Label.new()
	hint.theme_type_variation = &"ErrorLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.visible = false
	row.add_child(hint)
	for key in keys:
		_hints[key] = hint
	box.add_child(row)


func _add_line_row(box: Container, caption: String, key: String, text: String, parse: Callable,
		format: Callable, apply: Callable) -> void:
	_row(box, caption, [_line(key, text, parse, format, apply)], [key])


## Ein Textfeld, das beim Verlassen oder mit Enter übernimmt: [param parse] liest den Text,
## [param format] zeigt den Wert, [param apply] gibt ihn an den Katalog und sagt, was nicht ging.
func _line(key: String, text: String, parse: Callable, format: Callable, apply: Callable,
		width: int = 0) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = text
	if width > 0:
		edit.custom_minimum_size.x = width
	else:
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.focus_exited.connect(_on_line_focus_exited.bind(key, edit))
	# Enter übernimmt und gibt den Fokus ab; das Übernehmen selbst geschieht in focus_exited.
	edit.text_submitted.connect(func(_submitted: String) -> void: edit.release_focus())
	# Ein LineEdit merkt sich auch das Setzen von text als Schritt in seinem Verlauf, und leeren
	# lässt sich der von außen nicht. Cmd+Z im Feld nähme sonst den Wert ganz weg. gui_input kommt
	# vor der eigenen Verarbeitung des Felds; zeigt es noch den übernommenen Wert, schluckt das
	# Formular das Cmd+Z. Mit dem Fokus im Feld gehört es trotzdem dem Feld, nicht dem Katalog.
	edit.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed(&"ui_undo") and edit.text == _shown.get(key):
			edit.accept_event())
	_inputs[key] = edit
	_specs[key] = {"parse": parse, "format": format, "apply": apply}
	_shown[key] = text
	return edit


func _date_input(key: String, day: int, field: StringName) -> LineEdit:
	var edit := _line(key, format_date(day), parse_date, format_date, _set_field(field), DATE_WIDTH)
	edit.placeholder_text = "TT.MM.JJJJ"
	return edit


func _percent_input(key: String, share: float, apply: Callable) -> LineEdit:
	return _line(key, format_percent(share), parse_percent, format_percent, apply, NUMBER_WIDTH)


## Auswahl aus [param labels]; [param pick] bekommt die Stelle der Wahl.
##
## fit_to_longest_item ist aus: Sonst misst der OptionButton beim Eintritt in den Baum jeden
## Eintrag aus, um so breit zu werden wie der längste. Bei der Wahl eines Folgeereignisses aus
## 500 Ereignissen kostete das gut 20 ms je Neubau des Formulars, und der längste Titel zog das
## ganze Formular breiter, obwohl der Text mit clip_text ohnehin abgeschnitten wird.
func _choice(key: String, labels: Array[String], selected: int, pick: Callable) -> OptionButton:
	var choice := OptionButton.new()
	choice.fit_to_longest_item = false
	for label in labels:
		choice.add_item(label)
	choice.select(selected)
	choice.clip_text = true
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.item_selected.connect(func(index: int) -> void:
		if not _building:
			pick.call(index))
	_inputs[key] = choice
	return choice


## Nebenangabe in gedämpfter Farbe, etwa „Tage“ oder „%“.
func _muted(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"MutedLabel"
	label.text = text
	return label


## Übernimmt ein Feld des Ereignisses.
func _set_field(field: StringName) -> Callable:
	return func(value: Variant) -> String:
		editor.set_event_field(_event_id, field, value)
		return ""


## Übernimmt ein Feld eines Listeneintrags; für Textfelder.
func _apply_item(list: StringName, index: int, field: StringName) -> Callable:
	return func(value: Variant) -> String:
		editor.set_item_field(_event_id, list, index, field, value)
		return ""


## Übernimmt ein Feld eines Listeneintrags; für Auswahlen, deren Stelle der Wert ist.
func _set_item(list: StringName, index: int, field: StringName) -> Callable:
	return func(choice: int) -> void:
		editor.set_item_field(_event_id, list, index, field, choice)


func _rename(value: Variant) -> String:
	var old := _event_id
	var new_id := String(value)
	match editor.rename_event(old, new_id):
		OK:
			if new_id != old:
				_event_id = new_id
				event_renamed.emit(old, new_id)
			return ""
		ERR_ALREADY_EXISTS:
			return "Die Kennung „%s“ gibt es schon." % new_id
		ERR_INVALID_PARAMETER:
			return "Die Kennung darf nicht leer sein."
	return "Die Kennung ließ sich nicht ändern."


func _on_line_focus_exited(key: String, edit: LineEdit) -> void:
	# Alte Eingaben, die der Neubau gerade herausnimmt, übernehmen nichts mehr.
	if _building or edit.is_queued_for_deletion() or _inputs.get(key) != edit:
		return
	var before: String = _shown[key]
	if edit.text == before:
		return
	var spec: Dictionary = _specs[key]
	var parsed: Array = spec["parse"].call(edit.text)
	if not parsed[0]:
		edit.text = before
		_set_hint(key, parsed[1])
		return
	var shown: String = spec["format"].call(parsed[1])
	edit.text = shown
	_shown[key] = shown
	var problem: String = spec["apply"].call(parsed[1])
	if not problem.is_empty():
		edit.text = before
		_shown[key] = before
		_set_hint(key, problem)


func _set_hint(key: String, text: String) -> void:
	var hint: Label = _hints.get(key)
	if hint == null:
		return
	hint.theme_type_variation = &"ErrorLabel"
	hint.text = text
	hint.visible = not text.is_empty()


## Die Stelle der Eingabe, die gerade den Fokus hat; leer, wenn es keine des Formulars ist.
func _focused_key() -> String:
	if not is_inside_tree():
		return ""
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null:
		return ""
	for key: String in _inputs:
		if _inputs[key] == focus:
			return key
	return ""


# --- Meldungen --------------------------------------------------------------------------------

## Schreibt die Meldungen der Prüfung unter ihre Felder. Ein Feld mit Fehler bekommt die rote
## Kontur (ErrorLineEdit). Meldungen ohne passendes Feld, etwa zu einem unbekannten Schlüssel,
## stehen oben unter dem Titel.
func _show_issues() -> void:
	if editor == null or editor.catalog == null:
		return
	var lines := {}
	var has_error := {}
	var general := PackedStringArray()
	for issue in editor.issues():
		var for_event := not _event_id.is_empty() and issue.event_id == _event_id \
			and _event() != null
		var for_category := issue.event_id.is_empty() and issue.field.begins_with("categories[")
		if not for_event and not for_category:
			continue
		var is_error := issue.severity == CatalogIssue.Severity.ERROR
		var text := _reason(issue) if is_error else "? " + _reason(issue)
		var hint: Label = _hints.get(issue.field)
		if hint == null:
			general.append(text)
			continue
		if not lines.has(hint):
			lines[hint] = PackedStringArray()
		lines[hint].append(text)
		has_error[hint] = has_error.get(hint, false) or is_error
		var input: Control = _inputs.get(issue.field)
		if input is LineEdit and is_error:
			input.theme_type_variation = &"ErrorLineEdit"
	for hint: Label in lines:
		hint.text = "\n".join(lines[hint])
		hint.theme_type_variation = &"ErrorLabel" if has_error[hint] else &"WarningLabel"
		hint.visible = true
	_general_hint.text = "\n".join(general)
	_general_hint.visible = not general.is_empty()


## Der Grund einer Meldung ohne den Ort davor: aus „Ereignis „x“, Feld „date“: Das Datum …“ wird
## „Das Datum …“, denn das Feld steht ja direkt darüber.
static func _reason(issue: CatalogIssue) -> String:
	var cut := issue.message.find("“: ")
	if cut < 0:
		return issue.message
	return issue.message.substr(cut + 3)
