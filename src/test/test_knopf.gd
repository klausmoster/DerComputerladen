extends GutTest

## Prüft den Baustein Knopf (Feature 004, T018) gegen den Style-Guide, Baustein Knopf: Farben nur
## aus der Palette, Fläche gehaeuse und beim Überfahren signalgelb, Kontur tusche, Relief erhaben
## und gedrückt, Innenabstand, Größe, Mauszeiger und die Fokuslinie auf hellem und dunklem Grund.
##
## Fläche und Kontur kommen aus der Theme-Variante Knopf; die Tests lesen sie aus dem Theme. Relief
## und Fokuslinie malt der Knopf selbst. Headless entsteht dabei kein Bild, das ein Test ansehen
## könnte; geprüft wird deshalb die Liste der Rechtecke, die _draw() malt (Knopf.layers()). Wie der
## Knopf wirklich aussieht, prüft Klaus mit dem Auge.

const THEMA := preload("res://ui/computerladen_theme.tres")
const ZUSTAENDE: Array[StringName] = [&"normal", &"hover", &"pressed", &"hover_pressed",
	&"disabled"]

var _knopf: Knopf


func before_each() -> void:
	# Ein eigener Viewport wie in test_main_menu.gd: eigener Fokus, GUTs Oberfläche stört nicht.
	var eigener_viewport := SubViewport.new()
	add_child_autofree(eigener_viewport)
	_knopf = Knopf.new()
	_knopf.text = "Zum Hauptmenü"
	_knopf.position = Vector2(20, 20)
	eigener_viewport.add_child(_knopf)
	await wait_process_frames(1)


# --- Theme ----------------------------------------------------------------

func test_alle_farben_der_variante_stammen_aus_der_palette() -> void:
	var palette := UiPalette.TOKENS.values()
	for eintrag in THEMA.get_color_list(&"Knopf"):
		var farbe := THEMA.get_color(eintrag, &"Knopf")
		assert_true(palette.has(farbe), "Knopf/%s ist keine Farbe der Palette." % eintrag)
		assert_eq(farbe.a, 1.0, "Knopf/%s ist durchsichtig." % eintrag)
	for zustand in ZUSTAENDE:
		var kasten := THEMA.get_stylebox(zustand, &"Knopf") as StyleBoxFlat
		assert_true(palette.has(kasten.bg_color), "%s: Fläche aus der Palette." % zustand)
		assert_true(palette.has(kasten.border_color), "%s: Kontur aus der Palette." % zustand)


func test_schrift_ist_menue_in_tusche_aus_gedaempft() -> void:
	assert_eq(THEMA.get_font(&"font", &"Knopf"), THEMA.get_font(&"font", &"MenuRow"),
		"Ark Pixel 12 wie die Zeilen des Menüs.")
	assert_eq(THEMA.get_font_size(&"font_size", &"Knopf"), 12, "menue: 12 Pixel.")
	for eintrag: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color"]:
		assert_eq(THEMA.get_color(eintrag, &"Knopf"), UiPalette.TUSCHE, String(eintrag))
	assert_eq(THEMA.get_color(&"font_disabled_color", &"Knopf"), UiPalette.GEHAEUSE_DUNKEL,
		"Aus: Schrift gehaeuse-dunkel.")


func test_flaeche_gehaeuse_ueberfahren_signalgelb_kontur_tusche_eckig() -> void:
	var flaeche := {
		&"normal": UiPalette.GEHAEUSE,
		&"hover": UiPalette.SIGNALGELB,
		&"pressed": UiPalette.GEHAEUSE,
		&"hover_pressed": UiPalette.SIGNALGELB,
		&"disabled": UiPalette.GEHAEUSE,
	}
	for zustand in ZUSTAENDE:
		var kasten := THEMA.get_stylebox(zustand, &"Knopf") as StyleBoxFlat
		assert_eq(kasten.bg_color, flaeche[zustand], "%s: Fläche." % zustand)
		assert_eq(kasten.border_color, UiPalette.TUSCHE, "%s: Kontur tusche." % zustand)
		assert_false(kasten.anti_aliasing, "%s: keine weichen Ränder." % zustand)
		assert_eq(kasten.shadow_size, 0, "%s: kein weicher Schatten." % zustand)
		for seite in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			assert_eq(kasten.get_border_width(seite), 1, "%s: Kontur 1 Pixel." % zustand)
		for ecke in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
			assert_eq(kasten.get_corner_radius(ecke), 0, "%s: eckig (ecke-0)." % zustand)
	assert_true(THEMA.get_stylebox(&"focus", &"Knopf") is StyleBoxEmpty,
		"Die Fokuslinie malt der Knopf selbst, nicht Godot.")


func test_innenabstand_raster_8_und_gedrueckt_einen_pixel_tiefer() -> void:
	for zustand in ZUSTAENDE:
		var kasten := THEMA.get_stylebox(zustand, &"Knopf")
		# 1 Kontur und 8 Innenabstand (raster-8)
		assert_eq(kasten.get_content_margin(SIDE_LEFT), 9.0, "%s links" % zustand)
		assert_eq(kasten.get_content_margin(SIDE_RIGHT), 9.0, "%s rechts" % zustand)
		var oben := 3.0 if zustand in [&"pressed", &"hover_pressed"] else 2.0
		assert_eq(kasten.get_content_margin(SIDE_TOP), oben, "%s oben" % zustand)
		assert_eq(kasten.get_content_margin(SIDE_TOP) + kasten.get_content_margin(SIDE_BOTTOM),
			4.0, "%s: gleich hoch in jedem Zustand" % zustand)


# --- Knopf ----------------------------------------------------------------

func test_zum_hauptmenue_ist_101_mal_20_gross() -> void:
	# Style-Guide, Bildaufbau: der Knopf „Zum Hauptmenü“ ist 101 × 20.
	assert_eq(_knopf.get_combined_minimum_size(), Vector2(101, 20))
	assert_eq(_knopf.size, Vector2(101, 20))


func test_variante_und_mauszeiger() -> void:
	assert_eq(_knopf.theme_type_variation, &"Knopf")
	assert_eq(_knopf.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, "Die Hand.")


func test_ausgeschaltet_zeigt_den_pfeil_statt_der_hand() -> void:
	# Act: Godot malt den Knopf nach dem Umschalten im nächsten Bild neu.
	_knopf.disabled = true
	await wait_process_frames(1)
	var aus := _knopf.get_cursor_shape()
	_knopf.disabled = false
	await wait_process_frames(1)
	var an := _knopf.get_cursor_shape()

	# Assert (Style-Guide, Baustein Knopf: „Aus: keine Reaktion beim Überfahren“)
	assert_eq(aus, Control.CURSOR_ARROW, "Aus: der Pfeil, denn ein Klick tut nichts.")
	assert_eq(an, Control.CURSOR_POINTING_HAND, "Wieder an: die Hand.")


func test_in_ruhe_erhaben_licht_oben_links_schatten_unten_rechts() -> void:
	# Arrange
	var ebenen := _knopf.layers()
	var b := int(_knopf.size.x)
	var h := int(_knopf.size.y)

	# Assert: relief-erhaben innerhalb der Kontur
	assert_eq(_farbe(ebenen, 1, 1), UiPalette.GEHAEUSE_HELL, "Ecke oben links")
	assert_eq(_farbe(ebenen, 50, 1), UiPalette.GEHAEUSE_HELL, "Kante oben")
	assert_eq(_farbe(ebenen, 1, 10), UiPalette.GEHAEUSE_HELL, "Kante links")
	assert_eq(_farbe(ebenen, b - 2, 1), UiPalette.GEHAEUSE_HELL,
		"Die Ecke oben rechts gehört zur Kante oben, wie in relief-erhaben.")
	assert_eq(_farbe(ebenen, 1, h - 2), UiPalette.GEHAEUSE_HELL, "Ecke unten links")
	assert_eq(_farbe(ebenen, b - 2, h - 2), UiPalette.GEHAEUSE_DUNKEL, "Ecke unten rechts")
	assert_eq(_farbe(ebenen, 50, h - 2), UiPalette.GEHAEUSE_DUNKEL, "Kante unten")
	assert_eq(_farbe(ebenen, b - 2, 10), UiPalette.GEHAEUSE_DUNKEL, "Kante rechts")
	assert_null(_farbe(ebenen, 0, 0), "Die Kontur kommt aus dem Theme, nicht aus _draw().")
	assert_null(_farbe(ebenen, 50, 10), "Innen bleiben Fläche und Text frei.")
	_assert_nur_palette(ebenen)


func test_gedrueckt_vertieft() -> void:
	# Arrange: eingeschaltet zählt wie gedrückt (Style-Guide: aria-pressed).
	_knopf.toggle_mode = true
	_knopf.button_pressed = true

	# Act
	var ebenen := _knopf.layers()
	var b := int(_knopf.size.x)
	var h := int(_knopf.size.y)

	# Assert: relief-gedrueckt
	assert_eq(_knopf.get_draw_mode(), BaseButton.DRAW_PRESSED, "Voraussetzung: gedrückt.")
	assert_eq(_farbe(ebenen, 1, 1), UiPalette.GEHAEUSE_DUNKEL)
	assert_eq(_farbe(ebenen, b - 2, 1), UiPalette.GEHAEUSE_DUNKEL)
	assert_eq(_farbe(ebenen, 1, h - 2), UiPalette.GEHAEUSE_DUNKEL)
	assert_eq(_farbe(ebenen, b - 2, h - 2), UiPalette.GEHAEUSE_HELL)
	assert_eq(_farbe(ebenen, 50, h - 2), UiPalette.GEHAEUSE_HELL)


func test_ohne_fokus_keine_fokuslinie() -> void:
	# Act
	var ebenen := _knopf.layers()

	# Assert
	assert_false(_knopf.has_focus(), "Voraussetzung: kein Fokus.")
	assert_null(_farbe(ebenen, -2, -2), "Keine Linie ohne Fokus.")
	assert_eq(ebenen.size(), 4, "Nur die vier Kanten des Reliefs.")


func test_fokuslinie_tusche_einen_pixel_neben_dem_knopf() -> void:
	# Arrange
	_knopf.grab_focus()
	var b := int(_knopf.size.x)
	var h := int(_knopf.size.y)

	# Act
	var ebenen := _knopf.layers()

	# Assert
	for punkt: Vector2i in [Vector2i(-2, -2), Vector2i(b + 1, -2), Vector2i(-2, h + 1),
			Vector2i(b + 1, h + 1), Vector2i(50, -2), Vector2i(50, h + 1), Vector2i(-2, 10),
			Vector2i(b + 1, 10)]:
		assert_eq(_farbe(ebenen, punkt.x, punkt.y), UiPalette.TUSCHE, "Linie bei %s" % punkt)
	for punkt: Vector2i in [Vector2i(-1, -1), Vector2i(50, -1), Vector2i(b, h), Vector2i(-1, 10),
			Vector2i(-3, -3), Vector2i(b + 2, 10)]:
		assert_null(_farbe(ebenen, punkt.x, punkt.y), "Luft oder Grund bei %s" % punkt)
	_assert_nur_palette(ebenen)


func test_fokuslinie_auf_dunklem_grund_papier() -> void:
	# Arrange
	_knopf.on_dark = true
	_knopf.grab_focus()

	# Act
	var ebenen := _knopf.layers()

	# Assert
	assert_eq(_farbe(ebenen, -2, -2), UiPalette.PAPIER, "Auf nacht ist die Linie papier.")
	assert_eq(_farbe(ebenen, int(_knopf.size.x) + 1, int(_knopf.size.y) + 1), UiPalette.PAPIER)
	assert_eq(_farbe(ebenen, 1, 1), UiPalette.GEHAEUSE_HELL, "Das Relief bleibt gleich.")


func test_versteckter_fokus_zeigt_keine_linie() -> void:
	# Arrange: So bekommt ein Control den Fokus nach einem Mausklick, wie bei :focus-visible.
	_knopf.grab_focus(true)

	# Act
	var ebenen := _knopf.layers()

	# Assert
	assert_true(_knopf.has_focus(), "Voraussetzung: Der Knopf hat den Fokus.")
	assert_null(_farbe(ebenen, -2, -2), "Ein versteckter Fokus zeigt keine Linie.")


# --- Helfer ---------------------------------------------------------------

## Die Farbe, die der Knopf am Pixel ([param x], [param y]) über Fläche und Text malt: die des
## obersten Rechtecks, das den Pixel enthält, oder null, wenn er dort nichts malt.
func _farbe(ebenen: Array[Dictionary], x: int, y: int) -> Variant:
	var mitte := Vector2(x + 0.5, y + 0.5)
	var farbe: Variant = null
	for ebene in ebenen:
		var rechteck: Rect2 = ebene["rect"]
		if rechteck.has_point(mitte):
			farbe = ebene["color"]
	return farbe


func _assert_nur_palette(ebenen: Array[Dictionary]) -> void:
	var palette := UiPalette.TOKENS.values()
	for ebene in ebenen:
		assert_true(palette.has(ebene["color"]), "%s ist keine Farbe der Palette." % ebene)
		var rechteck: Rect2 = ebene["rect"]
		assert_eq(rechteck, Rect2(rechteck.position.round(), rechteck.size.round()),
			"%s liegt auf ganzen Pixeln." % ebene)
