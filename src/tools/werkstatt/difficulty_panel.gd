class_name DifficultyPanel
extends VBoxContainer

## Der Reiter „Schwierigkeitsgrade“ der Werkstatt (Feature 003, FR-015, FR-016; research.md, R11;
## contracts/werkstatt.md, „DifficultyPanel“): Hier pflegt Klaus die Profile von Leicht und Schwer.
## Oben wählt er den Grad, links stehen dessen Start-Modifikatoren als Tabelle, rechts die Felder
## des gewählten. Mittel hat kein Profil; dann steht statt Tabelle und Feldern nur eine Notiz.
##
## Wie Liste und Formular ändert das Panel den Katalog nur über den CatalogEditor. Ein
## Start-Modifikator-Objekt behält es dabei nie: Jede Änderung ersetzt das ganze Profil durch eine
## Kopie (R10), und ein gemerktes Objekt stünde danach nicht mehr im Katalog. Das Panel merkt sich
## deshalb nur Grad und Stelle und holt den Start-Modifikator jedes Mal neu (_modifier()).
##
## Die Felder entstehen einmal, in der Szene. Nach einer Änderung setzt refresh() nur ihre Werte
## neu, außer im Feld mit dem Fokus; dort tippt Klaus vielleicht gerade. Ein Feld übernimmt seinen
## Wert beim Verlassen oder mit Enter, wie im Formular (R15 von Feature 002). Die Zeilen der Tabelle
## baut das Panel dagegen erst am Ende des Bilds neu, wie die Liste der Ereignisse (T076): Ein
## Klick in die Tabelle nimmt einem Feld den Fokus, das Feld übernimmt, und bauten die Zeilen
## sofort neu, träfe der Klick eine neue Zeile statt der unter der Maus.

enum Column { MARK, EVENT, VALUE, FROM, TO, REASON, ID }

const TITLES: Array[String] = ["", "Ereignis", "Wert", "von", "bis", "Grund", "Kennung"]
## Breite der schmalen Spalten; Ereignis und Grund teilen sich den Rest.
const WIDTHS: Array[int] = [24, 0, 64, 96, 96, 0, 150]
## Die Felder eines Start-Modifikators, wie sie in Prüfmeldungen hinter der Stelle stehen, etwa
## „profiles.schwer[2].reason“, in der Reihenfolge der Felder im Reiter.
const FIELDS: Array[String] = ["event_id", "value", "from_day", "to_day", "reason", "id"]
## Die Textfelder unter diesen Feldern; „event_id“ ist eine Auswahl.
const EDIT_FIELDS: Array[String] = ["value", "from_day", "to_day", "reason", "id"]
const NEW_TIP := ("Einen Start-Modifikator für das ganze Spiel anlegen, auf das gewählte Ereignis, "
	+ "wenn es über Wahrscheinlichkeit kommt")
const NO_CHANCE_EVENT := "Der Katalog hat kein Ereignis über Wahrscheinlichkeit."

var editor: CatalogEditor
## Das gewählte Ereignis der Werkstatt; „Neu“ nimmt es, wenn es über Wahrscheinlichkeit kommt.
var selected_event_id: String = ""

## Die gewählte Stelle im gezeigten Profil, ab 0; −1 heißt keine. Gemerkt wird die Stelle, nie
## das Objekt (siehe oben).
var _index := -1
## Streifen, Auswahl und Überfahren der Tabelle.
var _zebra: Zebra
## Ob der Neubau der Zeilen für das Ende des Bilds vorgemerkt ist.
var _rows_queued := false
## Ob das Panel die Auswahl der Tabelle gerade selbst setzt; item_selected zählt dann nicht.
var _syncing := false
## Feld → Eingabe bzw. Hinweis darunter, etwa "value" → %ValueEdit.
var _inputs := {}
var _hints := {}
## Feld → Text, den das Textfeld zuletzt zeigte. Eine ungültige Eingabe stellt ihn wieder her, und
## Cmd+Z schluckt das Panel, solange das Feld genau ihn zeigt.
var _shown := {}
## Die Kennungen der Einträge in %EventOption, in ihrer Reihenfolge, und woraus sie gebaut sind.
var _event_ids: Array[String] = []
var _event_choice_key := ""

@onready var _difficulty_option: OptionButton = %DifficultyOption
@onready var _count_label: Label = %CountLabel
@onready var _mittel_note: Label = %MittelNote
@onready var _split: HSplitContainer = %Split
@onready var _table: Tree = %Table
@onready var _new_button: Button = %NewButton
@onready var _duplicate_button: Button = %DuplicateButton
@onready var _delete_button: Button = %DeleteButton
@onready var _event_option: OptionButton = %EventOption


func _ready() -> void:
	_set_up_table()
	_zebra = Zebra.new(_table)
	_inputs = {"event_id": _event_option, "value": %ValueEdit, "from_day": %FromEdit,
		"to_day": %ToEdit, "reason": %ReasonEdit, "id": %IdEdit}
	_hints = {"event_id": %EventHint, "value": %ValueHint, "from_day": %FromHint,
		"to_day": %ToHint, "reason": %ReasonHint, "id": %IdHint}
	for field in EDIT_FIELDS:
		_set_up_edit(field, _inputs[field])
	_align_captions()
	_difficulty_option.item_selected.connect(func(index: int) -> void:
		show_difficulty(index as Difficulty.Level))
	_table.item_selected.connect(_on_table_selected)
	_event_option.item_selected.connect(_on_event_picked)
	_new_button.pressed.connect(_on_new_pressed)
	_duplicate_button.pressed.connect(_on_duplicate_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)
	_update_view(true)


# --- Für die Werkstatt ------------------------------------------------------------------------

## Nach catalog_changed und issues_changed: Grad, Zahl, Knöpfe und Felder sofort, die Zeilen der
## Tabelle am Ende des Bilds (siehe oben). Solange editor fehlt, tut es nichts; die Werkstatt setzt
## ihn erst in ihrem _ready(), nach dem des Panels.
func refresh() -> void:
	if editor == null:
		return
	_update_view(false)
	_queue_rows()


## Zeigt den Grad [param level], ohne Aktion im Verlauf. Was im Feld mit dem Fokus getippt ist,
## gehört zum bisher gezeigten Start-Modifikator und wird vorher übernommen.
func show_difficulty(level: Difficulty.Level) -> void:
	if not Difficulty.is_valid(level):
		return
	_commit_focused()
	_difficulty_option.select(level)
	_index = -1
	_update_view(true)
	_fill_rows()


func shown_difficulty() -> Difficulty.Level:
	return _difficulty_option.selected as Difficulty.Level


## Wählt die Zeile [param index] und füllt die Felder; −1 oder eine Stelle, die es nicht gibt,
## wählt keine. Die offene Eingabe gilt vorher noch der bisher gezeigten Zeile.
func select_row(index: int) -> void:
	_commit_focused()
	_choose(index)
	_highlight()


## Fokus auf das Feld einer Prüfmeldung, etwa „profiles.schwer[2].reason“: Grad und Zeile wählen,
## dann das Feld. Ohne Stelle, etwa bei „profiles.mittel“, nur den Grad; bei „profiles“ allein und
## bei einem Grad, den es nicht gibt, nichts. Ein Feld, das es nicht gibt, lässt die Zeile gewählt.
func focus_field(field: String) -> void:
	var place := _place_of(field)
	var level: int = place["level"]
	if not Difficulty.is_valid(level):
		return
	show_difficulty(level as Difficulty.Level)
	if place["index"] < 0:
		return
	select_row(place["index"])
	var input: Control = _inputs.get(place["field"])
	if input == null or not input.is_visible_in_tree() or _modifier() == null:
		return
	input.grab_focus()
	if input is LineEdit:
		var edit: LineEdit = input
		edit.caret_column = edit.text.length()


## Zerlegt das Feld einer Prüfmeldung: „profiles.schwer[2].reason“ ergibt
## { "level": SCHWER, "index": 2, "field": "reason" }. Fehlt etwas, steht −1 bzw. "" darin; ein
## Feld außerhalb der Profile hat "level" −1. Verglichen wird nach ganzen Pfadteilen wie in
## DifficultyProfile.faulty_indices(): „profiles.schwerr“ ist kein Grad, „[02]“ keine Stelle.
static func _place_of(field: String) -> Dictionary:
	var place := {"level": -1, "index": -1, "field": ""}
	if not field.begins_with("profiles."):
		return place
	var rest := field.substr("profiles.".length())
	var bracket := rest.find("[")
	var key := rest if bracket < 0 else rest.left(bracket)
	place["level"] = Difficulty.from_key(key)
	if bracket < 0 or place["level"] < 0:
		return place
	rest = rest.substr(bracket + 1)
	var close := rest.find("]")
	if close < 0:
		return place
	var digits := rest.left(close)
	var after := rest.substr(close + 1)
	if digits.is_empty() or not digits.lstrip("0123456789").is_empty() \
			or str(digits.to_int()) != digits:
		return place
	if not after.is_empty() and not after.begins_with("."):
		return place
	place["index"] = digits.to_int()
	place["field"] = after.trim_prefix(".")
	return place


# --- Ansicht ----------------------------------------------------------------------------------

## Zeigt, was zum gewählten Grad gehört: bei Mittel die Notiz, sonst Tabelle, Knöpfe und Felder.
## [param force] setzt auch das Feld mit dem Fokus, etwa wenn eine andere Zeile gewählt ist.
func _update_view(force: bool) -> void:
	var profile := _profile()
	var is_mittel := shown_difficulty() == Difficulty.Level.MITTEL
	_mittel_note.visible = is_mittel
	_split.visible = not is_mittel
	_count_label.visible = not is_mittel
	if profile == null or _index >= profile.modifiers.size():
		_index = -1
	_count_label.text = _count_text(profile.modifiers.size() if profile != null else 0)
	_update_buttons()
	_fill_fields(force)


func _update_buttons() -> void:
	var has_chance := _has_chance_event()
	_new_button.disabled = _profile() == null or not has_chance
	_new_button.tooltip_text = NEW_TIP if has_chance else NO_CHANCE_EVENT
	_duplicate_button.disabled = _modifier() == null
	_delete_button.disabled = _modifier() == null


## Setzt die Werte der Felder aus dem gewählten Start-Modifikator, ohne gewählten leer und
## gesperrt. Das Feld mit dem Fokus bleibt ohne [param force], wie es ist. Danach stehen die
## Meldungen der Prüfung darunter.
func _fill_fields(force: bool) -> void:
	var modifier := _modifier()
	var focus := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	for field in EDIT_FIELDS:
		var edit: LineEdit = _inputs[field]
		edit.editable = modifier != null
		if edit == focus and modifier != null and not force:
			continue
		var text := _format(field, modifier.get(field)) if modifier != null else ""
		# Jedes Setzen von text landet im Verlauf des Felds; ein gleicher Text braucht keins.
		if edit.text != text:
			edit.text = text
		_shown[field] = text
	_fill_event_choice(modifier)
	_event_option.disabled = modifier == null
	_show_issues()


## Die Ereignisse über Wahrscheinlichkeit nach Titel. Zeigt der Start-Modifikator auf ein
## unbekanntes oder anderes Ereignis, steht es als eigener Eintrag oben, damit V25 bzw. V26 ein
## Feld haben. Neu gebaut wird nur, wenn sich die Einträge ändern: Mit 250 Ereignissen in
## catalog_500.json kostete jeder Neubau Zeit, und eine offene Liste bliebe so, wie sie ist.
func _fill_event_choice(modifier: ChanceModifier) -> void:
	var labels: Array[String] = []
	var ids: Array[String] = []
	var tips: Array[String] = []
	if modifier != null:
		var target := editor.catalog.get_event(modifier.event_id)
		if target == null or target.kind != TimelineEvent.Kind.CHANCE:
			labels.append(_target_label(modifier.event_id, target, true))
			ids.append(modifier.event_id)
			tips.append(modifier.event_id)
		for event in _chance_events():
			labels.append(_title_of(event))
			ids.append(event.id)
			tips.append(event.id)
	var key := "\n".join(labels) + "\u001f" + "\n".join(ids)
	if key != _event_choice_key and not _event_option.get_popup().visible:
		_event_choice_key = key
		_event_ids = ids
		_event_option.clear()
		for i in labels.size():
			_event_option.add_item(labels[i])
			_event_option.set_item_tooltip(i, tips[i])
	_event_option.select(_event_ids.find(modifier.event_id) if modifier != null else -1)


## Schreibt die Meldungen zum gewählten Start-Modifikator unter ihre Felder (FR-016): Ein Fehler
## gibt dem Feld die rote Kontur und steht in ErrorLabel, eine Warnung (V31) nur als Hinweis in der
## Warnfarbe, wie im Formular. Meldungen ohne Feld, etwa an „profiles.schwer[2]“, stehen nur in der
## Prüfung; die Zeile trägt trotzdem ihr Zeichen.
func _show_issues() -> void:
	for field in FIELDS:
		var hint: Label = _hints[field]
		hint.visible = false
		hint.text = ""
		(_inputs[field] as Control).theme_type_variation = &""
	if _modifier() == null:
		return
	var lines := {}
	var has_error := {}
	for issue in editor.issues():
		var place := _place_of(issue.field)
		if place["level"] != shown_difficulty() or place["index"] != _index \
				or not _hints.has(place["field"]):
			continue
		var field: String = place["field"]
		var is_error := issue.severity == CatalogIssue.Severity.ERROR
		if not lines.has(field):
			lines[field] = PackedStringArray()
		var text := FieldHelpers.reason(issue)
		lines[field].append(text if is_error else "? " + text)
		has_error[field] = has_error.get(field, false) or is_error
	for field: String in lines:
		var hint: Label = _hints[field]
		hint.text = "\n".join(lines[field])
		hint.theme_type_variation = &"ErrorLabel" if has_error[field] else &"WarningLabel"
		hint.visible = true
		if has_error[field]:
			FieldHelpers.mark_error(_inputs[field])


## Zeigt unter [param field], warum die Eingabe nicht ging, mit der Kontur des Fehlers. Meldungen
## der Prüfung zu diesem Feld stehen darunter weiter.
func _set_problem(field: String, text: String) -> void:
	var hint: Label = _hints[field]
	var lines := PackedStringArray([text])
	if hint.visible and not hint.text.is_empty():
		lines.append(hint.text)
	hint.text = "\n".join(lines)
	hint.theme_type_variation = &"ErrorLabel"
	hint.visible = true
	FieldHelpers.mark_error(_inputs[field])


## In %Fields steht links die Beschriftung, rechts eine Zelle aus Feld und Hinweis darunter. Ein
## GridContainer macht jede Zeile so hoch wie ihre höchste Zelle; mit sichtbarem Hinweis stünde die
## Beschriftung sonst mitten in der Zeile statt neben ihrem Feld. Sie bekommt deshalb die Höhe des
## Felds, steht oben und darin mittig, wie im Formular.
func _align_captions() -> void:
	var fields: GridContainer = %Fields
	for field in FIELDS:
		var cell := (_hints[field] as Control).get_parent() as Control
		var caption := fields.get_child(cell.get_index() - 1) as Label
		caption.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.custom_minimum_size.y = (_inputs[field] as Control).get_combined_minimum_size().y


# --- Tabelle ----------------------------------------------------------------------------------

func _set_up_table() -> void:
	_table.columns = TITLES.size()
	_table.column_titles_visible = true
	_table.hide_root = true
	# Ohne Klapp-Pfeil fällt auch sein Platz vorn in der ersten Spalte weg; sonst bliebe für das
	# Zeichen in der schmalen Spalte nichts übrig.
	_table.hide_folding = true
	_table.select_mode = Tree.SELECT_ROW
	for column in _table.columns:
		_table.set_column_title(column, TITLES[column])
		_table.set_column_title_alignment(column, HORIZONTAL_ALIGNMENT_LEFT)
		_table.set_column_clip_content(column, true)
		_table.set_column_expand(column, WIDTHS[column] == 0)
		if WIDTHS[column] > 0:
			_table.set_column_custom_minimum_width(column, WIDTHS[column])
	_table.create_item()


## Merkt den Neubau der Zeilen für das Ende des Bilds vor, einmal, wie oft refresh() auch kommt.
func _queue_rows() -> void:
	if _rows_queued:
		return
	_rows_queued = true
	_fill_rows_later.call_deferred()


## Der vorgemerkte Neubau; hat das Panel inzwischen sofort gebaut, etwa nach „Neu“, ist er erledigt.
func _fill_rows_later() -> void:
	if _rows_queued:
		_fill_rows()


## Baut die Zeilen des gezeigten Profils neu, je Start-Modifikator eine, in seiner Reihenfolge.
func _fill_rows() -> void:
	_rows_queued = false
	_syncing = true
	_zebra.forget()
	_table.clear()
	var root := _table.create_item()
	var profile := _profile()
	if profile != null:
		var severities := _severities()
		for i in profile.modifiers.size():
			_add_row(root, profile.modifiers[i], severities.get(i, -1))
	_syncing = false
	_highlight()


func _add_row(root: TreeItem, modifier: ChanceModifier, severity: int) -> void:
	var item := _table.create_item(root)
	var target := editor.catalog.get_event(modifier.event_id)
	item.set_text(Column.EVENT, _target_label(modifier.event_id, target, false))
	item.set_tooltip_text(Column.EVENT, "%s · %s" % [item.get_text(Column.EVENT), modifier.event_id])
	item.set_text(Column.VALUE, TimelineRun._points(modifier.value))
	item.set_text(Column.FROM, FieldHelpers.format_date(modifier.from_day))
	item.set_text(Column.TO, FieldHelpers.format_date(modifier.to_day))
	item.set_text(Column.REASON, modifier.reason)
	item.set_tooltip_text(Column.REASON, modifier.reason)
	item.set_text(Column.ID, modifier.id)
	item.set_tooltip_text(Column.ID, modifier.id)
	# Style-Guide, „Farbrollen“, wie in der Liste der Ereignisse: Ein Fehler ist ein gefülltes Feld
	# in kassenrot mit „!“ in papier, eine Warnung ein „?“ in holz. Beide Zellen behalten ihren
	# Grund über keep_cell(), auch in einer gestreiften oder gewählten Zeile.
	if severity < 0:
		return
	item.set_text_alignment(Column.MARK, HORIZONTAL_ALIGNMENT_CENTER)
	if severity == CatalogIssue.Severity.ERROR:
		item.set_text(Column.MARK, "!")
		_zebra.keep_cell(item, Column.MARK, UiPalette.KASSENROT)
		item.set_custom_color(Column.MARK, UiPalette.PAPIER)
		item.set_tooltip_text(Column.MARK,
			"Der Start-Modifikator hat einen Fehler und gilt im Spiel nicht; die Prüfung nennt ihn.")
	else:
		item.set_text(Column.MARK, "?")
		_zebra.keep_cell(item, Column.MARK, UiPalette.PAPIER)
		item.set_custom_color(Column.MARK, UiPalette.HOLZ)
		item.set_tooltip_text(Column.MARK, "Der Start-Modifikator hat eine Warnung.")


## Markiert die gewählte Zeile, sofern es sie schon gibt. Danach malt das Zebra alle Zeilen neu:
## deselect_all() meldet sich mit keinem Signal.
func _highlight() -> void:
	_syncing = true
	_table.deselect_all()
	var root := _table.get_root()
	if root != null and _index >= 0 and _index < root.get_child_count():
		var item := root.get_child(_index)
		item.select(Column.EVENT)
		_table.scroll_to_item(item)
	_syncing = false
	_zebra.paint_all()


## Je Stelle im gezeigten Profil die schwerste Meldung: ERROR ist 0, WARNING 1.
func _severities() -> Dictionary:
	var result := {}
	for issue in editor.issues():
		var place := _place_of(issue.field)
		if place["level"] != shown_difficulty() or place["index"] < 0:
			continue
		var index: int = place["index"]
		result[index] = mini(result.get(index, CatalogIssue.Severity.WARNING), issue.severity)
	return result


## Ein Klick wählt die Zeile. Ihre Stelle ist die Stelle im Profil, denn das Profil wird nie
## sortiert. Zeigen die Zeilen bis zum Neubau noch einen alten Stand, prüft _choose() die Stelle.
func _on_table_selected() -> void:
	if _syncing:
		return
	var item := _table.get_selected()
	if item == null or item.get_index() == _index:
		return
	_commit_focused()
	_choose(item.get_index())


## Setzt die gewählte Stelle und füllt die Felder, auch das mit dem Fokus.
func _choose(index: int) -> void:
	var profile := _profile()
	_index = index if profile != null and index >= 0 and index < profile.modifiers.size() else -1
	_update_buttons()
	_fill_fields(true)


# --- Eingaben ---------------------------------------------------------------------------------

func _set_up_edit(field: String, edit: LineEdit) -> void:
	# Übernommen wird beim Verlassen; Enter gibt nur den Fokus ab, damit das nächste Cmd+Z den
	# Katalog erreicht statt das Textfeld (R15 von Feature 002).
	edit.focus_exited.connect(_commit.bind(field))
	edit.text_submitted.connect(func(_text: String) -> void: edit.release_focus())
	# Ein LineEdit merkt sich auch das Setzen von text als Schritt in seinem Verlauf, und leeren
	# lässt sich der von außen nicht. Cmd+Z im Feld nähme sonst den Wert ganz weg. gui_input kommt
	# vor der eigenen Verarbeitung des Felds; zeigt es noch den übernommenen Wert, schluckt das
	# Panel die Taste, wie das Formular. Mit dem Fokus im Feld gehört sie trotzdem dem Feld.
	edit.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed(&"ui_undo") and edit.text == _shown.get(field):
			edit.accept_event())


## Übernimmt die offene Eingabe im Feld mit dem Fokus, wie es dessen focus_exited täte, und lässt
## den Fokus, wo er ist: bevor Klaus Zeile oder Grad wechselt oder einen Knopf drückt (wie
## EventForm._commit_focused(), T095 von Feature 002).
func _commit_focused() -> void:
	if not is_inside_tree():
		return
	var focus := get_viewport().gui_get_focus_owner()
	for field in EDIT_FIELDS:
		if _inputs[field] == focus:
			_commit(field)


## Übernimmt, was im Feld [param field] steht, falls es sich geändert hat: lesen, zeigen, an den
## Katalog, für die gerade gezeigte Zeile. Lässt es sich nicht lesen, bleibt der alte Wert stehen,
## und ein Hinweis am Feld sagt warum.
func _commit(field: String) -> void:
	var edit: LineEdit = _inputs[field]
	if editor == null or _modifier() == null:
		return
	var before: String = _shown.get(field, "")
	if edit.text == before:
		return
	var parsed := _parse(field, edit.text)
	if not parsed[0]:
		edit.text = before
		_set_problem(field, parsed[1])
		return
	var shown := _format(field, parsed[1])
	edit.text = shown
	_shown[field] = shown
	editor.set_start_modifier_field(shown_difficulty(), _index, StringName(field), parsed[1])


func _on_event_picked(index: int) -> void:
	if _modifier() == null or index < 0 or index >= _event_ids.size():
		return
	editor.set_start_modifier_field(shown_difficulty(), _index, &"event_id", _event_ids[index])


## „Neu“: auf das gewählte Ereignis der Werkstatt, wenn es über Wahrscheinlichkeit kommt, sonst
## auf das erste solche nach Kennung (CatalogEditor). Danach ist die neue Zeile gewählt und der
## Fokus in „Wert“, alles markiert: Klaus tippt gleich die Zahl.
func _on_new_pressed() -> void:
	_commit_focused()
	if _profile() == null:
		return
	var level := shown_difficulty()
	var chosen := editor.catalog.get_event(selected_event_id)
	var target := selected_event_id \
		if chosen != null and chosen.kind == TimelineEvent.Kind.CHANCE else ""
	if editor.add_start_modifier(level, target) == null:
		return
	_after_own_change(_profile().modifiers.size() - 1)
	var value: LineEdit = _inputs["value"]
	value.grab_focus()
	value.select_all()


func _on_duplicate_pressed() -> void:
	_commit_focused()
	var index := _index
	if _modifier() == null or editor.duplicate_start_modifier(shown_difficulty(), index) == null:
		return
	_after_own_change(index + 1)


## „Löschen“ fragt nicht nach, wie „−“ bei den Wirkungen; Cmd+Z holt den Start-Modifikator zurück
## (R11). Danach ist keine Zeile gewählt.
func _on_delete_pressed() -> void:
	_commit_focused()
	if _modifier() == null:
		return
	editor.delete_start_modifier(shown_difficulty(), _index)
	_after_own_change(-1)


## Nach einer Änderung aus dem Panel selbst: Die Zeilen sofort, damit die gewählte Zeile schon
## dasteht. Ein Klick in die Tabelle war es nicht, also trifft hier kein Klick eine falsche Zeile.
func _after_own_change(index: int) -> void:
	_index = index
	_update_view(true)
	_fill_rows()


# --- Hilfen -----------------------------------------------------------------------------------

## Das Profil des gezeigten Grads; null bei Mittel oder ohne Katalog.
func _profile() -> DifficultyProfile:
	if editor == null or editor.catalog == null:
		return null
	return editor.catalog.get_profile(shown_difficulty())


## Der gewählte Start-Modifikator, jedes Mal frisch aus dem Katalog; null ohne Auswahl.
func _modifier() -> ChanceModifier:
	var profile := _profile()
	if profile == null or _index < 0 or _index >= profile.modifiers.size():
		return null
	return profile.modifiers[_index]


func _has_chance_event() -> bool:
	if editor == null or editor.catalog == null:
		return false
	return editor.catalog.events.any(
		func(event: TimelineEvent) -> bool: return event.kind == TimelineEvent.Kind.CHANCE)


## Die Ereignisse über Wahrscheinlichkeit nach Titel, bei gleichem Titel nach Kennung.
func _chance_events() -> Array[TimelineEvent]:
	var result: Array[TimelineEvent] = []
	for event in editor.catalog.events:
		if event.kind == TimelineEvent.Kind.CHANCE:
			result.append(event)
	result.sort_custom(func(a: TimelineEvent, b: TimelineEvent) -> bool:
		var order := _title_of(a).naturalnocasecmp_to(_title_of(b))
		return order < 0 if order != 0 else a.id < b.id)
	return result


## Wie das Ziel eines Start-Modifikators heißt: sein Titel; „konkurrent (unbekannt)“, wenn es das
## Ereignis nicht gibt, und „– kein Ereignis –“ ohne Kennung. In der Auswahl nennt
## [param with_kind] dazu die Art eines Ereignisses, das nicht über Wahrscheinlichkeit kommt, etwa
## „Weihnachtsgeschäft (fix, jährlich)“.
static func _target_label(event_id: String, target: TimelineEvent, with_kind: bool) -> String:
	if event_id.is_empty():
		return "– kein Ereignis –"
	if target == null:
		return "%s (unbekannt)" % event_id
	if with_kind and target.kind != TimelineEvent.Kind.CHANCE:
		return "%s (%s)" % [_title_of(target), target.kind_label()]
	return _title_of(target)


static func _title_of(event: TimelineEvent) -> String:
	return event.title if not event.title.strip_edges().is_empty() else event.id


## „3 Start-Modifikatoren“, „1 Start-Modifikator“, „keine Start-Modifikatoren“.
static func _count_text(count: int) -> String:
	if count == 0:
		return "keine Start-Modifikatoren"
	return "%d %s" % [count, "Start-Modifikator" if count == 1 else "Start-Modifikatoren"]


## Ein Wert so, wie ihn Tabelle und Feld zeigen: Prozentpunkte mit Vorzeichen und dem einfachen
## Minus wie TimelineRun._points(), etwa „+5“ und „-2,5“; damit liest FieldHelpers.parse_percent()
## die angezeigte Zahl wieder. Tage als TT.MM.JJJJ, Texte, wie sie sind.
static func _format(field: String, value: Variant) -> String:
	match field:
		"value":
			return TimelineRun._points(value)
		"from_day", "to_day":
			return FieldHelpers.format_date(value)
	return str(value)


## Liest die Eingabe eines Felds mit den Lesefunktionen aus FieldHelpers: Zahlen mit Komma oder
## Punkt und Vorzeichen, Daten auch ohne führende Nullen. Grund und Kennung nehmen jeden Text an;
## was nicht passt, zeigt die Prüfung (V29, V30).
static func _parse(field: String, text: String) -> Array:
	match field:
		"value":
			return FieldHelpers.parse_percent(text)
		"from_day", "to_day":
			return FieldHelpers.parse_date(text)
	return FieldHelpers.parse_text(text)
