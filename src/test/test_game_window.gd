extends GutTest

## Prüft den Fensterfaktor (FR-004, data-model.md): der größte ganzzahlige Faktor des
## Oberflächenrasters 640 × 360, der samt Titelleiste in den nutzbaren Bereich des
## Bildschirms passt, mindestens 1.
##
## Dazu die Lage: samt Titelleiste mittig im nutzbaren Bereich (Feature 007, Klaus).
##
## `best_factor()` und `centered_position()` sind reine Funktionen: Sie bekommen die Maße und
## rechnen. Die Tests brauchen deshalb weder ein Fenster noch den Autoload `GameWindow`, sie
## rufen die Funktionen am Skript auf.
##
## Alle Maße sind Bildschirmpixel. Die Titelleiste von macOS ist 28 Punkte hoch, auf einem
## Retina-Bildschirm also 56 Pixel.
##
## Seit Feature 007 (T043) dazu das Vollbild-Kürzel: Ctrl+Cmd+F, F11 und Alt+Enter schalten, und
## Alt+Enter löst im Menü nichts aus, Enter allein schon (R15; Analyse, I2). Dafür stehen ein
## echtes Hauptmenü und ein Spion aus game_window.gd (unten) in einem eigenen Viewport; die
## Tasten gehen als erfundene Ereignisse über push_input hinein, denselben Weg wie echte. Zwei
## Stellen schreiben mit: die gewählte Zeile des Menüs über ihr Signal gui_input, was die Oberfläche
## überhaupt zu sehen bekommt, und ein Lauscher mit _unhandled_input(), was weder GameWindow noch
## das Menü genommen hat.
##
## Das Vollbild selbst lässt sich ohne Fenster nicht beobachten: Headless meldet das Fenster des
## Baums immer „minimiert“, gleich welchen Modus man setzt. Statt game_window.gd steht deshalb ein
## Spion im Viewport, eine Unterklasse, die nur zählt, wie oft toggle_fullscreen() gerufen wird.
## _input() und damit der Weg des Kürzels sind die echten aus game_window.gd. Weil der Spion das
## Fenster nie anfasst, laufen die Tests auch mit echtem Fenster ohne Schaden.

const WINDOW := preload("res://core/game_window.gd")
const MENU_SCENE := preload("res://scenes/title/main_menu.tscn")


## game_window.gd ohne Fenster: zählt, statt umzuschalten.
class FensterSpion extends "res://core/game_window.gd":
	var umgeschaltet := 0

	## Ersetzt _ready() von GameWindow, ein geerbtes _ready() ruft Godot 4 nicht von selbst: keine
	## Mindestgröße, keine Fenstergröße, kein _process(). _input() bleibt an.
	func _ready() -> void:
		set_process(false)

	func toggle_fullscreen() -> void:
		umgeschaltet += 1


## Schreibt mit, was im Viewport niemand verbraucht hat.
class Lauscher extends Node:
	var ereignisse: Array[InputEvent] = []

	func _unhandled_input(event: InputEvent) -> void:
		ereignisse.append(event)


var _viewport: SubViewport
var _fenster: FensterSpion
var _menu: MainMenu
var _lauscher: Lauscher
## Was die gewählte Zeile des Menüs zu sehen bekam.
var _bei_der_oberflaeche: Array[InputEvent] = []


func test_1080p_ergibt_faktor_2() -> void:
	# Act: Die Breite ließe 3 zu, die Höhe nur (1050 − 28) / 360 = 2,8.
	var factor := WINDOW.best_factor(Vector2i(1920, 1050), _titelleiste(28))

	# Assert
	assert_eq(factor, 2, "Die Höhe begrenzt, und es wird abgerundet, nicht gerundet.")


func test_1440p_ergibt_faktor_3() -> void:
	# Act: (1410 − 28) / 360 = 3,8.
	var factor := WINDOW.best_factor(Vector2i(2560, 1410), _titelleiste(28))

	# Assert
	assert_eq(factor, 3)


func test_4k_mit_retina_titelleiste_ergibt_faktor_5() -> void:
	# Act: (2130 − 56) / 360 = 5,8.
	var factor := WINDOW.best_factor(Vector2i(3840, 2130), _titelleiste(56))

	# Assert
	assert_eq(factor, 5)


func test_macbook_bildschirm_ergibt_faktor_4() -> void:
	# Act: Hier begrenzt die Breite: 3024 / 640 = 4,7, die Höhe ließe 5 zu.
	var factor := WINDOW.best_factor(Vector2i(3024, 1890), _titelleiste(56))

	# Assert
	assert_eq(factor, 4, "Der kleinere Faktor der beiden Achsen gilt.")


func test_zu_kleine_flaeche_ergibt_faktor_1() -> void:
	# Act: Rechnerisch 0, aber kleiner als 1 wird das Fenster nie.
	var factor := WINDOW.best_factor(Vector2i(600, 300), _titelleiste(28))

	# Assert
	assert_eq(factor, 1, "Der Faktor ist immer mindestens 1.")


# --- Lage im nutzbaren Bereich -------------------------------------------

func test_4k_mit_dock_steht_samt_titelleiste_mittig_im_nutzbaren_bereich() -> void:
	# Arrange: gemessen am Mac (Feature 007): 3840 × 2160, Menüleiste 60, Dock unten, also nutzbar
	# ab y 60 mit 1914 Höhe; Fläche 3200 × 1800 bei Faktor 5, Titelleiste 64.
	var nutzbar := Rect2i(0, 60, 3840, 1914)
	var rahmen := Vector2i(3200, 1864)

	# Act
	var lage := WINDOW.centered_position(nutzbar, rahmen, _titelleiste(64))

	# Assert: Rahmen oben bei 60 + (1914 − 1864) / 2 = 85, die Fläche 64 darunter.
	assert_eq(lage, Vector2i(320, 149))


func test_der_rest_eines_ungeraden_randes_faellt_nach_links_oben() -> void:
	# Act
	var lage := WINDOW.centered_position(Rect2i(10, 25, 1281, 781), Vector2i(1280, 776),
		_titelleiste(56))

	# Assert
	assert_eq(lage, Vector2i(10, 83), "Je ein halbes Pixel Rest bleibt rechts und unten.")


func test_ist_der_rahmen_zu_gross_steht_er_links_oben_im_nutzbaren_bereich() -> void:
	# Act: Faktor 1 passt nicht einmal; die Titelleiste muss trotzdem erreichbar bleiben.
	var lage := WINDOW.centered_position(Rect2i(0, 50, 600, 300), Vector2i(640, 416),
		_titelleiste(56))

	# Assert
	assert_eq(lage, Vector2i(0, 106))


# --- Vollbild-Kürzel ------------------------------------------------------

func test_alt_enter_im_menue_schaltet_nur_das_vollbild() -> void:
	await _baue_buehne()
	watch_signals(_menu)

	# Act
	_taste(KEY_ENTER, {"alt": true})

	# Assert
	assert_eq(_fenster.umgeschaltet, 1, "Alt+Enter schaltet das Vollbild.")
	assert_eq(_bei_der_oberflaeche.size(), 0,
		"GameWindow fängt das Kürzel in _input() ab, bevor die Oberfläche es sieht.")
	assert_signal_emit_count(_menu, "entry_activated", 0,
		"Der gewählte Eintrag „Beenden“ löst nicht aus.")
	assert_eq(_lauscher.ereignisse.size(), 0,
		"Drücken und Loslassen gelten als behandelt; niemand sonst sieht sie.")


func test_enter_allein_loest_aus_und_schaltet_nicht() -> void:
	await _baue_buehne()
	watch_signals(_menu)

	# Act
	_taste(KEY_ENTER)

	# Assert
	assert_signal_emitted_with_parameters(_menu, "entry_activated", [&"quit"])
	assert_eq(_fenster.umgeschaltet, 0, "Enter allein ist nicht das Kürzel.")


func test_jeder_druck_schaltet_einmal() -> void:
	await _baue_buehne()

	# Act: hin und zurück
	_taste(KEY_ENTER, {"alt": true})
	_taste(KEY_ENTER, {"alt": true})

	# Assert
	assert_eq(_fenster.umgeschaltet, 2, "Zweimal Alt+Enter, zweimal geschaltet; Loslassen schaltet nicht.")


func test_f11_schaltet() -> void:
	await _baue_buehne()

	# Act
	_taste(KEY_F11)

	# Assert
	assert_eq(_fenster.umgeschaltet, 1)
	assert_eq(_bei_der_oberflaeche.size(), 0, "Die Oberfläche sieht F11 nicht.")
	assert_eq(_lauscher.ereignisse.size(), 0, "F11 gilt als behandelt.")


func test_ctrl_cmd_f_schaltet_weiter() -> void:
	await _baue_buehne()

	# Act
	_taste(KEY_F, {"ctrl": true, "meta": true})

	# Assert
	assert_eq(_fenster.umgeschaltet, 1, "Das Kürzel von macOS bleibt.")


func test_andere_zusatztasten_schalten_nicht() -> void:
	await _baue_buehne()
	watch_signals(_menu)

	# Act: genauer Vergleich der Zusatztasten, also zählt eine zu viel wie eine zu wenig.
	_taste(KEY_ENTER, {"alt": true, "shift": true})
	_taste(KEY_F, {"ctrl": true})
	_taste(KEY_F11, {"shift": true})

	# Assert
	assert_eq(_fenster.umgeschaltet, 0, "Nur genau die drei Kürzel schalten.")
	assert_signal_emit_count(_menu, "entry_activated", 0,
		"Shift+Alt+Enter löst auch im Menü nichts aus.")


func test_halten_schaltet_nur_einmal() -> void:
	await _baue_buehne()

	# Act: F11 drücken, zweimal die Wiederholung beim Halten, dann loslassen.
	_viewport.push_input(_ereignis(KEY_F11, true, {}))
	for _i in 2:
		var wiederholung := _ereignis(KEY_F11, true, {})
		wiederholung.echo = true
		_viewport.push_input(wiederholung)
	_viewport.push_input(_ereignis(KEY_F11, false, {}))

	# Assert
	assert_eq(_fenster.umgeschaltet, 1, "Einmal geschaltet, nicht dreimal.")
	assert_eq(_lauscher.ereignisse.size(), 0, "Auch Wiederholung und Loslassen gelten als behandelt.")


# --- Helfer ---------------------------------------------------------------

## Die Fensterdekoration unter macOS: nur oben eine Titelleiste, links und rechts kein Rand.
func _titelleiste(hoehe: int) -> Vector2i:
	return Vector2i(0, hoehe)


## Baut die Bühne für die Tests des Kürzels: ein eigener Viewport mit Lauscher, Hauptmenü und dem
## Spion. Der Spion hängt im Viewport, damit push_input() sein _input() erreicht. Gewählt ist
## „Beenden“, der einzige verfügbare Eintrag.
func _baue_buehne() -> void:
	_viewport = SubViewport.new()
	add_child_autofree(_viewport)
	_lauscher = Lauscher.new()
	_viewport.add_child(_lauscher)
	_menu = MENU_SCENE.instantiate() as MainMenu
	_menu.entries = _eintraege()
	_viewport.add_child(_menu)
	_fenster = FensterSpion.new()
	_viewport.add_child(_fenster)
	# Die Startauswahl des Menüs kommt zeitversetzt (call_deferred).
	await wait_process_frames(1)
	_menu.select(-1)
	_bei_der_oberflaeche.clear()
	var zeile := _viewport.gui_get_focus_owner()
	zeile.gui_input.connect(func(ereignis: InputEvent) -> void: _bei_der_oberflaeche.append(ereignis))


## Drückt [param taste] und lässt sie los, mit den Zusatztasten aus [param mods] (alt, shift, ctrl,
## meta). Beim Loslassen sind die Zusatztasten noch gedrückt, wie bei einer echten Hand.
func _taste(taste: Key, mods: Dictionary = {}) -> void:
	for gedrueckt: bool in [true, false]:
		_viewport.push_input(_ereignis(taste, gedrueckt, mods))


func _ereignis(taste: Key, gedrueckt: bool, mods: Dictionary) -> InputEventKey:
	var ereignis := InputEventKey.new()
	ereignis.keycode = taste
	ereignis.physical_keycode = taste
	ereignis.alt_pressed = mods.get("alt", false)
	ereignis.shift_pressed = mods.get("shift", false)
	ereignis.ctrl_pressed = mods.get("ctrl", false)
	ereignis.meta_pressed = mods.get("meta", false)
	ereignis.pressed = gedrueckt
	return ereignis


## Zwei Einträge: „Neues Spiel“ gesperrt, „Beenden“ verfügbar.
func _eintraege() -> Array[MenuEntry]:
	var neues_spiel := MenuEntry.new()
	neues_spiel.id = &"new_game"
	neues_spiel.label = "Neues Spiel"
	neues_spiel.hint = "Der Laden hat noch zu."
	var beenden := MenuEntry.new()
	beenden.id = &"quit"
	beenden.label = "Beenden"
	beenden.available = true
	beenden.hint = "Laden abschließen und zurück zum Desktop."
	return [neues_spiel, beenden]
