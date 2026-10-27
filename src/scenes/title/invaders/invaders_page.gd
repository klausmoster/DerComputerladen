class_name InvadersPage
extends Control

## Das Spiel auf der Anzeige als Seite des Communicators (Style-Guide, Baustein „Spiel auf der
## Anzeige“; contracts/invaders.md, „InvadersPage“). Die Seite rechnet nichts selbst: Sie sammelt
## die Tasten, taktet den Kern (InvadersGame) mit festem Schritt, malt, was er zeigt, und spielt zu
## seinen Ereignissen die Töne. Am Ende zeigt sie die Ergebnisanzeige und meldet [signal finished].
##
## Eingabe: Die Seite hat den Tastaturfokus und bekommt die Tasten deshalb in _gui_input(). Jede
## Taste ohne Cmd, Strg oder Alt verbraucht sie mit accept_event(), damit nichts zum Bildschirm
## darunter durchdringt; Kürzel mit Cmd, Strg oder Alt und die Aktion toggle_fullscreen lässt sie
## durch (R9). Pfeil links und rechts sind gehalten, bis sie losgelassen werden; die Leertaste
## schießt bei jedem neuen Druck. Echo-Ereignisse zählen nie. Verliert die Seite den Fokus, solange
## sie zu sehen ist und läuft, holt sie ihn zurück. Einen Fokusrahmen malt ein schlichtes Control
## nicht; der Zeiger ist der Pfeil, der Standard von mouse_default_cursor_shape.
##
## Takt: _process() gibt die Zeit an advance(), das sie in einem Zeitspeicher sammelt und in festen
## Schritten von 1/60 s an den Kern gibt, höchstens 4 je Aufruf (R6, SC-003). Ohne Fokus des
## Fensters, nach finished und solange die Seite verborgen ist, taktet sie nicht; der Kern ruht bis
## zum nächsten start() (R11; Analyse, U1).
##
## Bild: _draw() malt jedes Pixel der Muster als 2 × 2 Oberflächenpixel in tusche auf die Anzeige,
## die selbst den Grund lcd hat. Die Kopfzeile zeigt Punkte und Leben, die Ergebnisanzeige drei
## Zeilen mittig; Lagen und Schriften aus dem Style-Guide.

## Das Spiel ist vorbei: nach der Ergebnisanzeige oder durch Esc. Der Bildschirm kehrt zurück.
signal finished

# --- Werte aus dem Style-Guide, Spiel auf der Anzeige ---------------------------------------------
# Lagen der Kopfzeile in Bildpixeln wie im Kern; die Ergebnisanzeige in Oberflächenpixeln, wie der
# Style-Guide sie angibt.

## Ein Bildpixel ist 2 × 2 Oberflächenpixel.
const PIXEL := 2
## Höchstens so viele Schritte holt ein Aufruf von advance() nach (SC-003).
const MAX_STEPS := 4
## So lange nimmt die Ergebnisanzeige nach dem Ende nichts an außer Esc: 0,5 s.
const RESULT_LOCK := 0.5
## Die Punkte stehen ab x 2, oben bündig bei y 1, in drucker wie LcdHeader.
const SCORE_POS := Vector2i(InvadersGame.INSET, 1)
const SCORE_THEME_TYPE := &"LcdHeader"
## Die Leben: Muster life bei y 2 bis 5, 2 auseinander, das letzte endet bei x 157.
const LIFE_TOP := 2
const LIFE_GAP := 2
## Die Ergebnisanzeige: drei Zeilen zu 20 Oberflächenpixeln, als Block mittig ab y 50 der Anzeige.
const RESULT_TOP := 50
const RESULT_ROW_HEIGHT := 20
## Zeilen 1 und 2 in drucker wie eine Kopfzeile, Zeile 3 in menue wie ein Eintrag.
const RESULT_THEME_TYPES: Array[StringName] = [&"LcdHeader", &"LcdHeader", &"LcdRow"]

## Die vier Marschtöne nach "note" 0 bis 3; sie teilen sich den Player MarchSound.
const MARCH_STREAMS: Array[AudioStream] = [
	preload("res://assets/sounds/marsch_1.wav"),
	preload("res://assets/sounds/marsch_2.wav"),
	preload("res://assets/sounds/marsch_3.wav"),
	preload("res://assets/sounds/marsch_4.wav"),
]

## true: Die Seite taktet sich selbst in _process(). false: Tests takten mit advance().
var autoplay: bool = true

## Die laufende Partie; null bis zum ersten start().
var _game: InvadersGame = null
## Ob die Seite die Partie taktet und Eingaben annimmt: ab start() bis finished, oder bis sie
## verborgen wird.
var _active := false
## Ob das Fenster den Fokus hat (R11). Ohne ihn steht alles, auch die Sperre der Ergebnisanzeige.
var _window_focused := true
## Gesammelte Zeit, die noch keinen ganzen Schritt ergibt.
var _time_left := 0.0
## Gehaltene Pfeile und ein neuer Druck auf die Leertaste seit dem letzten Schritt.
var _left_held := false
var _right_held := false
var _fire_pressed := false
## Schritte, bis die Ergebnisanzeige eine Taste annimmt.
var _lock_steps := 0

@onready var _shot_sound: AudioStreamPlayer = $ShotSound
@onready var _hit_sound: AudioStreamPlayer = $HitSound
@onready var _cannon_sound: AudioStreamPlayer = $CannonSound
@onready var _march_sound: AudioStreamPlayer = $MarchSound
@onready var _won_sound: AudioStreamPlayer = $WonSound
@onready var _lost_sound: AudioStreamPlayer = $LostSound


func _ready() -> void:
	focus_exited.connect(_on_focus_exited)
	# Hatte das Fenster schon vor _ready() keinen Fokus, gilt das jetzt auch für die Player.
	_pause_sounds(not _window_focused)


func _process(delta: float) -> void:
	if autoplay:
		advance(delta)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			# Verborgen: Der Kern ruht bis zum nächsten start(), und die Töne verstummen (FR-044).
			if not is_visible_in_tree() and _active:
				_active = false
				_release_keys()
				_stop_sounds()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_window_focused = false
			# Ein Loslassen, während das Fenster keinen Fokus hat, käme nie an; die Pfeile gelten
			# deshalb als losgelassen.
			_release_keys()
			_pause_sounds(true)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_window_focused = true
			# Ohne Nachholen: Die Zeit ohne Fokus zählt nicht.
			_time_left = 0.0
			_pause_sounds(false)


func _draw() -> void:
	# Kein Grund: Das ist die Anzeige selbst, lcd. Vor dem ersten start() bleibt sie leer.
	if _game == null:
		return
	_draw_header()
	if _is_over():
		_draw_result()
		return
	for drawable in _game.drawables():
		_draw_sprite(drawable["sprite"], drawable["frame"], drawable["pos"])


func _gui_input(event: InputEvent) -> void:
	if not _active:
		return
	var key := event as InputEventKey
	if key != null:
		_on_key(key)
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		# Rechts- und Mittelklick und das Mausrad tun nichts; ein Linksklick nur in der
		# Ergebnisanzeige, wenn sie wartet.
		if is_waiting_for_key():
			accept_event()
			_finish()


## Beginnt eine neue Partie und nimmt den Fokus; der Bildschirm zeigt die Seite vorher
## (Analyse, C1). [param seed] -1 heißt zufällig.
@warning_ignore("shadowed_global_identifier")
func start(seed: int = -1) -> void:
	_stop_sounds()
	_game = InvadersGame.new(seed if seed != -1 else randi())
	_active = true
	_time_left = 0.0
	_release_keys()
	_lock_steps = 0
	queue_redraw()
	if _can_take_focus():
		grab_focus()


## Taktet um [param seconds] weiter, mit festem Schritt und höchstens 4 Schritten je Aufruf (R6).
## Was über 4 Schritte hinausgeht, verfällt: Nach einem langen Bild springt das Spiel nicht.
func advance(seconds: float) -> void:
	if not _active or not _window_focused or not is_visible_in_tree():
		return
	_time_left += seconds
	# Der kleine Zuschlag fängt Rundungsfehler ab: 1/60 s ergibt genau einen Schritt.
	var steps := floori((_time_left + 1e-6) / InvadersGame.STEP)
	if steps > MAX_STEPS:
		steps = MAX_STEPS
		_time_left = 0.0
	else:
		_time_left = maxf(_time_left - steps * InvadersGame.STEP, 0.0)
	for i in steps:
		_step()
	if steps > 0:
		queue_redraw()


## Die laufende Partie (Tests).
func game() -> InvadersGame:
	return _game


## Ob die Ergebnisanzeige steht und eine Taste annimmt.
func is_waiting_for_key() -> bool:
	return _active and _is_over() and _lock_steps <= 0


# --- Takt und Töne --------------------------------------------------------

## Ein Schritt: in der Partie mit den gehaltenen Tasten, in der Ergebnisanzeige nur die Sperre.
func _step() -> void:
	if _is_over():
		_lock_steps = maxi(_lock_steps - 1, 0)
		return
	var events := _game.step(_left_held, _right_held, _fire_pressed)
	# Ein Druck schießt höchstens einmal, auch wenn ein Bild mehrere Schritte hat.
	_fire_pressed = false
	_play(events)
	if _is_over():
		_lock_steps = roundi(RESULT_LOCK / InvadersGame.STEP)


## Spielt zu jedem Ereignis seinen Ton (contracts/invaders.md, „Töne“). play() beginnt einen Ton,
## der noch klingt, von vorn; beim Marsch ist das der Schnitt, wenn der nächste Takt kommt.
func _play(events: Array[Dictionary]) -> void:
	for event in events:
		match event["event"]:
			InvadersGame.Event.SHOT:
				_shot_sound.play()
			InvadersGame.Event.ALIEN_HIT:
				_hit_sound.play()
			InvadersGame.Event.MARCH:
				_march_sound.stream = MARCH_STREAMS[event["note"]]
				_march_sound.play()
			InvadersGame.Event.CANNON_HIT:
				_cannon_sound.play()
			InvadersGame.Event.WON:
				_won_sound.play()
			InvadersGame.Event.LOST:
				_lost_sound.play()


## Die Player der Seite; leer vor _ready(), denn bis dahin sind die @onready-Variablen null. Die
## Fokus-Benachrichtigungen des Fensters kommen im echten Fenster schon beim Einhängen, vor _ready().
func _players() -> Array[AudioStreamPlayer]:
	if not is_node_ready():
		return []
	return [_shot_sound, _hit_sound, _cannon_sound, _march_sound, _won_sound, _lost_sound]


func _stop_sounds() -> void:
	for player in _players():
		player.stop()
		player.stream_paused = false


## Hält alle Töne an oder lässt sie weiterklingen, wo sie standen.
func _pause_sounds(paused: bool) -> void:
	for player in _players():
		player.stream_paused = paused


# --- Eingabe --------------------------------------------------------------

func _on_key(key: InputEventKey) -> void:
	# Kürzel und Vollbild gehen durch, auch in der Ergebnisanzeige, und führen dort nicht weiter.
	if key.ctrl_pressed or key.meta_pressed or key.alt_pressed:
		return
	if InputMap.has_action(&"toggle_fullscreen") and key.is_action(&"toggle_fullscreen"):
		return
	accept_event()
	var is_new_press := key.pressed and not key.echo
	if key.keycode == KEY_ESCAPE:
		if is_new_press:
			_finish()
		return
	if _is_over():
		if is_new_press and is_waiting_for_key() and not _is_modifier(key.keycode):
			_finish()
		return
	match key.keycode:
		KEY_LEFT:
			if not key.echo:
				_left_held = key.pressed
		KEY_RIGHT:
			if not key.echo:
				_right_held = key.pressed
		KEY_SPACE:
			if is_new_press:
				_fire_pressed = true


## Shift, Strg, Alt und Cmd allein zählen in der Ergebnisanzeige nicht als Taste (CHK009).
static func _is_modifier(keycode: Key) -> bool:
	return keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]


func _release_keys() -> void:
	_left_held = false
	_right_held = false
	_fire_pressed = false


## Das Ende der Seite: kein Takt, keine Töne mehr, dann die Meldung.
func _finish() -> void:
	_active = false
	_release_keys()
	_stop_sounds()
	finished.emit()


## Der Fokus ging weg, etwa an eine Gehäusetaste. Zurück erst nach diesem Bild, wenn die Seite dann
## noch läuft und zu sehen ist (Analyse, C5): Wer sie gerade verbirgt, bekommt den Fokus nicht
## wieder weggenommen.
func _on_focus_exited() -> void:
	if _active:
		_reclaim_focus.call_deferred()


func _reclaim_focus() -> void:
	if _active and not has_focus() and _can_take_focus():
		grab_focus()


## Ob die Seite den Fokus nehmen kann: zu sehen und nicht gesperrt, etwa durch den Communicator,
## der hinausfährt (focus_behavior_recursive).
func _can_take_focus() -> bool:
	return is_visible_in_tree() and get_focus_mode_with_override() != FOCUS_NONE


# --- Malen ----------------------------------------------------------------

func _is_over() -> bool:
	return _game != null and (_game.state == InvadersGame.State.WON
			or _game.state == InvadersGame.State.LOST)


## Die Kopfzeile: links die Punkte, rechts je verbleibendem Leben ein Muster life.
func _draw_header() -> void:
	var font := get_theme_font(&"font", SCORE_THEME_TYPE)
	var font_size := get_theme_font_size(&"font_size", SCORE_THEME_TYPE)
	# Oben bündig wie ein Label: Die Zeile beginnt bei y 1, die Grundlinie liegt eine Oberlänge
	# tiefer.
	var baseline := Vector2(SCORE_POS * PIXEL) + Vector2(0, font.get_ascent(font_size))
	draw_string(font, baseline, TitleTexts.INVADERS_SCORE % _game.score, HORIZONTAL_ALIGNMENT_LEFT,
			-1, font_size, UiPalette.TUSCHE)
	for index in _game.lives:
		_draw_sprite(&"life", 0, life_pos(index, _game.lives))


## Die Ergebnisanzeige: drei Zeilen, jede waagrecht mittig, der Block ab RESULT_TOP.
func _draw_result() -> void:
	var lines := result_lines(_game)
	for row in lines.size():
		var theme_type := RESULT_THEME_TYPES[row]
		var font := get_theme_font(&"font", theme_type)
		var font_size := get_theme_font_size(&"font_size", theme_type)
		var width := font.get_string_size(lines[row], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var top := RESULT_TOP + row * RESULT_ROW_HEIGHT
		# Senkrecht mittig in der Zeile wie ein Label, auf ganzen Oberflächenpixeln.
		var baseline := top + floorf((RESULT_ROW_HEIGHT - font.get_height(font_size)) / 2.0) \
				+ font.get_ascent(font_size)
		draw_string(font, Vector2(floorf((size.x - width) / 2.0), baseline), lines[row],
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiPalette.TUSCHE)


## Malt Muster [param sprite], Bild [param frame], mit der linken oberen Ecke bei [param pos] in
## Bildpixeln: jedes gesetzte Pixel als Quadrat von PIXEL × PIXEL Oberflächenpixeln.
func _draw_sprite(sprite: StringName, frame: int, pos: Vector2i) -> void:
	for pixel in InvadersSprites.pixels(sprite, frame):
		draw_rect(Rect2(Vector2((pos + pixel) * PIXEL), Vector2(PIXEL, PIXEL)), UiPalette.TUSCHE)


## Die drei Zeilen der Ergebnisanzeige für [param ended_game], eine Partie, die zu Ende ist.
static func result_lines(ended_game: InvadersGame) -> PackedStringArray:
	var headline := TitleTexts.INVADERS_WON if ended_game.state == InvadersGame.State.WON \
			else TitleTexts.INVADERS_LOST
	return PackedStringArray([headline, TitleTexts.INVADERS_POINTS % ended_game.score,
			TitleTexts.INVADERS_CONTINUE])


## Linke obere Ecke von Leben [param index] (0 links) bei [param lives] gezeigten, in Bildpixeln:
## rechtsbündig, das letzte endet am Innenrand bei x 157.
static func life_pos(index: int, lives: int) -> Vector2i:
	var width := InvadersSprites.size_of(&"life").x
	var from_right := lives - 1 - index
	var left := InvadersGame.RIGHT_EDGE + 1 - width - from_right * (width + LIFE_GAP)
	return Vector2i(left, LIFE_TOP)
