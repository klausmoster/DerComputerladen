class_name CaseKey
extends Control

## Eine Gehäusetaste: eine unsichtbare Klickfläche über einer Taste im Gehäusebild
## (contracts/gehaeusetasten.md, „CaseKey“; research.md, R4). Sie malt nichts; das Eindrücken malt
## der Communicator in seinem Knoten `Keys`, weil nur er Gehäusebild und Lage der Taste kennt.
##
## Gedrückt wird mit der linken Maustaste. Gezählt wird beim Loslassen über derselben Taste, wie bei
## jedem Button: Wer die Maus mit gedrückter Taste wegzieht, nimmt den Druck zurück (Spec, FR-001,
## Randfälle). Godot schickt das Loslassen an das Control, auf dem gedrückt wurde, auch wenn die
## Maus inzwischen woanders steht; [method _gui_input] prüft deshalb, ob sie noch auf der Taste ist.
## Rechte und mittlere Maustaste tun nichts.
##
## Verliert das Fenster den Fokus, springt eine gedrückte Taste zurück, ohne zu zählen, wie beim
## Hinausfahren (Klaus, nach der Phasenprüfung von Phase 5). Godot schickt dabei selbst ein
## Loslassen an die Taste; das erkennt [method _gui_input] an seinem Gerät und zählt es nicht.
##
## Keine Tastatur und kein Fokus (focus_mode NONE), der Zeiger bleibt der Pfeil (FR-001b): Die
## Tasten sind ein Geheimnis im Gehäuse, nichts verrät sie beim Überfahren (Style-Guide, Baustein
## Communicator, Gehäusetasten).

## Linke Maustaste über dieser Taste losgelassen, nachdem sie hier gedrückt wurde.
signal pressed
## Die Taste geht runter oder wieder hoch; der Communicator malt danach neu.
signal down_changed(is_down: bool)

## Das Gerät des Loslassens, das Godot selbst schickt, wenn das Fenster den Fokus verliert
## (InputEvent::DEVICE_ID_INTERNAL in Godots Quelltext; GDScript kennt die Konstante nicht).
const DEVICE_ID_INTERNAL := -2

## Ob die linke Maustaste auf dieser Taste unten ist. Nur lesen; es ändern Maus und cancel().
var is_down: bool = false


func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_ARROW
	focus_mode = FOCUS_NONE


## Fokus des Fensters weg: Die Taste springt zurück. Ein Loslassen danach findet sie oben und
## meldet nichts.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	# Nur die linke Maustaste; alles andere bleibt unverbraucht.
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if button.pressed:
		_set_down(true)
		return
	if not is_down:
		return
	# Godots eigenes Loslassen beim Verlust des Fensterfokus kann vor der Benachrichtigung oben
	# kommen. Es zählt nie, auch wenn die Maus noch über der Taste steht.
	if button.device == DEVICE_ID_INTERNAL:
		cancel()
		return
	# button.position ist lokal zur Taste, auch wenn die Maus sie längst verlassen hat.
	var over_key := Rect2(Vector2.ZERO, size).has_point(button.position)
	_set_down(false)
	if over_key:
		pressed.emit()


## Lässt die Taste ohne pressed hochgehen, falls sie unten ist.
func cancel() -> void:
	if is_down:
		_set_down(false)


## Setzt [member is_down] und meldet es mit down_changed.
func _set_down(down: bool) -> void:
	is_down = down
	down_changed.emit(down)
