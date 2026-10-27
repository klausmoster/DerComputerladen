class_name Communicator
extends Control

## Der Baustein Communicator aus dem Style-Guide: ein Taschengerät, das von unten ins Bild fährt
## und auf seiner Anzeige eine Seite zeigt, etwa ein Menü. Gebaut für jeden Bildschirm, der ihn
## braucht; den Titel kennt er nicht (Feature 005, FR-007).
##
## Aufbau (communicator.tscn): `Case` ist das Gehäuse, `Display` die Anzeige darauf, `Hint` der
## Hinweis links neben dem Gehäuse. Danach kommen die Seiten. Ein Bildschirm hängt sie in seiner
## Szene direkt unter die Instanz des Communicators; `_ready()` stellt jede auf die Anzeige und
## verbirgt sie, `show_page()` zeigt genau eine. Weil sie nach den eigenen Kindern stehen, liegen
## sie über der Anzeige, und die Pfade des Bildschirms wie `$Communicator/MainMenu` bleiben gültig.
##
## Was eine Seite meldet, hört der Bildschirm selbst. Der Communicator kennt die Signale seiner
## Seiten nicht; er stellt sie nur hin, zeigt sie und fährt.
##
## Das Gehäuse ist reine Grafik: Communicator, Gehäuse, Anzeige und Hinweis lassen die Maus durch
## (`mouse_filter` IGNORE in der Szene), bedienbar sind nur die Seiten. Bis das Bild G-02 da ist,
## malt `_draw()` an seiner Stelle einen Platzhalter (research.md, R11).
##
## Eingabe: Ab `slide_out()` nimmt keine Seite Fokus, Maus oder Tastatur an, bis `slide_in()` oder
## `place_hidden()` kommt. Das regeln zwei Eigenschaften von Control für den ganzen Teilbaum,
## `focus_behavior_recursive` und `mouse_behavior_recursive` (R8; Analyse, B2). Den Hinweis zur
## gewählten Zeile stellt `show_hint()` links neben das Gehäuse; als Kind fährt er mit (R7).
##
## Die Fahrt: Ein Tween schreibt in [member slide_y], das auf ganze Oberflächenpixel rundet. Der
## Tween ist angehalten; `_process()` taktet ihn mit `custom_step()` und gedeckeltem Zeitschritt.
## So springt das Gerät in einem langen ersten Bild nicht gleich halb herein, und ein Test kann die
## Fahrt Bild für Bild nachrechnen, ohne zu warten (research.md, R6).

## Die Fahrt herein oder hinaus ist zu Ende. [param arrived_in] true heißt Endlage, false draußen.
signal slide_finished(arrived_in: bool)

## Dauer einer Fahrt (Style-Guide, Baustein Communicator, Fahrt: 200 ms).
const SLIDE_SECONDS := 0.2
## Größter Zeitschritt je Bild ab dem zweiten Bild einer Fahrt (research.md, R6).
const MAX_STEP := 1.0 / 30.0
## Größter Zeitschritt im ersten Bild jeder Fahrt. Mit EASE_OUT legt das Gerät damit im ersten Bild
## höchstens 23 % des Wegs zurück, mit MAX_STEP wären es 42 % (research.md, R6).
const MAX_FIRST_STEP := 1.0 / 60.0
## Größe der Anzeige, für jedes Gehäuse gleich, damit jede Seite in jedes Gehäuse passt
## (Style-Guide, Baustein Communicator).
const DISPLAY_SIZE := Vector2i(384, 192)
## „Draußen“: Die Oberkante des Communicators liegt an der Unterkante des Bilds, 640 × 360
## (Style-Guide, Baustein Communicator).
const HIDDEN_Y := 360.0

## Lage und Größe der Anzeige im Gehäuse. Sie gehören zum Gehäuse; ein späteres Gehäuse setzt eigene
## (FR-001a). Vorgabe ist der Organizer: bei (24, 24), DISPLAY_SIZE groß (Style-Guide, Baustein
## Communicator).
@export var display_rect: Rect2i = Rect2i(Vector2i(24, 24), DISPLAY_SIZE):
	set(value):
		display_rect = value
		if is_node_ready():
			_apply_display()
## Farbe der Anzeige, auch sie gehört zum Gehäuse; Vorgabe lcd wie beim Organizer.
@export var display_color: Color = UiPalette.LCD:
	set(value):
		display_color = value
		if is_node_ready():
			_display.color = value

## false: Fahrten springen sofort ans Ziel und melden sich gleich (Tests, später „Bewegung
## reduzieren“).
var animate: bool = true

## Die Lage in y, beim Setzen auf ganze Oberflächenpixel gerundet. Der Tween schreibt hierhin und
## nicht direkt in position.y; so steht der Communicator nie zwischen zwei Pixeln.
var slide_y: float:
	get:
		return position.y
	set(value):
		position.y = roundf(value)

## Die Endlage in y: die Lage, die der Bildschirm dem Communicator in seiner Szene gibt.
var _home_y := 0.0
## Wohin der Communicator gerade fährt oder wo er steht.
var _target_y := 0.0
var _tween: Tween = null
## Ob das nächste Bild das erste der laufenden Fahrt ist; dann gilt MAX_FIRST_STEP.
var _first_step := false
## Ob die Eingabe gesperrt ist: ab slide_out() bis slide_in() oder place_hidden().
var _locked := false

@onready var _case: TextureRect = $Case
@onready var _display: ColorRect = $Display
## Der Hinweis zur gewählten Zeile. Als Kind fährt er mit, ohne eigenen Code (research.md, R7).
@onready var _hint: MenuHint = $Hint


func _ready() -> void:
	_home_y = position.y
	_target_y = _home_y
	if not _on_image_grid(position):
		push_warning(("Communicator „%s“: Die Endlage %s liegt nicht auf ganzen Bildpixeln, "
			+ "x und y müssen gerade sein (Style-Guide, Baustein Communicator).")
			% [name, position])
	_display.color = display_color
	_apply_display()
	# Die Seiten aus der Szene des Bildschirms sind jetzt schon Kinder: Godot ruft _ready() erst,
	# wenn alle Kinder bereit sind.
	for page in _page_list():
		add_page(page)


func _draw() -> void:
	# Ohne Bild im Gehäuse der Platzhalter; mit G-02 entfällt er von selbst.
	if _case.texture != null:
		return
	for layer in _placeholder_layers(_case.get_rect()):
		draw_rect(layer["rect"], layer["color"])


func _process(delta: float) -> void:
	if _tween == null:
		return
	if not _tween.is_valid():
		_tween = null
		return
	var step := minf(delta, MAX_FIRST_STEP if _first_step else MAX_STEP)
	_first_step = false
	# Das Ende meldet _on_slide_tween_finished(), noch während dieses Aufrufs. Der Rückgabewert von
	# custom_step() taugt dafür nicht: Er wird erst ein Bild nach dem Ende false.
	_tween.custom_step(step)


# --- Seiten ---------------------------------------------------------------

## Stellt [param page] auf die Anzeige: Kind des Communicators, auf display_rect gestellt,
## unsichtbar. Eine Seite, die noch kein Kind ist, kommt als letztes Kind dazu.
func add_page(page: Control) -> void:
	# Erst verbergen, dann einhängen: Eine Seite, die beim Einhängen sichtbar wäre, könnte in ihrem
	# _ready() den Fokus nehmen.
	page.hide()
	if page.get_parent() == null:
		add_child(page)
	elif page.get_parent() != self:
		page.reparent(self, false)
	_place_page(page)


## Zeigt [param page] und verbirgt jede andere Seite. Erst verbergen, dann zeigen: Eine Seite, die
## verschwindet, gibt ihren Fokus ab, und die neue kann ihn danach nehmen. Der Communicator bewegt
## sich dabei nicht (FR-005). Eine Seite, die er noch nicht kennt, stellt er vorher auf die Anzeige;
## jede andere stellt er noch einmal auf display_rect, falls sie ihre Größe inzwischen geändert hat.
func show_page(page: Control) -> void:
	if page.get_parent() != self:
		add_page(page)
	_place_page(page)
	for other in _page_list():
		if other != page:
			other.hide()
	page.show()


## Die Seite, die gerade zu sehen ist, oder null.
func current_page() -> Control:
	for page in _page_list():
		if page.visible:
			return page
	return null


# --- Fahrt ----------------------------------------------------------------

## Stellt den Communicator ohne Fahrt unter das Bild. Das ist keine Fahrt, deshalb kommt kein
## slide_finished. Gesperrt wird nichts: Der Bildschirm setzt danach Einträge und wählt, bevor die
## Fahrt herein beginnt (Analyse, C5).
func place_hidden() -> void:
	_set_locked(false)
	_stop()
	_target_y = HIDDEN_Y
	slide_y = HIDDEN_Y


## Fährt in die Endlage, aus jeder Lage, auch mitten aus der Fahrt hinaus. EASE_OUT: schnell los,
## sanft an. Die Seiten nehmen sofort wieder Eingaben an (FR-003); welche Zeile gewählt ist, setzt
## danach der Bildschirm.
##
## Eine Sperre der Maus braucht die Fahrt herein nicht: Godot meldet mouse_entered nur, wenn sich
## die Maus bewegt, nicht wenn eine Zeile unter den ruhenden Zeiger fährt. Eine Zeile, die unter
## dem Zeiger durchfährt, wird also nicht gewählt (CHK007; test_communicator.gd prüft das).
func slide_in() -> void:
	_set_locked(false)
	_slide_to(_home_y, Tween.EASE_OUT)


## Fährt unter das Bild. EASE_IN: sanft los, schnell weg. Die Eingabe ist sofort gesperrt, schon vor
## dem ersten Bild der Fahrt (R8).
func slide_out() -> void:
	_set_locked(true)
	_slide_to(HIDDEN_Y, Tween.EASE_IN)


## Ob der Communicator in der Endlage steht oder dorthin fährt.
func is_in() -> bool:
	return _target_y == _home_y


## Ob der Communicator gerade Eingaben annimmt: in der Endlage, auf der Fahrt herein und nach
## place_hidden(); ab slide_out() nicht mehr, bis slide_in() oder place_hidden() kommt.
func accepts_input() -> bool:
	return not _locked


# --- Hinweis --------------------------------------------------------------

## Zeigt [param text] als Hinweis zu der Zeile [param row_rect] (global): links neben dem Gehäuse,
## die rechte Kante MenuHint.GAP vor dessen linker Kante, oben bündig mit der Zeile (R7).
func show_hint(text: String, row_rect: Rect2) -> void:
	_hint.show_text(text, _beside_case(row_rect))


## Wie show_hint(), als Meldung (Baustein Meldung). Sie bleibt, bis ein Hinweis zu einer anderen
## Zeile kommt, wie MenuHint es regelt.
func show_warning(text: String, row_rect: Rect2) -> void:
	_hint.show_warning(text, _beside_case(row_rect))


## Blendet Hinweis und Meldung aus.
func hide_hint() -> void:
	_hint.hide_hint()


# --- Intern ---------------------------------------------------------------

## Beginnt eine Fahrt nach [param target_y]. Eine laufende Fahrt zum selben Ziel läuft weiter und
## meldet sich am Ende; eine Fahrt zum anderen Ziel endet ohne Meldung, und die neue beginnt in der
## jetzigen Lage, ohne Sprung.
func _slide_to(target_y: float, easing: Tween.EaseType) -> void:
	if target_y == _target_y and _tween != null:
		return
	_stop()
	_target_y = target_y
	# Ohne Animation oder ohne Weg ist die Fahrt sofort zu Ende. Auch dann kommt slide_finished,
	# damit ein Bildschirm, der darauf wartet, nie hängen bleibt.
	if not animate or slide_y == target_y:
		slide_y = target_y
		slide_finished.emit(is_in())
		return
	# TRANS_CUBIC federt nicht über das Ziel hinaus, anders als TRANS_BACK oder TRANS_ELASTIC.
	_tween = create_tween().set_ease(easing).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, ^"slide_y", target_y, SLIDE_SECONDS)
	_tween.finished.connect(_on_slide_tween_finished)
	# Angehalten: Den Takt gibt _process() mit gedeckeltem Zeitschritt vor, nicht die Engine.
	_tween.pause()
	_first_step = true


## Die Fahrt ist am Ziel; die letzte Lage, die der Tween geschrieben hat, ist genau das Ziel. Eine
## Fahrt, die eine Umkehr beendet, kommt nie hierher: kill() sendet kein finished.
func _on_slide_tween_finished() -> void:
	_tween = null
	slide_finished.emit(is_in())


func _stop() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


## Sperrt die Eingabe aller Seiten oder gibt sie frei. Beide Eigenschaften wirken auf den ganzen
## Teilbaum unter dem Communicator, also auch auf die Zeilen, die ein Menü erst zur Laufzeit baut:
## - focus_behavior_recursive DISABLED nimmt der Seite den Fokus sofort weg, und keine Zeile kann
##   ihn mit grab_focus() zurückholen. Ohne Fokus gehen Enter und Leertaste an keine Zeile.
## - mouse_behavior_recursive DISABLED lässt jede Zeile für die Maus wie IGNORE wirken: kein
##   mouse_entered (MainMenu wählt damit), kein gui_input (SaveList wählt bei Bewegung), kein Klick.
## Frei heißt INHERITED, nicht ENABLED: So gilt weiter, was der Bildschirm darüber einstellt.
func _set_locked(locked: bool) -> void:
	_locked = locked
	focus_behavior_recursive = FOCUS_BEHAVIOR_DISABLED if locked else FOCUS_BEHAVIOR_INHERITED
	mouse_behavior_recursive = MOUSE_BEHAVIOR_DISABLED if locked else MOUSE_BEHAVIOR_INHERITED


## Das Rechteck, das MenuHint bekommt: oben bündig mit [param row_rect], links aber an der linken
## Kante des Gehäuses statt der Zeile. MenuHint stellt seine rechte Kante GAP vor die linke Kante
## dessen, was er bekommt; so braucht er keine neue Funktion. Für gleiche Zeilen kommt ein gleiches
## Rechteck heraus, die Regel „eine Meldung bleibt bei derselben Zeile“ gilt also weiter.
func _beside_case(row_rect: Rect2) -> Rect2:
	return Rect2(Vector2(_case.get_global_rect().position.x, row_rect.position.y), row_rect.size)


## Stellt Anzeige und Seiten auf display_rect.
func _apply_display() -> void:
	_display.position = Vector2(display_rect.position)
	_display.size = Vector2(display_rect.size)
	for page in _page_list():
		_place_page(page)


## Gibt [param page] Lage und Größe der Anzeige. Was eine Seite selbst an Größe setzt, gilt hier
## nicht; auf der Anzeige ist jede Seite so groß wie die Anzeige (Analyse, C6).
func _place_page(page: Control) -> void:
	page.position = Vector2(display_rect.position)
	page.size = Vector2(display_rect.size)


## Die Seiten: jedes Control unter dem Communicator außer Gehäuse, Anzeige und Hinweis, in der
## Reihenfolge im Baum. Eine eigene Liste braucht es nicht; was der Bildschirm unter die Instanz
## hängt oder mit add_page() dazugibt, ist eine Seite, und was er wegnimmt, ist keine mehr.
func _page_list() -> Array[Control]:
	var pages: Array[Control] = []
	for child in get_children():
		var page := child as Control
		if page != null and page != _case and page != _display and page != _hint:
			pages.append(page)
	return pages


## Ob [param point] auf ganzen Bildpixeln liegt: Ein Bildpixel sind 2 × 2 Oberflächenpixel, x und y
## müssen also gerade sein. Nur dann steht das Gehäuse im Stand auf dem Raster des Hintergrunds.
static func _on_image_grid(point: Vector2) -> bool:
	return fposmod(point.x, 2.0) == 0.0 and fposmod(point.y, 2.0) == 0.0


## Der Platzhalter für das Gehäuse in [param rect], von unten nach oben, je als
## { "rect": Rect2, "color": Color }: Fläche gehaeuse, darum ein Pixel Kontur tusche (research.md,
## R11). Vier Streifen statt eines Rahmens aus draw_rect(..., false): Eine Linie liegt mittig auf
## der Kante und träfe die Pixel nur halb.
static func _placeholder_layers(rect: Rect2) -> Array[Dictionary]:
	var left := rect.position.x
	var top := rect.position.y
	var contour := UiPalette.TUSCHE
	return [
		{"rect": rect, "color": UiPalette.GEHAEUSE},
		{"rect": Rect2(left, top, rect.size.x, 1), "color": contour},
		{"rect": Rect2(left, rect.end.y - 1, rect.size.x, 1), "color": contour},
		{"rect": Rect2(left, top, 1, rect.size.y), "color": contour},
		{"rect": Rect2(rect.end.x - 1, top, 1, rect.size.y), "color": contour},
	]
