extends GutTest

## Prüft die Seite InvadersPage (Feature 006, T020; contracts/invaders.md, „Tests“).
##
## Die Seite steht wie auf der Anzeige bei (280, 120) in einem eigenen Viewport von 640 × 360. Der
## Test schaltet autoplay ab und taktet selbst mit advance(); so hängt nichts an der echten Zeit.
## Tasten und Klicks gehen als erfundene Ereignisse über push_input in den Viewport, also denselben
## Weg wie echte: Der Viewport gibt Tasten an das Control mit dem Fokus, Klicks an das Control unter
## dem Zeiger. Was die Seite nicht verbraucht, kommt beim Lauscher an, einem Node im selben
## Viewport, der _unhandled_input() mitschreibt wie später der Titel.
##
## Töne: Headless spielt Godot ohne Ausgabe, playing wird trotzdem true (research.md, R15). Der Test
## prüft also, welcher Player anläuft, nicht, was zu hören ist.

const SEITE := preload("res://scenes/title/invaders/invaders_page.tscn")
## Ein Bild bei 60 Bildern je Sekunde, zugleich ein Schritt des Kerns.
const BILD := 1.0 / 60.0
const SEED := 1
## Lage der Anzeige im Titel (Style-Guide, Baustein Communicator).
const LAGE := Vector2(280, 120)
## Mehr Schritte braucht keine Partie (SC-002, Obergrenze 3 Minuten).
const HOECHSTENS_SCHRITTE := 10800
## Die Sperre der Ergebnisanzeige in Schritten: 0,5 s.
const SPERRE := 30


## Schreibt mit, was kein Control verbraucht hat.
class Lauscher extends Node:
	var ereignisse: Array[InputEvent] = []

	func _unhandled_input(event: InputEvent) -> void:
		ereignisse.append(event)


var _viewport: SubViewport
var _seite: InvadersPage
var _lauscher: Lauscher
var _fertig := 0
## Welche Pfeile der Testspieler gerade hält.
var _haelt_links := false
var _haelt_rechts := false


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(640, 360)
	add_child_autofree(_viewport)
	_lauscher = Lauscher.new()
	_viewport.add_child(_lauscher)
	_seite = SEITE.instantiate() as InvadersPage
	_seite.autoplay = false
	_seite.position = LAGE
	_viewport.add_child(_seite)
	_seite.finished.connect(func() -> void: _fertig += 1)
	_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	_fertig = 0
	_haelt_links = false
	_haelt_rechts = false


# --- Start und Fokus ------------------------------------------------------

func test_start_nimmt_den_fokus_und_beginnt_eine_partie() -> void:
	# Act
	_seite.start(SEED)

	# Assert
	assert_true(_seite.has_focus(), "Die Seite hat den Fokus.")
	assert_not_null(_seite.game())
	assert_eq(_seite.game().state, InvadersGame.State.PLAYING)
	assert_eq(_seite.game().aliens_left(), 32)
	assert_false(_seite.is_waiting_for_key())


func test_zeiger_pfeil_und_fokus_fuer_tasten() -> void:
	assert_eq(_seite.mouse_default_cursor_shape, Control.CURSOR_ARROW, "Der Zeiger bleibt der Pfeil.")
	assert_eq(_seite.focus_mode, Control.FOCUS_ALL)
	assert_eq(_seite.mouse_filter, Control.MOUSE_FILTER_STOP, "Klicks bleiben bei der Seite.")


func test_der_fokus_kommt_zurueck_solange_die_seite_laeuft() -> void:
	# Arrange
	var anderes := Control.new()
	anderes.focus_mode = Control.FOCUS_ALL
	_viewport.add_child(anderes)
	_seite.start(SEED)

	# Act: Ein anderes Control nimmt den Fokus mit grab_focus().
	anderes.grab_focus()
	await wait_process_frames(1)

	# Assert
	assert_true(_seite.has_focus(), "Die Seite hat den Fokus zurück.")

	# Act: Nach finished bleibt der Fokus, wo er hingeht.
	_druecke(KEY_ESCAPE)
	anderes.grab_focus()
	await wait_process_frames(1)

	# Assert
	assert_true(anderes.has_focus(), "Nach finished holt die Seite den Fokus nicht zurück.")


func test_verborgen_holt_die_seite_den_fokus_nicht_zurueck() -> void:
	# Arrange
	var anderes := Control.new()
	anderes.focus_mode = Control.FOCUS_ALL
	_viewport.add_child(anderes)
	_seite.start(SEED)

	# Act: Wie beim Seitenwechsel: verbergen, dann nimmt ein anderes den Fokus.
	_seite.hide()
	anderes.grab_focus()
	await wait_process_frames(1)

	# Assert
	assert_true(anderes.has_focus())


# --- Tasten ---------------------------------------------------------------

func test_tasten_erreichen_den_bildschirm_darunter_nicht() -> void:
	# Arrange
	_seite.start(SEED)

	# Act: Pfeile, Leertaste, Esc-lose unbekannte Tasten und Shift allein.
	for taste: Key in [KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_A, KEY_ENTER, KEY_UP, KEY_TAB, KEY_SHIFT]:
		_druecke(taste)
	_taste(KEY_SPACE, true, true)

	# Assert
	assert_eq(_lauscher.ereignisse.size(), 0,
		"Durchgekommen: %s" % [_lauscher.ereignisse.map(func(e: InputEvent) -> String:
			return e.as_text())])
	assert_eq(_fertig, 0)


func test_pfeile_fahren_solange_gehalten() -> void:
	# Arrange
	_seite.start(SEED)
	var start_x := _seite.game().cannon_x

	# Act und Assert
	_taste(KEY_LEFT, true)
	_schritte(5)
	assert_eq(_seite.game().cannon_x, start_x - 5, "Links gehalten: 5 Schritte, 5 Bildpixel.")
	_taste(KEY_LEFT, false)
	_schritte(5)
	assert_eq(_seite.game().cannon_x, start_x - 5, "Losgelassen: steht.")
	_taste(KEY_RIGHT, true)
	_schritte(3)
	assert_eq(_seite.game().cannon_x, start_x - 2, "Rechts gehalten.")
	_taste(KEY_LEFT, true)
	_schritte(3)
	assert_eq(_seite.game().cannon_x, start_x - 2, "Beide gehalten heben sich auf.")


func test_leertaste_schiesst_bei_jedem_neuen_druck_echo_nicht() -> void:
	# Arrange
	_seite.start(SEED)

	# Act: nur ein Echo, ohne Druck vorher.
	_taste(KEY_SPACE, true, true)
	_schritte(1)

	# Assert
	assert_eq(_teile(&"shot").size(), 0, "Ein Echo schießt nicht.")

	# Act: ein neuer Druck.
	_druecke(KEY_SPACE)
	_schritte(1)

	# Assert
	assert_eq(_teile(&"shot").size(), 1, "Der neue Druck schießt.")


func test_ein_druck_schiesst_nur_einmal_auch_bei_mehreren_schritten() -> void:
	# Arrange
	_seite.start(SEED)
	_druecke(KEY_SPACE)

	# Act: ein langes Bild, vier Schritte; der Schuss fliegt in drei davon.
	_seite.advance(4 * BILD)

	# Assert
	var schuss := _teile(&"shot")
	assert_eq(schuss.size(), 1)
	assert_eq(schuss[0].y, 69 - 3 * InvadersGame.SHOT_SPEED,
		"Ein Schuss aus dem ersten Schritt, kein zweiter.")


func test_kuerzel_und_vollbild_gehen_durch() -> void:
	# Arrange
	_seite.start(SEED)

	# Act: Cmd+Q, Strg+Cmd+F (toggle_fullscreen), Alt+Pfeil und die Aktion selbst.
	_druecke(KEY_Q, {"meta": true})
	_druecke(KEY_F, {"meta": true, "ctrl": true})
	_druecke(KEY_LEFT, {"alt": true})
	var aktion := InputEventAction.new()
	aktion.action = &"toggle_fullscreen"
	aktion.pressed = true
	_viewport.push_input(aktion)
	_schritte(3)

	# Assert: Alle kommen beim Bildschirm an, und keins wirkt im Spiel.
	assert_eq(_lauscher.ereignisse.size(), 7, "Drei Tasten mit Loslassen und die Aktion.")
	assert_true(_lauscher.ereignisse[2].is_action(&"toggle_fullscreen"),
		"Strg+Cmd+F ist toggle_fullscreen.")
	assert_eq(_seite.game().cannon_x, InvadersGame.CANNON_START_X, "Alt+Pfeil fährt nicht.")
	assert_eq(_fertig, 0)


func test_f11_geht_durch_das_loslassen_von_enter_nicht() -> void:
	# Arrange (Feature 007, T043, T062): Ohne genauen Vergleich träfe schon das Loslassen von Enter
	# die Aktion, denn beim Loslassen prüft Godot die Zusatztasten von Alt+Enter nicht.
	_seite.start(SEED)
	var loslassen := InputEventKey.new()
	loslassen.keycode = KEY_ENTER
	loslassen.physical_keycode = KEY_ENTER
	assert_true(loslassen.is_action(&"toggle_fullscreen"), "Die Falle: ungenau trifft es.")
	assert_false(loslassen.is_action(&"toggle_fullscreen", true), "Genau trifft es nicht.")

	# Act
	_druecke(KEY_F11)
	_druecke(KEY_ENTER)

	# Assert: F11 kommt mit Drücken und Loslassen beim Bildschirm an, Enter gar nicht.
	assert_eq(_lauscher.ereignisse.size(), 2, "Durchgekommen: %s" % [_lauscher.ereignisse.map(
		func(e: InputEvent) -> String: return e.as_text())])
	if _lauscher.ereignisse.size() == 2:
		assert_true(_lauscher.ereignisse[0].is_action_pressed(&"toggle_fullscreen", false, true),
			"F11 ist toggle_fullscreen.")
		assert_true(_lauscher.ereignisse[1].is_action_released(&"toggle_fullscreen", true),
			"Das Loslassen von F11 geht mit durch.")
	assert_eq(_fertig, 0)


# --- Ereignisse und Töne --------------------------------------------------

func test_alle_player_laufen_auf_effekte() -> void:
	var player := _player()
	assert_eq(player.size(), 6)
	for name: String in player:
		assert_eq((player[name] as AudioStreamPlayer).bus, &"Effekte", name)
	assert_eq(_klang("ShotSound"), "schuss.wav")
	assert_eq(_klang("HitSound"), "treffer.wav")
	assert_eq(_klang("CannonSound"), "kanone.wav")
	assert_eq(_klang("WonSound"), "sieg.wav")
	assert_eq(_klang("LostSound"), "niederlage.wav")


func test_schuss_treffer_und_marsch_spielen_ihren_player() -> void:
	# Arrange
	_seite.start(SEED)

	# Act und Assert: Schuss.
	_druecke(KEY_SPACE)
	_schritte(1)
	assert_true(_spielt("ShotSound"), "Schuss")
	assert_false(_spielt("HitSound"))

	# Der erste Takt kommt nach 30 Schritten: marsch_1, der zweite marsch_2 im selben Player.
	_schritte(29)
	assert_true(_spielt("MarchSound"), "Erster Takt")
	assert_eq(_klang("MarchSound"), "marsch_1.wav")
	_schritte(30)
	assert_eq(_klang("MarchSound"), "marsch_2.wav", "Zweiter Takt im selben Player.")

	# Treffer: Der Testspieler fährt unter einen Außerirdischen und schießt.
	var uebrig := _seite.game().aliens_left()
	for i in 600:
		_spieler_tasten(_seite.game())
		_schritte(1)
		if _seite.game().aliens_left() < uebrig:
			break
	assert_eq(_seite.game().aliens_left(), uebrig - 1, "Getroffen.")
	assert_true(_spielt("HitSound"), "Treffer")


func test_kanone_getroffen_und_verloren_spielen_ihren_player() -> void:
	# Arrange: Die Kanone steht; drei Bomben treffen sie, bevor der Block landet (lernnotizen.md,
	# Phase 3).
	_seite.start(SEED)
	var leben := _seite.game().lives
	var kanone_gehoert := 0

	# Act
	for i in HOECHSTENS_SCHRITTE:
		_schritte(1)
		if _seite.game().lives < leben:
			leben = _seite.game().lives
			if _spielt("CannonSound"):
				kanone_gehoert += 1
		if _seite.game().state == InvadersGame.State.LOST:
			break

	# Assert
	assert_eq(_seite.game().lost_reason, InvadersGame.LostReason.HIT)
	assert_eq(kanone_gehoert, 3, "Jeder Treffer an der Kanone spielt kanone.wav.")
	assert_true(_spielt("LostSound"), "Verloren")
	assert_false(_spielt("WonSound"))


func test_gewonnen_spielt_sieg_und_zeigt_die_ergebnisanzeige() -> void:
	# Arrange
	_seite.start(SEED)

	# Act: Der Testspieler zielt und weicht aus, nur über Tasten.
	_spiele_bis_zum_ende(true)

	# Assert
	assert_eq(_seite.game().state, InvadersGame.State.WON)
	assert_eq(_seite.game().score, 640)
	assert_true(_spielt("WonSound"), "Sieg")
	assert_eq(InvadersPage.result_lines(_seite.game()),
		PackedStringArray(["ALLE ERWISCHT.", "640 PUNKTE", "Weiter mit Taste oder Klick."]))


# --- Ergebnisanzeige ------------------------------------------------------

func test_ergebnisanzeige_nimmt_erst_nach_der_sperre_einen_neuen_druck() -> void:
	# Arrange
	_seite.start(SEED)
	_spiele_bis_zum_ende(false)
	assert_eq(_seite.game().state, InvadersGame.State.LOST)
	assert_eq(InvadersPage.result_lines(_seite.game())[0], "GAME OVER")

	# Act und Assert: gesperrt, auch für Leertaste, Taste und Linksklick.
	assert_false(_seite.is_waiting_for_key())
	_druecke(KEY_SPACE)
	_druecke(KEY_A)
	_klick(MOUSE_BUTTON_LEFT)
	_schritte(SPERRE - 1)
	_druecke(KEY_A)
	assert_false(_seite.is_waiting_for_key(), "Ein Schritt vor dem Ende der Sperre.")
	assert_eq(_fertig, 0, "Während der Sperre führt nichts weiter.")

	# Nach 0,5 s wartet sie, und ein Echo, Shift allein und gehaltene Pfeile zählen nicht.
	_schritte(1)
	assert_true(_seite.is_waiting_for_key())
	_taste(KEY_A, true, true)
	_druecke(KEY_SHIFT)
	_taste(KEY_LEFT, false)
	assert_eq(_fertig, 0, "Echo, Shift allein und Loslassen zählen nicht.")

	# Ein neuer Druck führt weiter.
	_taste(KEY_LEFT, true)
	assert_eq(_fertig, 1, "Ein neuer Druck meldet finished.")
	assert_eq(_lauscher.ereignisse.size(), 0, "Nichts kam beim Bildschirm an.")


func test_ergebnisanzeige_linksklick_fuehrt_weiter_andere_maustasten_nicht() -> void:
	# Arrange
	_seite.start(SEED)
	_spiele_bis_zum_ende(false)
	_schritte(SPERRE)

	# Act und Assert
	_klick(MOUSE_BUTTON_RIGHT)
	_klick(MOUSE_BUTTON_MIDDLE)
	_klick(MOUSE_BUTTON_WHEEL_DOWN)
	assert_eq(_fertig, 0, "Rechts, Mitte und Rad tun nichts.")
	_klick(MOUSE_BUTTON_LEFT)
	assert_eq(_fertig, 1, "Linksklick führt weiter.")


func test_kuerzel_fuehren_in_der_ergebnisanzeige_nicht_weiter() -> void:
	# Arrange
	_seite.start(SEED)
	_spiele_bis_zum_ende(false)
	_schritte(SPERRE)

	# Act
	_druecke(KEY_Q, {"meta": true})
	_druecke(KEY_F, {"meta": true, "ctrl": true})
	_druecke(KEY_A, {"alt": true})
	_druecke(KEY_A, {"ctrl": true})
	_druecke(KEY_CTRL, {"ctrl": true})
	_druecke(KEY_META, {"meta": true})

	# Assert
	assert_eq(_fertig, 0, "Kürzel und Cmd oder Strg allein führen nicht weiter.")
	assert_eq(_lauscher.ereignisse.size(), 12, "Alle Kürzel kamen beim Bildschirm an.")
	assert_true(_seite.is_waiting_for_key())


func test_ohne_fokus_des_fensters_steht_auch_die_sperre() -> void:
	# Arrange
	_seite.start(SEED)
	_spiele_bis_zum_ende(false)

	# Act: Die Sperre läuft ohne Fokus nicht, und danach wird nichts nachgeholt.
	_seite.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_schritte(SPERRE * 2)
	_seite.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)

	# Assert
	assert_false(_seite.is_waiting_for_key(), "Die Sperre stand.")
	_schritte(SPERRE)
	assert_true(_seite.is_waiting_for_key())


# --- Esc und Ende ---------------------------------------------------------

func test_esc_beendet_mitten_im_spiel_und_danach_taktet_nichts() -> void:
	# Arrange: bis kurz nach dem ersten Takt, damit der Marschton läuft.
	_seite.start(SEED)
	_druecke(KEY_SPACE)
	_schritte(30)
	assert_true(_spielt("MarchSound"), "Voraussetzung: Der Marschton läuft.")
	var vorher := var_to_str(_seite.game().drawables())
	var bild := _seite.game().march_frame

	# Act
	_druecke(KEY_ESCAPE)
	_schritte(120)
	_seite.advance(10.0)

	# Assert
	assert_eq(_fertig, 1)
	# Das Loslassen von Esc kommt nach finished; die Seite läuft dann nicht mehr und lässt es durch.
	assert_eq(_gedrueckte_beim_bildschirm(), 0, "Esc kam nicht beim Bildschirm an.")
	for name: String in _player():
		assert_false(_spielt(name), "%s ist still." % name)
	assert_eq(_seite.game().march_frame, bild, "Kein Takt mehr.")
	assert_eq(var_to_str(_seite.game().drawables()), vorher, "Der Kern ruht.")


func test_esc_beendet_auch_in_der_sperre() -> void:
	# Arrange
	_seite.start(SEED)
	_spiele_bis_zum_ende(false)

	# Act
	_druecke(KEY_ESCAPE)

	# Assert
	assert_eq(_fertig, 1)
	assert_false(_spielt("LostSound"), "Verlassen: Auch das Motiv verstummt.")


func test_ein_neuer_start_beginnt_eine_neue_partie() -> void:
	# Arrange
	_seite.start(SEED)
	_schritte(10)
	_druecke(KEY_ESCAPE)
	var alte := _seite.game()

	# Act
	_seite.start(SEED)
	_schritte(1)

	# Assert
	assert_ne(_seite.game(), alte)
	assert_true(_seite.has_focus())
	assert_eq(_seite.game().state, InvadersGame.State.PLAYING)


# --- Takt -----------------------------------------------------------------

func test_hoechstens_vier_schritte_je_aufruf_und_ein_zeitspeicher() -> void:
	# Arrange
	_seite.start(SEED)
	var start_x := _seite.game().cannon_x
	_taste(KEY_RIGHT, true)

	# Act und Assert: ein Hänger von 1 s gibt nur 4 Schritte, der Rest verfällt.
	_seite.advance(1.0)
	assert_eq(_seite.game().cannon_x, start_x + 4)
	_seite.advance(BILD / 2.0)
	assert_eq(_seite.game().cannon_x, start_x + 4, "Ein halber Schritt wartet im Speicher.")
	_seite.advance(BILD / 2.0)
	assert_eq(_seite.game().cannon_x, start_x + 5, "Zwei halbe sind ein Schritt.")


func test_ohne_fokus_des_fensters_taktet_nichts_und_die_toene_halten_an() -> void:
	# Arrange
	_seite.start(SEED)
	_schritte(30)
	var vorher := var_to_str(_seite.game().drawables())
	var laufende := _player().keys().filter(func(name: String) -> bool: return _spielt(name))
	assert_has(laufende, "MarchSound", "Voraussetzung: Der Marschton läuft.")

	# Act: Der Pfeil ist gehalten, als das Fenster den Fokus verliert; sein Loslassen kommt nie an.
	_taste(KEY_RIGHT, true)
	_seite.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_schritte(60)

	# Assert: Was lief, ist angehalten; ein angehaltener Player meldet playing false.
	assert_eq(var_to_str(_seite.game().drawables()), vorher, "Nichts bewegt sich.")
	for name: String in laufende:
		assert_true((_player()[name] as AudioStreamPlayer).stream_paused, "%s hält an." % name)
		assert_false(_spielt(name), "%s schweigt." % name)

	# Act: zurück, ohne Nachholen; ein Pfeil zählt erst mit neuem Druck.
	_seite.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_schritte(1)

	# Assert: Was lief, klingt weiter, wo es stand.
	for name: String in _player():
		assert_false((_player()[name] as AudioStreamPlayer).stream_paused, name)
	for name: String in laufende:
		assert_true(_spielt(name), "%s klingt weiter." % name)
	assert_eq(_seite.game().cannon_x, InvadersGame.CANNON_START_X,
		"Der Pfeil aus der Zeit ohne Fokus fährt nicht.")


func test_fokus_des_fensters_vor_ready_ohne_fehler() -> void:
	# Arrange: Im echten Fenster kommen die Fokus-Benachrichtigungen schon, bevor _ready() die
	# Player geholt hat. Headless kommen sie nie; der Test schickt sie deshalb selbst.
	var seite := SEITE.instantiate() as InvadersPage
	seite.autoplay = false

	# Act: vor dem Einhängen, also vor _ready().
	seite.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	seite.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_viewport.add_child(seite)
	seite.start(SEED)
	seite.advance(4 * BILD)

	# Assert: Ohne Fokus taktet nichts, und kein Ton spielt. (stream_paused zeigt Godot nur bei
	# einem Player, der gerade spielt; das prüft der Test zum Fokus des Fensters oben.)
	assert_eq(seite.game().cannon_x, InvadersGame.CANNON_START_X)
	assert_eq(var_to_str(seite.game().drawables()),
		var_to_str(InvadersGame.new(SEED).drawables()), "Kein Schritt ohne Fokus.")
	for kind in seite.get_children():
		assert_false((kind as AudioStreamPlayer).playing, "%s still." % kind.name)

	# Act: Der Fokus kommt zurück.
	seite.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_taste(KEY_RIGHT, true)
	seite.advance(BILD)

	# Assert
	assert_eq(seite.game().cannon_x, InvadersGame.CANNON_START_X + 1, "Mit Fokus läuft es.")
	for kind in seite.get_children():
		assert_false((kind as AudioStreamPlayer).stream_paused, kind.name)


func test_verborgen_taktet_die_seite_nicht_und_ist_still() -> void:
	# Arrange
	_seite.start(SEED)
	_schritte(30)
	assert_true(_spielt("MarchSound"), "Voraussetzung: Der Marschton läuft.")
	var vorher := var_to_str(_seite.game().drawables())

	# Act
	_seite.hide()
	_schritte(60)
	_seite.show()
	_schritte(60)

	# Assert: Der Kern ruht bis zum nächsten start().
	assert_false(_spielt("MarchSound"))
	assert_eq(var_to_str(_seite.game().drawables()), vorher)
	assert_eq(_fertig, 0, "Verbergen meldet kein finished.")


# --- Kopfzeile ------------------------------------------------------------

func test_leben_rechtsbuendig_das_letzte_endet_am_innenrand() -> void:
	assert_eq(InvadersPage.life_pos(2, 3), Vector2i(151, 2))
	assert_eq(InvadersPage.life_pos(1, 3), Vector2i(142, 2))
	assert_eq(InvadersPage.life_pos(0, 3), Vector2i(133, 2))
	assert_eq(InvadersPage.life_pos(0, 1), Vector2i(151, 2), "Ein Leben steht ganz rechts.")


# --- Helfer ---------------------------------------------------------------

func _schritte(anzahl: int) -> void:
	for i in anzahl:
		_seite.advance(BILD)


## Eine Taste drücken ([param gedrueckt] true) oder loslassen, über push_input.
## [param mods]: "meta", "ctrl", "alt", "shift" auf true.
func _taste(taste: Key, gedrueckt: bool, echo: bool = false, mods: Dictionary = {}) -> void:
	var ereignis := InputEventKey.new()
	ereignis.keycode = taste
	ereignis.physical_keycode = taste
	ereignis.pressed = gedrueckt
	ereignis.echo = echo
	ereignis.meta_pressed = mods.get("meta", false)
	ereignis.ctrl_pressed = mods.get("ctrl", false)
	ereignis.alt_pressed = mods.get("alt", false)
	ereignis.shift_pressed = mods.get("shift", false)
	_viewport.push_input(ereignis)


func _druecke(taste: Key, mods: Dictionary = {}) -> void:
	_taste(taste, true, false, mods)
	_taste(taste, false, false, mods)


## Drücken und loslassen mit [param knopf] mitten auf der Seite.
func _klick(knopf: MouseButton) -> void:
	var stelle := LAGE + Vector2(160, 80)
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = knopf
		ereignis.position = stelle
		ereignis.global_position = stelle
		ereignis.pressed = gedrueckt
		_viewport.push_input(ereignis, true)


## Wie viele gedrückte Tasten beim Lauscher ankamen; Loslassen zählt nicht.
func _gedrueckte_beim_bildschirm() -> int:
	return _lauscher.ereignisse.filter(func(e: InputEvent) -> bool: return e.is_pressed()).size()


func _player() -> Dictionary:
	var player := {}
	for kind in _seite.get_children():
		if kind is AudioStreamPlayer:
			player[str(kind.name)] = kind
	return player


func _spielt(name: String) -> bool:
	return (_seite.get_node(name) as AudioStreamPlayer).playing


func _klang(name: String) -> String:
	return (_seite.get_node(name) as AudioStreamPlayer).stream.resource_path.get_file()


func _teile(sprite: StringName) -> Array[Vector2i]:
	var lagen: Array[Vector2i] = []
	for teil in _seite.game().drawables():
		if teil["sprite"] == sprite:
			lagen.append(teil["pos"])
	return lagen


## Spielt bis WON oder LOST. [param zielen] true: Der Testspieler zielt, schießt und weicht aus,
## wie in test_invaders_game.gd, aber über Tasten. false: Die Kanone steht und schießt nicht.
func _spiele_bis_zum_ende(zielen: bool) -> void:
	for i in HOECHSTENS_SCHRITTE:
		var spiel := _seite.game()
		if spiel.state == InvadersGame.State.WON or spiel.state == InvadersGame.State.LOST:
			return
		if zielen:
			_spieler_tasten(spiel)
		_seite.advance(BILD)
	fail_test("Die Partie endet nicht in %d Schritten." % HOECHSTENS_SCHRITTE)


func _spieler_tasten(spiel: InvadersGame) -> void:
	var bomben := _teile(&"bomb")
	var richtung := _ausweichen(spiel.cannon_x, bomben)
	var schiessen := false
	if spiel.state == InvadersGame.State.PLAYING:
		var schuss_x := spiel.cannon_x + 4
		var ziel := Vector2i(-100, 0)
		for a in _ausserirdische():
			if absi(a.x + 3 - schuss_x) < absi(ziel.x + 3 - schuss_x):
				ziel = a
			if schuss_x >= a.x and schuss_x <= a.x + 7:
				schiessen = true
		schiessen = schiessen and _teile(&"shot").is_empty()
		if richtung == 0:
			var wunsch := signi(ziel.x + 3 - schuss_x)
			if _sicher(spiel.cannon_x + wunsch, bomben):
				richtung = wunsch
	if (richtung < 0) != _haelt_links:
		_haelt_links = richtung < 0
		_taste(KEY_LEFT, _haelt_links)
	if (richtung > 0) != _haelt_rechts:
		_haelt_rechts = richtung > 0
		_taste(KEY_RIGHT, _haelt_rechts)
	if schiessen:
		_druecke(KEY_SPACE)


func _ausserirdische() -> Array[Vector2i]:
	var lagen: Array[Vector2i] = []
	for sprite: StringName in [&"alien_a", &"alien_b", &"alien_c"]:
		lagen.append_array(_teile(sprite))
	return lagen


## Richtung zum nächsten Platz, an dem keine Bombe über der Kanone fällt; 0, wenn sie dort schon
## steht.
func _ausweichen(kanone_x: int, bomben: Array[Vector2i]) -> int:
	if _sicher(kanone_x, bomben):
		return 0
	for weite in range(1, 160):
		for x: int in [kanone_x - weite, kanone_x + weite]:
			if x >= 2 and x <= 149 and _sicher(x, bomben):
				return signi(x - kanone_x)
	return 0


## Ob an [param kanone_x] keine Bombe über der Kanone liegt, mit 1 Bildpixel Luft zu jeder Seite.
func _sicher(kanone_x: int, bomben: Array[Vector2i]) -> bool:
	for b in bomben:
		if b.x + 1 >= kanone_x - 1 and b.x <= kanone_x + 9:
			return false
	return true
