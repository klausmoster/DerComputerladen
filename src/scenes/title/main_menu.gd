class_name MainMenu
extends Control

## Ein Menü auf Endlospapier (Baustein Menü im Style-Guide): das Hauptmenü und, als weitere
## Instanz derselben Szene, jedes andere Blatt im Titel mit einer Angabe je Zeile, etwa die
## Gradwahl.
##
## Oben steht die Kopfzeile [member header_text], darunter je Eintrag ein Button. Die Buttons
## sind durchsichtig (Theme-Variante `MenuRow`). Papier, Zeilenfarben, Lochränder,
## Hervorhebung und Pfeil malt das Menü in `_draw()` mit den statischen Funktionen von
## `MenuPaper`, also unter den Buttons. Dasselbe Papier malt später die Liste der Spielstände.
##
## Die Auswahl ist Godots Fokus: Gewählt ist die Zeile, deren Button den Fokus hat. So
## gibt es nur eine Auswahl, gleich welche Eingabe sie ändert. Die Maus holt sich den
## Fokus beim Überfahren und beim Rechtsklick, Pfeiltasten und Tab verschieben ihn, und
## an beiden Enden geht es am anderen Ende weiter. Verlässt die Maus das Menü, bleibt
## die Auswahl, wo sie ist.
##
## Das Menü führt selbst nichts aus, es meldet nur. Was ein Eintrag bewirkt, entscheidet,
## wer `entry_activated` hört.
##
## Seit Feature 005 kann das Menü auch auf der Anzeige des Communicators stehen ([member look] =
## LCD; Style-Guide, Baustein Menü, „Auf der Anzeige“). Dann malt es kein Papier, die Zeilen nehmen
## die Theme-Varianten `LcdRow` und `LcdHeader`, und die gewählte Zeile ist ein Balken in tusche mit
## Schrift und Pfeil in lcd. Die Größe gibt dann der Communicator; das Menü setzt keine eigene.
## Bedienung, Auswahl und Signale sind in beiden Fassungen gleich.

## Ein verfügbarer Eintrag wurde ausgelöst.
signal entry_activated(id: StringName)
## Eine Zeile wurde gewählt. [param row_rect] ist die ganze Zeile in globalen Koordinaten.
signal selection_changed(entry: MenuEntry, row_rect: Rect2)

## Höhe jeder Zeile, auch der Kopfzeile.
const ROW_HEIGHT := MenuPaper.ROW_HEIGHT
## Vorgabe für die Breite des Papiers, [member paper_width].
const PAPER_WIDTH := 144
## Links und rechts frei bis zum Innenbereich der Zeilen: Lochrand (8) und Abstand (4).
## Derselbe Wert steht als offset_left und offset_right von Rows in main_menu.tscn.
const ROW_INSET := MenuPaper.ROW_INSET
## Die Schriftfarben, die die gewählte Zeile auf der Anzeige per Override in lcd bekommt: alle außer
## font_disabled_color, denn eine gewählte, nicht verfügbare Zeile bleibt gedämpft (R3, R15).
const LIT_FONT_COLORS: Array[StringName] = [&"font_color", &"font_focus_color",
	&"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color"]

## Worauf das Menü steht: PAPER ist Endlospapier wie in Feature 004, LCD die Anzeige des
## Communicators.
enum Look { PAPER, LCD }

## Text der Kopfzeile, bisher fest „HAUPTMENÜ“ in der Szene.
@export var header_text: String = "HAUPTMENÜ":
	set(value):
		header_text = value
		if is_node_ready():
			_header.text = value
## Breite des Papiers. PAPER_WIDTH bleibt als Vorgabe stehen; test_main_menu.gd nutzt es weiter.
@export var paper_width: int = PAPER_WIDTH:
	set(value):
		paper_width = value
		if is_node_ready():
			_update_size()
## Worauf das Menü steht, siehe [enum Look]. Es gilt beim Bau der Zeilen; wer es danach ändert,
## lässt die Zeilen neu bauen, und die Auswahl bleibt auf ihrer Zeile (Analyse, C23).
@export var look: Look = Look.PAPER:
	set(value):
		look = value
		if is_node_ready():
			var index := _selected_index
			_apply_look()
			_build_rows()
			select(index)
## Die Einträge von oben nach unten. Aus ihnen baut `_ready()` die Zeilen; zur Laufzeit
## wechselt sie set_entries().
@export var entries: Array[MenuEntry] = []

var _buttons: Array[Button] = []
var _selected_index := 0
## Die Zeile, die `_ready()` wählt; set_entries() vor dem Erscheinen setzt sie.
var _start_index := 0

@onready var _rows: VBoxContainer = $Rows
@onready var _header: Label = $Rows/Header


func _ready() -> void:
	_header.text = header_text
	_apply_look()
	_build_rows()
	# Zeitversetzt, wie bisher: Erst wenn alle Knoten im Baum bereit sind, wählt das Menü
	# seine Startzeile und meldet sie. So hört der Titelbildschirm die erste Meldung schon.
	select.call_deferred(_start_index)


func _draw() -> void:
	if _draws_paper():
		MenuPaper.draw_paper(self, size.x, _row_count())
	var entry := selected_entry()
	if entry == null:
		return
	# Die gewählte Zeile: auf Papier signalgelb im Innenbereich, davor der Pfeil; auf der Anzeige
	# ein Balken in tusche, der Pfeil darin lcd.
	if look == Look.LCD:
		MenuPaper.draw_lcd_selection(self, size.x, _selected_index + 1, entry.available)
	else:
		MenuPaper.draw_selection(self, size.x, _selected_index + 1, entry.available)


## Baut die Zeilen aus [param new_entries] neu und wählt Zeile [param index]. Für Einträge, deren
## Verfügbarkeit oder Hinweis sich ändert, etwa „Weiterspielen“.
func set_entries(new_entries: Array[MenuEntry], index: int = 0) -> void:
	entries = new_entries
	_start_index = index
	# Vor dem Erscheinen gibt es Rows noch nicht; dann baut _ready() die Zeilen.
	if not is_node_ready():
		return
	_build_rows()
	select(index)


## Wählt Zeile [param index], indem ihr Button den Fokus bekommt. Außerhalb der Liste
## geht es am anderen Ende weiter, -1 ist also die letzte Zeile.
##
## Ist das Menü unsichtbar, merkt es sich die Zeile nur und meldet nichts: Ein Blatt, das
## nicht zu sehen ist, darf den Fokus nicht nehmen, sonst gingen Tasten an ein unsichtbares
## Menü. Wer es zeigt, ruft danach select(selected_index()).
func select(index: int) -> void:
	if _buttons.is_empty():
		return
	var row := posmod(index, _buttons.size())
	if not is_visible_in_tree():
		_selected_index = row
		_update_row_colors()
		queue_redraw()
		return
	_buttons[row].grab_focus()


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


## Ersetzt die Buttons durch neue, je Eintrag einer, und passt Größe und Enden an.
func _build_rows() -> void:
	# remove_child() sofort, queue_free() erst am Ende des Bilds: So stehen die alten Buttons
	# schon jetzt nicht mehr im VBoxContainer und zählen nicht mehr mit.
	for button in _buttons:
		_rows.remove_child(button)
		button.queue_free()
	_buttons.clear()
	_selected_index = 0
	for index in entries.size():
		var button := _make_row(index)
		_rows.add_child(button)
		_buttons.append(button)
	_link_ends()
	_update_row_colors()
	_update_size()
	queue_redraw()


## Papier so breit wie [member paper_width] und so hoch wie alle Zeilen. Die Größe setzt das
## Menü selbst und nicht nur als Mindestgröße, denn Mindestgrößen schrumpfen ein Control nicht:
## Hätte ein Blatt erst fünf Einträge und dann vier, bliebe es sonst eine Zeile zu hoch.
##
## Auf der Anzeige setzt das Menü keine Größe: Die gibt ihm der Communicator, so groß wie die
## Anzeige (Analyse, C6). Auch die Mindestgröße fällt weg, damit sie die Anzeige nie überstimmt.
func _update_size() -> void:
	if look == Look.LCD:
		custom_minimum_size = Vector2.ZERO
		return
	custom_minimum_size = Vector2(paper_width, ROW_HEIGHT * _row_count())
	size = custom_minimum_size


## Baut den Button für Eintrag [param index]: durchsichtig und linksbündig. Den Platz
## für den Pfeil hält die Theme-Variante MenuRow links frei.
func _make_row(index: int) -> Button:
	var entry := entries[index]
	var button := Button.new()
	button.text = entry.label
	# Nicht verfügbar heißt gesperrt: Der Button lässt sich wählen, aber nicht drücken.
	# Seine Schrift nimmt dann immer font_disabled_color aus dem Theme, auch mit Fokus;
	# gesperrt geht in Godot vor allen anderen Zuständen.
	button.disabled = not entry.available
	button.theme_type_variation = &"LcdRow" if look == Look.LCD else &"MenuRow"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	# Die Hand verspricht, dass ein Klick etwas tut. Über gesperrten Zeilen bleibt der
	# Pfeil (FR-018).
	button.mouse_default_cursor_shape = CURSOR_POINTING_HAND if entry.available else CURSOR_ARROW
	# Überfahren wählt die Zeile: Die Maus holt sich den Fokus, Maus und Tastatur teilen
	# sich also eine Auswahl (FR-011). Ein Gegenstück für mouse_exited gibt es bewusst
	# nicht, sonst ginge die Auswahl verloren, sobald die Maus das Menü verlässt.
	button.mouse_entered.connect(button.grab_focus)
	button.focus_entered.connect(_on_row_focus_entered.bind(index))
	button.pressed.connect(_on_row_pressed.bind(index))
	button.gui_input.connect(_on_row_gui_input.bind(index))
	return button


## Stellt Kopfzeile und Innenbereich der Zeilen auf [member look]: auf Papier 12 frei für Lochrand
## und Abstand, auf der Anzeige 4 (Style-Guide, Baustein Menü). Der Pfeil steht dann bei x 8, und
## der Innenabstand von LcdRow lässt den Text bei x 16 beginnen.
func _apply_look() -> void:
	var inset := MenuPaper.LCD_ROW_INSET if look == Look.LCD else ROW_INSET
	_rows.offset_left = inset
	_rows.offset_right = -inset
	_header.theme_type_variation = &"LcdHeader" if look == Look.LCD else &"MenuHeader"


## Ob _draw() Papier malt: nur auf Papier. Auf der Anzeige ist der Grund die Anzeige selbst.
## Headless entsteht kein Bild; Tests fragen deshalb hier.
func _draws_paper() -> bool:
	return look == Look.PAPER


## Auf der Anzeige bekommt die gewählte Zeile ihre Schrift lcd per Override, jede andere verliert
## ihn. Das Theme kann das nicht: Es kennt Fokus und Hover, aber nicht „gewählt“. Unter der Maus
## nimmt ein Button font_hover_color, auch ohne Fokus; wäre die lcd, stünde eine nicht gewählte
## Zeile unter der Maus hell auf hellem Grund, wäre sie tusche, die gewählte schwarz auf dem Balken
## (R15; Analyse, B1). Auf Papier gibt es keinen Override, alles kommt aus MenuRow.
func _update_row_colors() -> void:
	for index in _buttons.size():
		var lit := look == Look.LCD and index == _selected_index
		for color_name in LIT_FONT_COLORS:
			if lit:
				_buttons[index].add_theme_color_override(color_name, UiPalette.LCD)
			else:
				_buttons[index].remove_theme_color_override(color_name)


## Verbindet die erste und die letzte Zeile, damit die Auswahl an beiden Enden umläuft:
## Pfeil hoch und Shift+Tab springen von oben nach unten, Pfeil runter und Tab von unten
## nach oben (FR-010). Dazwischen findet Godot den Nachbarn selbst, denn die Zeilen
## stehen untereinander und im Baum hintereinander. Weil die Enden aufeinander zeigen,
## verlässt Tab das Menü nie, auch wenn später andere Bedienelemente daneben stehen.
func _link_ends() -> void:
	if _buttons.is_empty():
		return
	var first := _buttons[0]
	var last := _buttons[-1]
	first.focus_neighbor_top = first.get_path_to(last)
	first.focus_previous = first.get_path_to(last)
	last.focus_neighbor_bottom = last.get_path_to(first)
	last.focus_next = last.get_path_to(first)


## Die ganze Zeile [param index] in globalen Koordinaten, von Papierrand zu Papierrand.
## Der Button deckt nur den Innenbereich ab; der Hinweis richtet sich aber nach der Zeile.
## Gerechnet wird aus der Lage des Menüs, nicht aus dem Button: Nach set_entries() hat der
## VBoxContainer die neuen Buttons erst im nächsten Bild angeordnet, die Zeile stimmt aber
## schon jetzt.
func _row_rect(index: int) -> Rect2:
	var local := Rect2(0, ROW_HEIGHT * (index + 1), size.x, ROW_HEIGHT)
	return get_global_transform() * local


func _on_row_focus_entered(index: int) -> void:
	_selected_index = index
	_update_row_colors()
	queue_redraw()
	selection_changed.emit(entries[index], _row_rect(index))


## Ein gesperrter Button sendet pressed gar nicht erst, hier kommen nur verfügbare an.
func _on_row_pressed(index: int) -> void:
	entry_activated.emit(entries[index].id)


## Ein Rechtsklick wählt die Zeile und zeigt so ihren Hinweis, löst aber nichts aus
## (FR-009). Der Button selbst reagiert nur auf die linke Taste. Das Signal gui_input
## kommt, bevor der Button das Ereignis verarbeitet; accept_event() markiert es als
## behandelt, und dann sieht der Button es gar nicht mehr.
func _on_row_gui_input(event: InputEvent, index: int) -> void:
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_RIGHT:
		return
	if click.pressed:
		select(index)
	_buttons[index].accept_event()
