extends Node

## Autoload GameWindow: Fenster, Vollbild und Mindestgröße des Spielfensters.
##
## Das Spiel startet im Fenster. Gleich nach dem Start bekommt es den größten ganzzahligen
## Faktor, der samt Titelleiste auf seinen Bildschirm passt, und steht dort in der Mitte.
## Die Eingabe-Aktion `toggle_fullscreen` (Ctrl+Cmd+F) schaltet ins Vollbild und zurück, der
## grüne Fensterknopf von macOS tut das ohne eigenen Code; zurück im Fenster bekommt das
## Spiel wieder diese Größe. Kleiner als das Oberflächenraster bei Faktor 1 lässt es sich
## nicht ziehen (FR-004, FR-013).
##
## Läuft Godot headless (Tests, Startprobe), gibt es kein Fenster, und der Autoload tut
## nichts.

## Das Oberflächenraster in Bildschirmpixeln bei Faktor 1, zugleich die kleinste
## Fenstergröße.
const BASE_SIZE := Vector2i(640, 360)
## Länger als der Übergang aus dem Vollbild unter macOS, mit Reserve. Eine Fenstergröße,
## die vor seinem Ende kommt, kann macOS am Ende überschreiben. Ob die Zeit reicht, zeigt
## die Prüfung der gebauten App (T031).
const TRANSITION_MSEC := 1000

## Ob das Fenster im vorigen Bild im Vollbild war.
var _was_fullscreen := false
## Wann toggle_fullscreen() zuletzt umgeschaltet hat, in Millisekunden seit dem Start.
## Der Startwert liegt so weit zurück, dass er nie eine Wartezeit auslöst.
var _toggled_msec := -TRANSITION_MSEC
## Ab wann das Fenster seine Größe bekommt, in Millisekunden seit dem Start; -1 heißt:
## nichts geplant.
var _fit_msec := -1


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		set_process_unhandled_input(false)
		return
	# Godot rechnet Fenstergrößen in Bildschirmpixeln. Auf einem Retina-Bildschirm sind
	# 640 × 360 Pixel also 320 × 180 Punkte, wie FR-013 es verlangt.
	get_window().min_size = BASE_SIZE
	_was_fullscreen = is_fullscreen()
	# Das Spiel startet im Fenster (FR-004), anfangs in der Größe des Rasters. Seine Größe
	# bekommt es im ersten Bild in _process(), auf demselben Weg wie nach dem Vollbild.
	# Nicht per call_deferred(): Die Werkstatt hält GameWindow in ihrem _ready() an und
	# maximiert ihr Fenster selbst. Ein aufgeschobener Aufruf liefe erst danach und schrumpfte
	# ihr maximiertes Fenster auf die Spielgröße.
	# Eingebettet im Editor bestimmt der Editor die Größe. GameWindow setzt dort keine, wie
	# schon, als das Projekt noch im Vollbild startete.
	if not _was_fullscreen and not Engine.is_embedded_in_editor():
		_fit_msec = Time.get_ticks_msec()


## Ein Signal für den Wechsel des Fenstermodus gibt es nicht: size_changed meldet bei
## Stretch viewport nur den Viewport, und der bleibt 640 × 360. Deshalb vergleicht jedes
## Bild den Modus mit dem des vorigen.
func _process(_delta: float) -> void:
	var fullscreen := is_fullscreen()
	if _was_fullscreen and not fullscreen:
		# Beim grünen Knopf meldet Godot das Fenster erst, wenn macOS mit dem Übergang
		# fertig ist. Nach dem Kürzel meldet es das sofort, und der Übergang läuft noch.
		_fit_msec = maxi(Time.get_ticks_msec(), _toggled_msec + TRANSITION_MSEC)
	_was_fullscreen = fullscreen
	if _fit_msec >= 0 and Time.get_ticks_msec() >= _fit_msec:
		_fit_msec = -1
		# Wer inzwischen wieder ins Vollbild gewechselt hat, bekommt keine Fenstergröße.
		if get_window().mode == Window.MODE_WINDOWED:
			_fit_to_screen()


## Hier kommt nur an, was die Oberfläche nicht verbraucht hat. Enter, Leertaste, Tab und
## die Pfeiltasten bleiben beim Menü, Ctrl+Cmd+F kommt hier an.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


## Wechselt vom Vollbild ins Fenster und umgekehrt.
func toggle_fullscreen() -> void:
	_toggled_msec = Time.get_ticks_msec()
	get_window().mode = Window.MODE_WINDOWED if is_fullscreen() else Window.MODE_FULLSCREEN


## Auch das exklusive Vollbild zählt als Vollbild (research.md, R2).
func is_fullscreen() -> bool:
	var mode := get_window().mode
	return mode == Window.MODE_FULLSCREEN or mode == Window.MODE_EXCLUSIVE_FULLSCREEN


## Der größte ganzzahlige Faktor, mit dem das Raster samt Fensterrahmen in [param usable]
## passt, mindestens 1. [param decorations] ist der Rahmen, unter macOS die Titelleiste.
## Beide Werte sind Bildschirmpixel.
static func best_factor(usable: Vector2i, decorations: Vector2i) -> int:
	# Vector2i durch Vector2i teilt jede Achse für sich und ganzzahlig, der Rest fällt weg.
	# Genau das ist gewollt, deshalb ist Godots Warnung vor dem Abschneiden hier aus.
	# Der kleinere Faktor der beiden Achsen ist der, der passt.
	@warning_ignore("integer_division")
	var factors := (usable - decorations) / BASE_SIZE
	return maxi(mini(factors.x, factors.y), 1)


## Setzt das Fenster auf den größten Faktor, der samt Titelleiste auf den Bildschirm passt,
## auf dem es gerade liegt, und stellt es dort in die Mitte.
func _fit_to_screen() -> void:
	var window := get_window()
	var id := window.get_window_id()
	var screen := DisplayServer.window_get_current_screen(id)
	var usable := DisplayServer.screen_get_usable_rect(screen).size
	# Im Vollbild hat das Fenster keine Titelleiste. Gemessen wird deshalb erst nach dem
	# Übergang, wenn sie wieder da ist.
	var decorations := DisplayServer.window_get_size_with_decorations(id) - window.size
	window.size = BASE_SIZE * best_factor(usable, decorations)
	window.move_to_center()
