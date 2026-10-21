class_name IssuesPanel
extends Tree

## Die Prüfung der Werkstatt (FR-033; contracts/werkstatt.md, „Liste, Formular, Prüfung“): alle
## Meldungen des Katalogs als Tabelle mit Stufe, Ereignis, Feld und Text. Ein Klick auf eine
## Meldung sendet issue_activated; die Werkstatt wählt dann das Ereignis und setzt den Fokus ins
## Feld. Meldungen zu Kategorien haben kein Ereignis und führen zum Bereich für Kategorien.
##
## Das Panel ist selbst ein Tree: Ein Tree kann Spalten mit Überschriften und markiert die ganze
## Zeile, eine ItemList nur einen Eintrag. Die Zeilen hängen unter einer unsichtbaren Wurzel
## (hide_root), denn die Meldungen bilden keine Hierarchie.
##
## Fehler und Warnung unterscheiden sich in Form und Zeichen, nicht nur in der Farbe (Style-Guide,
## „Farbrollen“): Ein Fehler ist ein gefülltes Feld in kassenrot mit „!“ in papier, eine Warnung
## Text in holz mit „?“ davor. Die Zeilen sind gestreift wie alle Tabellen der Werkstatt (Zebra);
## die Zelle der Stufe behält dabei ihren Grund.
##
## Neue Meldungen zeigt das Panel erst am Ende des Bilds, wie die Liste der Ereignisse: Ein Klick in
## die Prüfung nimmt einem Feld im Formular den Fokus, bevor der Tree den Klick verarbeitet. Das
## Feld übernimmt seine Eingabe, die Meldungen ändern sich, und bauten die Zeilen sofort neu, träfe
## der Klick die neue Belegung statt der Meldung, die unter der Maus stand (T076).

signal issue_activated(event_id: String, field: String)

enum Column { SEVERITY, EVENT, FIELD, TEXT }

const TITLES: Array[String] = ["Stufe", "Ereignis", "Feld", "Text"]
## Breite der schmalen Spalten; der Text nimmt den Rest.
const WIDTHS: Array[int] = [112, 200, 200, 0]

## Streifen, Auswahl und Überfahren der Prüfung.
var _zebra: Zebra
## Die Meldungen, die das Panel am Ende des Bilds zeigt, und ob das vorgemerkt ist.
var _pending: Array[CatalogIssue] = []
var _queued := false


func _ready() -> void:
	_zebra = Zebra.new(self)
	columns = TITLES.size()
	column_titles_visible = true
	hide_root = true
	# Ohne Klapp-Pfeil fällt auch sein Platz vorn in der ersten Spalte weg.
	hide_folding = true
	select_mode = Tree.SELECT_ROW
	for column in columns:
		set_column_title(column, TITLES[column])
		set_column_title_alignment(column, HORIZONTAL_ALIGNMENT_LEFT)
		set_column_clip_content(column, true)
		set_column_expand(column, WIDTHS[column] == 0)
		if WIDTHS[column] > 0:
			set_column_custom_minimum_width(column, WIDTHS[column])
	# Ein Mausklick wählt und springt sofort zum Feld, auch auf die schon gewählte Zeile. Mit den
	# Pfeiltasten wandert nur die Auswahl, sonst nähme jeder Schritt der Liste den Fokus weg;
	# Enter oder ein Doppelklick springen dann.
	item_mouse_selected.connect(_on_item_mouse_selected)
	item_activated.connect(_activate_selected)
	show_issues([])


## Zeigt [param issues] in ihrer Reihenfolge: zuerst die Meldungen beim Lesen, dann die der
## Prüfung, darin nach Ereignis und Regel, Kategorien zuletzt (CatalogValidator). Gebaut wird am
## Ende des Bilds, einmal, mit den zuletzt übergebenen Meldungen (siehe oben).
func show_issues(issues: Array[CatalogIssue]) -> void:
	_pending = issues
	if _queued:
		return
	_queued = true
	_fill.call_deferred()


func _fill() -> void:
	_queued = false
	var issues := _pending
	_zebra.forget()
	clear()
	var root := create_item()
	if issues.is_empty():
		var empty := create_item(root)
		empty.set_text(Column.TEXT, "Keine Meldungen. Der Katalog ist in Ordnung.")
		for column in columns:
			empty.set_selectable(column, false)
		_zebra.paint_all()
		return
	for issue in issues:
		var item := create_item(root)
		var is_error := issue.severity == CatalogIssue.Severity.ERROR
		# Die Stufe behält ihren Grund über keep_cell(), auch in einer gestreiften oder gewählten
		# Zeile: holz ist nur auf papier gut zu lesen.
		if is_error:
			item.set_text(Column.SEVERITY, "! Fehler")
			_zebra.keep_cell(item, Column.SEVERITY, UiPalette.KASSENROT)
			item.set_custom_color(Column.SEVERITY, UiPalette.PAPIER)
		else:
			item.set_text(Column.SEVERITY, "? Warnung")
			_zebra.keep_cell(item, Column.SEVERITY, UiPalette.PAPIER)
			item.set_custom_color(Column.SEVERITY, UiPalette.HOLZ)
		item.set_text(Column.EVENT, issue.event_id if not issue.event_id.is_empty() else "–")
		item.set_text(Column.FIELD, issue.field)
		item.set_text(Column.TEXT, issue.message)
		item.set_tooltip_text(Column.TEXT, issue.message)
		item.set_metadata(Column.SEVERITY, {"event_id": issue.event_id, "field": issue.field})
	_zebra.paint_all()


func _on_item_mouse_selected(_position: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_LEFT:
		_activate_selected()


func _activate_selected() -> void:
	var item := get_selected()
	if item == null:
		return
	var place: Variant = item.get_metadata(Column.SEVERITY)
	if typeof(place) != TYPE_DICTIONARY:
		return
	issue_activated.emit(place["event_id"], place["field"])
