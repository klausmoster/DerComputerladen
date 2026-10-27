class_name SaveList
extends Control

## Das Blatt SPIELSTÄNDE im Titel (Baustein Liste im Style-Guide; Feature 004,
## contracts/titelbildschirm.md, „SaveList“; research.md, R12): je Spielstand eine Zeile mit vier
## Spalten, darunter immer „Löschen …“ und „Zurück“.
##
## Gebaut wie das Hauptmenü: oben die Kopfzeile, darunter je Zeile ein durchsichtiger Button
## (Theme-Variante `MenuRow`), und `_draw()` malt Papier, Auswahl und Pfeil mit `MenuPaper`. Die
## Auswahl ist Godots Fokus, Maus und Tastatur teilen sich also eine.
##
## Anders als im Menü gibt es nicht je Eintrag einen Button, sondern ein Fenster aus
## [constant VISIBLE_ROWS] Zeilen, die beim Rollen ihren Inhalt wechseln. Ein `ScrollContainer`
## schöbe die Zeilen pixelweise und zeigte halbe Zeilen und einen Rollbalken; hier rollt die Liste
## immer um eine ganze Zeile, und das Zebra bleibt an seiner Zeile (R12). Weil eine Zeile beim
## Rollen einen anderen Spielstand zeigt, steuert die Liste die Pfeiltasten und Tab selbst, statt
## Godot den nächsten Button suchen zu lassen.
##
## Die Spalten sind Labels im Button, an festen Anfängen ab dem Text der Zeile ([constant COLUMNS]).
## Schrift und Farben nehmen sie aus der Theme-Variante des Buttons.
##
## Die Liste führt selbst nichts aus, sie meldet nur. Allein den Löschmodus schaltet sie selbst ein,
## denn er ändert nur sie. Ausschalten kann ihn nur, wer sie zeigt: Ob „Zurück“ und Esc den Modus
## oder das Blatt beenden, entscheidet der Titelbildschirm.

## Eine fortsetzbare Zeile wurde ausgelöst.
signal resume_requested(slot: SaveSlot)
## Im Löschmodus wurde eine Zeile ausgelöst.
signal delete_requested(slot: SaveSlot)
## „Zurück“ wurde ausgelöst, im Löschmodus wie außerhalb. Was dann geschieht, entscheidet
## TitleScreen: im Löschmodus den Modus beenden, sonst ins Hauptmenü (Analyse, F3).
signal back_requested
## Eine Zeile wurde gewählt; für den Hinweis wie MainMenu.selection_changed. [param row_rect] ist
## die ganze Zeile in globalen Koordinaten.
signal selection_changed(hint: String, row_rect: Rect2)

## Höchstens so viele Spielstände sind zu sehen (Style-Guide, Baustein Liste).
const VISIBLE_ROWS: int = 6
## Anfänge der Spalten ab dem Text der Zeile: Name, Grad, Spieldatum, zuletzt gespielt (Style-Guide,
## Baustein Liste).
const COLUMNS: Array[int] = [0, 64, 108, 172]
## Breite des Papiers (Style-Guide, Baustein Liste).
const PAPER_WIDTH: int = 304

## Höhe jeder Zeile, auch der Kopfzeile.
const ROW_HEIGHT := MenuPaper.ROW_HEIGHT
## Links und rechts frei bis zum Innenbereich der Zeilen: Lochrand (8) und Abstand (4). Derselbe
## Wert steht als offset_left und offset_right von Rows in save_list.tscn.
const ROW_INSET := MenuPaper.ROW_INSET
## Der Text einer Zeile beginnt so weit vom linken Rand des Papiers: Lochrand 8, Abstand 4,
## Pfeil 12. Den Pfeil hält im Button der Innenabstand der Theme-Variante MenuRow frei.
const TEXT_INSET := 24
## Rechts bleibt so viel frei, vom Rand des Papiers.
const TEXT_END_INSET := 12
## Luft hinter jeder Spalte: Die letzte ist 90 breit, dahinter 6 (Style-Guide, Baustein Liste).
## Dieselbe Luft gilt hinter dem Namen; so passt „Spiel 9999“ (57) und „Spiel 10000“ (63) nicht.
const COLUMN_GAP := 6
## Rollmarken: ein Dreieck in tusche, 7 breit und 4 hoch wie der gedrehte Pfeil, 8 unter der
## Oberkante der Zeile und 12 vom rechten Rand des Papiers (Style-Guide, Baustein Liste).
const SCROLL_MARK_WIDTH := 7
const SCROLL_MARK_HEIGHT := 4
const SCROLL_MARK_TOP := 8
const SCROLL_MARK_INSET := 12

## Die Labels einer Zeile, in dieser Reihenfolge; „State“ steht bei nicht fortsetzbaren Spielständen
## statt Grad und Spieldatum.
const CELL_NAMES: Array[StringName] = [&"Name", &"Difficulty", &"Day", &"Played", &"State"]

## Die Spielstände in der Reihenfolge der Liste.
var _slots: Array[SaveSlot] = []
## Gewählt ist Zeile _selected_index: 0 bis _slots.size() − 1 ein Spielstand, dann „Löschen …“,
## dann „Zurück“.
var _selected_index := 0
## Die Zeile, die `_ready()` wählt; show_slots() vor dem Erscheinen setzt sie.
var _start_index := 0
## Der Spielstand, den die oberste Zeile des Fensters zeigt.
var _first_visible := 0
var _delete_mode := false

## Die Zeilen des Fensters, von oben nach unten, und die zwei festen darunter.
var _slot_buttons: Array[Button] = []
var _delete_button: Button
var _back_button: Button

@onready var _rows: VBoxContainer = $Rows
@onready var _header: Label = $Rows/Header


func _ready() -> void:
	_build_rows()
	_update_header()
	_refresh_rows()
	_update_size()
	# Zeitversetzt wie im Menü: Erst wenn alle Knoten im Baum bereit sind, wählt die Liste ihre
	# Startzeile und meldet sie. So hört der Titelbildschirm die erste Meldung schon.
	select.call_deferred(_start_index)


func _draw() -> void:
	MenuPaper.draw_paper(self, size.x, _row_count())
	# Die Auswahl: signalgelb, davor der Pfeil, gedämpft wie der Text der Zeile.
	MenuPaper.draw_selection(self, size.x, _visual_row(_selected_index) + 1,
		not _is_dimmed(_selected_index))
	# Die Rollmarken zuletzt, damit sie auch auf einer gewählten Zeile „Löschen …“ zu sehen sind.
	if _more_above():
		_draw_scroll_mark(0, true)
	if _more_below():
		_draw_scroll_mark(_visual_row(_slots.size()) + 1, false)


## Mausrad über der Kopfzeile oder dem Rand des Papiers. Über einer Zeile kommt es bei
## _on_row_gui_input() an, denn ein Button gibt Mausereignisse nicht an das Blatt weiter.
func _gui_input(event: InputEvent) -> void:
	if _handle_wheel(event):
		accept_event()


## Zeigt [param slots] in dieser Reihenfolge, Löschmodus aus, Auswahl auf Zeile [param index]. Zeile
## 0 ist der oberste Spielstand, danach kommen „Löschen …“ und „Zurück“. Das Fenster bleibt, wo es
## war, soweit es geht, und rollt nur so weit, dass die gewählte Zeile zu sehen ist.
func show_slots(slots: Array[SaveSlot], index: int = 0) -> void:
	_slots = slots.duplicate()
	_delete_mode = false
	_start_index = index
	# Vor dem Erscheinen gibt es Rows noch nicht; dann baut _ready() alles auf.
	if not is_node_ready():
		return
	_update_header()
	_update_size()
	select(index)


## Schaltet den Löschmodus ein oder aus. Die Auswahl bleibt, wo sie war; ihr Hinweis kommt neu,
## denn im Löschmodus sagt jede Zeile etwas anderes.
func set_delete_mode(on: bool) -> void:
	_delete_mode = on
	if not is_node_ready():
		return
	_update_header()
	select(_selected_index)


func is_delete_mode() -> bool:
	return _delete_mode


## Der Spielstand der gewählten Zeile; null bei „Löschen …“ und „Zurück“.
func selected_slot() -> SaveSlot:
	if _selected_index < _slots.size():
		return _slots[_selected_index]
	return null


## Wählt Zeile [param index] (wie bei show_slots()), rollt das Fenster dorthin und meldet die
## Auswahl. Außerhalb der Liste geht es am anderen Ende weiter, -1 ist also „Zurück“.
##
## Ist die Liste unsichtbar, merkt sie sich die Zeile nur und meldet nichts, wie MainMenu.select().
## Wer sie zeigt, ruft danach select(selected_index()).
func select(index: int) -> void:
	if _delete_button == null:
		_start_index = index
		return
	_selected_index = posmod(index, _slots.size() + 2)
	_scroll_to(_selected_index)
	_refresh_rows()
	queue_redraw()
	if not is_visible_in_tree():
		return
	# Hat der Button den Fokus schon, kommt kein focus_entered. Gemeldet wird trotzdem, denn nach
	# dem Rollen zeigt derselbe Button einen anderen Spielstand mit anderem Hinweis.
	_button_for(_selected_index).grab_focus()
	selection_changed.emit(_hint_for(_selected_index), _row_rect(_visual_row(_selected_index)))


func selected_index() -> int:
	return _selected_index


# --- Aufbau ---------------------------------------------------------------------------------------

## Legt die Buttons an: VISIBLE_ROWS Zeilen für Spielstände, dann „Löschen …“ und „Zurück“. Es
## bleiben immer dieselben; rollen und show_slots() ändern nur ihren Inhalt.
func _build_rows() -> void:
	for row in VISIBLE_ROWS:
		var button := _make_row("Slot%d" % row, "")
		for cell in CELL_NAMES:
			button.add_child(_make_cell(button, cell))
		_slot_buttons.append(button)
	_delete_button = _make_row("DeleteMode", TitleTexts.LABEL_DELETE_MODE)
	_back_button = _make_row("Back", TitleTexts.LABEL_BACK)


## Ein durchsichtiger, linksbündiger Button wie im Menü, schon in Rows eingehängt, damit er das
## Theme kennt, bevor seine Labels Schrift und Farbe von ihm holen.
func _make_row(node_name: String, label: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.theme_type_variation = &"MenuRow"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	button.focus_entered.connect(_on_row_focus_entered.bind(button))
	button.pressed.connect(_on_row_pressed.bind(button))
	button.gui_input.connect(_on_row_gui_input.bind(button))
	_rows.add_child(button)
	return button


## Ein Label für Spalte [param cell] in [param button]. Ein Button ist kein Container; seine Kinder
## stehen also genau dort, wo position sie hinsetzt. Schrift und Größe kommen aus der Theme-Variante
## MenuRow des Buttons, die Farbe setzt _fill_row().
func _make_cell(button: Button, cell: StringName) -> Label:
	var label := Label.new()
	label.name = cell
	# Die Maus geht durch das Label hindurch an den Button: Überfahren und Klicks gelten der Zeile.
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", button.get_theme_font(&"font"))
	label.add_theme_font_size_override(&"font_size", button.get_theme_font_size(&"font_size"))
	var column := COLUMNS[_column_of(cell)]
	label.position = Vector2(TEXT_INSET - ROW_INSET + column, 0)
	label.size = Vector2(_cell_width(cell), ROW_HEIGHT)
	if cell == &"Name":
		# Passt der Name nicht, kürzt Godot ihn selbst und hängt „…“ an (ellipsis_char). Dafür muss
		# das Label eine feste Breite haben; mit Kürzen schrumpft auch seine Mindestbreite, sonst
		# wüchse es mit dem Text.
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.clip_text = true
	return label


## Welche Spalte [param cell] beginnt: „State“ steht, wo sonst der Grad steht.
static func _column_of(cell: StringName) -> int:
	match cell:
		&"Name":
			return 0
		&"Day":
			return 2
		&"Played":
			return 3
	return 1


## Breite des Felds von [param cell]: bis zum Anfang der nächsten Spalte, die letzte bis 12 vor dem
## Rand, jeweils ohne die Luft dahinter. „State“ reicht über Grad und Spieldatum.
static func _cell_width(cell: StringName) -> int:
	var text_width := PAPER_WIDTH - TEXT_INSET - TEXT_END_INSET
	match cell:
		&"Name":
			return COLUMNS[1] - COLUMNS[0] - COLUMN_GAP
		&"Difficulty":
			return COLUMNS[2] - COLUMNS[1] - COLUMN_GAP
		&"Day":
			return COLUMNS[3] - COLUMNS[2] - COLUMN_GAP
		&"Played":
			return text_width - COLUMNS[3] - COLUMN_GAP
	return COLUMNS[3] - COLUMNS[1] - COLUMN_GAP


func _update_header() -> void:
	_header.text = TitleTexts.HEADER_DELETE_MODE if _delete_mode else TitleTexts.HEADER_SAVES


## Papier so breit wie PAPER_WIDTH und so hoch wie alle sichtbaren Zeilen; wie im Menü die Größe
## selbst, nicht nur die Mindestgröße, damit das Blatt mit weniger Spielständen auch schrumpft.
func _update_size() -> void:
	custom_minimum_size = Vector2(PAPER_WIDTH, ROW_HEIGHT * _row_count())
	size = custom_minimum_size


## Kopfzeile, die Zeilen des Fensters mit Spielstand, „Löschen …“ und „Zurück“.
func _row_count() -> int:
	return 1 + _shown_slot_rows() + 2


## Wie viele Zeilen des Fensters einen Spielstand zeigen.
func _shown_slot_rows() -> int:
	return mini(_slots.size(), VISIBLE_ROWS)


# --- Inhalt ---------------------------------------------------------------------------------------

## Füllt jede Zeile des Fensters mit dem Spielstand, den sie gerade zeigt, versteckt die übrigen und
## stellt „Löschen …“ auf den Modus ein.
func _refresh_rows() -> void:
	for row in VISIBLE_ROWS:
		var button := _slot_buttons[row]
		var index := _first_visible + row
		button.visible = index < _slots.size()
		if button.visible:
			_fill_row(button, _slots[index])
	# „Löschen …“ ist im Löschmodus nicht verfügbar: gesperrt, also gedämpft und ohne Wirkung.
	_delete_button.disabled = _delete_mode
	_delete_button.mouse_default_cursor_shape = _cursor(not _delete_mode)
	_back_button.mouse_default_cursor_shape = _cursor(true)


## Schreibt [param slot] in die Spalten von [param button].
func _fill_row(button: Button, slot: SaveSlot) -> void:
	var resumable := slot.can_resume()
	var texts := {&"Name": slot.display_name()}
	if resumable:
		texts[&"Difficulty"] = Difficulty.label(slot.game.difficulty)
		texts[&"Day"] = slot.game.day_text()
		texts[&"Played"] = SaveGame.time_text(slot.game.last_played_at)
	else:
		texts[&"State"] = _state_text(slot)
	# Gedämpft heißt: löst nichts aus. Außerhalb des Löschmodus ist das eine Zeile, die sich nicht
	# fortsetzen lässt; im Löschmodus löst jede Zeile die Rückfrage aus und steht in der normalen
	# Farbe, das Zustandswort sagt weiter, was mit ihr ist (Klaus, 2026-10-26). Die Farben kommen
	# aus der Theme-Variante MenuRow, wie bei Zeilen mit eigenem Text.
	var triggers := _delete_mode or resumable
	var color := button.get_theme_color(&"font_color" if triggers else &"font_disabled_color")
	for cell in CELL_NAMES:
		var label := button.get_node(NodePath(String(cell))) as Label
		label.visible = texts.has(cell)
		label.text = texts.get(cell, "")
		label.add_theme_color_override(&"font_color", color)
	# Gesperrt heißt hier dasselbe. Der Button hat keinen eigenen Text; was gedämpft aussieht,
	# regeln die Labels.
	button.disabled = not triggers
	button.mouse_default_cursor_shape = _cursor(triggers)


## „beschädigt“ oder „neuere Version“.
static func _state_text(slot: SaveSlot) -> String:
	if slot.state == SaveSlot.State.TOO_NEW:
		return TitleTexts.STATE_TOO_NEW
	return TitleTexts.STATE_DAMAGED


## Die Hand verspricht, dass ein Klick etwas tut; sonst der Pfeil (Style-Guide, Baustein Menü).
static func _cursor(triggers: bool) -> CursorShape:
	return CURSOR_POINTING_HAND if triggers else CURSOR_ARROW


## Der Hinweis zu Zeile [param index], je nach Modus (contracts/titelbildschirm.md, „Texte“).
func _hint_for(index: int) -> String:
	if index < _slots.size():
		var slot := _slots[index]
		if _delete_mode:
			return TitleTexts.slot_delete_hint(slot.display_name())
		if not slot.can_resume():
			return slot.reason
		# time_text() gibt „26.10.2026 21:40“; der Hinweis nennt Datum und Uhrzeit getrennt.
		var played := SaveGame.time_text(slot.game.last_played_at).split(" ")
		return TitleTexts.slot_hint(slot.game.day_text(), played[0], played[1])
	if index == _slots.size():
		return TitleTexts.HINT_DELETE_MODE_ACTIVE if _delete_mode else TitleTexts.HINT_DELETE_MODE
	return TitleTexts.HINT_BACK_DELETE_MODE if _delete_mode else TitleTexts.HINT_BACK


## Ob Zeile [param index] gedämpft ist, weil sie nichts auslöst: außerhalb des Löschmodus ein
## Spielstand, der sich nicht fortsetzen lässt, im Löschmodus „Löschen …“.
func _is_dimmed(index: int) -> bool:
	if index < _slots.size():
		return not _delete_mode and not _slots[index].can_resume()
	return index == _slots.size() and _delete_mode


# --- Fenster und Rollen ---------------------------------------------------------------------------

## Rollt so wenig wie möglich, damit Zeile [param index] im Fenster steht. „Löschen …“ und „Zurück“
## stehen immer da und rollen nicht mit. Nach show_slots() mit weniger Spielständen rückt das
## Fenster so weit hoch, dass es keine leere Zeile zeigt.
func _scroll_to(index: int) -> void:
	_first_visible = clampi(_first_visible, 0, _last_first())
	if index >= _slots.size():
		return
	if index < _first_visible:
		_first_visible = index
	elif index >= _first_visible + VISIBLE_ROWS:
		_first_visible = index - VISIBLE_ROWS + 1


## Der größte Wert für _first_visible: Dann zeigt die unterste Zeile den letzten Spielstand.
func _last_first() -> int:
	return maxi(_slots.size() - VISIBLE_ROWS, 0)


## Rollt das Fenster um [param step] Zeilen, ohne die Auswahl zu verschieben. Fällt der gewählte
## Spielstand aus dem Fenster, rückt die Auswahl auf die nächste Zeile, die noch zu sehen ist; der
## Hinweis steht immer neben einer sichtbaren Zeile.
func _scroll_by(step: int) -> void:
	var first := clampi(_first_visible + step, 0, _last_first())
	if first == _first_visible:
		return
	_first_visible = first
	var index := _selected_index
	if index < _slots.size():
		index = clampi(index, first, first + VISIBLE_ROWS - 1)
	select(index)


## Rollt bei einem Dreh am Mausrad um eine Zeile. true, wenn [param event] ein Mausrad war.
func _handle_wheel(event: InputEvent) -> bool:
	var wheel := event as InputEventMouseButton
	if wheel == null:
		return false
	match wheel.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if wheel.pressed:
				_scroll_by(-1)
			return true
		MOUSE_BUTTON_WHEEL_DOWN:
			if wheel.pressed:
				_scroll_by(1)
			return true
	return false


func _more_above() -> bool:
	return _first_visible > 0


func _more_below() -> bool:
	return _first_visible + VISIBLE_ROWS < _slots.size()


## Wo die Rollmarke in Zeile [param row] steht (0 ist die Kopfzeile), in Koordinaten des Blatts.
func _scroll_mark_rect(row: int) -> Rect2:
	return Rect2(size.x - SCROLL_MARK_INSET - SCROLL_MARK_WIDTH, ROW_HEIGHT * row + SCROLL_MARK_TOP,
		SCROLL_MARK_WIDTH, SCROLL_MARK_HEIGHT)


## Malt die Rollmarke in Zeile [param row] als Pixel-Dreieck: vier Reihen mit den Breiten 1, 3, 5
## und 7 nach oben, 7, 5, 3 und 1 nach unten, jede mittig. Das ist der Pfeil vor der Auswahl,
## gedreht.
func _draw_scroll_mark(row: int, up: bool) -> void:
	var rect := _scroll_mark_rect(row)
	for line in SCROLL_MARK_HEIGHT:
		var inset := SCROLL_MARK_HEIGHT - 1 - line if up else line
		draw_rect(Rect2(rect.position.x + inset, rect.position.y + line,
			SCROLL_MARK_WIDTH - 2 * inset, 1), UiPalette.TUSCHE)


# --- Zeilen und Auswahl ---------------------------------------------------------------------------

## Welche Zeile der Liste [param button] gerade zeigt.
func _index_of(button: Button) -> int:
	var row := _slot_buttons.find(button)
	if row != -1:
		return _first_visible + row
	if button == _delete_button:
		return _slots.size()
	return _slots.size() + 1


func _button_for(index: int) -> Button:
	if index < _slots.size():
		return _slot_buttons[index - _first_visible]
	if index == _slots.size():
		return _delete_button
	return _back_button


## Die Zeile auf dem Papier, in der Zeile [param index] steht, ohne die Kopfzeile: 0 ist die
## oberste Zeile des Fensters.
func _visual_row(index: int) -> int:
	if index < _slots.size():
		return index - _first_visible
	return _shown_slot_rows() + index - _slots.size()


## Die ganze Zeile [param visual_row] in globalen Koordinaten, von Papierrand zu Papierrand.
## Gerechnet aus der Lage des Blatts wie in MainMenu._row_rect().
func _row_rect(visual_row: int) -> Rect2:
	var local := Rect2(0, ROW_HEIGHT * (visual_row + 1), size.x, ROW_HEIGHT)
	return get_global_transform() * local


## Kommt der Fokus von anderswo auf eine Zeile, etwa mit einem Klick, wird sie die Auswahl. Kommt
## er von select(), ist sie es schon.
func _on_row_focus_entered(button: Button) -> void:
	var index := _index_of(button)
	if index != _selected_index:
		select(index)


## Ein gesperrter Button sendet pressed nicht; hier kommen nur Zeilen an, die etwas auslösen.
func _on_row_pressed(button: Button) -> void:
	var index := _index_of(button)
	if index < _slots.size():
		var slot := _slots[index]
		if _delete_mode:
			delete_requested.emit(slot)
		elif slot.can_resume():
			resume_requested.emit(slot)
	elif index == _slots.size():
		if not _delete_mode:
			set_delete_mode(true)
	else:
		back_requested.emit()


## Eingaben an einer Zeile, bevor der Button sie sieht; accept_event() hält sie dann von ihm und vom
## Viewport fern.
## - Mausbewegung wählt die Zeile. Jede Bewegung, nicht nur das Hineinfahren: Nach dem Mausrad
##   steht unter der ruhenden Maus ein anderer Spielstand, und schon ein kleines Rucken wählt ihn.
## - Rechtsklick wählt und zeigt den Hinweis, löst aber nichts aus.
## - Mausrad rollt.
## - Pfeil hoch und runter, Tab und Shift+Tab wählen die Zeile davor oder danach und laufen an den
##   Enden um. Die Liste macht das selbst, denn am Rand des Fensters bleibt der Fokus auf seinem
##   Button, und nur der Inhalt rollt. Godot suchte dagegen einen anderen Button und fände am Rand
##   keinen oder den falschen. Wie der Viewport selbst vergleichen die Abfragen genau (exact_match):
##   Sonst zählte Shift+Tab auch als Tab.
func _on_row_gui_input(event: InputEvent, button: Button) -> void:
	if event is InputEventMouseMotion:
		var index := _index_of(button)
		if index != _selected_index:
			select(index)
		return
	if _handle_wheel(event):
		button.accept_event()
		return
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_RIGHT:
		if click.pressed:
			select(_index_of(button))
		button.accept_event()
		return
	var step := 0
	if event.is_action_pressed(&"ui_up", true, true) \
			or event.is_action_pressed(&"ui_focus_prev", true, true):
		step = -1
	elif event.is_action_pressed(&"ui_down", true, true) \
			or event.is_action_pressed(&"ui_focus_next", true, true):
		step = 1
	if step != 0:
		button.accept_event()
		select(_selected_index + step)
