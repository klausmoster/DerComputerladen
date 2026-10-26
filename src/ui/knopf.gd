class_name Knopf
extends Button

## Der Baustein Knopf aus dem Style-Guide: gehaeuse, Kontur tusche, Relief erhaben, gedrückt
## vertieft, beim Überfahren signalgelb, Schrift menue. Steht er allein auf einem Bildschirm, zeigt
## der Bildschirm seinen Hinweis wie im Menü statt eines Tooltips (Style-Guide, CHK017). Das Relief
## und die Fokuslinie malt _draw(), denn eine StyleBoxFlat kennt kein Relief in zwei Farben. Auf
## dunklem Grund ist die Fokuslinie papier (Style-Guide, R17).
##
## Fläche, Kontur, Schrift und Innenabstand kommen aus der Theme-Variante `Knopf`: je Zustand eine
## StyleBoxFlat mit einem Pixel tusche als Rand, gehaeuse oder beim Überfahren signalgelb als
## Fläche. Gedrückt liegt der Innenabstand oben einen Pixel höher und unten einen niedriger; so
## rückt der Text einen Pixel tiefer. `_draw()` kommt nach Fläche und Text und malt nur noch, was
## eine StyleBoxFlat nicht kann: die Lichtkante oben links, die Schattenkante unten rechts und die
## Fokuslinie außen.

## Abstand zwischen Knopf und Fokuslinie: ein Oberflächenpixel Luft, dann die Linie, einen Pixel
## breit (Style-Guide, Oberfläche und Baustein Knopf).
const FOCUS_GAP := 1
## Breite der Fokuslinie.
const FOCUS_WIDTH := 1

## Ob der Knopf auf dunklem Grund steht; dann ist die Fokuslinie papier statt tusche.
@export var on_dark: bool = false:
	set(value):
		on_dark = value
		queue_redraw()


func _init() -> void:
	theme_type_variation = &"Knopf"
	mouse_default_cursor_shape = CURSOR_POINTING_HAND


func _notification(what: int) -> void:
	# Die Fokuslinie hängt am Fokus; ohne neues Malen bliebe sie stehen oder käme nicht.
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
		queue_redraw()


func _draw() -> void:
	_update_cursor()
	for layer in layers():
		draw_rect(layer["rect"], layer["color"])


## Die Hand nur, wenn ein Klick etwas tut; ein ausgeschalteter Knopf zeigt den Pfeil, denn er
## reagiert beim Überfahren nicht (Style-Guide, Baustein Knopf, „Aus“). Ein Signal für `disabled`
## gibt es nicht, und die Eigenschaft gehört Godots Button, ein Skript kann ihren Setter nicht
## ersetzen. Godot malt den Knopf aber neu, sobald sie sich ändert; deshalb ruft `_draw()` das hier.
func _update_cursor() -> void:
	mouse_default_cursor_shape = CURSOR_ARROW if disabled else CURSOR_POINTING_HAND


## Die Rechtecke, die `_draw()` über Fläche und Text malt, von unten nach oben, je als
## { "rect": Rect2, "color": Color }: das Relief und, wenn der Fokus zu sehen ist, die Fokuslinie.
## Headless entsteht kein Bild; Tests prüfen den Knopf über diese Liste.
func layers() -> Array[Dictionary]:
	var rect := Rect2(Vector2.ZERO, size)
	var mode := get_draw_mode()
	var pressed := mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
	var result := _relief_layers(rect, pressed)
	# has_focus(true) ist falsch, wenn der Fokus versteckt ist, etwa nach einem Mausklick. So
	# zeigt der Knopf die Linie nur, wenn die Tastatur ihn erreicht oder das Spiel ihm den Fokus
	# gibt, wie :focus-visible im Style-Guide.
	if has_focus(true):
		result.append_array(_focus_layers(rect, on_dark))
	return result


## Relief innerhalb der Kontur von [param rect]: relief-erhaben hat Licht oben und links
## (gehaeuse-hell) und Schatten unten und rechts (gehaeuse-dunkel), relief-gedrueckt umgekehrt.
## Das Licht kommt zuletzt und liegt oben; die Ecken oben rechts und unten links gehören also zur
## oberen und linken Kante, wie bei den zwei inset-Schatten im Token.
static func _relief_layers(rect: Rect2, pressed: bool) -> Array[Dictionary]:
	var inner := rect.grow(-1)
	if inner.size.x < 1 or inner.size.y < 1:
		return []
	var top_left := UiPalette.GEHAEUSE_DUNKEL if pressed else UiPalette.GEHAEUSE_HELL
	var bottom_right := UiPalette.GEHAEUSE_HELL if pressed else UiPalette.GEHAEUSE_DUNKEL
	return [
		{"rect": Rect2(inner.position.x, inner.end.y - 1, inner.size.x, 1), "color": bottom_right},
		{"rect": Rect2(inner.end.x - 1, inner.position.y, 1, inner.size.y), "color": bottom_right},
		{"rect": Rect2(inner.position.x, inner.position.y, inner.size.x, 1), "color": top_left},
		{"rect": Rect2(inner.position.x, inner.position.y, 1, inner.size.y), "color": top_left},
	]


## Die Fokuslinie um [param rect]: FOCUS_GAP Pixel Luft, dann FOCUS_WIDTH Pixel Linie, auf hellem
## Grund tusche, auf dunklem papier. Sie liegt außerhalb des Knopfs; ein Control darf über seinen
## Rand hinaus malen.
static func _focus_layers(rect: Rect2, dark_ground: bool) -> Array[Dictionary]:
	var line := rect.grow(FOCUS_GAP + FOCUS_WIDTH)
	var color := UiPalette.PAPIER if dark_ground else UiPalette.TUSCHE
	return [
		{"rect": Rect2(line.position.x, line.position.y, line.size.x, FOCUS_WIDTH),
			"color": color},
		{"rect": Rect2(line.position.x, line.end.y - FOCUS_WIDTH, line.size.x, FOCUS_WIDTH),
			"color": color},
		{"rect": Rect2(line.position.x, line.position.y, FOCUS_WIDTH, line.size.y),
			"color": color},
		{"rect": Rect2(line.end.x - FOCUS_WIDTH, line.position.y, FOCUS_WIDTH, line.size.y),
			"color": color},
	]
