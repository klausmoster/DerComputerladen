class_name EventList
extends VBoxContainer

## Die Liste der Ereignisse links in der Werkstatt (FR-030, FR-032; contracts/werkstatt.md,
## „EventList“): Suche über den Titel, Filter nach Art und Kategorie, je Zeile ein Zeichen für
## Fehler oder Warnung, Titel und Art. Darunter „Neu …“, „Duplizieren“ und „Löschen“.
##
## Die Liste ändert den Katalog nur über den CatalogEditor: Den Dialog „Neu …“ bringt sie selbst
## mit und ruft add_event(), Duplizieren ruft duplicate_event(). Alles andere meldet sie nach oben,
## an die Werkstatt: welches Ereignis gewählt wurde, dass eines neu entstanden ist und dass eines
## gelöscht werden soll. Die Auswahl gehört der Werkstatt, ebenso die Rückfrage vor dem Löschen.
##
## Die Zeilen sind gestreift wie alle Tabellen der Werkstatt (Zebra); das Zeichen für Fehler und
## Warnung behält seine Farben auch in einer gestreiften oder gewählten Zeile.

signal event_selected(id: String)
## Ein Ereignis ist neu entstanden, aus dem Dialog „Neu …“ oder durch Duplizieren.
signal event_created(id: String)
## Klaus will das gewählte Ereignis löschen; die Werkstatt fragt nach und nennt die Verweise.
signal delete_requested(id: String)
## Suche, Art oder Kategorie haben sich geändert, also auch, welche Ereignisse durchkommen. Die
## Werkstatt gibt den Filter dann an den Zeitstrahl weiter (T074).
signal filter_changed()

enum Column { MARK, TITLE, KIND }

## Kurze Namen der Arten für die schmale Spalte, in der Reihenfolge von TimelineEvent.Kind. Der
## lange Name steht im Tooltip und im Filter.
const SHORT_KIND_LABELS: Array[String] = ["fix", "jährlich", "gesetzt", "Chance", "Folge"]

var editor: CatalogEditor

## Das gewählte Ereignis; die Werkstatt setzt es mit select_event().
var _selected_id := ""
## Kennung → schwerste Meldung zu diesem Ereignis.
var _severity_by_event := {}
## Ob die Liste ihre Zeilen gerade selbst setzt; die Signale des Tree zählen dann nicht.
var _syncing := false
## Ob Klaus die Kennung im Dialog „Neu …“ selbst geändert hat; dann schlägt die Liste keine mehr
## vor.
var _id_edited := false
## Der Tag, mit dem der Dialog „Neu …“ vorbelegt ist, etwa nach einem Doppelklick im Zeitstrahl;
## −1 heißt keiner. Er gilt nur für fixe Ereignisse.
var _new_day := -1
## Streifen, Auswahl und Überfahren der Liste.
var _zebra: Zebra
## Was die Zeilen gerade zeigen, als ein Text (_rows_key()). Nach jeder Änderung kommen refresh()
## und show_issues(); ist der Text derselbe, bleiben die Zeilen stehen. Mit 500 Ereignissen spart
## das je Änderung zwei Neubauten von je rund 15 ms (SC-011).
var _shown_rows := ""

@onready var _search: LineEdit = %Search
@onready var _kind_filter: OptionButton = %KindFilter
@onready var _category_filter: OptionButton = %CategoryFilter
@onready var _tree: Tree = %List
@onready var _duplicate_button: Button = %DuplicateButton
@onready var _delete_button: Button = %DeleteButton
@onready var _new_dialog: ConfirmationDialog = %NewDialog
@onready var _new_kind: OptionButton = %NewKind
@onready var _new_title: LineEdit = %NewTitle
@onready var _new_category: OptionButton = %NewCategory
@onready var _new_date_caption: Label = %DateCaption
@onready var _new_date: Label = %NewDate
@onready var _new_id: LineEdit = %NewId
@onready var _new_hint: Label = %NewHint


func _ready() -> void:
	_tree.columns = Column.size()
	_tree.hide_root = true
	# Die Liste ist flach. Ohne Klapp-Pfeil fällt auch sein Platz vorn in der ersten Spalte weg;
	# sonst bliebe für das Zeichen in der schmalen Spalte nichts übrig.
	_tree.hide_folding = true
	_tree.select_mode = Tree.SELECT_ROW
	_tree.column_titles_visible = true
	_tree.set_column_title(Column.TITLE, "Titel")
	_tree.set_column_title(Column.KIND, "Art")
	_tree.set_column_title_alignment(Column.TITLE, HORIZONTAL_ALIGNMENT_LEFT)
	_tree.set_column_title_alignment(Column.KIND, HORIZONTAL_ALIGNMENT_LEFT)
	_tree.set_column_expand(Column.MARK, false)
	_tree.set_column_custom_minimum_width(Column.MARK, 24)
	_tree.set_column_expand(Column.KIND, false)
	_tree.set_column_custom_minimum_width(Column.KIND, 72)
	_tree.set_column_clip_content(Column.TITLE, true)
	_zebra = Zebra.new(_tree)
	_kind_filter.add_item("Alle Arten")
	for label in TimelineEvent.KIND_LABELS:
		_kind_filter.add_item(label)
	for label in TimelineEvent.KIND_LABELS:
		_new_kind.add_item(label)
	_search.text_changed.connect(func(_text: String) -> void: _on_filter_changed())
	_kind_filter.item_selected.connect(func(_index: int) -> void: _on_filter_changed())
	_category_filter.item_selected.connect(func(_index: int) -> void: _on_filter_changed())
	_tree.item_selected.connect(_on_item_selected)
	%NewButton.pressed.connect(open_new_dialog)
	_duplicate_button.pressed.connect(_on_duplicate_pressed)
	_delete_button.pressed.connect(func() -> void: delete_requested.emit(_selected_id))
	_new_title.text_changed.connect(_on_new_title_changed)
	_new_id.text_changed.connect(_on_new_id_changed)
	_new_kind.item_selected.connect(func(_index: int) -> void: _check_new())
	_new_dialog.confirmed.connect(_on_new_confirmed)
	_new_dialog.register_text_enter(_new_title)
	_new_dialog.register_text_enter(_new_id)
	_update_buttons()


## Baut Filter und Zeilen aus dem aktuellen Katalog neu, etwa nach catalog_changed. Gibt es die
## Kategorie im Filter nicht mehr, gilt wieder „Alle Kategorien“, und filter_changed meldet das.
func refresh() -> void:
	var lost := _fill_category_choices()
	_fill_rows()
	if lost:
		filter_changed.emit()


## Ob gerade gefiltert wird: Im Suchfeld steht etwas, oder Art oder Kategorie sind gewählt.
func is_filtered() -> bool:
	return not _query().is_empty() or _kind_filter.selected > 0 \
		or not _chosen_category().is_empty()


## Ob [param event] durch Suche und Filter kommt, nach derselben Regel wie die Zeilen der Liste.
## Der Zeitstrahl fragt hier, statt selbst zu filtern (T074); ohne Filter kommt jedes durch.
func passes(event: TimelineEvent) -> bool:
	return _passes(event, _query(), _kind_filter.selected - 1, _chosen_category())


## Zeigt an den Zeilen die schwerste Meldung je Ereignis, nach issues_changed.
func show_issues(issues: Array[CatalogIssue]) -> void:
	_severity_by_event.clear()
	for issue in issues:
		if issue.event_id.is_empty():
			continue
		# ERROR ist 0, WARNING 1: Die kleinere Zahl ist die schwerere Meldung.
		var worst: int = _severity_by_event.get(issue.event_id, CatalogIssue.Severity.WARNING)
		_severity_by_event[issue.event_id] = mini(worst, issue.severity)
	_fill_rows()


## Hebt das Ereignis hervor, das die Werkstatt gewählt hat, ohne event_selected zu senden.
func select_event(id: String) -> void:
	_selected_id = id
	_highlight()
	_update_buttons()


## Öffnet den Dialog „Neu …“: Art, Titel, Kategorie und die vorgeschlagene Kennung (US2,
## Szenario 1; FR-032). Der Knopf „Neu …“ ruft das ohne Werte auf. Nach einem Doppelklick im
## Zeitstrahl ist der Dialog vorbelegt: Art, [param category] und [param day]. Der Tag gilt nur,
## solange die Art „fix“ bleibt; wählt Klaus eine andere, gelten deren Vorgaben (US4, Szenario 5).
func open_new_dialog(kind: TimelineEvent.Kind = TimelineEvent.Kind.FIXED, category: String = "",
		day: int = -1) -> void:
	if editor == null or editor.catalog == null:
		return
	_new_title.text = ""
	_new_id.text = ""
	_id_edited = false
	_new_day = day
	_new_kind.select(kind)
	_fill_new_categories(category)
	_check_new()
	_new_dialog.popup_centered()
	_new_title.grab_focus()


# --- Zeilen -----------------------------------------------------------------------------------

## Baut die Zeilen neu, aber nur, wenn sie danach etwas anderes zeigten als jetzt. Ein Tree baut
## neue Zeilen nicht billig: Jede Zelle setzt ihren Text neu, und spätestens beim Rollen zur
## gewählten Zeile muss er jeden davon ausmessen. Das neue Datum eines Ereignisses ändert an der
## Liste nichts, ein neuer Titel oder ein neuer Fehler schon.
func _fill_rows() -> void:
	var key := _rows_key()
	if key == _shown_rows:
		return
	_shown_rows = key
	_syncing = true
	_zebra.forget()
	_tree.clear()
	var root := _tree.create_item()
	if editor != null and editor.catalog != null:
		for event in _visible_events():
			_add_row(root, event)
	_syncing = false
	_highlight()


## Alles, wovon die Zeilen abhängen, in einem Text: Suche, Filter und je Ereignis Kennung, Titel,
## Art, Kategorie und das Zeichen für Fehler oder Warnung. Die Zeilen zeigen davon Titel, Art,
## Zeichen und im Hinweis die Kennung; nach der Kategorie wird gefiltert, nach Titel und Kennung
## sortiert. Gleicher Text heißt also gleiche Zeilen. Das Trennzeichen \u001f kommt in keinem
## Titel vor, den jemand eintippt.
func _rows_key() -> String:
	if editor == null or editor.catalog == null:
		return "-"
	var parts := PackedStringArray([_search.text, str(_kind_filter.selected),
		_chosen_category()])
	for event in editor.catalog.events:
		parts.append("%s\u001f%s\u001f%d\u001f%s\u001f%d" % [event.id, event.title, event.kind,
			event.category, _severity_by_event.get(event.id, -1)])
	return "\n".join(parts)


## Die Ereignisse, die Suche und Filter durchlassen, nach Titel sortiert, bei gleichem Titel
## nach Kennung.
func _visible_events() -> Array[TimelineEvent]:
	var query := _query()
	var kind := _kind_filter.selected - 1
	var category := _chosen_category()
	var result: Array[TimelineEvent] = []
	# Die Titel klein, einmal je Ereignis: Der Vergleich beim Sortieren läuft bei 500 Ereignissen
	# rund 4.500-mal, und to_lower() in jedem Vergleich kostete mehr als das ganze Sortieren sonst.
	var lowered := {}
	for event in editor.catalog.events:
		if not _passes(event, query, kind, category):
			continue
		result.append(event)
		lowered[event] = event.title.to_lower()
	result.sort_custom(func(a: TimelineEvent, b: TimelineEvent) -> bool:
		var title_a: String = lowered[a]
		var title_b: String = lowered[b]
		if title_a != title_b:
			return title_a.naturalnocasecmp_to(title_b) < 0
		return a.id < b.id)
	return result


## Die Kennung der Kategorie im Filter; leer heißt alle.
func _chosen_category() -> String:
	if _category_filter.selected > 0:
		return _category_filter.get_item_metadata(_category_filter.selected)
	return ""


## Der Suchtext, wie er gilt: ohne Leerzeichen am Rand und klein.
func _query() -> String:
	return _search.text.strip_edges().to_lower()


## Die Regel des Filters an einer Stelle, für die Zeilen und für passes(): Der Titel enthält die
## Suche, Groß- und Kleinschreibung egal, und Art und Kategorie stimmen, wenn sie gewählt sind.
## [param kind] −1 und [param category] leer heißen alle.
static func _passes(event: TimelineEvent, query: String, kind: int, category: String) -> bool:
	if not query.is_empty() and not event.title.to_lower().contains(query):
		return false
	if kind >= 0 and event.kind != kind:
		return false
	return category.is_empty() or event.category == category


## Suche, Art oder Kategorie geändert: neue Zeilen, und die Werkstatt erfährt es.
func _on_filter_changed() -> void:
	_fill_rows()
	filter_changed.emit()


func _add_row(root: TreeItem, event: TimelineEvent) -> void:
	var item := _tree.create_item(root)
	item.set_metadata(Column.MARK, event.id)
	var title := event.title if not event.title.strip_edges().is_empty() else "(ohne Titel)"
	item.set_text(Column.TITLE, title)
	item.set_text(Column.KIND, SHORT_KIND_LABELS[event.kind])
	var tooltip := "%s · %s · %s" % [title, event.kind_label(), event.id]
	for column in Column.size():
		item.set_tooltip_text(column, tooltip)
	# Style-Guide, „Farbrollen“: Ein Fehler ist ein gefülltes Feld in kassenrot mit „!“ in papier,
	# eine Warnung ein „?“ in holz. Beide Zellen behalten ihren Grund über keep_cell(), auch in
	# einer gestreiften oder gewählten Zeile: holz ist nur auf papier gut zu lesen.
	if _severity_by_event.has(event.id):
		var severity: int = _severity_by_event[event.id]
		item.set_text_alignment(Column.MARK, HORIZONTAL_ALIGNMENT_CENTER)
		if severity == CatalogIssue.Severity.ERROR:
			item.set_text(Column.MARK, "!")
			_zebra.keep_cell(item, Column.MARK, UiPalette.KASSENROT)
			item.set_custom_color(Column.MARK, UiPalette.PAPIER)
			item.set_tooltip_text(Column.MARK,
				"Das Ereignis hat einen Fehler; die Prüfung nennt ihn.")
		else:
			item.set_text(Column.MARK, "?")
			_zebra.keep_cell(item, Column.MARK, UiPalette.PAPIER)
			item.set_custom_color(Column.MARK, UiPalette.HOLZ)
			item.set_tooltip_text(Column.MARK, "Das Ereignis hat eine Warnung.")


## Markiert die Zeile des gewählten Ereignisses, falls Suche und Filter sie zeigen. Danach malt das
## Zebra alle Zeilen neu: deselect_all() meldet sich mit keinem Signal.
func _highlight() -> void:
	_syncing = true
	_tree.deselect_all()
	var root := _tree.get_root()
	if root != null:
		for item in root.get_children():
			if item.get_metadata(Column.MARK) == _selected_id and not _selected_id.is_empty():
				item.select(Column.TITLE)
				_tree.scroll_to_item(item)
				break
	_syncing = false
	_zebra.paint_all()


func _on_item_selected() -> void:
	if _syncing:
		return
	var item := _tree.get_selected()
	if item == null:
		return
	var id: String = item.get_metadata(Column.MARK)
	_selected_id = id
	_update_buttons()
	event_selected.emit(id)


func _update_buttons() -> void:
	var has_event := editor != null and editor.catalog != null \
		and editor.catalog.get_event(_selected_id) != null
	_duplicate_button.disabled = not has_event
	_delete_button.disabled = not has_event


func _on_duplicate_pressed() -> void:
	var copy := editor.duplicate_event(_selected_id)
	if copy != null:
		event_created.emit(copy.id)


# --- Filter -----------------------------------------------------------------------------------

## Füllt die Auswahl der Kategorien; die gewählte bleibt, solange es sie gibt. Gibt zurück, ob sie
## verloren ging, weil es sie nicht mehr gibt; dann gilt „Alle Kategorien“.
func _fill_category_choices() -> bool:
	var chosen := _chosen_category()
	_category_filter.clear()
	_category_filter.add_item("Alle Kategorien")
	_category_filter.set_item_metadata(0, "")
	if editor == null or editor.catalog == null:
		return not chosen.is_empty()
	for category in editor.catalog.categories:
		_category_filter.add_item(_category_label(category))
		var index := _category_filter.item_count - 1
		_category_filter.set_item_metadata(index, category.id)
		if category.id == chosen:
			_category_filter.select(index)
	return _chosen_category() != chosen


static func _category_label(category: EventCategory) -> String:
	return category.name if not category.name.strip_edges().is_empty() else category.id


# --- Dialog „Neu …“ ---------------------------------------------------------------------------

## Die Kategorien zur Wahl; vorgewählt ist [param wanted], ohne sie die aus dem Filter, sonst die
## erste.
func _fill_new_categories(wanted: String) -> void:
	_new_category.clear()
	var preferred := wanted
	if preferred.is_empty() and _category_filter.selected > 0:
		preferred = _category_filter.get_item_metadata(_category_filter.selected)
	for category in editor.catalog.categories:
		_new_category.add_item(_category_label(category))
		var index := _new_category.item_count - 1
		_new_category.set_item_metadata(index, category.id)
		if category.id == preferred:
			_new_category.select(index)


## Solange Klaus die Kennung nicht selbst ändert, folgt sie dem Titel.
func _on_new_title_changed(_text: String) -> void:
	if not _id_edited:
		_new_id.text = editor.suggest_id(_new_title.text)
	_check_new()


func _on_new_id_changed(text: String) -> void:
	_id_edited = not text.is_empty() and text != editor.suggest_id(_new_title.text)
	_check_new()


## Prüft Titel und Kennung und sperrt „Anlegen“, solange etwas nicht stimmt; der Grund steht im
## Hinweis unter den Feldern. Ein leerer Titel braucht keinen: Das Feld zeigt, was hinein soll.
func _check_new() -> void:
	var problem := ""
	var id := _new_id.text
	var titled := not _new_title.text.strip_edges().is_empty()
	if titled and id.is_empty():
		problem = "Gib eine Kennung ein."
	elif titled and not _is_id(id):
		problem = "Die Kennung darf nur a–z, 0–9 und _ enthalten."
	elif titled and editor.catalog.get_event(id) != null:
		problem = "Die Kennung „%s“ gibt es schon." % id
	_new_hint.text = problem
	_new_hint.visible = not problem.is_empty()
	_new_dialog.get_ok_button().disabled = not titled or not problem.is_empty()
	# Den Tag zeigt der Dialog nur, solange er gilt: vorbelegt und Art „fix“.
	var dated := _new_day >= 0 and _new_kind.selected == TimelineEvent.Kind.FIXED
	_new_date_caption.visible = dated
	_new_date.visible = dated
	_new_date.text = str(GameDate.from_day_index(_new_day)) if dated else ""
	# Ein Fenster wächst mit seinem Inhalt, wird von selbst aber nicht wieder kleiner.
	if _new_dialog.visible:
		_new_dialog.reset_size()


func _on_new_confirmed() -> void:
	_check_new()
	if _new_dialog.get_ok_button().disabled:
		return
	var category := ""
	if _new_category.selected >= 0:
		category = _new_category.get_item_metadata(_new_category.selected)
	var kind := _new_kind.selected as TimelineEvent.Kind
	var day := _new_day if kind == TimelineEvent.Kind.FIXED else -1
	var event := editor.add_event(kind, _new_title.text.strip_edges(), category, day, _new_id.text)
	if event != null:
		event_created.emit(event.id)


## Ob [param text] nur aus a–z, 0–9 und _ besteht.
static func _is_id(text: String) -> bool:
	for character: String in text:
		var allowed := (character >= "a" and character <= "z") \
			or (character >= "0" and character <= "9") or character == "_"
		if not allowed:
			return false
	return true
