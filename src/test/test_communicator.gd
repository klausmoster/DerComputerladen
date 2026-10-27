extends GutTest

## Prüft den Baustein Communicator (Feature 005, T005 und T006; contracts/communicator.md).
##
## Aufbau und Seiten: Seiten aus der Szene liegen auf der Anzeige, genau eine ist zu sehen, ein
## Seitenwechsel bewegt nichts, und ein Klick auf das Gehäuse tut nichts. Als Seiten dienen
## schlichte Controls, kein Menü: Geprüft wird der Communicator, nicht, was auf ihm steht.
##
## Fahrt: Der Test taktet sie selbst, ohne await. set_process(false) hält die Engine davon ab,
## _process() zusätzlich mit echter Zeit aufzurufen, und der Tween im Communicator ist ohnehin
## angehalten. Dann ruft der Test _process() mit festen Zeitschritten und sieht die Fahrt Bild für
## Bild (Analyse, C22).
##
## Eingabe und Hinweis (T007): Während der Fahrt hinaus nimmt weder ein Menü noch eine Liste Tasten
## oder Maus an; eine Zeile, die unter dem ruhenden Zeiger durchfährt, wird nicht gewählt; der
## Hinweis steht links neben dem Gehäuse und fährt mit. Menü und Liste stehen dafür auf Papier,
## die Anzeige kommt erst in Phase 3.
##
## Probeseite (T008): die Probeszene mit drei Einträgen, bedient ohne Titelbildschirm (SC-005).
##
## Gehäusetasten (Feature 006, T026; contracts/gehaeusetasten.md, „Tests“): Die Tests geben dem
## Communicator die drei Tasten von G-03 wie später der Titel und drücken sie mit erfundenen
## Mausereignissen über push_input. Ob eine Taste eingedrückt aussieht, lässt sich headless nicht
## als Bild prüfen; geprüft werden die Rechtecke und die Farbe, die _draw_case_keys() benutzt, und
## dass Keys im nächsten Bild neu malt.
##
## Der Communicator steht wie im Titel bei (244, 92) in einem eigenen Viewport von 640 × 360,
## so groß wie das Oberflächenraster. Die Seiten hängt der Test vor dem Einhängen unter die Instanz,
## wie es ein Bildschirm in seiner Szene tut: Dann sind sie schon Kinder, wenn _ready() läuft.

const COMMUNICATOR_SCENE := preload("res://ui/communicator/communicator.tscn")
const MENU_SCENE := preload("res://scenes/title/main_menu.tscn")
const LIST_SCENE := preload("res://scenes/title/save_list.tscn")
const PROBE_SCENE_PATH := "res://test/fixtures/communicator_probe.tscn"
const PROBE_SCRIPT_PATH := "res://test/fixtures/communicator_probe.gd"
## Ein Bild bei 60 Bildern je Sekunde.
const BILD := 1.0 / 60.0
## Endlage wie im Titel (Style-Guide, Baustein Communicator, Lage im Titel).
const ENDLAGE := Vector2(244, 92)
## Anzeige des Organizers im Gehäuse (Style-Guide, Baustein Communicator).
const ANZEIGE := Rect2i(36, 28, 320, 160)
## Größe des Gehäuses G-03 auf der Oberfläche: 196 × 134 Bildpixel, genau ×2 (Style-Guide, Baustein
## Communicator).
const GEHAEUSE := Vector2(392, 268)
const GEHAEUSE_BILD := "res://assets/images/organizer_1991.png"
## Höchstens so lange nach dem ersten fahrenden Bild steht der Communicator am Ziel (SC-002).
const HOECHSTENS := 0.25
## Bildfolgen, mit denen die Fahrt laufen muss: erstes Bild, jedes weitere Bild, in Sekunden.
## 60 und 30 Bilder je Sekunde, dazu ein langes erstes Bild von 0,5 s wie beim Laden.
const BILDFOLGEN := [
	[1.0 / 60.0, 1.0 / 60.0],
	[1.0 / 30.0, 1.0 / 30.0],
	[0.5, 1.0 / 60.0],
	[0.5, 1.0 / 30.0],
]
## Mehr Bilder braucht keine Fahrt; danach gilt sie als hängengeblieben.
const HOECHSTENS_BILDER := 200
## Die drei grauen Tasten von G-03 in Bildpixeln des Gehäuses, einschließlich gezählt: x 140 bis
## 150, 154 bis 165, 169 bis 180, je y 114 bis 121 (Style-Guide, Baustein Communicator, Gehäusetasten).
const TASTEN: Array[Rect2i] = [Rect2i(140, 114, 11, 8), Rect2i(154, 114, 12, 8),
	Rect2i(169, 114, 12, 8)]
## Dieselben Tasten auf der Oberfläche, im Titel: ab 524/320, 552/320, 582/320 (Style-Guide).
const TASTEN_IM_TITEL: Array[Rect2] = [Rect2(524, 320, 22, 16), Rect2(552, 320, 24, 16),
	Rect2(582, 320, 24, 16)]
const KLICK := "res://assets/sounds/knopf.wav"

var _buehne: Control
var _communicator: Communicator
var _seite_a: Control
var _seite_b: Control
## Was slide_finished gemeldet hat, in der Reihenfolge der Meldungen.
var _meldungen: Array[bool] = []


func before_each() -> void:
	# Ein eigener Viewport wie in test_main_menu.gd: eigene Eingabe, eigener Fokus, und GUTs
	# Oberfläche im Haupt-Viewport fängt keinen Klick ab.
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	# Die Bühne liegt unter dem Communicator wie ein Hintergrundbild und nimmt die Maus an.
	_buehne = Control.new()
	_buehne.size = Vector2(640, 360)
	eigener_viewport.add_child(_buehne)
	_communicator = COMMUNICATOR_SCENE.instantiate() as Communicator
	_communicator.position = ENDLAGE
	_seite_a = _seite("SeiteA")
	_seite_b = _seite("SeiteB")
	_communicator.add_child(_seite_a)
	_communicator.add_child(_seite_b)
	_buehne.add_child(_communicator)
	# Die Maus steht im Viewport. Ohne diese Meldung gibt ein Viewport Mausbewegungen nicht an
	# gui_input weiter (wie in test_save_list.gd).
	eigener_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	# Erst nach dem Einhängen: In _ready() schaltet Godot _process() ein, weil das Skript es hat.
	_communicator.set_process(false)
	_meldungen.clear()
	_communicator.slide_finished.connect(func(drin: bool) -> void: _meldungen.append(drin))


# --- Aufbau ---------------------------------------------------------------

func test_teile_in_der_richtigen_reihenfolge() -> void:
	# Act
	var namen := _communicator.get_children().map(func(kind: Node) -> String: return kind.name)

	# Assert: Gehäuse, Anzeige, Hinweis, Gehäusetasten und ihr Klick (Feature 006), danach die
	# Seiten, die also über der Anzeige liegen.
	assert_eq(namen, ["Case", "Display", "Hint", "Keys", "KeyClick", "SeiteA", "SeiteB"])
	assert_true(_communicator.get_node(^"Hint") is MenuHint, "Der Hinweis ist ein MenuHint.")
	assert_false((_communicator.get_node(^"Hint") as Control).visible,
		"Der Hinweis ist zu Beginn nicht zu sehen.")


func test_anzeige_hat_lage_und_farbe_des_organizers() -> void:
	# Arrange
	var anzeige := _communicator.get_node(^"Display") as ColorRect

	# Assert
	assert_eq(_communicator.display_rect, ANZEIGE, "Vorgabe ist die Anzeige des Organizers.")
	assert_eq(Vector2i(_communicator.display_rect.size), Communicator.DISPLAY_SIZE)
	assert_eq(Rect2i(anzeige.get_rect()), ANZEIGE, "Die Anzeige steht auf display_rect.")
	assert_eq(_communicator.display_color, UiPalette.LCD, "Vorgabe ist lcd.")
	assert_eq(anzeige.color, UiPalette.LCD, "Die Anzeige hat die Farbe display_color.")


func test_lage_und_farbe_der_anzeige_sind_je_gehaeuse_einstellbar() -> void:
	# Arrange: ein anderes Gehäuse mit der Anzeige an anderer Stelle und in anderer Farbe.
	var anderswo := Rect2i(Vector2i(32, 40), Communicator.DISPLAY_SIZE)
	var anzeige := _communicator.get_node(^"Display") as ColorRect

	# Act
	_communicator.display_rect = anderswo
	_communicator.display_color = UiPalette.ANZEIGE_GRUND

	# Assert: Anzeige und Seiten ziehen mit.
	assert_eq(Rect2i(anzeige.get_rect()), anderswo)
	assert_eq(anzeige.color, UiPalette.ANZEIGE_GRUND)
	assert_eq(Rect2i(_seite_a.get_rect()), anderswo, "Die Seite zieht mit der Anzeige um.")
	assert_eq(Rect2i(_seite_b.get_rect()), anderswo)


func test_gehaeuse_ist_g03_genau_doppelt() -> void:
	# Arrange
	var gehaeuse := _communicator.get_node(^"Case") as TextureRect
	var bild := gehaeuse.texture

	# Act: die Fläche, die das Gehäuse auf der Oberfläche bedeckt, mit Skalierung.
	var flaeche := gehaeuse.get_transform() * Rect2(Vector2.ZERO, gehaeuse.size)

	# Assert: genau ×2, nicht auf eine feste Größe gezogen (Phasenprüfung Phase 2, Befund 2).
	assert_eq(bild.resource_path, GEHAEUSE_BILD, "Das Gehäuse ist G-03.")
	assert_eq(bild.get_size(), Vector2(196, 134), "196 × 134 Bildpixel.")
	assert_eq(gehaeuse.stretch_mode, TextureRect.STRETCH_KEEP, "Das Bild wird nicht gezogen.")
	assert_eq(gehaeuse.size, bild.get_size(), "Case ist so groß wie das Bild.")
	assert_eq(gehaeuse.scale, Vector2(2, 2), "Genau ×2 auf das Oberflächenraster.")
	assert_eq(flaeche, Rect2(Vector2.ZERO, bild.get_size() * 2), "Es bedeckt 392 × 268.")
	assert_eq(_communicator.size, GEHAEUSE, "Der Communicator ist so groß wie das Gehäuse.")
	assert_eq(flaeche.size, _communicator.size)
	assert_eq(gehaeuse.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "Pixel bleiben scharf.")


func test_platzhalter_ohne_bild_in_gehaeuse_mit_kontur_tusche() -> void:
	# Act: Ein Gehäuse ohne Bild bekäme den Platzhalter. Headless entsteht kein Bild; geprüft wird
	# die Liste der Rechtecke, die _draw() dann malt.
	var ebenen := Communicator._placeholder_layers(Rect2(Vector2.ZERO, GEHAEUSE))

	# Assert
	assert_eq(ebenen.size(), 5, "Fläche und vier Kanten.")
	assert_eq(ebenen[0], {"rect": Rect2(Vector2.ZERO, GEHAEUSE), "color": UiPalette.GEHAEUSE},
		"Die Fläche ist gehaeuse.")
	for kante: Dictionary in ebenen.slice(1):
		var rechteck: Rect2 = kante["rect"]
		assert_eq(kante["color"], UiPalette.TUSCHE, "Die Kontur ist tusche.")
		assert_eq(minf(rechteck.size.x, rechteck.size.y), 1.0, "Die Kontur ist 1 Pixel breit.")
		assert_true(Rect2(Vector2.ZERO, GEHAEUSE).encloses(rechteck), "Die Kontur liegt innen.")


# --- Seiten ---------------------------------------------------------------

func test_seiten_aus_der_szene_liegen_auf_der_anzeige() -> void:
	for seite: Control in [_seite_a, _seite_b]:
		assert_eq(seite.get_parent(), _communicator, "%s bleibt ein Kind." % seite.name)
		assert_eq(Rect2i(seite.get_rect()), ANZEIGE,
			"%s hat Lage und Größe der Anzeige, nicht mehr die eigene." % seite.name)
		assert_false(seite.visible, "%s ist verborgen, bis der Bildschirm sie zeigt." % seite.name)
	assert_null(_communicator.current_page(), "Zu Beginn ist keine Seite zu sehen.")


func test_seite_behaelt_lage_und_groesse() -> void:
	# Arrange
	_communicator.show_page(_seite_a)

	# Act: ein Bild abwarten, in dem Godot das Layout anordnet.
	await wait_process_frames(1)

	# Assert
	assert_eq(Rect2i(_seite_a.get_rect()), ANZEIGE, "Die Seite bleibt auf der Anzeige.")


func test_show_page_stellt_eine_geschrumpfte_seite_zurueck() -> void:
	# Arrange: Die Seite setzt ihre Größe selbst, etwa wie ein Menü auf Papier.
	_seite_a.size = Vector2(144, 100)

	# Act
	_communicator.show_page(_seite_a)

	# Assert
	assert_eq(Rect2i(_seite_a.get_rect()), ANZEIGE)


func test_add_page_haengt_eine_neue_seite_als_letztes_kind_an() -> void:
	# Arrange
	var neu := _seite("SeiteC")

	# Act
	_communicator.add_page(neu)

	# Assert
	assert_eq(neu.get_parent(), _communicator)
	assert_eq(neu.get_index(), _communicator.get_child_count() - 1, "Als letztes Kind.")
	assert_eq(Rect2i(neu.get_rect()), ANZEIGE)
	assert_false(neu.visible, "Auch eine neue Seite ist erst verborgen.")


func test_show_page_zeigt_genau_eine_seite() -> void:
	# Act und Assert
	_communicator.show_page(_seite_a)
	assert_eq([_seite_a.visible, _seite_b.visible], [true, false])
	assert_eq(_communicator.current_page(), _seite_a)

	_communicator.show_page(_seite_b)
	assert_eq([_seite_a.visible, _seite_b.visible], [false, true])
	assert_eq(_communicator.current_page(), _seite_b)


func test_show_page_bewegt_nichts() -> void:
	# Arrange
	var vorher := _communicator.position
	watch_signals(_communicator)

	# Act
	_communicator.show_page(_seite_a)
	_communicator.show_page(_seite_b)
	_communicator._process(1.0 / 60.0)

	# Assert
	assert_eq(_communicator.position, vorher, "Ein Seitenwechsel bewegt den Communicator nicht.")
	assert_signal_not_emitted(_communicator, "slide_finished", "Ein Seitenwechsel ist keine Fahrt.")


# --- Maus -----------------------------------------------------------------

func test_alles_ausser_den_seiten_laesst_die_maus_durch() -> void:
	for pfad: NodePath in [^".", ^"Case", ^"Display", ^"Hint"]:
		var teil := _communicator.get_node(pfad) as Control
		assert_eq(teil.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s lässt die Maus durch." % pfad)
		assert_eq(teil.mouse_default_cursor_shape, Control.CURSOR_ARROW,
			"%s zeigt den Pfeil, keine Hand." % pfad)


func test_klick_aufs_gehaeuse_tut_nichts() -> void:
	# Arrange: Seite A ist zu sehen, ihr Knopf hat den Fokus.
	_communicator.show_page(_seite_a)
	var knopf := _seite_a.get_node(^"Knopf") as Button
	knopf.grab_focus()
	watch_signals(knopf)
	watch_signals(_buehne)
	# Zwei Stellen auf dem Gehäuse außerhalb der Anzeige: der Rand oben links und unten die Stelle,
	# an der später die Tastatur ist.
	var stellen := [ENDLAGE + Vector2(4, 4), ENDLAGE + Vector2(8, 240)]

	for stelle: Vector2 in stellen:
		# Act
		_maus_nach(stelle)
		_klick(stelle)

	# Assert
	assert_signal_not_emitted(knopf, "pressed", "Ein Klick aufs Gehäuse löst nichts aus.")
	assert_eq(_buehne.get_viewport().gui_get_focus_owner(), knopf, "Der Fokus bleibt, wo er war.")
	assert_signal_emitted(_buehne, "gui_input",
		"Der Klick geht durch das Gehäuse an das, was darunter liegt.")


# --- Fahrt: Lagen (SC-003) ------------------------------------------------

func test_fahrt_herein_auf_ganzen_pixeln_und_nie_ueber_die_endlage() -> void:
	for bildfolge: Array in BILDFOLGEN:
		# Arrange
		_communicator.place_hidden()

		# Act
		_communicator.slide_in()
		var lagen := _fahre(bildfolge[0], bildfolge[1])

		# Assert
		var folge := _name(bildfolge)
		assert_eq(lagen.back(), ENDLAGE.y, "%s: am Ende in der Endlage." % folge)
		var vorige := Communicator.HIDDEN_Y
		for lage: float in lagen:
			assert_eq(lage, roundf(lage), "%s: %s ist kein ganzes Pixel." % [folge, lage])
			assert_gte(lage, ENDLAGE.y, "%s: %s liegt über der Endlage." % [folge, lage])
			assert_lte(lage, vorige, "%s: Bei %s fährt er zurück." % [folge, lage])
			vorige = lage
		assert_eq(_communicator.position.x, ENDLAGE.x, "%s: x bleibt." % folge)


func test_fahrt_hinaus_auf_ganzen_pixeln_und_nie_unter_den_bildrand() -> void:
	for bildfolge: Array in BILDFOLGEN:
		# Arrange
		_stelle_in_die_endlage()

		# Act
		_communicator.slide_out()
		var lagen := _fahre(bildfolge[0], bildfolge[1])

		# Assert
		var folge := _name(bildfolge)
		assert_eq(lagen.back(), Communicator.HIDDEN_Y, "%s: am Ende draußen." % folge)
		var vorige := ENDLAGE.y
		for lage: float in lagen:
			assert_eq(lage, roundf(lage), "%s: %s ist kein ganzes Pixel." % [folge, lage])
			assert_lte(lage, Communicator.HIDDEN_Y, "%s: %s liegt unter dem Ziel." % [folge, lage])
			assert_gte(lage, vorige, "%s: Bei %s fährt er zurück." % [folge, lage])
			vorige = lage


func test_place_hidden_stellt_die_oberkante_an_den_bildrand() -> void:
	# Act
	_communicator.place_hidden()

	# Assert
	assert_eq(_communicator.get_global_rect().position.y, 360.0, "Draußen: Oberkante bei y 360.")
	assert_false(_communicator.is_in())
	assert_eq(_meldungen, [] as Array[bool], "place_hidden() ist keine Fahrt und meldet nichts.")


func test_ungerade_endlage_meldet_eine_warnung() -> void:
	# Arrange
	var schief := COMMUNICATOR_SCENE.instantiate() as Communicator
	schief.position = Vector2(201, 97)

	# Act
	_buehne.add_child(schief)

	# Assert: Die Endlage muss auf ganzen Bildpixeln liegen, also auf geraden Lagen.
	assert_push_warning("nicht auf ganzen Bildpixeln")
	assert_true(Communicator._on_image_grid(ENDLAGE), "(244, 92) liegt auf dem Bildraster.")
	assert_false(Communicator._on_image_grid(Vector2(244, 93)), "y 93 ist ungerade.")
	assert_false(Communicator._on_image_grid(Vector2(201, 92)), "x 201 ist ungerade.")
	schief.queue_free()


# --- Fahrt: Dauer (SC-002) ------------------------------------------------

func test_endlage_nach_hoechstens_250_ms() -> void:
	for bildfolge: Array in BILDFOLGEN:
		# Arrange
		_communicator.place_hidden()

		# Act
		_communicator.slide_in()
		var bilder := _fahre(bildfolge[0], bildfolge[1]).size()

		# Assert
		var dauer := _gezaehlte_dauer(bildfolge, bilder)
		assert_lte(dauer, HOECHSTENS, "%s: %d Bilder, %.3f s." % [_name(bildfolge), bilder, dauer])


func test_draussen_nach_hoechstens_250_ms() -> void:
	for bildfolge: Array in BILDFOLGEN:
		# Arrange
		_stelle_in_die_endlage()

		# Act
		_communicator.slide_out()
		var bilder := _fahre(bildfolge[0], bildfolge[1]).size()

		# Assert
		var dauer := _gezaehlte_dauer(bildfolge, bilder)
		assert_lte(dauer, HOECHSTENS, "%s: %d Bilder, %.3f s." % [_name(bildfolge), bilder, dauer])


func test_im_ersten_bild_hoechstens_ein_viertel_des_wegs() -> void:
	var weg := Communicator.HIDDEN_Y - ENDLAGE.y
	for erstes: float in [1.0 / 60.0, 1.0 / 30.0, 0.5]:
		# Arrange und Act: herein, mit EASE_OUT am Anfang am schnellsten.
		_communicator.place_hidden()
		_communicator.slide_in()
		_communicator._process(erstes)
		var herein := Communicator.HIDDEN_Y - _communicator.position.y
		# Arrange und Act: hinaus aus der Endlage.
		_fahre(1.0 / 60.0, 1.0 / 60.0)
		_communicator.slide_out()
		_communicator._process(erstes)
		var hinaus := _communicator.position.y - ENDLAGE.y
		_fahre(1.0 / 60.0, 1.0 / 60.0)

		# Assert
		assert_gt(herein, 0.0, "Erstes Bild %.3f s: Die Fahrt herein beginnt sofort." % erstes)
		assert_lte(herein, weg / 4.0,
			"Erstes Bild %.3f s: herein %d von %d Pixeln." % [erstes, herein, weg])
		assert_lte(hinaus, weg / 4.0,
			"Erstes Bild %.3f s: hinaus %d von %d Pixeln." % [erstes, hinaus, weg])


# --- Fahrt: Umkehr --------------------------------------------------------

func test_umkehr_herein_nach_hinaus_ohne_sprung() -> void:
	# Arrange: aus draußen ein Stück herein.
	_communicator.place_hidden()
	_communicator.slide_in()
	for _bild in 4:
		_communicator._process(1.0 / 60.0)
	var vorher := _communicator.position.y

	# Act
	_communicator.slide_out()
	var gleich_danach := _communicator.position.y
	var lagen := _fahre(1.0 / 60.0, 1.0 / 60.0)

	# Assert
	assert_between(vorher, ENDLAGE.y + 1, Communicator.HIDDEN_Y - 1, "Voraussetzung: unterwegs.")
	assert_eq(gleich_danach, vorher, "Die Umkehr beginnt in der jetzigen Lage.")
	assert_lte(lagen[0] - vorher, (Communicator.HIDDEN_Y - vorher) / 4.0,
		"Im ersten Bild nach der Umkehr kein Sprung.")
	var vorige := vorher
	for lage: float in lagen:
		assert_eq(lage, roundf(lage), "%s ist kein ganzes Pixel." % lage)
		assert_gte(lage, vorige, "Bei %s fährt er wieder herein." % lage)
		vorige = lage
	assert_eq(lagen.back(), Communicator.HIDDEN_Y)
	assert_false(_communicator.is_in())
	assert_eq(_meldungen, [false] as Array[bool], "Nur die Fahrt hinaus meldet sich, einmal.")


func test_umkehr_hinaus_nach_herein_ohne_sprung() -> void:
	# Arrange: aus der Endlage ein Stück hinaus.
	_communicator.slide_out()
	for _bild in 6:
		_communicator._process(1.0 / 60.0)
	var vorher := _communicator.position.y

	# Act
	_communicator.slide_in()
	var gleich_danach := _communicator.position.y
	var lagen := _fahre(1.0 / 60.0, 1.0 / 60.0)

	# Assert
	assert_between(vorher, ENDLAGE.y + 1, Communicator.HIDDEN_Y - 1, "Voraussetzung: unterwegs.")
	assert_eq(gleich_danach, vorher, "Die Umkehr beginnt in der jetzigen Lage.")
	assert_lte(vorher - lagen[0], (vorher - ENDLAGE.y) / 4.0,
		"Im ersten Bild nach der Umkehr kein Sprung.")
	var vorige := vorher
	for lage: float in lagen:
		assert_eq(lage, roundf(lage), "%s ist kein ganzes Pixel." % lage)
		assert_gte(lage, ENDLAGE.y, "%s liegt über der Endlage." % lage)
		assert_lte(lage, vorige, "Bei %s fährt er wieder hinaus." % lage)
		vorige = lage
	assert_eq(lagen.back(), ENDLAGE.y)
	assert_true(_communicator.is_in())
	assert_eq(_meldungen, [true] as Array[bool], "Nur die Fahrt herein meldet sich, einmal.")


# --- Fahrt: Meldung und Zustand -------------------------------------------

func test_slide_finished_einmal_je_fahrt_mit_dem_richtigen_wert() -> void:
	# Arrange
	_communicator.place_hidden()

	# Act: herein, ein paar Bilder Stand, hinaus, wieder ein paar Bilder Stand.
	_communicator.slide_in()
	_fahre(1.0 / 60.0, 1.0 / 60.0)
	for _bild in 5:
		_communicator._process(1.0 / 60.0)
	_communicator.slide_out()
	_fahre(1.0 / 60.0, 1.0 / 60.0)
	for _bild in 5:
		_communicator._process(1.0 / 60.0)

	# Assert
	assert_eq(_meldungen, [true, false] as Array[bool], "Herein true, hinaus false, je einmal.")


func test_zweites_slide_in_waehrend_der_fahrt_aendert_nichts() -> void:
	# Arrange
	_communicator.place_hidden()
	_communicator.slide_in()
	_communicator._process(1.0 / 60.0)
	var lage := _communicator.position.y

	# Act
	_communicator.slide_in()
	_fahre(1.0 / 60.0, 1.0 / 60.0)

	# Assert
	assert_eq(_communicator.position.y, ENDLAGE.y)
	assert_lt(lage, Communicator.HIDDEN_Y, "Voraussetzung: Die Fahrt lief schon.")
	assert_eq(_meldungen, [true] as Array[bool], "Eine Fahrt, eine Meldung.")


func test_ohne_animation_sofort_am_ziel_und_gemeldet() -> void:
	# Arrange
	_communicator.animate = false

	# Act und Assert: ohne ein einziges Bild.
	_communicator.slide_out()
	assert_eq(_communicator.position.y, Communicator.HIDDEN_Y, "Sofort draußen.")
	assert_eq(_meldungen, [false] as Array[bool], "Sofort gemeldet.")

	_communicator.slide_in()
	assert_eq(_communicator.position.y, ENDLAGE.y, "Sofort in der Endlage.")
	assert_eq(_meldungen, [false, true] as Array[bool])


func test_fahrt_ohne_weg_meldet_sofort() -> void:
	# Act: Der Communicator steht schon in der Endlage, slide_in() hat keinen Weg.
	_communicator.slide_in()

	# Assert: Ein Bildschirm, der auf die Meldung wartet, bleibt nicht hängen.
	assert_eq(_meldungen, [true] as Array[bool])
	assert_eq(_communicator.position.y, ENDLAGE.y)


func test_is_in_folgt_dem_ziel() -> void:
	# Act und Assert
	assert_true(_communicator.is_in(), "Nach dem Erscheinen steht er in der Endlage.")
	_communicator.place_hidden()
	assert_false(_communicator.is_in(), "Draußen.")
	_communicator.slide_in()
	assert_true(_communicator.is_in(), "Auf dem Weg herein zählt schon als drin.")
	_communicator._process(1.0 / 60.0)
	_communicator.slide_out()
	assert_false(_communicator.is_in(), "Auf dem Weg hinaus zählt als draußen.")


func test_die_engine_treibt_die_fahrt_nicht_mit() -> void:
	# Arrange
	_communicator.place_hidden()
	_communicator.slide_in()

	# Act: echte Bilder vergehen, aber _process() ist aus und der Tween angehalten.
	await wait_process_frames(3)

	# Assert
	assert_eq(_communicator.position.y, Communicator.HIDDEN_Y,
		"Ohne _process() steht die Fahrt; nur der eigene Takt bewegt den Communicator.")


# --- Eingabe (T007) -------------------------------------------------------

func test_accepts_input_folgt_der_fahrt() -> void:
	# Act und Assert
	assert_true(_communicator.accepts_input(), "In der Endlage.")
	_communicator.slide_out()
	assert_false(_communicator.accepts_input(), "Ab slide_out(), schon vor dem ersten Bild.")
	_communicator._process(BILD)
	assert_false(_communicator.accepts_input(), "Auf der Fahrt hinaus.")
	_communicator.slide_in()
	assert_true(_communicator.accepts_input(), "Ab slide_in(), auch mitten aus der Fahrt hinaus.")
	_communicator.slide_out()
	_fahre(BILD, BILD)
	assert_false(_communicator.accepts_input(), "Draußen nach der Fahrt hinaus.")
	_communicator.place_hidden()
	assert_true(_communicator.accepts_input(), "place_hidden() sperrt nicht (C5).")


func test_nach_place_hidden_kann_der_bildschirm_waehlen() -> void:
	# Arrange: erst hinausgefahren, dann ohne Fahrt nach draußen gestellt.
	var menue := await _zeige_menue(0)
	_communicator.slide_out()
	_fahre(BILD, BILD)

	# Act
	_communicator.place_hidden()
	menue.select(2)

	# Assert
	assert_eq(_viewport().gui_get_focus_owner(), _zeilen(menue)[2],
		"Nach place_hidden() nimmt die Seite den Fokus wieder.")


func test_waehrend_der_fahrt_hinaus_loest_das_menue_nichts_aus() -> void:
	# Arrange: gewählt ist der zweite Eintrag, alle drei sind verfügbar.
	var menue := await _zeige_menue(1)
	watch_signals(menue)

	# Act: Die Fahrt hinaus läuft, dann jede Eingabe, die sonst etwas auslöst.
	_communicator.slide_out()
	_communicator._process(BILD)
	_taste(KEY_ENTER)
	_taste(KEY_SPACE)
	var zweite := _mitte(_zeilen(menue)[1])
	_maus_nach(zweite)
	_klick(zweite)
	# Maus über eine andere Zeile bewegen, dann Enter: Ohne Sperre holte sich die erste Zeile über
	# mouse_entered den Fokus, und Enter löste sie aus (Analyse, B2).
	var erste := _mitte(_zeilen(menue)[0])
	_maus_nach(erste + Vector2(0, 2))
	_maus_nach(erste)
	_taste(KEY_ENTER)

	# Assert
	assert_signal_not_emitted(menue, "entry_activated", "Während der Fahrt hinaus löst nichts aus.")
	assert_signal_not_emitted(menue, "selection_changed", "Die Maus wählt keine Zeile.")
	assert_null(_viewport().gui_get_focus_owner(), "Keine Seite hat den Fokus.")
	assert_eq(menue.selected_index(), 1, "Die Auswahl bleibt, wo sie war.")


func test_nach_slide_in_nimmt_das_menue_wieder_eingaben_an() -> void:
	# Arrange: hinaus, ein Stück unterwegs, dann wieder herein; der Bildschirm wählt neu.
	var menue := await _zeige_menue(1)
	_communicator.slide_out()
	_communicator._process(BILD)
	_communicator.slide_in()
	menue.select(menue.selected_index())
	watch_signals(menue)

	# Act
	_taste(KEY_ENTER)
	_maus_nach(_mitte(_zeilen(menue)[2]))

	# Assert: die Gegenprobe zum Test davor.
	assert_signal_emitted_with_parameters(menue, "entry_activated", [&"zwei"])
	assert_eq(menue.selected_index(), 2, "Die Maus wählt wieder.")


func test_waehrend_der_fahrt_hinaus_loest_die_liste_nichts_aus() -> void:
	# Arrange: gewählt ist der fortsetzbare Spielstand in der obersten Zeile.
	var liste := await _zeige_liste()
	watch_signals(liste)

	# Act
	_communicator.slide_out()
	_communicator._process(BILD)
	_taste(KEY_ENTER)
	_taste(KEY_SPACE)
	var spielstand := _mitte(liste.get_node(^"Rows/Slot0"))
	_maus_nach(spielstand)
	_klick(spielstand)
	# Maus über „Zurück“ bewegen, dann Enter: Ohne Sperre wählte die Liste bei jeder Bewegung.
	var zurueck := _mitte(liste.get_node(^"Rows/Back"))
	_maus_nach(zurueck + Vector2(0, 2))
	_maus_nach(zurueck)
	_taste(KEY_ENTER)

	# Assert
	assert_signal_not_emitted(liste, "resume_requested", "Kein Spielstand wird fortgesetzt.")
	assert_signal_not_emitted(liste, "back_requested", "„Zurück“ löst nicht aus.")
	assert_signal_not_emitted(liste, "selection_changed", "Die Maus wählt keine Zeile.")
	assert_eq(liste.selected_index(), 0, "Die Auswahl bleibt, wo sie war.")
	assert_null(_viewport().gui_get_focus_owner(), "Keine Seite hat den Fokus.")


func test_waehrend_der_fahrt_herein_wirken_tastatur_und_klick() -> void:
	# Arrange: von draußen ein Stück herein, so weit, dass die Zeilen im Bild sind.
	var menue := await _zeige_menue(0)
	_communicator.place_hidden()
	_communicator.slide_in()
	for _bild in 6:
		_communicator._process(BILD)
	watch_signals(menue)

	# Act
	_taste(KEY_DOWN)
	_taste(KEY_ENTER)
	var dritte := _mitte(_zeilen(menue)[2])
	_maus_nach(dritte)
	_klick(dritte)

	# Assert: wie im Stand (FR-003).
	assert_gt(_communicator.position.y, ENDLAGE.y, "Voraussetzung: noch unterwegs.")
	assert_signal_emit_count(menue, "entry_activated", 2)
	assert_eq(get_signal_parameters(menue, "entry_activated", 0), [&"zwei"], "Pfeil runter, Enter.")
	assert_eq(get_signal_parameters(menue, "entry_activated", 1), [&"drei"], "Klick.")


func test_zeile_unter_dem_ruhenden_zeiger_wird_nicht_gewaehlt() -> void:
	# Arrange: Der Zeiger ruht dort, wo in der Endlage die dritte Zeile steht. Der Communicator
	# steht draußen; unter dem Zeiger ist noch nichts von ihm.
	var menue := await _zeige_menue(0)
	var ziel := _mitte(_zeilen(menue)[2])
	_communicator.place_hidden()
	await wait_process_frames(1)
	_maus_nach(ziel)
	watch_signals(menue)

	# Act: herein, nach jedem Schritt ein echtes Bild, in dem Godot prüfen könnte, was jetzt unter
	# dem Zeiger liegt. Die erste und die zweite Zeile fahren dabei unter ihm durch.
	_communicator.slide_in()
	for _bild in HOECHSTENS_BILDER:
		_communicator._process(BILD)
		await wait_process_frames(1)
		if not _meldungen.is_empty():
			break
	await wait_process_frames(2)

	# Assert
	assert_eq(_communicator.position.y, ENDLAGE.y, "Voraussetzung: in der Endlage.")
	assert_signal_not_emitted(menue, "selection_changed", "Ohne Bewegung der Maus wählt nichts.")
	assert_eq(menue.selected_index(), 0)
	# Gegenprobe: Ein kleines Rucken der Maus wählt die Zeile unter ihr.
	_maus_nach(ziel + Vector2(1, 0))
	assert_eq(menue.selected_index(), 2, "Eine echte Bewegung wählt.")


# --- Hinweis (T007) -------------------------------------------------------

func test_hinweis_links_neben_dem_gehaeuse_oben_buendig() -> void:
	# Arrange: die dritte Zeile einer Seite auf der Anzeige, global.
	var zeile := _zeile_auf_der_anzeige(2)

	# Act
	_communicator.show_hint("Ein kurzer Hinweis.", zeile)

	# Assert
	var hinweis := _hinweis()
	assert_true(hinweis.visible, "Der Hinweis erscheint sofort.")
	assert_eq(hinweis.global_position.x + hinweis.size.x, ENDLAGE.x - MenuHint.GAP,
		"Die rechte Kante steht 4 vor der linken Kante des Gehäuses.")
	assert_eq(hinweis.global_position.y, zeile.position.y, "Oben bündig mit der Zeile.")
	assert_eq(hinweis.theme_type_variation, &"HintPanel")
	assert_eq(hinweis.get_parent(), _communicator, "Er ist ein Kind des Communicators.")


func test_hinweis_faehrt_um_genau_die_strecke_der_fahrt_mit() -> void:
	# Arrange
	_communicator.show_hint("Ein kurzer Hinweis.", _zeile_auf_der_anzeige(0))
	var vorher := _hinweis().global_position

	# Act und Assert
	_communicator.slide_out()
	_fahre(BILD, BILD)
	assert_eq(_hinweis().global_position - vorher, Vector2(0, Communicator.HIDDEN_Y - ENDLAGE.y),
		"Hinaus: um genau die Strecke der Fahrt nach unten.")
	_communicator.slide_in()
	_fahre(BILD, BILD)
	assert_eq(_hinweis().global_position, vorher, "Herein: wieder an seiner Stelle.")


func test_meldung_steht_an_der_stelle_des_hinweises() -> void:
	# Arrange
	var zeile := _zeile_auf_der_anzeige(1)
	_communicator.show_hint("Ein kurzer Hinweis.", zeile)
	var rechts := _hinweis().global_position.x + _hinweis().size.x

	# Act und Assert
	_communicator.show_warning("Das ging nicht.", zeile)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel", "Eine Meldung, Kontur kassenrot.")
	assert_eq(_hinweis().global_position.x + _hinweis().size.x, rechts, "Dieselbe rechte Kante.")
	assert_eq(_hinweis().global_position.y, zeile.position.y, "Oben bündig mit der Zeile.")
	_communicator.show_hint("Ein kurzer Hinweis.", zeile)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel",
		"Neben derselben Zeile bleibt die Meldung, wie MenuHint es regelt.")
	_communicator.show_hint("Ein anderer Hinweis.", _zeile_auf_der_anzeige(2))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Eine andere Zeile ersetzt sie.")
	_communicator.hide_hint()
	assert_false(_hinweis().visible, "hide_hint() blendet aus.")


# --- Probeseite (T008, SC-005) --------------------------------------------

func test_probeseite_meldet_den_zweiten_eintrag() -> void:
	# Arrange: die Probeszene in einem eigenen Viewport, ohne Titelbildschirm.
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	var probe := (load(PROBE_SCENE_PATH) as PackedScene).instantiate()
	eigener_viewport.add_child(probe)
	# Ein Bild: Die Startauswahl des Menüs kommt zeitversetzt.
	await wait_process_frames(1)
	var menue := probe.get_node(^"Communicator/MainMenu") as MainMenu
	watch_signals(menue)

	# Act
	_taste(KEY_DOWN, eigener_viewport)
	_taste(KEY_ENTER, eigener_viewport)

	# Assert
	assert_eq(menue.entries.size(), 3, "Drei Einträge.")
	assert_signal_emit_count(menue, "entry_activated", 1)
	assert_signal_emitted_with_parameters(menue, "entry_activated", [&"zwei"])


func test_probeseite_kommt_ohne_titelbildschirm_und_titeltexte_aus() -> void:
	# Arrange: die Quelltexte der Probe, so wie sie auf der Platte liegen.
	var szene := FileAccess.get_file_as_string(PROBE_SCENE_PATH)
	var skript := FileAccess.get_file_as_string(PROBE_SCRIPT_PATH)

	# Assert
	assert_gt(szene.length(), 0, "Voraussetzung: die Szene gelesen.")
	# Gesucht wird nach Benutzung, nicht nach dem Wort: Der Kopfkommentar der Probe nennt beide.
	for quelle: String in [szene, skript]:
		assert_false(quelle.contains("title_screen.tscn") or quelle.contains("TitleScreen."),
			"Kein Verweis auf den Titelbildschirm.")
		assert_false(quelle.contains("title_texts.gd") or quelle.contains("TitleTexts."),
			"Keine Texte des Titels.")
	assert_true(szene.contains("res://ui/communicator/communicator.tscn"),
		"Die Probe benutzt den Baustein selbst.")


# --- Gehäusetasten (Feature 006, T026) -----------------------------------

func test_ohne_vorgabe_hat_das_gehaeuse_keine_tasten() -> void:
	# Arrange: Sichtbar ist Seite A, ihr Knopf hat den Fokus; so wie vor Feature 006.
	_communicator.show_page(_seite_a)
	watch_signals(_communicator)
	watch_signals(_buehne)

	# Act: ein Linksklick dorthin, wo bei G-03 die linke graue Taste ist.
	var stelle := TASTEN_IM_TITEL[0].get_center()
	_maus_nach(stelle)
	_klick(stelle)

	# Assert
	assert_eq(_communicator.case_keys, [] as Array[Rect2i], "Vorgabe ist leer (Analyse, I2).")
	assert_eq(_tasten().size(), 0, "Ohne case_keys keine Klickfläche.")
	assert_false(_communicator.is_case_key_down(0), "Eine Taste, die es nicht gibt, ist nie unten.")
	assert_signal_not_emitted(_communicator, "case_key_pressed")
	assert_signal_emitted(_buehne, "gui_input", "Der Klick geht durch das Gehäuse wie bisher.")
	assert_false(_klick_spieler().playing, "Ohne Tasten klickt nichts.")


func test_keys_und_keyclick_sind_keine_seiten() -> void:
	# Arrange
	var keys := _communicator.get_node(^"Keys") as Control
	var klick := _klick_spieler()

	# Act
	_communicator.show_page(_seite_b)

	# Assert: Keys bleibt zu sehen, liegt über dem Gehäuse und unter den Seiten.
	assert_true(keys.visible, "show_page() verbirgt die Tasten nicht.")
	assert_eq(_communicator.current_page(), _seite_b)
	assert_eq(keys.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Keys lässt die Maus durch.")
	assert_eq(keys.position, Vector2.ZERO, "Keys liegt auf dem Communicator.")
	assert_gt(keys.get_index(), _communicator.get_node(^"Case").get_index(), "Über dem Gehäuse.")
	assert_lt(keys.get_index(), _seite_a.get_index(), "Unter den Seiten.")
	assert_eq(keys.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "Pixel bleiben scharf.")
	assert_eq(klick.stream.resource_path, KLICK, "Der Klick ist knopf.wav.")
	assert_eq(klick.bus, &"Effekte", "Auf dem Kanal Effekte.")


func test_drei_tasten_an_den_rechtecken_aus_dem_style_guide() -> void:
	# Act
	_communicator.case_keys = TASTEN

	# Assert: Klickflächen genau ×2, im Titel an den Stellen aus dem Style-Guide.
	var tasten := _tasten()
	assert_eq(tasten.size(), 3, "Drei Tasten.")
	for index in tasten.size():
		assert_eq(tasten[index].get_global_rect(), TASTEN_IM_TITEL[index], "Taste %d" % index)
		assert_eq(tasten[index].get_rect().size, Vector2(TASTEN[index].size * 2),
			"Taste %d ist genau ×2." % index)
		assert_false(_communicator.is_case_key_down(index), "Taste %d ist oben." % index)


func test_druck_und_loslassen_ueber_taste_1_meldet_einmal_0() -> void:
	# Arrange
	_communicator.case_keys = TASTEN
	watch_signals(_communicator)
	var stelle := TASTEN_IM_TITEL[0].get_center()

	# Act und Assert
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)
	assert_true(_communicator.is_case_key_down(0), "Unten, solange die Maustaste unten ist.")
	assert_signal_not_emitted(_communicator, "case_key_pressed",
		"Gezählt wird erst beim Loslassen.")
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)
	assert_false(_communicator.is_case_key_down(0), "Wieder oben.")
	assert_signal_emit_count(_communicator, "case_key_pressed", 1)
	assert_signal_emitted_with_parameters(_communicator, "case_key_pressed", [0])


func test_jede_taste_meldet_ihren_index() -> void:
	# Arrange
	_communicator.case_keys = TASTEN
	var gemeldet: Array[int] = []
	_communicator.case_key_pressed.connect(func(index: int) -> void: gemeldet.append(index))

	# Act: rechts, links, Mitte; je am Rand der Taste, einschließlich gezählt.
	for index: int in [2, 0, 1]:
		var stelle := TASTEN_IM_TITEL[index].position + Vector2(0.5, 0.5)
		_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)
		_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)

	# Assert
	assert_eq(gemeldet, [2, 0, 1] as Array[int])


func test_loslassen_anderswo_zaehlt_nicht() -> void:
	# Arrange
	_communicator.case_keys = TASTEN
	watch_signals(_communicator)
	var auf_taste_2 := TASTEN_IM_TITEL[1].get_center()
	var ziele := {
		"über Taste 3": TASTEN_IM_TITEL[2].get_center(),
		"außerhalb": ENDLAGE + Vector2(8, 240),
		"knapp unter Taste 2": Vector2(auf_taste_2.x, TASTEN_IM_TITEL[1].end.y + 1),
	}

	for ziel: String in ziele:
		# Act: drücken auf Taste 2, mit gedrückter Maustaste wegziehen, dort loslassen.
		_maus_taste(auf_taste_2, MOUSE_BUTTON_LEFT, true)
		assert_true(_communicator.is_case_key_down(1), "Unten vor dem Loslassen %s." % ziel)
		_maus_nach(ziele[ziel])
		_maus_taste(ziele[ziel], MOUSE_BUTTON_LEFT, false)

		# Assert
		assert_false(_communicator.is_case_key_down(1), "Taste 2 springt zurück (%s)." % ziel)
		assert_false(_communicator.is_case_key_down(2), "Taste 3 bleibt oben (%s)." % ziel)

	assert_signal_not_emitted(_communicator, "case_key_pressed", "Kein Druck zählt.")


func test_rechte_und_mittlere_maustaste_tun_nichts() -> void:
	# Arrange
	_communicator.case_keys = TASTEN
	watch_signals(_communicator)
	var stelle := TASTEN_IM_TITEL[0].get_center()

	for knopf: MouseButton in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		# Act
		_maus_taste(stelle, knopf, true)

		# Assert
		assert_false(_communicator.is_case_key_down(0), "Nicht eingedrückt (Knopf %d)." % knopf)
		assert_false(_klick_spieler().playing, "Kein Klick (Knopf %d)." % knopf)
		_maus_taste(stelle, knopf, false)

	assert_signal_not_emitted(_communicator, "case_key_pressed")


func test_slide_out_sperrt_die_tasten_und_laesst_eine_gedrueckte_hoch() -> void:
	# Arrange: Taste 1 ist unten.
	_communicator.case_keys = TASTEN
	watch_signals(_communicator)
	var stelle := TASTEN_IM_TITEL[0].get_center()
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)

	# Act
	_communicator.slide_out()

	# Assert: sofort oben, ohne zu zählen, auch nicht beim Loslassen danach.
	assert_false(_communicator.is_case_key_down(0), "Die gedrückte Taste geht hoch.")
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)
	assert_signal_not_emitted(_communicator, "case_key_pressed", "Das Loslassen zählt nicht.")

	# Act: ein neuer Druck auf der Fahrt hinaus. Der Communicator steht noch an derselben Stelle.
	_klick_spieler().stop()
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)

	# Assert
	assert_false(_communicator.is_case_key_down(0), "Gesperrt drückt sich nichts ein.")
	assert_false(_klick_spieler().playing, "Gesperrt klickt nichts.")
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)
	assert_signal_not_emitted(_communicator, "case_key_pressed", "Gesperrt zählt nichts.")


func test_nach_slide_in_melden_die_tasten_wieder() -> void:
	# Arrange: hinaus und wieder herein, ohne Fahrt.
	_communicator.case_keys = TASTEN
	_communicator.animate = false
	_communicator.slide_out()
	_communicator.slide_in()
	watch_signals(_communicator)
	var stelle := TASTEN_IM_TITEL[2].get_center()

	# Act
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)

	# Assert
	assert_signal_emit_count(_communicator, "case_key_pressed", 1)
	assert_signal_emitted_with_parameters(_communicator, "case_key_pressed", [2])


func test_jeder_druck_links_klickt_auch_einer_der_nicht_zaehlt() -> void:
	# Arrange
	_communicator.case_keys = TASTEN
	var klick := _klick_spieler()
	var auf_taste := TASTEN_IM_TITEL[1].get_center()
	var daneben := ENDLAGE + Vector2(8, 240)

	# Act und Assert: ein Druck, der zählt.
	_maus_taste(auf_taste, MOUSE_BUTTON_LEFT, true)
	assert_true(klick.playing, "Der Klick kommt beim Drücken.")
	_maus_taste(auf_taste, MOUSE_BUTTON_LEFT, false)

	# Act und Assert: ein Druck, der nicht zählt, weil die Maus woanders losgelassen wird.
	klick.stop()
	_maus_taste(auf_taste, MOUSE_BUTTON_LEFT, true)
	assert_true(klick.playing, "Auch dieser Druck klickt.")
	_maus_nach(daneben)
	_maus_taste(daneben, MOUSE_BUTTON_LEFT, false)
	assert_eq(klick.bus, &"Effekte", "Auf dem Kanal Effekte.")


func test_zeiger_pfeil_und_kein_fokus() -> void:
	# Arrange: Seite A ist zu sehen, ihr Knopf hat den Fokus.
	_communicator.case_keys = TASTEN
	_communicator.show_page(_seite_a)
	var knopf := _seite_a.get_node(^"Knopf") as Button
	knopf.grab_focus()

	for index in TASTEN_IM_TITEL.size():
		var taste := _tasten()[index]
		var stelle := TASTEN_IM_TITEL[index].get_center()

		# Act
		_maus_nach(stelle)
		_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)
		_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)

		# Assert
		assert_eq(taste.mouse_filter, Control.MOUSE_FILTER_STOP, "Taste %d nimmt die Maus." % index)
		assert_eq(taste.mouse_default_cursor_shape, Control.CURSOR_ARROW, "Pfeil, keine Hand.")
		assert_eq(taste.get_cursor_shape(taste.get_local_mouse_position()), Control.CURSOR_ARROW)
		assert_eq(taste.focus_mode, Control.FOCUS_NONE, "Taste %d nimmt keinen Fokus." % index)
		assert_eq(taste.tooltip_text, "", "Kein Tooltip.")
		assert_eq(_viewport().gui_get_focus_owner(), knopf, "Der Fokus bleibt, wo er war.")


func test_eingedrueckt_ausschnitt_eine_zeile_tiefer_oben_der_spalt() -> void:
	# Arrange
	_communicator.case_keys = TASTEN
	var bild := (_communicator.get_node(^"Case") as TextureRect).texture.get_image()

	for index in TASTEN.size():
		var taste := TASTEN[index]
		var flaeche := Rect2(Vector2(taste.position * 2), Vector2(taste.size * 2))

		# Act: was _draw_case_keys() für diese Taste malt, in Oberflächenpixeln des Communicators.
		var ebenen := _communicator._pressed_layers(taste)

		# Assert: Oben eine Bildpixelzeile in der Farbe des Pixels links neben der Taste.
		assert_eq(ebenen["gap_rect"], Rect2(flaeche.position, Vector2(flaeche.size.x, 2)),
			"Taste %d: oberste Zeile ×2." % index)
		assert_eq(ebenen["gap_color"], bild.get_pixel(taste.position.x - 1, taste.position.y),
			"Taste %d: Farbe des Spalts aus dem Bild, keine neue Farbe." % index)
		# Darunter die Taste ohne ihre unterste Zeile, eine Bildpixelzeile tiefer, ×2.
		assert_eq(ebenen["key_source"],
			Rect2(Vector2(taste.position), Vector2(taste.size.x, taste.size.y - 1)),
			"Taste %d: Ausschnitt ohne die unterste Zeile." % index)
		assert_eq(ebenen["key_rect"],
			Rect2(flaeche.position + Vector2(0, 2), flaeche.size - Vector2(0, 2)),
			"Taste %d: eine Bildpixelzeile tiefer, ×2." % index)
		assert_true(flaeche.encloses(ebenen["key_rect"]),
			"Taste %d: Der Ausschnitt reicht nicht über die Taste hinaus." % index)
		assert_eq((ebenen["gap_rect"] as Rect2).merge(ebenen["key_rect"]), flaeche,
			"Taste %d: Spalt und Ausschnitt decken genau die Taste." % index)


func test_eingedrueckt_im_naechsten_bild_gemalt() -> void:
	# Arrange: zählt, wie oft Keys malt und ob Taste 2 dabei unten war.
	_communicator.case_keys = TASTEN
	var keys := _communicator.get_node(^"Keys") as Control
	await wait_process_frames(1)
	var gemalt: Array[bool] = []
	keys.draw.connect(func() -> void: gemalt.append(_communicator.is_case_key_down(1)))
	var stelle := TASTEN_IM_TITEL[1].get_center()

	# Act
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)
	await wait_process_frames(1)

	# Assert
	assert_eq(gemalt, [true] as Array[bool], "Im nächsten Bild malt Keys die Taste eingedrückt.")

	# Act: loslassen, wieder ein Bild.
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)
	await wait_process_frames(1)

	# Assert
	assert_eq(gemalt, [true, false] as Array[bool], "Danach malt Keys sie wieder oben.")


func test_case_keys_zur_laufzeit_neu_gebaut() -> void:
	# Arrange
	_communicator.case_keys = TASTEN
	watch_signals(_communicator)

	# Act: nur noch eine Taste, an der Stelle der rechten. Die alten Klickflächen gibt der
	# Communicator mit queue_free() frei, also am Ende des Bilds; der Test wartet es ab, damit
	# keine verwaisten Nodes zurückbleiben.
	_communicator.case_keys = [TASTEN[2]] as Array[Rect2i]
	await wait_process_frames(1)

	# Assert
	assert_eq(_tasten().size(), 1, "Eine Klickfläche.")
	assert_eq(_tasten()[0].get_global_rect(), TASTEN_IM_TITEL[2])
	var stelle := TASTEN_IM_TITEL[2].get_center()
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)
	assert_signal_emitted_with_parameters(_communicator, "case_key_pressed", [0])

	# Act: gar keine Tasten mehr.
	_communicator.case_keys = []
	await wait_process_frames(1)

	# Assert
	assert_eq(_tasten().size(), 0, "Keine Klickfläche.")


func test_fokus_des_fensters_weg_laesst_die_taste_hoch_ohne_zu_zaehlen() -> void:
	# Arrange: Taste 1 ist unten.
	_communicator.case_keys = TASTEN
	watch_signals(_communicator)
	var stelle := TASTEN_IM_TITEL[0].get_center()
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)

	# Act: Das Fenster verliert den Fokus; danach wird über der Taste losgelassen.
	_communicator.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)

	# Assert
	assert_false(_communicator.is_case_key_down(0), "Die Taste springt zurück.")
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, false)
	assert_false(_communicator.is_case_key_down(0), "Sie bleibt oben.")
	assert_signal_not_emitted(_communicator, "case_key_pressed", "Der Druck zählt nicht.")


func test_godots_eigenes_loslassen_beim_fokusverlust_zaehlt_nicht() -> void:
	# Arrange: Taste 2 ist unten.
	_communicator.case_keys = TASTEN
	watch_signals(_communicator)
	var stelle := TASTEN_IM_TITEL[1].get_center()
	_maus_taste(stelle, MOUSE_BUTTON_LEFT, true)

	# Act: das Loslassen, das Godot beim Verlust des Fensterfokus selbst schickt, noch vor der
	# Benachrichtigung. Godot reicht es am Viewport vorbei direkt an die Taste weiter, mit der Lage
	# der Maus relativ zur Taste; hier mitten auf ihr.
	var taste := _tasten()[1]
	var ereignis := InputEventMouseButton.new()
	ereignis.device = CaseKey.DEVICE_ID_INTERNAL
	ereignis.button_index = MOUSE_BUTTON_LEFT
	ereignis.position = taste.size / 2
	ereignis.global_position = stelle
	ereignis.pressed = false
	taste._gui_input(ereignis)

	# Assert
	assert_false(_communicator.is_case_key_down(1), "Die Taste springt zurück.")
	assert_signal_not_emitted(_communicator, "case_key_pressed", "Es zählt nicht.")


func test_probeseite_meldet_eine_gehaeusetaste() -> void:
	# Arrange: die Probeszene mit den drei Tasten von G-03, in der Endlage.
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	var probe := (load(PROBE_SCENE_PATH) as PackedScene).instantiate()
	eigener_viewport.add_child(probe)
	var communicator := probe.get_node(^"Communicator") as Communicator
	# Die Probe fährt beim Start herein. Statt die Fahrt zu takten, steht das Gerät gleich in der
	# Endlage: place_hidden() beendet die Fahrt, slide_in() ohne Animation springt ans Ziel.
	communicator.set_process(false)
	communicator.animate = false
	communicator.place_hidden()
	communicator.slide_in()
	eigener_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	await wait_process_frames(1)
	var hinweis := communicator.get_node(^"Hint") as MenuHint
	watch_signals(communicator)

	# Act: Mitte drücken und loslassen.
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = MOUSE_BUTTON_LEFT
		ereignis.position = TASTEN_IM_TITEL[1].get_center()
		ereignis.global_position = ereignis.position
		ereignis.pressed = gedrueckt
		eigener_viewport.push_input(ereignis, true)

	# Assert
	assert_eq(communicator.case_keys, TASTEN, "Die Probe setzt die Tasten aus dem Style-Guide.")
	assert_signal_emitted_with_parameters(communicator, "case_key_pressed", [1])
	assert_eq((hinweis.get_node(^"Text") as Label).text, "Gehäusetaste 2 gedrückt.",
		"Die Meldung nennt die Taste.")
	assert_eq(hinweis.theme_type_variation, &"WarningPanel", "Als Meldung.")
	assert_true(Rect2(0, 0, 640, 360).encloses(hinweis.get_global_rect()),
		"Die Meldung steht im Bild, auch wenn die Zeile gewählt wurde, als das Gerät draußen war.")


func test_probeseite_meldung_eines_eintrags_steht_im_bild() -> void:
	# Arrange: die Probeszene wie gleich nach dem Start. Die Startauswahl kam, als das Gerät noch
	# draußen stand; dann steht es ohne Fahrt in der Endlage.
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	var probe := (load(PROBE_SCENE_PATH) as PackedScene).instantiate()
	eigener_viewport.add_child(probe)
	var communicator := probe.get_node(^"Communicator") as Communicator
	communicator.set_process(false)
	communicator.animate = false
	communicator.place_hidden()
	communicator.slide_in()
	await wait_process_frames(1)
	var hinweis := communicator.get_node(^"Hint") as MenuHint
	var menue := probe.get_node(^"Communicator/MainMenu") as MainMenu

	# Act: Enter auf dem ersten Eintrag.
	_taste(KEY_ENTER, eigener_viewport)

	# Assert
	assert_eq((hinweis.get_node(^"Text") as Label).text, "Ausgelöst: Erster Eintrag.",
		"Die Meldung nennt den Eintrag.")
	assert_true(Rect2(0, 0, 640, 360).encloses(hinweis.get_global_rect()),
		"Die Meldung steht im Bild, nicht da, wo die Zeile stand, als das Gerät draußen war.")
	assert_eq(hinweis.global_position.y, menue.global_position.y + MainMenu.ROW_HEIGHT,
		"Oben bündig mit der ersten Zeile, wo sie jetzt ist.")


# --- Helfer ---------------------------------------------------------------

## Stellt den Communicator ohne Fahrt in die Endlage, gleich wo er steht.
func _stelle_in_die_endlage() -> void:
	_communicator.animate = false
	_communicator.slide_in()
	_communicator.animate = true


## Ein schlichtes Control als Seite, zuerst in einer eigenen Größe, mit einem Knopf oben links.
func _seite(bezeichnung: String) -> Control:
	var seite := Control.new()
	seite.name = bezeichnung
	seite.size = Vector2(144, 100)
	var knopf := Button.new()
	knopf.name = "Knopf"
	knopf.text = bezeichnung
	knopf.size = Vector2(100, 20)
	seite.add_child(knopf)
	return seite


## Taktet die laufende Fahrt mit [param erstes] im ersten Bild und [param danach] in jedem weiteren,
## bis slide_finished kommt, und gibt die Lage in y nach jedem Bild zurück.
func _fahre(erstes: float, danach: float) -> Array[float]:
	var lagen: Array[float] = []
	var meldungen_vorher := _meldungen.size()
	var schritt := erstes
	for _bild in HOECHSTENS_BILDER:
		_communicator._process(schritt)
		lagen.append(_communicator.position.y)
		if _meldungen.size() > meldungen_vorher:
			return lagen
		schritt = danach
	fail_test("Die Fahrt endet nicht nach %d Bildern." % HOECHSTENS_BILDER)
	return lagen


## Die Dauer nach SC-002, gezählt über die Zeitschritte der Bilder: ein langes erstes Bild zählt als
## ein gedeckelter Schritt, hier streng mit dem größeren Deckel MAX_STEP, jedes weitere Bild mit
## seinem Zeitschritt.
func _gezaehlte_dauer(bildfolge: Array, bilder: int) -> float:
	return minf(bildfolge[0], Communicator.MAX_STEP) + (bilder - 1) * (bildfolge[1] as float)


func _name(bildfolge: Array) -> String:
	return "Erstes Bild %.3f s, dann %.3f s" % [bildfolge[0], bildfolge[1]]


func _viewport() -> Viewport:
	return _buehne.get_viewport()


func _hinweis() -> MenuHint:
	return _communicator.get_node(^"Hint") as MenuHint


## Zeile [param index] unter der Kopfzeile einer Seite auf der Anzeige, global, über die ganze
## Breite der Anzeige.
func _zeile_auf_der_anzeige(index: int) -> Rect2:
	var anzeige := Rect2(ENDLAGE + Vector2(ANZEIGE.position), Vector2(ANZEIGE.size))
	return Rect2(anzeige.position + Vector2(0, (index + 1) * MainMenu.ROW_HEIGHT),
		Vector2(anzeige.size.x, MainMenu.ROW_HEIGHT))


## Ein Menü auf Papier mit drei verfügbaren Einträgen als Seite, zu sehen, Zeile [param index]
## gewählt. Wartet ein Bild, bis die Zeilen angeordnet sind und die Startauswahl durch ist.
func _zeige_menue(index: int) -> MainMenu:
	var menue := MENU_SCENE.instantiate() as MainMenu
	menue.entries = [_eintrag(&"eins", "Eins"), _eintrag(&"zwei", "Zwei"),
		_eintrag(&"drei", "Drei")]
	_communicator.add_page(menue)
	_communicator.show_page(menue)
	await wait_process_frames(1)
	menue.select(index)
	return menue


func _eintrag(id: StringName, label: String) -> MenuEntry:
	var eintrag := MenuEntry.new()
	eintrag.id = id
	eintrag.label = label
	eintrag.available = true
	eintrag.hint = "Hinweis zu %s." % label
	return eintrag


## Die Buttons eines Menüs in ihrer Reihenfolge; sie entstehen im Code und haben keinen Owner.
func _zeilen(menue: MainMenu) -> Array[Node]:
	return menue.find_children("*", "Button", true, false)


## Die Mitte von [param knoten] in Koordinaten des Viewports; find_children() liefert Node.
func _mitte(knoten: Node) -> Vector2:
	return (knoten as Control).get_global_rect().get_center()


## Eine Liste auf Papier mit einem fortsetzbaren Spielstand als Seite, zu sehen, die oberste Zeile
## gewählt.
func _zeige_liste() -> SaveList:
	var liste := LIST_SCENE.instantiate() as SaveList
	_communicator.add_page(liste)
	var spiel := SaveGame.new()
	spiel.number = 1
	spiel.name = SaveGame.default_name(1)
	spiel.difficulty = Difficulty.Level.MITTEL
	spiel.day = 0
	var spielstand := SaveSlot.new()
	spielstand.number = 1
	spielstand.state = SaveSlot.State.OK
	spielstand.game = spiel
	liste.show_slots([spielstand] as Array[SaveSlot], 0)
	_communicator.show_page(liste)
	await wait_process_frames(1)
	liste.select(0)
	return liste


## Drückt [param taste] und lässt sie los, über push_input in [param ziel] oder den Viewport der
## Bühne.
func _taste(taste: Key, ziel: Viewport = null) -> void:
	var viewport := ziel if ziel != null else _viewport()
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = taste
		ereignis.physical_keycode = taste
		ereignis.pressed = gedrueckt
		viewport.push_input(ereignis)


## Fährt mit der Maus nach [param ziel], über push_input wie in test_main_menu.gd.
func _maus_nach(ziel: Vector2) -> void:
	var ereignis := InputEventMouseMotion.new()
	ereignis.position = ziel
	ereignis.global_position = ziel
	_buehne.get_viewport().push_input(ereignis, true)


## Die Klickflächen der Gehäusetasten in der Reihenfolge von case_keys.
func _tasten() -> Array[CaseKey]:
	var tasten: Array[CaseKey] = []
	for kind in _communicator.get_node(^"Keys").get_children():
		tasten.append(kind as CaseKey)
	return tasten


func _klick_spieler() -> AudioStreamPlayer:
	return _communicator.get_node(^"KeyClick") as AudioStreamPlayer


## Drückt die Maustaste [param knopf] bei [param ziel] oder lässt sie los, über push_input.
func _maus_taste(ziel: Vector2, knopf: MouseButton, gedrueckt: bool) -> void:
	var ereignis := InputEventMouseButton.new()
	ereignis.button_index = knopf
	ereignis.position = ziel
	ereignis.global_position = ziel
	ereignis.pressed = gedrueckt
	_buehne.get_viewport().push_input(ereignis, true)


## Linksklick bei [param ziel]: drücken und loslassen.
func _klick(ziel: Vector2) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = MOUSE_BUTTON_LEFT
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_buehne.get_viewport().push_input(ereignis, true)
