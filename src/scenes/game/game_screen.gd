class_name GameScreen
extends Control

## Der noch leere Spielbildschirm (FR-019, FR-020): ein Knopf „Zum Hauptmenü“ mit Hinweis.
## Esc löst nichts aus.
##
## Bis Bildrahmen und Bedienleiste kommen, ist er ein Vollbild in nacht mit dem Knopf in der Mitte
## (Style-Guide, „Bildaufbau“, Spielbildschirm als Platzhalter). Der Knopf steht allein auf dem
## Bildschirm; deshalb hat er von Anfang an den Fokus, und statt eines Tooltips steht sein Hinweis
## links daneben wie im Menü, 4 Pixel vor der Fokuslinie (Style-Guide, Baustein Knopf und Baustein
## Hinweis). Scheitert das Speichern, steht an der Stelle des Hinweises die Meldung (Baustein
## Meldung).
##
## Esc tut nichts, damit niemand versehentlich das Spiel verlässt: Der Bildschirm hört ui_cancel
## gar nicht erst ab.

## Der Titelbildschirm, zu dem der Knopf nach dem Speichern führt.
const TITLE_SCENE := "res://scenes/title/title_screen.tscn"

## GameSession hat als Autoload keinen class_name; den Typ gibt sein Skript.
const SESSION_SCRIPT := preload("res://core/game_session.gd")

## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
## Wechselt die Szene; ungültig heißt get_tree().change_scene_to_file(). Tests setzen eine eigene
## Funktion und prüfen den Aufruf statt des echten Wechsels (wie GameSession.quit_callback; Analyse,
## C1).
var scene_callback: Callable

@onready var _background: ColorRect = $Background
@onready var _leave_button: Knopf = $LeaveButton
@onready var _menu_hint: MenuHint = $MenuHint


func _ready() -> void:
	# Die Farbe kommt aus der Palette und nicht als Zahl aus der Szene; so gibt es sie nur einmal.
	_background.color = UiPalette.NACHT
	_leave_button.text = TitleTexts.LABEL_LEAVE
	# Die Session meldet jedes gescheiterte Speichern, solange dieser Bildschirm steht. Verbunden
	# im Code und nicht in der Szene, denn welche Session es ist, steht erst zur Laufzeit fest.
	# Wird der Bildschirm freigegeben, löst Godot die Verbindung selbst.
	_session().save_failed.connect(_on_session_save_failed)
	_leave_button.grab_focus()
	# Scheiterte schon das Speichern beim Fortsetzen, kam save_failed vor diesem Bildschirm; dann
	# steht der Satz noch in last_error (Analyse, F5).
	var error_text := _session().last_error
	if not error_text.is_empty():
		_menu_hint.show_warning(error_text, _button_rect())
	else:
		_show_hint()


## Speichert und führt ins Hauptmenü (FR-020). Verbunden in game_screen.tscn. Scheitert das
## Speichern, steht die Meldung neben dem Knopf, und das Spiel läuft weiter (FR-011).
func _on_leave_button_pressed() -> void:
	# Etwas auslösen beendet eine Meldung (Style-Guide, Baustein Meldung).
	_menu_hint.hide_hint()
	var game_session := _session()
	# Ohne laufendes Spiel, etwa wenn die Szene im Editor allein startet, gibt es nichts zu
	# speichern; der Knopf führt dann gleich ins Hauptmenü.
	if not game_session.is_running() or game_session.leave() == OK:
		_change_scene(TITLE_SCENE)
		return
	_menu_hint.show_warning(game_session.last_error, _button_rect())


func _on_session_save_failed(message: String) -> void:
	_menu_hint.show_warning(message, _button_rect())


## Der Hinweis neben dem Knopf nennt das laufende Spiel, „Speichert Spiel 2 und führt ins
## Hauptmenü.“ (R15). Ohne laufendes Spiel gibt es keinen.
func _show_hint() -> void:
	var game := _session().current
	if game == null:
		_menu_hint.hide_hint()
		return
	_menu_hint.show_text(TitleTexts.leave_hint(game.name), _button_rect())


## Die Stelle, neben die der Hinweis kommt, in globalen Koordinaten: der Knopf, links um seine
## Fokuslinie verbreitert. Der Knopf hat den Fokus von Anfang an; deshalb zählen die 4 Pixel bis
## zum Hinweis ab der Fokuslinie und nicht ab der Kontur (Style-Guide, Baustein Hinweis). Oben
## bleibt der Hinweis bündig mit dem Knopf. Luft und Linie kommen aus Knopf, damit beide nicht
## auseinanderlaufen, wenn sich die Fokuslinie ändert.
func _button_rect() -> Rect2:
	var focus_outset := Knopf.FOCUS_GAP + Knopf.FOCUS_WIDTH
	return _leave_button.get_global_rect().grow_side(SIDE_LEFT, focus_outset)


## Wechselt zur Szene [param path]: über scene_callback, ohne ihn mit change_scene_to_file().
func _change_scene(path: String) -> void:
	if scene_callback.is_valid():
		scene_callback.call(path)
	else:
		get_tree().change_scene_to_file(path)


## Die Session: session oder das Autoload GameSession.
func _session() -> SESSION_SCRIPT:
	return (session if session != null else GameSession) as SESSION_SCRIPT
