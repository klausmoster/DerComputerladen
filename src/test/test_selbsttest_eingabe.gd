extends GutTest

## Prüft SelbsttestEingabe ohne Fenster (Feature 007, T012; R4; FR-004, FR-010): Der Filter lässt
## nur Ereignisse mit device 4711 durch, ausgeschaltet alles; Positionen gehen vom Raster in
## Fensterpixel; Drücken und Loslassen kommen in zwei Bildern, vor dem Klick eine Bewegung; gehaltene
## Tasten wiederholen sich jedes Bild; erste_eingabe_ms() nennt die erste Eingabe eines Schritts.
##
## Den Empfang am echten Fenster (DisplayServer.window_set_input_event_callback()) gibt es headless
## nicht; einschalten() kommt deshalb nicht vor. Die Tests schalten den Filter über _aktiv ein und
## schicken die Ereignisse statt an Input an eine eigene Senke, die mitschreibt.

var _viewport: SubViewport
var _eingabe: SelbsttestEingabe
## Je Ereignis {"ereignis": InputEvent, "bild": int}.
var _gesendet: Array[Dictionary] = []


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(640, 360)
	add_child_autofree(_viewport)
	_gesendet.clear()
	_eingabe = SelbsttestEingabe.new()
	_eingabe.viewport = _viewport
	_eingabe.senke = _merke


# --- Filter ---------------------------------------------------------------------------------------

func test_eingeschaltet_kommen_nur_eigene_ereignisse_durch() -> void:
	# Arrange
	_eingabe._aktiv = true
	var echt := InputEventMouseButton.new()
	echt.device = 0
	var eigen := InputEventMouseButton.new()
	eigen.device = SelbsttestEingabe.DEVICE
	var taste := InputEventKey.new()

	# Assert
	assert_eq(SelbsttestEingabe.DEVICE, 4711)
	assert_true(_eingabe.ist_aktiv())
	assert_false(_eingabe.durchlassen(echt))
	assert_false(_eingabe.durchlassen(taste), "Eine echte Taste hat ein anderes Gerät.")
	assert_true(_eingabe.durchlassen(eigen))


func test_ausgeschaltet_kommt_alles_durch() -> void:
	# Arrange
	_eingabe._aktiv = true
	var echt := InputEventMouseMotion.new()
	echt.device = 0

	# Act
	_eingabe.ausschalten()

	# Assert
	assert_false(_eingabe.ist_aktiv())
	assert_true(_eingabe.durchlassen(echt))
	assert_true(Input.use_accumulated_input, "Wieder wie vorher.")


func test_der_empfang_reicht_nur_eigene_ereignisse_an_den_viewport() -> void:
	# Arrange: eine Fläche über dem ganzen Viewport, die mitschreibt, was ankommt.
	var flaeche := Control.new()
	flaeche.size = Vector2(640, 360)
	_viewport.add_child(flaeche)
	_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	var angekommen: Array[int] = []
	flaeche.gui_input.connect(func(ereignis: InputEvent) -> void:
		angekommen.append(ereignis.device))
	_eingabe._aktiv = true

	# Act
	for geraet in [0, SelbsttestEingabe.DEVICE, 1]:
		var bewegung := InputEventMouseMotion.new()
		bewegung.device = geraet
		bewegung.position = Vector2(100, 100)
		bewegung.global_position = Vector2(100, 100)
		_eingabe._empfange(bewegung)

	# Assert: nur das eigene, und zwar mit dem Gerät einer echten Maus
	assert_eq(angekommen, [InputEvent.DEVICE_ID_MOUSE] as Array[int])


func test_fuer_das_spiel_bekommt_eine_eigene_eingabe_das_echte_geraet() -> void:
	# Arrange: In Godot 4.7 gelten Aktionen nur für das Gerät echter Tasten.
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	enter.device = SelbsttestEingabe.DEVICE
	var klick := InputEventMouseButton.new()
	klick.device = SelbsttestEingabe.DEVICE
	var echt := InputEventKey.new()
	echt.device = 3

	# Act
	var taste := SelbsttestEingabe.fuer_das_spiel(enter)
	var maus := SelbsttestEingabe.fuer_das_spiel(klick)

	# Assert
	assert_false(enter.is_action_pressed(&"ui_accept"), "Mit 4711 löst Enter nichts aus.")
	assert_eq(taste.device, InputEvent.DEVICE_ID_KEYBOARD)
	assert_true(taste.is_action_pressed(&"ui_accept"))
	assert_eq(enter.device, SelbsttestEingabe.DEVICE, "Das Original bleibt gekennzeichnet.")
	assert_eq(maus.device, InputEvent.DEVICE_ID_MOUSE)
	assert_same(SelbsttestEingabe.fuer_das_spiel(echt), echt)


# --- Umrechnung -----------------------------------------------------------------------------------

func test_vom_raster_in_fensterpixel() -> void:
	# Faktor 2 bei 1280 × 720 (R4)
	assert_eq(SelbsttestEingabe.umrechnen(Vector2(320, 180), Transform2D.IDENTITY.scaled(
		Vector2(2, 2))), Vector2(640, 360))
	# Faktor 3 mit Rand links 10 und oben 5, wie in einem krummen Fenster
	assert_eq(SelbsttestEingabe.umrechnen(Vector2(100, 50), Transform2D(Vector2(3, 0),
		Vector2(0, 3), Vector2(10, 5))), Vector2(310, 155))


func test_ohne_vergroesserung_bleibt_der_punkt() -> void:
	assert_eq(_eingabe.ins_fenster(Vector2(12.5, 34)), Vector2(12.5, 34))


# --- Ereignisse -----------------------------------------------------------------------------------

func test_maus_zu_ist_eine_bewegung_mit_eigenem_geraet() -> void:
	# Act
	await _eingabe.maus_zu(Vector2(40, 30))
	await _eingabe.maus_zu(Vector2(50, 20))

	# Assert
	assert_eq(_gesendet.size(), 2)
	var zweite := _gesendet[1]["ereignis"] as InputEventMouseMotion
	assert_not_null(zweite)
	assert_eq(zweite.device, 4711)
	assert_eq(zweite.position, Vector2(50, 20))
	assert_eq(zweite.global_position, Vector2(50, 20))
	assert_eq(zweite.relative, Vector2(10, -10))
	assert_ne(_gesendet[0]["bild"], _gesendet[1]["bild"], "Jede Bewegung in ihrem Bild.")


func test_klick_bewegt_drueckt_und_laesst_im_naechsten_bild_los() -> void:
	# Act
	await _eingabe.klick(Vector2(200, 100))

	# Assert
	assert_eq(_gesendet.size(), 3)
	assert_true(_gesendet[0]["ereignis"] is InputEventMouseMotion, "Erst die Bewegung (R4).")
	var drueck := _gesendet[1]["ereignis"] as InputEventMouseButton
	var los := _gesendet[2]["ereignis"] as InputEventMouseButton
	assert_true(drueck.pressed)
	assert_false(los.pressed)
	assert_eq(drueck.button_index, MOUSE_BUTTON_LEFT)
	assert_eq(drueck.button_mask, MOUSE_BUTTON_MASK_LEFT)
	assert_eq(los.button_mask, 0)
	assert_eq(drueck.position, Vector2(200, 100))
	assert_eq(los.device, 4711)
	assert_eq(_gesendet[2]["bild"] - _gesendet[1]["bild"], 1, "Loslassen im nächsten Bild.")


func test_rechtsklick_und_rad() -> void:
	# Act
	await _eingabe.klick(Vector2(10, 10), MOUSE_BUTTON_RIGHT)
	await _eingabe.rad(Vector2(10, 10), MOUSE_BUTTON_WHEEL_DOWN)

	# Assert
	var rechts := _gesendet[1]["ereignis"] as InputEventMouseButton
	var rad := _gesendet[4]["ereignis"] as InputEventMouseButton
	assert_eq(rechts.button_index, MOUSE_BUTTON_RIGHT)
	assert_eq(rechts.button_mask, MOUSE_BUTTON_MASK_RIGHT)
	assert_eq(rad.button_index, MOUSE_BUTTON_WHEEL_DOWN)
	assert_eq(rad.button_mask, 0, "Ein Rad hält man nicht.")
	assert_eq(rad.factor, 1.0)


func test_taste_mit_umschalt_drueckt_und_laesst_los() -> void:
	# Act
	await _eingabe.taste(KEY_TAB, true)

	# Assert
	assert_eq(_gesendet.size(), 2)
	var drueck := _gesendet[0]["ereignis"] as InputEventKey
	var los := _gesendet[1]["ereignis"] as InputEventKey
	assert_eq(drueck.keycode, KEY_TAB)
	assert_eq(drueck.physical_keycode, KEY_TAB)
	assert_true(drueck.shift_pressed)
	assert_true(drueck.pressed)
	assert_false(drueck.echo)
	assert_false(los.pressed)
	assert_eq(drueck.device, 4711)
	assert_true(SelbsttestEingabe.fuer_das_spiel(drueck).is_action_pressed(&"ui_focus_prev", false,
		true), "Umschalt+Tab")
	assert_eq(_gesendet[1]["bild"] - _gesendet[0]["bild"], 1)


func test_leertaste_hat_ihr_zeichen() -> void:
	# Act
	await _eingabe.taste(KEY_SPACE)

	# Assert
	var drueck := _gesendet[0]["ereignis"] as InputEventKey
	assert_eq(drueck.unicode, 32)
	assert_true(SelbsttestEingabe.fuer_das_spiel(drueck).is_action_pressed(&"ui_accept"))


func test_gehaltene_taste_wiederholt_sich_jedes_bild() -> void:
	# Act
	var beginn := Time.get_ticks_msec()
	await _eingabe.taste_halten(KEY_RIGHT, 100)

	# Assert: erst Drücken, dann Wiederholungen, zuletzt Loslassen, frühestens nach 100 ms.
	assert_gte(Time.get_ticks_msec() - beginn, 100)
	assert_gt(_gesendet.size(), 2)
	var erstes := _gesendet[0]["ereignis"] as InputEventKey
	var letztes := _gesendet[-1]["ereignis"] as InputEventKey
	assert_true(erstes.pressed and not erstes.echo)
	assert_false(letztes.pressed)
	for index in range(1, _gesendet.size() - 1):
		var wiederholung := _gesendet[index]["ereignis"] as InputEventKey
		assert_true(wiederholung.pressed and wiederholung.echo, "Bild %d" % index)
		assert_eq(_gesendet[index]["bild"] - _gesendet[index - 1]["bild"], 1)


func test_erste_eingabe_zaehlt_ab_merke_beginn() -> void:
	# Arrange
	await _eingabe.maus_zu(Vector2(1, 1))
	_eingabe.merke_beginn()
	assert_eq(_eingabe.erste_eingabe_ms(), -1)

	# Act
	var vorher := Time.get_ticks_msec()
	await _eingabe.taste(KEY_ENTER)
	await _eingabe.taste(KEY_ENTER)

	# Assert: die erste Eingabe nach merke_beginn(), nicht die letzte
	assert_between(_eingabe.erste_eingabe_ms(), vorher, vorher + 1000)


# --- Hilfen ---------------------------------------------------------------------------------------

func _merke(ereignis: InputEvent) -> void:
	_gesendet.append({"ereignis": ereignis, "bild": Engine.get_process_frames()})
