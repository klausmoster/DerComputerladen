class_name MainMenu
extends Control

## Das Hauptmenü auf Endlospapier (Baustein Menü im Style-Guide).
##
## Oben steht die Kopfzeile „HAUPTMENÜ“, darunter je Eintrag ein Button. Die Buttons
## sind durchsichtig (Theme-Variante `MenuRow`). Papier, Zeilenfarben, Lochränder,
## Hervorhebung und Pfeil malt das Menü selbst in `_draw()`, also unter den Buttons.
##
## Die Auswahl ist Godots Fokus: Gewählt ist die Zeile, deren Button den Fokus hat. So
## gibt es nur eine Auswahl, gleich welche Eingabe sie ändert.
##
## Das Menü führt selbst nichts aus, es meldet nur. Was ein Eintrag bewirkt, entscheidet,
## wer `entry_activated` hört.

## Ein verfügbarer Eintrag wurde ausgelöst.
signal entry_activated(id: StringName)
## Eine Zeile wurde gewählt. [param row_rect] ist die ganze Zeile in globalen Koordinaten.
signal selection_changed(entry: MenuEntry, row_rect: Rect2)

## Höhe jeder Zeile, auch der Kopfzeile.
const ROW_HEIGHT := 20
## Breite des Papiers.
const PAPER_WIDTH := 144
## Links und rechts frei bis zum Innenbereich der Zeilen: Lochrand (8) und Abstand (4).
## Derselbe Wert steht als offset_left und offset_right von Rows in main_menu.tscn.
const ROW_INSET := 12
## Lochränder: Kreise mit Radius 2, Mittelpunkt 4 vom Rand, ab y 10 alle 12 Pixel.
const HOLE_RADIUS := 2
const HOLE_INSET := 4
const HOLE_FIRST_Y := 10
const HOLE_SPACING := 12
## Pfeil vor der gewählten Zeile: ein Pixel-Dreieck, 4 breit und 7 hoch, linke Kante bei x 16.
const ARROW_X := 16
const ARROW_WIDTH := 4
const ARROW_HEIGHT := 7
## pixelschatten: harter Versatz nach rechts unten, ohne Unschärfe.
const SHADOW_OFFSET := 2

## Die Einträge von oben nach unten. Aus ihnen baut `_ready()` die Zeilen.
@export var entries: Array[MenuEntry] = []

var _buttons: Array[Button] = []
var _selected_index := 0

@onready var _rows: VBoxContainer = $Rows


func _ready() -> void:
	for index in entries.size():
		var button := _make_row(index)
		_rows.add_child(button)
		_buttons.append(button)
	custom_minimum_size = Vector2(PAPER_WIDTH, ROW_HEIGHT * _row_count())
	# Zeitversetzt: Erst ordnet der VBoxContainer die Zeilen an, dann stimmt auch das
	# Rechteck, das selection_changed für die erste Zeile meldet.
	select.call_deferred(0)


func _draw() -> void:
	var paper := Rect2(0, 0, size.x, ROW_HEIGHT * _row_count())
	# Zuerst der pixelschatten: dasselbe Rechteck, um 2 nach rechts unten versetzt.
	# Alles, was danach gemalt wird, liegt darüber.
	draw_rect(Rect2(paper.position + Vector2.ONE * SHADOW_OFFSET, paper.size), UiPalette.TUSCHE)
	# Die Zeilen im Wechsel papier / endlos-gruen; die Kopfzeile ist die erste papier-Zeile.
	for row in _row_count():
		var color: Color = UiPalette.PAPIER if row % 2 == 0 else UiPalette.ENDLOS_GRUEN
		draw_rect(Rect2(0, row * ROW_HEIGHT, paper.size.x, ROW_HEIGHT), color)
	# Die Lochränder links und rechts, durchgehend über alle Zeilen. Auf dem Pixelraster
	# ist ein Kreis mit Radius 2 um einen Gitterpunkt ein 4 × 4-Block ohne Ecken.
	var hole_y := HOLE_FIRST_Y
	while hole_y + HOLE_RADIUS <= paper.size.y:
		draw_circle(Vector2(HOLE_INSET, hole_y), HOLE_RADIUS, UiPalette.TUSCHE)
		draw_circle(Vector2(paper.size.x - HOLE_INSET, hole_y), HOLE_RADIUS, UiPalette.TUSCHE)
		hole_y += HOLE_SPACING
	# Die gewählte Zeile: signalgelb im Innenbereich, davor der Pfeil.
	if selected_entry() == null:
		return
	var row_top := ROW_HEIGHT * (_selected_index + 1)
	var highlight := Rect2(ROW_INSET, row_top, paper.size.x - 2 * ROW_INSET, ROW_HEIGHT)
	draw_rect(highlight, UiPalette.SIGNALGELB)
	# (20 − 7) / 2 geht nicht auf. Abgerundet belegt der Pfeil die Pixelreihen 6 bis 12
	# der Zeile.
	var arrow_top := row_top + floori((ROW_HEIGHT - ARROW_HEIGHT) / 2.0)
	_draw_arrow(Vector2(ARROW_X, arrow_top), UiPalette.TUSCHE)


## Wählt Zeile [param index], indem ihr Button den Fokus bekommt. Außerhalb der Liste
## geht es am anderen Ende weiter, -1 ist also die letzte Zeile.
func select(index: int) -> void:
	if _buttons.is_empty():
		return
	_buttons[posmod(index, _buttons.size())].grab_focus()


func selected_index() -> int:
	return _selected_index


## Der gewählte Eintrag, oder null, solange das Menü keine Einträge hat.
func selected_entry() -> MenuEntry:
	if _selected_index < 0 or _selected_index >= entries.size():
		return null
	return entries[_selected_index]


## Löst den gewählten Eintrag aus, aber nur, wenn er verfügbar ist.
func activate_selected() -> void:
	var entry := selected_entry()
	if entry != null and entry.available:
		entry_activated.emit(entry.id)


## Kopfzeile und Einträge.
func _row_count() -> int:
	return entries.size() + 1


## Baut den Button für Eintrag [param index]: durchsichtig und linksbündig. Den Platz
## für den Pfeil hält die Theme-Variante MenuRow links frei.
func _make_row(index: int) -> Button:
	var entry := entries[index]
	var button := Button.new()
	button.text = entry.label
	button.disabled = not entry.available
	button.theme_type_variation = &"MenuRow"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	button.focus_entered.connect(_on_row_focus_entered.bind(index))
	button.pressed.connect(_on_row_pressed.bind(index))
	return button


## Die ganze Zeile [param index] in globalen Koordinaten, von Papierrand zu Papierrand.
## Der Button deckt nur den Innenbereich ab; der Hinweis richtet sich aber nach der Zeile.
func _row_rect(index: int) -> Rect2:
	return _buttons[index].get_global_rect().grow_individual(ROW_INSET, 0, ROW_INSET, 0)


## Der Pfeil als Pixel-Dreieck: vier Spalten mit den Höhen 7, 5, 3 und 1, jede mittig.
func _draw_arrow(top_left: Vector2, color: Color) -> void:
	for column in ARROW_WIDTH:
		var height := ARROW_HEIGHT - 2 * column
		draw_rect(Rect2(top_left.x + column, top_left.y + column, 1, height), color)


func _on_row_focus_entered(index: int) -> void:
	_selected_index = index
	queue_redraw()
	selection_changed.emit(entries[index], _row_rect(index))


## Ein gesperrter Button sendet pressed gar nicht erst, hier kommen nur verfügbare an.
func _on_row_pressed(index: int) -> void:
	entry_activated.emit(entries[index].id)
