extends GutTest

## Prüft den Spielbildschirm (Feature 004, T021; contracts/titelbildschirm.md, „GameScreen“ und
## „Tests“; Style-Guide, „Bildaufbau“ und Baustein Knopf): Grund nacht, der Knopf „Zum Hauptmenü“
## in der Mitte mit Fokus und Hinweis links daneben, Esc tut nichts, der Knopf speichert und führt
## über scene_callback zum Titel, und scheitert das Speichern, steht die Meldung neben dem Knopf,
## auch schon beim Erscheinen nach einem gescheiterten Speichern beim Fortsetzen (FR-019, FR-020,
## FR-011).
##
## Wie test_title_screen.gd: eigene Uhr, eigene Zeitleiste mit Test-Katalog, eigene GameSession mit
## dem Ordner ORDNER und ein eigener scene_callback, der nur mitschreibt; der Bildschirm steht in
## einem eigenen Viewport von 640 × 360. Speichern scheitert ohne Hilfe im Code (R16): Ein Ordner
## mit Inhalt an der Stelle der .neu lässt sich weder löschen noch beschreiben.

const SPIELBILDSCHIRM := preload("res://scenes/game/game_screen.tscn")
const SITZUNG := preload("res://core/game_session.gd")
const ZEITLEISTE := preload("res://core/timeline.gd")
const UHR := preload("res://core/game_clock.gd")
const WURZEL := "user://test_game_screen/"
const ORDNER := "user://test_game_screen/spielstaende/"
const KATALOGE := "res://test/fixtures/"
const TITEL := "res://scenes/title/title_screen.tscn"
## 26.10.2026, 20:40:12 UTC
const ANGELEGT := 1793047212
## Style-Guide, „Bildaufbau“: der Knopf „Zum Hauptmenü“, 101 × 20 bei x 270, y 170.
const KNOPF := Rect2(270, 170, 101, 20)
## Style-Guide, Baustein Knopf: ein Pixel Luft, dann die Fokuslinie, ihre linke Kante bei x 268.
const FOKUSLINIE_LINKS := 268.0
## Style-Guide, Baustein Hinweis: Der Hinweis endet 4 Pixel vor der Fokuslinie.
const HINWEIS_RECHTS := 264.0

const LAEUFT_WEITER := "Speichern ging nicht. Dein Spiel läuft weiter."

var _bildschirm: GameScreen
var _sitzung: SITZUNG
## Die Pfade, mit denen der Bildschirm scene_callback aufgerufen hat.
var _wechsel: Array = []
var _auto_accept_quit_vorher := true


func before_each() -> void:
	_raeume_auf(WURZEL)
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_wechsel.clear()
	_auto_accept_quit_vorher = get_tree().auto_accept_quit
	_sitzung = await _neue_sitzung()


func after_each() -> void:
	get_tree().auto_accept_quit = _auto_accept_quit_vorher
	_raeume_auf(WURZEL)


# --- Aufbau (FR-019) ------------------------------------------------------------------------------

func test_grund_nacht_und_der_knopf_in_der_mitte() -> void:
	# Arrange
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)

	# Act
	await _zeige_bildschirm()

	# Assert
	var grund := _bildschirm.get_node(^"Background") as ColorRect
	assert_eq(grund.color, UiPalette.NACHT, "Vollbild in nacht.")
	assert_eq(grund.get_global_rect(), Rect2(0, 0, 640, 360))
	assert_eq(_knopf().get_global_rect(), KNOPF, "In der Mitte, 101 × 20.")
	assert_eq(_knopf().text, "Zum Hauptmenü")
	assert_true(_knopf().on_dark, "Auf nacht ist die Fokuslinie papier.")


func test_der_knopf_hat_den_fokus_und_daneben_steht_sein_hinweis() -> void:
	# Arrange
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)

	# Act
	await _zeige_bildschirm()

	# Assert
	assert_eq(_bildschirm.get_viewport().gui_get_focus_owner(), _knopf(), "Fokus von Anfang an.")
	assert_true(_knopf().has_focus(true), "Der Fokus ist zu sehen, mit Fokuslinie.")
	assert_true(_hinweis().visible)
	assert_eq(_hinweis_text(), "Speichert Spiel 1 und führt ins Hauptmenü.")
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	_assert_links_neben_dem_knopf()


# --- Esc (FR-020) ---------------------------------------------------------------------------------

func test_esc_tut_nichts() -> void:
	# Arrange
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	await _zeige_bildschirm()

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	assert_eq(_wechsel, [])
	assert_true(_sitzung.is_running(), "Das Spiel läuft weiter.")
	assert_eq(_bildschirm.get_viewport().gui_get_focus_owner(), _knopf())
	assert_eq(_hinweis_text(), "Speichert Spiel 1 und führt ins Hauptmenü.")


# --- Verlassen (FR-020, FR-010) -------------------------------------------------------------------

func test_enter_speichert_und_fuehrt_zum_titel() -> void:
	# Arrange: Das Spiel steht am 15.02.1985.
	assert_eq(_sitzung.start_new(Difficulty.Level.SCHWER, 4711), OK)
	_vorspulen(_tag(1985, 2, 15))
	await _zeige_bildschirm()
	var szene_vorher := get_tree().current_scene

	# Act
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [TITEL], "Einmal zum Titel.")
	assert_eq(get_tree().current_scene, szene_vorher, "Gewechselt wird nur über scene_callback.")
	assert_false(_sitzung.is_running(), "Das Spiel ist beendet.")
	var slot := SaveSlot.read(ORDNER.path_join("spiel_1.json"), 1)
	assert_eq(slot.state, SaveSlot.State.OK, slot.reason)
	assert_eq(slot.game.day_text(), "15.02.1985", "Gespeichert mit dem Tag der Uhr.")


func test_leertaste_und_klick_loesen_ebenso_aus() -> void:
	# Arrange
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	await _zeige_bildschirm()

	# Act: Leertaste
	await _taste(KEY_SPACE)
	var nach_leertaste := _wechsel.duplicate()
	# Act: ein zweites Spiel, Klick mit der Maus
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	await _zeige_bildschirm()
	_wechsel.clear()
	var mitte := _knopf().get_global_rect().get_center()
	await _maus_nach(mitte)
	await _klick(mitte)

	# Assert
	assert_eq(nach_leertaste, [TITEL], "Die Leertaste löst aus.")
	assert_eq(_wechsel, [TITEL], "Ein Klick löst aus.")
	assert_false(_sitzung.is_running())


func test_speichern_scheitert_dann_meldung_und_das_spiel_laeuft_weiter() -> void:
	# Arrange (FR-011)
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	await _zeige_bildschirm()
	_hindernis(1)

	# Act
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [], "Kein Wechsel, das Spiel läuft weiter.")
	assert_true(_sitzung.is_running())
	assert_eq(_hinweis_text(), LAEUFT_WEITER)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel", "Kontur kassenrot.")
	_assert_links_neben_dem_knopf()
	assert_eq(_bildschirm.get_viewport().gui_get_focus_owner(), _knopf(), "Der Fokus bleibt.")
	assert_push_warning("Spielstand 1: Speichern: Schritt 1")


func test_nach_der_meldung_gelingt_der_zweite_versuch() -> void:
	# Arrange
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	await _zeige_bildschirm()
	_hindernis(1)
	await _taste(KEY_ENTER)
	_hindernis_weg(1)

	# Act
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [TITEL])
	assert_false(_sitzung.is_running())
	assert_eq(_sitzung.last_error, "")


func test_save_failed_zeigt_die_meldung() -> void:
	# Arrange: Gespeichert wird hier auch ohne den Knopf, etwa später automatisch.
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	await _zeige_bildschirm()
	_hindernis(1)

	# Act
	_sitzung.save()

	# Assert
	assert_eq(_hinweis_text(), LAEUFT_WEITER)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel")
	_assert_links_neben_dem_knopf()
	assert_push_warning("Spielstand 1: Speichern: Schritt 1")


func test_meldung_beim_erscheinen_nach_gescheitertem_speichern_beim_fortsetzen() -> void:
	# Arrange (Analyse, F5): ein Spielstand, an der Stelle seiner .neu ein Ordner mit Inhalt. Das
	# Signal save_failed kommt beim Fortsetzen, bevor der Spielbildschirm da ist.
	assert_eq(_sitzung.start_new(Difficulty.Level.LEICHT, 4711), OK)
	assert_eq(_sitzung.leave(), OK)
	_hindernis(1)
	assert_eq(_sitzung.resume(_sitzung.store().list_slots()[0]), OK)

	# Act
	await _zeige_bildschirm()

	# Assert
	assert_true(_sitzung.is_running(), "Das Spiel läuft trotzdem.")
	assert_eq(_hinweis_text(), LAEUFT_WEITER)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel")
	_assert_links_neben_dem_knopf()
	assert_push_warning("Spielstand 1: Speichern: Schritt 1")


# --- Helfer ---------------------------------------------------------------------------------------

## Baut den Spielbildschirm in einem eigenen Viewport mit der Session des Tests.
func _zeige_bildschirm() -> void:
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	_bildschirm = SPIELBILDSCHIRM.instantiate() as GameScreen
	_bildschirm.session = _sitzung
	_bildschirm.scene_callback = func(pfad: String) -> void: _wechsel.append(pfad)
	eigener_viewport.add_child(_bildschirm)
	await wait_process_frames(1)


func _neue_sitzung() -> SITZUNG:
	var uhr := UHR.new()
	add_child_autofree(uhr)
	var zeitleiste := ZEITLEISTE.new()
	zeitleiste.catalog_path = KATALOGE + "catalog_us1_grade.json"
	zeitleiste.clock = uhr
	add_child_autofree(zeitleiste)
	var sitzung := SITZUNG.new()
	sitzung.folder = ORDNER
	sitzung.clock = uhr
	sitzung.timeline = zeitleiste
	sitzung.now = func() -> int: return ANGELEGT
	sitzung.rng = RandomNumberGenerator.new()
	sitzung.rng.seed = 20261026
	sitzung.quit_callback = func() -> void: pass
	add_child_autofree(sitzung)
	await wait_process_frames(2)
	return sitzung


func _knopf() -> Knopf:
	return _bildschirm.get_node(^"LeaveButton") as Knopf


func _hinweis() -> MenuHint:
	return _bildschirm.get_node(^"MenuHint") as MenuHint


func _hinweis_text() -> String:
	assert_true(_hinweis().visible, "Der Hinweis ist zu sehen.")
	return (_hinweis().get_node(^"Text") as Label).text


## Hinweis oder Meldung stehen links neben dem Knopf, oben bündig, und 4 Pixel vor seiner
## Fokuslinie, nicht vor seiner Kontur: Der Knopf hat den Fokus von Anfang an (Style-Guide, Baustein
## Hinweis). Die Fokuslinie liegt bei x 268, die rechte Kante des Hinweises also bei x 264.
func _assert_links_neben_dem_knopf() -> void:
	var rechte_kante := _hinweis().global_position.x + _hinweis().size.x
	var fokuslinie := _fokuslinie_links()
	assert_eq(_hinweis().global_position.y, KNOPF.position.y, "Oben bündig mit dem Knopf.")
	assert_eq(fokuslinie, FOKUSLINIE_LINKS, "Die Fokuslinie liegt bei x 268.")
	assert_eq(rechte_kante, fokuslinie - MenuHint.GAP, "4 Pixel vor der Fokuslinie.")
	assert_eq(rechte_kante, HINWEIS_RECHTS, "Die rechte Kante liegt bei x 264.")
	assert_true(_hinweis().global_position.x >= 0.0, "Ganz auf dem Bildschirm.")


## Die linke Kante der Fokuslinie in globalen Koordinaten, aus dem, was der Knopf malt: Die Linie
## liegt außen, ganz links ist also sie.
func _fokuslinie_links() -> float:
	assert_true(_knopf().has_focus(true), "Voraussetzung: Die Fokuslinie ist zu sehen.")
	var links := INF
	for ebene in _knopf().layers():
		links = minf(links, (ebene["rect"] as Rect2).position.x)
	return _knopf().get_global_rect().position.x + links


## Drückt [param taste] und lässt sie los, über push_input, und wartet ein Bild.
func _taste(taste: Key) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = taste
		ereignis.physical_keycode = taste
		ereignis.pressed = gedrueckt
		_bildschirm.get_viewport().push_input(ereignis)
	await wait_process_frames(1)


## Fährt mit der Maus nach [param ziel] und wartet ein Bild; true heißt: Koordinaten des Viewports.
func _maus_nach(ziel: Vector2) -> void:
	var ereignis := InputEventMouseMotion.new()
	ereignis.position = ziel
	ereignis.global_position = ziel
	_bildschirm.get_viewport().push_input(ereignis, true)
	await wait_process_frames(1)


## Klickt mit der linken Taste bei [param ziel] und wartet ein Bild.
func _klick(ziel: Vector2) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = MOUSE_BUTTON_LEFT
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_bildschirm.get_viewport().push_input(ereignis, true)
	await wait_process_frames(1)


## Schaltet die Uhr der Session Tag für Tag bis zum Tag [param bis] weiter.
func _vorspulen(bis: int) -> void:
	var uhr := _sitzung.clock as UHR
	while uhr.date.to_day_index() < bis and not uhr.is_finished():
		uhr.advance_day()


func _pfad(nummer: int) -> String:
	return ORDNER.path_join("spiel_%d.json" % nummer)


## Ein Ordner mit Inhalt an der Stelle von spiel_<nummer>.json.neu: Speichern scheitert dort in
## Schritt 1 (R16).
func _hindernis(nummer: int) -> void:
	DirAccess.make_dir_recursive_absolute(_pfad(nummer) + ".neu/inhalt")


func _hindernis_weg(nummer: int) -> void:
	_raeume_auf(_pfad(nummer) + ".neu")


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
