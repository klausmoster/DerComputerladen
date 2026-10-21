class_name InterventionDialog
extends ConfirmationDialog

## Der Dialog für die Eingriffe im Simulator (FR-025 bis FR-027, FR-043; contracts/werkstatt.md):
## einen Modifikator setzen, einen Termin absagen oder verschieben, ein Ereignis einplanen. Je nach
## Art zeigt er die passenden Felder.
##
## Der Dialog fragt nur ab; den Eingriff macht der Lauf. Beim Öffnen bekommt er dafür ein Callable
## [code]apply[/code], das die Werte als Dictionary nimmt und zurückgibt, was nicht ging, etwa
## TimelineRun.last_refusal. Ein leerer Text heißt angenommen, dann schließt der Dialog. Sonst
## steht der Grund unter den Feldern, und der Dialog bleibt offen, damit Klaus korrigieren kann;
## dafür ist dialog_hide_on_ok aus.
##
## Die Werte je Art:
## - MODIFIER: event_id, value (Prozentpunkte als Anteil, +5 als 0.05), reason, from_day, to_day;
## - CANCEL: reason;
## - MOVE: new_day, reason;
## - SCHEDULE: event_id, day, reason.

enum Kind { MODIFIER, CANCEL, MOVE, SCHEDULE }

## Titel und Text des OK-Knopfs je Art.
const TITLES: Array[String] = [
	"Modifikator setzen", "Termin absagen", "Termin verschieben", "Ereignis einplanen",
]
const OK_TEXTS: Array[String] = ["Setzen", "Absagen", "Verschieben", "Einplanen"]

## Die Art, für die der Dialog gerade offen ist.
var kind := Kind.MODIFIER

var _apply := Callable()
## Kennungen der Ereignisse zur Wahl, an derselben Stelle wie in der Auswahl.
var _event_ids: Array[String] = []
## Der Termin beim Absagen und Verschieben; null bei den anderen Arten.
var _entry: ScheduleEntry

@onready var _entry_caption: Label = %EntryCaption
@onready var _entry_label: Label = %EntryLabel
@onready var _event_caption: Label = %EventCaption
@onready var _event_choice: OptionButton = %EventChoice
@onready var _value_caption: Label = %ValueCaption
@onready var _value_row: HBoxContainer = %ValueRow
@onready var _value_edit: LineEdit = %ValueEdit
@onready var _reason_edit: LineEdit = %ReasonEdit
@onready var _from_caption: Label = %FromCaption
@onready var _from_edit: LineEdit = %FromEdit
@onready var _to_caption: Label = %ToCaption
@onready var _to_edit: LineEdit = %ToEdit
@onready var _day_caption: Label = %DayCaption
@onready var _day_edit: LineEdit = %DayEdit
@onready var _hint: Label = %Hint


func _ready() -> void:
	confirmed.connect(_on_confirmed)
	# Enter in einem Feld wirkt wie der OK-Knopf.
	for edit: LineEdit in [_value_edit, _reason_edit, _from_edit, _to_edit, _day_edit]:
		register_text_enter(edit)


## Modifikator (FR-025): [param events] sind die Ereignisse über Wahrscheinlichkeit zur Wahl,
## [param event_id] ist vorgewählt, falls es dabei ist. Der Beginn ist [param start_day], der
## aktuelle Spieltag; das Ende ist Pflicht und bleibt leer, bis Klaus es einträgt.
func open_modifier(events: Array[TimelineEvent], event_id: String, start_day: int,
		apply: Callable) -> void:
	_open(Kind.MODIFIER, apply)
	_fill_events(events, event_id)
	_from_edit.text = EventForm.format_date(start_day)
	_focus_first()


## Absage (FR-026) des Termins [param entry]; gefragt wird nur nach dem Grund.
func open_cancel(entry: ScheduleEntry, apply: Callable) -> void:
	_open(Kind.CANCEL, apply)
	_entry = entry
	_entry_label.text = _entry_text(entry)
	_focus_first()


## Verschiebung (FR-026) des Termins [param entry] auf einen neuen Tag, mit Grund.
func open_move(entry: ScheduleEntry, apply: Callable) -> void:
	_open(Kind.MOVE, apply)
	_entry = entry
	_entry_label.text = _entry_text(entry)
	_focus_first()


## Einplanung (FR-026): [param events] sind die Ereignisse, die weder fix noch jährlich sind;
## [param event_id] ist vorgewählt, falls es dabei ist.
func open_schedule(events: Array[TimelineEvent], event_id: String, apply: Callable) -> void:
	_open(Kind.SCHEDULE, apply)
	_fill_events(events, event_id)
	_focus_first()


## Zeigt unter den Feldern, was nicht ging; leer nimmt den Hinweis weg. Solange er dasteht, haben
## die Felder in [param faulty] die Kontur des Fehlers, alle anderen ihren normalen Rahmen
## (Style-Guide, „Bedienelemente“, T093).
func show_problem(text: String, faulty: Array[Control] = []) -> void:
	_hint.text = text
	_hint.visible = not text.is_empty()
	for input: Control in [_event_choice, _value_edit, _reason_edit, _from_edit, _to_edit,
			_day_edit]:
		var error := &"ErrorOptionButton" if input is OptionButton else &"ErrorLineEdit"
		input.theme_type_variation = error if _hint.visible and faulty.has(input) else &""
	# Ein Fenster wächst mit seinem Inhalt, wird von selbst aber nicht wieder kleiner.
	if visible:
		reset_size()


# --- Aufbau -----------------------------------------------------------------------------------

func _open(p_kind: Kind, apply: Callable) -> void:
	kind = p_kind
	_apply = apply
	_entry = null
	title = TITLES[kind]
	ok_button_text = OK_TEXTS[kind]
	for edit: LineEdit in [_value_edit, _reason_edit, _from_edit, _to_edit, _day_edit]:
		edit.text = ""
	var with_entry := kind == Kind.CANCEL or kind == Kind.MOVE
	var with_event := kind == Kind.MODIFIER or kind == Kind.SCHEDULE
	var with_day := kind == Kind.MOVE or kind == Kind.SCHEDULE
	for control: Control in [_entry_caption, _entry_label]:
		control.visible = with_entry
	for control: Control in [_event_caption, _event_choice]:
		control.visible = with_event
	for control: Control in [_value_caption, _value_row, _from_caption, _from_edit, _to_caption,
			_to_edit]:
		control.visible = kind == Kind.MODIFIER
	for control: Control in [_day_caption, _day_edit]:
		control.visible = with_day
	_day_caption.text = "Neuer Tag" if kind == Kind.MOVE else "Tag"
	show_problem("")
	popup_centered()
	reset_size()


func _fill_events(events: Array[TimelineEvent], event_id: String) -> void:
	_event_choice.clear()
	_event_ids.clear()
	for event in events:
		_event_choice.add_item("%s (%s)" % [event.title, event.id])
		_event_ids.append(event.id)
	_event_choice.select(maxi(_event_ids.find(event_id), 0) if not _event_ids.is_empty() else -1)


## Der Fokus kommt ins erste Feld, in das Klaus tippen muss.
func _focus_first() -> void:
	match kind:
		Kind.MODIFIER:
			_value_edit.grab_focus()
		Kind.MOVE:
			_day_edit.grab_focus()
		_:
			_reason_edit.grab_focus()


static func _entry_text(entry: ScheduleEntry) -> String:
	# Nicht „title“: So heißt schon der Titel des Fensters, und -d warnte vor dem Überdecken.
	var shown := entry.event.title if not entry.event.title.is_empty() else entry.event.id
	return "%s am %s" % [shown, EventForm.format_date(entry.day)]


# --- Übernehmen -------------------------------------------------------------------------------

## OK oder Enter: Erst liest der Dialog die Felder; passt eins nicht, sagt der Hinweis warum, und
## das Feld bekommt die Kontur des Fehlers. Dann gibt er die Werte an apply; lehnt der Lauf ab,
## steht dessen Grund da, am Feld, um das es geht (_refused_fields()), sonst schließt er.
func _on_confirmed() -> void:
	var values := {}
	var faulty: Array[Control] = []
	var problem := _read(values, faulty)
	if problem.is_empty() and _apply.is_valid():
		problem = _apply.call(values)
		faulty = _refused_fields()
	show_problem(problem, faulty)
	if problem.is_empty():
		hide()


## Liest die Felder der Art nach [param values]; gibt zurück, was nicht passt, sonst leer. Das
## Feld, das nicht passt, kommt nach [param faulty].
func _read(values: Dictionary, faulty: Array[Control]) -> String:
	var reason := _reason_edit.text.strip_edges()
	if kind == Kind.MODIFIER or kind == Kind.SCHEDULE:
		if _event_choice.selected < 0:
			faulty.append(_event_choice)
			return "Wähle ein Ereignis."
		values["event_id"] = _event_ids[_event_choice.selected]
	if kind == Kind.MODIFIER:
		var points := _value_edit.text.strip_edges().replace("−", "-")
		if points.is_empty():
			faulty.append(_value_edit)
			return "Gib einen Wert in Prozentpunkten ein, etwa +5 oder -6."
		var parsed := EventForm.parse_percent(points)
		if not parsed[0]:
			faulty.append(_value_edit)
			return parsed[1]
		values["value"] = parsed[1]
		var from := _date(_from_edit.text, "Beginn")
		if not from[0]:
			faulty.append(_from_edit)
			return from[1]
		var to := _date(_to_edit.text, "Ende")
		if not to[0]:
			faulty.append(_to_edit)
			return to[1]
		values["from_day"] = from[1]
		values["to_day"] = to[1]
	if kind == Kind.MOVE:
		var day := _date(_day_edit.text, "neuer Tag")
		if not day[0]:
			faulty.append(_day_edit)
			return day[1]
		values["new_day"] = day[1]
	if kind == Kind.SCHEDULE:
		var day := _date(_day_edit.text, "Tag")
		if not day[0]:
			faulty.append(_day_edit)
			return day[1]
		values["day"] = day[1]
	if reason.is_empty():
		faulty.append(_reason_edit)
		return "Gib einen Grund ein; jeder Eingriff steht mit Grund im Protokoll."
	values["reason"] = reason
	return ""


## Die Felder, um die es geht, wenn der Lauf einen Eingriff ablehnt. Den Grund nennt der Lauf
## (TimelineRun.last_refusal), das Feld nicht; es folgt daraus, was der Dialog vorher selbst geprüft
## hat: Ereignis, Wert, Tage und Grund sind lesbar.
## - Modifikator: Abgelehnt wird dann nur ein Ende vor dem Beginn; es gelten beide Tage.
## - Einplanen: Der Tag liegt nicht nach dem Stand des Laufs oder nach dem 31.12.1999.
## - Verschieben: ebenso der neue Tag, oder er ist der alte; außer der Termin selbst lässt sich
##   gar nicht verschieben (_entry_unchangeable()), dann gilt der Grund keinem Feld.
## - Absagen: Es geht immer um den Termin, und für ihn gibt es kein Feld.
func _refused_fields() -> Array[Control]:
	var fields: Array[Control] = []
	match kind:
		Kind.MODIFIER:
			fields.assign([_from_edit, _to_edit])
		Kind.SCHEDULE:
			fields.append(_day_edit)
		Kind.MOVE:
			if not _entry_unchangeable(_entry):
				fields.append(_day_edit)
	return fields


## Ob sich [param entry] auf keinen Tag verschieben und nicht absagen lässt (FR-026): fix oder
## jährlich, nicht mehr geplant oder nach dem 31.12.1999. Nur für die Kontur; ob ein Eingriff
## geht, entscheidet allein der Lauf.
static func _entry_unchangeable(entry: ScheduleEntry) -> bool:
	return entry == null or entry.origin == ScheduleEntry.Origin.FIXED \
		or entry.origin == ScheduleEntry.Origin.YEARLY \
		or entry.state != ScheduleEntry.State.PLANNED or entry.day > TimelineRun.LAST_DAY


## Ein Datum wie im Formular, auch ohne führende Nullen: [true, Tagesindex] oder [false, Grund].
static func _date(text: String, caption: String) -> Array:
	if text.strip_edges().is_empty():
		return [false, "Gib ein Datum bei „%s“ ein, etwa 31.12.1993." % caption]
	return EventForm.parse_date(text)
