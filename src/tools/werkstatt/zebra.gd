class_name Zebra
extends RefCounted

## Zebra für die Tabellen der Werkstatt (Style-Guide, Abschnitt „Werkzeuge“, „Farbrollen“): jede
## zweite Zeile endlos-gruen, die gewählte petrol, die unter der Maus signalgelb. Den Text in der
## gewählten Zeile schreibt der Tree selbst in papier (Theme, font_selected_color).
##
## Ein Tree malt die eigene Farbe einer Zelle (set_custom_bg_color()) über seine Auswahl und sein
## Überfahren; eine grüne Zeile verdeckte sonst das petrol der Auswahl (Probe im Fenster, Phase 7).
## Zebra setzt deshalb alle drei Farben selbst, Zeile für Zeile.
##
## Zellen mit eigener Bedeutung, etwa das Fehlerfeld „!“ in kassenrot, meldet ihr Besitzer mit
## keep_cell() an; Zebra übermalt sie nie. Liste, Prüfung und Simulator benutzen es so:
## [codeblock]
## _zebra = Zebra.new(tree)    # einmal, etwa in _ready()
## _zebra.forget()             # vor tree.clear()
## ...                         # Zeilen anlegen, Zellen mit eigener Farbe über keep_cell()
## _zebra.paint_all()          # danach und nach jeder Auswahl aus dem Code
## [/codeblock]
##
## Zebra ist kein Node, sondern RefCounted, und hängt sich nur an die Signale des Tree. Wer es
## anlegt, hält es in einer Variablen; eine Verbindung allein hält es nicht am Leben.

const COLOR_SECOND_ROW := UiPalette.ENDLOS_GRUEN     # jede zweite Zeile
const COLOR_SELECTION := UiPalette.PETROL            # gewählte Zeile, der Text darauf in papier
const COLOR_HOVER := UiPalette.SIGNALGELB            # Zeile unter der Maus

var _tree: Tree
## Die Zeilen, die gerade gewählt bzw. unter der Maus sind; nach ihnen malt Zebra neu.
var _selected: TreeItem
var _hovered: TreeItem
## Zeile → { Spalte: Farbe } für die Zellen mit eigener Farbe (keep_cell()).
var _kept := {}
## Wo die Maus zuletzt war, und ob die Zeile darunter schon zum Suchen vorgemerkt ist.
var _mouse_at := Vector2.ZERO
var _hover_queued := false


func _init(tree: Tree) -> void:
	_tree = tree
	_tree.item_selected.connect(_on_item_selected)
	_tree.gui_input.connect(_on_gui_input)
	_tree.mouse_exited.connect(_set_hovered.bind(null))


## Vor Tree.clear(): Danach gibt es die Zeilen nicht mehr, und Zebra darf sie nicht anfassen.
func forget() -> void:
	_selected = null
	_hovered = null
	_kept.clear()


## Gibt einer Zelle eine eigene Hintergrundfarbe, die Zebra nie übermalt, auch nicht in einer
## gestreiften, gewählten oder überfahrenen Zeile; etwa dem Fehlerfeld „!“ kassenrot.
func keep_cell(item: TreeItem, column: int, color: Color) -> void:
	if not _kept.has(item):
		_kept[item] = {}
	_kept[item][column] = color
	item.set_custom_bg_color(column, color)


## Malt alle Zeilen: nachdem die Tabelle neu gefüllt ist und nachdem der Code die Auswahl geändert
## hat, denn deselect_all() meldet sich mit keinem Signal.
func paint_all() -> void:
	_selected = _tree.get_selected()
	var root := _tree.get_root()
	if root == null:
		return
	var index := 0
	for item in root.get_children():
		paint(item, index)
		index += 1


## Malt die Zeile [param item]; [param index] ist ihre Stelle in der Tabelle, gezählt ab 0.
func paint(item: TreeItem, index: int) -> void:
	var color := COLOR_SECOND_ROW
	var plain := false
	if _is_selected(item):
		color = COLOR_SELECTION
	elif item == _hovered:
		color = COLOR_HOVER
	elif index % 2 == 0:
		plain = true
	var kept: Dictionary = _kept.get(item, {})
	for column in _tree.columns:
		if kept.has(column):
			item.set_custom_bg_color(column, kept[column])
		elif plain:
			item.clear_custom_bg_color(column)
		else:
			item.set_custom_bg_color(column, color)


func _on_item_selected() -> void:
	var old := _selected
	_selected = _tree.get_selected()
	if old != null and is_instance_valid(old) and old != _selected:
		paint(old, old.get_index())
	if _selected != null:
		paint(_selected, _selected.get_index())


## gui_input kommt, bevor der Tree die Eingabe verarbeitet. Welche Zeile danach unter der Maus
## liegt, steht erst am Ende des Bilds fest; nach dem Mausrad ist es eine andere. Gesucht wird
## einmal je Bild, auch wenn die Maus in einem Bild mehrmals ruckt.
func _on_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse == null:
		return
	_mouse_at = mouse.position
	if not _hover_queued:
		_hover_queued = true
		_update_hover.call_deferred()


## Eine Zeile, die sich nicht wählen lässt, etwa „Keine Meldungen“ in der Prüfung, leuchtet beim
## Überfahren nicht auf.
func _update_hover() -> void:
	_hover_queued = false
	if not is_instance_valid(_tree) or not _tree.is_inside_tree():
		return
	var item := _tree.get_item_at_position(_mouse_at)
	if item != null and not _is_selectable(item):
		item = null
	_set_hovered(item)


func _set_hovered(item: TreeItem) -> void:
	if item == _hovered:
		return
	var old := _hovered
	_hovered = item
	if old != null and is_instance_valid(old):
		paint(old, old.get_index())
	if item != null:
		paint(item, item.get_index())


## Ob die Zeile gewählt ist. Mit Tree.SELECT_ROW sind es alle wählbaren Zellen zugleich.
func _is_selected(item: TreeItem) -> bool:
	for column in _tree.columns:
		if item.is_selected(column):
			return true
	return false


func _is_selectable(item: TreeItem) -> bool:
	for column in _tree.columns:
		if item.is_selectable(column):
			return true
	return false
